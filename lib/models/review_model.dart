import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String raterId;
  final String communityId;
  final String score;
  final String comment;
  final Timestamp createdAt;

  const ReviewModel({
    required this.id,
    required this.raterId,
    required this.communityId,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(String id, Map<String, dynamic> json) =>
      ReviewModel(
        id: id,
        raterId: json['raterId'] as String,
        communityId: json['communityId'] as String? ?? '',
        score: json['score'] as String,
        comment: json['comment'] as String,
        createdAt: json['createdAt'] as Timestamp,
      );

  Map<String, dynamic> toJson() => {
        'raterId': raterId,
        'communityId': communityId,
        'score': score,
        'comment': comment,
        'createdAt': createdAt,
      };
}

class ReviewsResult {
  final List<ReviewModel> reviews;
  final double averageScore;

  const ReviewsResult({required this.reviews, required this.averageScore});
}
