"""Admin configuration for plans and memberships."""

from django.contrib import admin

from memberships.models import Membership, Plan


@admin.register(Plan)
class PlanAdmin(admin.ModelAdmin):
    list_display = [
        "code",
        "name",
        "price_npr",
        "duration_days",
        "consultations_included",
        "checkins_included",
        "is_active",
    ]
    list_filter = ["is_active", "code"]
    search_fields = ["code", "name", "description"]
    readonly_fields = ["created_at", "updated_at"]

    def price_npr(self, obj):
        return f"Rs {obj.price_paisa // 100} ({obj.price_paisa} paisa)"


@admin.register(Membership)
class MembershipAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "user_email",
        "plan_name",
        "status",
        "consultations_remaining",
        "checkins_remaining",
        "start_date",
        "end_date",
    ]
    list_filter = ["status", "plan__code", "created_at"]
    search_fields = ["user__email", "user__name", "id"]
    readonly_fields = ["created_at", "updated_at"]

    def user_email(self, obj):
        return obj.user.email

    def plan_name(self, obj):
        return obj.plan.name
