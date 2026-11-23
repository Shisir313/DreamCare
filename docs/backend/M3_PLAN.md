# Milestone 3 Plan: Rule Engine, Routines & Hydration

## Objectives
1. Implement a data-driven, versioned recommendation rule engine (`routines` app):
   - Rules stored as versioned data rows (`RecommendationRule`), not hardcoded `if` chains.
   - Matches a user's `SkinProfile` (type, tone, concerns, conditions, routine level) and `LifestyleProfile` (sleep, activity, sun exposure) against versioned rule criteria.
   - Generates personalized AM/PM skincare routines (`UserRoutine` + `RoutineTask`).
   - Every recommendation output is explicitly marked *"pending dermatologist review"* with an advisory disclaimer. Never "AI", never a medical diagnosis.
   - Rule starter set seeded and versioned (v1.0).
2. Hydration Goal & Tracking:
   - Hydration formula: Documented and cited baseline based on EFSA/WHO scientific guidelines: `30-35 mL per kg of body weight` (~250 mL per standard glass).
   - Server-side calculation with documented limitations (climate, humidity, exercise, medical conditions).
   - Water logging endpoint supporting incremental glass logging, timestamps, and daily progress tracking (`WaterIntakeLog`).
3. Routine Daily Execution & Logs:
   - Routine task toggle endpoint (`POST /api/v1/routines/tasks/{id}/toggle/`) for a given date in `Asia/Kathmandu` (UTC+5:45).
   - Daily progress summary endpoint (`GET /api/v1/routines/daily-summary/`) aggregating AM/PM step completion and hydration progress.
4. Reminder Preferences:
   - User notification preferences for AM routine, PM routine, and periodic hydration alerts (`GET/PUT /api/v1/routines/reminders/`).

## Endpoints (M3)

| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/routines/generate/` | IsAuthenticated + HasCurrentConsent | Evaluate versioned rules against user's profile and generate active routine. |
| `GET` | `/api/v1/routines/current/` | IsAuthenticated + HasCurrentConsent | Retrieve active routine, AM/PM tasks, and today's completion status. |
| `POST` | `/api/v1/routines/tasks/{task_id}/toggle/` | IsAuthenticated + HasCurrentConsent | Check off or uncheck a routine task for today (in Asia/Kathmandu). |
| `GET` | `/api/v1/hydration/goal/` | IsAuthenticated + HasCurrentConsent | Retrieve hydration target, formula citation, and medical limitations. |
| `POST` | `/api/v1/hydration/goal/calculate/` | IsAuthenticated + HasCurrentConsent | Calculate/update hydration goal based on current weight and activity. |
| `POST` | `/api/v1/hydration/log/` | IsAuthenticated + HasCurrentConsent | Log water intake (+1 glass / 250ml) for today. |
| `GET` | `/api/v1/hydration/today/` | IsAuthenticated + HasCurrentConsent | Get today's water tracking progress, glasses completed, and timestamps. |
| `GET` | `/api/v1/routines/daily-summary/` | IsAuthenticated + HasCurrentConsent | Aggregate progress: routine steps completed + water intake vs goal. |
| `GET/PUT`| `/api/v1/routines/reminders/` | IsAuthenticated + HasCurrentConsent | Get or update routine and hydration reminder time preferences. |

## Test Plan
1. Versioned Rule Engine:
   - Rule evaluation matches Sujana's persona (oily, acne concern) -> produces salicylic acid/gentle cleanser, oil-free moisturizer, sunscreen.
   - Rule evaluation matches dry/sensitive persona -> produces hydrating cleanser, barrier cream.
   - Verify all generated notes contain the mandatory disclaimer: *"pending dermatologist review"*.
   - Verify rules are versioned and can evaluate against active rule versions without hardcoded if-chains.
2. Routine Tasks & Check-off:
   - Task completion toggles for today's date in Asia/Kathmandu.
   - Toggling same task again unchecks it.
   - Completion status resets properly on next calendar day.
3. Hydration & Tracking:
   - 60kg patient -> `60 * 35 = 2100 mL` -> 9 glasses (250ml each).
   - Log water intake increments glasses completed and appends timestamp.
   - Daily summary reflects accurate percentages for both routine tasks and hydration.
   - Reminder preferences persist and validate time formats.
