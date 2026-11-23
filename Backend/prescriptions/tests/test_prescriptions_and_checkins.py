"""Integration tests for prescriptions, immutability, audit logging, and weekly check-ins."""

from datetime import timedelta

import pytest
from django.core.exceptions import PermissionDenied, ValidationError
from django.utils import timezone
from rest_framework.test import APIClient

from accounts.models import User, UserRole
from consent.models import ConsentPolicy, ConsentRecord, PolicyType
from consultations.models import (
    DermatologistProfile,
    DermatologistSpecialty,
)
from memberships.models import Membership, MembershipStatus, Plan, PlanCode
from memberships.services import seed_default_plans
from prescriptions.models import (
    PrescriptionAccessAuditLog,
    PrescriptionStatus,
    WeeklyCheckInStatus,
)
from prescriptions.services import (
    amend_prescription,
    create_prescription,
    review_weekly_checkin,
    submit_weekly_checkin,
)


@pytest.fixture
def patient_user(db):
    user = User.objects.create_user(
        email="sujana_m7@example.com",
        password="ValidPassword123!",
        role=UserRole.PATIENT,
        name="Sujana Shrestha",
        phone="9841000002",
    )
    ConsentPolicy.objects.create(
        policy_type=PolicyType.TERMS_OF_SERVICE,
        version="1.0",
        title="Terms",
        summary="Terms",
        is_active=True,
    )
    ConsentRecord.objects.create(
        user=user,
        policy_type=PolicyType.TERMS_OF_SERVICE,
        policy_version="1.0",
        ip_hash="fake_hash",
        user_agent_hash="fake_ua_hash",
    )
    return user


@pytest.fixture
def active_membership(patient_user):
    seed_default_plans()
    basic_plan = Plan.objects.get(code=PlanCode.BASIC)
    now = timezone.now()
    return Membership.objects.create(
        user=patient_user,
        plan=basic_plan,
        status=MembershipStatus.ACTIVE,
        start_date=now,
        end_date=now + timedelta(days=28),
        consultations_remaining=1,
        checkins_remaining=4,
    )


@pytest.fixture
def doctor_user(db):
    return User.objects.create_user(
        email="dr_anjali_m7@dermacare.np",
        password="DoctorPassword123!",
        role=UserRole.DERMATOLOGIST,
        name="Dr. Anjali Sharma",
    )


@pytest.fixture
def verified_doctor(doctor_user):
    return DermatologistProfile.objects.create(
        user=doctor_user,
        nmc_number="NMC-77777",
        is_verified=True,
        specialty=DermatologistSpecialty.DERMATOLOGIST,
        qualifications="MBBS, MD (Dermatology)",
        experience_years=12,
        consultation_fee_paisa=150000,
    )


@pytest.fixture
def unverified_doctor(db):
    user = User.objects.create_user(
        email="dr_unverified_m7@dermacare.np",
        password="DoctorPassword123!",
        role=UserRole.DERMATOLOGIST,
        name="Dr. Unverified",
    )
    return DermatologistProfile.objects.create(
        user=user,
        nmc_number="NMC-88888",
        is_verified=False,
    )


@pytest.fixture
def sample_medications():
    return [
        {
            "name": "Adapalene Gel 0.1%",
            "dosage": "Thin layer",
            "frequency": "Once daily at night",
            "duration": "8 weeks",
            "instructions": "Apply to clean, dry skin. Avoid direct sunlight.",
            "beforeMeal": False,
        },
        {
            "name": "Doxycycline",
            "dosage": "100mg",
            "frequency": "Once daily",
            "duration": "4 weeks",
            "instructions": "Take after meals with a full glass of water.",
            "beforeMeal": False,
        },
    ]


@pytest.mark.django_db
def test_create_prescription_by_verified_dermatologist(
    doctor_user, verified_doctor, patient_user, sample_medications
):
    prescription = create_prescription(
        doctor_user=doctor_user,
        patient_id=patient_user.id,
        diagnosis="Acne Vulgaris (Grade II)",
        medications=sample_medications,
        notes="Gentle cleanser and broad spectrum SPF 50 required.",
        publish_now=True,
    )
    assert prescription.is_published is True
    assert prescription.version == 1
    assert prescription.diagnosis == "Acne Vulgaris (Grade II)"
    assert len(prescription.medications) == 2


@pytest.mark.django_db
def test_unverified_doctor_or_patient_cannot_create_prescription(
    unverified_doctor, patient_user, sample_medications
):
    # Unverified doctor raises ValidationError
    with pytest.raises(ValidationError) as exc_info:
        create_prescription(
            doctor_user=unverified_doctor.user,
            patient_id=patient_user.id,
            diagnosis="Eczema",
            medications=sample_medications,
        )
    assert "administratively verified" in str(exc_info.value)

    # Patient raises PermissionDenied
    with pytest.raises(PermissionDenied):
        create_prescription(
            doctor_user=patient_user,
            patient_id=patient_user.id,
            diagnosis="Self-medication",
            medications=sample_medications,
        )


