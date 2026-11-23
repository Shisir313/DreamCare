"""Tests for plans, membership state machine, entitlements, and dual-layer expiry enforcement."""

from datetime import timedelta

import pytest
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from consent.models import ConsentPolicy, ConsentRecord
from consent.services import initialize_default_policies
from memberships.models import Membership, MembershipStatus, PlanCode
from memberships.services import (
    activate_membership,
    consume_checkin_entitlement,
    consume_consultation_entitlement,
    create_pending_membership,
    expire_outdated_memberships,
    get_active_membership_with_expiry_check,
    seed_default_plans,
)

User = get_user_model()


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def user(db):
    user = User.objects.create_user(
        email="sujana@example.com",
        password="Password123!",
        name="Sujana Shrestha",
    )
    initialize_default_policies()
    seed_default_plans()

    for p in ConsentPolicy.objects.filter(is_mandatory=True):
        ConsentRecord.objects.create(
            user=user,
            policy_type=p.policy_type,
            policy_version=p.version,
            ip_hash="ip_hash",
            user_agent_hash="ua_hash",
        )
    return user


@pytest.mark.django_db
def test_list_plans_with_integer_paisa(api_client):
    url = reverse("api_v1:plans_direct")
    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert len(data) >= 3

    # Check pricing in integer paisa and rupees
    basic = next(p for p in data if p["code"] == "basic")
    assert basic["price_paisa"] == 39900
    assert basic["price_npr"] == 399.0
    assert basic["duration_days"] == 28
    assert basic["consultations_included"] == 1
    assert basic["checkins_included"] == 4


@pytest.mark.django_db
def test_select_plan_and_activate_lifecycle(api_client, user):
    api_client.force_authenticate(user=user)

    # 1. Select Premium Plan -> PENDING
    select_url = reverse("api_v1:memberships:select_plan")
    response = api_client.post(select_url, {"plan_code": PlanCode.PREMIUM}, format="json")
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["status"] == "pending"
    assert data["is_currently_active"] is False

    membership_id = data["id"]
    membership = Membership.objects.get(id=membership_id)
    assert membership.status == MembershipStatus.PENDING

    # 2. Activate membership (simulates payment verification in M5)
    activated = activate_membership(membership)
    assert activated.status == MembershipStatus.ACTIVE
    assert activated.is_currently_active is True
    assert activated.consultations_remaining == 2
    assert activated.checkins_remaining == 4
    assert activated.end_date > timezone.now() + timedelta(days=27)

    # 3. Verify GET /current/ reflects active membership
    current_url = reverse("api_v1:memberships:current_membership")
    current_resp = api_client.get(current_url)
    assert current_resp.status_code == status.HTTP_200_OK
    assert current_resp.json()["status"] == "active"
    assert current_resp.json()["consultations_remaining"] == 2


@pytest.mark.django_db
def test_request_time_expiry_enforcement(user):
    membership = create_pending_membership(user, PlanCode.BASIC)
    activate_membership(membership)

    # Fast forward end_date to 1 hour in the past
    membership.end_date = timezone.now() - timedelta(hours=1)
    membership.save(update_fields=["end_date"])

    # Querying with request-time check enforces transition to expired
    active_m = get_active_membership_with_expiry_check(user)
    assert active_m is None

    # Verify database record transitioned to expired
    membership.refresh_from_db()
    assert membership.status == MembershipStatus.EXPIRED


@pytest.mark.django_db
def test_scheduled_expiry_job(user):
    membership = create_pending_membership(user, PlanCode.BASIC)
    activate_membership(membership)

    # Move end_date to past
    membership.end_date = timezone.now() - timedelta(days=1)
    membership.save(update_fields=["end_date"])

    # Run background job
    expired_count = expire_outdated_memberships()
    assert expired_count == 1

    membership.refresh_from_db()
    assert membership.status == MembershipStatus.EXPIRED


@pytest.mark.django_db
def test_entitlement_consumption_and_guard(user):
    membership = create_pending_membership(user, PlanCode.BASIC)
    activate_membership(membership)
    assert membership.consultations_remaining == 1

    # 1. Consume the 1 included consultation
    consume_consultation_entitlement(user)
    membership.refresh_from_db()
    assert membership.consultations_remaining == 0

    # 2. Attempting to consume with 0 remaining raises ValidationError
    with pytest.raises(ValidationError, match="You have no remaining consultation credits"):
        consume_consultation_entitlement(user)

    # 3. Test check-in consumption
    assert membership.checkins_remaining == 4
    consume_checkin_entitlement(user)
    membership.refresh_from_db()
    assert membership.checkins_remaining == 3


@pytest.mark.django_db
def test_membership_cancellation(api_client, user):
    api_client.force_authenticate(user=user)
    membership = create_pending_membership(user, PlanCode.BASIC)
    activate_membership(membership)

    cancel_url = reverse(
        "api_v1:memberships:cancel_membership", kwargs={"membership_id": membership.id}
    )
    response = api_client.post(cancel_url, {"reason": "Personal reasons"}, format="json")
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] == "cancelled"

    membership.refresh_from_db()
    assert membership.status == MembershipStatus.CANCELLED
    assert membership.cancellation_reason == "Personal reasons"
