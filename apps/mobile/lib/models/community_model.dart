import 'dart:typed_data';
import 'rule_model.dart';

/// In-memory representation of a community.
/// No persistence — data resets on app restart (no DB yet).
class CommunityModel {
  final String name;
  final String description;
  final String category;
  final Uint8List? coverImage;
  final List<RuleModel> rules;
  final int memberCount;
  final String hostName;
  final double hostRating;

  const CommunityModel({
    required this.name,
    required this.description,
    required this.category,
    this.coverImage,
    this.rules = const [],
    this.memberCount = 1,
    this.hostName = '',
    this.hostRating = 5.0,
  });

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
