import 'package:dio/dio.dart';

import '../../../../core/errors/failure_simple.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/auth_tokens_simple.dart';
import '../../domain/models/login_request_simple.dart';
import '../../domain/models/user_simple.dart';
import 'auth_repository.dart';

/// Production authentication repository connecting to the Django DRF backend
class RealAuthRepository implements AuthRepository {
  RealAuthRepository({Dio? dio, SecureStorageService? secureStorage})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
                headers: {'Content-Type': 'application/json'},
              ),
            ),
        _secureStorage = secureStorage ?? SecureStorageService();

  final Dio _dio;
  final SecureStorageService _secureStorage;

  @override
  Future<Result<(User, AuthTokens)>> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/login/',
        data: {
          'phone': request.phone,
          'email': request.phone.contains('@') ? request.phone : '',
          'password': request.password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;

      final user = User(
        id: userJson['id']?.toString() ?? '',
        phone: userJson['phone']?.toString() ?? request.phone,
        name: userJson['name']?.toString() ?? '',
        email: userJson['email']?.toString(),
        dateOfBirth: userJson['date_of_birth'] != null
            ? DateTime.tryParse(userJson['date_of_birth'].toString())
            : null,
        isOnboarded: userJson['is_onboarded'] as bool? ?? false,
        createdAt: DateTime.now(),
      );

      final tokens = AuthTokens(
        accessToken: data['access']?.toString() ?? '',
        refreshToken: data['refresh']?.toString() ?? '',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      return Result.success((user, tokens));
    } on DioException catch (e) {
      return Result.error(_handleDioError(e));
    } catch (e) {
      return Result.error(Failure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Result<(User, AuthTokens)>> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/register/',
        data: {
          'phone': request.phone,
          'name': request.name,
          'password': request.password,
          if (request.email != null && request.email!.isNotEmpty)
            'email': request.email,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;

      final user = User(
        id: userJson['id']?.toString() ?? '',
        phone: userJson['phone']?.toString() ?? request.phone,
        name: userJson['name']?.toString() ?? request.name,
        email: userJson['email']?.toString() ?? request.email,
        dateOfBirth: userJson['date_of_birth'] != null
            ? DateTime.tryParse(userJson['date_of_birth'].toString())
            : null,
        isOnboarded: userJson['is_onboarded'] as bool? ?? false,
        createdAt: DateTime.now(),
      );

      final tokens = AuthTokens(
        accessToken: data['access']?.toString() ?? '',
        refreshToken: data['refresh']?.toString() ?? '',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      return Result.success((user, tokens));
    } on DioException catch (e) {
      return Result.error(_handleDioError(e));
    } catch (e) {
      return Result.error(Failure(message: 'Registration error: $e'));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final refresh = await _secureStorage.getRefreshToken();
      final access = await _secureStorage.getAccessToken();

      if (refresh != null && access != null) {
        await _dio.post(
          '/auth/logout/',
          data: {'refresh': refresh},
          options: Options(headers: {'Authorization': 'Bearer $access'}),
        );
      }
      return Result.success(null);
    } catch (_) {
      // Always treat local logout as success even if network fails
      return Result.success(null);
    }
  }

  @override
  Future<Result<AuthTokens>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      final tokens = AuthTokens(
        accessToken: data['access']?.toString() ?? '',
        refreshToken: refreshToken,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
      return Result.success(tokens);
    } on DioException catch (e) {
      return Result.error(_handleDioError(e));
    }
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final access = await _secureStorage.getAccessToken();
      if (access == null) {
        return Result.error<User>(
          const Failure(message: 'Not authenticated', code: 'unauthenticated'),
        );
      }

      final response = await _dio.get(
        '/auth/me/',
        options: Options(headers: {'Authorization': 'Bearer $access'}),
      );

      final userJson = response.data as Map<String, dynamic>;
      final user = User(
        id: userJson['id']?.toString() ?? '',
        phone: userJson['phone']?.toString() ?? '',
        name: userJson['name']?.toString() ?? '',
        email: userJson['email']?.toString(),
        dateOfBirth: userJson['date_of_birth'] != null
            ? DateTime.tryParse(userJson['date_of_birth'].toString())
            : null,
        isOnboarded: userJson['is_onboarded'] as bool? ?? false,
        createdAt: DateTime.now(),
      );

      return Result.success(user);
    } on DioException catch (e) {
      return Result.error(_handleDioError(e));
    }
  }

  @override
  Future<Result<User>> updateProfile({
    String? name,
    String? email,
    DateTime? dateOfBirth,
  }) async {
    try {
      final access = await _secureStorage.getAccessToken();
      final response = await _dio.patch(
        '/auth/me/',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (dateOfBirth != null)
            'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
        },
        options: Options(headers: {'Authorization': 'Bearer $access'}),
      );

      final userJson = response.data as Map<String, dynamic>;
      final user = User(
        id: userJson['id']?.toString() ?? '',
        phone: userJson['phone']?.toString() ?? '',
        name: userJson['name']?.toString() ?? '',
        email: userJson['email']?.toString(),
        dateOfBirth: userJson['date_of_birth'] != null
            ? DateTime.tryParse(userJson['date_of_birth'].toString())
            : null,
        isOnboarded: userJson['is_onboarded'] as bool? ?? false,
        createdAt: DateTime.now(),
      );

      return Result.success(user);
    } on DioException catch (e) {
      return Result.error(_handleDioError(e));
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final access = await _secureStorage.getAccessToken();
      await _dio.post(
        '/auth/password/change/',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: Options(headers: {'Authorization': 'Bearer $access'}),
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.error(_handleDioError(e));
    }
  }

  @override
  Future<Result<void>> requestPasswordReset(String phone) async {
    try {
      await _dio.post(
        '/auth/password/reset/request/',
        data: {'identifier': phone},
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.error(_handleDioError(e));
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/password/reset/confirm/',
        data: {
          'identifier': phone,
          'code': code,
          'new_password': newPassword,
        },
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.error(_handleDioError(e));
    }
  }

  @override
  Future<Result<void>> deleteAccount(String password) async {
    try {
      final access = await _secureStorage.getAccessToken();
      await _dio.delete(
        '/me/',
        data: {'password': password},
        options: Options(headers: {'Authorization': 'Bearer $access'}),
      );
      await _secureStorage.clearAll();
      return Result.success(null);
    } on DioException catch (e) {
      return Result.error(_handleDioError(e));
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        if (data.containsKey('error') && data['error'] is Map) {
          final errMap = data['error'] as Map;
          return Failure(
            message: errMap['message']?.toString() ?? 'Operation failed',
            code: errMap['code']?.toString() ?? 'error',
          );
        }
        if (data.containsKey('message')) {
          return Failure(message: data['message'].toString());
        }
        if (data.containsKey('detail')) {
          return Failure(message: data['detail'].toString());
        }
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const Failure(
        message: 'Connection timed out. Please check if backend is running.',
        code: 'timeout',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const Failure(
        message:
            'Cannot connect to backend server at http://127.0.0.1:8000/. Ensure backend is running.',
        code: 'connection_error',
      );
    }

    return Failure(message: e.message ?? 'Network error occurred');
  }
}
