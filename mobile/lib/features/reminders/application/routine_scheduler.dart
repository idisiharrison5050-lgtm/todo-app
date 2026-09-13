import '../data/local_notification_service.dart';
import '../domain/routine.dart';

class RoutineScheduler {
  RoutineScheduler({LocalNotificationService? notifications}) : _notifications = notifications ?? LocalNotificationService();

  final LocalNotificationService _notifications;
  static const int _daysToSchedule = 14;
  static const int _occurrencesPerRoutine = 500;

  static int _notificationId(String routineId, DateTime date) {
    var hash = 0x811c9dc5;
    final value = '$routineId:${date.millisecondsSinceEpoch}';
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 2 : hash;
  }

  Future<void> schedule(Routine routine) async {
    await cancelWithDefinition(routine);
    if (!routine.enabled || routine.title.trim().isEmpty || routine.days.isEmpty) return;

    var scheduledCount = 0;
    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset < _daysToSchedule && scheduledCount < _occurrencesPerRoutine; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      if (!routine.days.contains(date.weekday)) continue;

      for (var minutes = routine.startMinutes; minutes <= routine.endMinutes && scheduledCount < _occurrencesPerRoutine; minutes += routine.intervalMinutes) {
        final scheduledAt = DateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
        if (!scheduledAt.isAfter(now)) continue;
        await _notifications.scheduleOneTime(
          id: _notificationId(routine.id, scheduledAt),
          title: routine.title,
          body: routine.body.trim().isEmpty ? 'Your scheduled routine reminder.' : routine.body.trim(),
          scheduledAt: scheduledAt,
          payload: 'routine:${routine.id}',
          includeSnoozeActions: false,
        );
        scheduledCount++;
      }
    }
  }

  Future<void> cancelWithDefinition(Routine routine) async {
    var cancelled = 0;
    final now = DateTime.now();
    for (var dayOffset = -1; dayOffset <= _daysToSchedule && cancelled < _occurrencesPerRoutine; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      if (!routine.days.contains(date.weekday)) continue;
      for (var minutes = routine.startMinutes; minutes <= routine.endMinutes && cancelled < _occurrencesPerRoutine; minutes += routine.intervalMinutes) {
        final scheduledAt = DateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
        await _notifications.cancel(_notificationId(routine.id, scheduledAt));
        cancelled++;
      }
    }
  }

  Future<void> cancelAll(Iterable<Routine> routines) async {
    for (final routine in routines) {
      await cancelWithDefinition(routine);
    }
  }
}
