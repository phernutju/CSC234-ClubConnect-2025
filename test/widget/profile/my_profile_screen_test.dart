import 'package:flutter_test/flutter_test.dart';
import 'package:csc234_clubconnect/features/profile/screens/my_profile_screen.dart';
import '../../helpers/fake_providers.dart';
import '../../helpers/test_app.dart';

void main() {
  group('MyProfileScreen', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const MyProfileScreen(),
        profile: FakeProfileProvider(),
        rating: FakeRatingProvider(),
        community: FakeCommunityProvider(),
        auth: FakeAuthProvider(),
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('shows username from provider', (tester) async {
      final pp = FakeProfileProvider();
      await tester.pumpWidget(makeTestApp(
        child: const MyProfileScreen(),
        profile: pp,
        rating: FakeRatingProvider(),
        community: FakeCommunityProvider(),
        auth: FakeAuthProvider(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('TestUser'), findsWidgets);
    });

    testWidgets('Edit Profile button present', (tester) async {
      await tester.pumpWidget(makeTestApp(
        child: const MyProfileScreen(),
        profile: FakeProfileProvider(),
        rating: FakeRatingProvider(),
        community: FakeCommunityProvider(),
        auth: FakeAuthProvider(),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Edit'), findsWidgets);
    });

    testWidgets('empty ratings list renders without crash', (tester) async {
      final rat = FakeRatingProvider();
      await tester.pumpWidget(makeTestApp(
        child: const MyProfileScreen(),
        profile: FakeProfileProvider(),
        rating: rat,
        community: FakeCommunityProvider(),
        auth: FakeAuthProvider(),
      ));
      await tester.pumpAndSettle();
    });
  });
}
