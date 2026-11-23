"""Serializers for prescriptions, medications, and weekly check-ins."""

from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from consultations.serializers import DoctorSerializer
from media_vault.services import generate_signed_photo_url
from prescriptions.models import (
    Prescription,
    WeeklyCheckIn,
)


class MedicationSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    dosage = serializers.CharField(max_length=100)
    frequency = serializers.CharField(max_length=100)
    duration = serializers.CharField(max_length=100)
    instructions = serializers.CharField(required=False, allow_blank=True, default="")
    beforeMeal = serializers.BooleanField(required=False, default=False)


class PrescriptionSerializer(serializers.ModelSerializer):
    """Prescription representation matching Flutter Prescription model."""

    id = serializers.UUIDField(read_only=True)
    doctorId = serializers.UUIDField(source="dermatologist.id", read_only=True)
    userId = serializers.UUIDField(source="patient.id", read_only=True)
    medications = MedicationSerializer(many=True)
    diagnosis = serializers.CharField()
    prescribedDate = serializers.SerializerMethodField()
    status = serializers.CharField()
    doctor = DoctorSerializer(source="dermatologist", read_only=True)
    notes = serializers.CharField()
    followUpDate = serializers.DateField(source="follow_up_date", allow_null=True)
    labTests = serializers.ListField(child=serializers.CharField(), source="lab_tests")
    version = serializers.IntegerField(read_only=True)
    isPublished = serializers.BooleanField(source="is_published", read_only=True)

    class Meta:
        model = Prescription
        fields = [
            "id",
            "doctorId",
            "userId",
            "medications",
            "diagnosis",
            "prescribedDate",
            "status",
            "doctor",
            "notes",
            "followUpDate",
            "labTests",
            "version",
            "isPublished",
        ]

    @extend_schema_field(serializers.DateTimeField())
    def get_prescribedDate(self, obj: Prescription):
        return obj.published_at or obj.created_at


class CreatePrescriptionRequestSerializer(serializers.Serializer):
    patient_id = serializers.UUIDField()
    appointment_id = serializers.UUIDField(required=False, allow_null=True)
    diagnosis = serializers.CharField(max_length=255)
    medications = MedicationSerializer(many=True)
    instructions = serializers.CharField(required=False, allow_blank=True, default="")
    notes = serializers.CharField(required=False, allow_blank=True, default="")
    follow_up_date = serializers.DateField(required=False, allow_null=True)
    lab_tests = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    publish_now = serializers.BooleanField(required=False, default=True)


class AmendPrescriptionRequestSerializer(serializers.Serializer):
    diagnosis = serializers.CharField(max_length=255, required=False)
    medications = MedicationSerializer(many=True, required=False)
    instructions = serializers.CharField(required=False, allow_blank=True)
    notes = serializers.CharField(required=False, allow_blank=True)
    follow_up_date = serializers.DateField(required=False, allow_null=True)
    lab_tests = serializers.ListField(child=serializers.CharField(), required=False)
    publish_now = serializers.BooleanField(required=False, default=True)


class WeeklyCheckInSubmissionSerializer(serializers.Serializer):
    week_number = serializers.IntegerField(min_value=1, max_value=4)
    front_photo_id = serializers.UUIDField(required=False, allow_null=True)
    left_photo_id = serializers.UUIDField(required=False, allow_null=True)
    right_photo_id = serializers.UUIDField(required=False, allow_null=True)
    patient_note = serializers.CharField(required=False, allow_blank=True, default="")


class WeeklyCheckInSerializer(serializers.ModelSerializer):
    """Weekly skin progress photo check-in representation."""

    id = serializers.UUIDField(read_only=True)
    weekNumber = serializers.IntegerField(source="week_number")
    status = serializers.CharField()
    frontPhotoUrl = serializers.SerializerMethodField()
    leftPhotoUrl = serializers.SerializerMethodField()
    rightPhotoUrl = serializers.SerializerMethodField()
    patientNote = serializers.CharField(source="patient_note")
    dermatologistFeedback = serializers.CharField(source="dermatologist_feedback")
    reviewedAt = serializers.DateTimeField(source="reviewed_at", allow_null=True)
    submittedAt = serializers.DateTimeField(source="submitted_at")

    class Meta:
        model = WeeklyCheckIn
        fields = [
            "id",
            "weekNumber",
            "status",
            "frontPhotoUrl",
            "leftPhotoUrl",
            "rightPhotoUrl",
            "patientNote",
            "dermatologistFeedback",
            "reviewedAt",
            "submittedAt",
        ]

    def _get_photo_url(self, photo):
        if not photo or not photo.image_file:
            return None
        return generate_signed_photo_url(photo, actor=photo.user, expires_in_seconds=900)

    @extend_schema_field(serializers.CharField(allow_null=True))
    def get_frontPhotoUrl(self, obj: WeeklyCheckIn):
        return self._get_photo_url(obj.front_photo)

    @extend_schema_field(serializers.CharField(allow_null=True))
    def get_leftPhotoUrl(self, obj: WeeklyCheckIn):
        return self._get_photo_url(obj.left_photo)

    @extend_schema_field(serializers.CharField(allow_null=True))
    def get_rightPhotoUrl(self, obj: WeeklyCheckIn):
        return self._get_photo_url(obj.right_photo)


class WeeklyCheckInStatusOverviewSerializer(serializers.Serializer):
    weekNumber = serializers.IntegerField()
    isUnlocked = serializers.BooleanField()
    unlockDate = serializers.DateField()
    isSubmitted = serializers.BooleanField()
    checkIn = WeeklyCheckInSerializer(allow_null=True)


class ReviewCheckInRequestSerializer(serializers.Serializer):
    feedback = serializers.CharField()
