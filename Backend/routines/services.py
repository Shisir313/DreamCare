"""Business logic service layer for recommendation rule engine, routines, and hydration."""

import logging
import math

from django.db import transaction
from django.utils import timezone

from profiles.models import SkinProfile
from routines.models import (
    HydrationGoal,
    RecommendationRule,
    RoutineTask,
    RoutineTaskLog,
    TaskPeriod,
    UserRoutine,
    WaterIntakeLog,
)

logger = logging.getLogger(__name__)


def get_local_kathmandu_date(dt=None):
    """Return calendar date in Asia/Kathmandu timezone (UTC+5:45)."""
    if dt is None:
        dt = timezone.now()
    return timezone.localtime(dt).date()


def seed_default_recommendation_rules():
    """Seed baseline versioned recommendation rules marked pending dermatologist review."""
    rules_data = [
        {
            "name": "Oily & Acne-Prone Guidance Template",
            "version": "1.0",
            "description": "Advisory routine for oily skin prone to excess sebum and acne breakouts.",
            "target_skin_types": ["oily", "combination"],
            "target_concerns": ["acne", "oiliness", "largePores"],
            "routine_level": "beginner",
            "am_steps": [
                {
                    "order": 1,
                    "step_name": "Cleanser",
                    "instructions": "Wash face with a gentle foaming cleanser containing salicylic acid (pending dermatologist review).",
                    "product_type": "Foaming Cleanser",
                },
                {
                    "order": 2,
                    "step_name": "Toner",
                    "instructions": "Apply alcohol-free hydrating toner with niacinamide (pending dermatologist review).",
                    "product_type": "Balancing Toner",
                },
                {
                    "order": 3,
                    "step_name": "Moisturizer",
                    "instructions": "Apply lightweight, non-comedogenic oil-free gel moisturizer (pending dermatologist review).",
                    "product_type": "Gel Moisturizer",
                },
                {
                    "order": 4,
                    "step_name": "Sunscreen",
                    "instructions": "Apply broad-spectrum matte sunscreen SPF 50 (pending dermatologist review).",
                    "product_type": "Matte SPF 50",
                },
            ],
            "pm_steps": [
                {
                    "order": 1,
                    "step_name": "Cleanser",
                    "instructions": "Double cleanse gently to remove sunscreen, pollution, and excess sebum (pending dermatologist review).",
                    "product_type": "Gentle Cleanser",
                },
                {
                    "order": 2,
                    "step_name": "Treatment",
                    "instructions": "Apply mild spot/serum treatment as advised (pending dermatologist review).",
                    "product_type": "Exfoliating Serum",
                },
                {
                    "order": 3,
                    "step_name": "Night Cream",
                    "instructions": "Seal with lightweight soothing barrier night cream (pending dermatologist review).",
                    "product_type": "Light Night Cream",
                },
            ],
            "advisory_notes": (
                "Placeholder advisory recommendation: focuses on oil reduction and gentle pore clarity. "
                "All guidance is pending licensed dermatologist review."
            ),
        },
        {
            "name": "Dry & Sensitive Barrier Template",
            "version": "1.0",
            "description": "Advisory routine for dry, reactive, or eczema-prone skin.",
            "target_skin_types": ["dry", "sensitive"],
            "target_concerns": ["dryness", "redness", "sensitivity"],
            "routine_level": "beginner",
            "am_steps": [
                {
                    "order": 1,
                    "step_name": "Cleanser",
                    "instructions": "Wash with non-foaming hydrating milk cleanser (pending dermatologist review).",
                    "product_type": "Hydrating Milk Cleanser",
                },
                {
                    "order": 2,
                    "step_name": "Moisturizer",
                    "instructions": "Apply rich ceramide barrier cream generously (pending dermatologist review).",
                    "product_type": "Barrier Cream",
                },
                {
                    "order": 3,
                    "step_name": "Sunscreen",
                    "instructions": "Apply mineral physical sunscreen SPF 50+ (pending dermatologist review).",
                    "product_type": "Mineral Sunscreen SPF 50",
                },
            ],
            "pm_steps": [
                {
                    "order": 1,
                    "step_name": "Cleanser",
                    "instructions": "Gently cleanse with lukewarm water and cream cleanser (pending dermatologist review).",
                    "product_type": "Cream Cleanser",
                },
                {
                    "order": 2,
                    "step_name": "Treatment",
                    "instructions": "Apply soothing cica / hyaluronic acid serum (pending dermatologist review).",
                    "product_type": "Soothing Serum",
                },
                {
                    "order": 3,
                    "step_name": "Night Cream",
                    "instructions": "Apply deep moisture barrier seal (pending dermatologist review).",
                    "product_type": "Intense Barrier Cream",
                },
            ],
            "advisory_notes": (
                "Placeholder advisory recommendation: focuses on lipid barrier replenishment and redness reduction. "
                "All guidance is pending licensed dermatologist review."
            ),
        },
        {
            "name": "Balanced Daily Protection Template",
            "version": "1.0",
            "description": "Balanced baseline routine for normal/combination skin.",
            "target_skin_types": ["normal", "combination"],
            "target_concerns": ["dullness", "evenTone"],
            "routine_level": "beginner",
            "am_steps": [
                {
                    "order": 1,
                    "step_name": "Cleanser",
                    "instructions": "Gentle daily cleanse with lukewarm water (pending dermatologist review).",
                    "product_type": "Daily Cleanser",
                },
                {
                    "order": 2,
                    "step_name": "Moisturizer",
                    "instructions": "Hydrating antioxidant daily lotion (pending dermatologist review).",
                    "product_type": "Daily Lotion",
                },
                {
                    "order": 3,
                    "step_name": "Sunscreen",
                    "instructions": "Broad-spectrum SPF 50 (pending dermatologist review).",
                    "product_type": "SPF 50",
                },
            ],
            "pm_steps": [
                {
                    "order": 1,
                    "step_name": "Cleanser",
                    "instructions": "Remove daytime impurities and sunscreen (pending dermatologist review).",
                    "product_type": "Gentle Cleanser",
                },
                {
                    "order": 2,
                    "step_name": "Night Cream",
                    "instructions": "Nourishing night moisturizer (pending dermatologist review).",
                    "product_type": "Night Moisturizer",
                },
            ],
            "advisory_notes": (
                "Placeholder advisory recommendation for maintenance and daily protection. "
                "All guidance is pending licensed dermatologist review."
            ),
        },
    ]

    for data in rules_data:
        RecommendationRule.objects.get_or_create(
            name=data["name"],
            version=data["version"],
            defaults=data,
        )


