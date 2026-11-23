"""Views for plans, membership selection, current status, and cancellation."""

from django.core.exceptions import ValidationError as DjangoValidationError
from django.http import Http404
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import fields, permissions, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from consent.permissions import HasCurrentConsent
from memberships.models import Membership
from memberships.serializers import (
    CancelMembershipRequestSerializer,
    MembershipSerializer,
    PlanSerializer,
    SelectPlanRequestSerializer,
)
from memberships.services import (
    create_pending_membership,
    get_active_membership_with_expiry_check,
    get_active_plans,
    seed_default_plans,
)


class PlanListView(APIView):
    """List all available skincare consultation and membership plans."""

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="List Available Plans",
        description="Returns list of admin-editable plans, duration, entitlements, and price in paisa and NPR.",
        responses={200: PlanSerializer(many=True)},
        tags=["Memberships"],
    )
    def get(self, request):
        plans = get_active_plans()
        if not plans.exists():
            seed_default_plans()
            plans = get_active_plans()
        return Response(PlanSerializer(plans, many=True).data, status=status.HTTP_200_OK)


class CurrentMembershipView(APIView):
    """Retrieve current user's active membership, state, and live entitlements."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Get Active Membership",
        description="Returns currently active membership with live consultation and check-in counts. Enforces request-time expiry.",
        responses={
            200: MembershipSerializer,
            204: inline_serializer(
                name="NoActiveMembershipResponse", fields={"detail": fields.CharField()}
            ),
        },
        tags=["Memberships"],
    )
    def get(self, request):
        membership = get_active_membership_with_expiry_check(request.user)
        if not membership:
            return Response({"detail": "No active membership found."}, status=status.HTTP_200_OK)
        return Response(MembershipSerializer(membership).data, status=status.HTTP_200_OK)


class SelectPlanView(APIView):
    """Select a plan and initialize a pending membership ready for payment."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Select Plan (Checkout Init)",
        description="Selects a plan and provisions a pending membership ready for payment processing.",
        request=SelectPlanRequestSerializer,
        responses={201: MembershipSerializer},
        tags=["Memberships"],
    )
    def post(self, request):
        serializer = SelectPlanRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            membership = create_pending_membership(
                user=request.user,
                plan_code=serializer.validated_data["plan_code"],
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(MembershipSerializer(membership).data, status=status.HTTP_201_CREATED)


class CancelMembershipView(APIView):
    """Cancel a pending or active membership."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Cancel Membership",
        description="Transitions membership state to cancelled.",
        request=CancelMembershipRequestSerializer,
        responses={200: MembershipSerializer},
        tags=["Memberships"],
    )
    def post(self, request, membership_id):
        try:
            membership = Membership.objects.get(id=membership_id, user=request.user)
        except Membership.DoesNotExist as exc:
            raise Http404("Membership not found.") from exc

        serializer = CancelMembershipRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            membership.cancel(reason=serializer.validated_data.get("reason", ""))
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(MembershipSerializer(membership).data, status=status.HTTP_200_OK)


class MembershipHistoryView(APIView):
    """View complete membership history for authenticated user."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Get Membership History",
        description="Returns all historical and present memberships for current user.",
        responses={200: MembershipSerializer(many=True)},
        tags=["Memberships"],
    )
    def get(self, request):
        memberships = Membership.objects.filter(user=request.user).order_by("-created_at")
        return Response(
            MembershipSerializer(memberships, many=True).data, status=status.HTTP_200_OK
        )
