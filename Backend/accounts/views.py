"""Views for authentication, registration, profile, password, and tokens."""

from django.core.exceptions import ValidationError as DjangoValidationError
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import fields, permissions, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from accounts.serializers import (
    AuthSuccessResponseSerializer,
    ChangePasswordSerializer,
    CustomTokenObtainPairSerializer,
    CustomTokenRefreshSerializer,
    EmailVerifyConfirmSerializer,
    LoginRequestSerializer,
    LogoutRequestSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    RegisterRequestSerializer,
    UpdateProfileSerializer,
    UserProfileSerializer,
)
from accounts.services import (
    authenticate_user_by_credentials,
    change_user_password,
    create_jwt_tokens_for_user,
    register_patient,
    request_email_verification,
    request_password_reset,
    reset_password_with_token_or_code,
    verify_email_with_token,
)


@extend_schema(
    summary="Obtain JWT Token Pair",
    description="Takes email and password credentials and returns an access token (15m) and refresh token (7d).",
    tags=["Authentication"],
)
class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer


@extend_schema(
    summary="Refresh JWT Access Token",
    description="Takes a valid refresh token and returns a new access token while rotating and blacklisting the previous refresh token.",
    tags=["Authentication"],
)
class CustomTokenRefreshView(TokenRefreshView):
    serializer_class = CustomTokenRefreshSerializer


class RegisterView(APIView):
    """Patient registration endpoint. Strictly provisions accounts with patient role."""

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Register New Patient",
        description="Creates a new patient user account. Dermatologists and admins are provisioned by admin.",
        request=RegisterRequestSerializer,
        responses={201: AuthSuccessResponseSerializer},
        tags=["Authentication"],
    )
    def post(self, request):
        serializer = RegisterRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            user = register_patient(
                email=serializer.validated_data["email"],
                password=serializer.validated_data["password"],
                name=serializer.validated_data.get("name", ""),
                phone=serializer.validated_data.get("phone", ""),
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        tokens = create_jwt_tokens_for_user(user)
        user_data = UserProfileSerializer(user).data

        return Response(
            {
                "access": tokens["access"],
                "refresh": tokens["refresh"],
                "user": user_data,
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    """Dual-identifier login endpoint supporting email or phone."""

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Login with Phone or Email",
        description="Authenticates with email or Nepal phone number + password. Returns JWT pair and user profile.",
        request=LoginRequestSerializer,
        responses={200: AuthSuccessResponseSerializer},
        tags=["Authentication"],
    )
    def post(self, request):
        serializer = LoginRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            user = authenticate_user_by_credentials(
                identifier=serializer.validated_data["identifier"],
                password=serializer.validated_data["password"],
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        tokens = create_jwt_tokens_for_user(user)
        user_data = UserProfileSerializer(user).data

        return Response(
            {
                "access": tokens["access"],
                "refresh": tokens["refresh"],
                "user": user_data,
            },
            status=status.HTTP_200_OK,
        )


class LogoutView(APIView):
    """Logout endpoint by blacklisting refresh token."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Logout",
        description="Blacklists the provided refresh token.",
        request=LogoutRequestSerializer,
        responses={
            200: inline_serializer(name="LogoutResponse", fields={"detail": fields.CharField()})
        },
        tags=["Authentication"],
    )
    def post(self, request):
        serializer = LogoutRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            token = RefreshToken(serializer.validated_data["refresh"])
            token.blacklist()
        except Exception as exc:
            raise ValidationError({"refresh": ["Invalid or expired refresh token."]}) from exc

        return Response({"detail": "Successfully logged out."}, status=status.HTTP_200_OK)


class CurrentUserView(APIView):
    """Retrieve or update current authenticated user profile."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Get Current User Profile",
        description="Returns full profile of currently authenticated user.",
        responses={200: UserProfileSerializer},
        tags=["Accounts"],
    )
    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Update Current User Profile",
        description="Update profile attributes: name, phone, or date of birth.",
        request=UpdateProfileSerializer,
        responses={200: UserProfileSerializer},
        tags=["Accounts"],
    )
    def patch(self, request):
        serializer = UpdateProfileSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(UserProfileSerializer(request.user).data, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Permanently Delete Account & Photos",
        description="Permanently erases user database records and all facial photographs from storage.",
        responses={
            200: inline_serializer(
                name="AccountHardDeleteInlineResponse",
                fields={"status": fields.CharField(), "message": fields.CharField()},
            )
        },
        tags=["Accounts"],
    )
    def delete(self, request):
        from accounts.services import hard_delete_user_account

        result = hard_delete_user_account(request.user)
        return Response(result, status=status.HTTP_200_OK)


class ChangePasswordView(APIView):
    """Change user password requiring current password verification."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Change Password",
        description="Changes user password upon confirming current password.",
        request=ChangePasswordSerializer,
        responses={
            200: inline_serializer(
                name="ChangePasswordResponse", fields={"detail": fields.CharField()}
            )
        },
        tags=["Accounts"],
    )
    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            change_user_password(
                request.user,
                current_password=serializer.validated_data["current_password"],
                new_password=serializer.validated_data["new_password"],
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response({"detail": "Password changed successfully."}, status=status.HTTP_200_OK)


class PasswordResetRequestView(APIView):
    """Initiate password reset by identifier."""

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Request Password Reset",
        description="Sends a 6-digit reset code or token to user email or phone.",
        request=PasswordResetRequestSerializer,
        responses={
            200: inline_serializer(
                name="PasswordResetRequestResponse", fields={"detail": fields.CharField()}
            )
        },
        tags=["Accounts"],
    )
    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        token = request_password_reset(serializer.validated_data["identifier"])
        # Return generic safe response
        detail = "If an account matches that identifier, a reset code has been sent."
        resp_data = {"detail": detail}
        if token and request.query_params.get("debug") == "true":
            resp_data["code"] = token.code
            resp_data["token"] = token.token

        return Response(resp_data, status=status.HTTP_200_OK)


class PasswordResetConfirmView(APIView):
    """Confirm password reset with code and new password."""

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Confirm Password Reset",
        description="Resets user password with valid 6-digit code or reset token.",
        request=PasswordResetConfirmSerializer,
        responses={
            200: inline_serializer(
                name="PasswordResetConfirmResponse", fields={"detail": fields.CharField()}
            )
        },
        tags=["Accounts"],
    )
    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            reset_password_with_token_or_code(
                code_or_token=serializer.validated_data["code"],
                new_password=serializer.validated_data["new_password"],
            )
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(
            {"detail": "Password has been successfully reset."}, status=status.HTTP_200_OK
        )


class EmailVerifyRequestView(APIView):
    """Request email verification token."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Request Email Verification",
        description="Generates an email verification token for the current user.",
        request=None,
        responses={
            200: inline_serializer(
                name="EmailVerifyRequestResponse", fields={"detail": fields.CharField()}
            )
        },
        tags=["Accounts"],
    )
    def post(self, request):
        token = request_email_verification(request.user)
        resp_data = {"detail": "Verification email has been dispatched."}
        if request.query_params.get("debug") == "true":
            resp_data["token"] = token.token
        return Response(resp_data, status=status.HTTP_200_OK)


