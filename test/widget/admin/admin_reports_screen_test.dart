import 'package:flutter_test/flutter_test.dart';
import 'package:csc234_clubconnect/features/admin/screens/admin_reports_screen.dart';
import '../../helpers/fake_providers.dart';
import '../../helpers/test_app.dart';

void main() {
  group('AdminReportsScreen — access control', () {
    testWidgets('shows Access Denied when role is null', (tester) async {
      final auth = FakeAuthProvider()..role = null;
      await tester.pumpWidget(makeTestApp(
        child: const AdminReportsScreen(),
        auth: auth,
        report: FakeReportProvider(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('shows Access Denied when role is user', (tester) async {
      final auth = FakeAuthProvider()..role = 'user';
      await tester.pumpWidget(makeTestApp(
        child: const AdminReportsScreen(),
        auth: auth,
        report: FakeReportProvider(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('does NOT show Access Denied for admin role', (tester) async {
      final auth = FakeAuthProvider()..role = 'admin';
      await tester.pumpWidget(makeTestApp(
        child: const AdminReportsScreen(),
        auth: auth,
        report: FakeReportProvider(),
      ));
      // Only pump once — admin view has StreamBuilder that awaits Firestore.
      // We verify the access denied widget is absent.
      await tester.pump();
      expect(find.text('Access Denied'), findsNothing);
    });
  });
}
