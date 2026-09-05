import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../reminders/application/reminder_scheduler.dart';
import '../data/connectivity_sync_manager.dart';
import '../data/syncing_task_repository.dart';
import '../data/task_repository.dart';
import '../data/task_repository_factory.dart';
import '../domain/task.dart';

class TaskStore extends ChangeNotifier {
  TaskStore({TaskRepository? repository, ReminderScheduler? reminderScheduler})
      : _repository = repository ?? createTaskRepository(),
        _reminderScheduler = reminderScheduler ?? _createReminderScheduler() {
    if (_repository is SyncingTaskRepository) {
      _connectivitySyncManager = ConnectivitySyncManager(_repository)..start();
    }
  }

  static const Uuid _uuid = Uuid();
  final TaskRepository _repository;
  final ReminderScheduler _reminderScheduler;
  final List<Task> _tasks = <Task>[];
  ConnectivitySyncManager? _connectivitySyncManager;
  bool _isLoaded = false;

  static ReminderScheduler _createReminderScheduler() => kIsWeb ? NoopReminderScheduler() : LocalReminderScheduler();
  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (_isLoaded) return;
    final loaded = await _repository.getTasks();
    _tasks..clear()..addAll(loaded);
    _isLoaded = true;
    await _restoreReminders();
    notifyListeners();
  }

  Future<void> reloadForAccount() async {
    _isLoaded = false;
    _tasks.clear();
    await load();
  }

  void clearForLogout() {
    unawaited(_reminderScheduler.cancelAll());
    _tasks.clear();
    _isLoaded = false;
    notifyListeners();
  }

  Future<void> addTask({required String title, String notes = '', DateTime? dueAt, TaskReminderType reminderType = TaskReminderType.none, Duration? reminderInterval, TaskPriority priority = TaskPriority.normal, TaskRepeat repeat = TaskRepeat.none, int? repeatIntervalDays, bool isFavorite = false, String category = '', List<String> tags = const <String>[]}) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) throw ArgumentError('Task title cannot be empty.');
    final normalizedDueAt = _normalizeDueAt(dueAt);
    _validateSchedule(normalizedDueAt, reminderType, reminderInterval, repeat, repeatIntervalDays);
    final now = DateTime.now();
    final task = Task(id: _uuid.v4(), title: normalizedTitle, notes: notes.trim(), dueAt: normalizedDueAt, reminderType: reminderType, reminderInterval: reminderInterval, reminderTimeZone: _currentTimeZone(), priority: priority, repeat: repeat, repeatIntervalDays: repeatIntervalDays, isFavorite: isFavorite, category: category.trim(), tags: List.unmodifiable(tags), createdAt: now, history: <TaskHistoryEntry>[_history('Created', 'Task created', now)]);
    await _repository.saveTask(task);
    _tasks.add(task);
    notifyListeners();
    await _syncReminderSafely(task);
  }

  Future<void> updateTask(String id, {required String title, String notes = '', DateTime? dueAt, TaskReminderType reminderType = TaskReminderType.none, Duration? reminderInterval, TaskPriority priority = TaskPriority.normal, TaskRepeat? repeat, int? repeatIntervalDays, bool? isFavorite, String? category, List<String>? tags}) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) throw ArgumentError('Task title cannot be empty.');
    final normalizedDueAt = _normalizeDueAt(dueAt);
    final current = _tasks[index];
    final effectiveRepeat = repeat ?? current.repeat;
    final effectiveRepeatIntervalDays = repeatIntervalDays ?? current.repeatIntervalDays;
    _validateSchedule(normalizedDueAt, reminderType, reminderInterval, effectiveRepeat, effectiveRepeatIntervalDays, allowPastDue: true);
    final changes = <String>[];
    if (current.title != normalizedTitle) changes.add('Title changed');
    if (current.notes != notes.trim()) changes.add('Notes changed');
    if (current.dueAt != normalizedDueAt) changes.add('Schedule changed');
    if (current.reminderType != reminderType || current.reminderInterval != reminderInterval) changes.add('Reminder changed');
    if (current.priority != priority) changes.add('Priority changed');
    if (repeat != null && current.repeat != repeat) changes.add('Repeat changed');
    if (repeatIntervalDays != null && current.repeatIntervalDays != repeatIntervalDays) changes.add('Repeat interval changed');
    if (isFavorite != null && current.isFavorite != isFavorite) changes.add(isFavorite ? 'Added to favorites' : 'Removed from favorites');
    if (category != null && current.category != category.trim()) changes.add('Category changed');
    if (tags != null && current.tags.join('|') != tags.join('|')) changes.add('Tags changed');
    final reminderTimeZone = reminderType == TaskReminderType.none ? null : (current.reminderTimeZone ?? _currentTimeZone());
    final updated = current.copyWith(title: normalizedTitle, notes: notes.trim(), dueAt: normalizedDueAt, reminderType: reminderType, reminderInterval: reminderInterval, reminderTimeZone: reminderTimeZone, priority: priority, repeat: repeat, repeatIntervalDays: repeatIntervalDays, isFavorite: isFavorite, category: category?.trim(), tags: tags, history: changes.isEmpty ? current.history : [...current.history, _history(changes.length == 1 ? changes.single : 'Task updated', changes.join(' • '))]);
    await _repository.saveTask(updated);
    _tasks[index] = updated;
    notifyListeners();
    await _syncReminderSafely(updated);
  }

  Future<void> toggleFavorite(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;
    final favorite = !_tasks[index].isFavorite;
    final updated = _withHistory(_tasks[index].copyWith(isFavorite: favorite), favorite ? 'Added to favorites' : 'Removed from favorites', 'Favorite status changed');
    await _repository.saveTask(updated);
    _tasks[index] = updated;
    notifyListeners();
  }

  Future<void> toggleCompleted(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;

    final current = _tasks[index];
    final completing = !current.isCompleted;
    var updated = current.copyWith(isCompleted: completing);
    var historyAction = completing ? 'Completed' : 'Reopened';
    var historyDetail = completing ? 'Task completed' : 'Task marked active';

    if (completing && current.repeat != TaskRepeat.none && current.dueAt != null) {
      updated = _nextRecurringTask(current);
      historyAction = 'Completed occurrence';
      historyDetail = 'Next occurrence: ${_historySchedule(updated.dueAt!)}';
    }

    updated = _withHistory(updated, historyAction, historyDetail);

    _tasks[index] = updated;
    notifyListeners();

    try {
      await _repository.saveTask(updated);
      if (updated.isCompleted) {
        await _reminderScheduler.cancel(updated.id);
      } else {
        await _syncReminder(updated);
      }
    } catch (_) {
      // Persistence/scheduling runs in the background so the UI stays responsive.
    }
  }

  Future<void> addSubtask(String taskId, String title) async {
    final clean = title.trim();
    if (clean.isEmpty) return;
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    final current = _tasks[index];
    final subtask = TaskSubtask(id: _uuid.v4(), title: clean);
    final updated = _withHistory(current.copyWith(subtasks: [...current.subtasks, subtask]), 'Subtask added', clean);
    await _repository.saveTask(updated);
    _tasks[index] = updated;
    notifyListeners();
  }

  Future<void> updateSubtask(String taskId, String subtaskId, {String? title, bool? isCompleted}) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    final current = _tasks[index];
    final changed = current.subtasks.firstWhere((item) => item.id == subtaskId, orElse: () => const TaskSubtask(id: '', title: ''));
    final subtasks = current.subtasks.map((item) => item.id == subtaskId ? item.copyWith(title: title, isCompleted: isCompleted) : item).toList();
    final action = isCompleted != null && changed.isCompleted != isCompleted ? (isCompleted ? 'Subtask completed' : 'Subtask reopened') : 'Subtask edited';
    final updated = _withHistory(current.copyWith(subtasks: subtasks), action, title ?? changed.title);
    await _repository.saveTask(updated);
    _tasks[index] = updated;
    notifyListeners();
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    final current = _tasks[index];
    final removed = current.subtasks.firstWhere((item) => item.id == subtaskId, orElse: () => const TaskSubtask(id: '', title: ''));
    final updated = _withHistory(current.copyWith(subtasks: current.subtasks.where((item) => item.id != subtaskId).toList()), 'Subtask deleted', removed.title);
    await _repository.saveTask(updated);
    _tasks[index] = updated;
    notifyListeners();
  }

  TaskHistoryEntry _history(String action, String detail, [DateTime? timestamp]) => TaskHistoryEntry(id: _uuid.v4(), action: action, detail: detail, timestamp: timestamp ?? DateTime.now());
  Task _withHistory(Task task, String action, String detail) => task.copyWith(history: [...task.history, _history(action, detail)]);

  Task _nextRecurringTask(Task task) {
    final originalDue = task.dueAt!;
    var next = _advanceRecurringDate(task, originalDue);
    final now = DateTime.now();
    while (!next.isAfter(now)) {
      next = _advanceRecurringDate(task, next);
    }
    return task.copyWith(dueAt: next, isCompleted: false);
  }

  DateTime _advanceRecurringDate(Task task, DateTime due) {
    switch (task.repeat) {
      case TaskRepeat.daily:
        return _addCalendarDays(due, 1);
      case TaskRepeat.weekdays:
        var next = _addCalendarDays(due, 1);
        while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
          next = _addCalendarDays(next, 1);
        }
        return next;
      case TaskRepeat.weekly:
        return _addCalendarDays(due, 7);
      case TaskRepeat.monthly:
        return _addCalendarMonthClamped(due, 1);
      case TaskRepeat.custom:
        return _addCalendarDays(due, task.repeatIntervalDays ?? 1);
      case TaskRepeat.none:
        return due;
    }
  }

  String _historySchedule(DateTime value) => '${value.day}/${value.month}/${value.year} at ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  DateTime _addCalendarDays(DateTime value, int days) => DateTime(value.year, value.month, value.day + days, value.hour, value.minute, value.second);

  DateTime _addCalendarMonthClamped(DateTime value, int months) {
    final targetMonth = value.month + months;
    final targetYear = value.year + ((targetMonth - 1) ~/ 12);
    final month = ((targetMonth - 1) % 12) + 1;
    final lastDay = DateTime(targetYear, month + 1, 0).day;
    final day = value.day > lastDay ? lastDay : value.day;
    return DateTime(targetYear, month, day, value.hour, value.minute, value.second);
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
    await _reminderScheduler.cancel(id);
  }

  Future<void> clearCompleted() async {
    final completed = _tasks.where((task) => task.isCompleted).toList(growable: false);
    for (final task in completed) {
      await _repository.deleteTask(task.id);
      await _reminderScheduler.cancel(task.id);
    }
    _tasks.removeWhere((task) => task.isCompleted);
    notifyListeners();
  }

  void _validateSchedule(DateTime? dueAt, TaskReminderType reminderType, Duration? reminderInterval, TaskRepeat repeat, int? repeatIntervalDays, {bool allowPastDue = false}) {
    if (!allowPastDue && dueAt != null && dueAt.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      throw ArgumentError('Task date and time must be in the future.');
    }
    if (reminderType != TaskReminderType.none && dueAt == null) {
      throw ArgumentError('A reminder requires a due date and time.');
    }
    if (reminderType == TaskReminderType.interval && (reminderInterval == null || reminderInterval.inMinutes <= 0)) {
      throw ArgumentError('A repeating reminder must have a valid interval.');
    }
    if (repeat != TaskRepeat.none && dueAt == null) {
      throw ArgumentError('A recurring task requires a due date and time.');
    }
    if (repeat == TaskRepeat.custom && (repeatIntervalDays == null || repeatIntervalDays <= 0)) {
      throw ArgumentError('A custom recurrence must have a valid interval in days.');
    }
  }

  Future<void> _restoreReminders() async {
    final tasks = _tasks.where((task) => !task.isCompleted && task.reminderType != TaskReminderType.none && task.dueAt != null).toList(growable: false);
    if (tasks.isEmpty) return;
    final permitted = await _reminderScheduler.requestPermission();
    if (!permitted && !kIsWeb) return;
    for (final task in tasks) {
      await _reminderScheduler.schedule(task);
    }
  }

  Future<void> _syncReminder(Task task) async {
    await _reminderScheduler.cancel(task.id);
    if (task.isCompleted || task.reminderType == TaskReminderType.none || task.dueAt == null) return;
    final permitted = await _reminderScheduler.requestPermission();
    if (!permitted && !kIsWeb) return;
    await _reminderScheduler.schedule(task);
  }

  Future<void> _syncReminderSafely(Task task) async {
    try {
      await _syncReminder(task);
    } catch (_) {
      // A notification failure must not delay or undo the task UI update.
    }
  }

  String _currentTimeZone() {
    tz_data.initializeTimeZones();
    return tz.local.name;
  }

  DateTime? _normalizeDueAt(DateTime? value) => value == null ? null : DateTime(value.year, value.month, value.day, value.hour, value.minute);

  @override
  void dispose() {
    _connectivitySyncManager?.dispose();
    unawaited(_repository.close());
    super.dispose();
  }
}
