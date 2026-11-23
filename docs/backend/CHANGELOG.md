# Backend Changelog

All notable changes to the DermaCare backend will be documented here.

## [Milestone 8] - Notifications, Admin Customization & Demo Data Seeding - 2026-11-22

### Added
- **In-App & Push Notifications (`notifications`)**:
  - `Notification` model: Stores structured user alerts with types (`consultation_reminder`, `routine_am`, `routine_pm`, `water_reminder`, `prescription_ready`, `checkin_reminder`, `membership_update`, `payment_success`, `general`), action URLs, payload JSON, and read status timestamps.
  - `DeviceToken` model: Securely registers client FCM tokens with platform (`android`, `ios`, `web`) and active state.
  - Push Dispatch Pipeline: Clean `FCMPushService` provider pattern with pluggable mock / production implementations ensuring decoupled device notifications.
  - Dedicated API Endpoints:
    - `GET /api/v1/notifications/`: List user alerts with unread filtering.
    - `POST /api/v1/notifications/{id}/read/`: Mark individual notification read.
    - `POST /api/v1/notifications/mark-all-read/`: Batch mark all notifications read.
    - `POST /api/v1/notifications/devices/register/`: Idempotent device token registration.
- **Comprehensive Custom Django Admin**:
  - Full admin registrations configured across all applications:
    - `accounts`: `UserAdmin` with search, role filters, and consent inline.
    - `consultations`: `DermatologistProfileAdmin` with one-click doctor verification action, `AvailabilitySlotAdmin`, and `AppointmentAdmin`.
    - `prescriptions`: `PrescriptionAdmin`, `WeeklyCheckInAdmin`, and read-only `PrescriptionAccessAuditLogAdmin`.
    - `memberships`: `PlanAdmin` with integer paisa formatting, `MembershipAdmin` with status filters.
    - `payments`: `PaymentOrderAdmin` with nested inline payment attempts and status history, `PaymentAttemptAdmin`.
    - `media_vault`: `FacePhotoAdmin` and read-only `PhotoAccessAuditLogAdmin`.
    - `consent`: `ConsentPolicyAdmin` and read-only `ConsentRecordAdmin`.
    - `profiles`: `SkinProfileAdmin` and `LifestyleProfileAdmin`.
    - `routines`: `RecommendationRuleAdmin`, `UserRoutineAdmin`, `HydrationGoalAdmin`, `WaterIntakeLogAdmin`, `RoutineTaskLogAdmin`, `ReminderPreferenceAdmin`.
    - `notifications`: `NotificationAdmin` and `DeviceTokenAdmin`.
- **Nepal Demo Data Seeding Command (`seed_nepal_demo`)**:
  - `manage.py seed_nepal_demo`: Single-command idempotent demo seed script providing rich clinical and patient context:
    - Creates 3 realistic Nepali patient accounts (Sujana Shrestha with acne concerns, Triyog Bhattarai, Rasmi Sharma).
    - Seeds 3 NMC-licensed verified dermatologists (Dr. Anjali Sharma NMC-12345, Dr. Rajesh Thapa NMC-15678, Dr. Sushma Karki NMC-18901) with bios, hospital affiliations, and availability slots.
    - Seeds default v1.0 recommendation rules, personalized morning/evening skincare routines, and hydration targets.
    - Provisions active 4-week premium memberships with integer paisa pricing.
    - Seeds clinical prescriptions with structured medications and follow-up schedules.
    - Seeds weekly photo check-ins with doctor guidance notes.
    - Seeds actionable in-app notifications.
- **Verification & Test Coverage**:
  - 6 new integration tests verifying notification listing, marking read, device token registration, push dispatch service, and demo seed command execution (69/69 tests passing).
  - OpenAPI specification regenerated and validated at 115 KB.

## [Milestone 7] - Prescriptions & Weekly Photo Check-ins - 2026-11-22

### Added
- **Dermatologist-Authored Immutable Prescriptions (`prescriptions`)**:
  - `Prescription` model with patient, authoring verified dermatologist, appointment link, diagnosis, structured medications list, instructions, notes, follow-up date, and lab tests.
  - **Strict Immutability Enforced**: Once `is_published=True`, any direct updates to clinical fields (`diagnosis`, `medications`, `instructions`, etc.) raise validation errors.
  - **Versioned Amendment Workflow**: Creating an amendment creates version v+1 (`parent_prescription`), preserving the immutable published historical record while updating the active therapy.
  - Authorization guard: Only administratively verified dermatologists can author or publish prescriptions.
