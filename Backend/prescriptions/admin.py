"""Admin configuration for prescriptions, audit logs, and weekly check-ins."""

from django.contrib import admin

from prescriptions.models import (
    Prescription,
    PrescriptionAccessAuditLog,
    WeeklyCheckIn,
)


@admin.register(Prescription)
class PrescriptionAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "diagnosis",
        "patient_email",
        "dermatologist_name",
        "version",
        "is_published",
        "status",
        "created_at",
    ]
    list_filter = ["is_published", "status", "version"]
    search_fields = [
        "diagnosis",
        "patient__email",
        "patient__name",
        "dermatologist__user__name",
        "dermatologist__user__email",
    ]
    readonly_fields = ["created_at", "updated_at", "published_at"]

    def patient_email(self, obj):
        return obj.patient.email

    def dermatologist_name(self, obj):
        return obj.dermatologist.user.get_full_name()


@admin.register(PrescriptionAccessAuditLog)
class PrescriptionAccessAuditLogAdmin(admin.ModelAdmin):
    list_display = ["prescription_id", "user_email", "accessed_at", "ip_hash"]
    search_fields = ["prescription__id", "user__email"]
    readonly_fields = ["prescription", "user", "accessed_at", "ip_hash", "user_agent_hash"]

    def user_email(self, obj):
        return obj.user.email

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False


@admin.register(WeeklyCheckIn)
class WeeklyCheckInAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "patient_email",
        "membership_plan",
        "week_number",
        "status",
        "submitted_at",
        "reviewed_at",
    ]
    list_filter = ["week_number", "status"]
    search_fields = ["patient__email", "patient__name"]

    def patient_email(self, obj):
        return obj.patient.email

    def membership_plan(self, obj):
        return obj.membership.plan.name
