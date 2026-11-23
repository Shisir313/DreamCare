"""Serializers for consultations, doctors, slots, appointments, and video tokens."""

from django.utils import timezone
from rest_framework import serializers

from consultations.models import (
    Appointment,
    AppointmentType,
    AvailabilitySlot,
    DermatologistProfile,
)


class DoctorSerializer(serializers.ModelSerializer):
    """Doctor representation matching Flutter Doctor model."""

    id = serializers.UUIDField(read_only=True)
    name = serializers.SerializerMethodField()
    specialty = serializers.CharField()
    qualifications = serializers.CharField()
    experience = serializers.IntegerField(source="experience_years")
    rating = serializers.FloatField()
    totalReviews = serializers.IntegerField(source="total_reviews")
    consultationFee = serializers.IntegerField(source="fee_npr")
    consultationFeePaisa = serializers.IntegerField(source="consultation_fee_paisa")
    availableDays = serializers.SerializerMethodField()
    photoUrl = serializers.CharField(source="photo_url")
    hospital = serializers.CharField()
    about = serializers.CharField()
    languages = serializers.ListField(child=serializers.CharField())
    isAvailableToday = serializers.SerializerMethodField()
    isVerified = serializers.BooleanField(source="is_verified")

    class Meta:
        model = DermatologistProfile
        fields = [
            "id",
            "name",
            "specialty",
            "qualifications",
            "experience",
            "rating",
            "totalReviews",
            "consultationFee",
            "consultationFeePaisa",
            "availableDays",
            "photoUrl",
            "hospital",
            "about",
            "languages",
            "isAvailableToday",
            "isVerified",
        ]

    def get_name(self, obj: DermatologistProfile) -> str:
        full_name = obj.user.get_full_name()
        if not full_name:
            full_name = obj.user.email.split("@")[0].title()
        return f"Dr. {full_name}" if not full_name.startswith("Dr.") else full_name

    def get_availableDays(self, obj: DermatologistProfile) -> list[int]:
        # Days 1=Monday through 7=Sunday
        return [1, 2, 3, 4, 5, 6]

    def get_isAvailableToday(self, obj: DermatologistProfile) -> bool:
        today = timezone.localdate()
        return obj.slots.filter(
            start_time__date=today,
            is_booked=False,
        ).exists()


class TimeSlotSerializer(serializers.ModelSerializer):
    """Time slot representation matching Flutter TimeSlot model."""

    id = serializers.UUIDField(read_only=True)
    startTime = serializers.DateTimeField(source="start_time")
    endTime = serializers.DateTimeField(source="end_time")
    isAvailable = serializers.SerializerMethodField()
    timeRange = serializers.SerializerMethodField()

    class Meta:
        model = AvailabilitySlot
        fields = ["id", "startTime", "endTime", "isAvailable", "timeRange"]

    def get_isAvailable(self, obj: AvailabilitySlot) -> bool:
        return not obj.is_booked

    def get_timeRange(self, obj: AvailabilitySlot) -> str:
        local_start = timezone.localtime(obj.start_time)
        local_end = timezone.localtime(obj.end_time)
        return f"{local_start.strftime('%H:%M')} - {local_end.strftime('%H:%M')}"


class CreateSlotRequestSerializer(serializers.Serializer):
    start_time = serializers.DateTimeField()
    end_time = serializers.DateTimeField()

    def validate(self, attrs):
        if attrs["end_time"] <= attrs["start_time"]:
            raise serializers.ValidationError({"end_time": "End time must be after start time."})
        return attrs


class BookAppointmentRequestSerializer(serializers.Serializer):
    slot_id = serializers.UUIDField()
    type = serializers.ChoiceField(
        choices=AppointmentType.choices,
        default=AppointmentType.VIDEO,
    )
    symptoms = serializers.CharField(required=False, allow_blank=True, default="")


class RescheduleAppointmentRequestSerializer(serializers.Serializer):
    new_slot_id = serializers.UUIDField()


class CancelAppointmentRequestSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True, default="")


class AppointmentSerializer(serializers.ModelSerializer):
    """Appointment model matching Flutter Appointment representation."""

    id = serializers.UUIDField(read_only=True)
    doctorId = serializers.UUIDField(source="dermatologist.id", read_only=True)
    userId = serializers.UUIDField(source="patient.id", read_only=True)
    dateTime = serializers.DateTimeField(source="slot.start_time", read_only=True)
    type = serializers.CharField(source="appointment_type")
    status = serializers.CharField()
    fee = serializers.IntegerField(source="fee_npr", read_only=True)
    feePaisa = serializers.IntegerField(source="fee_paisa", read_only=True)
    doctor = DoctorSerializer(source="dermatologist", read_only=True)
    symptoms = serializers.CharField()
    notes = serializers.CharField()
    roomChannel = serializers.CharField(source="room_channel", read_only=True)
    createdAt = serializers.DateTimeField(source="created_at", read_only=True)

    class Meta:
        model = Appointment
        fields = [
            "id",
            "doctorId",
            "userId",
            "dateTime",
            "type",
            "status",
            "fee",
            "feePaisa",
            "doctor",
            "symptoms",
            "notes",
            "roomChannel",
            "createdAt",
        ]


class VideoTokenResponseSerializer(serializers.Serializer):
    roomChannel = serializers.CharField()
    token = serializers.CharField()
    appId = serializers.CharField()
    uid = serializers.IntegerField()
    expiresIn = serializers.IntegerField()
