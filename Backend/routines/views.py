"""Views for routines, tasks, hydration, and daily progress summaries."""

from django.http import Http404
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import fields, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from consent.permissions import HasCurrentConsent
from routines.models import HydrationGoal, ReminderPreference, UserRoutine
from routines.serializers import (
    CalculateHydrationRequestSerializer,
    HydrationGoalSerializer,
    LogWaterIntakeRequestSerializer,
    ReminderPreferenceSerializer,
    ToggleTaskResponseSerializer,
    UserRoutineSerializer,
)
from routines.services import (
    calculate_and_set_hydration_goal,
    evaluate_rules_for_user,
    get_daily_summary,
    get_local_kathmandu_date,
    log_water_intake,
    toggle_routine_task,
)


class GenerateRoutineView(APIView):
    """Evaluate versioned recommendation rules and provision user routine."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Generate Personalized Routine",
        description="Evaluates versioned rules against patient's skin and lifestyle profiles to create AM/PM routine.",
        request=None,
        responses={201: UserRoutineSerializer},
        tags=["Routines"],
    )
    def post(self, request):
        routine = evaluate_rules_for_user(request.user)
        return Response(UserRoutineSerializer(routine).data, status=status.HTTP_201_CREATED)


class CurrentRoutineView(APIView):
    """Retrieve current active routine with task completion flags for today."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Get Current Active Routine",
        description="Returns currently active routine and tasks for the user.",
        responses={200: UserRoutineSerializer},
        tags=["Routines"],
    )
    def get(self, request):
        routine = (
            UserRoutine.objects.filter(user=request.user, is_active=True)
            .prefetch_related("tasks")
            .first()
        )
        if not routine:
            routine = evaluate_rules_for_user(request.user)

        return Response(UserRoutineSerializer(routine).data, status=status.HTTP_200_OK)


class ToggleTaskView(APIView):
    """Toggle routine task completion for today's calendar date in Asia/Kathmandu."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Toggle Routine Task Completion",
        description="Checks off or unchecks a routine task for today in Asia/Kathmandu.",
        request=None,
        responses={200: ToggleTaskResponseSerializer},
        tags=["Routines"],
    )
    def post(self, request, task_id):
        try:
            today_nepal = get_local_kathmandu_date()
            is_completed, task = toggle_routine_task(
                user=request.user,
                task_id=task_id,
                target_date=today_nepal,
            )
        except Exception as exc:
            raise Http404("Routine task not found.") from exc

        return Response(
            {
                "task_id": task.id,
                "is_completed": is_completed,
                "date": today_nepal,
            },
            status=status.HTTP_200_OK,
        )


class DailySummaryView(APIView):
    """Aggregated daily progress summary for home dashboard."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Get Daily Progress Summary",
        description="Returns daily routine task completion and hydration progress in Asia/Kathmandu.",
        responses={
            200: inline_serializer(
                name="DailySummaryResponse",
                fields={
                    "date": fields.CharField(),
                    "routine": fields.DictField(),
                    "hydration": fields.DictField(),
                },
            )
        },
        tags=["Routines"],
    )
    def get(self, request):
        summary = get_daily_summary(request.user)
        return Response(summary, status=status.HTTP_200_OK)


class HydrationGoalView(APIView):
    """Retrieve current user's hydration target and scientific citation."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Get Hydration Target",
        description="Returns target ml, glasses, and clinical calculation limitations disclaimer.",
        responses={200: HydrationGoalSerializer},
        tags=["Hydration"],
    )
    def get(self, request):
        goal, _ = HydrationGoal.objects.get_or_create(
            user=request.user,
            defaults={"daily_goal_ml": 2000, "daily_goal_glasses": 8},
        )
        return Response(HydrationGoalSerializer(goal).data, status=status.HTTP_200_OK)


class CalculateHydrationGoalView(APIView):
    """Calculate and set hydration target using weight formula."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Recalculate Hydration Goal",
        description="Calculates recommended fluid intake based on weight in kg (35 mL/kg).",
        request=CalculateHydrationRequestSerializer,
        responses={200: HydrationGoalSerializer},
        tags=["Hydration"],
    )
    def post(self, request):
        serializer = CalculateHydrationRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        weight_kg = serializer.validated_data.get("weight_kg")
        goal = calculate_and_set_hydration_goal(request.user, weight_kg=weight_kg)
        return Response(HydrationGoalSerializer(goal).data, status=status.HTTP_200_OK)


class LogWaterIntakeView(APIView):
    """Log water intake (+1 glass / 250ml)."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Log Water Intake",
        description="Records consumed water glasses for today.",
        request=LogWaterIntakeRequestSerializer,
        responses={
            201: inline_serializer(
                name="LogWaterResponse",
                fields={"status": fields.CharField(), "glassesLogged": fields.IntegerField()},
            )
        },
        tags=["Hydration"],
    )
    def post(self, request):
        serializer = LogWaterIntakeRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        glasses = serializer.validated_data.get("glasses", 1)
        log_water_intake(user=request.user, glasses=glasses)
        return Response(
            {"status": "success", "glassesLogged": glasses}, status=status.HTTP_201_CREATED
        )


class TodayWaterIntakeView(APIView):
    """Retrieve today's water tracking model matching Flutter's WaterTracking format."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    @extend_schema(
        summary="Get Today's Water Tracking",
        description="Returns glasses completed, goal, progress, and intake timestamps for Flutter.",
        responses={
            200: inline_serializer(
                name="TodayWaterResponse",
                fields={
                    "date": fields.CharField(),
                    "glassesCompleted": fields.IntegerField(),
                    "dailyGoal": fields.IntegerField(),
                    "timestamps": fields.ListField(),
                },
            )
        },
        tags=["Hydration"],
    )
    def get(self, request):
        summary = get_daily_summary(request.user)
        hyd = summary["hydration"]
        response_data = {
            "date": summary["date"],
            "glassesCompleted": hyd["glassesCompleted"],
            "dailyGoal": hyd["dailyGoal"],
            "timestamps": hyd["timestamps"],
        }
        return Response(response_data, status=status.HTTP_200_OK)


class ReminderPreferencesView(APIView):
    """Get or update routine and hydration reminder time preferences."""

    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]
    serializer_class = ReminderPreferenceSerializer

    @extend_schema(
        summary="Get Reminder Preferences",
        description="Returns user reminder notification times for AM/PM routines and hydration.",
        responses={200: ReminderPreferenceSerializer},
        tags=["Routines"],
    )
    def get(self, request):
        pref, _ = ReminderPreference.objects.get_or_create(user=request.user)
        return Response(ReminderPreferenceSerializer(pref).data, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Update Reminder Preferences",
        description="Updates reminder times and hydration alert intervals.",
        request=ReminderPreferenceSerializer,
        responses={200: ReminderPreferenceSerializer},
        tags=["Routines"],
    )
    def put(self, request):
        pref, _ = ReminderPreference.objects.get_or_create(user=request.user)
        serializer = ReminderPreferenceSerializer(pref, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)
