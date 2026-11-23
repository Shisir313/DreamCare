"""Tests for payments, eSewa and Khalti adapters, S2S verification, anti-fraud, and reconciliation."""

import json
from unittest.mock import MagicMock, patch

import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from consent.models import ConsentPolicy, ConsentRecord
from consent.services import initialize_default_policies
from memberships.models import MembershipStatus, PlanCode
from memberships.services import create_pending_membership, seed_default_plans
from payments.gateways.esewa import EsewaGatewayAdapter
from payments.models import (
    AttemptStatus,
    GatewayChoice,
    OrderStatus,
)
from payments.services import (
    create_payment_order,
    initiate_payment_checkout,
    verify_payment_attempt,
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
        phone="9801234567",
    )
    initialize_default_policies()
    seed_default_plans()

    for p in ConsentPolicy.objects.filter(is_mandatory=True):
        ConsentRecord.objects.create(
            user=user,
            policy_type=p.policy_type,
            policy_version=p.version,
            ip_hash="test_ip",
            user_agent_hash="test_ua",
        )
    return user


@pytest.fixture
def pending_membership(user):
    return create_pending_membership(user, PlanCode.BASIC)


@pytest.mark.django_db
def test_create_order_with_idempotency_key(api_client, user, pending_membership):
    api_client.force_authenticate(user=user)
    url = reverse("api_v1:payments:create_order")

    idemp_key = "idemp_test_key_001"
    payload = {
        "membership_id": str(pending_membership.id),
        "idempotency_key": idemp_key,
    }

    # 1. First order creation
    resp1 = api_client.post(url, payload, format="json")
    assert resp1.status_code == status.HTTP_201_CREATED
    data1 = resp1.json()
    assert data1["amount_paisa"] == 39900
    assert data1["amount_npr"] == 399.0
    assert data1["status"] == "pending"

    # 2. Replay with identical idempotency key returns exact same order
    resp2 = api_client.post(url, payload, format="json")
    assert resp2.status_code == status.HTTP_201_CREATED
    data2 = resp2.json()
    assert data2["id"] == data1["id"]


@pytest.mark.django_db
def test_esewa_initiate_generates_valid_hmac_signature(user, pending_membership):
    order = create_payment_order(
        user=user,
        amount_paisa=39900,
        membership=pending_membership,
    )

    initiate_data = initiate_payment_checkout(
        order=order,
        gateway_name=GatewayChoice.ESEWA,
        return_url="https://dermacare.np/callback",
    )

    assert initiate_data["gateway"] == "esewa"
    form_fields = initiate_data["form_fields"]
    assert form_fields["amount"] == "399"
    assert form_fields["total_amount"] == "399"
    assert form_fields["product_code"] == "EPAYTEST"
    assert "signature" in form_fields

    # Verify signature manually
    expected_sig = EsewaGatewayAdapter.generate_signature(
        secret_key="8gBm/:&EnhH.1/q",
        total_amount="399",
        transaction_uuid=form_fields["transaction_uuid"],
        product_code="EPAYTEST",
    )
    assert form_fields["signature"] == expected_sig


@pytest.mark.django_db
def test_server_to_server_esewa_verification_and_activation(user, pending_membership):
    order = create_payment_order(
        user=user,
        amount_paisa=39900,
        membership=pending_membership,
    )
    initiate_data = initiate_payment_checkout(
        order=order,
        gateway_name=GatewayChoice.ESEWA,
        return_url="https://dermacare.np/callback",
    )
    tx_uuid = initiate_data["transaction_uuid"]

    # Mock official eSewa server status lookup API
    mock_esewa_response = {
        "product_code": "EPAYTEST",
        "total_amount": 399.0,
        "status": "COMPLETE",
        "ref_id": "ESEWA_MOCK_REF_9988",
        "transaction_uuid": tx_uuid,
    }

    mock_resp = MagicMock()
    mock_resp.read.return_value = json.dumps(mock_esewa_response).encode("utf-8")
    mock_resp.__enter__.return_value = mock_resp

    with patch("urllib.request.urlopen", return_value=mock_resp):
        is_success, attempt = verify_payment_attempt(attempt_reference=tx_uuid)

    assert is_success is True
    assert attempt.status == AttemptStatus.SUCCESS
    assert attempt.gateway_transaction_id == "ESEWA_MOCK_REF_9988"

    order.refresh_from_db()
    assert order.status == OrderStatus.PAID

    # Verify membership activation flow
    pending_membership.refresh_from_db()
    assert pending_membership.status == MembershipStatus.ACTIVE
    assert pending_membership.consultations_remaining == 1
    assert pending_membership.checkins_remaining == 4


@pytest.mark.django_db
def test_anti_fraud_amount_tampering_rejected(user, pending_membership):
    order = create_payment_order(
        user=user,
        amount_paisa=39900,
        membership=pending_membership,
    )
    initiate_data = initiate_payment_checkout(
        order=order,
        gateway_name=GatewayChoice.ESEWA,
        return_url="https://dermacare.np/callback",
    )
    tx_uuid = initiate_data["transaction_uuid"]

    # Fraudulent response: User paid only 50 NPR instead of 399 NPR
    tampered_response = {
        "product_code": "EPAYTEST",
        "total_amount": 50.0,
        "status": "COMPLETE",
        "ref_id": "FRAUD_REF",
        "transaction_uuid": tx_uuid,
    }

    mock_resp = MagicMock()
    mock_resp.read.return_value = json.dumps(tampered_response).encode("utf-8")
    mock_resp.__enter__.return_value = mock_resp

    with patch("urllib.request.urlopen", return_value=mock_resp):
        is_success, attempt = verify_payment_attempt(attempt_reference=tx_uuid)

    assert is_success is False
    assert attempt.status == AttemptStatus.FAILED
    assert attempt.gateway_response_raw["total_amount"] == 50.0

    order.refresh_from_db()
    assert order.status != OrderStatus.PAID

    pending_membership.refresh_from_db()
    assert pending_membership.status == MembershipStatus.PENDING


@pytest.mark.django_db
def test_replay_protection_is_safe_and_idempotent(user, pending_membership):
    order = create_payment_order(user=user, amount_paisa=39900, membership=pending_membership)
    initiate_data = initiate_payment_checkout(
        order=order, gateway_name=GatewayChoice.ESEWA, return_url="test"
    )
    tx_uuid = initiate_data["transaction_uuid"]

    mock_resp = MagicMock()
    mock_resp.read.return_value = json.dumps(
        {
            "status": "COMPLETE",
            "ref_id": "REF_1",
            "total_amount": 399.0,
            "transaction_uuid": tx_uuid,
        }
    ).encode("utf-8")
    mock_resp.__enter__.return_value = mock_resp

    with patch("urllib.request.urlopen", return_value=mock_resp):
        # 1. First verification
        is_success1, _ = verify_payment_attempt(attempt_reference=tx_uuid)
        assert is_success1 is True

        pending_membership.refresh_from_db()
        assert pending_membership.consultations_remaining == 1

        # 2. Replay of callback / verification
        is_success2, _ = verify_payment_attempt(attempt_reference=tx_uuid)
        assert is_success2 is True

        # Ensure entitlements did NOT double
        pending_membership.refresh_from_db()
        assert pending_membership.consultations_remaining == 1