class EmailVerifyConfirmView(APIView):
    """Confirm email verification with token."""

    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Confirm Email Verification",
        description="Verifies user's email address using token.",
        request=EmailVerifyConfirmSerializer,
        responses={
            200: inline_serializer(
                name="EmailVerifyConfirmResponse", fields={"detail": fields.CharField()}
            )
        },
        tags=["Accounts"],
    )
    def post(self, request):
        serializer = EmailVerifyConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            verify_email_with_token(serializer.validated_data["token"])
        except DjangoValidationError as exc:
            raise ValidationError(
                exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            ) from exc

        return Response(
            {"detail": "Email address verified successfully."}, status=status.HTTP_200_OK
        )


class UserDataExportView(APIView):
    """Export complete user data archive in compliance with privacy regulations."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Export User Data Archive",
        description="Returns full machine-readable JSON archive of user account, clinical assessments, consents, and photos.",
        responses={
            200: inline_serializer(
                name="UserDataExportResponse", fields={"export_metadata": fields.DictField()}
            )
        },
        tags=["Accounts"],
    )
    def get(self, request):
        from accounts.services import export_user_data

        data = export_user_data(request.user)
        return Response(data, status=status.HTTP_200_OK)


class AccountHardDeleteView(APIView):
    """User-initiated permanent hard deletion of account and stored files."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="Permanently Delete Account & Photos",
        description="Permanently erases user database records and all facial photographs from storage.",
        responses={
            200: inline_serializer(
                name="AccountHardDeleteResponse",
                fields={"status": fields.CharField(), "message": fields.CharField()},
            )
        },
        tags=["Accounts"],
    )
    def delete(self, request):
        from accounts.services import hard_delete_user_account

        result = hard_delete_user_account(request.user)
        return Response(result, status=status.HTTP_200_OK)
