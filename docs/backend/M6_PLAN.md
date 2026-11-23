# Milestone 6 Plan: Consultations & Video Room Tokens

## 1. Domain Models (`consultations` app)

### `DermatologistProfile`
- `user`: OneToOneField(`accounts.User`, on_delete=CASCADE, related_name='dermatologist_profile')
- `nmc_number`: CharField(max_length=50, unique=True) — Nepal Medical Council registration number
- `is_verified`: BooleanField(default=False) — Admin verification required before listing & booking
- `specialty`: CharField (choices: `dermatologist`, `cosmetologist`, `aesthetician`, `trichologist`)
- `qualifications`: CharField(max_length=255) (e.g. 'MBBS, MD (Dermatology)')
- `experience_years`: PositiveIntegerField(default=0)
- `rating`: DecimalField(max_digits=3, decimal_places=2, default=5.00)
- `total_reviews`: PositiveIntegerField(default=0)
- `consultation_fee_paisa`: PositiveIntegerField(default=150000) (NPR 1500.00)
- `hospital`: CharField(max_length=255, blank=True)
- `about`: TextField(blank=True)
- `languages`: JSONField(default=list) (e.g. `["Nepali", "English"]`)
- `photo_url`: URLField(blank=True)

### `AvailabilitySlot`
- `dermatologist`: ForeignKey(`DermatologistProfile`, on_delete=CASCADE, related_name='slots')
- `start_time`: DateTimeField() (UTC)
- `end_time`: DateTimeField() (UTC)
- `is_booked`: BooleanField(default=False)
- UniqueConstraint: `['dermatologist', 'start_time']`

### `Appointment`
- `patient`: ForeignKey(`accounts.User`, on_delete=CASCADE, related_name='appointments')
- `dermatologist`: ForeignKey(`DermatologistProfile`, on_delete=CASCADE, related_name='appointments')
- `slot`: OneToOneField(`AvailabilitySlot`, on_delete=PROTECT, related_name='appointment')
- `status`: CharField (choices: `scheduled`, `confirmed`, `in_progress`, `completed`, `cancelled`, `no_show`)
- `appointment_type`: CharField (choices: `video`, `in_person`, default `video`)
- `fee_paisa`: PositiveIntegerField()
- `symptoms`: TextField(blank=True)
- `notes`: TextField(blank=True)
- `cancellation_reason`: TextField(blank=True)
- `cancelled_at`: DateTimeField(null=True, blank=True)
- `room_channel`: CharField(max_length=100, unique=True)

## 2. API Endpoints

| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/consultations/doctors/` | AllowAny | List verified dermatologists (filters: specialty, date, search). |
| `GET` | `/api/v1/consultations/doctors/{id}/` | AllowAny | Get detailed doctor profile, experience, fees, languages. |
| `GET` | `/api/v1/consultations/doctors/{id}/slots/` | AllowAny | List available unbooked time slots for selected doctor and date. |
| `POST` | `/api/v1/consultations/slots/create/` | IsAuthenticated (Dermatologist/Admin) | Create availability slots. |
| `POST` | `/api/v1/consultations/book/` | IsAuthenticated + Consent (Patient) | Book appointment with transactional `select_for_update()` & entitlement decrement. |
| `GET` | `/api/v1/consultations/appointments/` | IsAuthenticated | List user's appointments (patient sees theirs, doctor sees theirs). |
| `GET` | `/api/v1/consultations/appointments/{id}/` | IsAuthenticated | Retrieve appointment details. |
| `POST` | `/api/v1/consultations/appointments/{id}/cancel/` | IsAuthenticated | Cancel appointment, frees slot, restores quota if > 2h before start. |
| `POST` | `/api/v1/consultations/appointments/{id}/reschedule/` | IsAuthenticated | Reschedule appointment to a new available slot atomically. |
| `POST` | `/api/v1/consultations/appointments/{id}/video-token/` | IsAuthenticated | Generate Agora RTC room token if within valid join window (15m before start). |

## 3. Concurrency & Integrity Architecture
- `select_for_update()` applied directly on `AvailabilitySlot` within an `atomic()` transaction.
- Entitlement check and decrement executes within the same atomic transaction.
- If slot `is_booked == True`, transaction aborts and returns 409 Conflict error.

## 4. Test Strategy
1. Doctor profile listing & verified filter (unverified doctors hidden from public listing).
2. Slot creation and availability querying in `Asia/Kathmandu`.
3. Patient appointment booking with entitlement consumption.
4. Concurrency test: 2 simultaneous threads attempting to book the exact same slot -> exactly 1 succeeds, 1 receives 409 Conflict.
5. Cancellation flow: frees slot, restores quota if > 2 hours ahead.
6. Video room token join window guard: 403 when call is too early, 200 with Agora token when within window.
