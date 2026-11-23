"""Serializers for payment orders, checkouts, attempts, and verification."""

from rest_framework import serializers

from payments.models import (
    GatewayChoice,
    OrderType,
    PaymentAttempt,
    PaymentOrder,
)


class CreateOrderRequestSerializer(serializers.Serializer):
    membership_id = serializers.UUIDField(required=False)
    order_type = serializers.ChoiceField(choices=OrderType.choices, default=OrderType.MEMBERSHIP)
    amount_paisa = serializers.IntegerField(required=False, min_value=100)
    idempotency_key = serializers.CharField(required=False, max_length=100)


class PaymentOrderSerializer(serializers.ModelSerializer):
    amount_npr = serializers.FloatField(read_only=True)

    class Meta:
        model = PaymentOrder
        fields = (
            "id",
            "order_type",
            "amount_paisa",
            "amount_npr",
            "currency",
            "status",
            "membership",
            "idempotency_key",
            "created_at",
        )


class InitiateCheckoutRequestSerializer(serializers.Serializer):
    order_id = serializers.UUIDField()
    gateway = serializers.ChoiceField(choices=GatewayChoice.choices)
    return_url = serializers.URLField(default="https://dermacare.np/payment/callback")


class VerifyPaymentRequestSerializer(serializers.Serializer):
    attempt_reference = serializers.CharField(
        max_length=150, help_text="eSewa transaction_uuid or Khalti pidx"
    )
    callback_payload = serializers.DictField(required=False, default=dict)


class PaymentAttemptSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentAttempt
        fields = (
            "id",
            "gateway",
            "attempt_reference",
            "amount_paisa",
            "status",
            "gateway_transaction_id",
            "initiated_at",
            "verified_at",
        )


class PaymentVerificationResponseSerializer(serializers.Serializer):
    is_verified = serializers.BooleanField()
    order_status = serializers.CharField()
    attempt = PaymentAttemptSerializer()
