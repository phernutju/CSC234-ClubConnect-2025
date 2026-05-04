import '../constants/app_constants.dart';

/// Payload passed via GoRouter `extra` when navigating to `/other-profile`.
/// Carries the minimum info the other-user profile screen needs to display.
class ProfileArgs {
  final String username;
  final String communityName;

  const ProfileArgs({
    this.username = AppStrings.rateTestUsername,
    this.communityName = AppStrings.rateTestCommunity,
  });
}
