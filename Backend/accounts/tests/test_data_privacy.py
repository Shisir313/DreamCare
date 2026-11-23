"""Tests for GDPR / Nepal Individual Privacy Act compliance: Data Export and Hard Deletion."""

import os

import pytest
from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from consent.models import ConsentPolicy, ConsentRecord
from consent.services import initialize_default_policies
from media_vault.models import FacePhoto, PhotoAngle
from media_vault.services import create_face_photo
from profiles.models import SkinProfile, SkinType

User = get_user_model()


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def test_user_with_data(db):
    user = User.objects.create_user(
        email="rasmi@example.com",
        password="Password123!",
        name="Rasmi Thapa",
        phone="9823456789",
    )
    initialize_default_policies()
    for p in ConsentPolicy.objects.filter(is_mandatory=True):
        ConsentRecord.objects.create(
            user=user,
            policy_type=p.policy_type,
            policy_version=p.version,
            ip_hash="test_ip",
            user_agent_hash="test_ua",
        )

    SkinProfile.objects.create(
        user=user,
        skin_type=SkinType.DRY,
        concerns=["dryness", "dullness"],
    )

    from media_vault.tests.test_photos import create_sample_image

    uploaded = SimpleUploadedFile(
        name="rasmi.jpg",
        content=create_sample_image(with_exif=False),
        content_type="image/jpeg",
    )
    create_face_photo(user=user, uploaded_file=uploaded, angle=PhotoAngle.FRONT)

    return user


@pytest.mark.django_db
def test_user_data_export(api_client, test_user_with_data):
    api_client.force_authenticate(user=test_user_with_data)
    url = reverse("api_v1:me_export_direct")

    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()

    assert data["account"]["email"] == "rasmi@example.com"
    assert data["skin_profile"]["skin_type"] == "dry"
    assert len(data["consents"]) >= 4
    assert len(data["face_photos"]) == 1
    assert "Nepal Individual Privacy Act 2018" in data["export_metadata"]["regulatory_framework"]


@pytest.mark.django_db
def test_user_hard_deletion_removes_db_and_files(api_client, test_user_with_data):
    api_client.force_authenticate(user=test_user_with_data)
    url = reverse("api_v1:me_direct")

    # Get photo file path
    photo = FacePhoto.objects.get(user=test_user_with_data)
    file_path = photo.image_file.path
    assert os.path.exists(file_path)

    # Perform hard deletion
    response = api_client.delete(url)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "hard_deleted"
    assert "legal_retention_notice" in data

    # Verify user record is completely gone
    assert not User.objects.filter(email="rasmi@example.com").exists()

    # Verify associated photo record is deleted
    assert not FacePhoto.objects.filter(id=photo.id).exists()

    # Verify physical file on disk is deleted
    assert not os.path.exists(file_path)
