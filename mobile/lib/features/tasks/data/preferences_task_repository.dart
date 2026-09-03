import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/data/token_storage.dart';
import '../domain/task.dart';
import 'task_repository.dart';

/// Web-safe local repository used when the app is running in a browser.
/// Each authenticated account gets its own storage key so browser data cannot
/// bleed between accounts on the same device.
class PreferencesTaskRepository implements TaskRepository {
  static const _legacyStorageKey = 'todo.tasks.v1';
  static const _anonymousStorageKey = 'todo.tasks.anonymous.v2';

  PreferencesTaskRepository({TokenStorage? storage}) : _storage = storage ?? const TokenStorage();

  final TokenStorage _storage;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<String> _storageKey() async {
    final accountId = await _storage.readAccountId();
    if (accountId == null || accountId.isEmpty) return _anonymousStorageKey;
    return 'todo.tasks.account.$accountId.v2';
  }

  @override
  Future<List<Task>> getTasks() async {
    final raw = (await _prefs).getString(await _storageKey());
    if (raw == null || raw.isEmpty) return const <Task>[];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Task.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false);
    } on FormatException {
      return const <Task>[];
    } on TypeError {
      return const <Task>[];
    }
  }

  @override
  Future<void> saveTask(Task task) async {
    final tasks = (await getTasks()).toList();
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      tasks.add(task);
    } else {
      tasks[index] = task;
    }

    await (await _prefs).setString(
      await _storageKey(),
      jsonEncode(tasks.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    final tasks = (await getTasks()).where((task) => task.id != id).toList();
    await (await _prefs).setString(
      await _storageKey(),
      jsonEncode(tasks.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<void> close() async {}
}
