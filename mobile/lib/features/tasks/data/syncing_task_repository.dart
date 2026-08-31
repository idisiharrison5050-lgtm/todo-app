import '../domain/task.dart';
import 'cloud_task_sync.dart';
import 'task_repository.dart';

class SyncingTaskRepository implements TaskRepository {
  SyncingTaskRepository(this._local, this._cloud);

  final TaskRepository _local;
  final CloudTaskSync _cloud;

  @override
  Future<List<Task>> getTasks() async {
    final local = await _local.getTasks();
    try {
      final remote = await _cloud.pull();
      final merged = <String, Task>{for (final task in local) task.id: task};
      for (final task in remote) merged[task.id] = task;
      final result = merged.values.toList(growable: false);
      for (final task in result) await _local.saveTask(task);
      final remoteIds = remote.map((task) => task.id).toSet();
      for (final task in local.where((task) => !remoteIds.contains(task.id))) await _cloud.push(task);
      return result;
    } catch (_) {
      return local;
    }
  }

  @override
  Future<void> saveTask(Task task) async {
    await _local.saveTask(task);
    try { await _cloud.push(task); } catch (_) {}
  }

  @override
  Future<void> deleteTask(String id) async {
    await _local.deleteTask(id);
    try { await _cloud.delete(id); } catch (_) {}
  }

  @override
  Future<void> close() async {
    await _local.close();
  }
}
