import 'package:flutter_test/flutter_test.dart';

import 'package:todo_mobile/app/app.dart';

void main() {
  testWidgets('renders the Today screen after initialization', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());

    // Let the initialization Future complete without waiting for unrelated
    // repeating animations or timers to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Your tasks'), findsOneWidget);
    expect(find.text('Nothing planned yet'), findsOneWidget);
    expect(find.text('Add task'), findsOneWidget);
  });
}
