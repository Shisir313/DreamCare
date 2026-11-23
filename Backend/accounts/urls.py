"""URL routing for accounts and auth endpoints."""

from django.urls import path

from accounts.views import (
    ChangePasswordView,
    CurrentUserView,
    CustomTokenObtainPairView,
    CustomTokenRefreshView,
    EmailVerifyConfirmView,
    EmailVerifyRequestView,
    LoginView,
    LogoutView,
    PasswordResetConfirmView,
    PasswordResetRequestView,
    RegisterView,
    UserDataExportView,
)

app_name = "accounts"

urlpatterns = [
    # JWT standard endpoints
    path("token/", CustomTokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("token/refresh/", CustomTokenRefreshView.as_view(), name="token_refresh"),
    # Auth endpoints
    path("register/", RegisterView.as_view(), name="register"),
    path("login/", LoginView.as_view(), name="login"),
    path("logout/", LogoutView.as_view(), name="logout"),
    # Current User Profile & Data Rights
    path("me/", CurrentUserView.as_view(), name="current_user"),
    path("me/export/", UserDataExportView.as_view(), name="user_data_export"),
    # Password management
    path("password/change/", ChangePasswordView.as_view(), name="change_password"),
    path(
        "password/reset/request/", PasswordResetRequestView.as_view(), name="password_reset_request"
    ),
    path(
        "password/reset/confirm/", PasswordResetConfirmView.as_view(), name="password_reset_confirm"
    ),
    # Email verification
    path("email/verify/request/", EmailVerifyRequestView.as_view(), name="email_verify_request"),
    path("email/verify/confirm/", EmailVerifyConfirmView.as_view(), name="email_verify_confirm"),
]
