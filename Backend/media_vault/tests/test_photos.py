"""Tests for face photo uploads, EXIF stripping, signed URLs, and audit logging."""

import io

import pytest
from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from PIL import Image
from rest_framework import status
from rest_framework.test import APIClient

from consent.models import ConsentPolicy, ConsentRecord
from consent.services import initialize_default_policies
from media_vault.models import FacePhoto, PhotoAccessAuditLog, PhotoAngle

User = get_user_model()


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def user_a(db):
    user = User.objects.create_user(email="sujana@example.com", password="Password123!")
    initialize_default_policies()
    for p in ConsentPolicy.objects.filter(is_mandatory=True):
        ConsentRecord.objects.create(
            user=user,
            policy_type=p.policy_type,
            policy_version=p.version,
            ip_hash="ip_hash",
            user_agent_hash="ua_hash",
        )
    return user


@pytest.fixture
def user_b(db):
    user = User.objects.create_user(email="triyog@example.com", password="Password123!")
    for p in ConsentPolicy.objects.filter(is_mandatory=True):
        ConsentRecord.objects.create(
            user=user,
            policy_type=p.policy_type,
            policy_version=p.version,
            ip_hash="ip_hash",
            user_agent_hash="ua_hash",
        )
    return user


def create_sample_image(with_exif=True):
    """Generate in-memory JPEG image with simulated EXIF metadata."""
    img = Image.new("RGB", (100, 100), color="blue")
    buf = io.BytesIO()

    if with_exif:
        exif = img.getexif()
        # Tag 306 = DateTime, Tag 271 = Make
        exif[306] = "2026:11:22 12:00:00"
        exif[271] = "Apple iPhone 15 Pro"
        img.save(buf, format="JPEG", exif=exif)
    else:
        img.save(buf, format="JPEG")

    buf.seek(0)
    return buf.getvalue()


@pytest.mark.django_db
def test_face_photo_upload_and_exif_stripping(api_client, user_a):
    api_client.force_authenticate(user=user_a)
    upload_url = reverse("api_v1:photos:photo_upload")

    image_bytes_with_exif = create_sample_image(with_exif=True)
    # Check that test image indeed has EXIF
    test_img = Image.open(io.BytesIO(image_bytes_with_exif))
    assert len(test_img.getexif()) > 0

    uploaded = SimpleUploadedFile(
        name="test_face.jpg",
        content=image_bytes_with_exif,
        content_type="image/jpeg",
    )

    response = api_client.post(
        upload_url,
        {"file": uploaded, "angle": PhotoAngle.FRONT},
        format="multipart",
    )
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["angle"] == "front"
    assert "signed_url" in data

    # Verify saved image has ZERO EXIF tags
    photo = FacePhoto.objects.get(id=data["id"])
    saved_img = Image.open(photo.image_file.path)
    exif = saved_img.getexif()
    assert len(exif) == 0


@pytest.mark.django_db
def test_invalid_file_rejected(api_client, user_a):
    api_client.force_authenticate(user=user_a)
    upload_url = reverse("api_v1:photos:photo_upload")

    bad_file = SimpleUploadedFile(
        name="script.sh",
        content=b"#!/bin/bash\necho hello",
        content_type="text/plain",
    )
    response = api_client.post(
        upload_url,
        {"file": bad_file, "angle": PhotoAngle.FRONT},
        format="multipart",
    )
    assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
def test_signed_url_streaming_and_access_audit(api_client, user_a, user_b):
    api_client.force_authenticate(user=user_a)
    upload_url = reverse("api_v1:photos:photo_upload")

    uploaded = SimpleUploadedFile(
        name="face.jpg",
        content=create_sample_image(with_exif=False),
        content_type="image/jpeg",
    )
    upload_resp = api_client.post(
        upload_url,
        {"file": uploaded, "angle": PhotoAngle.LEFT},
        format="multipart",
    )
    photo_id = upload_resp.json()["id"]

    # 1. Request fresh signed URL
    url_endpoint = reverse("api_v1:photos:photo_signed_url", kwargs={"photo_id": photo_id})
    url_resp = api_client.get(url_endpoint)
    assert url_resp.status_code == status.HTTP_200_OK
    signed_url = url_resp.json()["signed_url"]

    # Verify audit log was created
    audit_count = PhotoAccessAuditLog.objects.filter(photo_id=photo_id).count()
    assert audit_count >= 1

    # 2. Access the photo via signed URL (allow_any with valid token)
    stream_client = APIClient()
    stream_resp = stream_client.get(signed_url)
    assert stream_resp.status_code == status.HTTP_200_OK
    assert stream_resp["Content-Type"] == "image/jpeg"
    assert "no-cache" in stream_resp["Cache-Control"]

    # 3. Patient B attempts to generate signed URL for Patient A's photo
    api_client.force_authenticate(user=user_b)
    unauthorized_resp = api_client.get(url_endpoint)
    assert unauthorized_resp.status_code == status.HTTP_403_FORBIDDEN
