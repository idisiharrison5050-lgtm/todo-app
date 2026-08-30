import '../../tasks/domain/task.dart';

class ReminderSchedule {
  const ReminderSchedule({
    required this.taskId,
    required this.title,
    required this.fireAt,
    this.repeatInterval,
  });

  final String taskId;
  final String title;
  final DateTime fireAt;
  final Duration? repeatInterval;

  bool get isRepeating => repeatInterval != null;
}

ReminderSchedule? buildReminderSchedule(Task task, {DateTime? now}) {
  if (task.reminderType == TaskReminderType.none || task.dueAt == null) {
    return null;
  }

  final current = now ?? DateTime.now();
  if (task.reminderType == TaskReminderType.once) {
    if (!task.dueAt!.isAfter(current)) return null;
    return ReminderSchedule(
      taskId: task.id,
      title: task.title,
      fireAt: task.dueAt!,
    );
  }

  final interval = task.reminderInterval;
  if (interval == null || interval <= Duration.zero) return null;

  var fireAt = task.dueAt!;
  while (!fireAt.isAfter(current)) {
    fireAt = fireAt.add(interval);
  }

  return ReminderSchedule(
    taskId: task.id,
    title: task.title,
    fireAt: fireAt,
    repeatInterval: interval,
  );
}
