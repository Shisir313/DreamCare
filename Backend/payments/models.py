"""Models for orders, payment attempts, idempotency keys, and gateway status history."""

from django.conf import settings
from django.db import models
from django.utils import timezone

from core.models import CoreBaseModel, TimeStampedModel
from memberships.models import Membership


class GatewayChoice(models.TextChoices):
    ESEWA = "esewa", "eSewa"
    KHALTI = "khalti", "Khalti"


class OrderType(models.TextChoices):
    MEMBERSHIP = "membership", "Membership Subscription"
    CONSULTATION = "consultation", "Single Consultation Fee"


class OrderStatus(models.TextChoices):
    PENDING = "pending", "Pending Payment"
    PAID = "paid", "Paid & Verified"
    FAILED = "failed", "Failed"
    REFUNDED = "refunded", "Refunded"


class AttemptStatus(models.TextChoices):
    INITIATED = "initiated", "Initiated with Gateway"
    SUCCESS = "success", "Successfully Verified"
    FAILED = "failed", "Verification Failed"
    EXPIRED = "expired", "Session Expired"


class PaymentOrder(CoreBaseModel):
    """Customer payment order with strict integer paisa billing and client idempotency."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="payment_orders",
    )
    membership = models.ForeignKey(
        Membership,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="payment_orders",
    )
    order_type = models.CharField(
        max_length=20,
        choices=OrderType.choices,
        default=OrderType.MEMBERSHIP,
    )
    amount_paisa = models.PositiveIntegerField(
        help_text="Order amount in Nepali paisa (1 NPR = 100 paisa).",
    )
    currency = models.CharField(max_length=10, default="NPR")
    status = models.CharField(
        max_length=20,
        choices=OrderStatus.choices,
        default=OrderStatus.PENDING,
        db_index=True,
    )
    idempotency_key = models.CharField(
        max_length=100,
        unique=True,
        db_index=True,
        help_text="Client-supplied or server-generated idempotency key to prevent double charge.",
    )

    class Meta:
        db_table = "payments_order"
        ordering = ["-created_at"]

    def __str__(self):
        return f"Order {self.id} ({self.user.email}) - NPR {self.amount_npr:.2f} [{self.status}]"

    @property
    def amount_npr(self) -> float:
        return self.amount_paisa / 100.0


class PaymentAttempt(CoreBaseModel):
    """Individual checkout attempt against a specific payment gateway."""

    order = models.ForeignKey(
        PaymentOrder,
        on_delete=models.CASCADE,
        related_name="attempts",
    )
    gateway = models.CharField(
        max_length=20,
        choices=GatewayChoice.choices,
        db_index=True,
    )
    attempt_reference = models.CharField(
        max_length=150,
        unique=True,
        db_index=True,
        help_text="Gateway tracking reference (eSewa transaction_uuid or Khalti pidx)",
    )
    amount_paisa = models.PositiveIntegerField()
    status = models.CharField(
        max_length=20,
        choices=AttemptStatus.choices,
        default=AttemptStatus.INITIATED,
        db_index=True,
    )
    gateway_transaction_id = models.CharField(
        max_length=150,
        blank=True,
        null=True,
        help_text="Upstream confirmation ID returned by the gateway (e.g. ref_id from eSewa)",
    )
    gateway_payload = models.JSONField(
        default=dict,
        blank=True,
        help_text="Payload sent to or received from gateway on initiate",
    )
    gateway_response_raw = models.JSONField(
        default=dict,
        blank=True,
        help_text="Raw response received during server-to-server status lookup",
    )
    initiated_at = models.DateTimeField(default=timezone.now)
    verified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "payments_attempt"
        ordering = ["-initiated_at"]

    def __str__(self):
        return f"Attempt {self.attempt_reference} [{self.gateway}] - {self.status}"


class PaymentStatusHistory(TimeStampedModel):
    """Audit log of status changes for reconciliation and dispute tracking."""

    order = models.ForeignKey(
        PaymentOrder,
        on_delete=models.CASCADE,
        related_name="status_history",
    )
    attempt = models.ForeignKey(
        PaymentAttempt,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="status_history",
    )
    from_status = models.CharField(max_length=30)
    to_status = models.CharField(max_length=30)
    reason = models.TextField(blank=True)

    class Meta:
        db_table = "payments_status_history"
        ordering = ["-created_at"]

    def __str__(self):
        return f"Order {self.order.id}: {self.from_status} -> {self.to_status}"
