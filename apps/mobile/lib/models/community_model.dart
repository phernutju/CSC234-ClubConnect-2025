import 'dart:typed_data';

/// In-memory representation of a community created by the user.
/// No persistence — data resets on app restart (no DB yet).
class CommunityModel {
  final String name;
  final String description;
  final String category;
  final Uint8List? coverImage;
  final List<String> rules;

  const CommunityModel({
    required this.name,
    required this.description,
    required this.category,
    this.coverImage,
    required this.rules,
  });
}
