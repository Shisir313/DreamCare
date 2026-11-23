"""Models for plans, memberships, entitlements, and state transitions."""

from datetime import timedelta

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from core.models import CoreBaseModel, TimeStampedModel


class PlanCode(models.TextChoices):
    BASIC = "basic", "Basic Plan"
    PREMIUM = "premium", "Premium Plan"
    PAY_PER_CONSULTATION = "pay_per_consultation", "Pay-per-Consultation"


class Plan(TimeStampedModel):
    """Admin-editable membership plan with price stored strictly in NPR integer paisa."""

    code = models.CharField(
        max_length=50,
        choices=PlanCode.choices,
        unique=True,
        db_index=True,
    )
    name = models.CharField(max_length=100)
    description = models.TextField()
    price_paisa = models.PositiveIntegerField(
        help_text="Price in Nepali Paisa (1 NPR = 100 Paisa). E.g. Rs 399 = 39900 paisa.",
    )
    currency = models.CharField(max_length=10, default="NPR")
    duration_days = models.PositiveIntegerField(
        default=28,
        help_text="Term length in days (4 weeks = 28 days for memberships).",
    )
    consultations_included = models.PositiveIntegerField(
        default=1,
        help_text="Consultation quota granted upon activation.",
    )
    checkins_included = models.PositiveIntegerField(
        default=4,
        help_text="Weekly photo check-in quota granted upon activation.",
    )
    features = models.JSONField(
        default=list,
        blank=True,
        help_text="Bullet points displayed on frontend subscription card",
    )
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "memberships_plan"
        ordering = ["price_paisa"]

    def __str__(self):
        return f"{self.name} - NPR {self.price_npr:.2f}"

    @property
    def price_npr(self) -> float:
        """Helper returning price in rupees for display."""
        return self.price_paisa / 100.0


class MembershipStatus(models.TextChoices):
    PENDING = "pending", "Pending Payment"
    ACTIVE = "active", "Active"
    EXPIRED = "expired", "Expired"
    CANCELLED = "cancelled", "Cancelled"


class Membership(CoreBaseModel):
    """User membership instance with lifecycle state machine and live entitlement counters."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="memberships",
    )
    plan = models.ForeignKey(
        Plan,
        on_delete=models.PROTECT,
        related_name="memberships",
    )
    status = models.CharField(
        max_length=20,
        choices=MembershipStatus.choices,
        default=MembershipStatus.PENDING,
        db_index=True,
    )
    start_date = models.DateTimeField(null=True, blank=True)
    end_date = models.DateTimeField(null=True, blank=True, db_index=True)
    consultations_remaining = models.PositiveIntegerField(
        default=0,
        help_text="Live count of available consultations",
    )
    checkins_remaining = models.PositiveIntegerField(
        default=0,
        help_text="Live count of available weekly check-ins",
    )
    auto_renew = models.BooleanField(
        default=False,
        help_text="Always False: DermaCare plans are one-time payments with no auto-renewal.",
    )
    activated_at = models.DateTimeField(null=True, blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancellation_reason = models.TextField(blank=True)

    class Meta:
        db_table = "memberships_membership"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "status"]),
        ]

    def __str__(self):
        return f"Membership({self.user.email}, {self.plan.code}, {self.status})"

    @property
    def is_currently_active(self) -> bool:
        if self.status != MembershipStatus.ACTIVE:
            return False
        if self.end_date and timezone.now() >= self.end_date:
            return False
        return True

    def activate(self) -> None:
        """Transition from PENDING to ACTIVE upon verified payment receipt."""
        if self.status != MembershipStatus.PENDING:
            raise ValidationError(f"Cannot activate membership in state '{self.status}'.")

        now = timezone.now()
        self.status = MembershipStatus.ACTIVE
        self.activated_at = now
        self.start_date = now
        self.end_date = now + timedelta(days=self.plan.duration_days)
        self.consultations_remaining = self.plan.consultations_included
        self.checkins_remaining = self.plan.checkins_included
        self.save(
            update_fields=[
                "status",
                "activated_at",
                "start_date",
                "end_date",
                "consultations_remaining",
                "checkins_remaining",
                "updated_at",
            ]
        )

    def expire(self) -> None:
        """Transition from ACTIVE to EXPIRED."""
        if self.status == MembershipStatus.EXPIRED:
            return
        self.status = MembershipStatus.EXPIRED
        self.save(update_fields=["status", "updated_at"])

    def cancel(self, reason: str = "") -> None:
        """Cancel active or pending membership."""
        if self.status in (MembershipStatus.EXPIRED, MembershipStatus.CANCELLED):
            raise ValidationError(f"Cannot cancel membership in state '{self.status}'.")

        self.status = MembershipStatus.CANCELLED
        self.cancelled_at = timezone.now()
        self.cancellation_reason = reason
        self.save(update_fields=["status", "cancelled_at", "cancellation_reason", "updated_at"])

    def check_and_enforce_expiry(self) -> bool:
        """Check if active membership has reached its end_date and enforce expiry at request time."""
        if (
            self.status == MembershipStatus.ACTIVE
            and self.end_date
            and timezone.now() >= self.end_date
        ):
            self.expire()
            return True
        return False
