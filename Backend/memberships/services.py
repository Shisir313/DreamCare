"""Business logic service layer for plans, memberships, and entitlements."""

import logging

from django.core.exceptions import ValidationError
from django.db import transaction
from django.utils import timezone

from memberships.models import Membership, MembershipStatus, Plan, PlanCode

logger = logging.getLogger(__name__)


def seed_default_plans():
    """Seed baseline admin-editable plans with NPR prices stored as integer paisa."""
    default_plans = [
        {
            "code": PlanCode.BASIC,
            "name": "Basic Plan",
            "description": "Essential skincare guidance, daily tracking, and 1 dermatologist video consultation.",
            "price_paisa": 39900,  # NPR 399.00
            "duration_days": 28,  # 4-week term
            "consultations_included": 1,
            "checkins_included": 4,
            "features": [
                "1 Video Consultation with verified Dermatologist",
                "4 Weekly Photo Skin Check-ins",
                "Personalized Skincare Routine Guidance",
                "Hydration and Daily Task Checklist",
            ],
            "is_active": True,
        },
        {
            "code": PlanCode.PREMIUM,
            "name": "Premium Plan",
            "description": "Comprehensive dermatology care with 2 video consultations and routine reviews.",
            "price_paisa": 49900,  # NPR 499.00
            "duration_days": 28,  # 4-week term
            "consultations_included": 2,
            "checkins_included": 4,
            "features": [
                "2 Video Consultations with verified Dermatologist",
                "4 Weekly Photo Skin Check-ins",
                "Priority Dermatologist Routine Review",
                "Prescription Access & Follow-up Guidance",
                "Full Hydration & Lifestyle Insights",
            ],
            "is_active": True,
        },
        {
            "code": PlanCode.PAY_PER_CONSULTATION,
            "name": "Pay-per-Consultation",
            "description": "Single consultation without recurring monthly commitment.",
            "price_paisa": 20000,  # NPR 200.00
            "duration_days": 28,
            "consultations_included": 1,
            "checkins_included": 0,
            "features": [
                "1 Video Consultation with verified Dermatologist",
                "Prescription Access & Consultation Notes",
                "One-off Payment, No Subscription",
            ],
            "is_active": True,
        },
    ]

    for data in default_plans:
        Plan.objects.get_or_create(code=data["code"], defaults=data)


def get_active_plans():
    """Retrieve all active plans."""
    return Plan.objects.filter(is_active=True).order_by("price_paisa")


def create_pending_membership(user, plan_code: str) -> Membership:
    """Create a pending membership order ready for payment checkout."""
    try:
        plan = Plan.objects.get(code=plan_code, is_active=True)
    except Plan.DoesNotExist as exc:
        raise ValidationError(
            {"plan": [f"Plan '{plan_code}' is invalid or currently inactive."]}
        ) from exc

    # Reuse existing pending membership if identical
    pending = Membership.objects.filter(
        user=user,
        plan=plan,
        status=MembershipStatus.PENDING,
    ).first()
    if pending:
        return pending

    membership = Membership.objects.create(
        user=user,
        plan=plan,
        status=MembershipStatus.PENDING,
    )
    logger.info(
        "Pending membership created: id=%s, user_id=%s, plan=%s", membership.id, user.id, plan.code
    )
    return membership


@transaction.atomic
def activate_membership(membership: Membership) -> Membership:
    """Activate membership and supersede any existing active memberships."""
    # Enforce exclusivity: supersede previous active memberships
    previous_active = Membership.objects.select_for_update().filter(
        user=membership.user,
        status=MembershipStatus.ACTIVE,
    )
    for prev in previous_active:
        prev.expire()

    membership.activate()
    logger.info(
        "Membership activated: id=%s, user_id=%s, plan=%s, valid_until=%s",
        membership.id,
        membership.user.id,
        membership.plan.code,
        membership.end_date,
    )
    return membership


def get_active_membership_with_expiry_check(user) -> Membership | None:
    """Retrieve active membership enforcing request-time expiry check."""
    membership = (
        Membership.objects.filter(user=user, status=MembershipStatus.ACTIVE)
        .select_related("plan")
        .first()
    )
    if not membership:
        return None

    if membership.check_and_enforce_expiry():
        logger.info("Membership %s expired at request time for user %s", membership.id, user.id)
        return None

    return membership


def expire_outdated_memberships() -> int:
    """Scheduled background job (Celery task) to expire memberships whose end_date has passed."""
    now = timezone.now()
    count = Membership.objects.filter(
        status=MembershipStatus.ACTIVE,
        end_date__lte=now,
    ).update(
        status=MembershipStatus.EXPIRED,
        updated_at=now,
    )
    if count > 0:
        logger.info("Expired %d outdated memberships via scheduled job", count)
    return count


@transaction.atomic
def consume_consultation_entitlement(user) -> Membership:
    """Consume 1 consultation entitlement atomically with row locking."""
    membership = (
        Membership.objects.select_for_update()
        .filter(user=user, status=MembershipStatus.ACTIVE)
        .first()
    )
    if not membership or membership.check_and_enforce_expiry():
        raise ValidationError({"membership": ["You do not have an active membership."]})

    if membership.consultations_remaining <= 0:
        raise ValidationError(
            {"entitlement": ["You have no remaining consultation credits on your current plan."]}
        )

    membership.consultations_remaining -= 1
    membership.save(update_fields=["consultations_remaining", "updated_at"])
    logger.info(
        "Consultation consumed for user_id=%s. Remaining: %d",
        user.id,
        membership.consultations_remaining,
    )
    return membership


@transaction.atomic
def restore_consultation_entitlement(user) -> Membership | None:
    """Restore 1 consultation entitlement atomically (e.g. upon cancellation > 2h before slot)."""
    membership = (
        Membership.objects.select_for_update()
        .filter(user=user, status=MembershipStatus.ACTIVE)
        .first()
    )
    if membership:
        membership.consultations_remaining += 1
        membership.save(update_fields=["consultations_remaining", "updated_at"])
        logger.info(
            "Consultation entitlement restored for user_id=%s. New balance: %d",
            user.id,
            membership.consultations_remaining,
        )
    return membership


@transaction.atomic
def consume_checkin_entitlement(user) -> Membership:
    """Consume 1 weekly photo check-in entitlement atomically."""
    membership = (
        Membership.objects.select_for_update()
        .filter(user=user, status=MembershipStatus.ACTIVE)
        .first()
    )
    if not membership or membership.check_and_enforce_expiry():
        raise ValidationError({"membership": ["You do not have an active membership."]})

    if membership.checkins_remaining <= 0:
        raise ValidationError(
            {"entitlement": ["You have used all weekly check-ins included in your plan."]}
        )

    membership.checkins_remaining -= 1
    membership.save(update_fields=["checkins_remaining", "updated_at"])
    logger.info(
        "Checkin consumed for user_id=%s. Remaining: %d",
        user.id,
        membership.checkins_remaining,
    )
    return membership
