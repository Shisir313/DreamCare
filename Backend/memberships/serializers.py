"""Serializers for plans, memberships, and entitlement states."""

from rest_framework import serializers

from memberships.models import Membership, Plan


class PlanSerializer(serializers.ModelSerializer):
    price_npr = serializers.FloatField(read_only=True)

    class Meta:
        model = Plan
        fields = (
            "id",
            "code",
            "name",
            "description",
            "price_paisa",
            "price_npr",
            "currency",
            "duration_days",
            "consultations_included",
            "checkins_included",
            "features",
            "is_active",
        )


class MembershipSerializer(serializers.ModelSerializer):
    plan = PlanSerializer(read_only=True)
    is_currently_active = serializers.BooleanField(read_only=True)

    class Meta:
        model = Membership
        fields = (
            "id",
            "plan",
            "status",
            "start_date",
            "end_date",
            "consultations_remaining",
            "checkins_remaining",
            "is_currently_active",
            "auto_renew",
            "activated_at",
            "created_at",
        )


class SelectPlanRequestSerializer(serializers.Serializer):
    plan_code = serializers.CharField(
        max_length=50, help_text="Plan code: basic, premium, or pay_per_consultation"
    )


class CancelMembershipRequestSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True, default="")
