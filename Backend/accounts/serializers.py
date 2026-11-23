"""Serializers for accounts authentication, profile, password, and tokens."""

from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer, TokenRefreshSerializer

from accounts.models import User


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """SimpleJWT serializer adding user claims into JWT token and response."""

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["email"] = user.email
        token["role"] = user.role
        token["name"] = user.name
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        data["user"] = {
            "id": str(self.user.id),
            "email": self.user.email,
            "role": self.user.role,
            "name": self.user.name,
            "phone": self.user.phone,
            "is_onboarded": self.user.is_onboarded,
            "is_email_verified": self.user.is_email_verified,
        }
        return data


class CustomTokenRefreshSerializer(TokenRefreshSerializer):
    pass


class RegisterRequestSerializer(serializers.Serializer):
    email = serializers.EmailField(required=False, allow_blank=True)
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)
    name = serializers.CharField(max_length=255, required=False, default="", allow_blank=True)
    password = serializers.CharField(min_length=8, write_only=True)

    def validate(self, attrs):
        email = attrs.get("email", "").strip()
        phone = attrs.get("phone", "").strip()

        if not email and not phone:
            raise serializers.ValidationError(
                "Either an email address or phone number must be provided."
            )

        # If email is empty but phone is present, formulate fallback internal email
        if not email and phone:
            attrs["email"] = f"{phone}@dermacare.np"

        return attrs


class LoginRequestSerializer(serializers.Serializer):
    phone = serializers.CharField(
        required=False, allow_blank=True, help_text="Phone number or email"
    )
    email = serializers.EmailField(required=False, allow_blank=True, help_text="Email address")
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        identifier = attrs.get("phone") or attrs.get("email")
        if not identifier:
            raise serializers.ValidationError(
                "Please provide either phone number or email address."
            )
        attrs["identifier"] = identifier
        return attrs


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "phone",
            "name",
            "role",
            "date_of_birth",
            "is_email_verified",
            "is_onboarded",
            "date_joined",
        )
        read_only_fields = ("id", "role", "is_email_verified", "is_onboarded", "date_joined")


class UpdateProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("name", "phone", "date_of_birth")


class ChangePasswordSerializer(serializers.Serializer):
    current_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(min_length=8, write_only=True)


class PasswordResetRequestSerializer(serializers.Serializer):
    identifier = serializers.CharField(help_text="Email address or phone number")


class PasswordResetConfirmSerializer(serializers.Serializer):
    code = serializers.CharField(max_length=64, help_text="6-digit reset code or token")
    new_password = serializers.CharField(min_length=8, write_only=True)


class EmailVerifyConfirmSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=64)


class LogoutRequestSerializer(serializers.Serializer):
    refresh = serializers.CharField(help_text="The refresh token to be blacklisted")


class AuthSuccessResponseSerializer(serializers.Serializer):
    access = serializers.CharField()
    refresh = serializers.CharField()
    user = UserProfileSerializer()
