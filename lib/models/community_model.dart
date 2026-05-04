import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rule_model.dart';

class CommunityModel {
  final String id;
  final String communityId;
  final String communityName;
  final List<String> category;
  final String description;
  final String coverImageURL;
  final String createdById;
  final List<RuleModel> rules;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunityModel({
    required this.id,
    required this.communityId,
    required this.communityName,
    required this.category,
    required this.description,
    required this.coverImageURL,
    required this.createdById,
    required this.rules,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json, String id) {
    return CommunityModel(
      id: id,
      communityId: json['communityId'] as String? ?? id,
      communityName: json['communityName'] as String? ?? '',
      category: List<String>.from(json['category'] as List? ?? []),
      description: json['description'] as String? ?? '',
      coverImageURL: json['coverImageURL'] as String? ?? '',
      createdById: json['createdById'] as String? ?? '',
      rules: (json['rules'] as List<dynamic>? ?? [])
          .map((e) => RuleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      memberCount: json['memberCount'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'communityId': communityId,
      'communityName': communityName,
      'category': category,
      'description': description,
      'coverImageURL': coverImageURL,
      'rules': rules.map((r) => r.toJson()).toList(),
      'memberCount': memberCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CommunityModel copyWith({
    String? communityName,
    List<String>? category,
    String? description,
    String? coverImageURL,
    List<RuleModel>? rules,
    int? memberCount,
  }) =>
      CommunityModel(
        id: id,
        communityId: communityId,
        communityName: communityName ?? this.communityName,
        category: category ?? this.category,
        description: description ?? this.description,
        coverImageURL: coverImageURL ?? this.coverImageURL,
        createdById: createdById,
        rules: rules ?? this.rules,
        memberCount: memberCount ?? this.memberCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
