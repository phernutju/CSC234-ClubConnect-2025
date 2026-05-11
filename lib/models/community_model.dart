import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rule_model.dart';
import '../models/category_model.dart';

enum RoomType { community, event }

class RoomModel {
  final String id;
  final String name;
  final String createdBy;
  final List<CategoryModel> tags;
  final List<RuleModel> rules;
  final RoomType type;
  final String? eventId;       // null if type is community
  final Timestamp? expiresAt;  // null if type is community
  final Timestamp createdAt;

  RoomModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.tags,
    required this.rules,
    required this.type,
    required this.createdAt,
    this.eventId,
    this.expiresAt,
  });

  /// Whether this room has expired (only relevant for event rooms)
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!.toDate());
  }

  /// Whether this room is permanent (community room)
  bool get isPermanent => type == RoomType.community;

  factory RoomModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RoomModel(
      id: doc.id,
      name: data['name'] ?? '',
      createdBy: data['createdBy'] ?? '',
      tags: (data['tags'] as List<dynamic>?)?.map((t) => CategoryModel.fromMap(t)).toList() ?? [],
      rules: (data['rules'] as List<dynamic>?)?.map((r) => RuleModel.fromMap(r)).toList() ?? [],
      type: data['type'] == 'event' ? RoomType.event : RoomType.community,
      eventId: data['eventId'] as String?,
      expiresAt: data['expiresAt'] as Timestamp?,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdBy': createdBy,
      'tags': tags,
      'rules': rules.map((r) => r.toMap()).toList(),
      'type': type == RoomType.event ? 'event' : 'community',
      'eventId': eventId,       // stored as null if community
      'expiresAt': expiresAt,   // stored as null if community
      'createdAt': createdAt,
    };
  }

  /// Convenience factory for creating a community room
  factory RoomModel.community({
    required String id,
    required String name,
    required String createdBy,
    required List<CategoryModel> tags,
    required List<RuleModel> rules,
  }) {
    return RoomModel(
      id: id,
      name: name,
      createdBy: createdBy,
      tags: tags,
      rules: rules,
      type: RoomType.community,
      createdAt: Timestamp.now(),
      eventId: null,
      expiresAt: null,
    );
  }

  /// Convenience factory for creating an event room
  factory RoomModel.forEvent({
    required String id,
    required String name,
    required String createdBy,
    required List<CategoryModel> tags,
    required String eventId,
    required DateTime expiresAt,
  }) {
    return RoomModel(
      id: id,
      name: name,
      createdBy: createdBy,
      tags: tags,
      rules: [RuleModel(id: "rule_1", text: 'This room is tied to an event. Please stay on topic.', severity: "high")],
      type: RoomType.event,
      createdAt: Timestamp.now(),
      eventId: eventId,
      expiresAt: Timestamp.fromDate(expiresAt),
    );
  }
}

/// CommunityModel represents a community in the app
class CommunityModel {
  final String id;
  final String communityName;
  final String description;
  final List<CategoryModel> tags;
  final String coverImageURL;
  final List<RuleModel> rules;
  final int memberCount;
  final String createdBy;
  final Timestamp createdAt;

  CommunityModel({
    required this.id,
    required this.communityName,
    required this.description,
    required this.tags,
    required this.coverImageURL,
    required this.rules,
    required this.memberCount,
    required this.createdBy,
    required this.createdAt,
  });

  factory CommunityModel.fromJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityModel(
      id: doc.id,
      communityName: data['communityName'] ?? '',
      description: data['description'] ?? '',
      tags: (data['tags'] as List<dynamic>?)?.map((t) => CategoryModel.fromMap(t)).toList() ?? [],
      coverImageURL: data['coverImageURL'] ?? '',
      rules: (data['rules'] as List<dynamic>?)?.map((r) => RuleModel.fromMap(r)).toList() ?? [],
      memberCount: data['memberCount'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'communityName': communityName,
      'description': description,
      'tags': tags.map((t) => t.toJson()).toList(),
      'coverImageURL': coverImageURL,
      'rules': rules.map((r) => r.toMap()).toList(),
      'memberCount': memberCount,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  CommunityModel copyWith({
    String? communityName,
    String? description,
    List<CategoryModel>? tags,
    String? coverImageURL,
    List<RuleModel>? rules,
    int? memberCount,
  }) =>
      CommunityModel(
        id: id,
        communityName: communityName ?? this.communityName,
        description: description ?? this.description,
        tags: tags ?? this.tags,
        coverImageURL: coverImageURL ?? this.coverImageURL,
        rules: rules ?? this.rules,
        memberCount: memberCount ?? this.memberCount,
        createdBy: createdBy,
        createdAt: createdAt,
      );
}
