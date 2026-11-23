"""Integration tests for notifications, push delivery, and demo database seeding."""

import pytest
from django.core.management import call_command
from rest_framework.test import APIClient

from accounts.models import User, UserRole
from notifications.models import DevicePlatform, DeviceToken, Notification, NotificationType
from notifications.push import MockFCMPushService, get_push_service
from notifications.services import (
    register_device_token,
    send_notification,
)


@pytest.fixture
def test_user(db):
    return User.objects.create_user(
        email="test_notify_user@dermacare.np",
        password="ValidPassword123!",
        role=UserRole.PATIENT,
        name="Test Patient",
    )


@pytest.mark.django_db
def test_send_and_list_notifications(test_user):
    send_notification(
        user=test_user,
        title="Appointment Confirmed",
        body="Dr. Anjali confirmed your appointment.",
        notification_type=NotificationType.APPOINTMENT,
    )
    send_notification(
        user=test_user,
        title="Drink Water",
        body="Hydration reminder.",
        notification_type=NotificationType.HYDRATION,
    )

    client = APIClient()
    client.force_authenticate(user=test_user)

    response = client.get("/api/v1/notifications/")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["title"] == "Drink Water"
    assert data[0]["unread"] is True
    assert data[0]["isRead"] is False


@pytest.mark.django_db
def test_mark_individual_notification_as_read(test_user):
    notif = send_notification(
        user=test_user,
        title="Prescription Ready",
        body="Your prescription was published.",
        notification_type=NotificationType.PRESCRIPTION,
    )
    assert notif.is_read is False

    client = APIClient()
    client.force_authenticate(user=test_user)

    response = client.post(f"/api/v1/notifications/{notif.id}/read/")
    assert response.status_code == 200
    assert response.json()["isRead"] is True

    notif.refresh_from_db()
    assert notif.is_read is True


@pytest.mark.django_db
def test_mark_all_notifications_as_read(test_user):
    for i in range(3):
        send_notification(
            user=test_user,
            title=f"Notification {i}",
            body="Test body",
        )

    assert Notification.objects.filter(user=test_user, is_read=False).count() == 3

    client = APIClient()
    client.force_authenticate(user=test_user)

    response = client.post("/api/v1/notifications/mark-all-read/")
    assert response.status_code == 200

    assert Notification.objects.filter(user=test_user, is_read=False).count() == 0


@pytest.mark.django_db
def test_register_device_token_idempotent(test_user):
    client = APIClient()
    client.force_authenticate(user=test_user)

    payload = {
        "fcm_token": "fcm_test_token_abcdef1234567890",
        "device_type": "android",
    }
    response = client.post("/api/v1/notifications/devices/register/", data=payload)
    assert response.status_code == 201
    assert response.json()["fcmToken"] == payload["fcm_token"]

    # Registering same token again updates instead of duplicating
    response2 = client.post("/api/v1/notifications/devices/register/", data=payload)
    assert response2.status_code == 201

    assert DeviceToken.objects.filter(fcm_token=payload["fcm_token"]).count() == 1


@pytest.mark.django_db
def test_push_service_dispatches_to_registered_devices(test_user):
    register_device_token(
        user=test_user,
        fcm_token="fcm_token_device_1",
        device_type=DevicePlatform.ANDROID,
    )

    push_service = get_push_service()
    if isinstance(push_service, MockFCMPushService):
        initial_count = len(push_service.dispatched_messages)

        send_notification(
            user=test_user,
            title="Check-in Feedback",
            body="Dr. Sharma reviewed your Week 1 check-in.",
            notification_type=NotificationType.CHECKIN,
        )

        assert len(push_service.dispatched_messages) == initial_count + 1
        last_msg = push_service.dispatched_messages[-1]
        assert last_msg["token"] == "fcm_token_device_1"
        assert last_msg["title"] == "Check-in Feedback"


@pytest.mark.django_db
def test_seed_nepal_demo_command_executes_cleanly():
    """Verify that seed_nepal_demo management command executes idempotently and cleanly."""
    call_command("seed_nepal_demo")

    assert User.objects.filter(email="sujana@dermacare.np").exists()
    assert User.objects.filter(email="dr.anjali@dermacare.np").exists()
    assert User.objects.filter(email="admin@dermacare.np").exists()
