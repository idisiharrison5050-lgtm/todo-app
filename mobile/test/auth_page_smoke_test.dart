import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_mobile/features/auth/application/auth_store.dart';
import 'package:todo_mobile/features/auth/presentation/auth_page.dart';

void main() {
  testWidgets('renders sign in experience', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthPage(store: AuthStore(), onAuthenticated: () {}),
      ),
    );

    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('New here?  Create an account'), findsOneWidget);
  });
}
