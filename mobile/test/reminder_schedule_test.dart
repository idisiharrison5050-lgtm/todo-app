import 'package:flutter_test/flutter_test.dart';

import 'package:todo_mobile/features/reminders/domain/reminder_schedule.dart';
import 'package:todo_mobile/features/tasks/domain/task.dart';

void main() {
  test('one-time reminder does not schedule in the past', () {
    final now = DateTime(2026, 9, 4, 12, 0);
    final task = Task(id: '1', title: 'Past', dueAt: now.subtract(const Duration(minutes: 1)), reminderType: TaskReminderType.once);
    expect(buildReminderSchedule(task, now: now), isNull);
  });

  test('interval reminder advances to the next future occurrence', () {
    final now = DateTime(2026, 9, 4, 12, 0);
    final task = Task(id: '2', title: 'Repeat', dueAt: now.subtract(const Duration(hours: 2)), reminderType: TaskReminderType.interval, reminderInterval: const Duration(hours: 1));
    final schedule = buildReminderSchedule(task, now: now);
    expect(schedule, isNotNull);
    expect(schedule!.fireAt, now.add(const Duration(hours: 1)));
  });

  test('invalid interval reminder is rejected', () {
    final task = Task(id: '3', title: 'Invalid', dueAt: DateTime(2026, 9, 5), reminderType: TaskReminderType.interval, reminderInterval: Duration.zero);
    expect(buildReminderSchedule(task), isNull);
  });
}
