/// Membership tier types
enum MembershipTier {
  basic,
  premium,
  payPerConsultation;

  String get displayName {
    switch (this) {
      case MembershipTier.basic:
        return 'Basic';
      case MembershipTier.premium:
        return 'Premium';
      case MembershipTier.payPerConsultation:
        return 'Pay Per Consultation';
    }
  }

  String get description {
    switch (this) {
      case MembershipTier.basic:
        return 'Essential skincare tracking and routine management';
      case MembershipTier.premium:
        return 'Complete skincare solution with AI and priority support';
      case MembershipTier.payPerConsultation:
        return 'Pay only when you need expert consultation';
    }
  }

  int get priceNPR {
    switch (this) {
      case MembershipTier.basic:
        return 399;
      case MembershipTier.premium:
        return 499;
      case MembershipTier.payPerConsultation:
        return 200; // Per consultation
    }
  }

  String get priceDisplay {
    switch (this) {
      case MembershipTier.basic:
        return 'Rs 399/month';
      case MembershipTier.premium:
        return 'Rs 499/month';
      case MembershipTier.payPerConsultation:
        return 'Rs 200/consultation';
    }
  }

  List<String> get features {
    switch (this) {
      case MembershipTier.basic:
        return [
          'Daily skincare routine tracking',
          'Product scanning and recommendations',
          'Hydration and symptom tracking',
          'Basic progress photos',
          'Community forum access',
        ];
      case MembershipTier.premium:
        return [
          'Everything in Basic',
          'AI-powered skin analysis',
          'Unlimited doctor consultations',
          'Personalized care plans',
          'Priority appointment booking',
          'Advanced progress tracking',
          'Prescription management',
          'Priority customer support',
        ];
      case MembershipTier.payPerConsultation:
        return [
          'Access to doctor consultations',
          'Pay only when you consult',
          'No monthly commitment',
          'Prescription access',
          'Consultation history',
        ];
    }
  }

  bool get isSubscription {
    return this != MembershipTier.payPerConsultation;
  }
}

/// User's membership information
class UserMembership {
  const UserMembership({
    required this.tier,
    this.startDate,
    this.endDate,
    this.isActive = false,
    this.autoRenew = false,
  });

  final MembershipTier tier;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool autoRenew;

  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  int get daysRemaining {
    if (endDate == null) return 0;
    return endDate!.difference(DateTime.now()).inDays;
  }

  UserMembership copyWith({
    MembershipTier? tier,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? autoRenew,
  }) {
    return UserMembership(
      tier: tier ?? this.tier,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      autoRenew: autoRenew ?? this.autoRenew,
    );
  }
}
