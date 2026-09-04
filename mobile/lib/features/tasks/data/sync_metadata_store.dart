enum PendingOperationType { upsert, delete }

class PendingOperation {
  const PendingOperation({required this.id, required this.type, required this.updatedAt, this.operationId});
  final String id;
  final PendingOperationType type;
  final DateTime updatedAt;
  final String? operationId;
}

abstract interface class SyncMetadataStore {
  Future<List<PendingOperation>> getPendingOperations();
  Future<void> markPendingUpsert(String id, DateTime updatedAt, {String? operationId});
  Future<void> addPendingDelete(String id, {String? operationId});
  Future<void> clearPendingOperation(String id);
  Future<List<String>> getPendingDeletes();
  Future<String?> getPendingDeleteOperationId(String id);
  Future<void> clearPendingDelete(String id);
}
