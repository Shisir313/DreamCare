"""URLs for user notifications and device push registration."""

from django.urls import path

from notifications.views import (
    NotificationListView,
    NotificationMarkAllReadView,
    NotificationMarkReadView,
    RegisterDeviceTokenView,
)

app_name = "notifications"

urlpatterns = [
    path("", NotificationListView.as_view(), name="notification_list"),
    path(
        "<uuid:notification_id>/read/",
        NotificationMarkReadView.as_view(),
        name="notification_mark_read",
    ),
    path(
        "mark-all-read/", NotificationMarkAllReadView.as_view(), name="notification_mark_all_read"
    ),
    path("devices/register/", RegisterDeviceTokenView.as_view(), name="register_device_token"),
]
