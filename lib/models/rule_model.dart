class RuleModel {
  final String id;
  final String text;
  final String severity;

  RuleModel({
    required this.id,
    required this.text,
    required this.severity,
  });

  factory RuleModel.fromJson(Map<String, dynamic> json) {
    return RuleModel(
      id: json['id'] as String,
      text: json['text'] as String,
      severity: json['severity'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'severity': severity,
    };
  }
}