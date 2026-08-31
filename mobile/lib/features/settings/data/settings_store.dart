import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore extends ChangeNotifier {
  static const _notificationsKey = 'notifications_enabled';
  static const _defaultReminderKey = 'default_reminder_enabled';

  bool _notificationsEnabled = true;
  bool _defaultReminderEnabled = true;
  bool _loaded = false;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get defaultReminderEnabled => _defaultReminderEnabled;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded || kIsWeb) {
      _loaded = true;
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    _notificationsEnabled = preferences.getBool(_notificationsKey) ?? true;
    _defaultReminderEnabled = preferences.getBool(_defaultReminderKey) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationsKey, value);
    notifyListeners();
  }

  Future<void> setDefaultReminderEnabled(bool value) async {
    _defaultReminderEnabled = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_defaultReminderKey, value);
    notifyListeners();
  }
}
