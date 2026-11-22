import 'skin_profile.dart';
import 'lifestyle_profile.dart';
import 'hydration_profile.dart';

/// Allergy types
enum Allergy {
  fragrance,
  latex,
  nickel,
  lanolin,
  parabens,
  sulfa,
  none;

  String get displayName {
    switch (this) {
      case Allergy.fragrance:
        return 'Fragrance';
      case Allergy.latex:
        return 'Latex';
      case Allergy.nickel:
        return 'Nickel';
      case Allergy.lanolin:
        return 'Lanolin';
      case Allergy.parabens:
        return 'Parabens';
      case Allergy.sulfa:
        return 'Sulfa drugs';
      case Allergy.none:
        return 'None';
    }
  }
}

/// Skin condition types
enum SkinCondition {
  eczema,
  psoriasis,
  rosacea,
  dermatitis,
  vitiligo,
  melasma,
  none;

  String get displayName {
    switch (this) {
      case SkinCondition.eczema:
        return 'Eczema';
      case SkinCondition.psoriasis:
        return 'Psoriasis';
      case SkinCondition.rosacea:
        return 'Rosacea';
      case SkinCondition.dermatitis:
        return 'Dermatitis';
      case SkinCondition.vitiligo:
        return 'Vitiligo';
      case SkinCondition.melasma:
        return 'Melasma';
      case SkinCondition.none:
        return 'None';
    }
  }
}

/// Medical history information
class MedicalHistory {
  const MedicalHistory({
    this.allergies = const [],
    this.skinConditions = const [],
    this.currentMedications,
    this.isPregnant = false,
    this.isBreastfeeding = false,
    this.additionalNotes,
  });

  final List<Allergy> allergies;
  final List<SkinCondition> skinConditions;
  final String? currentMedications;
  final bool isPregnant;
  final bool isBreastfeeding;
  final String? additionalNotes;

  MedicalHistory copyWith({
    List<Allergy>? allergies,
    List<SkinCondition>? skinConditions,
    String? currentMedications,
    bool? isPregnant,
    bool? isBreastfeeding,
    String? additionalNotes,
  }) {
    return MedicalHistory(
      allergies: allergies ?? this.allergies,
      skinConditions: skinConditions ?? this.skinConditions,
      currentMedications: currentMedications ?? this.currentMedications,
      isPregnant: isPregnant ?? this.isPregnant,
      isBreastfeeding: isBreastfeeding ?? this.isBreastfeeding,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }
}

/// Complete onboarding data
class OnboardingData {
  const OnboardingData({
    this.skinProfile,
    this.lifestyleProfile,
    this.hydrationProfile,
    this.medicalHistory,
    this.privacyConsentGiven = false,
  });

  final SkinProfile? skinProfile;
  final LifestyleProfile? lifestyleProfile;
  final HydrationProfile? hydrationProfile;
  final MedicalHistory? medicalHistory;
  final bool privacyConsentGiven;

  bool get isComplete =>
      skinProfile != null &&
      lifestyleProfile != null &&
      hydrationProfile != null &&
      medicalHistory != null &&
      privacyConsentGiven;

  OnboardingData copyWith({
    SkinProfile? skinProfile,
    LifestyleProfile? lifestyleProfile,
    HydrationProfile? hydrationProfile,
    MedicalHistory? medicalHistory,
    bool? privacyConsentGiven,
  }) {
    return OnboardingData(
      skinProfile: skinProfile ?? this.skinProfile,
      lifestyleProfile: lifestyleProfile ?? this.lifestyleProfile,
      hydrationProfile: hydrationProfile ?? this.hydrationProfile,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      privacyConsentGiven: privacyConsentGiven ?? this.privacyConsentGiven,
    );
  }
}
