import '../domain/reminder_schedule.dart';
import '../../tasks/domain/task.dart';

abstract interface class ReminderScheduler {
  Future<bool> requestPermission();
  Future<void> schedule(Task task);
  Future<void> cancel(String taskId);
  Future<void> cancelAll();
}

class NoopReminderScheduler implements ReminderScheduler {
  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(Task task) async {
    // Native notification implementation is added in the platform phase.
    final schedule = buildReminderSchedule(task);
    if (schedule == null) return;
  }

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> cancelAll() async {}
}
