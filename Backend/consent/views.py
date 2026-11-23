"""Views for listing policies and submitting user consent."""

from django.core.exceptions import ValidationError as DjangoValidationError
from drf_spectacular.utils import extend_schema
from rest_framework import permissions, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from consent.models import ConsentPolicy, ConsentRecord
from consent.serializers import (
    AcceptConsentRequestSerializer,
    ConsentPolicySerializer,
    ConsentStatusResponseSerializer,
)
from consent.services import (
    check_user_has_current_consent,
    get_active_policies,
    record_user_consents,
)


class ListPoliciesView(APIView):
    """List active consent policies, noting whether the current user has accepted them."""

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="List Active Consent Policies",
        description="Returns list of all active policies, their versions, legal summaries, and user acceptance status.",
        responses={200: ConsentPolicySerializer(many=True)},
        tags=["Consent"],
    )
    def get(self, request):
        policies = get_active_policies()
        serializer = ConsentPolicySerializer(policies, many=True, context={"request": request})
        return Response(serializer.data, status=status.HTTP_200_OK)


class AcceptConsentView(APIView):
    """Submit acceptance for one or more versioned policies."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Accept Policies",
        description="Records acceptance of specific policy types and versions. Stores cryptographic hash of IP and UA.",
        request=AcceptConsentRequestSerializer,
        responses={200: ConsentStatusResponseSerializer},
        tags=["Consent"],
    )
    def post(self, request):
        serializer = AcceptConsentRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            record_user_consents(
                user=request.user,
                consents=serializer.validated_data["consents"],
                request=request,
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        has_consent = check_user_has_current_consent(request.user)
        active_mandatory = ConsentPolicy.objects.filter(is_active=True, is_mandatory=True)
        missing = []
        for pol in active_mandatory:
            if not ConsentRecord.objects.filter(
                user=request.user,
                policy_type=pol.policy_type,
                policy_version=pol.version,
            ).exists():
                missing.append(pol)

        response_data = {
            "has_current_consent": has_consent,
            "missing_policies": ConsentPolicySerializer(
                missing, many=True, context={"request": request}
            ).data,
        }
        return Response(response_data, status=status.HTTP_200_OK)


class ConsentStatusView(APIView):
    """Retrieve the current user's consent status and any pending policies."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Check User Consent Status",
        description="Returns whether the user has satisfied all mandatory active policy requirements.",
        responses={200: ConsentStatusResponseSerializer},
        tags=["Consent"],
    )
    def get(self, request):
        has_consent = check_user_has_current_consent(request.user)
        active_mandatory = ConsentPolicy.objects.filter(is_active=True, is_mandatory=True)
        missing = [
            pol
            for pol in active_mandatory
            if not ConsentRecord.objects.filter(
                user=request.user,
                policy_type=pol.policy_type,
                policy_version=pol.version,
            ).exists()
        ]

        response_data = {
            "has_current_consent": has_consent,
            "missing_policies": ConsentPolicySerializer(
                missing, many=True, context={"request": request}
            ).data,
        }
        return Response(response_data, status=status.HTTP_200_OK)
