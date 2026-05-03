import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';

class ProfileService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _allowedProfileFields = {
    'displayName',
    'bio',
    'interests',
    'phoneNumber',
    'photoURL',
  };

  ProfileService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> _ratings(String userId) =>
      _users.doc(userId).collection('rating');

  // ── Profile (3.3) ──────────────────────────────────────────────────────────

  Future<UserModel> getUserProfile(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) throw Exception('User not found: $userId');
    return UserModel.fromJson(doc.data()!);
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final current = _requireAuth();
    if (current.uid != userId) {
      throw Exception('You can only modify your own profile');
    }

    final updates = Map<String, dynamic>.from(data)
      ..removeWhere((k, _) => !_allowedProfileFields.contains(k));
    if (updates.isEmpty) throw ArgumentError('No updatable fields provided');

    if (updates.containsKey('displayName')) {
      final name = updates['displayName'];
      if (name is! String || name.trim().isEmpty) {
        throw ArgumentError('displayName must not be empty');
      }
      updates['displayName'] = name.trim();
    }

    if (updates.containsKey('interests')) {
      final interests = updates['interests'];
      if (interests is! List || interests.any((e) => e is! String)) {
        throw ArgumentError('interests must be a List<String>');
      }
    }

    updates['updatedAt'] = Timestamp.now();
    await _users.doc(userId).update(updates);
  }

  Future<void> deleteUserProfile(String userId) async {
    final current = _requireAuth();
    if (current.uid != userId) await _requireAdmin(current.uid);
    await _users.doc(userId).delete();
  }

  // ── Reviews (3.5) ──────────────────────────────────────────────────────────

  Future<ReviewModel> createReview(
    String targetUserId, {
    required String communityId,
    required String score,
    required String comment,
  }) async {
    final current = _requireAuth();
    if (current.uid == targetUserId) {
      throw ArgumentError('You cannot review yourself');
    }
    _validateScore(score);
    if (comment.trim().isEmpty) throw ArgumentError('comment must not be empty');

    final data = {
      'raterId': current.uid,
      'communityId': communityId,
      'score': score,
      'comment': comment.trim(),
      'createdAt': Timestamp.now(),
    };

    final ref = await _ratings(targetUserId).add(data);
    return ReviewModel.fromJson(ref.id, data);
  }

  Future<ReviewsResult> getReviews(String targetUserId) async {
    final snapshot = await _ratings(targetUserId).get();
    final reviews = snapshot.docs
        .map((doc) => ReviewModel.fromJson(doc.id, doc.data()))
        .toList();
    final average = reviews.isEmpty
        ? 0.0
        : reviews.fold<int>(0, (acc, r) => acc + int.parse(r.score)) /
            reviews.length;
    return ReviewsResult(reviews: reviews, averageScore: average);
  }

  Future<void> updateReview(
    String targetUserId,
    String reviewId,
    Map<String, dynamic> data,
  ) async {
    final current = _requireAuth();
    final doc = await _ratings(targetUserId).doc(reviewId).get();
    if (!doc.exists) throw Exception('Review not found: $reviewId');

    final review = ReviewModel.fromJson(doc.id, doc.data()!);
    if (review.raterId != current.uid) {
      throw Exception('Only the original reviewer can edit this review');
    }

    final updates = <String, dynamic>{};
    if (data.containsKey('score')) {
      _validateScore(data['score'] as String);
      updates['score'] = data['score'];
    }
    if (data.containsKey('comment')) {
      final comment = data['comment'] as String;
      if (comment.trim().isEmpty) {
        throw ArgumentError('comment must not be empty');
      }
      updates['comment'] = comment.trim();
    }
    if (updates.isEmpty) throw ArgumentError('No updatable review fields provided');

    await _ratings(targetUserId).doc(reviewId).update(updates);
  }

  Future<void> deleteReview(String targetUserId, String reviewId) async {
    final current = _requireAuth();
    final doc = await _ratings(targetUserId).doc(reviewId).get();
    if (!doc.exists) throw Exception('Review not found: $reviewId');

    final review = ReviewModel.fromJson(doc.id, doc.data()!);
    if (review.raterId != current.uid) await _requireAdmin(current.uid);
    await _ratings(targetUserId).doc(reviewId).delete();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  User _requireAuth() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return user;
  }

  Future<void> _requireAdmin(String uid) async {
    final doc = await _users.doc(uid).get();
    if (doc.data()?['role'] != 'admin') throw Exception('Permission denied');
  }

  void _validateScore(String score) {
    if (!{'1', '2', '3', '4', '5'}.contains(score)) {
      throw ArgumentError('score must be "1"–"5", got "$score"');
    }
  }
}