@transaction.atomic
def evaluate_rules_for_user(user) -> UserRoutine:
    """Evaluate database recommendation rules against user skin profile and generate routine."""
    skin_profile, _ = SkinProfile.objects.get_or_create(user=user)

    # 1. Match from active versioned rules in DB
    rules = RecommendationRule.objects.filter(is_active=True).order_by("-version")
    selected_rule = None

    user_skin_type = skin_profile.skin_type
    user_concerns = set(skin_profile.concerns or [])

    # Score candidate rules
    best_score = -1
    for rule in rules:
        score = 0
        if user_skin_type in rule.target_skin_types:
            score += 10
        matching_concerns = user_concerns.intersection(set(rule.target_concerns or []))
        score += len(matching_concerns) * 5

        if score > best_score:
            best_score = score
            selected_rule = rule

    if not selected_rule:
        seed_default_recommendation_rules()
        selected_rule = RecommendationRule.objects.filter(is_active=True).first()

    # 2. Deactivate existing routines for this user
    UserRoutine.objects.filter(user=user, is_active=True).update(is_active=False)

    # 3. Create new routine
    routine = UserRoutine.objects.create(
        user=user,
        rule=selected_rule,
        title=f"Custom Routine ({selected_rule.name})",
        is_active=True,
        disclaimer=(
            f"Advisory educational guidance derived from Rule v{selected_rule.version}. "
            "Not a medical diagnosis. Pending dermatologist review."
        ),
    )

    # 4. Generate AM tasks
    for item in selected_rule.am_steps:
        RoutineTask.objects.create(
            routine=routine,
            period=TaskPeriod.MORNING,
            order=item.get("order", 1),
            step_name=item.get("step_name", "Step"),
            instructions=item.get("instructions", ""),
            product_type=item.get("product_type", ""),
        )

    # 5. Generate PM tasks
    for item in selected_rule.pm_steps:
        RoutineTask.objects.create(
            routine=routine,
            period=TaskPeriod.EVENING,
            order=item.get("order", 1),
            step_name=item.get("step_name", "Step"),
            instructions=item.get("instructions", ""),
            product_type=item.get("product_type", ""),
        )

    logger.info("Routine generated for user_id=%s using rule=%s", user.id, selected_rule.id)
    return routine


def calculate_and_set_hydration_goal(user, weight_kg: float | None = None) -> HydrationGoal:
    """Calculate and persist hydration goal based on EFSA/WHO weight-based guidelines.

    Formula: 35 mL per kg body weight (reference: European Food Safety Authority / WHO fluid recommendations).
    """
    if weight_kg is None:
        if hasattr(user, "lifestyle_profile") and user.lifestyle_profile.weight_kg:
            weight_kg = user.lifestyle_profile.weight_kg
        else:
            weight_kg = 60.0  # Population average baseline fallback

    # Compute target milliliters
    target_ml = round(weight_kg * 35)
    # 250ml per standard glass
    target_glasses = max(4, math.ceil(target_ml / 250))

    goal, _ = HydrationGoal.objects.update_or_create(
        user=user,
        defaults={
            "daily_goal_ml": target_ml,
            "daily_goal_glasses": target_glasses,
            "formula_citation": (
                f"Calculated at 35 mL/kg based on {weight_kg}kg body weight "
                "(EFSA Scientific Opinion on Dietary Reference Values for Water)."
            ),
            "limitations_disclaimer": (
                "Individual fluid requirements vary based on Nepal's climate/elevation, "
                "daily physical exertion, and clinical conditions. Consult a physician."
            ),
        },
    )
    return goal


