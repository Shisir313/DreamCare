"""Models for recommendation rules, routines, daily tasks, hydration, and reminders."""

from django.conf import settings
from django.db import models
from django.utils import timezone

from core.models import CoreBaseModel, TimeStampedModel


class TaskPeriod(models.TextChoices):
    MORNING = "morning", "Morning (AM)"
    EVENING = "evening", "Evening (PM)"


class RecommendationRule(TimeStampedModel):
    """Versioned clinical recommendation rule mapping skin attributes to advisory routines."""

    version = models.CharField(
        max_length=20, default="1.0", help_text="Rule version (e.g. 1.0, 1.1)"
    )
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)

    # Condition criteria (stored as data criteria, not hardcoded if-chains)
    target_skin_types = models.JSONField(
        default=list,
        help_text="Matching skin types: dry, oily, combination, normal, sensitive",
    )
    target_concerns = models.JSONField(
        default=list,
        blank=True,
        help_text="Matching skin concerns: acne, darkSpots, wrinkles, redness, dryness, oiliness",
    )
    routine_level = models.CharField(
        max_length=20, blank=True, help_text="beginner, intermediate, advanced"
    )

    # Advisory content & template
    am_steps = models.JSONField(
        default=list, help_text="Morning routine task items: title, instructions"
    )
    pm_steps = models.JSONField(
        default=list, help_text="Evening routine task items: title, instructions"
    )
    advisory_notes = models.TextField(
        default="Advisory routine based on your submitted profile (pending dermatologist review).",
        help_text="Clinical guidance notes explicitly marked pending dermatologist review",
    )

    class Meta:
        db_table = "routines_recommendation_rule"
        ordering = ["-version", "name"]

    def __str__(self):
        return f"{self.name} (v{self.version})"


class UserRoutine(CoreBaseModel):
    """Active personalized skincare routine assigned to a patient."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="routines",
    )
    rule = models.ForeignKey(
        RecommendationRule,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="assigned_routines",
    )
    title = models.CharField(max_length=255, default="Personalized Skincare Routine")
    is_active = models.BooleanField(default=True)
    disclaimer = models.TextField(
        default="Advisory recommendation only. Not a medical diagnosis. Pending dermatologist review.",
    )

    class Meta:
        db_table = "routines_user_routine"
        ordering = ["-created_at"]

    def __str__(self):
        return f"UserRoutine({self.user.email}, {self.title})"


class RoutineTask(CoreBaseModel):
    """Individual routine task (AM or PM step)."""

    routine = models.ForeignKey(
        UserRoutine,
        on_delete=models.CASCADE,
        related_name="tasks",
    )
    period = models.CharField(
        max_length=10,
        choices=TaskPeriod.choices,
        default=TaskPeriod.MORNING,
        db_index=True,
    )
    order = models.PositiveIntegerField(default=1)
    step_name = models.CharField(
        max_length=100, help_text="e.g. Cleanser, Toner, Moisturizer, Sunscreen"
    )
    instructions = models.TextField(help_text="Application guidance and technique")
    product_type = models.CharField(max_length=100, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "routines_routine_task"
        ordering = ["period", "order"]

    def __str__(self):
        return f"{self.period.upper()} Step {self.order}: {self.step_name}"


class RoutineTaskLog(TimeStampedModel):
    """Daily completion log for a specific routine task in Asia/Kathmandu."""

    task = models.ForeignKey(
        RoutineTask,
        on_delete=models.CASCADE,
        related_name="logs",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="task_logs",
    )
    log_date = models.DateField(db_index=True, help_text="Calendar date in Asia/Kathmandu")
    completed_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = "routines_routine_task_log"
        unique_together = ("task", "log_date")
        ordering = ["-log_date"]

    def __str__(self):
        return f"Log: {self.user.email} completed {self.task.step_name} on {self.log_date}"


class HydrationGoal(TimeStampedModel):
    """User hydration target calculated using scientific formula with limitations disclaimer."""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="hydration_goal",
    )
    daily_goal_ml = models.PositiveIntegerField(
        default=2000, help_text="Target milliliters per day"
    )
    daily_goal_glasses = models.PositiveIntegerField(
        default=8, help_text="Equivalent in 250ml glasses"
    )
    formula_citation = models.CharField(
        max_length=255,
        default="EFSA (European Food Safety Authority) & WHO: ~30-35 mL fluid intake per kg body weight.",
    )
    limitations_disclaimer = models.TextField(
        default=(
            "Estimate only. Individual fluid requirements vary depending on physical activity, "
            "ambient temperature/humidity, diet, pregnancy, lactation, and underlying health conditions."
        ),
    )

    class Meta:
        db_table = "routines_hydration_goal"

    def __str__(self):
        return f"HydrationGoal({self.user.email}: {self.daily_goal_ml}ml / {self.daily_goal_glasses} glasses)"


class WaterIntakeLog(CoreBaseModel):
    """Log record of water intake events."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="water_logs",
    )
    log_date = models.DateField(db_index=True, help_text="Calendar date in Asia/Kathmandu")
    glasses = models.PositiveIntegerField(default=1)
    milliliters = models.PositiveIntegerField(default=250)
    logged_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = "routines_water_intake_log"
        ordering = ["logged_at"]

    def __str__(self):
        return f"{self.user.email} drank {self.glasses} glass(es) on {self.log_date}"


class ReminderPreference(TimeStampedModel):
    """User reminder time preferences for routines and hydration."""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="reminder_preferences",
    )
    morning_routine_time = models.TimeField(default="08:00:00")
    evening_routine_time = models.TimeField(default="21:00:00")
    water_reminders_enabled = models.BooleanField(default=True)
    water_interval_hours = models.PositiveIntegerField(default=2)

    class Meta:
        db_table = "routines_reminder_preference"

    def __str__(self):
        return f"Reminders({self.user.email})"
