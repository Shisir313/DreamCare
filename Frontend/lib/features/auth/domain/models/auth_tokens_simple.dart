/// Authentication tokens - simple Dart class
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// Check if access token is expired or about to expire (within 5 minutes)
  bool get isExpired {
    final now = DateTime.now();
    const buffer = Duration(minutes: 5);
    return now.isAfter(expiresAt.subtract(buffer));
  }

  /// Time until token expires
  Duration get timeUntilExpiry {
    final now = DateTime.now();
    return expiresAt.difference(now);
  }

  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthTokens &&
          runtimeType == other.runtimeType &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, expiresAt);

  @override
  String toString() => 'AuthTokens(expires: $expiresAt)';
}
