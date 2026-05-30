import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:csc234_clubconnect/features/auth/screens/welcome_screen.dart';
import '../../helpers/test_app.dart';

void main() {
  group('WelcomeScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(makeTestApp(child: const WelcomeScreen()));
      await tester.pumpAndSettle();
    });

    testWidgets('shows Login button', (tester) async {
      await tester.pumpWidget(makeTestApp(child: const WelcomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows tagline Drop-in !', (tester) async {
      await tester.pumpWidget(makeTestApp(child: const WelcomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Drop-in !'), findsOneWidget);
    });

    testWidgets('shows Sign Up somewhere in RichText', (tester) async {
      await tester.pumpWidget(makeTestApp(child: const WelcomeScreen()));
      await tester.pumpAndSettle();
      // 'Sign Up' is a TextSpan inside a RichText; match via full rendered text
      final richTextFinder = find.byWidgetPredicate((w) =>
          w is RichText &&
          w.text.toPlainText().contains('Sign Up'));
      expect(richTextFinder, findsWidgets);
    });

    testWidgets('ElevatedButton present for Login', (tester) async {
      await tester.pumpWidget(makeTestApp(child: const WelcomeScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });
}
