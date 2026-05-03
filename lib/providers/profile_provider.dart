import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service;

  UserModel? profile;
  ReviewsResult? reviewsResult;
  bool isLoading = false;
  String? error;

  ProfileProvider({ProfileService? service})
      : _service = service ?? ProfileService();

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> loadProfile(String userId) => _run(() async {
        profile = await _service.getUserProfile(userId);
      });

  Future<void> updateProfile(String userId, Map<String, dynamic> data) =>
      _run(() async {
        await _service.updateUserProfile(userId, data);
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
    required String score,
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

  // ── Helper ────────────────────────────────────────────────────────────────

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
