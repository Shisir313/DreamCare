# Milestone 5 Plan: Payments & Gateway Adapters (eSewa & Khalti)

## Objectives
1. Implement a secure, replay-safe, and idempotent payment architecture in a dedicated `payments` app:
   - Money stored strictly in **NPR integer paisa** (1 NPR = 100 paisa) per Fixed Decision #1.
   - Unified Payment Gateway Adapter interface (`BasePaymentGateway`) providing polymorphic initiation and server-side verification for:
     - **eSewa (ePay v2)**: HMAC-SHA256 signature generation, parameters `total_amount`, `transaction_uuid`, `product_code`, and server-to-server transaction status check API.
     - **Khalti (ePayment v2)**: `pidx` token initiation and server-to-server `POST /api/v2/epayment/lookup/` status verification.
2. Server-Side Verification Rule (Fixed Decision #5):
   - **Never trust client-side callbacks**: A client callback merely triggers a server-to-server lookup query directly to the payment gateway's status API.
   - Exact amount and reference checks: The verified amount from the gateway is matched against `order.amount_paisa`. Any discrepancy immediately fails the attempt and flags an alert.
   - Idempotency & Replay Protection: Unique idempotency keys on orders, unique attempt references (`transaction_uuid` / `pidx`), and `select_for_update` row locks in atomic transactions ensure that repeated webhook or callback calls can never double-activate or double-credit a user.
   - Clear Activation Flow:
     `Verified Payment Attempt (success)` -> `Order (paid)` -> `Membership (active)`.
3. Background Reconciliation & Audit:
   - `PaymentStatusHistory` recording all transitions (`initiated`, `success`, `failed`, `expired`).
   - `reconcile_pending_payment_attempts()` scheduled Celery job querying stalled initiated attempts against the gateways' status APIs.
   - Failure and refund tracking policy.

## Endpoints (M5)

| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/payments/orders/create/` | IsAuthenticated + Consent | Create payment order with client idempotency key for membership or consultation. |
| `POST` | `/api/v1/payments/checkout/initiate/` | IsAuthenticated + Consent | Initiate gateway checkout (eSewa HMAC payload or Khalti `pidx` + URL). |
| `POST` | `/api/v1/payments/verify/` | IsAuthenticated | Client-reported completion trigger: executes server-to-server lookup API and activates membership. |
| `POST` | `/api/v1/payments/webhook/{gateway}/` | AllowAny | Replay-safe webhook handler for gateway asynchronous notifications. |
| `GET` | `/api/v1/payments/orders/{order_id}/` | IsAuthenticated | Get order payment status and attempt history. |

## Test Plan
1. Unified Gateway Adapters:
   - eSewa adapter produces valid HMAC-SHA256 signature matching ePay v2 specs.
   - Khalti adapter serializes payload in paisa and extracts `pidx`.
2. Server-to-Server Verification & Membership Activation:
   - Mocking gateway status API returning `COMPLETE` / `Completed` transitions order to `paid` and membership to `active`.
   - Entitlements populated on user upon verified payment.
3. Security & Anti-Fraud:
   - Amount tampering attempt (e.g. gateway returns 1000 paisa instead of 39900 paisa) is rejected with 400 and marked `failed`.
   - Replay protection: Submitting same callback twice returns success idempotently without re-triggering activation or entitlement increments.
4. Reconciliation:
   - Pending attempts older than threshold are checked via `reconcile_pending_payment_attempts()` and resolved.
