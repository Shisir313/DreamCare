"""Views for doctor profiles, availability slots, appointment booking, rescheduling, and video tokens."""

from django.core.exceptions import PermissionDenied, ValidationError as DjangoValidationError
from django.db.models import Q
from django.http import Http404
from django.utils import timezone
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import permissions, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import UserRole
from consent.permissions import HasCurrentConsent
from consultations.models import (
    Appointment,
    AvailabilitySlot,
    DermatologistProfile,
)
from consultations.serializers import (
    AppointmentSerializer,
    BookAppointmentRequestSerializer,
    CancelAppointmentRequestSerializer,
    CreateSlotRequestSerializer,
    DoctorSerializer,
    RescheduleAppointmentRequestSerializer,
    TimeSlotSerializer,
    VideoTokenResponseSerializer,
)
from consultations.services import (
    book_appointment,
    cancel_appointment,
    generate_video_token_for_appointment,
    reschedule_appointment,
)


class DoctorListView(APIView):
    """List verified dermatologists and specialists for consultation."""

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="List Verified Doctors",
        description="Returns list of administrative-verified dermatologists. Supports specialty and search query filters.",
        parameters=[
            OpenApiParameter(
                name="specialty",
                description="Filter by specialty (e.g. dermatologist, cosmetologist)",
                required=False,
                type=str,
            ),
            OpenApiParameter(
                name="search",
                description="Search by name, qualifications, or hospital",
                required=False,
                type=str,
            ),
        ],
        responses={200: DoctorSerializer(many=True)},
        tags=["Consultations"],
    )
    def get(self, request):
        queryset = DermatologistProfile.objects.filter(is_verified=True).select_related("user")

        specialty = request.query_params.get("specialty")
        if specialty:
            queryset = queryset.filter(specialty=specialty)

        search = request.query_params.get("search")
        if search:
            queryset = queryset.filter(
                Q(user__name__icontains=search)
                | Q(qualifications__icontains=search)
                | Q(hospital__icontains=search)
            )

        serializer = DoctorSerializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class DoctorDetailView(APIView):
    """Retrieve detailed doctor profile."""

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Get Doctor Profile Details",
        description="Returns full profile of a verified doctor including fees, languages, and qualifications.",
        responses={200: DoctorSerializer},
        tags=["Consultations"],
    )
    def get(self, request, doctor_id):
        try:
            doctor = DermatologistProfile.objects.select_related("user").get(
                id=doctor_id,
                is_verified=True,
            )
        except DermatologistProfile.DoesNotExist as exc:
            raise Http404("Doctor not found or not currently verified.") from exc

        return Response(DoctorSerializer(doctor).data, status=status.HTTP_200_OK)


class DoctorSlotsView(APIView):
    """List available time slots for a doctor on a specific date."""

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="List Doctor Available Slots",
        description="Returns available unbooked slots for a doctor on a date in Asia/Kathmandu.",
        parameters=[
            OpenApiParameter(
                name="date",
                description="Date in YYYY-MM-DD format (Asia/Kathmandu)",
                required=False,
                type=str,
            ),
        ],
        responses={200: TimeSlotSerializer(many=True)},
        tags=["Consultations"],
    )
    def get(self, request, doctor_id):
        try:
            doctor = DermatologistProfile.objects.get(id=doctor_id, is_verified=True)
        except DermatologistProfile.DoesNotExist as exc:
            raise Http404("Doctor not found.") from exc

        date_str = request.query_params.get("date")
        if date_str:
            try:
                target_date = timezone.datetime.strptime(date_str, "%Y-%m-%d").date()
            except ValueError:
                target_date = timezone.localdate()
        else:
            target_date = timezone.localdate()

        slots = AvailabilitySlot.objects.filter(
            dermatologist=doctor,
            start_time__date=target_date,
            is_booked=False,
        ).order_by("start_time")

        return Response(TimeSlotSerializer(slots, many=True).data, status=status.HTTP_200_OK)


