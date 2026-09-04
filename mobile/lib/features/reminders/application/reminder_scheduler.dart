import '../data/local_notification_service.dart';
import '../domain/reminder_schedule.dart';
import '../../tasks/domain/task.dart';

abstract interface class ReminderScheduler {
  Future<bool> requestPermission();
  Future<void> schedule(Task task);
  Future<void> snooze(Task task, int minutes);
  Future<void> cancel(String taskId);
  Future<void> cancelAll();
}

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler({LocalNotificationService? notifications})
      : _notifications = notifications ?? LocalNotificationService() {
    LocalNotificationService.onSnoozeRequested = _handleSnooze;
  }

  final LocalNotificationService _notifications;

  static const int _recurringOccurrences = 30;
  static const int _snoozeOccurrence = 99;

  static int _notificationId(String taskId, [int occurrence = 0]) {
    var hash = 0x811c9dc5;
    final value = '$taskId:$occurrence';
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  @override
  Future<bool> requestPermission() => _notifications.requestPermissions();

  @override
  Future<void> schedule(Task task) async {
    await cancel(task.id);

    final schedule = buildReminderSchedule(task);
    if (schedule == null) return;

    await _notifications.scheduleOneTime(
      id: _notificationId(task.id),
      title: task.title,
      body: 'You have a scheduled task.',
      scheduledAt: schedule.fireAt,
      payload: task.id,
    );

    final interval = schedule.repeatInterval;
    if (interval == null) return;

    var next = schedule.fireAt;
    for (var occurrence = 1; occurrence < _recurringOccurrences; occurrence++) {
      next = next.add(interval);
      await _notifications.scheduleOneTime(
        id: _notificationId(task.id, occurrence),
        title: task.title,
        body: 'You have a scheduled task.',
        scheduledAt: next,
        payload: task.id,
      );
    }
  }

  @override
  Future<void> snooze(Task task, int minutes) async {
    if (minutes <= 0 || task.title.trim().isEmpty) return;

    await _notifications.cancel(_notificationId(task.id, _snoozeOccurrence));
    await _notifications.scheduleOneTime(
      id: _notificationId(task.id, _snoozeOccurrence),
      title: task.title,
      body: 'Snoozed reminder.',
      scheduledAt: DateTime.now().add(Duration(minutes: minutes)),
      payload: task.id,
      includeSnoozeActions: true,
    );
  }

  Future<void> _handleSnooze(String taskId, int minutes) async {
    if (taskId.isEmpty || minutes <= 0) return;

    await _notifications.cancel(_notificationId(taskId, _snoozeOccurrence));
    await _notifications.scheduleOneTime(
      id: _notificationId(taskId, _snoozeOccurrence),
      title: 'Task reminder',
      body: 'Snoozed reminder.',
      scheduledAt: DateTime.now().add(Duration(minutes: minutes)),
      payload: taskId,
      includeSnoozeActions: true,
    );
  }

  @override
  Future<void> cancel(String taskId) async {
    for (var occurrence = 0; occurrence < _recurringOccurrences; occurrence++) {
      await _notifications.cancel(_notificationId(taskId, occurrence));
    }
    await _notifications.cancel(_notificationId(taskId, _snoozeOccurrence));
  }

  @override
  Future<void> cancelAll() => _notifications.cancelAll();
}

/// Keeps tests and unsupported platforms independent from native notification APIs.
class NoopReminderScheduler implements ReminderScheduler {
  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(Task task) async {}

  @override
  Future<void> snooze(Task task, int minutes) async {}

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> cancelAll() async {}
}
