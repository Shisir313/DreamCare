"""URL routing for routines and hydration."""

from django.urls import path

from routines.views import (
    CalculateHydrationGoalView,
    CurrentRoutineView,
    DailySummaryView,
    GenerateRoutineView,
    HydrationGoalView,
    LogWaterIntakeView,
    ReminderPreferencesView,
    TodayWaterIntakeView,
    ToggleTaskView,
)

app_name = "routines"

urlpatterns = [
    # Routines & Daily Tracking
    path("generate/", GenerateRoutineView.as_view(), name="generate_routine"),
    path("current/", CurrentRoutineView.as_view(), name="current_routine"),
    path("tasks/<uuid:task_id>/toggle/", ToggleTaskView.as_view(), name="toggle_task"),
    path("daily-summary/", DailySummaryView.as_view(), name="daily_summary"),
    path("reminders/", ReminderPreferencesView.as_view(), name="reminder_preferences"),
    # Hydration
    path("hydration/goal/", HydrationGoalView.as_view(), name="hydration_goal"),
    path(
        "hydration/goal/calculate/",
        CalculateHydrationGoalView.as_view(),
        name="calculate_hydration_goal",
    ),
    path("hydration/log/", LogWaterIntakeView.as_view(), name="log_water_intake"),
    path("hydration/today/", TodayWaterIntakeView.as_view(), name="today_water"),
]
