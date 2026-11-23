"""Business logic services for consultations, booking, rescheduling, and Agora video room tokens."""

import logging
import uuid
from datetime import timedelta

from django.conf import settings
from django.core.exceptions import PermissionDenied, ValidationError
from django.db import transaction
from django.utils import timezone

from consultations.agora import generate_agora_rtc_token
from consultations.models import (
    Appointment,
    AppointmentStatus,
    AppointmentType,
    AvailabilitySlot,
)
from memberships.services import (
    consume_consultation_entitlement,
    restore_consultation_entitlement,
)

logger = logging.getLogger(__name__)


@transaction.atomic
def book_appointment(
    patient,
    slot_id,
    appointment_type: str = AppointmentType.VIDEO,
    symptoms: str = "",
) -> Appointment:
    """Book an appointment with transactional row locking on AvailabilitySlot and entitlement decrement.

    Guarantees zero double-booking even under highly concurrent simultaneous booking attempts.
    """
    try:
        slot = (
            AvailabilitySlot.objects.select_for_update()
            .select_related("dermatologist__user")
            .get(id=slot_id)
        )
    except AvailabilitySlot.DoesNotExist as exc:
        raise ValidationError({"slot": ["Selected time slot was not found."]}) from exc

    if not slot.dermatologist.is_verified:
        raise ValidationError(
            {"doctor": ["This dermatologist is pending administrative verification."]}
        )

    if slot.is_booked:
        raise ValidationError({"slot": ["This slot is already booked."]})

    # Consume consultation entitlement atomically
    consume_consultation_entitlement(user=patient)

    # Mark slot booked
    slot.is_booked = True
    slot.save(update_fields=["is_booked", "updated_at"])

    room_channel = f"dermacare_{uuid.uuid4().hex[:16]}"

    appointment = Appointment.objects.create(
        patient=patient,
        dermatologist=slot.dermatologist,
        slot=slot,
        status=AppointmentStatus.CONFIRMED,
        appointment_type=appointment_type,
        fee_paisa=slot.dermatologist.consultation_fee_paisa,
        symptoms=symptoms,
        room_channel=room_channel,
    )

    logger.info(
        "Appointment %s booked successfully: patient=%s, doctor=%s, slot=%s",
        appointment.id,
        patient.id,
        slot.dermatologist.id,
        slot.id,
    )
    return appointment


@transaction.atomic
def cancel_appointment(
    appointment_id,
    user,
    reason: str = "",
) -> Appointment:
    """Cancel an appointment, release the slot, and restore entitlement if > 2 hours prior to start."""
    try:
        appointment = (
            Appointment.objects.select_for_update()
            .select_related("slot", "patient", "dermatologist__user")
            .get(id=appointment_id)
        )
    except Appointment.DoesNotExist as exc:
        raise ValidationError({"appointment": ["Appointment not found."]}) from exc

    is_patient = user.id == appointment.patient.id
    is_doctor = user.id == appointment.dermatologist.user.id
    if not (is_patient or is_doctor or user.is_staff):
        raise PermissionDenied("You are not authorized to cancel this appointment.")

    if appointment.status in [AppointmentStatus.COMPLETED, AppointmentStatus.CANCELLED]:
        raise ValidationError(
            {"appointment": [f"Cannot cancel appointment with status '{appointment.status}'."]}
        )

    now = timezone.now()
    # If cancelled at least 2 hours before start, restore entitlement credit
    if appointment.slot.start_time - now >= timedelta(hours=2):
        restore_consultation_entitlement(user=appointment.patient)

    # Free the slot
    slot = appointment.slot
    slot.is_booked = False
    slot.save(update_fields=["is_booked", "updated_at"])

    appointment.status = AppointmentStatus.CANCELLED
    appointment.cancellation_reason = reason
    appointment.cancelled_at = now
    appointment.save(update_fields=["status", "cancellation_reason", "cancelled_at", "updated_at"])

    logger.info("Appointment %s cancelled by user=%s. Reason: %s", appointment.id, user.id, reason)
    return appointment


