import 'package:flutter/foundation.dart';

import '../domain/task.dart';
import 'cloud_task_sync.dart';
import 'sync_status.dart';
import 'task_repository.dart';

class SyncingTaskRepository implements TaskRepository {
  SyncingTaskRepository(this._local, this._cloud);

  final TaskRepository _local;
  final CloudTaskSync _cloud;
  final ValueNotifier<SyncState> state = ValueNotifier(const SyncState());

  Future<void> syncNow() async {
    state.value = state.value.copyWith(status: SyncStatus.syncing);
    try {
      final local = await _local.getTasks();
      final remote = await _cloud.pull();
      final merged = <String, Task>{};

      for (final task in remote) {
        merged[task.id] = task;
      }
      for (final task in local) {
        // Local state wins when the same task exists on both sides. This keeps
        // edits made offline from being discarded during the next pull.
        merged[task.id] = task;
      }

      final result = merged.values.toList(growable: false);
      for (final task in result) {
        await _local.saveTask(task);
      }

      // Push every local task. The Laravel endpoint uses client_id with
      // updateOrCreate, so existing remote tasks are updated rather than
      // duplicated, while offline-created tasks are uploaded when connection
      // returns.
      for (final task in local) {
        await _cloud.push(task);
      }

      state.value = state.value.copyWith(
        status: SyncStatus.synced,
        pending: 0,
        message: 'Synced',
        lastSyncedAt: DateTime.now(),
      );
    } catch (_) {
      state.value = state.value.copyWith(
        status: SyncStatus.offline,
        message: 'Working offline',
      );
    }
  }

  @override
  Future<List<Task>> getTasks() async {
    await syncNow();
    return _local.getTasks();
  }

  @override
  Future<void> saveTask(Task task) async {
    await _local.saveTask(task);
    state.value = state.value.copyWith(
      status: SyncStatus.syncing,
      pending: state.value.pending + 1,
    );
    try {
      await _cloud.push(task);
      state.value = state.value.copyWith(
        status: SyncStatus.synced,
        pending: state.value.pending > 0 ? state.value.pending - 1 : 0,
        message: 'Saved and synced',
        lastSyncedAt: DateTime.now(),
      );
    } catch (_) {
      state.value = state.value.copyWith(
        status: SyncStatus.offline,
        message: 'Saved offline',
      );
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    await _local.deleteTask(id);
    try {
      await _cloud.delete(id);
      state.value = state.value.copyWith(
        status: SyncStatus.synced,
        message: 'Deleted and synced',
        lastSyncedAt: DateTime.now(),
      );
    } catch (_) {
      state.value = state.value.copyWith(
        status: SyncStatus.offline,
        message: 'Deleted offline',
      );
    }
  }

  @override
  Future<void> close() async {
    state.dispose();
    await _local.close();
  }
}
