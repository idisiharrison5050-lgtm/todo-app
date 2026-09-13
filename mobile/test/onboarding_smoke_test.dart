import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_mobile/features/reminders/data/local_notification_service.dart';
import 'package:todo_mobile/features/tasks/presentation/first_run_onboarding_page.dart';

void main() {
  testWidgets('renders the first-run onboarding flow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FirstRunOnboardingPage(
          notifications: LocalNotificationService(),
          onComplete: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todo'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Turn a busy day into a clear plan.'), findsOneWidget);
    expect(find.text('Fast task capture'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('Stay productive, even when life goes offline.'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('Enable notifications'), findsOneWidget);
    expect(find.text('Start planning'), findsOneWidget);
  });
}
