import 'package:dio/dio.dart';

import '../../auth/data/token_storage.dart';
import '../domain/task.dart';

class CloudTaskSync {
  CloudTaskSync({Dio? dio, TokenStorage? storage, String? baseUrl})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api/v1'), connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 12), headers: const {'Accept': 'application/json'})),
        _storage = storage ?? const TokenStorage();

  final Dio _dio;
  final TokenStorage _storage;

  Future<bool> get isAuthenticated async => (await _storage.read())?.isNotEmpty == true;

  Future<List<Task>> pull() async {
    final token = await _storage.read();
    if (token == null || token.isEmpty) return const <Task>[];
    final response = await _dio.get('/tasks', options: _options(token));
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    if (raw is! List) return const <Task>[];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      final payload = data['payload'];
      if (payload is Map) return Task.fromJson(Map<String, dynamic>.from(payload));
      return Task(id: data['client_id'] as String, title: data['title'] as String? ?? '', isCompleted: data['completed'] as bool? ?? false, updatedAt: DateTime.tryParse(data['updated_at'] as String? ?? ''));
    }).where((task) => task.title.trim().isNotEmpty).toList();
  }

  Future<Task> push(Task task) async {
    final token = await _storage.read();
    if (token == null || token.isEmpty) return task;
    try {
      final response = await _dio.post('/tasks', data: {
        'client_id': task.id,
        'title': task.title,
        'completed': task.isCompleted,
        'payload': task.toJson(),
        'client_updated_at': task.updatedAt?.toIso8601String(),
      }, options: _options(token));
      return _taskFromResponse(response.data, task);
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) {
        return _taskFromResponse(error.response?.data, task);
      }
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final token = await _storage.read();
    if (token == null || token.isEmpty) return;
    final tasks = await _dio.get('/tasks', options: _options(token));
    final body = tasks.data as Map<String, dynamic>;
    final raw = body['data'];
    if (raw is! List) return;
    for (final item in raw.whereType<Map>()) {
      final data = Map<String, dynamic>.from(item);
      if (data['client_id'] == id && data['id'] != null) {
        await _dio.delete('/tasks/${data['id']}', options: _options(token));
        return;
      }
    }
  }

  Task _taskFromResponse(dynamic response, Task fallback) {
    if (response is Map) {
      final data = response['task'];
      if (data is Map) {
        final payload = data['payload'];
        if (payload is Map) return Task.fromJson(Map<String, dynamic>.from(payload));
        return Task(id: data['client_id'] as String? ?? fallback.id, title: data['title'] as String? ?? fallback.title, isCompleted: data['completed'] as bool? ?? fallback.isCompleted, updatedAt: DateTime.tryParse(data['client_updated_at'] as String? ?? data['updated_at'] as String? ?? '') ?? fallback.updatedAt);
      }
    }
    return fallback;
  }

  Options _options(String token) => Options(headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});
}
