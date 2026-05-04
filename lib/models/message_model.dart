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
  final String? replyToName;
  final String? replyToText;

  MessageModel({
    required this.id,
    required this.senderId,
    this.senderName = '',
    required this.text,
    this.imageURL = '',
    required this.timestamp,
    this.seenBy = const [],
    this.flagged = false,
    this.replyToName,
    this.replyToText,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      text: json['text'] ?? '',
      imageURL: json['imageURL'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seenBy: List<String>.from(json['seenBy'] ?? []),
      flagged: json['flagged'] ?? false,
      replyToName: json['replyToName'],
      replyToText: json['replyToText'],
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json, String id) =>
      MessageModel(
        id: id,
        senderId: json['senderId'] ?? '',
        senderName: json['senderName'] ?? '',
        text: json['text'] ?? '',
        imageURL: json['imageURL'] ?? '',
        timestamp:
            (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        seenBy: List<String>.from(json['seenBy'] ?? []),
        flagged: json['flagged'] ?? false,
        replyToName: json['replyToName'],
        replyToText: json['replyToText'],
      );

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'imageURL': imageURL,
        'timestamp': Timestamp.fromDate(timestamp),
        'seenBy': seenBy,
        'flagged': flagged,
        'replyToName': replyToName,
        'replyToText': replyToText,
      };
}