/// Skin profile captured during onboarding
class SkinProfile {
  const SkinProfile({
    required this.skinType,
    required this.concerns,
    required this.goals,
  });

  final SkinType skinType;
  final List<SkinConcern> concerns;
  final List<SkinGoal> goals;

  SkinProfile copyWith({
    SkinType? skinType,
    List<SkinConcern>? concerns,
    List<SkinGoal>? goals,
  }) {
    return SkinProfile(
      skinType: skinType ?? this.skinType,
      concerns: concerns ?? this.concerns,
      goals: goals ?? this.goals,
    );
  }
}

/// Skin type enum
enum SkinType {
  dry('Dry', 'Tight, flaky, or rough texture'),
  oily('Oily', 'Shiny, large pores, prone to breakouts'),
  combination('Combination', 'Oily T-zone, dry cheeks'),
  normal('Normal', 'Balanced, neither too dry nor oily'),
  sensitive('Sensitive', 'Easily irritated, reactive');

  const SkinType(this.label, this.description);
  final String label;
  final String description;
}

/// Skin concerns enum
enum SkinConcern {
  acne('Acne', 'Pimples, blackheads, whiteheads'),
  darkSpots('Dark Spots', 'Hyperpigmentation, uneven tone'),
  wrinkles('Wrinkles', 'Fine lines, aging signs'),
  redness('Redness', 'Inflammation, rosacea'),
  dryness('Dryness', 'Flaky, dehydrated skin'),
  oiliness('Oiliness', 'Excess sebum, shine'),
  largePores('Large Pores', 'Visible, enlarged pores'),
  dullness('Dullness', 'Lack of radiance, tired-looking');

  const SkinConcern(this.label, this.description);
  final String label;
  final String description;
}

/// Skin goals enum
enum SkinGoal {
  clearSkin('Clear Skin', 'Reduce breakouts and blemishes'),
  evenTone('Even Tone', 'Fade dark spots, brighten'),
  antiAging('Anti-Aging', 'Reduce wrinkles, firm skin'),
  hydration('Hydration', 'Moisturize and plump'),
  oilControl('Oil Control', 'Mattify and reduce shine'),
  sensitivity('Sensitivity', 'Calm and soothe irritation'),
  brightening('Brightening', 'Enhance radiance and glow');

  const SkinGoal(this.label, this.description);
  final String label;
  final String description;
}
