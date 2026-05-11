class RoomModel {
  final String roomId;
  final String name;
  final List<String> tags;
  final String creatorId;
  final String rules;
  final int memberCount;

  const RoomModel({
    required this.roomId,
    required this.name,
    required this.creatorId,
    this.tags = const [],
    this.rules = '',
    this.memberCount = 0,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        roomId: json['roomId'] as String,
        name: json['name'] as String,
        creatorId: json['creatorId'] as String,
        tags: List<String>.from(json['tags'] as List? ?? []),
        rules: json['rules'] as String? ?? '',
        memberCount: json['memberCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'name': name,
        'tags': tags,
        'creatorId': creatorId,
        'rules': rules,
        'memberCount': memberCount,
      };
}
