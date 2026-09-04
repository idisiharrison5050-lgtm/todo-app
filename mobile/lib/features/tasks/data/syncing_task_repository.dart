import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/task.dart';
import 'cloud_task_sync.dart';
import 'local_task_database.dart';
import 'sync_metadata_store.dart';
import 'sync_status.dart';
import 'task_repository.dart';

class SyncingTaskRepository implements TaskRepository {
  SyncingTaskRepository(this._local, this._cloud);

  final TaskRepository _local;
  final CloudTaskSync _cloud;
  final ValueNotifier<SyncState> state = ValueNotifier(const SyncState());
  static const Uuid _uuid = Uuid();
  bool _syncRunning = false;

  SyncMetadataStore? get _metadata {
    final local = _local;
    if (local is SyncMetadataStore) return local;
    return null;
  }

  Future<void> syncNow() async {
    if (_syncRunning) return;
    _syncRunning = true;
    state.value = state.value.copyWith(status: SyncStatus.syncing, message: 'Syncing…');
    try {
      final metadata = _metadata;
      if (metadata != null) {
        final operations = await metadata.getPendingOperations();
        for (final operation in operations) {
          if (operation.type == PendingOperationType.delete) {
            int? version;
            String? operationId = operation.operationId;
            if (_local is LocalTaskDatabase) {
              version = await _local.getPendingDeleteVersion(operation.id);
              operationId ??= await _local.getPendingDeleteOperationId(operation.id);
            }
            await _cloud.delete(operation.id, syncVersion: version, operationId: operationId);
            await metadata.clearPendingOperation(operation.id);
            continue;
          }

          final tasks = await _local.getTasks();
          final matchingTasks = tasks.where((item) => item.id == operation.id);
          final task = matchingTasks.isEmpty ? null : matchingTasks.first;
          if (task == null) {
            await metadata.clearPendingOperation(operation.id);
            continue;
          }

          final sentUpdatedAt = task.updatedAt;
          final serverTask = await _cloud.push(task, operationId: operation.operationId);
          final current = await _findLocalTask(task.id);
          if (serverTask == null) {
            if (_isSameLocalRevision(current, task)) await _local.deleteTask(task.id);
          } else if (_isSameLocalRevision(current, task, sentUpdatedAt: sentUpdatedAt)) {
            await _local.saveTask(serverTask);
          }
          await metadata.clearPendingOperation(operation.id);
        }
      }

      final pendingDeletes = metadata == null ? const <String>[] : await metadata.getPendingDeletes();
      for (final id in pendingDeletes) {
        int? version;
        String? operationId;
        if (_local is LocalTaskDatabase) {
          version = await _local.getPendingDeleteVersion(id);
          operationId = await _local.getPendingDeleteOperationId(id);
        }
        await _cloud.delete(id, syncVersion: version, operationId: operationId);
        await metadata?.clearPendingDelete(id);
      }

      final deletedIds = await _cloud.pullDeletedIds();
      for (final id in deletedIds) {
        await _local.deleteTask(id);
        if (metadata != null) await metadata.clearPendingOperation(id);
      }

      final local = await _local.getTasks();
      final remote = await _cloud.pull();
      final remoteById = <String, Task>{for (final task in remote) task.id: task};
      final pendingIds = metadata == null ? <String>{} : (await metadata.getPendingOperations()).map((operation) => operation.id).toSet();

      for (final task in local) {
        if (deletedIds.contains(task.id) || pendingIds.contains(task.id)) continue;
        final remoteTask = remoteById[task.id];
        if (remoteTask == null) {
          final serverTask = await _pushPersisted(task, metadata);
          final current = await _findLocalTask(task.id);
          if (serverTask == null) {
            if (_isSameLocalRevision(current, task)) await _local.deleteTask(task.id);
          } else if (_isSameLocalRevision(current, task)) {
            await _local.saveTask(serverTask);
          }
          continue;
        }

        final localVersion = task.syncVersion;
        final remoteVersion = remoteTask.syncVersion;
        if (localVersion != null && remoteVersion != null) {
          if (remoteVersion > localVersion) {
            final current = await _findLocalTask(task.id);
            if (_isSameLocalRevision(current, task)) await _local.saveTask(remoteTask);
          } else if (localVersion > remoteVersion) {
            final sentUpdatedAt = task.updatedAt;
            final serverTask = await _pushPersisted(task, metadata);
            final current = await _findLocalTask(task.id);
            if (serverTask == null) {
              if (_isSameLocalRevision(current, task)) await _local.deleteTask(task.id);
            } else if (_isSameLocalRevision(current, task, sentUpdatedAt: sentUpdatedAt)) {
              await _local.saveTask(serverTask);
            }
          }
        } else {
          final localTime = task.updatedAt;
          final remoteTime = remoteTask.updatedAt;
          if (localTime != null && remoteTime != null && remoteTime.isAfter(localTime)) {
            final current = await _findLocalTask(task.id);
            if (_isSameLocalRevision(current, task)) await _local.saveTask(remoteTask);
          } else {
            final sentUpdatedAt = task.updatedAt;
            final serverTask = await _pushPersisted(task, metadata);
            final current = await _findLocalTask(task.id);
            if (serverTask == null) {
              if (_isSameLocalRevision(current, task)) await _local.deleteTask(task.id);
            } else if (_isSameLocalRevision(current, task, sentUpdatedAt: sentUpdatedAt)) {
              await _local.saveTask(serverTask);
            }
          }
        }
      }

      final localIds = local.map((task) => task.id).toSet();
      for (final task in remote) {
        if (!localIds.contains(task.id) && !deletedIds.contains(task.id)) await _local.saveTask(task);
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

  Future<Task?> _pushPersisted(Task task, SyncMetadataStore? metadata) async {
    final operationId = _uuid.v4();
    if (metadata != null) {
      await metadata.markPendingUpsert(task.id, task.updatedAt ?? DateTime.now().toUtc(), operationId: operationId);
    }
    return _cloud.push(task, operationId: operationId);
  }

  Future<Task?> _findLocalTask(String id) async {
    final tasks = await _local.getTasks();
    final matches = tasks.where((item) => item.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  bool _isSameLocalRevision(Task? current, Task sent, {DateTime? sentUpdatedAt}) {
    if (current == null) return false;
    final expectedUpdatedAt = sentUpdatedAt ?? sent.updatedAt;
    if (expectedUpdatedAt == null || current.updatedAt == null) {
      return current.syncVersion == sent.syncVersion && current.title == sent.title && current.isCompleted == sent.isCompleted;
    }
    return current.updatedAt!.toUtc() == expectedUpdatedAt.toUtc();
  }

  @override
  Future<List<Task>> getTasks() async {
    final tasks = await _local.getTasks();
    unawaited(syncNow());
    return tasks;
  }

  @override
  Future<void> saveTask(Task task) async {
    final changedTask = task.copyWith(updatedAt: DateTime.now().toUtc());
    final operationId = _uuid.v4();
    await _local.saveTask(changedTask);
    final metadata = _metadata;
    if (metadata != null) await metadata.markPendingUpsert(changedTask.id, changedTask.updatedAt!, operationId: operationId);
    state.value = state.value.copyWith(status: SyncStatus.syncing, pending: state.value.pending + 1);
    try {
      final serverTask = await _cloud.push(changedTask, operationId: operationId);
      final current = await _findLocalTask(changedTask.id);
      if (serverTask == null) {
        if (_isSameLocalRevision(current, changedTask)) await _local.deleteTask(changedTask.id);
      } else if (_isSameLocalRevision(current, changedTask)) {
        await _local.saveTask(serverTask);
      }
      if (metadata != null) await metadata.clearPendingOperation(changedTask.id);
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
    final tasks = await _local.getTasks();
    final matchingTasks = tasks.where((item) => item.id == id);
    final task = matchingTasks.isEmpty ? null : matchingTasks.first;
    final metadata = _metadata;
    final operationId = _uuid.v4();
    if (metadata != null) await metadata.addPendingDelete(id, operationId: operationId);
    await _local.deleteTask(id);
    try {
      await _cloud.delete(id, syncVersion: task?.syncVersion, operationId: operationId);
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
  Future<void> close() async {
    state.dispose();
    await _local.close();
  }
}
