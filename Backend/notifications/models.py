"""Models for user notifications and push device tokens."""

from django.conf import settings
from django.db import models

from core.models import TimeStampedModel, UUIDModel


class NotificationType(models.TextChoices):
    APPOINTMENT = "appointment", "Appointment"
    PRESCRIPTION = "prescription", "Prescription"
    CHECKIN = "checkin", "Weekly Check-in"
    ROUTINE = "routine", "Routine Reminder"
    HYDRATION = "hydration", "Hydration Reminder"
    GENERAL = "general", "General"


class Notification(UUIDModel, TimeStampedModel):
    """User in-app and push notification record."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    title = models.CharField(max_length=255)
    body = models.TextField()
    notification_type = models.CharField(
        max_length=30,
        choices=NotificationType.choices,
        default=NotificationType.GENERAL,
        db_index=True,
    )
    is_read = models.BooleanField(default=False, db_index=True)
    data = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "is_read"]),
            models.Index(fields=["user", "notification_type"]),
        ]

    def __str__(self) -> str:
        status = "READ" if self.is_read else "UNREAD"
        return f"[{status}] {self.title} for {self.user.email}"


class DevicePlatform(models.TextChoices):
    ANDROID = "android", "Android"
    IOS = "ios", "iOS"
    WEB = "web", "Web"


class DeviceToken(UUIDModel, TimeStampedModel):
    """FCM Device registration token for push notifications."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="device_tokens",
    )
    fcm_token = models.CharField(max_length=255, unique=True, db_index=True)
    device_type = models.CharField(
        max_length=20,
        choices=DevicePlatform.choices,
        default=DevicePlatform.ANDROID,
    )

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.user.email} - {self.device_type} ({self.fcm_token[:16]}...)"
