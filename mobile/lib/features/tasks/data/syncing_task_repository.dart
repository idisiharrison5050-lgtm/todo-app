import 'dart:async';
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
  bool _syncRunning = false;
  SyncMetadataStore? get _metadata => _local is SyncMetadataStore ? _local as SyncMetadataStore : null;

  Future<void> syncNow() async {
    if (_syncRunning) return;
    _syncRunning = true;
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
      final remoteById = <String, Task>{for (final task in remote) task.id: task};
      for (final task in local) {
        final remoteTask = remoteById[task.id];
        if (remoteTask == null) {
          final serverTask = await _cloud.push(task);
          await _local.saveTask(serverTask);
          continue;
        }
        final localTime = task.updatedAt;
        final remoteTime = remoteTask.updatedAt;
        if (localTime != null && remoteTime != null && remoteTime.isAfter(localTime)) {
          await _local.saveTask(remoteTask);
        } else {
          final serverTask = await _cloud.push(task);
          await _local.saveTask(serverTask);
        }
      }
      final localIds = local.map((task) => task.id).toSet();
      for (final task in remote) {
        if (!localIds.contains(task.id)) await _local.saveTask(task);
      }
      state.value = state.value.copyWith(status: SyncStatus.synced, pending: 0, message: 'Synced', lastSyncedAt: DateTime.now());
    } on DioException catch (error) {
      if (error.response?.statusCode != null && error.response!.statusCode! >= 400) {
        state.value = state.value.copyWith(status: SyncStatus.error, message: 'Cloud sync unavailable');
      } else {
        state.value = state.value.copyWith(status: SyncStatus.offline, message: 'Working offline');
      }
    } catch (_) {
      state.value = state.value.copyWith(status: SyncStatus.offline, message: 'Working offline');
    } finally {
      _syncRunning = false;
    }
  }

  @override
  Future<List<Task>> getTasks() async {
    final tasks = await _local.getTasks();
    unawaited(syncNow());
    return tasks;
  }

  @override
  Future<void> saveTask(Task task) async {
    final now = DateTime.now().toUtc();
    final changedTask = task.updatedAt == null ? task.copyWith(updatedAt: now) : task;
    await _local.saveTask(changedTask);
    final metadata = _metadata;
    if (metadata != null) await metadata.clearPendingDelete(changedTask.id);
    state.value = state.value.copyWith(status: SyncStatus.syncing, pending: state.value.pending + 1);
    try {
      final serverTask = await _cloud.push(changedTask);
      await _local.saveTask(serverTask);
      state.value = state.value.copyWith(status: SyncStatus.synced, pending: state.value.pending > 0 ? state.value.pending - 1 : 0, message: 'Saved and synced', lastSyncedAt: DateTime.now());
    } on DioException catch (error) {
      if (error.response?.statusCode != null && error.response!.statusCode! >= 400) {
        state.value = state.value.copyWith(status: SyncStatus.error, message: 'Saved locally — will sync later');
      } else {
        state.value = state.value.copyWith(status: SyncStatus.offline, message: 'Saved offline');
      }
    } catch (_) {
      state.value = state.value.copyWith(status: SyncStatus.offline, message: 'Saved offline');
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
      if (error.response?.statusCode != null && error.response!.statusCode! >= 400) {
        state.value = state.value.copyWith(status: SyncStatus.error, message: 'Deleted locally — will sync later');
      } else {
        state.value = state.value.copyWith(status: SyncStatus.offline, message: 'Deleted offline');
      }
    } catch (_) {
      state.value = state.value.copyWith(status: SyncStatus.offline, message: 'Deleted offline');
    }
  }

  @override
  Future<void> close() async { state.dispose(); await _local.close(); }
}
