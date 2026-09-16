import 'package:flutter_test/flutter_test.dart';
import 'package:todo_mobile/features/tasks/data/sync_error.dart';

void main() {
  test('creates retryable failures by default', () {
    const failure = SyncFailure(message: 'Network unavailable');
    expect(failure.message, 'Network unavailable');
    expect(failure.retryable, isTrue);
    expect(failure.toString(), 'Network unavailable');
  });

  test('supports non-retryable failures', () {
    const failure = SyncFailure(message: 'Unauthorized', retryable: false);
    expect(failure.retryable, isFalse);
  });
}
