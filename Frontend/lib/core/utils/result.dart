import '../errors/failure_simple.dart';

/// Result type for repository methods
/// Either `Success<T>` or `Error` with Failure
sealed class Result<T> {
  const Result();

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is error
  bool get isError => this is Error<T>;

  /// Get value if success, otherwise null
  T? get valueOrNull => switch (this) {
    Success(value: final v) => v,
    Error() => null,
  };

  /// Get failure if error, otherwise null
  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Error(failure: final f) => f,
  };

  /// Transform success value
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(value: final v) => Result.success(transform(v)),
      Error(failure: final f) => Result.error(f),
    };
  }

  /// Execute function on success
  Result<T> onSuccess(void Function(T value) action) {
    if (this case Success(value: final v)) {
      action(v);
    }
    return this;
  }

  /// Execute function on error
  Result<T> onError(void Function(Failure failure) action) {
    if (this case Error(failure: final f)) {
      action(f);
    }
    return this;
  }

  /// Fold into a single value
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onError,
  }) {
    return switch (this) {
      Success(value: final v) => onSuccess(v),
      Error(failure: final f) => onError(f),
    };
  }

  // Constructors
  static Result<T> success<T>(T value) => Success(value);
  static Result<T> error<T>(Failure failure) => Error(failure);
}

/// Success case
final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Error case
final class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;

  @override
  String toString() => 'Error(${failure.message})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;
}
