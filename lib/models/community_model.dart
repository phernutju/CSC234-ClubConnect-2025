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

  factory CommunityModel.fromJson(Map<String, dynamic> json, String id) {
    // category may be stored as List<String> (Firestore) or plain String
    final rawCategory = json['category'];
    final category = rawCategory is List
        ? (rawCategory.isNotEmpty ? rawCategory.first as String : '')
        : (rawCategory as String? ?? '');

    // rule stored as '\n'-joined String; rules stored as List<Map>
    List<RuleModel> rules = [];
    if (json['rules'] is List) {
      rules = (json['rules'] as List<dynamic>)
          .map((r) => RuleModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } else if (json['rule'] is String && (json['rule'] as String).isNotEmpty) {
      rules = (json['rule'] as String)
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .map((t) => RuleModel(title: t.trim()))
          .toList();
    }

    return CommunityModel(
      id: id,
      name: json['communityName'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: category,
      memberCount: json['memberCount'] as int? ?? 0,
      hostName: json['hostName'] as String? ?? '',
      hostRating: (json['hostRating'] as num?)?.toDouble() ?? 5.0,
      coverImageUrl: json['coverImageURL'] as String? ?? json['coverImageUrl'] as String? ?? '',
      rules: rules,
    );
  }

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
    String? id,
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
        id: id ?? this.id,
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
