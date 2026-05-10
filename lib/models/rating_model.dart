/// One submitted star rating with an optional comment.
class RatingModel {
  final String ratedUsername;
  final String communityName;
  final int stars; // 1–5
  final String comment;

  /// When the rating was submitted — used for relative-time display.
  final DateTime submittedAt;

  RatingModel({
    required this.ratedUsername,
    required this.communityName,
    required this.stars,
    required this.comment,
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();
}
