/// Failure type for Result pattern - simple Dart class
class Failure {
  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  /// Check if failure is due to network issues
  bool get isNetworkError => code == 'network_error';

  /// Check if failure is due to authentication issues
  bool get isAuthError => code == 'auth_error' || code == 'unauthorized';

  /// Check if failure is due to validation issues
  bool get isValidationError => code == 'validation_error';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => Object.hash(message, code);

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}
