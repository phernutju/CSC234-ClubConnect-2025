import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String msgId;
  final String roomId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool flagged;

  const MessageModel({
    required this.msgId,
    required this.roomId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.flagged = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        msgId: json['msgId'] as String,
        roomId: json['roomId'] as String,
        senderId: json['senderId'] as String,
        text: json['text'] as String,
        timestamp: (json['timestamp'] as Timestamp).toDate(),
        flagged: json['flagged'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'msgId': msgId,
        'roomId': roomId,
        'senderId': senderId,
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
        'flagged': flagged,
      };
}
