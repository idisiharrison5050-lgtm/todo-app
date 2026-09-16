import 'package:dio/dio.dart';

import '../domain/auth_user.dart';

class AuthApiException implements Exception {
  AuthApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class AuthApi {
  AuthApi({Dio? dio, String? baseUrl}) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api/v1'), connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 15), headers: const {'Accept': 'application/json'}));
  final Dio _dio;

  Future<AuthUser> login({required String email, required String password, required String deviceName}) async {
    try { return _parse(await _dio.post('/auth/login', data: {'email': email.trim(), 'password': password, 'device_name': deviceName})); } on DioException catch (error) { throw _mapError(error); }
  }

  Future<AuthUser> register({required String name, required String email, required String password, required String deviceName}) async {
    try { return _parse(await _dio.post('/auth/register', data: {'name': name.trim(), 'email': email.trim(), 'password': password, 'password_confirmation': password, 'device_name': deviceName})); } on DioException catch (error) { throw _mapError(error); }
  }

  Future<String> requestPasswordReset({required String email}) async {
    try {
      final response = await _dio.post('/auth/forgot-password', data: {'email': email.trim()});
      final body = response.data as Map<String, dynamic>;
      return body['message'] as String? ?? 'If an account exists for that email, a password reset link has been sent.';
    } on DioException catch (error) { throw _mapError(error); }
  }

  Future<AuthUser> me(String token) async {
    try {
      final response = await _dio.get('/me', options: Options(headers: {'Authorization': 'Bearer $token'}));
      final body = response.data as Map<String, dynamic>;
      final user = body['user'] is Map<String, dynamic> ? body['user'] as Map<String, dynamic> : body;
      return AuthUser.fromJson(user, token: token);
    } on DioException catch (error) { throw _mapError(error); }
  }

  AuthUser _parse(Response<dynamic> response) {
    final body = response.data as Map<String, dynamic>;
    final user = body['user'] as Map<String, dynamic>;
    final token = body['token'] as String? ?? body['access_token'] as String?;
    return AuthUser.fromJson(user, token: token);
  }

  Future<void> logout(String token) async {
    try { await _dio.post('/auth/logout', options: Options(headers: {'Authorization': 'Bearer $token'})); } on DioException catch (error) { throw _mapError(error); }
  }

  AuthApiException _mapError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (statusCode == 422 && data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            return AuthApiException(value.first.toString(), statusCode: statusCode);
          }
        }
      }
      final message = data['message'];
      if (message is String && message.isNotEmpty) return AuthApiException(message, statusCode: statusCode);
    }
    if (statusCode == 401) return AuthApiException('The email or password is incorrect.', statusCode: statusCode);
    if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.receiveTimeout) return AuthApiException('Cannot reach the Todo server. Check that the backend is running and the app API address is correct.', statusCode: statusCode);
    return AuthApiException('The server could not complete the request. Please try again.', statusCode: statusCode);
  }
}
