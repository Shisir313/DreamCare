# ADR 001: Selection of PostgreSQL for Relational Storage

## Status
Accepted

## Context
DermaCare provides personalized skincare and dermatology consultation services in Nepal, supporting membership plans, consultations, payments (eSewa, Khalti), and prescriptions. The initial architecture report mentioned MySQL, but the operational model requires:
1. Strict ACID concurrency guarantees during appointment booking to prevent double-booking across concurrent slot requests.
2. Row-level pessimistic locking (`SELECT ... FOR UPDATE NOWAIT` / `SKIP LOCKED`) under Django ORM that operates consistently across transactions with payment and consultation entitlement decrementing.
3. Native JSONB support for versioned skin profile recommendation rules, lifestyle assessments, and payment gateway callback/verification payloads with indexability.
4. Robust advisory locks for Celery-based background reconciliation jobs (e.g., verifying orphaned eSewa/Khalti transactions).

## Decision
We select **PostgreSQL (v16+)** as the primary relational database for DermaCare.

## One-Sentence Executive Justification
> PostgreSQL is required over MySQL to guarantee race-free consultation booking via deterministic `select_for_update` row-level locks, provide first-class JSONB querying for versioned clinical recommendation rules, and support audit-grade transactional integrity across memberships and payments.

## Consequences
- Requires PostgreSQL client libraries (`psycopg` v3).
- Local development is backed by Docker Compose `postgres:16-alpine` service, with test suites able to run against isolated test databases.
- Schema migrations must be strictly validated for PostgreSQL compatibility.
