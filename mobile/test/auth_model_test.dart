import 'package:flutter_test/flutter_test.dart';
import 'package:todo_mobile/features/auth/domain/auth_user.dart';

void main() {
  test('parses authenticated user and access token', () {
    final user = AuthUser.fromJson({
      'id': 42,
      'name': 'Harrison',
      'email': 'harrison@example.com',
    }, token: 'test-token');

    expect(user.id, 42);
    expect(user.name, 'Harrison');
    expect(user.email, 'harrison@example.com');
    expect(user.token, 'test-token');
  });
}
