import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:csc234_clubconnect/features/chat/screens/chat_screen.dart';
import '../../helpers/fake_providers.dart';
import '../../helpers/test_app.dart';

void main() {
  group('ChatScreen', () {
    testWidgets('renders with community name in app bar', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const ChatScreen(
          communityName: 'Badminton Club',
          memberCount: '',
        ),
        auth: FakeAuthProvider(),
        community: FakeCommunityProvider(),
      ));
      await tester.pumpAndSettle();
      // memberCount empty → title is just communityName
      expect(find.text('Badminton Club'), findsOneWidget);
    });

    testWidgets('renders community name with member count', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const ChatScreen(
          communityName: 'TestRoom',
          memberCount: '12',
        ),
        auth: FakeAuthProvider(),
        community: FakeCommunityProvider(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('TestRoom (12)'), findsOneWidget);
    });

    testWidgets('renders message input bar (TextField present)', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const ChatScreen(
          communityName: 'TestRoom',
          memberCount: '5',
        ),
        auth: FakeAuthProvider(),
        community: FakeCommunityProvider(),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('send icon button present', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const ChatScreen(
          communityName: 'TestRoom',
          memberCount: '5',
        ),
        auth: FakeAuthProvider(),
        community: FakeCommunityProvider(),
      ));
      await tester.pumpAndSettle();
      final hasIcon = tester.widgetList(find.byIcon(Icons.send)).isNotEmpty ||
          tester.widgetList(find.byIcon(Icons.arrow_upward)).isNotEmpty ||
          tester.widgetList(find.byIcon(Icons.send_rounded)).isNotEmpty;
      expect(hasIcon, isTrue);
    });
  });
}
