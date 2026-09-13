import 'package:flutter_test/flutter_test.dart';
import 'package:todo_mobile/features/auth/domain/auth_user.dart';

void main() {
  test('auth user can carry an access token without exposing storage details', () {
    final user = AuthUser.fromJson({'id': 1, 'name': 'Test User', 'email': 'test@example.com'}, token: 'secure-token');
    expect(user.token, 'secure-token');
  });
}
