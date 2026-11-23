"""Views for user notifications and device registration."""

from django.http import Http404
from drf_spectacular.utils import extend_schema
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from notifications.models import Notification
from notifications.serializers import (
    DeviceTokenSerializer,
    NotificationSerializer,
    RegisterDeviceTokenRequestSerializer,
)
from notifications.services import (
    mark_all_notifications_as_read,
    mark_notification_as_read,
    register_device_token,
)


class NotificationListView(APIView):
    """List notifications for authenticated user."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="List Notifications",
        description="Returns user notifications sorted by newest first.",
        responses={200: NotificationSerializer(many=True)},
        tags=["Notifications"],
    )
    def get(self, request):
        notifications = Notification.objects.filter(user=request.user)
        return Response(
            NotificationSerializer(notifications, many=True).data, status=status.HTTP_200_OK
        )


class NotificationMarkReadView(APIView):
    """Mark a notification as read."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Mark Notification as Read",
        description="Marks a specific notification as read.",
        request=None,
        responses={200: NotificationSerializer},
        tags=["Notifications"],
    )
    def post(self, request, notification_id):
        try:
            notification = mark_notification_as_read(
                notification_id=notification_id,
                user=request.user,
            )
        except Notification.DoesNotExist as exc:
            raise Http404("Notification not found.") from exc

        return Response(NotificationSerializer(notification).data, status=status.HTTP_200_OK)


class NotificationMarkAllReadView(APIView):
    """Mark all unread notifications as read."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Mark All Notifications as Read",
        description="Marks all unread notifications for current user as read.",
        request=None,
        responses={200: NotificationSerializer(many=True)},
        tags=["Notifications"],
    )
    def post(self, request):
        mark_all_notifications_as_read(user=request.user)
        notifications = Notification.objects.filter(user=request.user)
        return Response(
            NotificationSerializer(notifications, many=True).data, status=status.HTTP_200_OK
        )


class RegisterDeviceTokenView(APIView):
    """Register FCM device token for push notifications."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Register Device Push Token",
        description="Registers device FCM registration token for push notifications.",
        request=RegisterDeviceTokenRequestSerializer,
        responses={201: DeviceTokenSerializer},
        tags=["Notifications"],
    )
    def post(self, request):
        serializer = RegisterDeviceTokenRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        token_obj = register_device_token(
            user=request.user,
            fcm_token=serializer.validated_data["fcm_token"],
            device_type=serializer.validated_data.get("device_type", "android"),
        )
        return Response(DeviceTokenSerializer(token_obj).data, status=status.HTTP_201_CREATED)
