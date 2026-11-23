"""Models for versioned user consent and policy definitions."""

import hashlib

from django.conf import settings
from django.db import models
from django.utils import timezone

from core.models import CoreBaseModel, TimeStampedModel


class PolicyType(models.TextChoices):
    TERMS_OF_SERVICE = "terms_of_service", "Terms of Service"
    PRIVACY_POLICY = "privacy_policy", "Privacy Policy"
    HEALTH_DATA_CONSENT = "health_data_consent", "Health Data Consent"
    TELEMEDICINE_CONSENT = "telemedicine_consent", "Telemedicine Consent"


class ConsentPolicy(TimeStampedModel):
    """Catalog of versioned legal and health policies."""

    policy_type = models.CharField(
        max_length=50,
        choices=PolicyType.choices,
        db_index=True,
        help_text="Type of policy (e.g. privacy, health data, terms)",
    )
    version = models.CharField(
        max_length=20,
        help_text="Policy version identifier (e.g. 1.0, 1.1)",
    )
    title = models.CharField(max_length=255)
    summary = models.TextField(
        help_text="Summary or plain-language description of this policy version"
    )
    document_url = models.URLField(blank=True, help_text="Link to full legal text")
    is_mandatory = models.BooleanField(
        default=True,
        help_text="Whether acceptance is required to access medical and onboarding features",
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Whether this is the currently active version for new consents",
    )

    class Meta:
        db_table = "consent_policy"
        unique_together = ("policy_type", "version")
        ordering = ["policy_type", "-version"]

    def __str__(self):
        return f"{self.get_policy_type_display()} v{self.version} ({'Active' if self.is_active else 'Inactive'})"


class ConsentRecord(CoreBaseModel):
    """Audit log of user consent with privacy-preserving cryptographic hashes."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="consent_records",
        help_text="User who accepted the policy",
    )
    policy_type = models.CharField(
        max_length=50,
        choices=PolicyType.choices,
        db_index=True,
    )
    policy_version = models.CharField(max_length=20)
    accepted_at = models.DateTimeField(default=timezone.now, db_index=True)
    ip_hash = models.CharField(
        max_length=64,
        help_text="SHA-256 hash of client IP address (no plaintext IP stored)",
    )
    user_agent_hash = models.CharField(
        max_length=64,
        help_text="SHA-256 hash of client User-Agent",
    )

    class Meta:
        db_table = "consent_record"
        indexes = [
            models.Index(fields=["user", "policy_type", "policy_version"]),
        ]
        ordering = ["-accepted_at"]

    def __str__(self):
        return f"{self.user.email} accepted {self.policy_type} v{self.policy_version} at {self.accepted_at}"

    @staticmethod
    def hash_value(value: str) -> str:
        """Compute SHA-256 hash of a string value."""
        return hashlib.sha256(value.strip().encode("utf-8")).hexdigest()
