import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _deviceNameKey = 'device_name';
  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) async {
    if (token.trim().isEmpty) {
      throw ArgumentError('Token cannot be empty.');
    }
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<String?> readDeviceName() => _storage.read(key: _deviceNameKey);

  Future<void> saveDeviceName(String name) =>
      _storage.write(key: _deviceNameKey, value: name.trim());

  Future<void> clear() => _storage.deleteAll();
}
