import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? createdBy;  // null = system/default
  final bool isDefault;
  final bool isApproved;
  final int usageCount;
  final Timestamp createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.isDefault,
    required this.isApproved,
    required this.usageCount,
    required this.createdAt,
    this.createdBy,
  });

  factory CategoryModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel.fromJson({...data, 'id': doc.id});
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel.fromJson(map);
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      createdBy: json['createdBy'] as String?,
      isDefault: json['isDefault'] ?? false,
      isApproved: json['isApproved'] ?? false,
      usageCount: json['usageCount'] ?? 0,
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'createdBy': createdBy,
    'isDefault': isDefault,
    'isApproved': isApproved,
    'usageCount': usageCount,
    'createdAt': createdAt,
  };

  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id');
    return map;
  }

  // Helper to generate slug from name
  static String toSlug(String name) {
    return name.toLowerCase().trim().replaceAll(' ', '-');
  }
}