- **Privacy Audit Logging**:
  - `PrescriptionAccessAuditLog`: Records every patient read access with SHA-256 hashed IP and User-Agent, providing auditability under Nepal's Privacy Act 2018 without storing raw sensitive identifiers.
- **Weekly Photo Check-ins (4-Week Term)**:
  - `WeeklyCheckIn` model: Captures 3-angle face photos (`front_photo`, `left_photo`, `right_photo`) with EXIF stripping, patient notes, and dermatologist clinical feedback.
  - **Week Unlock Logic in `Asia/Kathmandu`**:
    - Week 1: Unlocked immediately on membership start.
    - Week 2: Unlocked on day 8 (`start_date + 7 days`).
    - Week 3: Unlocked on day 15 (`start_date + 14 days`).
    - Week 4: Unlocked on day 22 (`start_date + 21 days`).
    - Early submission attempts before unlock date are rejected with informative local dates.
  - **Post-Expiry Upload Lock & Historical Access**:
    - Expired memberships block new check-in uploads.
    - Historical check-ins and clinical feedbacks remain permanently viewable via `/api/v1/prescriptions/check-ins/history/`.
  - Entitlement consumption: Each check-in submission consumes 1 check-in credit atomically.
- **API Endpoints**:
  - `GET /api/v1/prescriptions/`: List prescriptions for patient or authoring doctor.
  - `POST /api/v1/prescriptions/`: Author new prescription (verified doctor only).
  - `GET /api/v1/prescriptions/{id}/`: Get prescription details (triggers read audit log for patient).
  - `POST /api/v1/prescriptions/{id}/publish/`: Lock draft prescription into immutable published state.
  - `POST /api/v1/prescriptions/{id}/amend/`: Create version v+1 amendment.
  - `GET /api/v1/prescriptions/check-ins/status/`: 4-week unlock schedule and status overview.
  - `POST /api/v1/prescriptions/check-ins/submit/`: Submit weekly photos and note (consumes entitlement).
  - `GET /api/v1/prescriptions/check-ins/history/`: View past submitted check-ins and doctor reviews.
  - `POST /api/v1/prescriptions/check-ins/{id}/review/`: Dermatologist submits clinical guidance on check-in.
- **Test Coverage**: 9 new integration tests covering verified doctor authoring, immutable updates rejection, versioned amendments, audit logs, Asia/Kathmandu unlock timing, quota decrement, post-expiry submission locks, and dermatologist reviews (63/63 tests passing).

## [Milestone 6] - Consultations & Video Room Tokens - 2026-11-22

### Added
- **Dermatologist & Specialist Profiles (`consultations`)**:
  - `DermatologistProfile` linked to `accounts.User` with Nepal Medical Council registration number (`nmc_number`), credentials, experience, ratings, and specialties (`dermatologist`, `cosmetologist`, `aesthetician`, `trichologist`).
  - Mandatory admin verification (`is_verified=True`): unverified doctors are strictly filtered out of public listings and cannot accept bookings.
  - Formatted matching Flutter's `Doctor` model (`id`, `name`, `specialty`, `qualifications`, `experience`, `rating`, `totalReviews`, `consultationFee`, `consultationFeePaisa`, `availableDays`, `photoUrl`, `hospital`, `about`, `languages`, `isAvailableToday`, `isVerified`).
- **Availability Slots**:
  - `AvailabilitySlot` model with unique constraint on `(dermatologist, start_time)` preventing duplicate slots.
  - Day grouping and start/end time representations formatted in `Asia/Kathmandu` (UTC+5:45).
- **Concurrency-Safe Appointment Booking**:
  - `Appointment` model linking patient, verified dermatologist, and time slot.
  - Transactional booking service using `select_for_update()` row locking on `AvailabilitySlot` combined with `consume_consultation_entitlement()` inside a single atomic transaction.
  - Prevents race conditions and double-booking even under simultaneous booking attempts.
- **Cancellation & Rescheduling Policies**:
  - Cancellation > 2 hours prior to scheduled start time automatically releases the slot and restores the patient's consultation quota credit via `restore_consultation_entitlement()`.
  - Cancellation <= 2 hours frees the slot while preserving audit records.
  - Rescheduling atomically swaps old and new slots with the same dermatologist.
- **Agora RTC Video Room Token Engine**:
  - Generates HMAC-SHA256 authenticated short-lived Agora RTC tokens (ADR 0002).
  - Strict join window enforcement: tokens are only granted starting 15 minutes before slot start time up to 45 minutes after slot end time.
