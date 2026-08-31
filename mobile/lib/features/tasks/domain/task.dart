enum TaskReminderType { none, once, interval }

enum TaskPriority { low, normal, high }

enum TaskRepeat { none, daily, weekdays, weekly, monthly, custom }

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
    this.repeat = TaskRepeat.none,
    this.repeatIntervalDays,
    this.isFavorite = false,
    this.category = '',
    this.tags = const <String>[],
    this.createdAt,
  });

  final String id;
  final String title;
  final String notes;
  final DateTime? dueAt;
  final TaskReminderType reminderType;
  final Duration? reminderInterval;
  final TaskPriority priority;
  final bool isCompleted;
  final TaskRepeat repeat;
  final int? repeatIntervalDays;
  final bool isFavorite;
  final String category;
  final List<String> tags;
  final DateTime? createdAt;

  Task copyWith({
    String? title,
    String? notes,
    Object? dueAt = _unspecified,
    TaskReminderType? reminderType,
    Object? reminderInterval = _unspecified,
    TaskPriority? priority,
    bool? isCompleted,
    TaskRepeat? repeat,
    Object? repeatIntervalDays = _unspecified,
    bool? isFavorite,
    String? category,
    List<String>? tags,
    Object? createdAt = _unspecified,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueAt: identical(dueAt, _unspecified) ? this.dueAt : dueAt as DateTime?,
      reminderType: reminderType ?? this.reminderType,
      reminderInterval: identical(reminderInterval, _unspecified) ? this.reminderInterval : reminderInterval as Duration?,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      repeat: repeat ?? this.repeat,
      repeatIntervalDays: identical(repeatIntervalDays, _unspecified) ? this.repeatIntervalDays : repeatIntervalDays as int?,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: identical(createdAt, _unspecified) ? this.createdAt : createdAt as DateTime?,
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
      'repeat': repeat.name,
      'repeatIntervalDays': repeatIntervalDays,
      'isFavorite': isFavorite,
      'category': category,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    T enumValue<T extends Enum>(List<T> values, String? name, T fallback) {
      return values.firstWhere((value) => value.name == name, orElse: () => fallback);
    }
    final interval = json['reminderIntervalMinutes'];
    final repeatDays = json['repeatIntervalDays'];
    final rawTags = json['tags'];
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      dueAt: DateTime.tryParse(json['dueAt'] as String? ?? ''),
      reminderType: enumValue(TaskReminderType.values, json['reminderType'] as String?, TaskReminderType.none),
      reminderInterval: interval is int ? Duration(minutes: interval) : null,
      priority: enumValue(TaskPriority.values, json['priority'] as String?, TaskPriority.normal),
      isCompleted: json['isCompleted'] as bool? ?? false,
      repeat: enumValue(TaskRepeat.values, json['repeat'] as String?, TaskRepeat.none),
      repeatIntervalDays: repeatDays is int ? repeatDays : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
      category: json['category'] as String? ?? '',
      tags: rawTags is List ? rawTags.whereType<String>().toList() : const <String>[],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

const Object _unspecified = Object();
