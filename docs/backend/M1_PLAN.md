# Milestone 1 Plan: Accounts and Consent

## Objectives
1. Implement complete authentication and account management for DermaCare:
   - Patient registration: `POST /api/v1/auth/register/` (strictly creates `patient` role; dermatologists and admins cannot self-register).
   - Dual-identifier login: Support login by either `email` or `phone` (with password) to seamlessly support the Flutter client mocks with no screen changes.
   - Logout: `POST /api/v1/auth/logout/` blacklisting the refresh token.
   - Email verification: Token generation and confirmation endpoints.
   - Password reset: Request reset token/code and confirm new password.
   - Password change: `POST /api/v1/auth/password/change/` with current password verification.
   - Current user profile: `GET/PATCH /api/v1/auth/me/`.
2. Privacy-first versioned consent management (`consent` app):
   - `ConsentRecord` model tracking user consent per policy type (`terms_of_service`, `privacy_policy`, `health_data_consent`, `telemedicine_consent`), version, acceptance timestamp in UTC, and privacy-preserving SHA-256 hashes of client IP and User-Agent (no plaintext IP storage, meeting Nepal Individual Privacy Act 2018 best practices).
   - Endpoints to list required policies (`GET /api/v1/consent/policies/`) and record acceptance (`POST /api/v1/consent/accept/`).
   - `HasCurrentConsent` permission class enforcing that users have accepted all mandatory active policies before accessing clinical or onboarding endpoints.

## Endpoints (M1)

| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/auth/register/` | AllowAny | Register new patient account with name, email/phone, password. |
| `POST` | `/api/v1/auth/login/` | AllowAny | Authenticate via email or phone + password, returns JWT tokens and user profile. |
| `POST` | `/api/v1/auth/logout/` | IsAuthenticated | Invalidate session by blacklisting refresh token. |
| `GET` | `/api/v1/auth/me/` | IsAuthenticated | Retrieve current user profile and consent summary. |
| `PATCH` | `/api/v1/auth/me/` | IsAuthenticated | Update profile details (name, phone, date_of_birth). |
| `POST` | `/api/v1/auth/password/change/` | IsAuthenticated | Change password by verifying current password. |
| `POST` | `/api/v1/auth/password/reset/request/` | AllowAny | Request password reset token via email or phone. |
| `POST` | `/api/v1/auth/password/reset/confirm/` | AllowAny | Confirm password reset using valid token and new password. |
| `POST` | `/api/v1/auth/email/verify/request/` | IsAuthenticated | Request email verification link/token. |
| `POST` | `/api/v1/auth/email/verify/confirm/` | AllowAny | Verify email address with token. |
| `GET` | `/api/v1/consent/policies/` | AllowAny / IsAuthenticated | List active policy versions and user acceptance state. |
| `POST` | `/api/v1/consent/accept/` | IsAuthenticated | Submit acceptance of required policy versions. |
| `GET` | `/api/v1/consent/status/` | IsAuthenticated | Check if user has accepted all current mandatory consents. |

## Models (M1)
1. In `accounts`:
   - `User` additions: `date_of_birth` (DateField, null=True), `is_email_verified` (BooleanField, default=False), `is_onboarded` (BooleanField, default=False).
   - `EmailVerificationToken` (UUIDModel, TimeStampedModel): token, user, expires_at, is_used.
   - `PasswordResetToken` (UUIDModel, TimeStampedModel): token, user, expires_at, is_used.
2. In `consent`:
   - `ConsentPolicy`: `policy_type`, `version`, `title`, `content_url_or_summary`, `is_mandatory`, `is_active`.
   - `ConsentRecord` (CoreBaseModel): `user`, `policy`, `policy_type`, `policy_version`, `accepted_at`, `ip_hash`, `user_agent_hash`.

## Test Plan
1. Registration:
   - Patient successfully registered.
   - Attempting to pass `role: "admin"` or `role: "dermatologist"` is blocked / forced to `patient`.
   - Duplicate email or duplicate phone rejects with 400 `validation_error`.
2. Login & Logout:
   - Login with email succeeds.
   - Login with phone succeeds.
   - Logout blacklists refresh token; subsequent refresh fails.
3. Password & Profile:
   - `GET /api/v1/auth/me/` returns profile and role.
   - `PATCH /api/v1/auth/me/` updates name and phone.
   - `POST /api/v1/auth/password/change/` checks current password and changes hash.
   - Password reset request and confirm flow.
4. Consent:
   - Anonymous user lists current active policies.
   - Authenticated user accepts current policies. SHA-256 IP and UA hash stored, no raw IP logged.
   - `HasCurrentConsent` permission allows access once all mandatory policies are accepted, rejects with 403 `consent_required` if outdated or unaccepted.
