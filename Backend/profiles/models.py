"""Models for user skin profiles, lifestyle attributes, and physical measurements."""

from django.conf import settings
from django.db import models

from core.models import CoreBaseModel


class SkinType(models.TextChoices):
    DRY = "dry", "Dry"
    OILY = "oily", "Oily"
    COMBINATION = "combination", "Combination"
    NORMAL = "normal", "Normal"
    SENSITIVE = "sensitive", "Sensitive"


class SkinTone(models.TextChoices):
    FAIR = "fair", "Fair (Fitzpatrick I-II)"
    MEDIUM = "medium", "Medium (Fitzpatrick III-IV)"
    OLIVE = "olive", "Olive (Fitzpatrick IV-V)"
    DEEP = "deep", "Deep (Fitzpatrick V-VI)"


class RoutineLevel(models.TextChoices):
    BEGINNER = "beginner", "Beginner (1-2 steps)"
    INTERMEDIATE = "intermediate", "Intermediate (3-4 steps)"
    ADVANCED = "advanced", "Advanced (5+ steps)"


class SunExposure(models.TextChoices):
    LOW = "low", "Low (< 1 hour daily)"
    MODERATE = "moderate", "Moderate (1-3 hours daily)"
    HIGH = "high", "High (3+ hours daily)"


class StressLevel(models.TextChoices):
    LOW = "low", "Low"
    MODERATE = "moderate", "Moderate"
    HIGH = "high", "High"


class ActivityLevel(models.TextChoices):
    SEDENTARY = "sedentary", "Sedentary"
    LIGHT = "light", "Light (1-2 days/week)"
    MODERATE = "moderate", "Moderate (3-4 days/week)"
    ACTIVE = "active", "Active (5+ days/week)"


class SkinProfile(CoreBaseModel):
    """Clinical skin profile captured during onboarding and updated over time."""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="skin_profile",
    )
    skin_type = models.CharField(
        max_length=20,
        choices=SkinType.choices,
        default=SkinType.COMBINATION,
        help_text="Primary skin classification",
    )
    skin_tone = models.CharField(
        max_length=20,
        choices=SkinTone.choices,
        default=SkinTone.MEDIUM,
        help_text="Fitzpatrick skin tone estimate",
    )
    conditions = models.JSONField(
        default=list,
        blank=True,
        help_text="Reported clinical conditions (e.g. eczema, psoriasis, rosacea, acne)",
    )
    concerns = models.JSONField(
        default=list,
        blank=True,
        help_text="Primary concerns (e.g. acne, darkSpots, wrinkles, redness, dryness, oiliness)",
    )
    goals = models.JSONField(
        default=list,
        blank=True,
        help_text="User goals (e.g. clearSkin, evenTone, hydration, oilControl)",
    )
    routine_level = models.CharField(
        max_length=20,
        choices=RoutineLevel.choices,
        default=RoutineLevel.BEGINNER,
        help_text="Preferred complexity of daily routine",
    )
    sun_exposure = models.CharField(
        max_length=20,
        choices=SunExposure.choices,
        default=SunExposure.MODERATE,
        help_text="Daily UV/sunlight exposure level",
    )

    class Meta:
        db_table = "profiles_skin_profile"
        verbose_name = "Skin Profile"
        verbose_name_plural = "Skin Profiles"

    def __str__(self):
        return f"SkinProfile({self.user.email}, {self.skin_type})"


class LifestyleProfile(CoreBaseModel):
    """Lifestyle factors and physical measurements for personalized skincare guidance."""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="lifestyle_profile",
    )
    height_cm = models.FloatField(
        null=True,
        blank=True,
        help_text="Height in centimetres",
    )
    weight_kg = models.FloatField(
        null=True,
        blank=True,
        help_text="Weight in kilograms",
    )
    age = models.PositiveIntegerField(
        null=True,
        blank=True,
        help_text="Age in years (derived or reported)",
    )
    sleep_hours = models.PositiveIntegerField(
        default=7,
        help_text="Average hours of sleep per night",
    )
    stress_level = models.CharField(
        max_length=20,
        choices=StressLevel.choices,
        default=StressLevel.MODERATE,
    )
    activity_level = models.CharField(
        max_length=20,
        choices=ActivityLevel.choices,
        default=ActivityLevel.LIGHT,
    )

    class Meta:
        db_table = "profiles_lifestyle_profile"
        verbose_name = "Lifestyle Profile"
        verbose_name_plural = "Lifestyle Profiles"

    def __str__(self):
        return f"LifestyleProfile({self.user.email}, BMI: {self.bmi})"

    @property
    def bmi(self) -> float | None:
        """Compute Body Mass Index (BMI = kg / m^2) server-side."""
        if not self.height_cm or not self.weight_kg or self.height_cm <= 0:
            return None
        height_m = self.height_cm / 100.0
        return round(self.weight_kg / (height_m * height_m), 1)

    @property
    def bmi_category(self) -> str | None:
        """Categorize BMI according to WHO standards."""
        bmi_val = self.bmi
        if bmi_val is None:
            return None
        if bmi_val < 18.5:
            return "underweight"
        if bmi_val < 25.0:
            return "normal"
        if bmi_val < 30.0:
            return "overweight"
        return "obese"
