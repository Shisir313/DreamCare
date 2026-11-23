# DreamCare Frontend Implementation Plan

## Scope

This document covers Flutter frontend work only.

- All work belongs under `Frontend/lib`, `Frontend/test`, `Frontend/assets`, and this documentation.
- Do not modify the Django backend, database, API routes, migrations, or backend models.
- Existing backend endpoints may guide future UI integration, but frontend screens must remain usable with mock repositories until real services are implemented.
- No backend implementation, backend endpoint changes, or secret configuration is included in this plan.

## Current Frontend Status

The Flutter app already contains the following implemented screen areas:

- Splash
- Login and registration
- Onboarding: welcome, skin profile, lifestyle, hydration, medical history, and completion
- Home dashboard
- Membership plans, payment, and payment success
- Doctor list, doctor profile, booking, and booking confirmation
- Prescription list and prescription details
- Progress photos and skin logs
- Profile, edit profile, settings, help center, and about
- Voice chat assistant

The app uses:

- Flutter with Riverpod
- `go_router` for navigation
- Secure/shared storage services
- Shared theme and reusable widgets
- Mock repositories for authentication, doctors, prescriptions, and progress

## Main Gaps to Complete

### 1. Authentication and Account Security

Pages and flows to add:

- Forgot password request
- Reset password code entry and confirmation
- Change password
- Email verification guidance and token confirmation
- Delete account confirmation and password verification
- Account logout confirmation and reliable session cleanup

Frontend behavior to complete:

- Restore the saved session at startup
- Refresh expired access tokens
- Replace the mock-only auth repository with a real client implementation
- Add global redirect rules for authentication and onboarding
- Prevent authenticated users from returning to login/register
- Redirect unauthenticated users away from protected screens
- Return to the intended route after login
- Connect profile editing and password actions to the auth repository

### 2. Onboarding and Consent

Pages and flows to add:

- Dedicated consent and policy acceptance screen
- Review/edit page for the completed skin profile
- Onboarding resume/restart behavior

Frontend behavior to complete:

- Save onboarding progress after every step
- Restore partial onboarding state after app restart
- Mark onboarding complete only after policy acceptance
- Respect backend consent-policy status in future API integration
- Add loading, success, validation, and error states to every step

### 3. Home, Routine, and Hydration

Pages and flows to add:

- Hydration detail screen
- Hydration history screen
- Routine overview
- Routine detail
- Product detail
- Product scanner
- Skin tracking/check-in entry

Frontend behavior to complete:

- Replace fake refresh behavior with provider refresh state
- Add a notification screen or notification list
- Wire "Track Skin" to a real skin check-in screen
- Wire "Scan Product" to camera/image selection and a result/error state
- Show upcoming routine steps, missed steps, and completion status
- Persist or mock routine and hydration changes consistently

### 4. Care Plans and Membership

Pages and flows to add:

- Care plans overview
- Care plan detail
- AI skin analysis upload or capture page
- AI skin analysis progress state
- AI skin analysis result page
- Membership upgrade/renewal history
- Receipt or invoice view

Frontend behavior to complete:

- Replace the home care-plan placeholder with live plan status
- Show active, upcoming, paused, and expired plan states
- Reuse one purchase/checkout flow instead of duplicated routes
- Provide cancel-plan, renewal, and plan-selection confirmation dialogs
- Ensure payment UI shows validation, processing, success, failure, and retry states
- Keep provider logos and payment methods behind typed models

### 5. Doctors and Appointments

Pages and flows to add:

- Appointments list
- Appointment detail
- Reschedule/cancel appointment flow
- Video call placeholder or pre-call lobby
- Doctor search and filters
- Doctor availability calendar
- Past doctor reviews

Frontend behavior to complete:

- Complete the doctor search experience
- Display filters for specialty, availability, rating, and price
- Add loading, empty, and error states to the doctor list
- Save appointment selections to typed providers
- Handle missing or invalid appointment data instead of sending users home
- Add appointment status: pending, confirmed, cancelled, completed, and rescheduled
- Add deep-link-safe appointment routes

### 6. Prescriptions

Pages and flows to add:

- Prescription upload/request flow if required by the product scope
- Refill request and refill status
- Download/share receipt or prescription where platform APIs support it

Frontend behavior to complete:

- Add loading, empty, filtering, sorting, and error states
- Separate current and completed prescriptions
- Improve unreadable or missing medication data handling
- Add confirmation states for refill requests

### 7. Progress and Skin Journal

Pages and flows to add:

- Check-in creation
- Check-in detail
- Comparison view across progress photos
- Photo before/after viewer

Frontend behavior to complete:

- Add image capture, crop, preview, and removal
- Support retaking a photo and uploading progress
- Validate required mood, symptoms, severity, and notes
- Show trend charts and summary metrics
- Add privacy controls for local/removed images

### 8. Profile, Settings, and Support

Pages and flows to add:

