"""Views for prescriptions, audits, and weekly photo check-ins."""

from django.core.exceptions import PermissionDenied, ValidationError as DjangoValidationError
from django.http import Http404
from drf_spectacular.utils import extend_schema
from rest_framework import permissions, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import UserRole
from consent.permissions import HasCurrentConsent
from prescriptions.models import Prescription, WeeklyCheckIn
from prescriptions.serializers import (
    AmendPrescriptionRequestSerializer,
    CreatePrescriptionRequestSerializer,
    PrescriptionSerializer,
    ReviewCheckInRequestSerializer,
    WeeklyCheckInSerializer,
    WeeklyCheckInStatusOverviewSerializer,
    WeeklyCheckInSubmissionSerializer,
)
from prescriptions.services import (
    amend_prescription,
    create_prescription,
    get_weekly_checkin_schedule,
    log_prescription_access,
    publish_prescription,
    review_weekly_checkin,
    submit_weekly_checkin,
)


class PrescriptionListCreateView(APIView):
    """List or create clinical prescriptions."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="List Prescriptions",
        description="Returns list of prescriptions for current patient or authoring doctor.",
        responses={200: PrescriptionSerializer(many=True)},
        tags=["Prescriptions"],
    )
    def get(self, request):
        if request.user.role == UserRole.DERMATOLOGIST and hasattr(
            request.user, "dermatologist_profile"
        ):
            qs = Prescription.objects.filter(
                dermatologist=request.user.dermatologist_profile
            ).select_related("dermatologist__user", "patient")
        else:
            qs = Prescription.objects.filter(
                patient=request.user,
                is_published=True,
            ).select_related("dermatologist__user", "patient")

        return Response(PrescriptionSerializer(qs, many=True).data, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Create Prescription",
        description="Authored exclusively by verified dermatologists.",
        request=CreatePrescriptionRequestSerializer,
        responses={201: PrescriptionSerializer},
        tags=["Prescriptions"],
    )
    def post(self, request):
        serializer = CreatePrescriptionRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            prescription = create_prescription(
                doctor_user=request.user,
                patient_id=serializer.validated_data["patient_id"],
                appointment_id=serializer.validated_data.get("appointment_id"),
                diagnosis=serializer.validated_data["diagnosis"],
                medications=serializer.validated_data["medications"],
                instructions=serializer.validated_data.get("instructions", ""),
                notes=serializer.validated_data.get("notes", ""),
                follow_up_date=serializer.validated_data.get("follow_up_date"),
                lab_tests=serializer.validated_data.get("lab_tests", []),
                publish_now=serializer.validated_data.get("publish_now", True),
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(PrescriptionSerializer(prescription).data, status=status.HTTP_201_CREATED)


class PrescriptionDetailView(APIView):
    """Retrieve prescription details with audited access."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Get Prescription Details",
        description="Retrieves prescription details. Logs read audit record when accessed by patient.",
        responses={200: PrescriptionSerializer},
        tags=["Prescriptions"],
    )
    def get(self, request, prescription_id):
        try:
            prescription = Prescription.objects.select_related(
                "dermatologist__user", "patient"
            ).get(id=prescription_id)
        except Prescription.DoesNotExist as exc:
            raise Http404("Prescription not found.") from exc

        is_patient = request.user.id == prescription.patient.id
        is_doctor = (
            hasattr(request.user, "dermatologist_profile")
            and request.user.dermatologist_profile.id == prescription.dermatologist.id
        )
        if not (is_patient or is_doctor or request.user.is_staff):
            raise PermissionDenied("You are not authorized to view this prescription.")

        # Audit log patient access
        if is_patient:
            log_prescription_access(prescription=prescription, user=request.user, request=request)

        return Response(PrescriptionSerializer(prescription).data, status=status.HTTP_200_OK)


class PublishPrescriptionView(APIView):
    """Publish a draft prescription."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Publish Prescription",
        description="Locks clinical contents permanently as an immutable record.",
        request=None,
        responses={200: PrescriptionSerializer},
        tags=["Prescriptions"],
    )
    def post(self, request, prescription_id):
        try:
            prescription = publish_prescription(
                prescription_id=prescription_id,
                doctor_user=request.user,
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(PrescriptionSerializer(prescription).data, status=status.HTTP_200_OK)


class AmendPrescriptionView(APIView):
    """Create a versioned amendment to a published prescription."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Amend Prescription",
        description="Creates version v+1 amendment while retaining the published historical record.",
        request=AmendPrescriptionRequestSerializer,
        responses={201: PrescriptionSerializer},
        tags=["Prescriptions"],
    )
    def post(self, request, prescription_id):
        serializer = AmendPrescriptionRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            new_prescription = amend_prescription(
                prescription_id=prescription_id,
                doctor_user=request.user,
                amendments=serializer.validated_data,
                publish_now=serializer.validated_data.get("publish_now", True),
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(
            PrescriptionSerializer(new_prescription).data, status=status.HTTP_201_CREATED
        )


class WeeklyCheckInStatusView(APIView):
    """Check-in 4-week unlock schedule and status."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Weekly Check-in Status",
        description="Returns 4-week unlock schedule, unlock dates in Asia/Kathmandu, and submission status.",
        responses={200: WeeklyCheckInStatusOverviewSerializer(many=True)},
        tags=["Check-ins"],
    )
    def get(self, request):
        schedule = get_weekly_checkin_schedule(user=request.user)
        return Response(
            WeeklyCheckInStatusOverviewSerializer(schedule, many=True).data,
            status=status.HTTP_200_OK,
        )


class WeeklyCheckInSubmitView(APIView):
    """Submit weekly photo progress check-in."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Submit Weekly Check-in",
        description="Uploads front, left, and right photos + optional note. Consumes check-in entitlement.",
        request=WeeklyCheckInSubmissionSerializer,
        responses={201: WeeklyCheckInSerializer},
        tags=["Check-ins"],
    )
    def post(self, request):
        serializer = WeeklyCheckInSubmissionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            checkin = submit_weekly_checkin(
                user=request.user,
                week_number=serializer.validated_data["week_number"],
                front_photo_id=serializer.validated_data.get("front_photo_id"),
                left_photo_id=serializer.validated_data.get("left_photo_id"),
                right_photo_id=serializer.validated_data.get("right_photo_id"),
                patient_note=serializer.validated_data.get("patient_note", ""),
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(WeeklyCheckInSerializer(checkin).data, status=status.HTTP_201_CREATED)


class WeeklyCheckInHistoryView(APIView):
    """View historical check-ins (accessible even after membership expiry)."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Check-in History",
        description="View past check-ins and clinical feedbacks. Unlocked permanently even after plan expiry.",
        responses={200: WeeklyCheckInSerializer(many=True)},
        tags=["Check-ins"],
    )
    def get(self, request):
        checkins = WeeklyCheckIn.objects.filter(patient=request.user).order_by("week_number")
        return Response(
            WeeklyCheckInSerializer(checkins, many=True).data, status=status.HTTP_200_OK
        )


class ReviewCheckInView(APIView):
    """Dermatologist reviews weekly check-in."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Review Weekly Check-in",
        description="Dermatologist reviews photos and submits clinical guidance.",
        request=ReviewCheckInRequestSerializer,
        responses={200: WeeklyCheckInSerializer},
        tags=["Check-ins"],
    )
    def post(self, request, checkin_id):
        serializer = ReviewCheckInRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            checkin = review_weekly_checkin(
                checkin_id=checkin_id,
                doctor_user=request.user,
                feedback=serializer.validated_data["feedback"],
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(WeeklyCheckInSerializer(checkin).data, status=status.HTTP_200_OK)
