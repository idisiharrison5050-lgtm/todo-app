import 'package:flutter/foundation.dart';

import '../data/preferences_task_repository.dart';
import '../data/task_repository.dart';
import '../domain/task.dart';

class TaskStore extends ChangeNotifier {
  TaskStore({TaskRepository? repository})
      : _repository = repository ?? PreferencesTaskRepository();

  final TaskRepository _repository;
  final List<Task> _tasks = <Task>[];
  bool _isLoaded = false;

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (_isLoaded) return;

    final loaded = await _repository.getTasks();
    _tasks
      ..clear()
      ..addAll(loaded);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    String notes = '',
    DateTime? dueAt,
    TaskReminderType reminderType = TaskReminderType.none,
    Duration? reminderInterval,
    TaskPriority priority = TaskPriority.normal,
  }) async {
    final task = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      notes: notes.trim(),
      dueAt: dueAt,
      reminderType: reminderType,
      reminderInterval: reminderInterval,
      priority: priority,
    );

    await _repository.saveTask(task);
    _tasks.add(task);
    notifyListeners();
  }

  Future<void> toggleCompleted(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;

    final updated = _tasks[index].copyWith(
      isCompleted: !_tasks[index].isCompleted,
    );
    await _repository.saveTask(updated);
    _tasks[index] = updated;
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }
}
