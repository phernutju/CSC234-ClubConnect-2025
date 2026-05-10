import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import '../services/user_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service;

  UserModel? profile;
  ReviewsResult? reviewsResult;

  // Isolated state for OtherProfileScreen — never touches [profile] or [reviewsResult].
  UserModel? viewedProfile;
  ReviewsResult? viewedReviewsResult;

  bool isLoading = false;
  String? error;

  // ── Local UI state (HEAD-branch screens) ─────────────────────────────────
  String _username = 'Username';
  String _bio = AppStrings.profileBio;
  Uint8List? _avatarBytes;
  Uint8List? _coverBytes;
  final Set<String> _selectedInterests = {};

  String get username => _username;
  String get bio => _bio;
  Uint8List? get avatarBytes => _avatarBytes;
  Uint8List? get coverBytes => _coverBytes;
  Set<String> get selectedInterests => Set.unmodifiable(_selectedInterests);

  void saveProfile({required String username, required String bio, Set<String>? interests}) {
    _username = username.isEmpty ? 'Username' : username;
    _bio = bio.isEmpty ? _bio : bio;
    if (interests != null) { _selectedInterests..clear()..addAll(interests); }
    UserService.updateProfile(username: _username, bio: _bio, interests: Set.unmodifiable(_selectedInterests));
    notifyListeners();
  }

  void saveInterests(Set<String> interests) {
    _selectedInterests..clear()..addAll(interests);
    UserService.updateProfile(username: _username, bio: _bio, interests: Set.unmodifiable(_selectedInterests));
    notifyListeners();
  }

  void updateAvatar(Uint8List bytes) {
    _avatarBytes = bytes;
    UserService.updateAvatar(bytes);
    notifyListeners();
  }

  void updateCover(Uint8List bytes) {
    _coverBytes = bytes;
    UserService.updateCover(bytes);
    notifyListeners();
  }

  void logout() {
    _username = 'Username';
    _bio = AppStrings.profileBio;
    _avatarBytes = null;
    _coverBytes = null;
    _selectedInterests.clear();
    notifyListeners();
  }

  ProfileProvider({ProfileService? service})
      : _service = service ?? ProfileService();

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> loadProfile(String userId) => _run(() async {
        profile = await _service.getUserProfile(userId);
        if (profile != null && _selectedInterests.isEmpty) {
          _selectedInterests
            ..clear()
            ..addAll(profile!.interests);
        }
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
        viewedReviewsResult = await _service.getReviews(targetUserId);
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
