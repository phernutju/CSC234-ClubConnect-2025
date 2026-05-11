class CategoryModel {
  final String id;
  final String name;

  const CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json, String id) =>
      CategoryModel(
        id: id,
        name: (json['name'] as String? ?? '').trim(),
      );
}
