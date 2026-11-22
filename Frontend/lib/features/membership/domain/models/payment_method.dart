/// Payment method types available in Nepal
enum PaymentMethod {
  esewa,
  khalti,
  imePay,
  fonepay,
  creditCard,
  debitCard;

  String get displayName {
    switch (this) {
      case PaymentMethod.esewa:
        return 'eSewa';
      case PaymentMethod.khalti:
        return 'Khalti';
      case PaymentMethod.imePay:
        return 'IME Pay';
      case PaymentMethod.fonepay:
        return 'FonePay';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
    }
  }

  String get iconAsset {
    // TODO: Add actual payment provider logos
    switch (this) {
      case PaymentMethod.esewa:
        return 'assets/images/payment/esewa.png';
      case PaymentMethod.khalti:
        return 'assets/images/payment/khalti.png';
      case PaymentMethod.imePay:
        return 'assets/images/payment/imepay.png';
      case PaymentMethod.fonepay:
        return 'assets/images/payment/fonepay.png';
      case PaymentMethod.creditCard:
        return 'assets/images/payment/card.png';
      case PaymentMethod.debitCard:
        return 'assets/images/payment/card.png';
    }
  }

  bool get isDigitalWallet {
    return this == PaymentMethod.esewa ||
        this == PaymentMethod.khalti ||
        this == PaymentMethod.imePay ||
        this == PaymentMethod.fonepay;
  }
}

/// Payment transaction record
class PaymentTransaction {
  const PaymentTransaction({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.transactionId,
    this.description,
  });

  final String id;
  final int amount; // Amount in NPR paisa (smallest unit)
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? transactionId;
  final String? description;

  double get amountNPR => amount / 100.0;

  PaymentTransaction copyWith({
    String? id,
    int? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    DateTime? createdAt,
    String? transactionId,
    String? description,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      transactionId: transactionId ?? this.transactionId,
      description: description ?? this.description,
    );
  }
}

/// Payment status
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded;

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}
