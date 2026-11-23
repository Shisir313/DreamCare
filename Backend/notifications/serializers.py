"""Serializers for notifications and device token registration."""

from rest_framework import serializers

from notifications.models import DevicePlatform, DeviceToken, Notification


class NotificationSerializer(serializers.ModelSerializer):
    """Notification representation matching Flutter notification model."""

    id = serializers.UUIDField(read_only=True)
    title = serializers.CharField()
    body = serializers.CharField()
    type = serializers.CharField(source="notification_type")
    unread = serializers.SerializerMethodField()
    isRead = serializers.BooleanField(source="is_read")
    data = serializers.JSONField()
    createdAt = serializers.DateTimeField(source="created_at", read_only=True)

    class Meta:
        model = Notification
        fields = [
            "id",
            "title",
            "body",
            "type",
            "unread",
            "isRead",
            "data",
            "createdAt",
        ]

    def get_unread(self, obj: Notification) -> bool:
        return not obj.is_read


class RegisterDeviceTokenRequestSerializer(serializers.Serializer):
    fcm_token = serializers.CharField(max_length=255)
    device_type = serializers.ChoiceField(
        choices=DevicePlatform.choices,
        default=DevicePlatform.ANDROID,
    )


class DeviceTokenSerializer(serializers.ModelSerializer):
    id = serializers.UUIDField(read_only=True)
    fcmToken = serializers.CharField(source="fcm_token")
    deviceType = serializers.CharField(source="device_type")
    createdAt = serializers.DateTimeField(source="created_at", read_only=True)

    class Meta:
        model = DeviceToken
        fields = ["id", "fcmToken", "deviceType", "createdAt"]
