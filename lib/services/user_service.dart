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

  static Timestamp? _expiresAt(String durationLabel) {
    final now = DateTime.now();
    switch (durationLabel) {
      case '1 hours':  return Timestamp.fromDate(now.add(const Duration(hours: 1)));
      case '6 hours':  return Timestamp.fromDate(now.add(const Duration(hours: 6)));
      case '12 hours': return Timestamp.fromDate(now.add(const Duration(hours: 12)));
      case '24 hours': return Timestamp.fromDate(now.add(const Duration(hours: 24)));
      case '7 Days':   return Timestamp.fromDate(now.add(const Duration(days: 7)));
      case '1 Month':  return Timestamp.fromDate(now.add(const Duration(days: 30)));
      default:         return null; // Permanently
    }
  }

  static Future<void> banUser(String userId, String reason, String durationLabel) async {
    final current = _auth.currentUser;
    if (current == null) throw Exception('Not authenticated');

    final expiresAt = _expiresAt(durationLabel);
    final isPermanent = expiresAt == null;

    final data = <String, dynamic>{
      'isBanned': true,
      'banReason': reason,
      'durationLabel': durationLabel,
      'bannedAt': FieldValue.serverTimestamp(),
      'bannedBy': current.uid,
      'banExpiresAt': expiresAt ?? FieldValue.delete(),
    };
    await _users.doc(userId).update(data);

    final durationText = isPermanent ? 'permanently' : 'for $durationLabel';
    await _notifications.createNotification(userId, {
      'communityId': '',
      'mentionedBy': current.uid,
      'title': 'You have been restricted',
      'description': 'Your account has been restricted $durationText. Reason: ${reason.isNotEmpty ? reason : 'Violation of community guidelines'}',
      'type': 'restriction',
    });
  }

  static Future<void> unbanUser(String userId) async {
    final current = _auth.currentUser;
    if (current == null) throw Exception('Not authenticated');

    await _users.doc(userId).update({
      'isBanned': false,
      'isMuted': false,
      'violationCount': 0,
      'banReason': FieldValue.delete(),
      'durationLabel': FieldValue.delete(),
      'banExpiresAt': FieldValue.delete(),
      'bannedAt': FieldValue.delete(),
      'bannedBy': FieldValue.delete(),
    });
  }

  static Stream<List<Map<String, dynamic>>> streamBannedUsers() {
    final bannedStream = _db
        .collection('users')
        .where('isBanned', isEqualTo: true)
        .snapshots();
    final mutedStream = _db
        .collection('users')
        .where('isMuted', isEqualTo: true)
        .snapshots();

    return bannedStream.asyncExpand((bannedSnap) {
      return mutedStream.map((mutedSnap) {
        final seen = <String>{};
        final result = <Map<String, dynamic>>[];
        for (final doc in [...bannedSnap.docs, ...mutedSnap.docs]) {
          if (seen.add(doc.id)) {
            final data = doc.data();
            data['uid'] = doc.id;
            result.add(data);
          }
        }
        return result;
      });
    });
  }
}
