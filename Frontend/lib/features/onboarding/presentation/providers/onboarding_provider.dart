import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider_simple.dart';
import '../../domain/models/hydration_profile.dart';
import '../../domain/models/lifestyle_profile.dart';
import '../../domain/models/onboarding_data.dart';
import '../../domain/models/skin_profile.dart';

part 'onboarding_provider.g.dart';

/// Onboarding state notifier
@riverpod
class Onboarding extends _$Onboarding {
  @override
  OnboardingData build() => const OnboardingData();

  /// Update skin profile
  void updateSkinProfile(SkinProfile profile) {
    state = state.copyWith(skinProfile: profile);
  }

  /// Update lifestyle profile
  void updateLifestyleProfile(LifestyleProfile profile) {
    state = state.copyWith(lifestyleProfile: profile);
  }

  /// Update hydration profile
  void updateHydrationProfile(HydrationProfile profile) {
    state = state.copyWith(hydrationProfile: profile);
  }

  /// Update medical history
  void updateMedicalHistory(MedicalHistory history) {
    state = state.copyWith(medicalHistory: history);
  }

  /// Give privacy consent
  void givePrivacyConsent() {
    state = state.copyWith(privacyConsentGiven: true);
  }

  /// Complete onboarding
  Future<void> complete(MedicalHistory medicalHistory) async {
    // Update medical history
    state = state.copyWith(medicalHistory: medicalHistory);

    // Give privacy consent automatically
    state = state.copyWith(privacyConsentGiven: true);

    if (!state.isComplete) {
      throw StateError('Onboarding data is incomplete');
    }

    // Save onboarding completion to local storage
    final localStorage = ref.read(localStorageServiceProvider);
    await localStorage.setOnboardingComplete(true);

    // Save privacy consent
    await localStorage.setPrivacyConsent(
      given: true,
      timestamp: DateTime.now(),
    );

    // Mark user as onboarded in auth state
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      // In real app, would call API to update user.isOnboarded
      // For now, we'll just update local state via auth provider
      // This is handled by the router redirect logic
    }

    // Reset onboarding state
    state = const OnboardingData();
  }

  /// Complete onboarding (simpler version for complete screen)
  Future<void> completeOnboarding() async {
    final localStorage = ref.read(localStorageServiceProvider);
    await localStorage.setOnboardingComplete(true);
    state = const OnboardingData();
  }

  /// Reset onboarding (for testing)
  void reset() {
    state = const OnboardingData();
  }
}

/// Current onboarding step provider
@riverpod
class OnboardingStep extends _$OnboardingStep {
  @override
  int build() => 0;

  void nextStep() {
    if (state < 5) {
      state = state + 1;
    }
  }

  void previousStep() {
    if (state > 0) {
      state = state - 1;
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 5) {
      state = step;
    }
  }

  void reset() {
    state = 0;
  }
}
