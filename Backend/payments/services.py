"""Business logic service layer for orders, checkouts, server-side verification, and reconciliation."""

import logging
import uuid
from datetime import timedelta

from django.core.exceptions import ValidationError
from django.db import transaction
from django.utils import timezone

from memberships.models import Membership, MembershipStatus
from memberships.services import activate_membership
from payments.gateways.base import BasePaymentGateway, PaymentVerificationResult
from payments.gateways.esewa import EsewaGatewayAdapter
from payments.gateways.khalti import KhaltiGatewayAdapter
from payments.models import (
    AttemptStatus,
    GatewayChoice,
    OrderStatus,
    OrderType,
    PaymentAttempt,
    PaymentOrder,
    PaymentStatusHistory,
)

logger = logging.getLogger(__name__)


def get_gateway_adapter(gateway: str) -> BasePaymentGateway:
    """Factory returning unified payment gateway adapter."""
    if gateway == GatewayChoice.ESEWA:
        return EsewaGatewayAdapter()
    if gateway == GatewayChoice.KHALTI:
        return KhaltiGatewayAdapter()
    raise ValidationError({"gateway": [f"Unsupported payment gateway '{gateway}'."]})


def create_payment_order(
    *,
    user,
    amount_paisa: int,
    order_type: str = OrderType.MEMBERSHIP,
    membership: Membership | None = None,
    idempotency_key: str | None = None,
) -> PaymentOrder:
    """Create a payment order with client/server idempotency key."""
    if not idempotency_key:
        idempotency_key = f"ord_idemp_{uuid.uuid4()}"

    # Return existing order if identical idempotency_key exists (Idempotent replay)
    existing = PaymentOrder.objects.filter(idempotency_key=idempotency_key).first()
    if existing:
        return existing

    order = PaymentOrder.objects.create(
        user=user,
        membership=membership,
        order_type=order_type,
        amount_paisa=amount_paisa,
        currency="NPR",
        status=OrderStatus.PENDING,
        idempotency_key=idempotency_key,
    )
    PaymentStatusHistory.objects.create(
        order=order,
        from_status="none",
        to_status=OrderStatus.PENDING,
        reason="Order initialized",
    )
    logger.info(
        "Payment order created: order_id=%s, user_id=%s, amount=%s", order.id, user.id, amount_paisa
    )
    return order


def initiate_payment_checkout(*, order: PaymentOrder, gateway_name: str, return_url: str) -> dict:
    """Initiate gateway checkout attempt."""
    if order.status == OrderStatus.PAID:
        raise ValidationError({"order": ["This order has already been paid and settled."]})

    adapter = get_gateway_adapter(gateway_name)
    reference = f"dc_{order.id.hex[:12]}_{timezone.now().strftime('%M%S%f')[:8]}"

    attempt = PaymentAttempt.objects.create(
        order=order,
        gateway=gateway_name,
        attempt_reference=reference,
        amount_paisa=order.amount_paisa,
        status=AttemptStatus.INITIATED,
    )

    initiate_result = adapter.initiate_payment(attempt, return_url=return_url)

    # If gateway returned custom reference (like Khalti pidx), update attempt_reference
    if "pidx" in initiate_result and initiate_result["pidx"]:
        attempt.attempt_reference = initiate_result["pidx"]

    attempt.gateway_payload = initiate_result
    attempt.save(update_fields=["attempt_reference", "gateway_payload", "updated_at"])

    PaymentStatusHistory.objects.create(
        order=order,
        attempt=attempt,
        from_status="none",
        to_status=AttemptStatus.INITIATED,
        reason=f"Checkout initiated with {gateway_name}",
    )
    return initiate_result


