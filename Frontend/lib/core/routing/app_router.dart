import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/membership/presentation/screens/membership_plans_screen.dart';
import '../../features/membership/presentation/screens/payment_screen.dart';
import '../../features/membership/presentation/screens/payment_success_screen.dart';
import '../../features/membership/domain/models/membership_tier.dart';
import '../../features/doctors/presentation/screens/doctors_list_screen.dart';
import '../../features/doctors/presentation/screens/doctor_profile_screen.dart';
import '../../features/doctors/presentation/screens/appointment_booking_screen.dart';
import '../../features/doctors/presentation/screens/appointment_confirmation_screen.dart';
import '../../features/doctors/presentation/screens/appointments_list_screen.dart';
import '../../features/doctors/presentation/screens/appointment_detail_screen.dart';
import '../../features/doctors/domain/models/appointment.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/onboarding/presentation/screens/skin_profile_screen.dart';
import '../../features/onboarding/presentation/screens/lifestyle_screen.dart';
import '../../features/onboarding/presentation/screens/hydration_screen.dart';
import '../../features/onboarding/presentation/screens/medical_history_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_complete_screen.dart';
import '../../features/prescriptions/presentation/screens/prescriptions_list_screen.dart';
import '../../features/prescriptions/presentation/screens/prescription_details_screen.dart';
import '../../features/progress/presentation/screens/progress_photos_screen.dart';
import '../../features/progress/presentation/screens/skin_logs_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/help_center_screen.dart';
import '../../features/profile/presentation/screens/about_screen.dart';
import '../../features/assistant/presentation/screens/voice_chat_screen.dart';
import '../../features/routine/presentation/screens/routine_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import 'route_names.dart';
import 'page_transitions.dart';

/// Provider for the app router
/// This will be used in main.dart with MaterialApp.router
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter(ref).router;
});

/// App router configuration using go_router
class AppRouter {
  AppRouter(this.ref);

  final Ref ref;

