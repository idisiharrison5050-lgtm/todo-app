import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required String baseUrl, Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: baseUrl.replaceFirst(RegExp(r'/$'), ''),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ));

  final Dio _dio;

  Dio get dio => _dio;

  void setBearerToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
      return;
    }
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response<dynamic>> post(String path, {Object? data}) =>
      _dio.post(path, data: data);

  Future<Response<dynamic>> patch(String path, {Object? data}) =>
      _dio.patch(path, data: data);

  Future<Response<dynamic>> delete(String path) => _dio.delete(path);
}
