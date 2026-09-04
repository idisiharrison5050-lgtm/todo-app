import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'syncing_task_repository.dart';

class ConnectivitySyncManager {
  ConnectivitySyncManager(this._repository);

  final SyncingTaskRepository _repository;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _retryTimer;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) unawaited(_repository.syncNow());
    });
    _retryTimer = Timer.periodic(const Duration(minutes: 5), (_) => unawaited(_repository.syncNow()));
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _started = false;
  }
}
