"""Business logic services for prescriptions, immutability, audit logging, and weekly check-ins."""

import logging
from datetime import timedelta

from django.core.exceptions import PermissionDenied, ValidationError
from django.db import transaction
from django.utils import timezone

from accounts.models import User, UserRole
from consultations.models import DermatologistProfile
from media_vault.models import FacePhoto
from memberships.models import Membership, MembershipStatus
from memberships.services import consume_checkin_entitlement
from prescriptions.models import (
    Prescription,
    PrescriptionAccessAuditLog,
    PrescriptionStatus,
    WeeklyCheckIn,
    WeeklyCheckInStatus,
)

logger = logging.getLogger(__name__)


def create_prescription(
    doctor_user,
    patient_id,
    diagnosis: str,
    medications: list,
    appointment_id=None,
    instructions: str = "",
    notes: str = "",
    follow_up_date=None,
    lab_tests: list = None,
    publish_now: bool = True,
) -> Prescription:
    """Authored exclusively by verified dermatologists."""
    if doctor_user.role != UserRole.DERMATOLOGIST and not doctor_user.is_staff:
        raise PermissionDenied("Only registered dermatologists can author prescriptions.")

    try:
        doctor_profile = doctor_user.dermatologist_profile
    except DermatologistProfile.DoesNotExist as exc:
        raise ValidationError({"doctor": ["Dermatologist profile not found."]}) from exc

    if not doctor_profile.is_verified:
        raise ValidationError(
            {"doctor": ["Only administratively verified dermatologists can issue prescriptions."]}
        )

    try:
        patient = User.objects.get(id=patient_id, role=UserRole.PATIENT)
    except User.DoesNotExist as exc:
        raise ValidationError({"patient": ["Patient not found."]}) from exc

    prescription = Prescription(
        patient=patient,
        dermatologist=doctor_profile,
        appointment_id=appointment_id,
        diagnosis=diagnosis,
        medications=medications,
        instructions=instructions,
        notes=notes,
        follow_up_date=follow_up_date,
        lab_tests=lab_tests or [],
        version=1,
    )

    if publish_now:
        prescription.is_published = True
        prescription.published_at = timezone.now()

    prescription.save()
    logger.info(
        "Prescription %s (v1) created by doctor=%s for patient=%s",
        prescription.id,
        doctor_user.id,
        patient.id,
    )
    return prescription


def publish_prescription(prescription_id, doctor_user) -> Prescription:
    """Publish a draft prescription, locking clinical contents permanently."""
    prescription = Prescription.objects.get(id=prescription_id)
    if prescription.dermatologist.user_id != doctor_user.id and not doctor_user.is_staff:
        raise PermissionDenied("Only the authoring dermatologist can publish this prescription.")

    if prescription.is_published:
        return prescription

    prescription.is_published = True
    prescription.published_at = timezone.now()
    prescription.save(update_fields=["is_published", "published_at", "updated_at"])
    return prescription


@transaction.atomic
def amend_prescription(
    prescription_id,
    doctor_user,
    amendments: dict,
    publish_now: bool = True,
) -> Prescription:
    """Create a versioned amendment (v+1) of an existing published prescription."""
    original = Prescription.objects.select_for_update().get(id=prescription_id)
    if original.dermatologist.user_id != doctor_user.id and not doctor_user.is_staff:
        raise PermissionDenied("Only the authoring dermatologist can amend this prescription.")

    new_version = Prescription(
        patient=original.patient,
        dermatologist=original.dermatologist,
        appointment=original.appointment,
        parent_prescription=original,
        version=original.version + 1,
        diagnosis=amendments.get("diagnosis", original.diagnosis),
        medications=amendments.get("medications", original.medications),
        instructions=amendments.get("instructions", original.instructions),
        notes=amendments.get("notes", original.notes),
        follow_up_date=amendments.get("follow_up_date", original.follow_up_date),
        lab_tests=amendments.get("lab_tests", original.lab_tests),
        status=PrescriptionStatus.ACTIVE,
    )

    if publish_now:
        new_version.is_published = True
        new_version.published_at = timezone.now()

    new_version.save()

    # Mark original as completed/superseded
    original.status = PrescriptionStatus.COMPLETED
    original.save(update_fields=["status", "updated_at"])

    logger.info(
        "Prescription %s amended to new version %s (v%d)",
        original.id,
        new_version.id,
        new_version.version,
    )
    return new_version


