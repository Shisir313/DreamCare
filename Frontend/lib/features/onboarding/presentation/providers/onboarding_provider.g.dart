// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Onboarding state notifier

@ProviderFor(Onboarding)
final onboardingProvider = OnboardingProvider._();

/// Onboarding state notifier
final class OnboardingProvider
    extends $NotifierProvider<Onboarding, OnboardingData> {
  /// Onboarding state notifier
  OnboardingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingHash();

  @$internal
  @override
  Onboarding create() => Onboarding();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingData>(value),
    );
  }
}

String _$onboardingHash() => r'1855ccfc3413195a6c3df867f341a9ed5a3aa59b';

/// Onboarding state notifier

abstract class _$Onboarding extends $Notifier<OnboardingData> {
  OnboardingData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OnboardingData, OnboardingData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OnboardingData, OnboardingData>,
              OnboardingData,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Current onboarding step provider

@ProviderFor(OnboardingStep)
final onboardingStepProvider = OnboardingStepProvider._();

/// Current onboarding step provider
final class OnboardingStepProvider
    extends $NotifierProvider<OnboardingStep, int> {
  /// Current onboarding step provider
  OnboardingStepProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingStepProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingStepHash();

  @$internal
  @override
  OnboardingStep create() => OnboardingStep();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$onboardingStepHash() => r'920bba6c103215d426d5ab8f8712b21e63bd6b7a';

/// Current onboarding step provider

abstract class _$OnboardingStep extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
