class SyncFailure implements Exception {
  const SyncFailure({required this.message, this.retryable = true});

  final String message;
  final bool retryable;

  @override
  String toString() => message;
}
