import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:csc234_clubconnect/features/home/screens/home_screen.dart';
import '../../helpers/fake_providers.dart';
import '../../helpers/test_app.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders without crash (logged-out state)', (tester) async {
      // user == null: no Firebase calls made in initState
      await tester.pumpWidget(makeTestApp(
        child: const HomeScreen(),
        auth: FakeAuthProvider()..user = null,
        community: FakeCommunityProvider(),
        event: FakeEventProvider(),
        profile: FakeProfileProvider(),
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('shows Discover tab', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const HomeScreen(),
        auth: FakeAuthProvider(),
        community: FakeCommunityProvider(),
        event: FakeEventProvider(),
        profile: FakeProfileProvider(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Discover'), findsWidgets);
    });

    testWidgets('shows My club tab', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const HomeScreen(),
        auth: FakeAuthProvider(),
        community: FakeCommunityProvider(),
        event: FakeEventProvider(),
        profile: FakeProfileProvider(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('My club'), findsWidgets);
    });

    testWidgets('shows Trending tab', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const HomeScreen(),
        auth: FakeAuthProvider(),
        community: FakeCommunityProvider(),
        event: FakeEventProvider(),
        profile: FakeProfileProvider(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Trending'), findsWidgets);
    });

    testWidgets('shows search field', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const HomeScreen(),
        auth: FakeAuthProvider(),
        community: FakeCommunityProvider(),
        event: FakeEventProvider(),
        profile: FakeProfileProvider(),
      ));
      await tester.pumpAndSettle();
      final hasSearch = tester.widgetList(find.byType(TextField)).isNotEmpty ||
          tester.widgetList(find.byIcon(Icons.search)).isNotEmpty;
      expect(hasSearch, isTrue);
    });
  });
}
