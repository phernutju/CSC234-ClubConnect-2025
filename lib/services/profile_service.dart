import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class ProfileService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final StorageService _storage;
  final NotificationService _notifications;

  static const _allowedProfileFields = {
    'displayName',
    'bio',
    'interests',
    'phoneNumber',
    'photoURL',
  };

  ProfileService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    StorageService? storage,
    NotificationService? notifications,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? StorageService(),
        _notifications = notifications ?? NotificationService();

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _communities =>
      _db.collection('communities');

  CollectionReference<Map<String, dynamic>> _ratings(String userId) =>
      _users.doc(userId).collection('rating');

  // ── Profile ────────────────────────────────────────────────────────────────

  Future<UserModel> getUserProfile(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) throw Exception('User not found: $userId');
    return UserModel.fromJson(doc.data()!);
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data, {
    Uint8List? avatarBytes,
  }) async {
    final current = _requireAuth();
    if (current.uid != userId) {
      throw Exception('You can only modify your own profile');
    }

    final updates = Map<String, dynamic>.from(data)
      ..removeWhere((k, _) => !_allowedProfileFields.contains(k));

    if (avatarBytes != null) {
      updates['photoURL'] = await _storage.uploadUserAvatar(avatarBytes, userId);
    }

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

  /// Writes only the interests field for the currently signed-in user.
  /// Used by ProfileProvider.saveProfile() to persist category selections.
  Future<void> saveCurrentUserInterests(List<String> interests) async {
    final user = _requireAuth();
    await _users.doc(user.uid).update({
      'interests': interests,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteUserProfile(String userId) async {
    final current = _requireAuth();
    if (current.uid != userId) await _requireAdmin(current.uid);
    await _users.doc(userId).delete();
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  Future<ReviewModel> createReview(
    String targetUserId, {
    required String communityId,
    required double score,
    required String comment,
  }) async {
    final current = _requireAuth();
    if (current.uid == targetUserId) {
      throw ArgumentError('You cannot review yourself');
    }
    _validateScore(score);

    final communityName = await getCommunityName(communityId) ?? '';
    final data = {
      'raterId': current.uid,
      'communityId': communityId,
      'communityName': communityName,
      'score': score,
      'comment': comment.trim(),
      'createdAt': Timestamp.now(),
    };

    final ref = await _ratings(targetUserId).add(data);

    await _notifications.createNotification(targetUserId, {
      'communityId': communityId,
      'mentionedBy': current.uid,
      'title': current.displayName ?? 'Someone',
      'description':
          '${current.displayName ?? 'Someone'} rated you ${score.toInt()} stars in $communityName',
      'type': 'rating',
    });

    return ReviewModel.fromJson(ref.id, data);
  }

  Future<ReviewsResult> getReviews(String targetUserId) async {
    final snapshot = await _ratings(targetUserId).get();

    final reviews = snapshot.docs
        .map((doc) => ReviewModel.fromJson(doc.id, doc.data()))
        .toList();
    final average = reviews.isEmpty
        ? 5.0
        : reviews.fold<double>(0, (acc, r) => acc + r.score) / reviews.length;
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
      final score = (data['score'] as num).toDouble();
      _validateScore(score);
      updates['score'] = score;
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

  // ── Community ──────────────────────────────────────────────────────────────

  /// Fetch just the community name from a community ID.
  Future<String?> getCommunityName(String communityId) async {
    if (communityId.isEmpty) return null;
    final doc = await _communities.doc(communityId).get();
    if (!doc.exists) return null;
    return doc.data()?['communityName'] as String?;
  }

  // ── Reports ────────────────────────────────────────────────────────────────

  Future<void> submitReport({
    required String targetId,
    required String reason,
    required String description,
  }) async {
    final current = _requireAuth();
    await _db.collection('reports').add({
      'reporterId': current.uid,
      'targetId': targetId,
      'reason': reason,
      'description': description.trim(),
      'createdAt': Timestamp.now(),
    });
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

  void _validateScore(double score) {
    if (score < 1.0 || score > 5.0) {
      throw ArgumentError('score must be between 1.0 and 5.0, got $score');
    }
  }
}
