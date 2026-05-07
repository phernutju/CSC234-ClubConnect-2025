import 'package:flutter_test/flutter_test.dart';
import 'package:csc234_clubconnect/main.dart';

void main() {
  testWidgets('App smoke test — root widget mounts', (WidgetTester tester) async {
    await tester.pumpWidget(const ClubConnectApp());
    expect(find.byType(ClubConnectApp), findsOneWidget);
  });
}
