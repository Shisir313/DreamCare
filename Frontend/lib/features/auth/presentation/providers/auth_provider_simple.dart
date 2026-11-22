import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/fake_auth_repository.dart';
import '../../domain/models/auth_tokens_simple.dart';
import '../../domain/models/login_request_simple.dart';
import '../../domain/models/user_simple.dart';

part 'auth_provider_simple.g.dart';

/// Provider for auth repository
@riverpod
AuthRepository authRepository(Ref ref) {
  if (FeatureFlags.enableMockData) {
    return FakeAuthRepository(failureRate: 0.1);
  }
  throw UnimplementedError('Real auth repository not yet implemented');
}

/// Auth state
class AuthState {
  const AuthState({this.user, this.tokens, this.isLoading = false, this.error});

  final User? user;
  final AuthTokens? tokens;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null && tokens != null;
  bool get needsOnboarding => user != null && user!.isOnboarded == false;

  AuthState copyWith({
    User? user,
    AuthTokens? tokens,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearTokens = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      tokens: clearTokens ? null : (tokens ?? this.tokens),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Auth notifier using Riverpod 3.x
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  SecureStorageService get _secureStorage =>
      ref.read(secureStorageServiceProvider);

  Future<void> login(String phone, String password) async {
    print('🔐 Auth: Login started for $phone');
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.login(
      LoginRequest(phone: phone, password: password),
    );

    result.fold(
      onSuccess: (data) async {
        print('✅ Auth: Login successful');
        final (user, tokens) = data;
        await _secureStorage.saveAccessToken(tokens.accessToken);
        await _secureStorage.saveRefreshToken(tokens.refreshToken);
        await _secureStorage.saveUserId(user.id);
        state = AuthState(user: user, tokens: tokens);
        print('✅ Auth: State updated, user: ${user.name}');
      },
      onError: (failure) {
        print('❌ Auth: Login failed - ${failure.message}');
        state = state.copyWith(isLoading: false, error: failure.message);
      },
    );
  }

  Future<void> register(
    String phone,
    String name,
    String password, {
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.register(
      RegisterRequest(
        phone: phone,
        name: name,
        password: password,
        email: email,
      ),
    );

    result.fold(
      onSuccess: (data) async {
        final (user, tokens) = data;
        await _secureStorage.saveAccessToken(tokens.accessToken);
        await _secureStorage.saveRefreshToken(tokens.refreshToken);
        await _secureStorage.saveUserId(user.id);
        state = AuthState(user: user, tokens: tokens);
      },
      onError: (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    await _secureStorage.clearAll();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Convenience providers
@riverpod
User? currentUser(Ref ref) {
  return ref.watch(authProvider).user;
}

@riverpod
bool isAuthenticated(Ref ref) {
  return ref.watch(authProvider).isAuthenticated;
}
