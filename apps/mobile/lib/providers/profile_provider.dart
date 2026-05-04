import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../services/user_service.dart';

/// Holds the current user's editable profile data for the session.
/// Shared via MultiProvider so all screens see the same instance.
class ProfileProvider extends ChangeNotifier {
  String _username = 'Username';
  String _bio = AppStrings.profileBio;
  Uint8List? _avatarBytes;
  Uint8List? _coverBytes;
  final Set<String> _selectedInterests = {};

  String get username => _username;
  String get bio => _bio;
  Uint8List? get avatarBytes => _avatarBytes;
  Uint8List? get coverBytes => _coverBytes;
  Set<String> get selectedInterests => Set.unmodifiable(_selectedInterests);

  /// Persist username and bio. Pass [interests] to also update the interest set,
  /// or omit it to leave interests unchanged (e.g., when saving from set-profile screen).
  void saveProfile({
    required String username,
    required String bio,
    Set<String>? interests,
  }) {
    _username = username.isEmpty ? 'Username' : username;
    _bio = bio.isEmpty ? _bio : bio;
    if (interests != null) {
      _selectedInterests
        ..clear()
        ..addAll(interests);
    }
    UserService.updateProfile(
      username: _username,
      bio: _bio,
      interests: Set.unmodifiable(_selectedInterests),
    );
    notifyListeners();
  }

  /// Persist selected interests (called from category screen on completion).
  void saveInterests(Set<String> interests) {
    _selectedInterests
      ..clear()
      ..addAll(interests);
    UserService.updateProfile(
      username: _username,
      bio: _bio,
      interests: Set.unmodifiable(_selectedInterests),
    );
    notifyListeners();
  }

  /// Persist avatar immediately when picked (does not require pressing Save).
  void updateAvatar(Uint8List bytes) {
    _avatarBytes = bytes;
    UserService.updateAvatar(bytes);
    notifyListeners();
  }

  /// Persist cover photo immediately when picked (does not require pressing Save).
  void updateCover(Uint8List bytes) {
    _coverBytes = bytes;
    UserService.updateCover(bytes);
    notifyListeners();
  }

  /// Resets all profile data back to defaults (called on logout).
  void logout() {
    _username = 'Username';
    _bio = AppStrings.profileBio;
    _avatarBytes = null;
    _coverBytes = null;
    _selectedInterests.clear();
    notifyListeners();
  }
}
