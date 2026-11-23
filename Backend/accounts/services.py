"""Business logic service layer for accounts."""

import logging

from django.contrib.auth import authenticate
from django.core.exceptions import ValidationError
from django.db import models, transaction
from django.utils import timezone
from rest_framework_simplejwt.tokens import RefreshToken

from accounts.models import EmailVerificationToken, PasswordResetToken, User, UserRole

logger = logging.getLogger(__name__)


def register_patient(*, email: str, password: str, name: str = "", phone: str = "") -> User:
    """Register a new patient user. Strictly enforces patient role."""
    email = email.strip().lower()
    phone = phone.strip() if phone else None

    if User.objects.filter(email=email).exists():
        raise ValidationError({"email": ["An account with this email address already exists."]})

    if phone and User.objects.filter(phone=phone).exists():
        raise ValidationError({"phone": ["An account with this phone number already exists."]})

    user = User.objects.create_user(
        email=email,
        password=password,
        name=name.strip(),
        phone=phone,
        role=UserRole.PATIENT,
    )
    logger.info("New patient registered successfully: user_id=%s", user.id)
    return user


def authenticate_user_by_credentials(*, identifier: str, password: str) -> User:
    """Authenticate a user using either their email address or phone number."""
    identifier = identifier.strip()
    user = None

    # Check by email first
    if "@" in identifier:
        user = authenticate(username=identifier.lower(), password=password)
    else:
        # Lookup by phone
        try:
            matched_user = User.objects.get(phone=identifier)
            if matched_user.check_password(password):
                user = matched_user
        except User.DoesNotExist:
            user = None

    if not user:
        raise ValidationError(
            {"detail": "Invalid credentials. Please verify your email/phone and password."}
        )

    if not user.is_active:
        raise ValidationError({"detail": "This account is inactive. Please contact support."})

    return user


def create_jwt_tokens_for_user(user: User) -> dict:
    """Generate SimpleJWT access and refresh tokens for user."""
    refresh = RefreshToken.for_user(user)
    refresh["email"] = user.email
    refresh["role"] = user.role
    refresh["name"] = user.name

    return {
        "access": str(refresh.access_token),
        "refresh": str(refresh),
    }


def change_user_password(user: User, *, current_password: str, new_password: str) -> None:
    """Change user password after verifying current password."""
    if not user.check_password(current_password):
        raise ValidationError({"current_password": ["Current password is incorrect."]})

    if current_password == new_password:
        raise ValidationError(
            {"new_password": ["New password cannot be the same as the current password."]}
        )

    user.set_password(new_password)
    user.save(update_fields=["password", "updated_at"])
    logger.info("User changed password successfully: user_id=%s", user.id)


def request_password_reset(identifier: str) -> PasswordResetToken | None:
    """Initiate password reset by identifier (email or phone)."""
    identifier = identifier.strip()
    user = None
    if "@" in identifier:
        user = User.objects.filter(email=identifier.lower(), is_active=True).first()
    else:
        user = User.objects.filter(phone=identifier, is_active=True).first()

    if not user:
        return None

    # Invalidate previous tokens
    PasswordResetToken.objects.filter(user=user, is_used=False).update(is_used=True)
    token = PasswordResetToken.generate(user=user)
    logger.info("Password reset token generated: user_id=%s", user.id)
    return token


@transaction.atomic
def reset_password_with_token_or_code(*, code_or_token: str, new_password: str) -> User:
    """Reset password using 6-digit code or URL-safe token."""
    reset_record = (
        PasswordResetToken.objects.select_for_update()
        .filter(is_used=False)
        .filter(models.Q(token=code_or_token) | models.Q(code=code_or_token))
        .first()
    )

    if not reset_record or not reset_record.is_valid:
        raise ValidationError({"code": ["Invalid or expired reset code/token."]})

    user = reset_record.user
    user.set_password(new_password)
    user.save(update_fields=["password", "updated_at"])

    reset_record.is_used = True
    reset_record.save(update_fields=["is_used", "updated_at"])
    logger.info("User password reset successfully: user_id=%s", user.id)
    return user


