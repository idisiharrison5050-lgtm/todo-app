import '../domain/task.dart';

abstract interface class TaskRepository {
  Future<List<Task>> getTasks();
  Future<void> saveTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> close();
}
