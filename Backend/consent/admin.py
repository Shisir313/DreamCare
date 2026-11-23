"""Django admin configuration for consent app."""

from django.contrib import admin

from consent.models import ConsentPolicy, ConsentRecord


@admin.register(ConsentPolicy)
class ConsentPolicyAdmin(admin.ModelAdmin):
    list_display = ("policy_type", "version", "title", "is_mandatory", "is_active", "created_at")
    list_filter = ("policy_type", "is_mandatory", "is_active")
    search_fields = ("title", "version", "summary")
    ordering = ("policy_type", "-version")


@admin.register(ConsentRecord)
class ConsentRecordAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "policy_type",
        "policy_version",
        "accepted_at",
        "ip_hash",
        "user_agent_hash",
    )
    list_filter = ("policy_type", "policy_version")
    search_fields = ("user__email", "user__phone", "ip_hash")
    readonly_fields = (
        "user",
        "policy_type",
        "policy_version",
        "accepted_at",
        "ip_hash",
        "user_agent_hash",
    )
    ordering = ("-accepted_at",)

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False
