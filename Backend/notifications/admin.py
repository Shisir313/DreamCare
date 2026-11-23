"""Admin configuration for notifications and push device tokens."""

from django.contrib import admin

from notifications.models import DeviceToken, Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ["id", "user_email", "title", "notification_type", "is_read", "created_at"]
    list_filter = ["is_read", "notification_type", "created_at"]
    search_fields = ["user__email", "user__name", "title", "body"]
    readonly_fields = ["created_at", "updated_at"]

    def user_email(self, obj):
        return obj.user.email


@admin.register(DeviceToken)
class DeviceTokenAdmin(admin.ModelAdmin):
    list_display = ["id", "user_email", "device_type", "token_preview", "created_at"]
    list_filter = ["device_type", "created_at"]
    search_fields = ["user__email", "user__name", "fcm_token"]
    readonly_fields = ["created_at", "updated_at"]

    def user_email(self, obj):
        return obj.user.email

    def token_preview(self, obj):
        return f"{obj.fcm_token[:20]}..."
