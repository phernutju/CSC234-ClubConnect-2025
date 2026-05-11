import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String imageURL;
  final DateTime timestamp;
  final List<String> seenBy;
  final bool flagged;
  final String? replyToId;
  final String? replyToSenderName;
  final String? replyToText;
  final bool isSystem;
  final List<String> mentions;

  MessageModel({
    required this.id,
    required this.senderId,
    this.senderName = '',
    required this.text,
    this.imageURL = '',
    required this.timestamp,
    this.seenBy = const [],
    this.flagged = false,
    this.replyToId,
    this.replyToSenderName,
    this.replyToText,
    this.isSystem = false,
    this.mentions = const [],
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    final senderId = (json['senderId'] as String? ?? '').trim();
    return MessageModel(
      id: doc.id,
      senderId: senderId,
      senderName: json['senderName'] ?? '',
      text: (json['text'] as String? ?? '').trim(),
      imageURL: (json['imageURL'] as String? ?? '').trim(),
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seenBy: List<String>.from(json['seenBy'] ?? []),
      flagged: json['flagged'] ?? false,
      replyToId: json['replyToId'] as String?,
      replyToSenderName: json['replyToSenderName'] as String?,
      replyToText: json['replyToText'] as String?,
      isSystem: (json['isSystem'] as bool? ?? false) || senderId == 'system',
      mentions: List<String>.from(json['mentions'] ?? []),
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json, String id) =>
      MessageModel(
        id: id,
        senderId: (json['senderId'] as String? ?? '').trim(),
        senderName: json['senderName'] as String? ?? '',
        text: (json['text'] as String? ?? '').trim(),
        imageURL: (json['imageURL'] as String? ?? '').trim(),
        timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        seenBy: List<String>.from(json['seenBy'] ?? []),
        flagged: json['flagged'] ?? false,
        replyToId: json['replyToId'] as String?,
        replyToSenderName: json['replyToSenderName'] as String?,
        replyToText: json['replyToText'] as String?,
      );

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'imageURL': imageURL,
      'timestamp': Timestamp.fromDate(timestamp),
      'seenBy': seenBy,
      'flagged': flagged,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (replyToText != null) 'replyToText': replyToText,
      if (mentions.isNotEmpty) 'mentions': mentions,
    };
  }
}