- **API Endpoints**:
  - `GET /api/v1/consultations/doctors/`: List verified doctors (supports specialty and search query filters).
  - `GET /api/v1/consultations/doctors/{id}/`: Doctor profile details.
  - `GET /api/v1/consultations/doctors/{id}/slots/`: List unbooked availability slots for a date in `Asia/Kathmandu`.
  - `POST /api/v1/consultations/slots/create/`: Create availability slots (dermatologists & staff).
  - `POST /api/v1/consultations/book/`: Book appointment with transactional row locking & entitlement deduction.
  - `GET /api/v1/consultations/appointments/`: List patient/doctor consultation appointments.
  - `GET /api/v1/consultations/appointments/{id}/`: Appointment detail.
  - `POST /api/v1/consultations/appointments/{id}/cancel/`: Cancel appointment and release slot.
  - `POST /api/v1/consultations/appointments/{id}/reschedule/`: Atomically reschedule to new slot.
  - `POST /api/v1/consultations/appointments/{id}/video-token/`: Generate Agora RTC room token within join window.
- **Test Coverage**: 7 new integration and concurrency tests covering verified doctor filtering, slot listing in Asia/Kathmandu, transactional booking, concurrency guard against double booking, advance cancellation refund, rescheduling slot swaps, and video room token join window restrictions (54/54 tests passing).

## [Milestone 5] - Payments & Gateway Integration - 2026-11-22

### Added
- **Payments Engine (`payments`)**:
  - `PaymentOrder`: Represents payment intent in integer paisa, bound to a user, plan/membership, and client-supplied `idempotency_key`.
  - `PaymentAttempt`: Tracks individual gateway attempts with status lifecycle (`initiated`, `pending`, `success`, `failed`, `cancelled`), gateway reference, and raw audit response.
  - `PaymentStatusHistory`: Immutable audit ledger recording every state change with timestamp and actor.
- **Unified Gateway Adapters (eSewa & Khalti)**:
  - Base `BasePaymentGatewayAdapter` defining interface for initiation, server-side lookup verification, and webhook parsing.
  - `EsewaGatewayAdapter`: Implements eSewa ePay v2 with HMAC-SHA256 signature generation (`total_amount,transaction_uuid,product_code`) and authoritative server-to-server transaction status lookup (`https://rc.esewa.com.np/api/epay/transaction/status/`).
  - `KhaltiGatewayAdapter`: Implements Khalti ePayment v2 with API initiation (pidx) and authoritative server-to-server lookup verification (`https://a.khalti.com/api/v2/epayment/lookup/`).
- **Security & Anti-Fraud Protection**:
  - Replay-safe and idempotent verification: if an attempt is already verified, re-querying returns success without duplicate membership activations.
  - Amount tampering defense: verification strictly compares authoritative gateway amount against internal order amount; tampered callbacks fail immediately.
  - Client callbacks are strictly treated as cues; no payment is marked successful or membership activated without a direct S2S gateway lookup verification.
- **Payment Endpoints**:
  - `POST /api/v1/payments/orders/create/`: Create payment order with client idempotency key.
  - `POST /api/v1/payments/checkout/initiate/`: Initiate gateway checkout (generates form payload/URL).
  - `POST /api/v1/payments/verify/`: S2S status check and activation trigger.
  - `POST /api/v1/payments/webhook/{gateway}/`: Replay-safe IPN/webhook endpoint.
  - `GET /api/v1/payments/orders/{order_id}/`: Retrieve order details and attempt history.
- **Test Coverage**: 5 new comprehensive integration tests covering idempotency keys, HMAC signatures, S2S verification, anti-fraud amount tampering rejection, and replay protection (47/47 tests passing).

## [Milestone 4] - Plans, Memberships & Entitlements - 2026-11-22

