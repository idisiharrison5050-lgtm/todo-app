enum PendingOperationType { upsert, delete }

class PendingOperation {
  const PendingOperation({required this.id, required this.type, required this.updatedAt});
  final String id;
  final PendingOperationType type;
  final DateTime updatedAt;
}

abstract interface class SyncMetadataStore {
  Future<List<PendingOperation>> getPendingOperations();
  Future<void> markPendingUpsert(String id, DateTime updatedAt);
  Future<void> addPendingDelete(String id);
  Future<void> clearPendingOperation(String id);
  Future<List<String>> getPendingDeletes();
  Future<void> clearPendingDelete(String id);
}
