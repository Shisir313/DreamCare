"""Admin configuration for clinical skin profiles and lifestyle measurements."""

from django.contrib import admin

from profiles.models import LifestyleProfile, SkinProfile


@admin.register(SkinProfile)
class SkinProfileAdmin(admin.ModelAdmin):
    list_display = [
        "user_email",
        "skin_type",
        "skin_tone",
        "routine_level",
        "sun_exposure",
        "created_at",
    ]
    list_filter = ["skin_type", "skin_tone", "routine_level", "sun_exposure"]
    search_fields = ["user__email", "user__name"]
    readonly_fields = ["created_at", "updated_at"]

    def user_email(self, obj):
        return obj.user.email


@admin.register(LifestyleProfile)
class LifestyleProfileAdmin(admin.ModelAdmin):
    list_display = [
        "user_email",
        "height_cm",
        "weight_kg",
        "bmi",
        "age",
        "sleep_hours",
        "created_at",
    ]
    search_fields = ["user__email", "user__name"]
    readonly_fields = ["created_at", "updated_at", "bmi"]

    def user_email(self, obj):
        return obj.user.email
