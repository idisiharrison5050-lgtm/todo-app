import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/local_notification_service.dart';
import '../domain/routine.dart';

class RoutineScheduler {
  RoutineScheduler({LocalNotificationService? notifications}) : _notifications = notifications ?? LocalNotificationService();

  final LocalNotificationService _notifications;

  static int _notificationId(String routineId, String slot) {
    var hash = 0x811c9dc5;
    final value = '$routineId:$slot';
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 2 : hash;
  }

  Future<void> schedule(Routine routine) async {
    await cancelWithDefinition(routine);
    if (!routine.enabled || routine.title.trim().isEmpty || routine.days.isEmpty) return;

    final now = DateTime.now();
    final everyDay = routine.days.length == 7;

    for (var minutes = routine.startMinutes; minutes <= routine.endMinutes; minutes += routine.intervalMinutes) {
      if (everyDay) {
        final scheduledAt = _nextDailyOccurrence(now, minutes);
        await _notifications.scheduleRecurring(
          id: _notificationId(routine.id, 'daily:$minutes'),
          title: routine.title,
          body: routine.body.trim().isEmpty ? 'Your scheduled routine reminder.' : routine.body.trim(),
          scheduledAt: scheduledAt,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'routine:${routine.id}',
        );
        continue;
      }

      for (final weekday in routine.days) {
        final scheduledAt = _nextWeeklyOccurrence(now, weekday, minutes);
        await _notifications.scheduleRecurring(
          id: _notificationId(routine.id, 'weekly:$weekday:$minutes'),
          title: routine.title,
          body: routine.body.trim().isEmpty ? 'Your scheduled routine reminder.' : routine.body.trim(),
          scheduledAt: scheduledAt,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'routine:${routine.id}',
        );
      }
    }
  }

  Future<void> cancelWithDefinition(Routine routine) async {
    await _notifications.cancelByPayloadPrefix('routine:${routine.id}');
  }

  Future<void> cancelAll(Iterable<Routine> routines) async {
    for (final routine in routines) {
      await cancelWithDefinition(routine);
    }
  }

  DateTime _nextDailyOccurrence(DateTime now, int minutes) {
    var candidate = DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
    if (!candidate.isAfter(now)) candidate = candidate.add(const Duration(days: 1));
    return candidate;
  }

  DateTime _nextWeeklyOccurrence(DateTime now, int weekday, int minutes) {
    var dayOffset = (weekday - now.weekday) % 7;
    var candidate = DateTime(now.year, now.month, now.day + dayOffset, minutes ~/ 60, minutes % 60);
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }
}