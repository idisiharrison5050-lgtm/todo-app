import 'package:flutter_test/flutter_test.dart';
import 'package:todo_mobile/features/tasks/data/sync_status.dart';

void main() {
  test('default state is idle', () {
    const state = SyncState();
    expect(state.status, SyncStatus.idle);
    expect(state.pending, 0);
    expect(state.hasIssue, isFalse);
  });

  test('copyWith preserves unspecified values', () {
    final original = SyncState(
      status: SyncStatus.synced,
      pending: 2,
      message: 'Done',
      lastSyncedAt: DateTime(2026, 1, 1),
    );
    final changed = original.copyWith(status: SyncStatus.syncing);
    expect(changed.status, SyncStatus.syncing);
    expect(changed.pending, 2);
    expect(changed.message, 'Done');
    expect(changed.lastSyncedAt, DateTime(2026, 1, 1));
  });

  test('issue states are marked correctly', () {
    expect(const SyncState(status: SyncStatus.offline).hasIssue, isTrue);
    expect(const SyncState(status: SyncStatus.error).hasIssue, isTrue);
    expect(const SyncState(status: SyncStatus.syncing).isSyncing, isTrue);
  });
}
