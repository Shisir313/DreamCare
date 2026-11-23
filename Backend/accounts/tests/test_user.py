"""Tests for accounts User model."""

import uuid

import pytest
from django.contrib.auth import get_user_model

from accounts.models import UserRole

User = get_user_model()


@pytest.mark.django_db
def test_create_patient_user():
    user = User.objects.create_user(
        email="sujana@example.com",
        password="TestPassword123!",
        name="Sujana Shrestha",
        phone="9801234567",
    )
    assert user.email == "sujana@example.com"
    assert user.name == "Sujana Shrestha"
    assert user.phone == "9801234567"
    assert user.role == UserRole.PATIENT
    assert user.is_patient
    assert not user.is_staff
    assert not user.is_superuser
    assert isinstance(user.id, uuid.UUID)
    assert user.check_password("TestPassword123!")


@pytest.mark.django_db
def test_email_is_normalized():
    user = User.objects.create_user(
        email="TRIYOG@EXAMPLE.COM",
        password="TestPassword123!",
    )
    assert user.email == "TRIYOG@example.com"


@pytest.mark.django_db
def test_create_user_without_email_raises():
    with pytest.raises(ValueError, match="The Email field must be set."):
        User.objects.create_user(email="")


@pytest.mark.django_db
def test_create_superuser():
    admin = User.objects.create_superuser(
        email="admin@dermacare.np",
        password="AdminPassword123!",
    )
    assert admin.role == UserRole.ADMIN
    assert admin.is_staff
    assert admin.is_superuser
    assert admin.is_admin_user
