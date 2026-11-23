"""Push notification delivery engine (FCM Interface).

Provides a clean interface for dispatching push notifications to Android, iOS,
and Web devices via Firebase Cloud Messaging.
"""

import logging
from abc import ABC, abstractmethod

logger = logging.getLogger(__name__)


class BasePushNotificationService(ABC):
    """Abstract interface for push notification providers."""

    @abstractmethod
    def send_to_token(self, token: str, title: str, body: str, data: dict = None) -> bool:
        """Send push notification to a specific device registration token."""
        pass

    @abstractmethod
    def send_to_user(self, user, title: str, body: str, data: dict = None) -> int:
        """Send push notification to all active devices registered to a user."""
        pass


class MockFCMPushService(BasePushNotificationService):
    """Sandbox/Testing push notification service that logs and records dispatches."""

    def __init__(self):
        self.dispatched_messages = []

    def send_to_token(self, token: str, title: str, body: str, data: dict = None) -> bool:
        payload = {
            "token": token,
            "title": title,
            "body": body,
            "data": data or {},
        }
        self.dispatched_messages.append(payload)
        logger.info("[MOCK FCM PUSH] Delivered to token=%s: %s - %s", token[:16], title, body)
        return True

    def send_to_user(self, user, title: str, body: str, data: dict = None) -> int:
        tokens = list(user.device_tokens.values_list("fcm_token", flat=True))
        delivered_count = 0
        for token in tokens:
            if self.send_to_token(token, title, body, data):
                delivered_count += 1
        logger.info("[MOCK FCM PUSH] Sent %d notifications to user=%s", delivered_count, user.id)
        return delivered_count


# Default singleton provider
push_service: BasePushNotificationService = MockFCMPushService()


def get_push_service() -> BasePushNotificationService:
    return push_service
