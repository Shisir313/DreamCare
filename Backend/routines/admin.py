"""Admin configuration for recommendation rules, routines, and hydration."""

from django.contrib import admin

from routines.models import (
    HydrationGoal,
    RecommendationRule,
    ReminderPreference,
    RoutineTask,
    RoutineTaskLog,
    UserRoutine,
    WaterIntakeLog,
)


class RoutineTaskInline(admin.TabularInline):
    model = RoutineTask
    extra = 0


@admin.register(RecommendationRule)
class RecommendationRuleAdmin(admin.ModelAdmin):
    list_display = ["name", "version", "routine_level", "is_active", "created_at"]
    list_filter = ["is_active", "version", "routine_level"]
    search_fields = ["name", "description"]


@admin.register(UserRoutine)
class UserRoutineAdmin(admin.ModelAdmin):
    list_display = ["id", "user_email", "title", "rule_name", "is_active", "created_at"]
    list_filter = ["is_active", "created_at"]
    search_fields = ["user__email", "user__name", "title"]
    inlines = [RoutineTaskInline]

    def user_email(self, obj):
        return obj.user.email

    def rule_name(self, obj):
        return obj.rule.name if obj.rule else "-"


@admin.register(HydrationGoal)
class HydrationGoalAdmin(admin.ModelAdmin):
    list_display = ["user_email", "daily_goal_ml", "daily_goal_glasses", "created_at"]
    search_fields = ["user__email", "user__name"]

    def user_email(self, obj):
        return obj.user.email


@admin.register(WaterIntakeLog)
class WaterIntakeLogAdmin(admin.ModelAdmin):
    list_display = ["user_email", "glasses", "milliliters", "log_date", "logged_at"]
    list_filter = ["log_date"]
    search_fields = ["user__email", "user__name"]

    def user_email(self, obj):
        return obj.user.email


@admin.register(RoutineTaskLog)
class RoutineTaskLogAdmin(admin.ModelAdmin):
    list_display = ["user_email", "task_name", "log_date", "completed_at"]
    list_filter = ["log_date"]
    search_fields = ["user__email", "user__name", "task__step_name"]

    def user_email(self, obj):
        return obj.user.email

    def task_name(self, obj):
        return obj.task.step_name


@admin.register(ReminderPreference)
class ReminderPreferenceAdmin(admin.ModelAdmin):
    list_display = [
        "user_email",
        "morning_routine_time",
        "evening_routine_time",
        "water_reminders_enabled",
    ]
    search_fields = ["user__email", "user__name"]

    def user_email(self, obj):
        return obj.user.email
