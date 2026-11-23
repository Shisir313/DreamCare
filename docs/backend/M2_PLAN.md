# Milestone 2 Plan: Profiles and Photos

## Objectives
1. Implement clinical and lifestyle onboarding profiles in a dedicated `profiles` app:
   - `SkinProfile`: `skin_type` (dry, oily, combination, normal, sensitive), `skin_tone` (Fitzpatrick I-VI / fair, medium, olive, deep), `conditions` (eczema, psoriasis, rosacea, dermatitis, none, etc.), `concerns` (acne, darkSpots, wrinkles, redness, dryness, oiliness, largePores, dullness), `routine_level` (beginner, intermediate, advanced), `sun_exposure` (low, moderate, high).
   - `LifestyleProfile`: `height_cm`, `weight_kg`, `age`, `sleep_hours`, `stress_level` (low, moderate, high), `activity_level` (sedentary, light, moderate, active).
   - Server-side calculation of BMI: `BMI = weight_kg / (height_m ^ 2)` with classification (`underweight`, `normal`, `overweight`, `obese`).
2. Private facial photographic assessment and audit logging in a dedicated `media_vault` app:
   - `FacePhoto` model: angles (`front`, `left`, `right`), `file_path`, file size, MIME type.
   - Strict validation: Allowed MIME types (`image/jpeg`, `image/png`, `image/webp`), max file size (e.g., 10MB).
   - Privacy-first image sanitation: Strip all EXIF metadata (GPS coordinates, camera serial numbers, device model) using Pillow before persisting.
   - Private object storage: Photos stored in non-public storage; access granted strictly via short-lived signed URLs (e.g., 15-minute expiration) with cryptographic HMAC signatures.
   - Audit logging: `PhotoAccessAuditLog` tracking every single view/generation of signed URLs (`user`, `photo`, `actor_role`, `accessed_at`, `ip_hash`, `purpose`).
3. Privacy Rights & Compliance (Nepal Individual Privacy Act 2018):
   - Data export: `GET /api/v1/me/export/` returning complete, machine-readable JSON archive of user account, consents, skin profiles, measurements, and metadata.
   - Hard deletion: `DELETE /api/v1/me/` allowing user-initiated account deletion, removing database records and deleting all face photos from physical storage.
   - Retention documentation: Clear legal disclaimer of what is retained (e.g. anonymized payment transaction references required for financial accounting/anti-fraud audit under Nepal's financial laws).

## Endpoints (M2)

| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/profile/skin/` | IsAuthenticated + HasCurrentConsent | Retrieve skin profile. |
| `PUT/PATCH` | `/api/v1/profile/skin/` | IsAuthenticated + HasCurrentConsent | Create or update skin profile attributes. |
| `GET` | `/api/v1/profile/lifestyle/` | IsAuthenticated + HasCurrentConsent | Retrieve lifestyle profile and server-computed BMI. |
| `PUT/PATCH` | `/api/v1/profile/lifestyle/` | IsAuthenticated + HasCurrentConsent | Create or update lifestyle and physical measurements. |
| `POST` | `/api/v1/photos/upload/` | IsAuthenticated + HasCurrentConsent | Upload face photo (angle: front/left/right), strips EXIF, validates type/size. |
| `GET` | `/api/v1/photos/` | IsAuthenticated + HasCurrentConsent | List user's active photos with short-lived signed URLs (audited). |
| `GET` | `/api/v1/photos/{id}/url/` | IsAuthenticated + HasCurrentConsent | Generate fresh short-lived signed URL for a photo (audited). |
| `GET` | `/api/v1/photos/view/{token}/` | AllowAny (token-verified) | Stream private photo binary verifying signature and expiration. |
| `GET` | `/api/v1/me/export/` | IsAuthenticated | Export complete user data archive in JSON format. |
| `DELETE` | `/api/v1/me/` | IsAuthenticated | Hard deletion of account, clinical data, and storage files. |

## Test Plan
1. Profile & BMI:
   - Create and retrieve skin profile.
   - Calculate BMI correctly (e.g. 70kg, 175cm -> BMI 22.9, 'normal').
   - Reject unconsented user with 403 `consent_required`.
2. Face Photo Upload & Privacy:
   - Reject invalid MIME types (e.g., text/plain, exe) and oversized files (>10MB).
   - Verify EXIF stripping (create image with simulated GPS tag, verify saved image has no EXIF).
   - Generate short-lived signed URL and verify access.
   - Verify audit log is generated on signed URL generation/access.
   - Verify patient B cannot access patient A's photo.
3. Export & Hard Deletion:
   - `GET /api/v1/me/export/` returns all user data.
   - `DELETE /api/v1/me/` purges database records and deletes uploaded files from disk/storage.
