import 'package:dio/dio.dart';

class AuthSession {
  const AuthSession({required this.token});
  final String token;

  static AuthSession fromResponse(Response<dynamic> response) {
    final body = response.data as Map<String, dynamic>;
    final token = body['token'] as String? ?? body['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('Authentication response did not contain an access token.');
    }
    return AuthSession(token: token);
  }
}
