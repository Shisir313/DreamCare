import 'dart:math';

import '../../../../core/errors/failure_simple.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/auth_tokens_simple.dart';
import '../../domain/models/login_request_simple.dart';
import '../../domain/models/user_simple.dart';
import 'auth_repository.dart';

/// Fake authentication repository for testing
/// Simulates network delays and random failures
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.shouldFail = false, this.failureRate = 0.1});

  final bool shouldFail;
  final double failureRate;
  final _random = Random();

  // In-memory user storage (simulates backend)
  final Map<String, _FakeUser> _users = {
    '9801234567': _FakeUser(
      user: User(
        id: 'user_sujana_001',
        phone: '9801234567',
        name: 'Sujana Shrestha',
        email: 'sujana@example.com',
        dateOfBirth: DateTime(1995, 6, 15),
        isOnboarded: true,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
      password: 'password123',
    ),
    '9812345678': _FakeUser(
      user: User(
        id: 'user_triyog_002',
        phone: '9812345678',
        name: 'Triyog Shrestha',
        email: 'triyog@example.com',
        dateOfBirth: DateTime(1992, 3, 22),
        isOnboarded: true,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
      password: 'password123',
    ),
    '9823456789': _FakeUser(
      user: User(
        id: 'user_rasmi_003',
        phone: '9823456789',
        name: 'Rasmi Thapa',
        email: 'rasmi@example.com',
        dateOfBirth: DateTime(1998, 11, 8),
        isOnboarded: false, // New user, needs onboarding
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      password: 'password123',
    ),
  };

  String? _currentUserId;

  /// Simulate network delay
  Future<void> _delay() async {
    await Future.delayed(Duration(milliseconds: 1000 + _random.nextInt(1000)));
  }

  /// Check if should simulate failure
  bool _shouldSimulateFailure() {
    if (shouldFail) return true;
    return _random.nextDouble() < failureRate;
  }

  /// Generate fake auth tokens
  AuthTokens _generateTokens() {
    return AuthTokens(
      accessToken: 'fake_access_token_${_random.nextInt(999999)}',
      refreshToken: 'fake_refresh_token_${_random.nextInt(999999)}',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  @override
  Future<Result<(User, AuthTokens)>> login(LoginRequest request) async {
    await _delay();

    if (_shouldSimulateFailure()) {
      return Result.error(
        const Failure(
          message: 'Network error. Please try again.',
          code: 'network_error',
        ),
      );
    }

    final fakeUser = _users[request.phone];
    if (fakeUser == null) {
      return Result.error(
        const Failure(
          message: 'Phone number not registered',
          code: 'not_found',
        ),
      );
    }

    if (fakeUser.password != request.password) {
      return Result.error(
        const Failure(message: 'Incorrect password', code: 'auth_error'),
      );
    }

    _currentUserId = fakeUser.user.id;
    final tokens = _generateTokens();

    return Result.success((fakeUser.user, tokens));
  }

  @override
  Future<Result<(User, AuthTokens)>> register(RegisterRequest request) async {
    await _delay();

    if (_shouldSimulateFailure()) {
      return Result.error(
        const Failure(
          message: 'Network error. Please try again.',
          code: 'network_error',
        ),
      );
    }

    // Check if phone already exists
    if (_users.containsKey(request.phone)) {
      return Result.error(
        const Failure(
          message: 'Phone number already registered',
          code: 'validation_error',
        ),
      );
    }

    // Create new user
    final newUser = User(
      id: 'user_${_random.nextInt(999999)}',
      phone: request.phone,
      name: request.name,
      email: request.email,
      isOnboarded: false, // New users need to complete onboarding
      createdAt: DateTime.now(),
    );

    _users[request.phone] = _FakeUser(
      user: newUser,
      password: request.password,
    );

    _currentUserId = newUser.id;
    final tokens = _generateTokens();

    return Result.success((newUser, tokens));
  }

  @override
  Future<Result<void>> logout() async {
    await _delay();
    _currentUserId = null;
    return Result.success(null);
  }

  @override
  Future<Result<AuthTokens>> refreshToken(String refreshToken) async {
    await _delay();

    if (_shouldSimulateFailure()) {
      return Result.error(
        const Failure(
          message: 'Failed to refresh token',
          code: 'network_error',
        ),
      );
    }

    return Result.success(_generateTokens());
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    await _delay();

    if (_currentUserId == null) {
      return Result.error(
        const Failure(message: 'Not authenticated', code: 'auth_error'),
      );
    }

    final fakeUser = _users.values.firstWhere(
      (u) => u.user.id == _currentUserId,
      orElse: () => throw StateError('User not found'),
    );

    return Result.success(fakeUser.user);
  }

  @override
  Future<Result<User>> updateProfile({
    String? name,
    String? email,
    DateTime? dateOfBirth,
  }) async {
    await _delay();

    if (_currentUserId == null) {
      return Result.error(
        const Failure(message: 'Not authenticated', code: 'auth_error'),
      );
    }

    if (_shouldSimulateFailure()) {
      return Result.error(
        const Failure(
          message: 'Failed to update profile',
          code: 'network_error',
        ),
      );
    }

    // Find and update user
    final entry = _users.entries.firstWhere(
      (e) => e.value.user.id == _currentUserId,
    );

    final updatedUser = entry.value.user.copyWith(
      name: name ?? entry.value.user.name,
      email: email ?? entry.value.user.email,
      dateOfBirth: dateOfBirth ?? entry.value.user.dateOfBirth,
      updatedAt: DateTime.now(),
    );

    _users[entry.key] = _FakeUser(
      user: updatedUser,
      password: entry.value.password,
    );

    return Result.success(updatedUser);
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _delay();

    if (_currentUserId == null) {
      return Result.error(
        const Failure(message: 'Not authenticated', code: 'auth_error'),
      );
    }

    final entry = _users.entries.firstWhere(
      (e) => e.value.user.id == _currentUserId,
    );

    if (entry.value.password != currentPassword) {
      return Result.error(
        const Failure(
          message: 'Current password is incorrect',
          code: 'validation_error',
        ),
      );
    }

    _users[entry.key] = _FakeUser(
      user: entry.value.user,
      password: newPassword,
    );

    return Result.success(null);
  }

  @override
  Future<Result<void>> requestPasswordReset(String phone) async {
    await _delay();

    if (!_users.containsKey(phone)) {
      return Result.error(
        const Failure(
          message: 'Phone number not registered',
          code: 'not_found',
        ),
      );
    }

    // Simulate SMS sent (in real app, backend would send SMS)
    return Result.success(null);
  }

  @override
  Future<Result<void>> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    await _delay();

    if (!_users.containsKey(phone)) {
      return Result.error(
        const Failure(
          message: 'Phone number not registered',
          code: 'not_found',
        ),
      );
    }

    // Simulate code verification (accept any 6-digit code for fake repo)
    if (code.length != 6) {
      return Result.error(
        const Failure(
          message: 'Invalid verification code',
          code: 'validation_error',
        ),
      );
    }

    final entry = _users.entries.firstWhere((e) => e.key == phone);
    _users[phone] = _FakeUser(user: entry.value.user, password: newPassword);

    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteAccount(String password) async {
    await _delay();

    if (_currentUserId == null) {
      return Result.error(
        const Failure(message: 'Not authenticated', code: 'auth_error'),
      );
    }

    final entry = _users.entries.firstWhere(
      (e) => e.value.user.id == _currentUserId,
    );

    if (entry.value.password != password) {
      return Result.error(
        const Failure(message: 'Incorrect password', code: 'validation_error'),
      );
    }

    _users.remove(entry.key);
    _currentUserId = null;

    return Result.success(null);
  }
}

/// Internal class to store user with password
class _FakeUser {
  const _FakeUser({required this.user, required this.password});

  final User user;
  final String password;
}
