import 'package:flutter/foundation.dart';

import '../domain/task.dart';

class TaskStore extends ChangeNotifier {
  final List<Task> _tasks = <Task>[];

  List<Task> get tasks => List.unmodifiable(_tasks);

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
    notifyListeners();
  }

  void toggleCompleted(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;

    _tasks[index] = _tasks[index].copyWith(
      isCompleted: !_tasks[index].isCompleted,
    );
    notifyListeners();
  }
}
