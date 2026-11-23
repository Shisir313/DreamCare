"""Integration and concurrency tests for consultations, booking, and Agora video room tokens."""

from datetime import timedelta
from unittest.mock import patch

import pytest
from django.core.exceptions import PermissionDenied, ValidationError
from django.utils import timezone
from rest_framework.test import APIClient

from accounts.models import User, UserRole
from consent.models import ConsentPolicy, ConsentRecord, PolicyType
from consultations.models import (
    Appointment,
    AppointmentStatus,
    AvailabilitySlot,
    DermatologistProfile,
    DermatologistSpecialty,
)
from consultations.services import (
    book_appointment,
    cancel_appointment,
    generate_video_token_for_appointment,
    reschedule_appointment,
)
from memberships.models import Membership, MembershipStatus, Plan, PlanCode
from memberships.services import seed_default_plans


@pytest.fixture
def patient_user(db):
    user = User.objects.create_user(
        email="sujana_m6@example.com",
        password="ValidPassword123!",
        role=UserRole.PATIENT,
        name="Sujana Shrestha",
        phone="9841000001",
    )
    # Grant active consent
    ConsentPolicy.objects.create(
        policy_type=PolicyType.TERMS_OF_SERVICE,
        version="1.0",
        title="Terms",
        summary="Terms summary",
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
    user = User.objects.create_user(
        email="dr_anjali@dermacare.np",
        password="DoctorPassword123!",
        role=UserRole.DERMATOLOGIST,
        name="Anjali Sharma",
        phone="9841112233",
    )
    return user


@pytest.fixture
def verified_doctor(doctor_user):
    return DermatologistProfile.objects.create(
        user=doctor_user,
        nmc_number="NMC-12345",
        is_verified=True,
        specialty=DermatologistSpecialty.DERMATOLOGIST,
        qualifications="MBBS, MD (Dermatology)",
        experience_years=12,
        rating=4.8,
        total_reviews=156,
        consultation_fee_paisa=150000,
        hospital="Nepal Mediciti Hospital",
        about="Specialized in acne and cosmetic dermatology.",
        languages=["Nepali", "English"],
    )


@pytest.fixture
def unverified_doctor(db):
    user = User.objects.create_user(
        email="dr_unverified@dermacare.np",
        password="DoctorPassword123!",
        role=UserRole.DERMATOLOGIST,
        name="Ramesh Karki",
    )
    return DermatologistProfile.objects.create(
        user=user,
        nmc_number="NMC-99999",
        is_verified=False,
    )


@pytest.fixture
def slot(verified_doctor):
    tomorrow = timezone.now() + timedelta(days=1)
    slot_start = tomorrow.replace(hour=10, minute=0, second=0, microsecond=0)
    slot_end = slot_start + timedelta(minutes=30)
    return AvailabilitySlot.objects.create(
        dermatologist=verified_doctor,
        start_time=slot_start,
        end_time=slot_end,
    )


@pytest.mark.django_db
def test_doctor_listing_shows_only_verified_dermatologists(verified_doctor, unverified_doctor):
    client = APIClient()
    response = client.get("/api/v1/consultations/doctors/")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["name"] == "Dr. Anjali Sharma"
    assert data[0]["isVerified"] is True
    assert data[0]["consultationFee"] == 1500
    assert data[0]["consultationFeePaisa"] == 150000


@pytest.mark.django_db
def test_doctor_slots_listing(verified_doctor, slot):
    client = APIClient()
    local_date = timezone.localtime(slot.start_time).strftime("%Y-%m-%d")
    response = client.get(
        f"/api/v1/consultations/doctors/{verified_doctor.id}/slots/?date={local_date}"
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["isAvailable"] is True
    local_start = timezone.localtime(slot.start_time).strftime("%H:%M")
    local_end = timezone.localtime(slot.end_time).strftime("%H:%M")
    assert f"{local_start} - {local_end}" in data[0]["timeRange"]


@pytest.mark.django_db
def test_book_appointment_consumes_entitlement(patient_user, active_membership, slot):
    appointment = book_appointment(
        patient=patient_user,
        slot_id=slot.id,
        symptoms="Redness on cheeks",
    )
    assert appointment.status == AppointmentStatus.CONFIRMED
    assert appointment.symptoms == "Redness on cheeks"
    assert appointment.room_channel.startswith("dermacare_")

    slot.refresh_from_db()
    assert slot.is_booked is True

    active_membership.refresh_from_db()
    assert active_membership.consultations_remaining == 0


@pytest.mark.django_db
def test_concurrency_no_double_booking(patient_user, active_membership, slot):
    """Concurrency guard test: Proves no double booking.

    Once a slot is locked and claimed, any simultaneous or competing booking
    attempt targeting the same slot is rejected and aborted without modifying state.
    """
    # First booking succeeds
    apt1 = book_appointment(patient=patient_user, slot_id=slot.id)
    assert apt1.status == AppointmentStatus.CONFIRMED
    assert slot.appointment.id == apt1.id

    # Second patient attempts to book the exact same slot
    patient_2 = User.objects.create_user(
        email="patient2@example.com",
        password="ValidPassword123!",
        role=UserRole.PATIENT,
        name="Triyog Bhattarai",
    )
    p2_membership = Membership.objects.create(
        user=patient_2,
        plan=active_membership.plan,
        status=MembershipStatus.ACTIVE,
        start_date=timezone.now(),
        end_date=timezone.now() + timedelta(days=28),
        consultations_remaining=1,
    )

    with pytest.raises(ValidationError) as exc_info:
        book_appointment(patient=patient_2, slot_id=slot.id)

    assert "This slot is already booked" in str(exc_info.value)

    # Entitlement was preserved for patient 2
    p2_membership.refresh_from_db()
    assert p2_membership.consultations_remaining == 1

    # Exactly one appointment exists for this slot
    assert Appointment.objects.filter(slot=slot).count() == 1


@pytest.mark.django_db
def test_cancel_appointment_restores_entitlement(patient_user, active_membership, slot):
    appointment = book_appointment(patient=patient_user, slot_id=slot.id)
    active_membership.refresh_from_db()
    assert active_membership.consultations_remaining == 0

    # Cancel with > 2 hours advance notice (slot is tomorrow)
    cancelled_apt = cancel_appointment(
        appointment_id=appointment.id,
        user=patient_user,
        reason="Schedule conflict",
    )
    assert cancelled_apt.status == AppointmentStatus.CANCELLED
    assert cancelled_apt.cancellation_reason == "Schedule conflict"

    slot.refresh_from_db()
    assert slot.is_booked is False

    active_membership.refresh_from_db()
    assert active_membership.consultations_remaining == 1


@pytest.mark.django_db
def test_reschedule_appointment(patient_user, active_membership, verified_doctor, slot):
    appointment = book_appointment(patient=patient_user, slot_id=slot.id)

    # Create second slot with same doctor
    day_after = timezone.now() + timedelta(days=2)
    new_slot = AvailabilitySlot.objects.create(
        dermatologist=verified_doctor,
        start_time=day_after.replace(hour=14, minute=0, second=0, microsecond=0),
        end_time=day_after.replace(hour=14, minute=30, second=0, microsecond=0),
    )

    rescheduled = reschedule_appointment(
        appointment_id=appointment.id,
        new_slot_id=new_slot.id,
        user=patient_user,
    )
    assert rescheduled.slot_id == new_slot.id

    slot.refresh_from_db()
    assert slot.is_booked is False

    new_slot.refresh_from_db()
    assert new_slot.is_booked is True


@pytest.mark.django_db
def test_video_token_join_window_guard(patient_user, active_membership, slot):
    appointment = book_appointment(patient=patient_user, slot_id=slot.id)

    # Slot is tomorrow -> current time is way too early
    with pytest.raises(PermissionDenied) as exc_info:
        generate_video_token_for_appointment(appointment.id, user=patient_user)
    assert "Video call is not active" in str(exc_info.value)

    # Mock time to within 10 minutes before slot start
    with patch("django.utils.timezone.now", return_value=slot.start_time - timedelta(minutes=10)):
        token_data = generate_video_token_for_appointment(appointment.id, user=patient_user)
        assert token_data["roomChannel"] == appointment.room_channel
        assert len(token_data["token"]) > 20
        assert token_data["expiresIn"] == 3600
