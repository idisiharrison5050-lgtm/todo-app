import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/task.dart';
import 'cloud_task_sync.dart';
import 'sync_metadata_store.dart';
import 'sync_status.dart';
import 'task_repository.dart';

class SyncingTaskRepository implements TaskRepository {
  SyncingTaskRepository(this._local, this._cloud);

  final TaskRepository _local;
  final CloudTaskSync _cloud;
  final ValueNotifier<SyncState> state = ValueNotifier(const SyncState());

  SyncMetadataStore? get _metadata => _local is SyncMetadataStore ? _local as SyncMetadataStore : null;

  Future<void> syncNow() async {
    state.value = state.value.copyWith(status: SyncStatus.syncing, message: 'Syncing…');
    try {
      final metadata = _metadata;
      if (metadata != null) {
        final deletedIds = await metadata.getPendingDeletes();
        for (final id in deletedIds) {
          await _cloud.delete(id);
          await metadata.clearPendingDelete(id);
        }
      }

      final local = await _local.getTasks();
      final remote = await _cloud.pull();
      final merged = <String, Task>{};

      for (final task in remote) {
        merged[task.id] = task;
      }
      for (final task in local) {
        merged[task.id] = task;
      }

      final result = merged.values.toList(growable: false);
      for (final task in result) {
        await _local.saveTask(task);
      }

      for (final task in local) {
        await _cloud.push(task);
      }

      state.value = state.value.copyWith(
        status: SyncStatus.synced,
        pending: 0,
        message: 'Synced',
        lastSyncedAt: DateTime.now(),
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        state.value = state.value.copyWith(status: SyncStatus.error, message: 'Session expired. Please log in again.');
      } else if (statusCode != null && statusCode >= 400) {
        state.value = state.value.copyWith(status: SyncStatus.error, message: 'Sync failed (${statusCode}).');
      } else {
        state.value = state.value.copyWith(status: SyncStatus.offline, message: 'Working offline');
      }
    } catch (_) {
      state.value = state.value.copyWith(status: SyncStatus.error, message: 'Sync failed.');
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
    final metadata = _metadata;
    if (metadata != null) await metadata.clearPendingDelete(task.id);
    state.value = state.value.copyWith(status: SyncStatus.syncing, pending: state.value.pending + 1);
    try {
      await _cloud.push(task);
      state.value = state.value.copyWith(status: SyncStatus.synced, pending: state.value.pending > 0 ? state.value.pending - 1 : 0, message: 'Saved and synced', lastSyncedAt: DateTime.now());
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        state.value = state.value.copyWith(status: SyncStatus.error, message: 'Session expired. Please log in again.');
      } else if (statusCode != null && statusCode >= 400) {
        state.value = state.value.copyWith(status: SyncStatus.error, message: 'Saved locally, but sync failed (${statusCode}).');
      } else {
        state.value = state.value.copyWith(status: SyncStatus.offline, message: 'Saved offline');
      }
    } catch (_) {
      state.value = state.value.copyWith(status: SyncStatus.error, message: 'Saved locally, but sync failed.');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    final metadata = _metadata;
    if (metadata != null) await metadata.addPendingDelete(id);
    await _local.deleteTask(id);
    try {
      await _cloud.delete(id);
      if (metadata != null) await metadata.clearPendingDelete(id);
      state.value = state.value.copyWith(status: SyncStatus.synced, message: 'Deleted and synced', lastSyncedAt: DateTime.now());
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        state.value = state.value.copyWith(status: SyncStatus.error, message: 'Session expired. Please log in again.');
      } else if (statusCode != null && statusCode >= 400) {
        state.value = state.value.copyWith(status: SyncStatus.error, message: 'Deleted locally, but sync failed (${statusCode}).');
      } else {
        state.value = state.value.copyWith(status: SyncStatus.offline, message: 'Deleted offline');
      }
    } catch (_) {
      state.value = state.value.copyWith(status: SyncStatus.error, message: 'Deleted locally, but sync failed.');
    }
  }

  @override
  Future<void> close() async {
    state.dispose();
    await _local.close();
  }
}
