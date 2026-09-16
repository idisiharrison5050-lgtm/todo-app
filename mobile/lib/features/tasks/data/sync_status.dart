enum SyncStatus { idle, syncing, synced, offline, error }

class SyncState {
  const SyncState({this.status = SyncStatus.idle, this.pending = 0, this.message = '', this.lastSyncedAt});

  final SyncStatus status;
  final int pending;
  final String message;
  final DateTime? lastSyncedAt;

  bool get isSyncing => status == SyncStatus.syncing;
  bool get hasIssue => status == SyncStatus.offline || status == SyncStatus.error;

  SyncState copyWith({SyncStatus? status, int? pending, String? message, Object? lastSyncedAt = _unspecified}) {
    return SyncState(
      status: status ?? this.status,
      pending: pending ?? this.pending,
      message: message ?? this.message,
      lastSyncedAt: identical(lastSyncedAt, _unspecified) ? this.lastSyncedAt : lastSyncedAt as DateTime?,
    );
  }
}

const Object _unspecified = Object();
