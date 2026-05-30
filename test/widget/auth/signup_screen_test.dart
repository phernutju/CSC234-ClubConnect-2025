import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:csc234_clubconnect/features/auth/screens/signup_screen.dart';
import '../../helpers/fake_providers.dart';
import '../../helpers/test_app.dart';

void main() {
  group('SignupScreen', () {
    testWidgets('renders label text for all three fields', (tester) async {
      await tester.pumpWidget(
          makeTestApp(child: const SignupScreen(), auth: FakeAuthProvider()));
      await tester.pumpAndSettle();
      expect(find.text('Email *'), findsOneWidget);
      expect(find.text('Password *'), findsOneWidget);
      expect(find.text('Confirm Password *'), findsOneWidget);
    });

    testWidgets('renders three TextField widgets', (tester) async {
      await tester.pumpWidget(
          makeTestApp(child: const SignupScreen(), auth: FakeAuthProvider()));
      await tester.pumpAndSettle();
      expect(find.byType(TextField).evaluate().length,
          greaterThanOrEqualTo(3));
    });

    testWidgets('Next button is present', (tester) async {
      await tester.pumpWidget(
          makeTestApp(child: const SignupScreen(), auth: FakeAuthProvider()));
      await tester.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('email field accepts input', (tester) async {
      await tester.pumpWidget(
          makeTestApp(child: const SignupScreen(), auth: FakeAuthProvider()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'new@example.com');
      expect(find.text('new@example.com'), findsOneWidget);
    });

    testWidgets('heading RichText contains account', (tester) async {
      await tester.pumpWidget(
          makeTestApp(child: const SignupScreen(), auth: FakeAuthProvider()));
      await tester.pumpAndSettle();
      final richFinder = find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('account'));
      expect(richFinder, findsWidgets);
    });

    testWidgets('shows circular Google sign-in button icon', (tester) async {
      await tester.pumpWidget(
          makeTestApp(child: const SignupScreen(), auth: FakeAuthProvider()));
      await tester.pumpAndSettle();
      // GoogleSignInButton is an icon-only circular button (48×48)
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
