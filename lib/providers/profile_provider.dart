import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service;

  UserModel? profile;
  ReviewsResult? reviewsResult;

  // Isolated state for OtherProfileScreen — never touches [profile] or [reviewsResult].
  UserModel? viewedProfile;
  ReviewsResult? viewedReviewsResult;

  bool isLoading = false;
  String? error;

  ProfileProvider({ProfileService? service})
      : _service = service ?? ProfileService();

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> loadProfile(String userId) => _run(() async {
        profile = await _service.getUserProfile(userId);
      });

  Future<void> loadViewedProfile(String userId) => _run(() async {
        viewedProfile = null;
        viewedReviewsResult = null;
        viewedProfile = await _service.getUserProfile(userId);
        viewedReviewsResult = await _service.getReviews(userId);
      });

  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> data, {
    Uint8List? avatarBytes,
  }) =>
      _run(() async {
        await _service.updateUserProfile(userId, data, avatarBytes: avatarBytes);
        profile = await _service.getUserProfile(userId);
      });

  Future<void> deleteProfile(String userId) => _run(() async {
        await _service.deleteUserProfile(userId);
        profile = null;
      });

  // ── Reviews ───────────────────────────────────────────────────────────────

  Future<void> loadReviews(String targetUserId) => _run(() async {
        reviewsResult = await _service.getReviews(targetUserId);
      });

  Future<void> createReview(
    String targetUserId, {
    required String communityId,
    required double score,
    required String comment,
  }) =>
      _run(() async {
        await _service.createReview(
          targetUserId,
          communityId: communityId,
          score: score,
          comment: comment,
        );
        reviewsResult = await _service.getReviews(targetUserId);
      });

  Future<void> updateReview(
    String targetUserId,
    String reviewId,
    Map<String, dynamic> data,
  ) =>
      _run(() async {
        await _service.updateReview(targetUserId, reviewId, data);
        reviewsResult = await _service.getReviews(targetUserId);
      });

  Future<void> deleteReview(String targetUserId, String reviewId) =>
      _run(() async {
        await _service.deleteReview(targetUserId, reviewId);
        reviewsResult = await _service.getReviews(targetUserId);
      });

  // ── Reports ───────────────────────────────────────────────────────────────

  Future<void> submitReport({
    required String targetId,
    required String reason,
    required String description,
  }) =>
      _run(() => _service.submitReport(
            targetId: targetId,
            reason: reason,
            description: description,
          ));

  // ── Community ──────────────────────────────────────────────────────────────

  Future<String?> fetchCommunityName(String communityId) =>
      _service.getCommunityName(communityId);

  /// Fetch any user's profile without mutating shared [profile] state.
  Future<UserModel> fetchUserById(String userId) =>
      _service.getUserProfile(userId);

  /// Fetch reviews + average for any user without mutating shared [reviewsResult].
  Future<ReviewsResult> fetchReviewsForUser(String userId) =>
      _service.getReviews(userId);

  // ── Helper ────────────────────────────────────────────────────────────────

  Future<void> _run(Future<void> Function() fn) async {
  isLoading = true;
  notifyListeners();

  try {
    await fn();
  } catch (e, _) {
    rethrow;
  } finally {
    isLoading = false;
    notifyListeners();
  }
}
}
