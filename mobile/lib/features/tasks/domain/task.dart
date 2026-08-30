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
    Object? dueAt = _copyWithUnspecified,
    TaskReminderType? reminderType,
    Object? reminderInterval = _copyWithUnspecified,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueAt: identical(dueAt, _copyWithUnspecified) ? this.dueAt : dueAt as DateTime?,
      reminderType: reminderType ?? this.reminderType,
      reminderInterval: identical(reminderInterval, _copyWithUnspecified)
          ? this.reminderInterval
          : reminderInterval as Duration?,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'dueAt': dueAt?.toIso8601String(),
      'reminderType': reminderType.name,
      'reminderIntervalMinutes': reminderInterval?.inMinutes,
      'priority': priority.name,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final reminderName = json['reminderType'] as String?;
    final priorityName = json['priority'] as String?;
    final reminderType = TaskReminderType.values.firstWhere(
      (value) => value.name == reminderName,
      orElse: () => TaskReminderType.none,
    );
    final priority = TaskPriority.values.firstWhere(
      (value) => value.name == priorityName,
      orElse: () => TaskPriority.normal,
    );
    final intervalMinutes = json['reminderIntervalMinutes'] as int?;
    final dueAtText = json['dueAt'] as String?;

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      dueAt: dueAtText == null ? null : DateTime.tryParse(dueAtText),
      reminderType: reminderType,
      reminderInterval: intervalMinutes == null ? null : Duration(minutes: intervalMinutes),
      priority: priority,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

const Object _copyWithUnspecified = Object();
