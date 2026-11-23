"""Serializers for face photos and upload validation."""

from rest_framework import serializers

from media_vault.models import FacePhoto, PhotoAngle
from media_vault.services import generate_signed_photo_url


class FacePhotoUploadSerializer(serializers.Serializer):
    angle = serializers.ChoiceField(choices=PhotoAngle.choices, default=PhotoAngle.FRONT)
    file = serializers.ImageField(help_text="Facial image file (JPEG, PNG, WEBP, up to 10MB)")


class FacePhotoResponseSerializer(serializers.ModelSerializer):
    signed_url = serializers.SerializerMethodField()

    class Meta:
        model = FacePhoto
        fields = (
            "id",
            "angle",
            "file_size",
            "content_type",
            "signed_url",
            "created_at",
        )

    def get_signed_url(self, obj) -> str:
        request = self.context.get("request")
        actor = request.user if request else obj.user
        return generate_signed_photo_url(obj, actor=actor, request=request)


class SignedUrlResponseSerializer(serializers.Serializer):
    photo_id = serializers.UUIDField()
    signed_url = serializers.URLField()
    expires_in_seconds = serializers.IntegerField(default=900)
