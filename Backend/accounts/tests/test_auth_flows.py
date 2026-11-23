"""Integration tests for accounts authentication, registration, profile, and password reset."""

import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from accounts.models import UserRole
from accounts.services import request_password_reset

User = get_user_model()


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def existing_user(db):
    return User.objects.create_user(
        email="existing@example.com",
        password="ValidPassword123!",
        name="Existing User",
        phone="9801111111",
    )


@pytest.mark.django_db
def test_patient_registration_success(api_client):
    url = reverse("api_v1:accounts:register")
    payload = {
        "email": "sujana@example.com",
        "phone": "9801234567",
        "name": "Sujana Shrestha",
        "password": "SecurePassword123!",
    }
    response = api_client.post(url, payload, format="json")
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert "access" in data
    assert "refresh" in data
    assert data["user"]["email"] == "sujana@example.com"
    assert data["user"]["role"] == UserRole.PATIENT

    # Verify user in database is patient
    user = User.objects.get(email="sujana@example.com")
    assert user.role == UserRole.PATIENT


@pytest.mark.django_db
def test_registration_with_phone_only_generates_internal_email(api_client):
    url = reverse("api_v1:accounts:register")
    payload = {
        "phone": "9812345678",
        "name": "Triyog Shrestha",
        "password": "SecurePassword123!",
    }
    response = api_client.post(url, payload, format="json")
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["user"]["phone"] == "9812345678"
    assert "9812345678@dermacare.np" in data["user"]["email"]


@pytest.mark.django_db
def test_duplicate_registration_fails(api_client, existing_user):
    url = reverse("api_v1:accounts:register")
    response = api_client.post(
        url,
        {
            "email": "existing@example.com",
            "phone": "9809999999",
            "password": "Password123!",
        },
        format="json",
    )
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert response.json()["error"]["code"] == "validation_error"


@pytest.mark.django_db
def test_login_with_phone_and_email(api_client, existing_user):
    login_url = reverse("api_v1:accounts:login")

    # 1. Login with email
    resp1 = api_client.post(
        login_url,
        {"email": "existing@example.com", "password": "ValidPassword123!"},
        format="json",
    )
    assert resp1.status_code == status.HTTP_200_OK
    assert "access" in resp1.json()

    # 2. Login with phone
    resp2 = api_client.post(
        login_url,
        {"phone": "9801111111", "password": "ValidPassword123!"},
        format="json",
    )
    assert resp2.status_code == status.HTTP_200_OK
    assert "access" in resp2.json()


@pytest.mark.django_db
def test_logout_blacklists_token(api_client, existing_user):
    login_url = reverse("api_v1:accounts:login")
    login_resp = api_client.post(
        login_url,
        {"email": "existing@example.com", "password": "ValidPassword123!"},
        format="json",
    )
    tokens = login_resp.json()

    logout_url = reverse("api_v1:accounts:logout")
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
    logout_resp = api_client.post(logout_url, {"refresh": tokens["refresh"]}, format="json")
    assert logout_resp.status_code == status.HTTP_200_OK

    # Try refreshing blacklisted token
    refresh_url = reverse("api_v1:accounts:token_refresh")
    refresh_resp = api_client.post(refresh_url, {"refresh": tokens["refresh"]}, format="json")
    assert refresh_resp.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
def test_get_and_patch_current_user_profile(api_client, existing_user):
    login_url = reverse("api_v1:accounts:login")
    tokens = api_client.post(
        login_url,
        {"email": "existing@example.com", "password": "ValidPassword123!"},
        format="json",
    ).json()

    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
    me_url = reverse("api_v1:accounts:current_user")

    # GET profile
    get_resp = api_client.get(me_url)
    assert get_resp.status_code == status.HTTP_200_OK
    assert get_resp.json()["email"] == "existing@example.com"

    # PATCH profile
    patch_resp = api_client.patch(
        me_url,
        {"name": "Updated Name", "date_of_birth": "1998-05-15"},
        format="json",
    )
    assert patch_resp.status_code == status.HTTP_200_OK
    assert patch_resp.json()["name"] == "Updated Name"
    assert patch_resp.json()["date_of_birth"] == "1998-05-15"


@pytest.mark.django_db
def test_change_password(api_client, existing_user):
    login_url = reverse("api_v1:accounts:login")
    tokens = api_client.post(
        login_url,
        {"email": "existing@example.com", "password": "ValidPassword123!"},
        format="json",
    ).json()

    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
    change_url = reverse("api_v1:accounts:change_password")

    # Wrong current password
    fail_resp = api_client.post(
        change_url,
        {"current_password": "WrongPassword!", "new_password": "BrandNewPassword123!"},
        format="json",
    )
    assert fail_resp.status_code == status.HTTP_400_BAD_REQUEST

    # Correct current password
    ok_resp = api_client.post(
        change_url,
        {"current_password": "ValidPassword123!", "new_password": "BrandNewPassword123!"},
        format="json",
    )
    assert ok_resp.status_code == status.HTTP_200_OK

    # Verify new password works
    login_again = api_client.post(
        login_url,
        {"email": "existing@example.com", "password": "BrandNewPassword123!"},
        format="json",
    )
    assert login_again.status_code == status.HTTP_200_OK


@pytest.mark.django_db
def test_password_reset_flow(api_client, existing_user):
    token = request_password_reset("existing@example.com")
    assert token is not None

    confirm_url = reverse("api_v1:accounts:password_reset_confirm")
    confirm_resp = api_client.post(
        confirm_url,
        {"code": token.code, "new_password": "NewResetPassword123!"},
        format="json",
    )
    assert confirm_resp.status_code == status.HTTP_200_OK

    # Verify user can log in with new password
    login_url = reverse("api_v1:accounts:login")
    login_resp = api_client.post(
        login_url,
        {"email": "existing@example.com", "password": "NewResetPassword123!"},
        format="json",
    )
    assert login_resp.status_code == status.HTTP_200_OK
