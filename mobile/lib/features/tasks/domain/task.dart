enum TaskReminderType {
  none,
  once,
  interval,
}

enum TaskPriority {
  low,
  normal,
  high,
}

class Task {
  const Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.dueAt,
    this.reminderType = TaskReminderType.none,
    this.reminderInterval,
    this.priority = TaskPriority.normal,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String notes;
  final DateTime? dueAt;
  final TaskReminderType reminderType;
  final Duration? reminderInterval;
  final TaskPriority priority;
  final bool isCompleted;

  Task copyWith({
    String? title,
    String? notes,
    DateTime? dueAt,
    TaskReminderType? reminderType,
    Duration? reminderInterval,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueAt: dueAt ?? this.dueAt,
      reminderType: reminderType ?? this.reminderType,
      reminderInterval: reminderInterval ?? this.reminderInterval,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
