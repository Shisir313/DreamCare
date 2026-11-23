"""Admin configuration for dermatologist profiles, availability slots, and appointments."""

from django.contrib import admin

from consultations.models import (
    Appointment,
    AvailabilitySlot,
    DermatologistProfile,
)


@admin.register(DermatologistProfile)
class DermatologistProfileAdmin(admin.ModelAdmin):
    list_display = [
        "user_email",
        "user_full_name",
        "nmc_number",
        "specialty",
        "is_verified",
        "experience_years",
        "rating",
        "consultation_fee_paisa",
    ]
    list_filter = ["is_verified", "specialty"]
    search_fields = ["user__email", "user__name", "nmc_number", "hospital"]
    actions = ["verify_dermatologists", "unverify_dermatologists"]

    def user_email(self, obj):
        return obj.user.email

    def user_full_name(self, obj):
        return obj.user.get_full_name()

    @admin.action(description="Verify selected dermatologists")
    def verify_dermatologists(self, request, queryset):
        queryset.update(is_verified=True)

    @admin.action(description="Unverify selected dermatologists")
    def unverify_dermatologists(self, request, queryset):
        queryset.update(is_verified=False)


@admin.register(AvailabilitySlot)
class AvailabilitySlotAdmin(admin.ModelAdmin):
    list_display = ["dermatologist_name", "start_time", "end_time", "is_booked"]
    list_filter = ["is_booked", "start_time"]
    search_fields = ["dermatologist__user__name", "dermatologist__user__email"]

    def dermatologist_name(self, obj):
        return obj.dermatologist.user.get_full_name()


@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "patient_email",
        "dermatologist_name",
        "slot_time",
        "status",
        "appointment_type",
        "fee_paisa",
        "room_channel",
    ]
    list_filter = ["status", "appointment_type", "created_at"]
    search_fields = [
        "patient__email",
        "patient__name",
        "dermatologist__user__name",
        "room_channel",
    ]
    readonly_fields = ["room_channel", "created_at", "updated_at"]

    def patient_email(self, obj):
        return obj.patient.email

    def dermatologist_name(self, obj):
        return obj.dermatologist.user.get_full_name()

    def slot_time(self, obj):
        return obj.slot.start_time
