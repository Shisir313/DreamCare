# Milestone 8 Plan: Notifications, Audit & Admin Polish, Seed Command & Final Hardening

## 1. Domain Models (`notifications` app)

### `Notification`
- `id`: UUIDField (pk)
- `user`: ForeignKey(`accounts.User`, related_name='notifications')
- `title`: CharField(max_length=255)
- `body`: TextField()
- `notification_type`: CharField (choices: `appointment`, `prescription`, `checkin`, `routine`, `hydration`, `general`)
- `is_read`: BooleanField(default=False, db_index=True)
- `data`: JSONField(default=dict, blank=True)
- `created_at`: DateTimeField(auto_now_add=True, db_index=True)

### `DeviceToken`
- `id`: UUIDField (pk)
- `user`: ForeignKey(`accounts.User`, related_name='device_tokens')
- `fcm_token`: CharField(max_length=255, unique=True)
- `device_type`: CharField(choices: `android`, `ios`, `web`, default=`android`)

## 2. API Endpoints

| Method | Path | Auth / Role | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/notifications/` | IsAuthenticated | List notifications for authenticated user (paginated, latest first). |
| `POST` | `/api/v1/notifications/{id}/read/` | IsAuthenticated | Mark a specific notification as read. |
| `POST` | `/api/v1/notifications/mark-all-read/` | IsAuthenticated | Mark all unread notifications as read. |
| `POST` | `/api/v1/notifications/devices/register/` | IsAuthenticated | Register FCM device token for push notifications. |

## 3. Push Notification Engine (FCM Interface)
- `BasePushNotificationService` interface.
- `MockFCMPushService` for sandbox/testing (records payloads, verifies token matching).
- `send_notification_to_user(user, title, body, notification_type, data)` service function that saves the database notification record and dispatches through the push provider.
- Event dispatchers:
  - Appointment confirmed / cancelled
  - Prescription published / amended
  - Check-in reviewed by dermatologist

## 4. Admin Customization & Audit Viewer
- `ConsentRecordAdmin`: Read-only audit log with search on IP and user agent hashes.
- `PhotoAccessAuditLogAdmin`: Read-only audit log for private facial photo streaming.
- `PrescriptionAccessAuditLogAdmin`: Read-only audit log for clinical prescriptions.
- `PaymentOrderAdmin` & `PaymentAttemptAdmin`: Financial audit logs with masked secrets and gateway response JSON viewers.
- `DermatologistProfileAdmin`: Direct admin verification action ("Verify selected dermatologists").

## 5. Seed Command (`seed_nepal_demo`)
- Creates core personas:
  - Sujana (19, student, basic plan, acne routine, upcoming appointment)
  - Triyog (28, professional, premium plan, dry/sensitive)
  - Rasmi (40, teacher, pay-per-consultation)
- Creates verified dermatologists with realistic NMC registration numbers:
  - Dr. Anjali Sharma (NMC 12345)
  - Dr. Rajesh Thapa (NMC 15678)
  - Dr. Sushma Karki (NMC 18901)
- Populates availability slots for the upcoming week in `Asia/Kathmandu`.
- Creates sample prescriptions, check-ins, and notifications.

## 6. Test Strategy
1. Notification listing, unread count, and individual/bulk read marking.
2. Device token registration and deduplication.
3. Push notification dispatch hook with mock verification.
4. `manage.py seed_nepal_demo` execution testing (proves database seeds cleanly without integrity errors).
