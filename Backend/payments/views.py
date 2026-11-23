"""Views for payment order creation, checkout initiation, verification, and webhooks."""

from django.core.exceptions import ValidationError as DjangoValidationError
from django.http import Http404
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import fields, permissions, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from consent.permissions import HasCurrentConsent
from memberships.models import Membership
from payments.models import PaymentOrder
from payments.serializers import (
    CreateOrderRequestSerializer,
    InitiateCheckoutRequestSerializer,
    PaymentOrderSerializer,
    PaymentVerificationResponseSerializer,
    VerifyPaymentRequestSerializer,
)
from payments.services import (
    create_payment_order,
    initiate_payment_checkout,
    verify_payment_attempt,
)


class CreateOrderView(APIView):
    """Create a payment order with client idempotency key."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Create Payment Order",
        description="Creates an order for a pending membership or consultation fee in integer paisa.",
        request=CreateOrderRequestSerializer,
        responses={201: PaymentOrderSerializer},
        tags=["Payments"],
    )
    def post(self, request):
        serializer = CreateOrderRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        membership = None
        membership_id = serializer.validated_data.get("membership_id")
        if membership_id:
            try:
                membership = Membership.objects.get(id=membership_id, user=request.user)
            except Membership.DoesNotExist as exc:
                raise ValidationError({"membership_id": ["Membership not found."]}) from exc
            amount_paisa = membership.plan.price_paisa
        else:
            amount_paisa = serializer.validated_data.get("amount_paisa")
            if not amount_paisa:
                raise ValidationError(
                    {"amount_paisa": ["amount_paisa is required when membership_id is not given."]}
                )

        order = create_payment_order(
            user=request.user,
            amount_paisa=amount_paisa,
            order_type=serializer.validated_data.get("order_type"),
            membership=membership,
            idempotency_key=serializer.validated_data.get("idempotency_key"),
        )
        return Response(PaymentOrderSerializer(order).data, status=status.HTTP_201_CREATED)


class InitiateCheckoutView(APIView):
    """Initiate checkout payload or URL for eSewa or Khalti."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Initiate Gateway Checkout",
        description="Generates eSewa signed HMAC form fields or Khalti pidx token and payment URL.",
        request=InitiateCheckoutRequestSerializer,
        responses={
            200: inline_serializer(
                name="CheckoutInitiateResponse",
                fields={
                    "gateway": fields.CharField(),
                    "amount_npr": fields.FloatField(),
                    "form_fields": fields.DictField(required=False),
                    "payment_url": fields.URLField(required=False),
                },
            )
        },
        tags=["Payments"],
    )
    def post(self, request):
        serializer = InitiateCheckoutRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            order = PaymentOrder.objects.get(
                id=serializer.validated_data["order_id"], user=request.user
            )
        except PaymentOrder.DoesNotExist as exc:
            raise Http404("Payment order not found.") from exc

        try:
            checkout_data = initiate_payment_checkout(
                order=order,
                gateway_name=serializer.validated_data["gateway"],
                return_url=serializer.validated_data["return_url"],
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(checkout_data, status=status.HTTP_200_OK)


class VerifyPaymentView(APIView):
    """Authoritative server-to-server payment status lookup triggered by client completion."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Verify Payment (Server-to-Server)",
        description="Performs authoritative S2S status check against gateway API. Activates membership upon success.",
        request=VerifyPaymentRequestSerializer,
        responses={200: PaymentVerificationResponseSerializer},
        tags=["Payments"],
    )
    def post(self, request):
        serializer = VerifyPaymentRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            is_success, attempt = verify_payment_attempt(
                attempt_reference=serializer.validated_data["attempt_reference"],
                callback_payload=serializer.validated_data.get("callback_payload"),
                actor=request.user,
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        http_code = status.HTTP_200_OK if is_success else status.HTTP_400_BAD_REQUEST
        return Response(
            {
                "is_verified": is_success,
                "order_status": attempt.order.status,
                "attempt": {
                    "id": attempt.id,
                    "gateway": attempt.gateway,
                    "attempt_reference": attempt.attempt_reference,
                    "amount_paisa": attempt.amount_paisa,
                    "status": attempt.status,
                    "gateway_transaction_id": attempt.gateway_transaction_id,
                    "initiated_at": attempt.initiated_at,
                    "verified_at": attempt.verified_at,
                },
            },
            status=http_code,
        )


class GatewayWebhookView(APIView):
    """Replay-safe webhook handler for gateway asynchronous notifications."""

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Payment Gateway Webhook",
        description="Receives gateway IPN/webhook. Queries gateway status API authoritatively.",
        request=inline_serializer(
            name="GatewayWebhookRequest",
            fields={
                "transaction_uuid": fields.CharField(required=False),
                "pidx": fields.CharField(required=False),
            },
        ),
        responses={
            200: inline_serializer(
                name="GatewayWebhookResponse",
                fields={
                    "status": fields.CharField(),
                    "is_verified": fields.BooleanField(),
                },
            )
        },
        tags=["Payments"],
    )
    def post(self, request, gateway):
        reference = (
            request.data.get("transaction_uuid")
            or request.data.get("pidx")
            or request.query_params.get("pidx")
        )
        if not reference:
            return Response(
                {"error": "Missing transaction reference"}, status=status.HTTP_400_BAD_REQUEST
            )

        try:
            is_success, attempt = verify_payment_attempt(
                attempt_reference=reference,
                callback_payload=request.data,
            )
        except Exception as exc:
            return Response({"error": str(exc)}, status=status.HTTP_400_BAD_REQUEST)

        return Response(
            {"status": "received", "is_verified": is_success}, status=status.HTTP_200_OK
        )


class OrderDetailView(APIView):
    """Retrieve payment order status and attempts."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Get Payment Order Details",
        description="Returns order status and history of payment attempts.",
        responses={200: PaymentOrderSerializer},
        tags=["Payments"],
    )
    def get(self, request, order_id):
        try:
            order = PaymentOrder.objects.get(id=order_id, user=request.user)
        except PaymentOrder.DoesNotExist as exc:
            raise Http404("Payment order not found.") from exc

        return Response(PaymentOrderSerializer(order).data, status=status.HTTP_200_OK)
