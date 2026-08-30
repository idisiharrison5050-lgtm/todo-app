import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/task.dart';
import 'task_repository.dart';

/// Web-safe local repository used when the app is running in a browser.
/// The mobile builds use SQLite through [LocalTaskDatabase].
class PreferencesTaskRepository implements TaskRepository {
  static const _storageKey = 'todo.tasks.v1';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<List<Task>> getTasks() async {
    final raw = (await _prefs).getString(_storageKey);
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
      _storageKey,
      jsonEncode(tasks.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    final tasks = (await getTasks()).where((task) => task.id != id).toList();
    await (await _prefs).setString(
      _storageKey,
      jsonEncode(tasks.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<void> close() async {}
}
