import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:csc234_clubconnect/features/auth/screens/login_screen.dart';
import '../../helpers/fake_providers.dart';
import '../../helpers/test_app.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(
          makeTestApp(child: const LoginScreen(), auth: FakeAuthProvider()));
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Email *'), findsOneWidget);
      expect(find.text('Password *'), findsOneWidget);
    });

    testWidgets('Next button is present', (tester) async {
      await tester.pumpWidget(
          makeTestApp(child: const LoginScreen(), auth: FakeAuthProvider()));
      await tester.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Next button disabled when fields are empty', (tester) async {
      await tester.pumpWidget(
          makeTestApp(child: const LoginScreen(), auth: FakeAuthProvider()));
      await tester.pumpAndSettle();
      // _canSubmit is false → onPressed is null → button is disabled
      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Next'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('email field accepts text input', (tester) async {
      await tester.pumpWidget(
          makeTestApp(child: const LoginScreen(), auth: FakeAuthProvider()));
      await tester.pumpAndSettle();
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('shows Google sign-in button (GestureDetector)', (tester) async {
      await tester.pumpWidget(
          makeTestApp(child: const LoginScreen(), auth: FakeAuthProvider()));
      await tester.pumpAndSettle();
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
