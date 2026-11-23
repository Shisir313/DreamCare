"""Tests for JWT token obtain, rotation, and blacklist."""

import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

User = get_user_model()


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def patient_user(db):
    return User.objects.create_user(
        email="sujana@example.com",
        password="ValidPassword123!",
        name="Sujana",
        phone="9801234567",
    )


@pytest.mark.django_db
def test_jwt_token_obtain_and_refresh_cycle(api_client, patient_user):
    token_url = reverse("api_v1:accounts:token_obtain_pair")
    refresh_url = reverse("api_v1:accounts:token_refresh")

    # 1. Obtain token pair
    login_resp = api_client.post(
        token_url,
        {"email": "sujana@example.com", "password": "ValidPassword123!"},
        format="json",
    )
    assert login_resp.status_code == status.HTTP_200_OK
    data = login_resp.json()
    assert "access" in data
    assert "refresh" in data
    assert "user" in data
    assert data["user"]["email"] == "sujana@example.com"
    assert data["user"]["role"] == "patient"

    initial_refresh = data["refresh"]

    # 2. Refresh token (should rotate)
    refresh_resp = api_client.post(
        refresh_url,
        {"refresh": initial_refresh},
        format="json",
    )
    assert refresh_resp.status_code == status.HTTP_200_OK
    refresh_data = refresh_resp.json()
    assert "access" in refresh_data
    assert "refresh" in refresh_data
    new_refresh = refresh_data["refresh"]
    assert new_refresh != initial_refresh

    # 3. Old refresh token should now be blacklisted
    blacklisted_resp = api_client.post(
        refresh_url,
        {"refresh": initial_refresh},
        format="json",
    )
    assert blacklisted_resp.status_code == status.HTTP_401_UNAUTHORIZED
    error_data = blacklisted_resp.json()
    assert error_data["error"]["code"] == "authentication_failed"
