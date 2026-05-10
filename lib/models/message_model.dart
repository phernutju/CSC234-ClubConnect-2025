import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String imageURL;
  final DateTime timestamp;
  final List<String> seenBy;
  final String? replyToId;
  final String? replyToSenderName;
  final String? replyToText;
  final List<String> mentions;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.imageURL,
    required this.timestamp,
    required this.seenBy,
    this.replyToId,
    this.replyToSenderName,
    this.replyToText,
    this.mentions = const [],
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String id) {
    return MessageModel(
      id: id,
      senderId: (json['senderId'] as String? ?? '').trim(),
      text: (json['text'] as String? ?? '').trim(),
      imageURL: (json['imageURL'] as String? ?? '').trim(),
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seenBy: List<String>.from(json['seenBy'] ?? []),
      replyToId: json['replyToId'] as String?,
      replyToSenderName: json['replyToSenderName'] as String?,
      replyToText: json['replyToText'] as String?,
      mentions: List<String>.from(json['mentions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      'imageURL': imageURL,
      'timestamp': Timestamp.fromDate(timestamp),
      'seenBy': seenBy,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (replyToText != null) 'replyToText': replyToText,
      if (mentions.isNotEmpty) 'mentions': mentions,
    };
  }
}