import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityModel {
  final String id;

  final String communityId;
  final String communityName;
  final List<String> category;
  final String description;
  final String coverImageURL;
  final String rule;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommunityModel({
    required this.id,
    required this.communityId,
    required this.communityName,
    required this.category,
    required this.description,
    required this.coverImageURL,
    required this.rule,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 🔁 Firestore → Dart
  factory CommunityModel.fromJson(Map<String, dynamic> json, String id) {
    return CommunityModel(
      id: id,
      communityId: json['communityId'] ?? '',
      communityName: json['communityName'] ?? '',
      category: List<String>.from(json['category'] ?? []),
      description: json['description'] ?? '',
      coverImageURL: json['coverImageURL'] ?? '',
      rule: json['rule'] ?? '',
      memberCount: json['memberCount'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// 🔁 Dart → Firestore
  Map<String, dynamic> toJson() {
    return {
      'communityId': communityId,
      'communityName': communityName,
      'category': category,
      'description': description,
      'coverImageURL': coverImageURL,
      'rule': rule,
      'memberCount': memberCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}