@transaction.atomic
def verify_payment_attempt(
    *,
    attempt_reference: str,
    callback_payload: dict | None = None,
    actor=None,
) -> tuple[bool, PaymentAttempt]:
    """Execute authoritative server-to-server gateway status check and activate resources."""
    attempt = (
        PaymentAttempt.objects.select_for_update()
        .filter(attempt_reference=attempt_reference)
        .select_related("order", "order__user", "order__membership")
        .first()
    )

    if not attempt:
        raise ValidationError(
            {"reference": [f"No payment attempt found for reference '{attempt_reference}'."]}
        )

    # 1. Replay Safety Check
    if attempt.status == AttemptStatus.SUCCESS and attempt.order.status == OrderStatus.PAID:
        logger.info(
            "Payment attempt %s already verified as SUCCESS. Replay handled safely.",
            attempt_reference,
        )
        return True, attempt

    order = attempt.order
    adapter = get_gateway_adapter(attempt.gateway)

    # 2. Server-to-server authoritative lookup query
    result: PaymentVerificationResult = adapter.verify_payment(
        attempt, callback_payload=callback_payload
    )

    # 3. Handle verification outcome
    if result.is_successful:
        # Amount match sanity check
        if result.amount_paisa != order.amount_paisa:
            attempt.status = AttemptStatus.FAILED
            attempt.gateway_response_raw = result.raw_response or {}
            attempt.save(update_fields=["status", "gateway_response_raw", "updated_at"])
            raise ValidationError({"amount": ["Amount paid does not match order amount."]})

        now = timezone.now()
        attempt.status = AttemptStatus.SUCCESS
        attempt.gateway_transaction_id = result.gateway_transaction_id
        attempt.gateway_response_raw = result.raw_response or {}
        attempt.verified_at = now
        attempt.save(
            update_fields=[
                "status",
                "gateway_transaction_id",
                "gateway_response_raw",
                "verified_at",
                "updated_at",
            ]
        )

        old_order_status = order.status
        order.status = OrderStatus.PAID
        order.save(update_fields=["status", "updated_at"])

        PaymentStatusHistory.objects.create(
            order=order,
            attempt=attempt,
            from_status=old_order_status,
            to_status=OrderStatus.PAID,
            reason=f"Payment verified via {attempt.gateway} S2S lookup (TxID: {result.gateway_transaction_id})",
        )

        # 4. Activation Flow: Activate Membership
        if order.membership and order.membership.status == MembershipStatus.PENDING:
            activate_membership(order.membership)
            logger.info(
                "Membership %s activated following verified payment %s",
                order.membership.id,
                attempt.id,
            )

        return True, attempt

    else:
        attempt.status = AttemptStatus.FAILED
        attempt.gateway_response_raw = result.raw_response or {}
        attempt.save(update_fields=["status", "gateway_response_raw", "updated_at"])

        PaymentStatusHistory.objects.create(
            order=order,
            attempt=attempt,
            from_status=order.status,
            to_status=OrderStatus.FAILED,
            reason=f"Gateway verification rejected: {result.error_message}",
        )
        return False, attempt


def reconcile_pending_payment_attempts() -> dict[str, int]:
    """Background reconciliation job for orphaned initiated attempts (Celery task)."""
    stale_time = timezone.now() - timedelta(minutes=5)
    pending_attempts = PaymentAttempt.objects.filter(
        status=AttemptStatus.INITIATED,
        initiated_at__lte=stale_time,
    ).select_related("order")

    reconciled_success = 0
    reconciled_failed = 0

    for attempt in pending_attempts:
        try:
            success, _ = verify_payment_attempt(attempt_reference=attempt.attempt_reference)
            if success:
                reconciled_success += 1
            else:
                reconciled_failed += 1
        except Exception as exc:
            logger.warning(
                "Reconciliation query failed for attempt %s: %s", attempt.attempt_reference, exc
            )

    logger.info(
        "Reconciliation complete. Success: %d, Failed/Expired: %d",
        reconciled_success,
        reconciled_failed,
    )
    return {"reconciled_success": reconciled_success, "reconciled_failed": reconciled_failed}
