import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db;

  NotificationService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notifications(String userId) =>
      _db.collection('users').doc(userId).collection('notifications');

  /// Creates a notification for [targetUserId].
  /// Caller supplies [data] with: communityId, mentionedBy, title, description, type.
  /// createdAt and isRead are set automatically.
  Future<void> createNotification(
    String targetUserId,
    Map<String, dynamic> data,
  ) async {
    await _notifications(targetUserId).add({
      ...data,
      'createdAt': Timestamp.now(),
      'isRead': false,
    });
  }

  /// Returns all notifications for [userId] sorted newest-first, with unread count.
  Future<NotificationsResult> getNotifications(String userId) async {
    final snapshot = await _notifications(userId)
        .orderBy('createdAt', descending: true)
        .get();

    final notifications = snapshot.docs
        .map((doc) => NotificationModel.fromJson(doc.id, doc.data()))
        .toList();

    return NotificationsResult(
      notifications: notifications,
      unreadCount: notifications.where((n) => !n.isRead).length,
    );
  }

  /// Real-time stream of notifications for [userId].
  Stream<NotificationsResult> watchNotifications(String userId) {
    return _notifications(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final notifications = snap.docs
          .map((doc) => NotificationModel.fromJson(doc.id, doc.data()))
          .toList();
      return NotificationsResult(
        notifications: notifications,
        unreadCount: notifications.where((n) => !n.isRead).length,
      );
    });
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _notifications(userId).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot =
        await _notifications(userId).where('isRead', isEqualTo: false).get();

    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    await _notifications(userId).doc(notificationId).delete();
  }
}
