"""Serializers for consent management APIs."""

from rest_framework import serializers

from consent.models import ConsentPolicy, ConsentRecord


class ConsentPolicySerializer(serializers.ModelSerializer):
    is_accepted = serializers.SerializerMethodField()

    class Meta:
        model = ConsentPolicy
        fields = (
            "id",
            "policy_type",
            "version",
            "title",
            "summary",
            "document_url",
            "is_mandatory",
            "is_active",
            "is_accepted",
        )

    def get_is_accepted(self, obj) -> bool:
        user = self.context.get("request").user if "request" in self.context else None
        if not user or not user.is_authenticated:
            return False
        return ConsentRecord.objects.filter(
            user=user,
            policy_type=obj.policy_type,
            policy_version=obj.version,
        ).exists()


class PolicyAcceptItemSerializer(serializers.Serializer):
    policy_type = serializers.CharField(max_length=50)
    version = serializers.CharField(max_length=20)


class AcceptConsentRequestSerializer(serializers.Serializer):
    consents = PolicyAcceptItemSerializer(many=True)


class ConsentStatusResponseSerializer(serializers.Serializer):
    has_current_consent = serializers.BooleanField()
    missing_policies = ConsentPolicySerializer(many=True)
