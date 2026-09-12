import 'package:flutter/foundation.dart';

import 'cloud_task_sync.dart';
import 'local_task_database.dart';
import 'preferences_task_repository.dart';
import 'syncing_task_repository.dart';
import 'task_repository.dart';

TaskRepository createTaskRepository() {
  if (kIsWeb) {
    return PreferencesTaskRepository();
  }
  return SyncingTaskRepository(LocalTaskDatabase(), CloudTaskSync());
}