@pytest.mark.django_db
def test_prescription_immutability_after_publishing(
    doctor_user, verified_doctor, patient_user, sample_medications
):
    prescription = create_prescription(
        doctor_user=doctor_user,
        patient_id=patient_user.id,
        diagnosis="Acne Vulgaris",
        medications=sample_medications,
        publish_now=True,
    )

    # Attempting to directly alter clinical diagnosis on published prescription raises ValidationError
    prescription.diagnosis = "Tampered Diagnosis"
    with pytest.raises(ValidationError) as exc_info:
        prescription.save()

    assert "Cannot modify 'diagnosis' on a published prescription" in str(exc_info.value)


@pytest.mark.django_db
def test_amend_prescription_creates_new_version(
    doctor_user, verified_doctor, patient_user, sample_medications
):
    orig = create_prescription(
        doctor_user=doctor_user,
        patient_id=patient_user.id,
        diagnosis="Acne Vulgaris",
        medications=sample_medications,
        publish_now=True,
    )

    amended = amend_prescription(
        prescription_id=orig.id,
        doctor_user=doctor_user,
        amendments={
            "diagnosis": "Acne Vulgaris (Improving)",
            "notes": "Step down oral antibiotics.",
        },
    )

    assert amended.version == 2
    assert amended.parent_prescription_id == orig.id
    assert amended.diagnosis == "Acne Vulgaris (Improving)"
    assert amended.notes == "Step down oral antibiotics."

    orig.refresh_from_db()
    assert orig.status == PrescriptionStatus.COMPLETED


@pytest.mark.django_db
def test_patient_read_logs_audit_record(
    doctor_user, verified_doctor, patient_user, sample_medications
):
    prescription = create_prescription(
        doctor_user=doctor_user,
        patient_id=patient_user.id,
        diagnosis="Atopic Dermatitis",
        medications=sample_medications,
        publish_now=True,
    )

    client = APIClient()
    client.force_authenticate(user=patient_user)

    response = client.get(f"/api/v1/prescriptions/{prescription.id}/")
    assert response.status_code == 200

    # Verify audit log record created
    log = PrescriptionAccessAuditLog.objects.filter(
        prescription=prescription, user=patient_user
    ).first()
    assert log is not None
    assert len(log.ip_hash) == 64
    assert len(log.user_agent_hash) == 64


@pytest.mark.django_db
def test_weekly_checkin_unlock_logic_in_asia_kathmandu(patient_user, active_membership):
    # Week 1 is unlocked immediately on start date
    checkin_w1 = submit_weekly_checkin(
        user=patient_user,
        week_number=1,
        patient_note="Week 1 baseline progress.",
    )
    assert checkin_w1.week_number == 1
    assert checkin_w1.status == WeeklyCheckInStatus.SUBMITTED

    # Week 2 submission today (start_date + 0 days) should fail because Week 2 unlocks at start_date + 7 days
    with pytest.raises(ValidationError) as exc_info:
        submit_weekly_checkin(
            user=patient_user,
            week_number=2,
            patient_note="Early submission.",
        )
    assert "Week 2 check-in unlocks on" in str(exc_info.value)


@pytest.mark.django_db
def test_submit_weekly_checkin_consumes_entitlement(patient_user, active_membership):
    assert active_membership.checkins_remaining == 4

    submit_weekly_checkin(
        user=patient_user,
        week_number=1,
        patient_note="Week 1 photos.",
    )

    active_membership.refresh_from_db()
    assert active_membership.checkins_remaining == 3


@pytest.mark.django_db
def test_expired_membership_locks_checkin_submission_but_history_readable(
    patient_user, active_membership
):
    # Submit week 1 while active
    submit_weekly_checkin(
        user=patient_user,
        week_number=1,
        patient_note="Submitted while active.",
    )

    # Fast forward membership to expired
    active_membership.status = MembershipStatus.EXPIRED
    active_membership.end_date = timezone.now() - timedelta(days=1)
    active_membership.save(update_fields=["status", "end_date"])

    # New checkin submission is locked
    with pytest.raises(ValidationError) as exc_info:
        submit_weekly_checkin(user=patient_user, week_number=2)
    assert "membership has expired" in str(exc_info.value).lower()

    # Historical read via API remains accessible
    client = APIClient()
    client.force_authenticate(user=patient_user)

    response = client.get("/api/v1/prescriptions/check-ins/history/")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["weekNumber"] == 1


@pytest.mark.django_db
def test_dermatologist_reviews_weekly_checkin(
    doctor_user, verified_doctor, patient_user, active_membership
):
    checkin = submit_weekly_checkin(
        user=patient_user,
        week_number=1,
        patient_note="Experiencing slight redness after gel application.",
    )

    reviewed = review_weekly_checkin(
        checkin_id=checkin.id,
        doctor_user=doctor_user,
        feedback="Redness is a normal retinoid reaction during week 1. Apply moisturizer 20 minutes before gel.",
    )

    assert reviewed.status == WeeklyCheckInStatus.REVIEWED
    assert reviewed.dermatologist_id == verified_doctor.id
    assert "retinoid reaction" in reviewed.dermatologist_feedback
    assert reviewed.reviewed_at is not None
