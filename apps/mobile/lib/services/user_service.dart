import 'dart:typed_data';

/// TODO: Replace stubs with real API calls.
/// Backend team: implement these methods.
class UserService {
  /// TODO: GET /api/users/me
  static Future<Map<String, dynamic>> fetchProfile() async {
    return {};
  }

  /// TODO: PUT /api/users/me
  static Future<void> updateProfile({
    required String username,
    required String bio,
    required Set<String> interests,
  }) async {}

  /// TODO: PUT /api/users/me/avatar
  static Future<void> updateAvatar(Uint8List bytes) async {}

  /// TODO: PUT /api/users/me/cover
  static Future<void> updateCover(Uint8List bytes) async {}
}
