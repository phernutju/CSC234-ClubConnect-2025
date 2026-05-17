import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String communityId;
  final Timestamp createdAt;
  final String description;
  final bool isRead;
  final String mentionedBy;
  final String title;
  final String type;
  final String? chatRoomId;
  final String? messageId;

  const NotificationModel({
    required this.id,
    required this.communityId,
    required this.createdAt,
    required this.description,
    required this.isRead,
    required this.mentionedBy,
    required this.title,
    required this.type,
    this.chatRoomId,
    this.messageId,
  });

  factory NotificationModel.fromJson(String id, Map<String, dynamic> json) {
    String? optTrimmed(dynamic v) {
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    return NotificationModel(
      id: id,
      communityId: (json['communityId'] as String? ?? '').trim(),
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
      description: (json['description'] as String? ?? '').trim(),
      isRead: json['isRead'] as bool? ?? false,
      mentionedBy: (json['mentionedBy'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? '').trim(),
      chatRoomId: optTrimmed(json['chatRoomId']),
      messageId: optTrimmed(json['messageId']),
    );
  }

  Map<String, dynamic> toJson() => {
        'communityId': communityId,
        'createdAt': createdAt,
        'description': description,
        'isRead': isRead,
        'mentionedBy': mentionedBy,
        'title': title,
        'type': type,
        if (chatRoomId != null) 'chatRoomId': chatRoomId,
        if (messageId != null) 'messageId': messageId,
      };
}

class NotificationsResult {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationsResult({
    required this.notifications,
    required this.unreadCount,
  });
}
