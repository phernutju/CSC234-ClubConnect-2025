import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String userId;
  final DateTime joinedAt;
  final String role;

  MemberModel({
    required this.userId,
    required this.joinedAt,
    required this.role,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json, String id) {
    return MemberModel(
      userId: id,
      joinedAt: (json['joinedAt'] as Timestamp).toDate(),
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'joinedAt': Timestamp.fromDate(joinedAt),
      'role': role,
    };
  }
}