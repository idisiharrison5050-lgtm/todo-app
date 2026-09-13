import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/local_notification_service.dart';
import '../domain/routine.dart';
import 'routine_scheduler.dart';

class RoutineStore extends ChangeNotifier {
  RoutineStore({LocalNotificationService? notifications})
      : _notifications = notifications ?? LocalNotificationService(),
        _scheduler = RoutineScheduler(notifications: notifications);

  static const String _storageKey = 'todo_routines_v1';
  final LocalNotificationService _notifications;
  final RoutineScheduler _scheduler;
  final Uuid _uuid = const Uuid();
  List<Routine> _routines = <Routine>[];
  bool _loaded = false;

  List<Routine> get routines => List.unmodifiable(_routines);
  bool get isLoaded => _loaded;
  int get enabledCount => _routines.where((routine) => routine.enabled).length;

  Future<void> load() async {
    if (_loaded) return;
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _routines = decoded.whereType<Map>().map((item) => Routine.fromJson(Map<String, dynamic>.from(item))).where((routine) => routine.title.trim().isNotEmpty).toList();
        }
      } catch (_) {
        _routines = <Routine>[];
      }
    }
    _loaded = true;
    notifyListeners();

    // Rebuild the next notification window whenever routines are loaded.
    for (final routine in _routines.where((item) => item.enabled)) {
      await _scheduler.schedule(routine);
    }
  }

  Future<Routine> add({
    required String title,
    String body = '',
    required int startMinutes,
    required int endMinutes,
    required int intervalMinutes,
    List<int> days = const <int>[1, 2, 3, 4, 5, 6, 7],
  }) async {
    final routine = Routine(
      id: _uuid.v4(),
      title: title.trim(),
      body: body.trim(),
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      intervalMinutes: intervalMinutes,
      days: List<int>.from(days),
      createdAt: DateTime.now(),
    );
    final notificationsGranted = await _notifications.requestPermissions();
    if (!notificationsGranted) {
      throw StateError('Notification permission is required for routine reminders.');
    }
    _routines = [..._routines, routine];
    await _persist();
    notifyListeners();
    await _scheduler.schedule(routine);
    return routine;
  }

  Future<void> update(Routine routine) async {
    final index = _routines.indexWhere((item) => item.id == routine.id);
    if (index == -1) return;
    final previous = _routines[index];
    await _scheduler.cancelWithDefinition(previous);
    if (routine.enabled) {
      final notificationsGranted = await _notifications.requestPermissions();
      if (!notificationsGranted) {
        throw StateError('Notification permission is required for routine reminders.');
      }
    }
    _routines = [..._routines]..[index] = routine;
    await _persist();
    notifyListeners();
    await _scheduler.schedule(routine);
  }

  Future<void> toggle(Routine routine, bool enabled) async {
    await update(routine.copyWith(enabled: enabled));
  }

  Future<void> remove(Routine routine) async {
    await _scheduler.cancelWithDefinition(routine);
    _routines = _routines.where((item) => item.id != routine.id).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> rescheduleAll() async {
    await load();
    for (final routine in _routines.where((item) => item.enabled)) {
      await _scheduler.schedule(routine);
    }
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(_routines.map((routine) => routine.toJson()).toList()));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
