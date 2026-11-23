"""Tests for core base models."""

from core.models import TimeStampedModel, UUIDModel


def test_uuid_model_defaults():
    """Verify UUIDModel defines a non-editable UUID4 primary key."""
    field = UUIDModel._meta.get_field("id")
    assert field.primary_key is True
    assert field.editable is False
    assert field.default is not None


def test_timestamped_model_fields():
    """Verify TimeStampedModel has created_at and updated_at datetime fields."""
    fields = [f.name for f in TimeStampedModel._meta.fields]
    assert "created_at" in fields
    assert "updated_at" in fields