### Added
- **Plans App (`memberships`)**:
  - `Plan` model with prices strictly stored in **NPR integer paisa** (1 NPR = 100 paisa) to eliminate floating-point precision issues.
  - Seeded admin-editable default plans (one-time payment, 4-week term, no auto-renewal per Fixed Decision #2):
    - *Basic Plan*: NPR 399.00 (`39900` paisa), 28 days, 1 consultation, 4 weekly check-ins.
    - *Premium Plan*: NPR 499.00 (`49900` paisa), 28 days, 2 consultations, 4 weekly check-ins, routine review.
    - *Pay-per-Consultation*: NPR 200.00 (`20000` paisa), 28 days, 1 consultation, 0 check-ins.
  - `GET /api/v1/plans/`: Public endpoint returning active plans, feature lists, and pricing in both paisa and rupees.
- **Membership State Machine & Entitlements**:
  - `Membership` model with state transitions: `pending` -> `active` -> `expired` (or `cancelled`).
  - Atomically tracks live quotas: `consultations_remaining` and `checkins_remaining`.
  - Service functions `consume_consultation_entitlement()` and `consume_checkin_entitlement()` with row-level locks and validation against zero balances.
- **Dual-Layer Expiry Enforcement**:
  - **Request-time enforcement**: `get_active_membership_with_expiry_check()` checks `now >= end_date` upon access and automatically transitions status to `expired`.
  - **Scheduled background job**: `expire_outdated_memberships()` batch-updates all expired memberships for Celery periodic execution.
- **User Membership Endpoints**:
  - `GET /api/v1/memberships/current/`: Retrieve active membership and live entitlement balances.
  - `POST /api/v1/memberships/select/`: Select a plan creating a pending membership ready for checkout.
  - `POST /api/v1/memberships/{id}/cancel/`: Cancel active or pending membership.
  - `GET /api/v1/memberships/history/`: View complete membership history.
- **Test Coverage**: Added 6 new integration tests covering plans, integer paisa checks, state machine transitions, request-time and background expiry, and entitlement guards (42/42 tests passing).

## [Milestone 3] - Rule Engine, Routines & Hydration - 2026-11-22

### Added
- **Versioned Recommendation Rule Engine (`routines`)**:
  - `RecommendationRule` data model holding matching criteria (`target_skin_types`, `target_concerns`, `routine_level`), morning/evening task templates, and clinical guidance notes.
  - Seeded starter rules (v1.0) for Oily/Acne-prone skin, Dry/Sensitive barrier support, and Balanced daily care.
  - Mandatory disclaimer on all outputs: *"Advisory recommendation only. Not a medical diagnosis. Pending dermatologist review."*
  - Generated routines persisted in `UserRoutine` with individual `RoutineTask` steps for morning (AM) and evening (PM).
- **Daily Routine Tracking in Asia/Kathmandu**:
  - `RoutineTaskLog` model tracking daily check-off per task with date boundaries strictly computed in `Asia/Kathmandu` (UTC+5:45).
  - `POST /api/v1/routines/tasks/{id}/toggle/`: Toggles task completion on or off for today.
  - `GET /api/v1/routines/daily-summary/`: Returns comprehensive dashboard progress including AM/PM counts, percentage completion, and water metrics.
- **Scientific Hydration Tracking**:
  - `HydrationGoal` model implementing the scientific formula: `35 mL per kg body weight` (~250 mL per glass), documented and cited from EFSA and WHO guidelines.
  - `WaterIntakeLog` tracking incremental glasses and timestamps.
  - `GET /api/v1/hydration/today/` formatted for full compatibility with Flutter's `WaterTracking` model.
  - `POST /api/v1/hydration/goal/calculate/` and `POST /api/v1/hydration/log/`.
- **Reminder Preferences**: `ReminderPreference` model and `GET/PUT /api/v1/routines/reminders/`.

## [Milestone 2] - Profiles, Face Photos & Data Privacy - 2026-11-22

### Added
- **Profiles App (`profiles`)**: SkinProfile, LifestyleProfile, server-side BMI calculation.
- **Media Vault App (`media_vault`)**: FacePhoto, EXIF stripping, 15-minute cryptographically signed URLs, access audit logging.
- **Data Privacy & GDPR/Nepal Compliance**: Data export (`GET /api/v1/me/export/`) and hard deletion (`DELETE /api/v1/me/`).

## [Milestone 1] - Accounts, Authentication & Privacy-First Consent - 2026-11-22

### Added
- **Patient Registration**: Patient-only registration at `/api/v1/auth/register/`.
- **Dual-Identifier Authentication**: Email or Nepal phone at `/api/v1/auth/login/`.
- **Session Termination & Lifecycle**: Logout blacklist, profile management, password change and reset.
- **Consent App (`consent`)**: Versioned policies, SHA-256 IP/UA hashing, and `HasCurrentConsent` permission class.

## [Milestone 0] - Hardening of Skeleton & Foundational Infrastructure - 2026-11-22

### Added
- Project skeleton, environment split, custom User model, Docker Compose, Ruff, Pytest, GitHub Actions CI, ADR 001, ADR 002.