@transaction.atomic
def reschedule_appointment(
    appointment_id,
    new_slot_id,
    user,
) -> Appointment:
    """Reschedule an appointment to a new available slot atomically."""
    try:
        appointment = (
            Appointment.objects.select_for_update()
            .select_related("slot", "patient", "dermatologist__user")
            .get(id=appointment_id)
        )
    except Appointment.DoesNotExist as exc:
        raise ValidationError({"appointment": ["Appointment not found."]}) from exc

    is_patient = user.id == appointment.patient.id
    is_doctor = user.id == appointment.dermatologist.user.id
    if not (is_patient or is_doctor or user.is_staff):
        raise PermissionDenied("You are not authorized to reschedule this appointment.")

    if appointment.status != AppointmentStatus.CONFIRMED:
        raise ValidationError({"appointment": ["Only confirmed appointments can be rescheduled."]})

    try:
        new_slot = AvailabilitySlot.objects.select_for_update().get(id=new_slot_id)
    except AvailabilitySlot.DoesNotExist as exc:
        raise ValidationError({"slot": ["New time slot was not found."]}) from exc

    if new_slot.is_booked:
        raise ValidationError({"slot": ["Selected time slot is already booked."]})

    if new_slot.dermatologist_id != appointment.dermatologist_id:
        raise ValidationError({"slot": ["Rescheduling must be with the same dermatologist."]})

    # Free old slot, claim new slot
    old_slot = appointment.slot
    old_slot.is_booked = False
    old_slot.save(update_fields=["is_booked", "updated_at"])

    new_slot.is_booked = True
    new_slot.save(update_fields=["is_booked", "updated_at"])

    appointment.slot = new_slot
    appointment.save(update_fields=["slot", "updated_at"])

    logger.info(
        "Appointment %s rescheduled: old_slot=%s -> new_slot=%s",
        appointment.id,
        old_slot.id,
        new_slot.id,
    )
    return appointment


def generate_video_token_for_appointment(appointment_id, user) -> dict:
    """Issue short-lived Agora RTC room token if the current time is within the allowed join window."""
    try:
        appointment = Appointment.objects.select_related(
            "slot", "patient", "dermatologist__user"
        ).get(id=appointment_id)
    except Appointment.DoesNotExist as exc:
        raise ValidationError({"appointment": ["Appointment not found."]}) from exc

    is_patient = user.id == appointment.patient.id
    is_doctor = user.id == appointment.dermatologist.user.id
    if not (is_patient or is_doctor or user.is_staff):
        raise PermissionDenied("You are not authorized to access this consultation room.")

    if appointment.status not in [AppointmentStatus.CONFIRMED, AppointmentStatus.IN_PROGRESS]:
        raise ValidationError(
            {"appointment": [f"Cannot join consultation with status '{appointment.status}'."]}
        )

    now = timezone.now()
    join_window_start = appointment.slot.start_time - timedelta(minutes=15)
    join_window_end = appointment.slot.end_time + timedelta(minutes=45)

    if not (join_window_start <= now <= join_window_end):
        raise PermissionDenied(
            "Video call is not active. The join window opens 15 minutes before the scheduled start time."
        )

    # Transition to IN_PROGRESS if currently confirmed
    if appointment.status == AppointmentStatus.CONFIRMED and now >= appointment.slot.start_time:
        appointment.status = AppointmentStatus.IN_PROGRESS
        appointment.save(update_fields=["status", "updated_at"])

    # UID: integer hash of user UUID
    uid = abs(hash(str(user.id))) % 10000000

    app_id = getattr(settings, "AGORA_APP_ID", "test_agora_app_id_dermacare")
    app_cert = getattr(settings, "AGORA_APP_CERTIFICATE", "test_agora_certificate")

    token = generate_agora_rtc_token(
        app_id=app_id,
        app_certificate=app_cert,
        channel_name=appointment.room_channel,
        uid=uid,
        expire_seconds=3600,
        role=1,
    )

    return {
        "roomChannel": appointment.room_channel,
        "token": token,
        "appId": app_id,
        "uid": uid,
        "expiresIn": 3600,
    }
