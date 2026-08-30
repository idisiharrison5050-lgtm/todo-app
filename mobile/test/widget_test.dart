import 'package:flutter_test/flutter_test.dart';

import 'package:todo_mobile/app/app.dart';

void main() {
  testWidgets('renders the Today screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Your tasks'), findsOneWidget);
    expect(find.text('Nothing planned yet'), findsOneWidget);
    expect(find.text('Add task'), findsOneWidget);
  });
}
