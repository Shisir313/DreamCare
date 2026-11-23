"""Accounts models including custom User model, verification, and reset tokens."""

import secrets
import uuid
from datetime import timedelta

from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models
from django.utils import timezone

from accounts.managers import UserManager
from core.models import CoreBaseModel


class UserRole(models.TextChoices):
    PATIENT = "patient", "Patient"
    DERMATOLOGIST = "dermatologist", "Dermatologist"
    ADMIN = "admin", "Admin"


class User(AbstractBaseUser, PermissionsMixin):
    """Custom User model with email authentication, UUID primary key, and role distinction."""

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Unique user UUIDv4",
    )
    email = models.EmailField(
        unique=True,
        db_index=True,
        help_text="Primary email address used for login and notifications",
    )
    phone = models.CharField(
        max_length=20,
        blank=True,
        null=True,
        db_index=True,
        help_text="Nepal phone number (e.g. 98XXXXXXXX)",
    )
    name = models.CharField(
        max_length=255,
        blank=True,
        help_text="Full legal or preferred name",
    )
    role = models.CharField(
        max_length=20,
        choices=UserRole.choices,
        default=UserRole.PATIENT,
        db_index=True,
        help_text="System actor role: patient, dermatologist, or admin",
    )
    date_of_birth = models.DateField(
        null=True,
        blank=True,
        help_text="Date of birth for age and clinical profile calculation",
    )
    is_email_verified = models.BooleanField(
        default=False,
        help_text="Designates whether the user's email address has been verified",
    )
    is_onboarded = models.BooleanField(
        default=False,
        help_text="Designates whether the user has completed medical onboarding",
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Designates whether this user account is active",
    )
    is_staff = models.BooleanField(
        default=False,
        help_text="Designates whether the user can log into the Django admin site",
    )
    date_joined = models.DateTimeField(
        auto_now_add=True,
        help_text="Date and time when the account was registered (UTC)",
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="Date and time when user record was last updated (UTC)",
    )

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    class Meta:
        db_table = "accounts_user"
        verbose_name = "User"
        verbose_name_plural = "Users"
        ordering = ["-date_joined"]

    def __str__(self):
        return f"{self.email} ({self.role})"

    def get_full_name(self) -> str:
        return self.name or self.email.split("@")[0].title()

    def get_short_name(self) -> str:
        return self.name.split()[0] if self.name else self.email.split("@")[0]

    @property
    def is_patient(self) -> bool:
        return self.role == UserRole.PATIENT

    @property
    def is_dermatologist(self) -> bool:
        return self.role == UserRole.DERMATOLOGIST

    @property
    def is_admin_user(self) -> bool:
        return self.role == UserRole.ADMIN or self.is_superuser


class EmailVerificationToken(CoreBaseModel):
    """Token for confirming user email verification."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="email_tokens")
    token = models.CharField(max_length=64, unique=True, db_index=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)

    class Meta:
        db_table = "accounts_email_verification_token"

    @classmethod
    def generate(cls, user, expires_in_hours=24):
        token_str = secrets.token_urlsafe(32)
        expires_at = timezone.now() + timedelta(hours=expires_in_hours)
        return cls.objects.create(user=user, token=token_str, expires_at=expires_at)

    @property
    def is_valid(self) -> bool:
        return not self.is_used and timezone.now() < self.expires_at


class PasswordResetToken(CoreBaseModel):
    """Token for initiating and confirming password reset."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="password_tokens")
    token = models.CharField(max_length=64, unique=True, db_index=True)
    code = models.CharField(
        max_length=6, db_index=True, help_text="6-digit reset code for mobile UI"
    )
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)

    class Meta:
        db_table = "accounts_password_reset_token"

    @classmethod
    def generate(cls, user, expires_in_minutes=15):
        token_str = secrets.token_urlsafe(32)
        code_str = f"{secrets.randbelow(900000) + 100000}"
        expires_at = timezone.now() + timedelta(minutes=expires_in_minutes)
        return cls.objects.create(user=user, token=token_str, code=code_str, expires_at=expires_at)

    @property
    def is_valid(self) -> bool:
        return not self.is_used and timezone.now() < self.expires_at
