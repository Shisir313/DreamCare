"""Business logic for consent recording and compliance checks."""

import logging

from django.core.exceptions import ValidationError
from django.db import transaction
from django.utils import timezone

from consent.models import ConsentPolicy, ConsentRecord, PolicyType

logger = logging.getLogger(__name__)


def get_client_ip(request) -> str:
    """Extract client IP handling reverse proxy headers."""
    x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
    if x_forwarded_for:
        return x_forwarded_for.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR", "127.0.0.1")


def get_active_policies():
    """Retrieve all currently active consent policies."""
    return ConsentPolicy.objects.filter(is_active=True)


def check_user_has_current_consent(user) -> bool:
    """Check if the user has accepted the latest version of all mandatory policies."""
    if not user.is_authenticated:
        return False

    if user.is_staff or user.is_superuser:
        return True

    mandatory_policies = ConsentPolicy.objects.filter(is_active=True, is_mandatory=True)
    for policy in mandatory_policies:
        accepted = ConsentRecord.objects.filter(
            user=user,
            policy_type=policy.policy_type,
            policy_version=policy.version,
        ).exists()
        if not accepted:
            return False

    return True


@transaction.atomic
def record_user_consents(*, user, consents: list[dict], request) -> list[ConsentRecord]:
    """Record consent acceptances for a list of policies with IP/UA hashing.

    consents format: [{"policy_type": "terms_of_service", "version": "1.0"}, ...]
    """
    client_ip = get_client_ip(request)
    user_agent = request.META.get("HTTP_USER_AGENT", "Unknown")

    ip_hash = ConsentRecord.hash_value(client_ip)
    ua_hash = ConsentRecord.hash_value(user_agent)
    now = timezone.now()

    records = []
    for item in consents:
        ptype = item.get("policy_type")
        pversion = item.get("version")

        # Verify policy exists and is active
        policy = ConsentPolicy.objects.filter(
            policy_type=ptype,
            version=pversion,
            is_active=True,
        ).first()

        if not policy:
            raise ValidationError(
                {"consent": [f"Policy '{ptype}' version '{pversion}' is not an active policy."]}
            )

        # Check if already accepted to avoid duplicate records
        record, created = ConsentRecord.objects.get_or_create(
            user=user,
            policy_type=ptype,
            policy_version=pversion,
            defaults={
                "accepted_at": now,
                "ip_hash": ip_hash,
                "user_agent_hash": ua_hash,
            },
        )
        records.append(record)
        logger.info(
            "Consent recorded: user_id=%s, policy=%s, version=%s, created=%s",
            user.id,
            ptype,
            pversion,
            created,
        )

    return records


def initialize_default_policies():
    """Seed baseline standard policies for DermaCare Nepal."""
    defaults = [
        {
            "policy_type": PolicyType.TERMS_OF_SERVICE,
            "version": "1.0",
            "title": "Terms of Service",
            "summary": "Governs the use of DermaCare services, advisory recommendations, and appointment scheduling in Nepal.",
            "is_mandatory": True,
            "is_active": True,
        },
        {
            "policy_type": PolicyType.PRIVACY_POLICY,
            "version": "1.0",
            "title": "Privacy Policy",
            "summary": "Explains data handling, encryption, and hard deletion rights in compliance with Nepal's Individual Privacy Act 2018.",
            "is_mandatory": True,
            "is_active": True,
        },
        {
            "policy_type": PolicyType.HEALTH_DATA_CONSENT,
            "version": "1.0",
            "title": "Health & Skin Data Processing Consent",
            "summary": "Explicit authorization to store and process facial photographs, skin condition history, and consultation notes.",
            "is_mandatory": True,
            "is_active": True,
        },
        {
            "policy_type": PolicyType.TELEMEDICINE_CONSENT,
            "version": "1.0",
            "title": "Telemedicine & Advisory Disclaimer",
            "summary": "Explicit agreement that rule-based skin routines are educational and advisory, not medical diagnoses. Video consultations are conducted with licensed dermatologists.",
            "is_mandatory": True,
            "is_active": True,
        },
    ]

    for p in defaults:
        ConsentPolicy.objects.get_or_create(
            policy_type=p["policy_type"],
            version=p["version"],
            defaults=p,
        )
