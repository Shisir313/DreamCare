"""Models for dermatologist-authored immutable prescriptions, read audits, and weekly photo check-ins."""

import hashlib

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from core.models import CoreBaseModel, TimeStampedModel, UUIDModel


class PrescriptionStatus(models.TextChoices):
    ACTIVE = "active", "Active"
    COMPLETED = "completed", "Completed"
    CANCELLED = "cancelled", "Cancelled"
    EXPIRED = "expired", "Expired"


class Prescription(UUIDModel, TimeStampedModel):
    """Immutable clinical prescription authored by verified dermatologists."""

    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="prescriptions",
    )
    dermatologist = models.ForeignKey(
        "consultations.DermatologistProfile",
        on_delete=models.CASCADE,
        related_name="prescriptions",
    )
    appointment = models.ForeignKey(
        "consultations.Appointment",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="prescriptions",
    )
    version = models.PositiveIntegerField(default=1)
    parent_prescription = models.ForeignKey(
        "self",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="amendments",
    )
    is_published = models.BooleanField(
        default=False,
        db_index=True,
        help_text="Once published, clinical contents become permanently immutable.",
    )
    published_at = models.DateTimeField(null=True, blank=True)
    diagnosis = models.CharField(max_length=255)
    medications = models.JSONField(
        default=list,
        help_text="List of medication objects (name, dosage, frequency, duration, instructions, beforeMeal).",
    )
    instructions = models.TextField(blank=True)
    notes = models.TextField(blank=True)
    follow_up_date = models.DateField(null=True, blank=True)
    lab_tests = models.JSONField(default=list, blank=True)
    status = models.CharField(
        max_length=20,
        choices=PrescriptionStatus.choices,
        default=PrescriptionStatus.ACTIVE,
        db_index=True,
    )

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["patient", "status"]),
            models.Index(fields=["dermatologist", "status"]),
        ]

    def __str__(self) -> str:
        return (
            f"Prescription {self.id} (v{self.version}) - {self.diagnosis} for {self.patient.email}"
        )

    def clean(self):
        super().clean()
        if self.pk:
            orig = Prescription.objects.filter(pk=self.pk).first()
            if orig and orig.is_published:
                # Disallow modifying clinical content once published
                immutable_fields = [
                    "diagnosis",
                    "medications",
                    "instructions",
                    "notes",
                    "follow_up_date",
                    "lab_tests",
                ]
                for f in immutable_fields:
                    if getattr(self, f) != getattr(orig, f):
                        raise ValidationError(
                            {
                                f: [
                                    f"Cannot modify '{f}' on a published prescription. An amendment must be created."
                                ]
                            }
                        )

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)


class PrescriptionAccessAuditLog(CoreBaseModel):
    """Audit record of patient/user accessing clinical prescription."""

    prescription = models.ForeignKey(
        Prescription,
        on_delete=models.CASCADE,
        related_name="access_logs",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="prescription_access_logs",
    )
    accessed_at = models.DateTimeField(default=timezone.now, db_index=True)
    ip_hash = models.CharField(max_length=64, help_text="SHA-256 hash of client IP")
    user_agent_hash = models.CharField(max_length=64, help_text="SHA-256 hash of client User-Agent")

    class Meta:
        db_table = "prescription_access_audit_log"
        ordering = ["-accessed_at"]

    @staticmethod
    def hash_value(val: str) -> str:
        return hashlib.sha256(val.strip().encode("utf-8")).hexdigest()


class WeeklyCheckInStatus(models.TextChoices):
    SUBMITTED = "submitted", "Submitted"
    REVIEWED = "reviewed", "Reviewed"


class WeeklyCheckIn(UUIDModel, TimeStampedModel):
    """Weekly skin progress photo check-in for active memberships."""

    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="weekly_checkins",
    )
    membership = models.ForeignKey(
        "memberships.Membership",
        on_delete=models.CASCADE,
        related_name="checkins",
    )
    week_number = models.PositiveIntegerField(
        choices=[(1, "Week 1"), (2, "Week 2"), (3, "Week 3"), (4, "Week 4")]
    )
    front_photo = models.ForeignKey(
        "media_vault.FacePhoto",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="+",
    )
    left_photo = models.ForeignKey(
        "media_vault.FacePhoto",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="+",
    )
    right_photo = models.ForeignKey(
        "media_vault.FacePhoto",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="+",
    )
    patient_note = models.TextField(blank=True)
    status = models.CharField(
        max_length=20,
        choices=WeeklyCheckInStatus.choices,
        default=WeeklyCheckInStatus.SUBMITTED,
        db_index=True,
    )
    dermatologist = models.ForeignKey(
        "consultations.DermatologistProfile",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="reviewed_checkins",
    )
    dermatologist_feedback = models.TextField(blank=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    submitted_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ["week_number"]
        constraints = [
            models.UniqueConstraint(
                fields=["membership", "week_number"],
                name="unique_membership_week_checkin",
            )
        ]

    def __str__(self) -> str:
        return f"Check-in Week {self.week_number} ({self.membership.plan.name}) for {self.patient.email} [{self.status}]"