class CreateSlotView(APIView):
    """Create availability slots (dermatologists and admins only)."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Create Availability Slot",
        description="Doctor creates a consultation availability slot.",
        request=CreateSlotRequestSerializer,
        responses={201: TimeSlotSerializer},
        tags=["Consultations"],
    )
    def post(self, request):
        if request.user.role != UserRole.DERMATOLOGIST and not request.user.is_staff:
            raise PermissionDenied("Only registered dermatologists can create availability slots.")

        try:
            doctor = request.user.dermatologist_profile
        except DermatologistProfile.DoesNotExist as exc:
            raise ValidationError({"user": ["Dermatologist profile does not exist."]}) from exc

        serializer = CreateSlotRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        slot, _ = AvailabilitySlot.objects.get_or_create(
            dermatologist=doctor,
            start_time=serializer.validated_data["start_time"],
            defaults={"end_time": serializer.validated_data["end_time"]},
        )

        return Response(TimeSlotSerializer(slot).data, status=status.HTTP_201_CREATED)


class BookAppointmentView(APIView):
    """Book consultation appointment using active membership entitlement."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Book Appointment",
        description="Atomically locks slot and decrements consultation entitlement from active membership.",
        request=BookAppointmentRequestSerializer,
        responses={201: AppointmentSerializer},
        tags=["Consultations"],
    )
    def post(self, request):
        serializer = BookAppointmentRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            appointment = book_appointment(
                patient=request.user,
                slot_id=serializer.validated_data["slot_id"],
                appointment_type=serializer.validated_data.get("type", "video"),
                symptoms=serializer.validated_data.get("symptoms", ""),
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(AppointmentSerializer(appointment).data, status=status.HTTP_201_CREATED)


class AppointmentListView(APIView):
    """List appointments for authenticated patient or doctor."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="List Appointments",
        description="Returns list of consultation appointments for the current user.",
        responses={200: AppointmentSerializer(many=True)},
        tags=["Consultations"],
    )
    def get(self, request):
        if request.user.role == UserRole.DERMATOLOGIST and hasattr(
            request.user, "dermatologist_profile"
        ):
            appointments = Appointment.objects.filter(
                dermatologist=request.user.dermatologist_profile
            ).select_related("slot", "patient", "dermatologist__user")
        else:
            appointments = Appointment.objects.filter(patient=request.user).select_related(
                "slot", "patient", "dermatologist__user"
            )

        return Response(
            AppointmentSerializer(appointments, many=True).data, status=status.HTTP_200_OK
        )


class AppointmentDetailView(APIView):
    """Retrieve individual appointment details."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Get Appointment Details",
        description="Returns appointment metadata, status, symptoms, and doctor info.",
        responses={200: AppointmentSerializer},
        tags=["Consultations"],
    )
    def get(self, request, appointment_id):
        try:
            appointment = Appointment.objects.select_related(
                "slot", "patient", "dermatologist__user"
            ).get(id=appointment_id)
        except Appointment.DoesNotExist as exc:
            raise Http404("Appointment not found.") from exc

        is_patient = request.user.id == appointment.patient.id
        is_doctor = (
            hasattr(request.user, "dermatologist_profile")
            and request.user.dermatologist_profile.id == appointment.dermatologist.id
        )
        if not (is_patient or is_doctor or request.user.is_staff):
            raise PermissionDenied("You are not authorized to view this appointment.")

        return Response(AppointmentSerializer(appointment).data, status=status.HTTP_200_OK)


class CancelAppointmentView(APIView):
    """Cancel scheduled appointment."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Cancel Appointment",
        description="Cancels appointment, releases availability slot, and restores entitlement if > 2h before start.",
        request=CancelAppointmentRequestSerializer,
        responses={200: AppointmentSerializer},
        tags=["Consultations"],
    )
    def post(self, request, appointment_id):
        serializer = CancelAppointmentRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            appointment = cancel_appointment(
                appointment_id=appointment_id,
                user=request.user,
                reason=serializer.validated_data.get("reason", ""),
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(AppointmentSerializer(appointment).data, status=status.HTTP_200_OK)


class RescheduleAppointmentView(APIView):
    """Reschedule confirmed appointment to a new slot."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Reschedule Appointment",
        description="Atomically swaps to a new slot with the same doctor.",
        request=RescheduleAppointmentRequestSerializer,
        responses={200: AppointmentSerializer},
        tags=["Consultations"],
    )
    def post(self, request, appointment_id):
        serializer = RescheduleAppointmentRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            appointment = reschedule_appointment(
                appointment_id=appointment_id,
                new_slot_id=serializer.validated_data["new_slot_id"],
                user=request.user,
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(AppointmentSerializer(appointment).data, status=status.HTTP_200_OK)


class AppointmentVideoTokenView(APIView):
    """Issue short-lived Agora RTC video consultation room token."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Generate Agora Video Room Token",
        description="Issues temporary RTC token. Enforces join window (15 minutes prior to appointment start time).",
        request=None,
        responses={200: VideoTokenResponseSerializer},
        tags=["Consultations"],
    )
    def post(self, request, appointment_id):
        try:
            token_data = generate_video_token_for_appointment(
                appointment_id=appointment_id,
                user=request.user,
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(token_data, status=status.HTTP_200_OK)