- Notification settings
- Privacy settings
- Data and storage settings
- Change password
- Delete account
- Privacy policy content
- Terms of service content

Frontend behavior to complete:

- Persist notification preferences locally and through a future provider
- Connect dark mode to `ThemeMode` and persistence
- Remove or replace hard-coded coming-soon snack bars
- Improve profile name/avatar handling for empty or short names
- Add support tickets or an FAQ search experience
- Confirm destructive and logout actions consistently
- Add app language preference when localization is enabled

## Routes to Add or Complete

The following route names already exist in `route_names.dart` and need routing or final behavior:

| Route area | Routes |
| --- | --- |
| Authentication | `/forgot-password`, `/reset-password` |
| Onboarding | `/onboarding/consent` |
| Routine | `/routine`, `/routine/:routineId`, `/routine/product/:productId` |
| Hydration | `/hydration`, `/hydration/history` |
| Care | `/care`, `/care/plans`, `/care/plans/:planId`, `/care/ai-analysis`, `/care/ai-analysis/result/:analysisId` |
| Appointments | `/appointments`, `/appointments/:appointmentId`, `/appointments/:appointmentId/video` |
| Progress | `/progress/check-in/create`, `/progress/check-in/:checkInId` |
| Profile | `/profile/change-password`, `/profile/notifications`, `/profile/privacy`, `/profile/delete-account` |

Additional routes should be added for notifications, product scanning, privacy policy, terms of service, and data/storage settings if those are kept as separate pages.

The router must stop relying on `state.extra` alone for required detail data. Add a fallback to a repository/provider lookup or a clear not-found state for deep links.

## Data and State Work

Create typed Riverpod providers and repositories for:

- Routine
- Hydration
- Care plans
- AI analysis
- Appointments
- Notifications
- Check-ins
- Consent
- Settings/preferences

Keep the repository pattern already used by authentication and fake data features:

1. Domain models
2. Repository interface
3. Fake/mock repository
4. Provider/notifier
5. Screen widgets
6. Widget/unit tests

Do not add a real API implementation until its backend contract is ready and reviewed. Initial frontend work should use mock repositories or a separate configurable data source.

## Shared UI Work

Before adding many screens, complete the shared frontend foundation:

- Reusable app bars and bottom navigation shell
- Reusable confirmation dialogs
- Reusable loading, empty, and error states
- Consistent form field, validation, and submit behavior
- Consistent page transitions
- Safe-area and small-screen layout checks
- Keyboard dismissal and scrolling behavior
- Loading/success/error snackbar patterns
- Confirmation before logout, cancellation, deletion, and unsaved exit
- Accessibility labels and semantic text
- Minimum tap target and contrast checks

## Implementation Order

### Phase A: Navigation and Session Foundation

- Repair and document route constants
- Implement auth/onboarding redirect rules
- Add session restore and token refresh handling
- Add forgot/reset password screens
- Add change password and delete account screens
- Add a real mock/repository adapter structure

### Phase B: Home and Daily Care

- Add routine overview/detail
- Add product detail and scanner
- Add hydration detail/history
- Add skin tracking/check-in
- Connect notification entry point
- Replace Home screen placeholders

### Phase C: Care and Appointment Workflows

- Add care plans overview/detail
- Add AI analysis upload/progress/result
- Complete appointments list/detail/reschedule/cancel
- Add pre-call/video placeholder
- Complete doctor search/filter/reviews

### Phase D: Progress and Profile

- Add check-in create/detail
- Add progress comparison
- Complete profile settings
- Add privacy/terms pages
- Add notification and appearance settings
- Persist preference changes

### Phase E: Quality and Polishing

- Remove placeholder behavior
- Add deep-link and invalid-route tests
- Add responsive layout checks
- Add loading/empty/error/success tests
- Run Flutter analysis and test suite
- Verify Android, iOS, and web behavior where supported

## Testing Requirements

Add focused tests for:

- Route coverage and invalid route behavior
- Auth redirect rules
- Login/register/forgot-password validation
- Onboarding navigation and persisted progress
- Appointments and appointment cancellation/rescheduling
- Hydration and routine state changes
- Care plan selection and payment state
- Profile editing and settings persistence
- Loading, empty, error, and success states
- Deep-link parameter handling
- Theme contrast and responsive layouts

Run at least:

```bash
cd Frontend
flutter pub get
dart format lib test
flutter analyze
flutter test
```

## Definition of Done

A frontend page is complete only when it has:

- A registered route
- A typed model/provider/repository as needed
- Loading, empty, error, success, and retry behavior
- Form validation and disabled state during submit
- Responsive layout
- Back navigation and deep-link-safe behavior
- Reusable theme styles
- User-visible success/failure feedback
- Widget or unit coverage for the behavior
- No unresolved TODO or fake navigation for that flow

## First Implementation Backlog

Recommended first five screens to implement:

1. Forgot password
2. Reset password
3. Appointments list
4. Routine overview
5. Notification/notification settings
