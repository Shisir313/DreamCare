"""Tests for skin profiles, lifestyle assessments, and BMI computation."""

import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from consent.models import ConsentRecord
from consent.services import initialize_default_policies
from profiles.models import (
    ActivityLevel,
    RoutineLevel,
    SkinProfile,
    SkinTone,
    SkinType,
    StressLevel,
)

User = get_user_model()


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def consented_user(db):
    user = User.objects.create_user(
        email="sujana@example.com",
        password="Password123!",
        name="Sujana",
        phone="9801234567",
    )
    initialize_default_policies()
    # Accept mandatory policies
    from consent.models import ConsentPolicy

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
def unconsented_user(db):
    initialize_default_policies()
    return User.objects.create_user(
        email="unconsented@example.com",
        password="Password123!",
        name="Unconsented",
    )


@pytest.mark.django_db
def test_skin_profile_creation_and_update(api_client, consented_user):
    api_client.force_authenticate(user=consented_user)
    url = reverse("api_v1:profiles:skin_profile")

    # Initial GET creates default or empty profile
    get_resp = api_client.get(url)
    assert get_resp.status_code == status.HTTP_200_OK

    # Update profile
    payload = {
        "skin_type": SkinType.OILY,
        "skin_tone": SkinTone.MEDIUM,
        "conditions": ["acne"],
        "concerns": ["acne", "oiliness", "largePores"],
        "goals": ["clearSkin", "oilControl"],
        "routine_level": RoutineLevel.INTERMEDIATE,
        "sun_exposure": "high",
    }
    patch_resp = api_client.patch(url, payload, format="json")
    assert patch_resp.status_code == status.HTTP_200_OK
    data = patch_resp.json()
    assert data["skin_type"] == "oily"
    assert "acne" in data["concerns"]
    assert data["routine_level"] == "intermediate"

    # Verify database model
    profile = SkinProfile.objects.get(user=consented_user)
    assert profile.skin_type == SkinType.OILY
    assert profile.concerns == ["acne", "oiliness", "largePores"]


@pytest.mark.django_db
def test_lifestyle_profile_and_server_side_bmi(api_client, consented_user):
    api_client.force_authenticate(user=consented_user)
    url = reverse("api_v1:profiles:lifestyle_profile")

    payload = {
        "height_cm": 175.0,
        "weight_kg": 70.0,
        "age": 28,
        "sleep_hours": 8,
        "stress_level": StressLevel.LOW,
        "activity_level": ActivityLevel.MODERATE,
    }
    patch_resp = api_client.patch(url, payload, format="json")
    assert patch_resp.status_code == status.HTTP_200_OK
    data = patch_resp.json()
    # BMI = 70 / (1.75^2) = 22.857 -> 22.9
    assert data["bmi"] == 22.9
    assert data["bmi_category"] == "normal"

    # Test overweight scenario
    payload2 = {"weight_kg": 95.0}
    patch_resp2 = api_client.patch(url, payload2, format="json")
    assert patch_resp2.status_code == status.HTTP_200_OK
    data2 = patch_resp2.json()
    # BMI = 95 / (1.75^2) = 31.02 -> 31.0
    assert data2["bmi"] == 31.0
    assert data2["bmi_category"] == "obese"


@pytest.mark.django_db
def test_profiles_require_current_consent(api_client, unconsented_user):
    api_client.force_authenticate(user=unconsented_user)
    skin_url = reverse("api_v1:profiles:skin_profile")
    lifestyle_url = reverse("api_v1:profiles:lifestyle_profile")

    resp1 = api_client.get(skin_url)
    assert resp1.status_code == status.HTTP_403_FORBIDDEN

    resp2 = api_client.get(lifestyle_url)
    assert resp2.status_code == status.HTTP_403_FORBIDDEN
