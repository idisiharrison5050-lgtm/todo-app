import 'package:dio/dio.dart';

import '../domain/auth_user.dart';

class AuthApi {
  AuthApi({Dio? dio, String baseUrl = 'http://10.0.2.2:8000/api/v1'})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 15)));

  final Dio _dio;

  Future<AuthUser> login({required String email, required String password, required String deviceName}) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email.trim(),
      'password': password,
      'device_name': deviceName,
    });
    return AuthUser.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> register({required String name, required String email, required String password, required String deviceName}) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'password_confirmation': password,
      'device_name': deviceName,
    });
    return AuthUser.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<void> logout(String token) async {
    await _dio.post('/auth/logout', options: Options(headers: {'Authorization': 'Bearer $token'}));
  }
}
