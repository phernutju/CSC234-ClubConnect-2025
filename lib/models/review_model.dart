import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String raterId;
  final String communityId;
  final String communityName;
  final double score;
  final String comment;
  final Timestamp createdAt;

  const ReviewModel({
    required this.id,
    required this.raterId,
    required this.communityId,
    required this.communityName,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(String id, Map<String, dynamic> json) =>
      ReviewModel(
        id: id,
        raterId: (json['raterId'] as String? ?? '').trim(),
        communityId: (json['communityId'] as String? ?? '').trim(),
        communityName: (json['communityName'] as String? ?? '').trim(),
        score: json['score'] as double? ?? 0.0,
        comment: (json['comment'] as String? ?? '').trim(),
        createdAt: json['createdAt'] as Timestamp,
      );

  Map<String, dynamic> toJson() => {
        'raterId': raterId,
        'communityId': communityId,
        'communityName': communityName,
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
