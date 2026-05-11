import 'package:cloud_firestore/cloud_firestore.dart';

class AttendeeModel {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime joinedAt;
  final String role; // 'host' | 'attendee'

  AttendeeModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.joinedAt,
    required this.role,
  });

  bool get isHost => role == 'host';

  factory AttendeeModel.fromJson(Map<String, dynamic> json, String id) {
    return AttendeeModel(
      userId: id,
      displayName: (json['displayName'] as String? ?? 'User').trim(),
      avatarUrl: json['avatarUrl'] as String?,
      joinedAt: (json['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: (json['role'] as String? ?? 'attendee').trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'role': role,
      };
}
