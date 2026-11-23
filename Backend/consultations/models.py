"""Data models for dermatologists, availability slots, and consultation appointments."""

from django.conf import settings
from django.db import models

from core.models import TimeStampedModel, UUIDModel


class DermatologistSpecialty(models.TextChoices):
    DERMATOLOGIST = "dermatologist", "Dermatologist"
    COSMETOLOGIST = "cosmetologist", "Cosmetologist"
    AESTHETICIAN = "aesthetician", "Aesthetician"
    TRICHOLOGIST = "trichologist", "Trichologist"


class DermatologistProfile(UUIDModel, TimeStampedModel):
    """Profile for licensed medical dermatologists and specialists in Nepal."""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="dermatologist_profile",
    )
    nmc_number = models.CharField(
        max_length=50,
        unique=True,
        help_text="Nepal Medical Council registration number.",
    )
    is_verified = models.BooleanField(
        default=False,
        db_index=True,
        help_text="Requires admin verification before profile is listed or bookable.",
    )
    specialty = models.CharField(
        max_length=30,
        choices=DermatologistSpecialty.choices,
        default=DermatologistSpecialty.DERMATOLOGIST,
    )
    qualifications = models.CharField(
        max_length=255,
        default="MBBS, MD (Dermatology)",
        help_text="Medical degrees and credentials.",
    )
    experience_years = models.PositiveIntegerField(default=5)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=5.00)
    total_reviews = models.PositiveIntegerField(default=0)
    consultation_fee_paisa = models.PositiveIntegerField(
        default=150000,
        help_text="Consultation fee in NPR integer paisa (e.g. 150000 = Rs 1500).",
    )
    hospital = models.CharField(max_length=255, blank=True)
    about = models.TextField(blank=True)
    languages = models.JSONField(
        default=list,
        blank=True,
        help_text="Spoken languages (e.g. ['Nepali', 'English']).",
    )
    photo_url = models.URLField(blank=True)

    class Meta:
        ordering = ["-rating", "-experience_years"]

    def __str__(self) -> str:
        status = "Verified" if self.is_verified else "Pending Verification"
        return f"Dr. {self.user.get_full_name()} ({self.nmc_number}) - {status}"

    @property
    def fee_npr(self) -> int:
        return self.consultation_fee_paisa // 100


class AvailabilitySlot(UUIDModel, TimeStampedModel):
    """Dermatologist availability time slot."""

    dermatologist = models.ForeignKey(
        DermatologistProfile,
        on_delete=models.CASCADE,
        related_name="slots",
    )
    start_time = models.DateTimeField(db_index=True)
    end_time = models.DateTimeField()
    is_booked = models.BooleanField(default=False, db_index=True)

    class Meta:
        ordering = ["start_time"]
        constraints = [
            models.UniqueConstraint(
                fields=["dermatologist", "start_time"],
                name="unique_dermatologist_slot",
            )
        ]

    def __str__(self) -> str:
        booked = "BOOKED" if self.is_booked else "AVAILABLE"
        return f"Slot {self.dermatologist.user.get_full_name()} [{self.start_time.isoformat()}] ({booked})"


class AppointmentStatus(models.TextChoices):
    SCHEDULED = "scheduled", "Scheduled"
    CONFIRMED = "confirmed", "Confirmed"
    IN_PROGRESS = "in_progress", "In Progress"
    COMPLETED = "completed", "Completed"
    CANCELLED = "cancelled", "Cancelled"
    NO_SHOW = "no_show", "No Show"


class AppointmentType(models.TextChoices):
    VIDEO = "video", "Video Consultation"
    IN_PERSON = "in_person", "In-Person Visit"


class Appointment(UUIDModel, TimeStampedModel):
    """Consultation booking between a patient and verified dermatologist."""

    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="patient_appointments",
    )
    dermatologist = models.ForeignKey(
        DermatologistProfile,
        on_delete=models.CASCADE,
        related_name="doctor_appointments",
    )
    slot = models.OneToOneField(
        AvailabilitySlot,
        on_delete=models.PROTECT,
        related_name="appointment",
    )
    status = models.CharField(
        max_length=20,
        choices=AppointmentStatus.choices,
        default=AppointmentStatus.CONFIRMED,
        db_index=True,
    )
    appointment_type = models.CharField(
        max_length=20,
        choices=AppointmentType.choices,
        default=AppointmentType.VIDEO,
    )
    fee_paisa = models.PositiveIntegerField(help_text="Fee in integer paisa at booking time.")
    symptoms = models.TextField(blank=True)
    notes = models.TextField(blank=True)
    cancellation_reason = models.TextField(blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    room_channel = models.CharField(max_length=100, unique=True)

    class Meta:
        ordering = ["-slot__start_time"]
        indexes = [
            models.Index(fields=["patient", "status"]),
            models.Index(fields=["dermatologist", "status"]),
        ]

    def __str__(self) -> str:
        return f"Appointment {self.id}: {self.patient.email} with Dr. {self.dermatologist.user.get_full_name()} [{self.status}]"

    @property
    def fee_npr(self) -> int:
        return self.fee_paisa // 100
