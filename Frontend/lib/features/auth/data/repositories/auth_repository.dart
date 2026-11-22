import '../../../../core/utils/result.dart';
import '../../domain/models/auth_tokens_simple.dart';
import '../../domain/models/login_request_simple.dart';
import '../../domain/models/user_simple.dart';

/// Abstract auth repository interface
/// Allows swapping between fake and real implementations
abstract class AuthRepository {
  /// Login with phone and password
  Future<Result<(User, AuthTokens)>> login(LoginRequest request);

  /// Register new user
  Future<Result<(User, AuthTokens)>> register(RegisterRequest request);

  /// Logout current user
  Future<Result<void>> logout();

  /// Refresh access token
  Future<Result<AuthTokens>> refreshToken(String refreshToken);

  /// Get current user profile
  Future<Result<User>> getCurrentUser();

  /// Update user profile
  Future<Result<User>> updateProfile({
    String? name,
    String? email,
    DateTime? dateOfBirth,
  });

  /// Change password
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Request password reset
  Future<Result<void>> requestPasswordReset(String phone);

  /// Reset password with code
  Future<Result<void>> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  });

  /// Delete account
  Future<Result<void>> deleteAccount(String password);
}
