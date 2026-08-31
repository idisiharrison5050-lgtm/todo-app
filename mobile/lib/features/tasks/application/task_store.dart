import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../reminders/application/reminder_scheduler.dart';
import '../data/task_repository.dart';
import '../data/task_repository_factory.dart';
import '../domain/task.dart';

class TaskStore extends ChangeNotifier {
  TaskStore({TaskRepository? repository, ReminderScheduler? reminderScheduler})
      : _repository = repository ?? createTaskRepository(),
        _reminderScheduler = reminderScheduler ?? _createReminderScheduler();

  static const Uuid _uuid = Uuid();
  final TaskRepository _repository;
  final ReminderScheduler _reminderScheduler;
  final List<Task> _tasks = <Task>[];
  bool _isLoaded = false;

  static ReminderScheduler _createReminderScheduler() {
    if (kIsWeb) return NoopReminderScheduler();
    return LocalReminderScheduler();
  }

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

  Future<void> addTask({required String title, String notes = '', DateTime? dueAt, TaskReminderType reminderType = TaskReminderType.none, Duration? reminderInterval, TaskPriority priority = TaskPriority.normal}) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) throw ArgumentError('Task title cannot be empty.');
    final normalizedDueAt = _normalizeDueAt(dueAt);
    _validateSchedule(normalizedDueAt, reminderType, reminderInterval);
    final task = Task(id: _uuid.v4(), title: normalizedTitle, notes: notes.trim(), dueAt: normalizedDueAt, reminderType: reminderType, reminderInterval: reminderInterval, priority: priority);
    await _repository.saveTask(task);
    _tasks.add(task);
    await _syncReminder(task);
    notifyListeners();
  }

  Future<void> updateTask(String id, {required String title, String notes = '', DateTime? dueAt, TaskReminderType reminderType = TaskReminderType.none, Duration? reminderInterval, TaskPriority priority = TaskPriority.normal}) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) throw ArgumentError('Task title cannot be empty.');
    final normalizedDueAt = _normalizeDueAt(dueAt);
    _validateSchedule(normalizedDueAt, reminderType, reminderInterval);
    final updated = _tasks[index].copyWith(title: normalizedTitle, notes: notes.trim(), dueAt: normalizedDueAt, reminderType: reminderType, reminderInterval: reminderInterval, priority: priority);
    await _repository.saveTask(updated);
    _tasks[index] = updated;
    await _syncReminder(updated);
    notifyListeners();
  }

  Future<void> toggleCompleted(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;
    final updated = _tasks[index].copyWith(isCompleted: !_tasks[index].isCompleted);
    await _repository.saveTask(updated);
    _tasks[index] = updated;
    if (updated.isCompleted) await _reminderScheduler.cancel(updated.id); else await _syncReminder(updated);
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    _tasks.removeWhere((task) => task.id == id);
    await _reminderScheduler.cancel(id);
    notifyListeners();
  }

  Future<void> clearCompleted() async {
    final completed = _tasks.where((task) => task.isCompleted).toList(growable: false);
    for (final task in completed) { await _repository.deleteTask(task.id); await _reminderScheduler.cancel(task.id); }
    _tasks.removeWhere((task) => task.isCompleted);
    notifyListeners();
  }

  void _validateSchedule(DateTime? dueAt, TaskReminderType reminderType, Duration? reminderInterval) {
    if (dueAt != null && dueAt.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) throw ArgumentError('Task date and time must be in the future.');
    if (reminderType != TaskReminderType.none && dueAt == null) throw ArgumentError('A reminder requires a due date and time.');
    if (reminderType == TaskReminderType.interval && (reminderInterval == null || reminderInterval.inMinutes <= 0)) throw ArgumentError('A repeating reminder must have a valid interval.');
  }

  Future<void> _restoreReminders() async {
    final reminderTasks = _tasks.where((task) => !task.isCompleted && task.reminderType != TaskReminderType.none && task.dueAt != null).toList(growable: false);
    if (reminderTasks.isEmpty) return;
    final permitted = await _reminderScheduler.requestPermission();
    if (!permitted && !kIsWeb) return;
    for (final task in reminderTasks) await _reminderScheduler.schedule(task);
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
  void dispose() { _repository.close(); super.dispose(); }
}
