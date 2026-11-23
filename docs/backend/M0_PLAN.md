# Milestone 0 Plan: Hardening of the Skeleton

## Objectives
1. Implement the foundation described in the project blueprint:
   - Project structure under `Backend/`
   - Custom `accounts.User` model (email login, no username, UUID pk, role: `patient` / `dermatologist` / `admin`, `AUTH_USER_MODEL = "accounts.User"`)
   - Split settings architecture (`base.py`, `dev.py`, `prod.py`)
   - Timezone configured strictly to `"Asia/Kathmandu"` with `USE_TZ = True`
   - DRF + SimpleJWT (15-minute access token, 7-day rotating and blacklisted refresh token)
   - `drf-spectacular` OpenAPI 3.0 configuration (schema at `/api/schema/`, docs at `/api/docs/`)
   - Consistent machine-readable error handler for DRF (`code`, `message`, `details`)
2. `core` shared foundation app:
   - `UUIDModel`: Abstract model providing `id = UUIDField(primary_key=True, default=uuid.uuid4, editable=False)`
   - `TimeStampedModel`: Abstract model providing `created_at` and `updated_at`
   - `HealthCheckView` at `/api/v1/health/` returning system status, timestamp, timezone, and database connectivity check.
3. Tooling and Devops:
   - `.env.example` with documented environment variables
   - `docker-compose.yml` for local multi-service orchestration (Django app, PostgreSQL 16, Redis 7, MinIO S3 object storage)
   - `pytest.ini` with `pytest-django` integration
   - `ruff.toml` linting and formatting configuration
   - `.pre-commit-config.yaml`
   - `.github/workflows/ci.yml` (Ruff linting, pytest suite, OpenAPI schema generation & diff check)
4. OpenAPI schema generation committed to `schema.yml`.

## Endpoints (M0)
| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/health/` | AllowAny | Health check (checks database, app uptime, returns Asia/Kathmandu time) |
| `POST` | `/api/v1/auth/token/` | AllowAny | Obtain JWT token pair (SimpleJWT) |
| `POST` | `/api/v1/auth/token/refresh/` | AllowAny | Refresh JWT access token with rotation & blacklist |
| `GET` | `/api/schema/` | AllowAny | OpenAPI 3.0 YAML/JSON schema endpoint |
| `GET` | `/api/docs/` | AllowAny | Swagger UI documentation |

## Test Plan
1. `core.tests.test_base_models`: Verify `UUIDModel` and `TimeStampedModel` generation, immutability of UUID, timestamp auto-population.
2. `core.tests.test_health`: Verify `GET /api/v1/health/` returns HTTP 200, status `ok`, and correct metadata.
3. `core.tests.test_exception_handler`: Verify validation errors, 404s, and unhandled exceptions render uniform JSON `{ "error": { "code": "...", "message": "...", "details": ... } }`.
4. `accounts.tests.test_user_model`: Verify custom User creation, normalization of email, superuser creation, role assignment, and absence of username.
5. `accounts.tests.test_jwt_auth`: Verify token obtain endpoint issues 15m access token, refresh token rotates, and old refresh token is blacklisted.
