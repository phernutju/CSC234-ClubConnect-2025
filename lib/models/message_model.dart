import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String imageURL;
  final DateTime timestamp;
  final List<String> seenBy;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.imageURL,
    required this.timestamp,
    required this.seenBy,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String id) {
    return MessageModel(
      id: id,
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      imageURL: json['imageURL'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seenBy: List<String>.from(json['seenBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      'imageURL': imageURL,
      'timestamp': Timestamp.fromDate(timestamp),
      'seenBy': seenBy,
    };
  }
}