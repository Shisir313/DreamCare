/// Simple exception classes without Freezed
/// Base exception class
abstract class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message, [this.statusCode]);
  final int? statusCode;
}

class ServerException extends AppException {
  const ServerException(super.message, [this.statusCode]);
  final int? statusCode;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Your session has expired. Please log in again.']);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message, [this.errors]);
  final Map<String, String>? errors;
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out. Please try again.']);
}

class UnknownException extends AppException {
  const UnknownException([super.message = 'An unexpected error occurred. Please try again.']);
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException([super.message = 'Permission denied. Please grant the required permissions.']);
}

class StorageException extends AppException {
  const StorageException(super.message);
}
