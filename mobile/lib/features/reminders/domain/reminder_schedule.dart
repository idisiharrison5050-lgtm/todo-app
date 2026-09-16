import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../tasks/domain/task.dart';

class ReminderSchedule {
  const ReminderSchedule({
    required this.taskId,
    required this.title,
    required this.fireAt,
    required this.timeZone,
    this.repeatInterval,
  });

  final String taskId;
  final String title;
  final DateTime fireAt;
  final String timeZone;
  final Duration? repeatInterval;

  bool get isRepeating => repeatInterval != null;
}

ReminderSchedule? buildReminderSchedule(Task task, {DateTime? now}) {
  if (task.reminderType == TaskReminderType.none || task.dueAt == null) {
    return null;
  }

  tz_data.initializeTimeZones();
  final persistedTimeZone = task.reminderTimeZone?.trim();
  final hasPersistedTimeZone = persistedTimeZone?.isNotEmpty == true;
  final current = now ?? DateTime.now();

  if (!hasPersistedTimeZone) {
    return _buildLocalWallClockSchedule(task, current);
  }

  final location = _safeLocation(persistedTimeZone!);
  final currentInZone = tz.TZDateTime.from(current, location);
  var fireAt = _wallClockInZone(task.dueAt!, location);

  if (task.reminderType == TaskReminderType.once) {
    if (!fireAt.isAfter(currentInZone)) {
      return null;
    }
    return ReminderSchedule(
      taskId: task.id,
      title: task.title,
      fireAt: _asDateTime(fireAt),
      timeZone: location.name,
    );
  }

  final interval = task.reminderInterval;
  if (interval == null || interval <= Duration.zero) {
    return null;
  }

  while (!fireAt.isAfter(currentInZone)) {
    fireAt = fireAt.add(interval);
  }

  return ReminderSchedule(
    taskId: task.id,
    title: task.title,
    fireAt: _asDateTime(fireAt),
    timeZone: location.name,
    repeatInterval: interval,
  );
}

ReminderSchedule? _buildLocalWallClockSchedule(Task task, DateTime current) {
  final due = task.dueAt!;
  var fireAt = DateTime(due.year, due.month, due.day, due.hour, due.minute, due.second);
  final currentWallClock = DateTime(current.year, current.month, current.day, current.hour, current.minute, current.second);

  if (task.reminderType == TaskReminderType.once) {
    if (!fireAt.isAfter(currentWallClock)) {
      return null;
    }
    return ReminderSchedule(
      taskId: task.id,
      title: task.title,
      fireAt: fireAt,
      timeZone: tz.local.name,
    );
  }

  final interval = task.reminderInterval;
  if (interval == null || interval <= Duration.zero) {
    return null;
  }

  while (!fireAt.isAfter(currentWallClock)) {
    fireAt = fireAt.add(interval);
  }

  return ReminderSchedule(
    taskId: task.id,
    title: task.title,
    fireAt: fireAt,
    timeZone: tz.local.name,
    repeatInterval: interval,
  );
}

tz.Location _safeLocation(String name) {
  try {
    return tz.getLocation(name);
  } catch (_) {
    return tz.local;
  }
}

tz.TZDateTime _wallClockInZone(DateTime value, tz.Location location) => tz.TZDateTime(location, value.year, value.month, value.day, value.hour, value.minute, value.second);

DateTime _asDateTime(tz.TZDateTime value) => DateTime.fromMillisecondsSinceEpoch(value.millisecondsSinceEpoch);
