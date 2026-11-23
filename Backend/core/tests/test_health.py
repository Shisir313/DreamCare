"""Tests for health check endpoint."""

import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient


@pytest.fixture
def api_client():
    return APIClient()


@pytest.mark.django_db
def test_health_check_returns_200(api_client):
    """Verify GET /api/v1/health/ returns 200, status ok, and Asia/Kathmandu timezone."""
    url = reverse("api_v1:core:health-check")
    response = api_client.get(url)

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "ok"
    assert data["database"] == "connected"
    assert data["timezone"] == "Asia/Kathmandu"
    assert "utc_time" in data
    assert "local_time" in data
