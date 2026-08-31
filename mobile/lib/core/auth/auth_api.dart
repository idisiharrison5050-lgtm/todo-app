import '../network/api_client.dart';
import 'secure_token_store.dart';

class AuthApi {
  AuthApi({required this.client, required this.tokens});

  final ApiClient client;
  final SecureTokenStore tokens;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
  }) async {
    final response = await client.post('/api/v1/auth/register', data: {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
      'device_name': deviceName.trim(),
    });
    return _storeToken(response.data);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final response = await client.post('/api/v1/auth/login', data: {
      'email': email.trim(),
      'password': password,
      'device_name': deviceName.trim(),
    });
    return _storeToken(response.data);
  }

  Future<void> logout() async {
    try {
      await client.post('/api/v1/auth/logout');
    } finally {
      client.setBearerToken(null);
      await tokens.clear();
    }
  }

  Future<Map<String, dynamic>> me() async {
    final response = await client.get('/api/v1/me');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> _storeToken(dynamic data) async {
    final payload = Map<String, dynamic>.from(data as Map);
    final token = payload['token'];
    if (token is! String || token.isEmpty) {
      throw StateError('Authentication response did not contain a token.');
    }
    await tokens.saveToken(token);
    client.setBearerToken(token);
    return payload;
  }
}
