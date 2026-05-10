import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _notifications = NotificationService();

  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

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

  /// Sets isBanned = true and records the reason on the user document.
  /// Also sends a "restriction" notification to the banned user.
  static Future<void> banUser(String userId, String reason) async {
    final current = _auth.currentUser;
    if (current == null) throw Exception('Not authenticated');

    await _users.doc(userId).update({
      'isBanned': true,
      'banReason': reason,
      'bannedAt': FieldValue.serverTimestamp(),
      'bannedBy': current.uid,
    });

    await _notifications.createNotification(userId, {
      'communityId': '',
      'mentionedBy': current.uid,
      'title': 'You have been restricted',
      'description': reason.isNotEmpty ? reason : 'You have been restricted from the platform.',
      'type': 'restriction',
    });
  }

  /// Sets isBanned = false and clears the ban reason.
  static Future<void> unbanUser(String userId) async {
    final current = _auth.currentUser;
    if (current == null) throw Exception('Not authenticated');

    await _users.doc(userId).update({
      'isBanned': false,
      'banReason': FieldValue.delete(),
      'bannedAt': FieldValue.delete(),
      'bannedBy': FieldValue.delete(),
    });
  }
}
