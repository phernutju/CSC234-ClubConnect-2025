import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
    try {
      await _notifications(targetUserId).add({
        ...data,
        'createdAt': Timestamp.now(),
        'isRead': false,
      });
    } catch (e, st) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'NotificationService.createNotification failed',
        information: ['targetUserId=$targetUserId', 'type=${data['type']}'],
      );
      rethrow;
    }
  }

  /// Returns all notifications for [userId] sorted newest-first, with unread count.
  Future<NotificationsResult> getNotifications(String userId) async {
    try {
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
    } catch (e, st) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'NotificationService.getNotifications failed',
        information: ['userId=$userId'],
      );
      rethrow;
    }
  }

  /// Real-time stream of notifications for [userId].
  Stream<NotificationsResult> watchNotifications(String userId) {
    return _notifications(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((Object e, StackTrace st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'NotificationService.watchNotifications stream failure',
        information: ['userId=$userId'],
      );
    }).map((snap) {
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
    try {
      await _notifications(userId).doc(notificationId).update({'isRead': true});
    } catch (e, st) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'NotificationService.markAsRead failed',
        information: ['userId=$userId', 'notificationId=$notificationId'],
      );
      rethrow;
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot =
          await _notifications(userId).where('isRead', isEqualTo: false).get();

      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e, st) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'NotificationService.markAllAsRead failed',
        information: ['userId=$userId'],
      );
      rethrow;
    }
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _notifications(userId).doc(notificationId).delete();
    } catch (e, st) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'NotificationService.deleteNotification failed',
        information: ['userId=$userId', 'notificationId=$notificationId'],
      );
      rethrow;
    }
  }
}
