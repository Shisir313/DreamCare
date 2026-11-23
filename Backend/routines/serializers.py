"""Serializers for routines, tasks, hydration goals, and reminders."""

from rest_framework import serializers

from routines.models import (
    HydrationGoal,
    ReminderPreference,
    RoutineTask,
    UserRoutine,
)


class RoutineTaskSerializer(serializers.ModelSerializer):
    is_completed = serializers.BooleanField(default=False, read_only=True)

    class Meta:
        model = RoutineTask
        fields = (
            "id",
            "period",
            "order",
            "step_name",
            "instructions",
            "product_type",
            "is_completed",
        )


class UserRoutineSerializer(serializers.ModelSerializer):
    tasks = RoutineTaskSerializer(many=True, read_only=True)

    class Meta:
        model = UserRoutine
        fields = (
            "id",
            "title",
            "disclaimer",
            "is_active",
            "tasks",
            "created_at",
        )


class ToggleTaskResponseSerializer(serializers.Serializer):
    task_id = serializers.UUIDField()
    is_completed = serializers.BooleanField()
    date = serializers.DateField()


class HydrationGoalSerializer(serializers.ModelSerializer):
    class Meta:
        model = HydrationGoal
        fields = (
            "daily_goal_ml",
            "daily_goal_glasses",
            "formula_citation",
            "limitations_disclaimer",
            "updated_at",
        )
        read_only_fields = ("updated_at",)


class CalculateHydrationRequestSerializer(serializers.Serializer):
    weight_kg = serializers.FloatField(required=False, min_value=20, max_value=300)


class LogWaterIntakeRequestSerializer(serializers.Serializer):
    glasses = serializers.IntegerField(default=1, min_value=1, max_value=20)


class ReminderPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReminderPreference
        fields = (
            "morning_routine_time",
            "evening_routine_time",
            "water_reminders_enabled",
            "water_interval_hours",
        )
