"""Tests for consent tracking, IP/UA hashing, and permission checks."""

import hashlib

import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.test import APIClient, APIRequestFactory
from rest_framework.views import APIView

from consent.models import ConsentPolicy, ConsentRecord, PolicyType
from consent.permissions import HasCurrentConsent
from consent.services import initialize_default_policies

User = get_user_model()


class MockOnboardingClinicalView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasCurrentConsent]

    def get(self, request):
        return Response({"status": "access_granted"})


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def user(db):
    return User.objects.create_user(
        email="patient@example.com",
        password="Password123!",
        name="Patient User",
    )


@pytest.fixture
def policies(db):
    initialize_default_policies()
    return ConsentPolicy.objects.filter(is_active=True)


@pytest.mark.django_db
def test_list_active_policies_anonymous(api_client, policies):
    url = reverse("api_v1:consent:list_policies")
    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert len(data) >= 4
    for policy in data:
        assert policy["is_accepted"] is False


@pytest.mark.django_db
def test_accept_policies_hashes_ip_and_user_agent(api_client, user, policies):
    api_client.force_authenticate(user=user)
    accept_url = reverse("api_v1:consent:accept_consent")

    client_ip = "192.168.1.100"
    user_agent = "Mozilla/5.0 Flutter/3.0 Mobile"
    expected_ip_hash = hashlib.sha256(client_ip.encode("utf-8")).hexdigest()
    expected_ua_hash = hashlib.sha256(user_agent.encode("utf-8")).hexdigest()

    payload = {
        "consents": [
            {"policy_type": PolicyType.TERMS_OF_SERVICE, "version": "1.0"},
            {"policy_type": PolicyType.PRIVACY_POLICY, "version": "1.0"},
            {"policy_type": PolicyType.HEALTH_DATA_CONSENT, "version": "1.0"},
            {"policy_type": PolicyType.TELEMEDICINE_CONSENT, "version": "1.0"},
        ]
    }

    response = api_client.post(
        accept_url,
        payload,
        format="json",
        REMOTE_ADDR=client_ip,
        HTTP_USER_AGENT=user_agent,
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["has_current_consent"] is True
    assert len(data["missing_policies"]) == 0

    # Verify records stored in database
    records = ConsentRecord.objects.filter(user=user)
    assert records.count() == 4
    for record in records:
        assert record.ip_hash == expected_ip_hash
        assert record.user_agent_hash == expected_ua_hash
        # Ensure plaintext IP is never stored
        assert client_ip not in record.ip_hash


@pytest.mark.django_db
def test_has_current_consent_permission(user, policies):
    factory = APIRequestFactory()
    view = MockOnboardingClinicalView.as_view()

    from rest_framework.test import force_authenticate

    # 1. User without consent is rejected
    req1 = factory.get("/mock-onboarding/")
    force_authenticate(req1, user=user)
    resp1 = view(req1)
    assert resp1.status_code == status.HTTP_403_FORBIDDEN

    # 2. Accept all mandatory policies
    for p in policies.filter(is_mandatory=True):
        ConsentRecord.objects.create(
            user=user,
            policy_type=p.policy_type,
            policy_version=p.version,
            ip_hash="test_ip_hash",
            user_agent_hash="test_ua_hash",
        )

    # 3. User with consent is granted access
    req2 = factory.get("/mock-onboarding/")
    force_authenticate(req2, user=user)
    resp2 = view(req2)
    assert resp2.status_code == status.HTTP_200_OK
    assert resp2.data["status"] == "access_granted"
