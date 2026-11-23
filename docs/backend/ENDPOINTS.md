# Backend API Endpoints (v1)

Base URL: `/api/v1/`
OpenAPI Schema: `/api/schema/`
Interactive Swagger Documentation: `/api/docs/`
ReDoc Documentation: `/api/redoc/`

## Health & System
| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/health/` | AllowAny | Returns system status, UTC & Asia/Kathmandu timestamps, and DB status. |

## Authentication & Accounts (`/api/v1/auth/` and `/api/v1/me/`)
| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/auth/register/` | AllowAny | Register patient account (strictly provisions role `patient`). |
| `POST` | `/api/v1/auth/login/` | AllowAny | Authenticate via email or phone + password. Returns JWT and user profile. |
| `POST` | `/api/v1/auth/token/` | AllowAny | SimpleJWT standard token obtain endpoint. |
| `POST` | `/api/v1/auth/token/refresh/` | AllowAny | Refresh access token with rotation and blacklist. |
| `POST` | `/api/v1/auth/logout/` | IsAuthenticated | Invalidate session by blacklisting the refresh token. |
| `GET` | `/api/v1/auth/me/` | IsAuthenticated | Retrieve current user profile. |
| `PATCH` | `/api/v1/auth/me/` | IsAuthenticated | Update profile fields (name, phone, date_of_birth). |
| `DELETE` | `/api/v1/me/` | IsAuthenticated | User-initiated hard deletion of account and stored facial photographs. |
| `GET` | `/api/v1/me/export/` | IsAuthenticated | Download full machine-readable JSON data export archive. |
| `POST` | `/api/v1/auth/password/change/` | IsAuthenticated | Change password by verifying current password. |
| `POST` | `/api/v1/auth/password/reset/request/` | AllowAny | Request 6-digit password reset code. |
| `POST` | `/api/v1/auth/password/reset/confirm/` | AllowAny | Reset password using 6-digit code or reset token. |
| `POST` | `/api/v1/auth/email/verify/request/` | IsAuthenticated | Request email verification token. |
| `POST` | `/api/v1/auth/email/verify/confirm/` | AllowAny | Confirm email address with token. |

## Privacy & Consent (`/api/v1/consent/`)
| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/consent/policies/` | AllowAny | List active policies, versions, summaries, and user acceptance status. |
| `POST` | `/api/v1/consent/accept/` | IsAuthenticated | Accept mandatory policies; computes SHA-256 hash of IP & UA. |
| `GET` | `/api/v1/consent/status/` | IsAuthenticated | Check if user has satisfied all active mandatory consents. |

## Clinical Profiles & Measurements (`/api/v1/profile/`)
| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/profile/skin/` | IsAuthenticated + Consent | Retrieve clinical skin profile, type, concerns, and routine level. |
| `PUT/PATCH` | `/api/v1/profile/skin/` | IsAuthenticated + Consent | Create or update skin profile attributes. |
| `GET` | `/api/v1/profile/lifestyle/` | IsAuthenticated + Consent | Retrieve lifestyle factors, measurements, and server-computed BMI. |
| `PUT/PATCH` | `/api/v1/profile/lifestyle/` | IsAuthenticated + Consent | Update measurements (height, weight, sleep, stress, activity). |

## Private Facial Photos Vault (`/api/v1/photos/`)
| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/photos/upload/` | IsAuthenticated + Consent | Upload face photo (angle: front/left/right), strips EXIF, validates format/size. |
| `GET` | `/api/v1/photos/` | IsAuthenticated + Consent | List active face photos with short-lived signed URLs. |
| `GET` | `/api/v1/photos/{id}/url/` | IsAuthenticated + Consent | Generate fresh audited 15-minute signed URL. |
| `GET` | `/api/v1/photos/view/{token}/` | AllowAny (token-verified) | Stream private photo binary without caching; verifies signature and expiration. |

## Rule Engine, Routines & Hydration (`/api/v1/routines/` and `/api/v1/hydration/`)
| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/routines/generate/` | IsAuthenticated + Consent | Evaluate versioned rules against skin & lifestyle profile to build custom AM/PM routine. |
| `GET` | `/api/v1/routines/current/` | IsAuthenticated + Consent | Retrieve active routine, morning/evening tasks, and today's completion status. |
| `POST` | `/api/v1/routines/tasks/{id}/toggle/` | IsAuthenticated + Consent | Check-off or uncheck a routine task for today in Asia/Kathmandu. |
| `GET` | `/api/v1/routines/daily-summary/` | IsAuthenticated + Consent | Aggregated daily progress: task checklist completion and water intake stats. |
| `GET/PUT` | `/api/v1/routines/reminders/` | IsAuthenticated + Consent | Retrieve or update reminder notification times (AM/PM routines and hydration). |
| `GET` | `/api/v1/hydration/goal/` | IsAuthenticated + Consent | Retrieve daily hydration target, formula citation, and clinical limitations. |
| `POST` | `/api/v1/hydration/goal/calculate/` | IsAuthenticated + Consent | Recalculate target fluid intake based on body weight (35 mL/kg). |
| `POST` | `/api/v1/hydration/log/` | IsAuthenticated + Consent | Log water intake (+1 glass / 250ml) for today. |
| `GET` | `/api/v1/hydration/today/` | IsAuthenticated + Consent | Get today's water tracking model (glasses completed, daily goal, timestamps). |