  /// Root router configuration
  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: RouteNames.splash,
    routes: _routes,
    redirect: _redirect,
    errorBuilder: _errorBuilder,
  );

  /// Route definitions
  List<RouteBase> get _routes => [
    // Splash
    GoRoute(
      path: RouteNames.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Authentication
    GoRoute(
      path: RouteNames.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteNames.register,
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: RouteNames.forgotPassword,
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: RouteNames.resetPassword,
      name: 'reset-password',
      builder: (context, state) =>
          ResetPasswordScreen(phone: state.extra as String?),
    ),

    // Home (with bottom navigation)
    GoRoute(
      path: RouteNames.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/routine',
      name: 'routine',
      builder: (context, state) => const RoutineScreen(),
    ),

    // Membership
    GoRoute(
      path: '/membership/plans',
      name: 'membership-plans',
      builder: (context, state) => const MembershipPlansScreen(),
    ),
    GoRoute(
      path: '/membership/payment',
      name: 'membership-payment',
      builder: (context, state) {
        final tier = state.extra as MembershipTier?;
        if (tier == null) {
          return const MembershipPlansScreen();
        }
        return PaymentScreen(tier: tier);
      },
    ),
    GoRoute(
      path: '/membership/success',
      name: 'membership-success',
      builder: (context, state) {
        final tier = state.extra as MembershipTier?;
        if (tier == null) {
          return const HomeScreen();
        }
        return PaymentSuccessScreen(tier: tier);
      },
    ),

    // Doctors & Appointments
    GoRoute(
      path: '/doctors',
      name: 'doctors-list',
      builder: (context, state) => const DoctorsListScreen(),
    ),
    GoRoute(
      path: '/doctors/:doctorId',
      name: 'doctor-profile',
      builder: (context, state) {
        final doctorId = state.pathParameters['doctorId']!;
        return DoctorProfileScreen(doctorId: doctorId);
      },
    ),
    GoRoute(
      path: '/doctors/:doctorId/book',
      name: 'appointment-booking',
      builder: (context, state) {
        final doctorId = state.pathParameters['doctorId']!;
        return AppointmentBookingScreen(doctorId: doctorId);
      },
    ),
    GoRoute(
      path: '/appointments/:appointmentId/confirmed',
      name: 'appointment-confirmed',
      builder: (context, state) {
        final appointment = state.extra as Appointment?;
        if (appointment == null) {
          return const HomeScreen();
        }
        return AppointmentConfirmationScreen(appointment: appointment);
      },
    ),
    GoRoute(
      path: '/appointments',
      name: 'appointments',
      builder: (context, state) => const AppointmentsListScreen(),
    ),
    GoRoute(
      path: '/appointments/:appointmentId',
      name: 'appointment-detail',
      builder: (context, state) => AppointmentDetailScreen(
        appointmentId: state.pathParameters['appointmentId']!,
        appointment: state.extra as Appointment?,
      ),
    ),

    // Onboarding
    GoRoute(
      path: '/onboarding/welcome',
      name: 'onboarding-welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/onboarding/skin-profile',
      name: 'onboarding-skin-profile',
      builder: (context, state) => const SkinProfileScreen(),
    ),
    GoRoute(
      path: '/onboarding/lifestyle',
      name: 'onboarding-lifestyle',
      builder: (context, state) => const LifestyleScreen(),
    ),
    GoRoute(
      path: '/onboarding/hydration',
      name: 'onboarding-hydration',
      builder: (context, state) => const HydrationScreen(),
    ),
    GoRoute(
      path: '/onboarding/medical-history',
      name: 'onboarding-medical-history',
      builder: (context, state) => const MedicalHistoryScreen(),
    ),
    GoRoute(
      path: '/onboarding/complete',
      name: 'onboarding-complete',
      builder: (context, state) => const OnboardingCompleteScreen(),
    ),

    // Prescriptions & Progress
    GoRoute(
      path: '/prescriptions',
      name: 'prescriptions',
      builder: (context, state) => const PrescriptionsListScreen(),
    ),
    GoRoute(
      path: '/prescriptions/:prescriptionId',
      name: 'prescription-details',
      builder: (context, state) {
        final id = state.pathParameters['prescriptionId']!;
        return PrescriptionDetailsScreen(prescriptionId: id);
      },
    ),
    GoRoute(
      path: '/progress/photos',
      name: 'progress-photos',
      builder: (context, state) => const ProgressPhotosScreen(),
    ),
    GoRoute(
      path: '/progress/logs',
      name: 'skin-logs',
      builder: (context, state) => const SkinLogsScreen(),
    ),

    // Profile & Settings
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      name: 'edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/profile/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/profile/help',
      name: 'help',
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      path: '/profile/about',
      name: 'about',
      builder: (context, state) => const AboutScreen(),
    ),

    // AI Assistant
    GoRoute(
      path: '/assistant/chat',
      name: 'voice-chat',
      pageBuilder: (context, state) => AppPageTransitions.slideUp(
        child: const VoiceChatScreen(),
        key: state.pageKey,
      ),
    ),

    // TODO: Add remaining routes in respective milestones:
    // M1: onboarding routes
    // M2: routine, hydration routes
    // M3: care, plans, membership routes
    // M4: doctors, appointments routes
    // M5: prescriptions, progress routes
    // M6: profile, settings routes
  ];

  /// Global redirect logic
  /// Handles authentication and onboarding flow
  String? _redirect(BuildContext context, GoRouterState state) {
    // TODO: Implement proper redirect logic in M1
    // For now, allow all navigation for testing

    // Future logic:
    // 1. If not authenticated -> login
    // 2. If authenticated but not onboarded -> onboarding
    // 3. If authenticated and onboarded -> allow navigation

    final isOnSplash = state.matchedLocation == RouteNames.splash;

    // TODO: Check actual auth state from authProvider
    // const isAuthenticated = false; // Placeholder
    // const isOnboarded = false; // Placeholder

    // If on splash, decide where to go
    if (isOnSplash) {
      // Simulate splash delay and navigation
      // In real implementation, check auth state and navigate accordingly
      Future.delayed(const Duration(seconds: 2), () {
        // This won't work as expected - will be properly implemented in M1
        // For now, router will stay on splash
      });
      return null;
    }

    // Allow navigation for now
    return null;
  }

  /// Error page builder
  Widget _errorBuilder(BuildContext context, GoRouterState state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(RouteNames.home),
              icon: const Icon(Icons.home),
              label: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
