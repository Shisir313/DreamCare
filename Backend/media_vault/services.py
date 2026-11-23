"""Business logic for media vault: EXIF stripping, signed tokens, and access auditing."""

import hashlib
import io
import logging

from django.core import signing
from django.core.exceptions import ValidationError
from django.core.files.base import ContentFile
from django.urls import reverse
from django.utils import timezone
from PIL import Image, ImageOps

from consent.services import get_client_ip
from media_vault.models import FacePhoto, PhotoAccessAuditLog

logger = logging.getLogger(__name__)

ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB
TOKEN_SALT = "dermacare-vault-photo-signing-salt"


def sanitize_and_strip_exif(uploaded_file) -> tuple[ContentFile, str, int]:
    """Validate image, strip all EXIF metadata (GPS, camera info), and re-encode safely."""
    # 1. File size check
    if uploaded_file.size > MAX_FILE_SIZE_BYTES:
        raise ValidationError({"file": ["Photo file size exceeds maximum limit of 10MB."]})

    # 2. Open with Pillow
    try:
        uploaded_file.seek(0)
        img = Image.open(uploaded_file)
        img.verify()
    except Exception as exc:
        raise ValidationError(
            {"file": ["Uploaded file is not a valid or readable image."]}
        ) from exc

    # Re-open after verify()
    uploaded_file.seek(0)
    img = Image.open(uploaded_file)

    # 3. Transpose based on orientation tag if present, then strip all metadata
    try:
        img = ImageOps.exif_transpose(img)
    except Exception:
        pass

    # 4. Normalize format to clean JPEG
    output_io = io.BytesIO()
    # Convert RGBA to RGB for JPEG compatibility
    if img.mode in ("RGBA", "P"):
        img = img.convert("RGB")

    # Save purely as RGB without passing exif
    img.save(output_io, format="JPEG", quality=90, optimize=True)
    sanitized_bytes = output_io.getvalue()

    filename = f"photo_{timezone.now().strftime('%Y%m%d_%H%M%S')}.jpg"
    content_file = ContentFile(sanitized_bytes, name=filename)
    return content_file, "image/jpeg", len(sanitized_bytes)


def create_face_photo(*, user, uploaded_file, angle: str) -> FacePhoto:
    """Sanitize and persist a face photo for a patient."""
    content_file, content_type, file_size = sanitize_and_strip_exif(uploaded_file)

    photo = FacePhoto.objects.create(
        user=user,
        angle=angle,
        image_file=content_file,
        content_type=content_type,
        file_size=file_size,
    )
    logger.info(
        "Face photo saved and sanitized: photo_id=%s, user_id=%s, angle=%s",
        photo.id,
        user.id,
        angle,
    )
    return photo


def generate_signed_photo_url(
    photo: FacePhoto,
    *,
    actor,
    request=None,
    purpose: str = "view_photo",
    expires_in_seconds: int = 900,
) -> str:
    """Generate a short-lived cryptographically signed URL for photo access and record audit log."""
    signer = signing.TimestampSigner(salt=TOKEN_SALT)
    payload = {
        "photo_id": str(photo.id),
        "actor_id": str(actor.id),
    }
    signed_token = signer.sign_object(payload)

    # Log audit entry
    client_ip = get_client_ip(request) if request else "127.0.0.1"
    ip_hash = hashlib.sha256(client_ip.encode("utf-8")).hexdigest()

    PhotoAccessAuditLog.objects.create(
        photo=photo,
        patient=photo.user,
        actor=actor,
        actor_role=getattr(actor, "role", "unknown"),
        ip_hash=ip_hash,
        purpose=purpose,
    )

    view_path = reverse("api_v1:photos:stream_photo", kwargs={"token": signed_token})
    if request:
        return request.build_absolute_uri(view_path)
    return view_path


def verify_signed_photo_token(token: str, max_age_seconds: int = 900) -> FacePhoto:
    """Verify signed token validity, signature, and expiration."""
    signer = signing.TimestampSigner(salt=TOKEN_SALT)
    try:
        payload = signer.unsign_object(token, max_age=max_age_seconds)
    except signing.SignatureExpired as exc:
        raise ValidationError({"detail": "This photo access link has expired."}) from exc
    except signing.BadSignature as exc:
        raise ValidationError({"detail": "Invalid or tampered photo token."}) from exc

    photo_id = payload.get("photo_id")
    try:
        return FacePhoto.objects.get(id=photo_id, is_active=True)
    except FacePhoto.DoesNotExist as exc:
        raise ValidationError(
            {"detail": "The requested photograph was not found or has been removed."}
        ) from exc