def toggle_routine_task(*, user, task_id, target_date=None) -> tuple[bool, RoutineTask]:
    """Check-off or uncheck a routine task for the calendar date in Asia/Kathmandu."""
    if target_date is None:
        target_date = get_local_kathmandu_date()

    task = RoutineTask.objects.get(id=task_id, routine__user=user, is_active=True)

    log = RoutineTaskLog.objects.filter(task=task, user=user, log_date=target_date).first()
    if log:
        log.delete()
        is_completed = False
    else:
        RoutineTaskLog.objects.create(task=task, user=user, log_date=target_date)
        is_completed = True

    return is_completed, task


def log_water_intake(*, user, glasses: int = 1, target_date=None) -> WaterIntakeLog:
    """Record water intake event in Asia/Kathmandu."""
    if target_date is None:
        target_date = get_local_kathmandu_date()

    log = WaterIntakeLog.objects.create(
        user=user,
        log_date=target_date,
        glasses=glasses,
        milliliters=glasses * 250,
        logged_at=timezone.now(),
    )
    return log


def get_daily_summary(user, target_date=None) -> dict:
    """Aggregate progress: routine steps completed and water intake for the given date."""
    if target_date is None:
        target_date = get_local_kathmandu_date()

    # 1. Routine progress
    active_routine = (
        UserRoutine.objects.filter(user=user, is_active=True).prefetch_related("tasks").first()
    )
    if not active_routine:
        active_routine = evaluate_rules_for_user(user)

    tasks = list(active_routine.tasks.filter(is_active=True).order_by("period", "order"))
    completed_task_ids = set(
        RoutineTaskLog.objects.filter(user=user, log_date=target_date).values_list(
            "task_id", flat=True
        )
    )

    tasks_data = []
    morning_completed = 0
    morning_total = 0
    evening_completed = 0
    evening_total = 0

    for task in tasks:
        done = task.id in completed_task_ids
        if task.period == TaskPeriod.MORNING:
            morning_total += 1
            if done:
                morning_completed += 1
        else:
            evening_total += 1
            if done:
                evening_completed += 1

        tasks_data.append(
            {
                "id": str(task.id),
                "period": task.period,
                "order": task.order,
                "step_name": task.step_name,
                "instructions": task.instructions,
                "product_type": task.product_type,
                "is_completed": done,
            }
        )

    total_tasks = len(tasks)
    total_completed = morning_completed + evening_completed
    routine_progress = (total_completed / total_tasks) if total_tasks > 0 else 0.0

    # 2. Water intake progress
    goal, _ = HydrationGoal.objects.get_or_create(
        user=user,
        defaults={"daily_goal_ml": 2000, "daily_goal_glasses": 8},
    )
    water_logs = WaterIntakeLog.objects.filter(user=user, log_date=target_date).order_by(
        "logged_at"
    )
    glasses_drank = sum(log.glasses for log in water_logs)
    timestamps = [log.logged_at.isoformat() for log in water_logs]

    hydration_progress = (
        (glasses_drank / goal.daily_goal_glasses) if goal.daily_goal_glasses > 0 else 0.0
    )

    return {
        "date": target_date.isoformat(),
        "timezone": "Asia/Kathmandu",
        "routine": {
            "id": str(active_routine.id),
            "title": active_routine.title,
            "disclaimer": active_routine.disclaimer,
            "total_tasks": total_tasks,
            "completed_tasks": total_completed,
            "progress_ratio": round(routine_progress, 2),
            "percent_complete": int(min(1.0, routine_progress) * 100),
            "morning": {
                "total": morning_total,
                "completed": morning_completed,
            },
            "evening": {
                "total": evening_total,
                "completed": evening_completed,
            },
            "tasks": tasks_data,
        },
        "hydration": {
            "glassesCompleted": glasses_drank,
            "dailyGoal": goal.daily_goal_glasses,
            "dailyGoalML": goal.daily_goal_ml,
            "progress": round(hydration_progress, 2),
            "percentComplete": int(min(1.0, hydration_progress) * 100),
            "goalReached": glasses_drank >= goal.daily_goal_glasses,
            "timestamps": timestamps,
            "formula_citation": goal.formula_citation,
            "limitations_disclaimer": goal.limitations_disclaimer,
        },
    }
