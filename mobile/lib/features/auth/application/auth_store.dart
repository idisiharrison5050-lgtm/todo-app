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
  bool get isAuthenticated => _token != null && _user != null;

  Future<bool> restore() async {
    _token = await _storage.read();
    return _token != null;
  }

  Future<AuthUser> login({required String email, required String password, required String deviceName}) async {
    final user = await _api.login(email: email, password: password, deviceName: deviceName);
    _user = user;
    return user;
  }

  Future<AuthUser> register({required String name, required String email, required String password, required String deviceName}) async {
    final user = await _api.register(name: name, email: email, password: password, deviceName: deviceName);
    _user = user;
    return user;
  }

  Future<void> logout() async {
    final token = _token;
    if (token != null) {
      try {
        await _api.logout(token);
      } finally {
        await _storage.clear();
      }
    }
    _token = null;
    _user = null;
  }
}
