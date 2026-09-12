import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  const TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'todo_auth_token';
  static const _accountIdKey = 'todo_account_id';
  static const _accountTokenHashKey = 'todo_account_token_hash';

  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _accountIdKey);
    await _storage.delete(key: _accountTokenHashKey);
  }

  Future<String?> readAccountId() async {
    final token = await read();
    if (token == null || token.isEmpty) return null;

    final accountId = await _storage.read(key: _accountIdKey);
    final tokenHash = await _storage.read(key: _accountTokenHashKey);
    if (accountId == null || accountId.isEmpty || tokenHash == null || tokenHash.isEmpty) return null;

    final currentHash = sha256.convert(utf8.encode(token)).toString();
    if (tokenHash != currentHash) return null;
    return accountId;
  }

  Future<void> writeAccountId(int accountId) async {
    final token = await read();
    if (token == null || token.isEmpty) return;
    final tokenHash = sha256.convert(utf8.encode(token)).toString();
    await _storage.write(key: _accountIdKey, value: accountId.toString());
    await _storage.write(key: _accountTokenHashKey, value: tokenHash);
  }

  Future<void> clearAccountId() async {
    await _storage.delete(key: _accountIdKey);
    await _storage.delete(key: _accountTokenHashKey);
  }
}
