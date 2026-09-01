import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

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
      _connectivitySyncManager = ConnectivitySyncManager(_repository as SyncingTaskRepository)..start();
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

  Future<void> addTask({required String title, String notes = '', DateTime? dueAt, TaskReminderType reminderType = TaskReminderType.none, Duration? reminderInterval, TaskPriority priority = TaskPriority.normal, TaskRepeat repeat = TaskRepeat.none, int? repeatIntervalDays, bool isFavorite = false, String category = '', List<String> tags = const <String>[]}) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) throw ArgumentError('Task title cannot be empty.');
    final normalizedDueAt = _normalizeDueAt(dueAt);
    _validateSchedule(normalizedDueAt, reminderType, reminderInterval);
    final now = DateTime.now();
    final task = Task(id: _uuid.v4(), title: normalizedTitle, notes: notes.trim(), dueAt: normalizedDueAt, reminderType: reminderType, reminderInterval: reminderInterval, priority: priority, repeat: repeat, repeatIntervalDays: repeatIntervalDays, isFavorite: isFavorite, category: category.trim(), tags: List.unmodifiable(tags), createdAt: now, history: <TaskHistoryEntry>[_history('Created', 'Task created', now)]);
    await _repository.saveTask(task);
    _tasks.add(task);
    await _syncReminder(task);
    notifyListeners();
  }

  Future<void> updateTask(String id, {required String title, String notes = '', DateTime? dueAt, TaskReminderType reminderType = TaskReminderType.none, Duration? reminderInterval, TaskPriority priority = TaskPriority.normal, TaskRepeat? repeat, int? repeatIntervalDays, bool? isFavorite, String? category, List<String>? tags}) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) throw ArgumentError('Task title cannot be empty.');
    final normalizedDueAt = _normalizeDueAt(dueAt);
    _validateSchedule(normalizedDueAt, reminderType, reminderInterval);
    final current = _tasks[index];
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
    final updated = current.copyWith(title: normalizedTitle, notes: notes.trim(), dueAt: normalizedDueAt, reminderType: reminderType, reminderInterval: reminderInterval, priority: priority, repeat: repeat, repeatIntervalDays: repeatIntervalDays, isFavorite: isFavorite, category: category?.trim(), tags: tags, history: changes.isEmpty ? current.history : [...current.history, _history(changes.length == 1 ? changes.single : 'Task updated', changes.join(' • '))]);
    await _repository.saveTask(updated);
    _tasks[index] = updated;
    await _syncReminder(updated);
    notifyListeners();
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
    if (completing && current.repeat != TaskRepeat.none && current.dueAt != null) updated = _nextRecurringTask(current);
    updated = _withHistory(updated, completing ? 'Completed' : 'Reopened', completing ? 'Task completed' : 'Task marked active');
    await _repository.saveTask(updated);
    _tasks[index] = updated;
    if (updated.isCompleted) await _reminderScheduler.cancel(updated.id); else await _syncReminder(updated);
    notifyListeners();
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
    final due = task.dueAt!;
    DateTime next = due;
    switch (task.repeat) {
      case TaskRepeat.daily: next = due.add(const Duration(days: 1)); break;
      case TaskRepeat.weekdays:
        next = due.add(const Duration(days: 1));
        while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) next = next.add(const Duration(days: 1));
        break;
      case TaskRepeat.weekly: next = due.add(const Duration(days: 7)); break;
      case TaskRepeat.monthly: next = DateTime(due.year, due.month + 1, due.day, due.hour, due.minute); break;
      case TaskRepeat.custom: next = due.add(Duration(days: task.repeatIntervalDays ?? 1)); break;
      case TaskRepeat.none: return task.copyWith(isCompleted: true);
    }
    return task.copyWith(dueAt: next, isCompleted: false);
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    _tasks.removeWhere((task) => task.id == id);
    await _reminderScheduler.cancel(id);
    notifyListeners();
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

  void _validateSchedule(DateTime? dueAt, TaskReminderType reminderType, Duration? reminderInterval) {
    if (dueAt != null && dueAt.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) throw ArgumentError('Task date and time must be in the future.');
    if (reminderType != TaskReminderType.none && dueAt == null) throw ArgumentError('A reminder requires a due date and time.');
    if (reminderType == TaskReminderType.interval && (reminderInterval == null || reminderInterval.inMinutes <= 0)) throw ArgumentError('A repeating reminder must have a valid interval.');
  }

  Future<void> _restoreReminders() async {
    final tasks = _tasks.where((task) => !task.isCompleted && task.reminderType != TaskReminderType.none && task.dueAt != null).toList(growable: false);
    if (tasks.isEmpty) return;
    final permitted = await _reminderScheduler.requestPermission();
    if (!permitted && !kIsWeb) return;
    for (final task in tasks) await _reminderScheduler.schedule(task);
  }

  Future<void> _syncReminder(Task task) async {
    await _reminderScheduler.cancel(task.id);
    if (task.isCompleted || task.reminderType == TaskReminderType.none || task.dueAt == null) return;
    final permitted = await _reminderScheduler.requestPermission();
    if (!permitted && !kIsWeb) return;
    await _reminderScheduler.schedule(task);
  }

  DateTime? _normalizeDueAt(DateTime? value) => value == null ? null : DateTime(value.year, value.month, value.day, value.hour, value.minute);

  @override
  void dispose() {
    unawaited(_connectivitySyncManager?.dispose());
    _repository.close();
    super.dispose();
  }
}
