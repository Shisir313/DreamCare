# Milestone 4 Plan: Memberships & Entitlements

## Objectives
1. Implement admin-editable plans with NPR prices stored strictly as integer paisa (1 NPR = 100 paisa) in a dedicated `memberships` app:
   - `Basic`: 1 consultation, 4 weekly check-ins, routine guidance. 4-week term (28 days).
   - `Premium`: 2 consultations, routine review, 4 check-ins. 4-week term (28 days).
   - `Pay-per-consultation`: 1 consultation, 0 check-ins, single-use consultation entitlement.
   - All durations are one-time payments for a 4-week fixed term (no auto-renewal per Fixed Decision #2).
2. Membership State Machine & Entitlements:
   - State machine: `pending` -> `active` -> `expired` (or `cancelled`).
   - Track live entitlements: `consultations_remaining` and `checkins_remaining`.
   - Dual-layer expiry enforcement:
     - **Request-time enforcement**: checked dynamically whenever active membership is requested or entitlements are queried.
     - **Scheduled background job**: `expire_outdated_memberships()` designed for Celery periodic task execution.
3. Access & Endpoints:
   - `GET /api/v1/plans/`: List public active plans with price in paisa and formatted NPR.
   - `GET /api/v1/memberships/current/`: Get current authenticated user's active membership, state, remaining entitlements, and expiration date in Asia/Kathmandu.
   - `POST /api/v1/memberships/select/`: Select a plan creating a `pending` membership ready for payment checkout (M5).
   - `POST /api/v1/memberships/{id}/cancel/`: Cancel active or pending membership.
   - `GET /api/v1/memberships/history/`: List past and current memberships for the user.

## Endpoints (M4)

| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/plans/` | AllowAny | List active plans, pricing in paisa/NPR, features, and entitlements. |
| `GET` | `/api/v1/memberships/current/` | IsAuthenticated | Get user's active membership, state, and remaining consultation/check-in counts. |
| `POST` | `/api/v1/memberships/select/` | IsAuthenticated + Consent | Create pending membership for a selected plan. |
| `POST` | `/api/v1/memberships/{id}/cancel/` | IsAuthenticated | Cancel membership. |
| `GET` | `/api/v1/memberships/history/` | IsAuthenticated | View past and present membership records. |

## Test Plan
1. Plans:
   - List plans returns Basic, Premium, and Pay-per-consultation with integer paisa prices and formatted NPR.
2. Membership State Machine:
   - Creation generates `pending` membership.
   - Activation transitions `pending` -> `active`, initializes 28-day expiration, and populates `consultations_remaining` and `checkins_remaining`.
   - Enforce request-time expiration when `now > end_date`.
   - Scheduled expiry task updates outdated memberships to `expired`.
   - Cancellation transitions `active` -> `cancelled`.
3. Entitlements decrement:
   - Decrementing consultation count reduces `consultations_remaining`.
   - Raising exception if user attempts to consume consultation with 0 remaining.
