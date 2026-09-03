import '../data/auth_api.dart';
import '../data/token_storage.dart';
import '../domain/auth_user.dart';

class AuthStore {
  AuthStore({AuthApi? api, TokenStorage? storage}) : _api = api ?? AuthApi(), _storage = storage ?? const TokenStorage();

  final AuthApi _api;
  final TokenStorage _storage;

  AuthUser? _user;
  String? _token;

  AuthUser? get user => _user;
  String? get token => _token;
  bool get hasSession => _token != null;
  bool get isAuthenticated => _token != null && _user != null;

  Future<bool> restore() async {
    _token = await _storage.read();
    return _token != null;
  }

  Future<AuthUser> login({required String email, required String password, required String deviceName}) async {
    final user = await _api.login(email: email, password: password, deviceName: deviceName);
    _user = user;
    _token = user.token;
    if (_token == null || _token!.isEmpty) {
      throw StateError('Authentication succeeded without an access token.');
    }
    await _storage.write(_token!);
    await _storage.writeAccountId(user.id);
    return user;
  }

  Future<AuthUser> register({required String name, required String email, required String password, required String deviceName}) async {
    final user = await _api.register(name: name, email: email, password: password, deviceName: deviceName);
    _user = user;
    _token = user.token;
    if (_token == null || _token!.isEmpty) {
      throw StateError('Registration succeeded without an access token.');
    }
    await _storage.write(_token!);
    await _storage.writeAccountId(user.id);
    return user;
  }

  Future<void> logout() async {
    final token = _token;
    try {
      if (token != null) await _api.logout(token);
    } finally {
      await _storage.clear();
      await _storage.clearAccountId();
      _token = null;
      _user = null;
    }
  }
}
