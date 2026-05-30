import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:csc234_clubconnect/firebase_options.dart';
import 'package:csc234_clubconnect/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  group('App smoke tests', () {
    testWidgets('app launches and shows welcome or home screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // Welcome screen visible for unauthenticated users
      final hasWelcome = tester.widgetList(find.text('Login')).isNotEmpty ||
          tester.widgetList(find.text('Drop-in !')).isNotEmpty ||
          tester.widgetList(find.text('Sign Up')).isNotEmpty;
      expect(hasWelcome, isTrue);
    });

    testWidgets('login screen navigable from welcome', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      final loginBtn = find.text('Login');
      if (loginBtn.evaluate().isNotEmpty) {
        await tester.tap(loginBtn.first);
        await tester.pumpAndSettle();
        expect(find.text('Email *'), findsOneWidget);
      }
    });
  });
}
