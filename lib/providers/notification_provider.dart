import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  List<NotificationModel> notifications = [];
  int unreadCount = 0;
  bool isLoading = false;
  String? error;

  StreamSubscription<NotificationsResult>? _sub;

  NotificationProvider({NotificationService? service})
      : _service = service ?? NotificationService();

  void watchNotifications(String userId) {
    _sub?.cancel();
    _sub = _service.watchNotifications(userId).listen(
      (result) {
        notifications = result.notifications;
        unreadCount = result.unreadCount;
        error = null;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  void stopWatching() {
    _sub?.cancel();
    _sub = null;
    notifications = [];
    unreadCount = 0;
  }

  Future<void> markAsRead(String userId, String notificationId) =>
      _run(() => _service.markAsRead(userId, notificationId));

  Future<void> markAllAsRead(String userId) =>
      _run(() => _service.markAllAsRead(userId));

  Future<void> deleteNotification(String userId, String notificationId) =>
      _run(() => _service.deleteNotification(userId, notificationId));

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
