"""Shared base models for DermaCare."""

import uuid

from django.db import models


class UUIDModel(models.Model):
    """Abstract model providing a UUID primary key."""

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Unique identifier (UUIDv4)",
    )

    class Meta:
        abstract = True


class TimeStampedModel(models.Model):
    """Abstract model providing created and updated timestamps in UTC."""

    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
        help_text="Timestamp when the record was created (UTC)",
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="Timestamp when the record was last updated (UTC)",
    )

    class Meta:
        abstract = True


class CoreBaseModel(UUIDModel, TimeStampedModel):
    """Abstract model combining UUID primary key and timestamp tracking."""

    class Meta:
        abstract = True
