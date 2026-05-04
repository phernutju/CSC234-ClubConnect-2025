class ReviewModel {
  final String reviewId;
  final String authorId;
  final String targetId;
  final double rating;
  final String body;

  const ReviewModel({
    required this.reviewId,
    required this.authorId,
    required this.targetId,
    required this.rating,
    this.body = '',
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        reviewId: json['reviewId'] as String,
        authorId: json['authorId'] as String,
        targetId: json['targetId'] as String,
        rating: (json['rating'] as num).toDouble(),
        body: json['body'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'reviewId': reviewId,
        'authorId': authorId,
        'targetId': targetId,
        'rating': rating,
        'body': body,
      };
}
