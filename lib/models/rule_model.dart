class RuleModel {
  final String title;
  final String description;

  const RuleModel({required this.title, this.description = ''});

  factory RuleModel.fromJson(Map<String, dynamic> json) => RuleModel(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'title': title, 'description': description};
}
