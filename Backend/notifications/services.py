"""Notification dispatch services and push integration."""

import logging

from accounts.models import User
from notifications.models import DevicePlatform, DeviceToken, Notification, NotificationType
from notifications.push import get_push_service

logger = logging.getLogger(__name__)


def send_notification(
    user: User,
    title: str,
    body: str,
    notification_type: str = NotificationType.GENERAL,
    data: dict = None,
) -> Notification:
    """Create in-app notification record and deliver via FCM push service."""
    data = data or {}
    notification = Notification.objects.create(
        user=user,
        title=title,
        body=body,
        notification_type=notification_type,
        data=data,
    )

    # Dispatch to user devices via push hook
    try:
        push_service = get_push_service()
        push_service.send_to_user(
            user=user,
            title=title,
            body=body,
            data={"notification_id": str(notification.id), "type": notification_type, **data},
        )
    except Exception as exc:
        logger.warning("Failed to dispatch push notification for user=%s: %s", user.id, exc)

    return notification


def mark_notification_as_read(notification_id, user: User) -> Notification:
    """Mark a specific notification as read."""
    notification = Notification.objects.get(id=notification_id, user=user)
    if not notification.is_read:
        notification.is_read = True
        notification.save(update_fields=["is_read", "updated_at"])
    return notification


def mark_all_notifications_as_read(user: User) -> int:
    """Mark all unread notifications for a user as read."""
    return Notification.objects.filter(user=user, is_read=False).update(is_read=True)


def register_device_token(
    user: User,
    fcm_token: str,
    device_type: str = DevicePlatform.ANDROID,
) -> DeviceToken:
    """Register or update an FCM push device token."""
    device_token, _ = DeviceToken.objects.update_or_create(
        fcm_token=fcm_token,
        defaults={"user": user, "device_type": device_type},
    )
    return device_token
