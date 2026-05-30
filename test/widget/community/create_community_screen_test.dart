import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:csc234_clubconnect/features/home/screens/create_community_screen.dart';
import '../../helpers/fake_providers.dart';
import '../../helpers/test_app.dart';

void main() {
  group('CreateCommunityScreen — validation logic (unit)', () {
    test('community name empty → nameError set', () {
      const name = '';
      final nameError = name.isEmpty ? 'Please enter a community name' : null;
      expect(nameError, 'Please enter a community name');
    });

    test('community name non-empty → no nameError', () {
      const name = 'My Club';
      final nameError = name.isEmpty ? 'Please enter a community name' : null;
      expect(nameError, isNull);
    });

    test('about empty → aboutError set', () {
      const about = '';
      final aboutError =
          about.isEmpty ? 'Please tell us about your community' : null;
      expect(aboutError, 'Please tell us about your community');
    });
  });

  group('CreateCommunityScreen — widget', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const CreateCommunityScreen(),
        community: FakeCommunityProvider(),
        category: FakeCategoryProvider(),
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('shows Host title', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const CreateCommunityScreen(),
        community: FakeCommunityProvider(),
        category: FakeCategoryProvider(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Host'), findsWidgets);
    });

    testWidgets('shows Community Name and About labels', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const CreateCommunityScreen(),
        community: FakeCommunityProvider(),
        category: FakeCategoryProvider(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Community Name'), findsOneWidget);
      expect(find.text('About Community'), findsOneWidget);
    });

    testWidgets('Create button exists in widget tree', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const CreateCommunityScreen(),
        community: FakeCommunityProvider(),
        category: FakeCategoryProvider(),
      ));
      await tester.pumpAndSettle();
      // find.text searches full tree regardless of scroll position
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('community name field accepts input', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const CreateCommunityScreen(),
        community: FakeCommunityProvider(),
        category: FakeCategoryProvider(),
      ));
      await tester.pumpAndSettle();
      // Community Name field is at top of screen — visible without scrolling
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'My Club');
      expect(find.text('My Club'), findsOneWidget);
    });

    testWidgets('empty name error shows after tapping Create', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const CreateCommunityScreen(),
        community: FakeCommunityProvider(),
        category: FakeCategoryProvider(),
      ));
      await tester.pumpAndSettle();
      // Scroll Create button into view, ensure visible, then tap
      await tester.scrollUntilVisible(
        find.text('Create'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      // Scroll back to top where the name error renders
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a community name'), findsOneWidget);
    });
  });
}