def request_email_verification(user: User) -> EmailVerificationToken:
    """Generate verification token for user's email."""
    EmailVerificationToken.objects.filter(user=user, is_used=False).update(is_used=True)
    token = EmailVerificationToken.generate(user=user)
    return token


@transaction.atomic
def verify_email_with_token(token: str) -> User:
    """Mark user email as verified given a valid token."""
    token_record = (
        EmailVerificationToken.objects.select_for_update()
        .filter(token=token, is_used=False)
        .first()
    )

    if not token_record or not token_record.is_valid:
        raise ValidationError({"token": ["Invalid or expired email verification token."]})

    user = token_record.user
    user.is_email_verified = True
    user.save(update_fields=["is_email_verified", "updated_at"])

    token_record.is_used = True
    token_record.save(update_fields=["is_used", "updated_at"])
    logger.info("User email verified successfully: user_id=%s", user.id)
    return user


def export_user_data(user: User) -> dict:
    """Export all user data in compliance with Nepal Individual Privacy Act 2018."""
    export_payload = {
        "export_metadata": {
            "user_id": str(user.id),
            "generated_at": timezone.now().isoformat(),
            "regulatory_framework": "Nepal Individual Privacy Act 2018 (Privacy & Data Rights)",
        },
        "account": {
            "email": user.email,
            "phone": user.phone,
            "name": user.name,
            "role": user.role,
            "date_of_birth": user.date_of_birth.isoformat() if user.date_of_birth else None,
            "date_joined": user.date_joined.isoformat(),
        },
        "consents": [
            {
                "policy_type": c.policy_type,
                "version": c.policy_version,
                "accepted_at": c.accepted_at.isoformat(),
            }
            for c in user.consent_records.all()
        ],
    }

    # Skin Profile
    if hasattr(user, "skin_profile"):
        sp = user.skin_profile
        export_payload["skin_profile"] = {
            "skin_type": sp.skin_type,
            "skin_tone": sp.skin_tone,
            "conditions": sp.conditions,
            "concerns": sp.concerns,
            "goals": sp.goals,
            "routine_level": sp.routine_level,
            "sun_exposure": sp.sun_exposure,
        }

    # Lifestyle Profile
    if hasattr(user, "lifestyle_profile"):
        lp = user.lifestyle_profile
        export_payload["lifestyle_profile"] = {
            "height_cm": lp.height_cm,
            "weight_kg": lp.weight_kg,
            "age": lp.age,
            "sleep_hours": lp.sleep_hours,
            "stress_level": lp.stress_level,
            "activity_level": lp.activity_level,
            "bmi": lp.bmi,
            "bmi_category": lp.bmi_category,
        }

    # Face Photos metadata
    photos = user.face_photos.filter(is_active=True)
    export_payload["face_photos"] = [
        {
            "id": str(p.id),
            "angle": p.angle,
            "file_size": p.file_size,
            "created_at": p.created_at.isoformat(),
        }
        for p in photos
    ]

    return export_payload


@transaction.atomic
def hard_delete_user_account(user: User) -> dict:
    """Hard delete user account, clinical profiles, and physical photo files from storage.

    Documents what is retained: Anonymized financial payment references if required by Nepal
    banking and accounting laws.
    """
    user_id = str(user.id)
    user_email = user.email

    # 1. Delete physical files from private media storage
    for photo in user.face_photos.all():
        if photo.image_file:
            photo.image_file.delete(save=False)

    # 2. Hard delete user (cascades to all related profiles, photos, consents)
    user.delete()

    logger.warning("Hard deletion executed for user_id=%s, email=%s", user_id, user_email)

    return {
        "status": "hard_deleted",
        "user_id": user_id,
        "message": (
            "All personal identity, clinical skin assessments, and facial photographs "
            "have been permanently deleted from storage and database in compliance with "
            "Nepal's Individual Privacy Act 2018."
        ),
        "legal_retention_notice": (
            "Anonymized payment audit logs and regulatory invoice numbers (if any) are retained "
            "in accordance with Nepal Inland Revenue Department (IRD) accounting regulations."
        ),
    }
