import 'dart:typed_data';
import 'rule_model.dart';

class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final Uint8List? coverImage;
  final List<RuleModel> rules;
  final int memberCount;
  final String hostName;
  final double hostRating;
  final String coverImageUrl;

  const CommunityModel({
    this.id = '',
    required this.name,
    required this.description,
    required this.category,
    this.coverImage,
    this.rules = const [],
    this.memberCount = 1,
    this.hostName = '',
    this.hostRating = 5.0,
    this.coverImageUrl = '',
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json, String id) =>
      CommunityModel(
        id: id,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? '',
        memberCount: json['memberCount'] as int? ?? 0,
        hostName: json['hostName'] as String? ?? '',
        hostRating: (json['hostRating'] as num?)?.toDouble() ?? 5.0,
        coverImageUrl: json['coverImageUrl'] as String? ?? '',
        rules: (json['rules'] as List<dynamic>?)
                ?.map((r) => RuleModel.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'category': category,
        'memberCount': memberCount,
        'hostName': hostName,
        'hostRating': hostRating,
        'coverImageUrl': coverImageUrl,
        'rules': rules.map((r) => r.toJson()).toList(),
      };

  CommunityModel copyWith({
    String? name,
    String? description,
    String? category,
    Uint8List? coverImage,
    List<RuleModel>? rules,
    int? memberCount,
    String? hostName,
    double? hostRating,
  }) =>
      CommunityModel(
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        coverImage: coverImage ?? this.coverImage,
        rules: rules ?? this.rules,
        memberCount: memberCount ?? this.memberCount,
        hostName: hostName ?? this.hostName,
        hostRating: hostRating ?? this.hostRating,
      );
}