def log_prescription_access(
    prescription: Prescription, user: User, request
) -> PrescriptionAccessAuditLog:
    """Audit log every patient or clinical access to a prescription."""
    ip = request.META.get("HTTP_X_FORWARDED_FOR", "").split(",")[0].strip() or request.META.get(
        "REMOTE_ADDR", ""
    )
    ua = request.META.get("HTTP_USER_AGENT", "")

    return PrescriptionAccessAuditLog.objects.create(
        prescription=prescription,
        user=user,
        ip_hash=PrescriptionAccessAuditLog.hash_value(ip or "127.0.0.1"),
        user_agent_hash=PrescriptionAccessAuditLog.hash_value(ua or "Unknown"),
    )


def get_weekly_checkin_schedule(user: User) -> list[dict]:
    """Calculate 4-week unlock schedule and status in Asia/Kathmandu."""
    membership = (
        Membership.objects.filter(
            user=user, status__in=[MembershipStatus.ACTIVE, MembershipStatus.EXPIRED]
        )
        .order_by("-created_at")
        .first()
    )
    if not membership:
        return []

    local_start_date = timezone.localtime(membership.start_date).date()
    today = timezone.localdate()

    schedule = []
    for week_num in range(1, 5):
        unlock_date = local_start_date + timedelta(days=(week_num - 1) * 7)
        checkin = WeeklyCheckIn.objects.filter(membership=membership, week_number=week_num).first()
        schedule.append(
            {
                "weekNumber": week_num,
                "isUnlocked": today >= unlock_date,
                "unlockDate": unlock_date,
                "isSubmitted": checkin is not None,
                "checkIn": checkin,
            }
        )
    return schedule


@transaction.atomic
def submit_weekly_checkin(
    user: User,
    week_number: int,
    front_photo_id=None,
    left_photo_id=None,
    right_photo_id=None,
    patient_note: str = "",
) -> WeeklyCheckIn:
    """Submit weekly photo check-in with Asia/Kathmandu unlock enforcement and quota check."""
    membership = (
        Membership.objects.select_for_update()
        .filter(user=user, status=MembershipStatus.ACTIVE)
        .first()
    )
    if not membership or membership.check_and_enforce_expiry():
        raise ValidationError(
            {"membership": ["Your membership has expired. Check-in uploads are locked."]}
        )

    # Enforce unlock date in Asia/Kathmandu
    local_start_date = timezone.localtime(membership.start_date).date()
    unlock_date = local_start_date + timedelta(days=(week_number - 1) * 7)
    today = timezone.localdate()

    if today < unlock_date:
        raise ValidationError(
            {"week_number": [f"Week {week_number} check-in unlocks on {unlock_date}."]}
        )

    if WeeklyCheckIn.objects.filter(membership=membership, week_number=week_number).exists():
        raise ValidationError(
            {"week_number": [f"Week {week_number} check-in has already been submitted."]}
        )

    # Consume entitlement
    consume_checkin_entitlement(user=user)

    front_photo = (
        FacePhoto.objects.filter(id=front_photo_id, user=user).first() if front_photo_id else None
    )
    left_photo = (
        FacePhoto.objects.filter(id=left_photo_id, user=user).first() if left_photo_id else None
    )
    right_photo = (
        FacePhoto.objects.filter(id=right_photo_id, user=user).first() if right_photo_id else None
    )

    checkin = WeeklyCheckIn.objects.create(
        patient=user,
        membership=membership,
        week_number=week_number,
        front_photo=front_photo,
        left_photo=left_photo,
        right_photo=right_photo,
        patient_note=patient_note,
        status=WeeklyCheckInStatus.SUBMITTED,
    )

    logger.info(
        "Weekly check-in submitted: user=%s, membership=%s, week=%d",
        user.id,
        membership.id,
        week_number,
    )
    return checkin


def review_weekly_checkin(checkin_id, doctor_user, feedback: str) -> WeeklyCheckIn:
    """Dermatologist reviews weekly check-in and submits clinical guidance."""
    try:
        doctor_profile = doctor_user.dermatologist_profile
    except DermatologistProfile.DoesNotExist as exc:
        raise PermissionDenied("Only registered dermatologists can review check-ins.") from exc

    if not doctor_profile.is_verified:
        raise ValidationError({"doctor": ["Only verified dermatologists can review check-ins."]})

    checkin = WeeklyCheckIn.objects.get(id=checkin_id)
    checkin.dermatologist = doctor_profile
    checkin.dermatologist_feedback = feedback
    checkin.status = WeeklyCheckInStatus.REVIEWED
    checkin.reviewed_at = timezone.now()
    checkin.save(
        update_fields=[
            "dermatologist",
            "dermatologist_feedback",
            "status",
            "reviewed_at",
            "updated_at",
        ]
    )

    return checkin
