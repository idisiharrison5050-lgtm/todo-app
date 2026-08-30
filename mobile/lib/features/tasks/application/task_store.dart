import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/task.dart';

class TaskStore extends ChangeNotifier {
  static const _storageKey = 'todo.tasks.v1';

  final List<Task> _tasks = <Task>[];
  SharedPreferences? _preferences;

  List<Task> get tasks => List.unmodifiable(_tasks);

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    final raw = _preferences?.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _tasks
        ..clear()
        ..addAll(
          decoded.map(
            (item) => Task.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        );
      notifyListeners();
    } on FormatException {
      // Ignore corrupted local data rather than crashing the app.
    } on TypeError {
      // Ignore malformed local data rather than crashing the app.
    }
  }

  void addTask({
    required String title,
    String notes = '',
    DateTime? dueAt,
    TaskReminderType reminderType = TaskReminderType.none,
    Duration? reminderInterval,
    TaskPriority priority = TaskPriority.normal,
  }) {
    _tasks.add(
      Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title.trim(),
        notes: notes.trim(),
        dueAt: dueAt,
        reminderType: reminderType,
        reminderInterval: reminderInterval,
        priority: priority,
      ),
    );
    _persist();
    notifyListeners();
  }

  void toggleCompleted(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;

    _tasks[index] = _tasks[index].copyWith(
      isCompleted: !_tasks[index].isCompleted,
    );
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) return;

    final encoded = jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await preferences.setString(_storageKey, encoded);
  }
}
