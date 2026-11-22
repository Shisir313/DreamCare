/// Named route constants for the app
/// Using path-style naming for go_router
library;

class RouteNames {
  RouteNames._();

  // Root & Navigation
  static const String splash = '/';
  static const String home = '/home';

  // Authentication
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Onboarding
  static const String onboarding = '/onboarding';
  static const String onboardingWelcome = '/onboarding/welcome';
  static const String onboardingSkinProfile = '/onboarding/skin-profile';
  static const String onboardingLifestyle = '/onboarding/lifestyle';
  static const String onboardingHydration = '/onboarding/hydration';
  static const String onboardingConsent = '/onboarding/consent';
  static const String onboardingComplete = '/onboarding/complete';

  // Home & Dashboard
  // (home is already defined above)

  // Routine
  static const String routine = '/routine';
  static const String routineDetail = '/routine/:routineId';
  static const String routineProductDetail = '/routine/product/:productId';

  // Hydration (accessed from Home)
  static const String hydrationDetail = '/hydration';
  static const String hydrationHistory = '/hydration/history';

  // Care Plans
  static const String care = '/care';
  static const String membership = '/care/membership';
  static const String membershipCheckout = '/care/membership/checkout';
  static const String planList = '/care/plans';
  static const String planDetail = '/care/plans/:planId';
  static const String aiAnalysis = '/care/ai-analysis';
  static const String aiAnalysisResult = '/care/ai-analysis/result/:analysisId';

  // Doctors & Appointments
  static const String doctors = '/doctors';
  static const String doctorDetail = '/doctors/:doctorId';
  static const String bookAppointment = '/doctors/:doctorId/book';
  static const String appointments = '/appointments';
  static const String appointmentDetail = '/appointments/:appointmentId';
  static const String videoCall = '/appointments/:appointmentId/video';

  // Prescriptions
  static const String prescriptions = '/prescriptions';
  static const String prescriptionDetail = '/prescriptions/:prescriptionId';

  // Progress & Check-ins
  static const String progress = '/progress';
  static const String checkInCreate = '/progress/check-in/create';
  static const String checkInDetail = '/progress/check-in/:checkInId';
  static const String progressPhotos = '/progress/photos';

  // Profile & Settings
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
  static const String notificationSettings = '/profile/notifications';
  static const String privacySettings = '/profile/privacy';
  static const String about = '/profile/about';
  static const String help = '/profile/help';
  static const String deleteAccount = '/profile/delete-account';

  // Helper methods to build parameterized routes
  static String routineDetailPath(String routineId) => '/routine/$routineId';
  static String routineProductPath(String productId) => '/routine/product/$productId';
  static String planDetailPath(String planId) => '/care/plans/$planId';
  static String aiAnalysisResultPath(String analysisId) => '/care/ai-analysis/result/$analysisId';
  static String doctorDetailPath(String doctorId) => '/doctors/$doctorId';
  static String bookAppointmentPath(String doctorId) => '/doctors/$doctorId/book';
  static String appointmentDetailPath(String appointmentId) => '/appointments/$appointmentId';
  static String videoCallPath(String appointmentId) => '/appointments/$appointmentId/video';
  static String prescriptionDetailPath(String prescriptionId) => '/prescriptions/$prescriptionId';
  static String checkInDetailPath(String checkInId) => '/progress/check-in/$checkInId';
}