## Plans & Memberships (`/api/v1/plans/` and `/api/v1/memberships/`)
| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/plans/` | AllowAny | List active plans with integer paisa and formatted NPR prices, entitlements, and features. |
| `GET` | `/api/v1/memberships/current/` | IsAuthenticated | Get current active membership, state, expiration, and remaining consultation/checkin quotas. |
| `POST` | `/api/v1/memberships/select/` | IsAuthenticated + Consent | Select plan and provision pending membership for checkout. |
| `POST` | `/api/v1/memberships/{id}/cancel/` | IsAuthenticated | Cancel active or pending membership. |
| `GET` | `/api/v1/memberships/history/` | IsAuthenticated | View all past and current memberships for authenticated user. |

## Payments & Gateways (`/api/v1/payments/`)
| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/payments/orders/create/` | IsAuthenticated + Consent | Create payment order with client idempotency key. |
| `POST` | `/api/v1/payments/checkout/initiate/` | IsAuthenticated + Consent | Initiate gateway checkout for eSewa (ePay v2 form) or Khalti (pidx URL). |
| `POST` | `/api/v1/payments/verify/` | IsAuthenticated | Authoritative server-to-server verification; activates membership upon gateway success. |
| `POST` | `/api/v1/payments/webhook/{gateway}/` | AllowAny | Replay-safe gateway webhook / IPN handler with server lookup. |
| `GET` | `/api/v1/payments/orders/{order_id}/` | IsAuthenticated | Retrieve payment order status, amount in paisa, and attempt history. |

## Consultations & Video Room Tokens (`/api/v1/consultations/`)
| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/consultations/doctors/` | AllowAny | List verified dermatologists (supports specialty and search filters). |
| `GET` | `/api/v1/consultations/doctors/{id}/` | AllowAny | Get doctor profile, experience, fees, hospital affiliation, and languages. |
| `GET` | `/api/v1/consultations/doctors/{id}/slots/` | AllowAny | List unbooked availability slots for doctor on a specific date in Asia/Kathmandu. |
| `POST` | `/api/v1/consultations/slots/create/` | IsAuthenticated (Doctor/Admin) | Create availability slot. |
| `POST` | `/api/v1/consultations/book/` | IsAuthenticated + Consent | Book appointment with transactional `select_for_update` row lock and entitlement deduction. |
| `GET` | `/api/v1/consultations/appointments/` | IsAuthenticated | List appointments for patient or dermatologist. |
| `GET` | `/api/v1/consultations/appointments/{id}/` | IsAuthenticated | Get appointment details, doctor info, symptoms, and room channel. |
| `POST` | `/api/v1/consultations/appointments/{id}/cancel/` | IsAuthenticated | Cancel appointment, releases slot, restores entitlement if > 2h before start. |
| `POST` | `/api/v1/consultations/appointments/{id}/reschedule/` | IsAuthenticated | Atomically swap to a new availability slot with the same doctor. |
| `POST` | `/api/v1/consultations/appointments/{id}/video-token/` | IsAuthenticated | Generate Agora RTC room token (join window opens 15m prior to start). |

## Prescriptions & Clinical Records (`/api/v1/prescriptions/`)
| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/prescriptions/` | IsAuthenticated | List prescriptions for current patient or authoring doctor. |
| `POST` | `/api/v1/prescriptions/` | IsAuthenticated (Verified Doctor) | Author a new clinical prescription or draft. |
| `GET` | `/api/v1/prescriptions/{id}/` | IsAuthenticated | Get prescription details (audited read for patient with hashed IP/UA). |
| `POST` | `/api/v1/prescriptions/{id}/publish/` | IsAuthenticated (Author Doctor) | Lock draft into permanent immutable published state. |
| `POST` | `/api/v1/prescriptions/{id}/amend/` | IsAuthenticated (Author Doctor) | Create version v+1 amendment while keeping original published record. |

## Weekly Photo Check-ins (`/api/v1/prescriptions/check-ins/` and `/api/v1/check-ins/`)
| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/prescriptions/check-ins/status/` | IsAuthenticated | Get 4-week unlock schedule, local unlock dates in Asia/Kathmandu, and status. |
| `POST` | `/api/v1/prescriptions/check-ins/submit/` | IsAuthenticated + Consent | Submit weekly face photos (front/left/right) and note. Consumes check-in entitlement. |
| `GET` | `/api/v1/prescriptions/check-ins/history/` | IsAuthenticated | View past check-in history and doctor guidance (accessible even after plan expiry). |
| `POST` | `/api/v1/prescriptions/check-ins/{id}/review/` | IsAuthenticated (Verified Doctor) | Dermatologist reviews photos and submits clinical guidance. |

## Notifications & Push Devices (`/api/v1/notifications/`)
| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/notifications/` | IsAuthenticated | List notifications for authenticated user (filter by `unread_only=true`). |
| `POST` | `/api/v1/notifications/{id}/read/` | IsAuthenticated | Mark specific notification as read. |
| `POST` | `/api/v1/notifications/mark-all-read/` | IsAuthenticated | Mark all unread notifications as read for current user. |
| `POST` | `/api/v1/notifications/devices/register/` | IsAuthenticated | Register or update FCM device push token with platform (`android`/`ios`/`web`). |
