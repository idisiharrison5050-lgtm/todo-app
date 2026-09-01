abstract interface class SyncMetadataStore {
  Future<List<String>> getPendingDeletes();
  Future<void> addPendingDelete(String id);
  Future<void> clearPendingDelete(String id);
}
