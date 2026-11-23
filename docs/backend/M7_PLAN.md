# Milestone 7 Plan: Prescriptions & Weekly Photo Check-ins

## 1. Domain Models (`prescriptions` app)

### `Prescription`
- `id`: UUIDField (pk)
- `patient`: ForeignKey(`accounts.User`, related_name='prescriptions')
- `dermatologist`: ForeignKey(`consultations.DermatologistProfile`, related_name='prescriptions')
- `appointment`: ForeignKey(`consultations.Appointment`, null=True, blank=True, related_name='prescriptions')
- `version`: PositiveIntegerField(default=1)
- `parent_prescription`: ForeignKey('self', null=True, blank=True, related_name='amendments')
- `is_published`: BooleanField(default=False, db_index=True)
- `published_at`: DateTimeField(null=True, blank=True)
- `diagnosis`: CharField(max_length=255)
- `medications`: JSONField(default=list) — List of `{name, dosage, frequency, duration, instructions, beforeMeal}`
- `instructions`: TextField(blank=True)
- `notes`: TextField(blank=True)
- `follow_up_date`: DateField(null=True, blank=True)
- `lab_tests`: JSONField(default=list, blank=True)
- `status`: CharField(choices: `active`, `completed`, `cancelled`, `expired`, default=`active`)

### `PrescriptionAccessAuditLog`
- `prescription`: ForeignKey(`Prescription`, related_name='access_logs')
- `user`: ForeignKey(`accounts.User`, related_name='prescription_access_logs')
- `accessed_at`: DateTimeField(default=timezone.now)
- `ip_hash`: CharField(max_length=64)
- `user_agent_hash`: CharField(max_length=64)

### `WeeklyCheckIn`
- `id`: UUIDField (pk)
- `patient`: ForeignKey(`accounts.User`, related_name='checkins')
- `membership`: ForeignKey(`memberships.Membership`, related_name='checkins')
- `week_number`: PositiveIntegerField(help_text="Week 1-4 of the 28-day membership")
- `front_photo`: ForeignKey(`media_vault.FacePhoto`, null=True, blank=True, related_name='+', on_delete=SET_NULL)
- `left_photo`: ForeignKey(`media_vault.FacePhoto`, null=True, blank=True, related_name='+', on_delete=SET_NULL)
- `right_photo`: ForeignKey(`media_vault.FacePhoto`, null=True, blank=True, related_name='+', on_delete=SET_NULL)
- `patient_note`: TextField(blank=True)
- `status`: CharField(choices: `submitted`, `reviewed`, default=`submitted`)
- `dermatologist`: ForeignKey(`consultations.DermatologistProfile`, null=True, blank=True, related_name='reviewed_checkins')
- `dermatologist_feedback`: TextField(blank=True)
- `reviewed_at`: DateTimeField(null=True, blank=True)
- `submitted_at`: DateTimeField(auto_now_add=True)

## 2. API Endpoints

| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/prescriptions/` | IsAuthenticated (Verified Dermatologist) | Author a new prescription or draft. |
| `POST` | `/api/v1/prescriptions/{id}/publish/` | IsAuthenticated (Author Dermatologist) | Publish prescription, locks immutability. |
| `POST` | `/api/v1/prescriptions/{id}/amend/` | IsAuthenticated (Author Dermatologist) | Create version v+1 amendment of published prescription. |
| `GET` | `/api/v1/prescriptions/` | IsAuthenticated | List prescriptions for current patient (or doctor). |
| `GET` | `/api/v1/prescriptions/{id}/` | IsAuthenticated | Get prescription details (audited read for patient). |
| `GET` | `/api/v1/check-ins/status/` | IsAuthenticated | Get 4-week check-in status, unlock dates, and submission state. |
| `POST` | `/api/v1/check-ins/submit/` | IsAuthenticated + Consent (Patient) | Submit weekly check-in (front/left/right photos + note). Consumes quota. |
| `GET` | `/api/v1/check-ins/history/` | IsAuthenticated | View past check-ins (accessible even after membership expiry). |
| `POST` | `/api/v1/check-ins/{id}/review/` | IsAuthenticated (Verified Dermatologist) | Dermatologist reviews weekly check-in and submits clinical feedback. |

## 3. Privacy & Clinical Rules
- Immutability: Once `is_published=True`, `save()` rejects field modifications.
- Nepal tele-prescribing: Prescriptions carry advisory metadata, NMC license number, and clear follow-up notices.
- Audit logging: Every read of a prescription by a patient logs SHA-256 hashed IP and User-Agent.
- Week unlock:
  - Week 1: `start_date`
  - Week 2: `start_date + 7 days` (in `Asia/Kathmandu`)
  - Week 3: `start_date + 14 days`
  - Week 4: `start_date + 21 days`
- Post-expiry lock: If membership is expired, submissions return 403 Forbidden, but history read returns 200 OK.

## 4. Test Strategy
1. Prescription creation by verified dermatologist vs unverified doctor vs patient (forbidden).
2. Prescription immutability once published (updates raise ValidationError).
3. Amendment workflow produces `version=2` with `parent_prescription` link.
4. Patient read access generates audit log record with hashed IP/UA.
5. Weekly check-in unlock timing in `Asia/Kathmandu` (early submission rejected).
6. Weekly check-in submission consumes entitlement.
7. Post-expiry check-in rejection while historical read succeeds.
8. Dermatologist check-in review submission.
