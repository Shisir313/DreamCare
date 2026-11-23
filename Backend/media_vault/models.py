"""Models for secure facial photo vault and access audit trails."""

from django.conf import settings
from django.db import models
from django.utils import timezone

from core.models import CoreBaseModel


class PhotoAngle(models.TextChoices):
    FRONT = "front", "Front Facing"
    LEFT = "left", "Left Profile (45°/90°)"
    RIGHT = "right", "Right Profile (45°/90°)"


class FacePhoto(CoreBaseModel):
    """Secure private photo record for clinical skin assessment."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="face_photos",
        help_text="Patient who owns this photograph",
    )
    angle = models.CharField(
        max_length=20,
        choices=PhotoAngle.choices,
        default=PhotoAngle.FRONT,
        db_index=True,
    )
    image_file = models.FileField(
        upload_to="vault/photos/%Y/%m/",
        help_text="Private storage path for sanitized image",
    )
    file_size = models.PositiveIntegerField(help_text="File size in bytes")
    content_type = models.CharField(max_length=50, default="image/jpeg")
    is_active = models.BooleanField(
        default=True,
        help_text="Soft-delete or retention flag",
    )

    class Meta:
        db_table = "media_vault_face_photo"
        ordering = ["-created_at"]

    def __str__(self):
        return f"FacePhoto({self.user.email}, {self.angle}, {self.id})"


class PhotoAccessAuditLog(CoreBaseModel):
    """Audit log tracking every access or signed-URL generation for private medical photos."""

    photo = models.ForeignKey(
        FacePhoto,
        on_delete=models.CASCADE,
        related_name="audit_logs",
    )
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="photo_audits_as_subject",
        help_text="Subject patient whose photo was accessed",
    )
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="photo_audits_as_actor",
        help_text="User (patient, dermatologist, or admin) who requested access",
    )
    actor_role = models.CharField(max_length=20, default="patient")
    accessed_at = models.DateTimeField(default=timezone.now, db_index=True)
    ip_hash = models.CharField(
        max_length=64,
        help_text="SHA-256 hash of requester IP address",
    )
    purpose = models.CharField(
        max_length=100,
        default="view_photo",
        help_text="Context of access (e.g. consultation_review, patient_view)",
    )

    class Meta:
        db_table = "media_vault_photo_access_audit_log"
        ordering = ["-accessed_at"]

    def __str__(self):
        actor_email = self.actor.email if self.actor else "System"
        return f"Audit: {actor_email} ({self.actor_role}) accessed photo {self.photo.id} at {self.accessed_at}"
