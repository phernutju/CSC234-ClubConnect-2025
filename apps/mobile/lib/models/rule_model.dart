/// A single community rule with a title and optional description.
class RuleModel {
  final String title;
  final String description;

  const RuleModel({
    required this.title,
    this.description = '',
  });
}
