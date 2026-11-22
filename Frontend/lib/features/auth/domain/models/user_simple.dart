/// User model - simple Dart class without Freezed
class User {
  const User({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    this.dateOfBirth,
    this.profilePhotoUrl,
    required this.isOnboarded,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String phone;
  final String name;
  final String? email;
  final DateTime? dateOfBirth;
  final String? profilePhotoUrl;
  final bool isOnboarded;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Display name or fallback
  String get displayName => name.isNotEmpty ? name : phone;

  /// Check if user has completed profile
  bool get hasCompleteProfile => email != null && dateOfBirth != null;

  /// User age if date of birth is set
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    var age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Copy with method for immutability
  User copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    DateTime? dateOfBirth,
    String? profilePhotoUrl,
    bool? isOnboarded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          phone == other.phone &&
          name == other.name &&
          email == other.email &&
          dateOfBirth == other.dateOfBirth &&
          profilePhotoUrl == other.profilePhotoUrl &&
          isOnboarded == other.isOnboarded &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        phone,
        name,
        email,
        dateOfBirth,
        profilePhotoUrl,
        isOnboarded,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'User(id: $id, name: $name, phone: $phone)';
}
