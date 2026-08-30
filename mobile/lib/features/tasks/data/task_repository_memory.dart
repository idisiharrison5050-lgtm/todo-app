import '../domain/task.dart';
import 'task_repository.dart';

/// In-memory repository used by unit tests.
class MemoryTaskRepository implements TaskRepository {
  final List<Task> _tasks = <Task>[];

  @override
  Future<List<Task>> getTasks() async => List.unmodifiable(_tasks);

  @override
  Future<void> saveTask(Task task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((task) => task.id == id);
  }

  @override
  Future<void> close() async {}
}
