"""Admin configuration for private face photos and photo access audit logs."""

from django.contrib import admin

from media_vault.models import FacePhoto, PhotoAccessAuditLog


@admin.register(FacePhoto)
class FacePhotoAdmin(admin.ModelAdmin):
    list_display = ["id", "user_email", "angle", "content_type", "file_size_kb", "created_at"]
    list_filter = ["angle", "content_type", "created_at"]
    search_fields = ["user__email", "user__name"]
    readonly_fields = ["created_at", "updated_at", "file_size"]

    def user_email(self, obj):
        return obj.user.email

    def file_size_kb(self, obj):
        return f"{obj.file_size // 1024} KB"


@admin.register(PhotoAccessAuditLog)
class PhotoAccessAuditLogAdmin(admin.ModelAdmin):
    list_display = ["photo_id", "actor_email", "purpose", "accessed_at", "ip_hash"]
    list_filter = ["purpose", "accessed_at"]
    search_fields = ["photo__id", "actor__email", "ip_hash"]
    readonly_fields = [
        "photo",
        "patient",
        "actor",
        "actor_role",
        "purpose",
        "ip_hash",
        "accessed_at",
    ]

    def actor_email(self, obj):
        return obj.actor.email

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False
