"""Serializers for skin and lifestyle profiles."""

from rest_framework import serializers

from profiles.models import LifestyleProfile, SkinProfile


class SkinProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = SkinProfile
        fields = (
            "id",
            "skin_type",
            "skin_tone",
            "conditions",
            "concerns",
            "goals",
            "routine_level",
            "sun_exposure",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")


class LifestyleProfileSerializer(serializers.ModelSerializer):
    bmi = serializers.FloatField(read_only=True)
    bmi_category = serializers.CharField(read_only=True)

    class Meta:
        model = LifestyleProfile
        fields = (
            "id",
            "height_cm",
            "weight_kg",
            "age",
            "sleep_hours",
            "stress_level",
            "activity_level",
            "bmi",
            "bmi_category",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "bmi", "bmi_category", "created_at", "updated_at")

    def validate_height_cm(self, value):
        if value is not None and (value < 50 or value > 250):
            raise serializers.ValidationError("Height must be between 50 cm and 250 cm.")
        return value

    def validate_weight_kg(self, value):
        if value is not None and (value < 20 or value > 300):
            raise serializers.ValidationError("Weight must be between 20 kg and 300 kg.")
        return value
