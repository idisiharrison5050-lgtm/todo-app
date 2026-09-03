import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  const TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'todo_auth_token';
  static const _accountIdKey = 'todo_account_id';

  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  Future<void> clear() => _storage.delete(key: _key);

  Future<String?> readAccountId() => _storage.read(key: _accountIdKey);
  Future<void> writeAccountId(int accountId) => _storage.write(key: _accountIdKey, value: accountId.toString());
  Future<void> clearAccountId() => _storage.delete(key: _accountIdKey);
}
