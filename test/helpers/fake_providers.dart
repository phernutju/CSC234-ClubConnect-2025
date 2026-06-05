import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:csc234_clubconnect/models/category_model.dart';
import 'package:csc234_clubconnect/models/community_model.dart';
import 'package:csc234_clubconnect/models/event_model.dart';
import 'package:csc234_clubconnect/models/member_model.dart';
import 'package:csc234_clubconnect/models/message_model.dart';
import 'package:csc234_clubconnect/models/rating_model.dart';
import 'package:csc234_clubconnect/models/report_model.dart';
import 'package:csc234_clubconnect/models/review_model.dart';
import 'package:csc234_clubconnect/models/rule_model.dart';
import 'package:csc234_clubconnect/models/user_model.dart';
import 'package:csc234_clubconnect/providers/auth_provider.dart';
import 'package:csc234_clubconnect/providers/category_provider.dart';
import 'package:csc234_clubconnect/providers/community_provider.dart';
import 'package:csc234_clubconnect/providers/event_provider.dart';
import 'package:csc234_clubconnect/providers/profile_provider.dart';
import 'package:csc234_clubconnect/providers/rating_provider.dart';
import 'package:csc234_clubconnect/providers/report_provider.dart';

// ─── Auth ─────────────────────────────────────────────────────────────────────

class FakeAuthProvider extends ChangeNotifier implements AppAuthProvider {
  @override
  User? user;
  @override
  String? role;
  @override
  bool isBanned = false;
  @override
  bool isMuted = false;
  @override
  DateTime? muteExpiresAt;
  @override
  String? banReason;
  @override
  DateTime? banExpiresAt;
  @override
  String? durationLabel;

  @override
  bool get isLoading => false;
  @override
  OtpState get otpState => OtpState.idle;
  @override
  String? get otpError => null;
  @override
  bool get canResend => false;
  @override
  bool get pendingGoogleRegistration => false;
  @override
  bool get pendingEmailRegistration => false;
  @override
  String? get googleDisplayName => null;
  @override
  String? get googleEmail => null;
  @override
  String? get cachedEmail => null;
  @override
  String? get cachedPassword => null;
  @override
  bool get biometricAvailable => false;
  @override
  bool get biometricEnrolled => false;

  @override
  void setEmailPassword(String email, String password) {}
  @override
  void setPhoneNumber(String phonenum) {}
  @override
  String formatPhoneNumber(String phone) => phone;
  @override
  void setExtraInfo(String photoURL, String displayName, String bio,
      {Uint8List? imageBytes}) {}
  @override
  void setInterests(List<String> tags) {}
  @override
  Future<void> createEmailAuthAccount(String email, String password) async {}
  @override
  Future<void> sendOtp() async {}
  @override
  Future<void> verifyOtp(String smsCode) async {}
  @override
  Future<void> signUp() async {}
  @override
  Future<void> signIn(
      {required String email, required String password}) async {}
  @override
  Future<User?> signInWithGoogle() async => null;
  @override
  Future<void> startGoogleRegistration() async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> initBiometric() async {}
  @override
  Future<bool> loginWithBiometric() async => false;
  @override
  void clearCachedCredentials() {}
  @override
  Future<bool> shouldOfferBiometricEnrollment() async => false;
  @override
  Future<bool> saveBiometricCredentials() async => false;
}

// ─── Community ────────────────────────────────────────────────────────────────

class FakeCommunityProvider extends ChangeNotifier
    implements CommunityProvider {
  @override
  List<CommunityModel> communities = [];
  @override
  List<CommunityModel> myCommunities = [];
  @override
  List<CommunityModel> trendingCommunities = [];
  @override
  List<CommunityModel> recommendedCommunities = [];
  @override
  CommunityModel? activeCommunity;
  @override
  List<MessageModel> messages = [];
  @override
  List<MemberModel> members = [];
  @override
  bool isLoading = false;
  @override
  bool isUploading = false;
  @override
  bool isTrendingLoading = false;
  @override
  bool isRecommendedLoading = false;
  @override
  String? error;
  @override
  String? trendingError;
  @override
  String? recommendedError;
  @override
  String? violationWarning;
  @override
  List<CommunityModel> discoverPage = [];
  @override
  int discoverTotalCount = 0;
  @override
  int discoverCurrentPage = 0;
  @override
  bool isDiscoverLoading = false;

  @override
  int get discoverTotalPages => 0;
  @override
  int get discoverKnownPages => 1;
  @override
  Set<String> get mutedCommunityNames => {};

  @override
  void clearError() {}
  @override
  bool isMuted(String communityId) => false;
  @override
  Stream<bool> hasUnreadStream(String communityId) => Stream.value(false);
  @override
  void toggleMute(String communityId) {}
  @override
  String displayNameOf(String uid) => '';
  @override
  String photoURLOf(String uid) => '';
  @override
  Future<String> resolveCommunityName(String communityId) async => '';
  @override
  Future<void> fetchDisplayName(String uid) async {}
  @override
  void loadMembers(String communityId) {}
  @override
  void loadCommunities() {}
  @override
  void loadFirst10Communities() {}
  @override
  void loadCommunitiesLimited({int limit = 20}) {}
  @override
  void loadCommunitiesByIds(List<String> communityIds) {}
  @override
  void loadCommunitiesByCategory(String category) {}
  @override
  void loadMyCommunities() {}
  @override
  Future<bool> checkIsMember(String communityId) async => false;
  @override
  Future<CommunityModel?> fetchCommunity(String communityId) async => null;
  @override
  void setActiveCommunity(CommunityModel community) {}
  @override
  void clearActiveCommunity() {}
  @override
  Future<void> editCommunity(
      String communityId, Map<String, dynamic> data) async {}
  @override
  Future<void> joinCommunity(String communityId) async {}
  @override
  Future<void> leaveCommunity(String communityId) async {}
  @override
  Future<void> deleteCommunity(String communityId) async {}
  @override
  Future<void> kickMember(String communityId, String userId) async {}
  @override
  Future<void> addCommunity({
    required String communityName,
    required List<CategoryModel> category,
    required String description,
    required List<RuleModel> rules,
    Uint8List? coverImageBytes,
  }) async {}
  @override
  Future<void> editMember(
      String communityId, String userId, String newRole) async {}
  @override
  Future<void> sendMessage(
    String communityId, {
    required String text,
    String imageURL = '',
    String? replyToId,
    String? replyToSenderName,
    String? replyToText,
    String? replyToSenderId,
    List<String> mentions = const [],
  }) async {}
  @override
  Future<void> sendImageMessage(String communityId, Uint8List bytes) async {}
  @override
  Future<void> markMessageSeen(String communityId, String messageId) async {}
  @override
  Future<void> markMessagesSeenBatch(
      String communityId, List<String> messageIds) async {}
  @override
  Future<void> deleteMessage(String communityId, String messageId) async {}
  @override
  void loadTrendingCommunities({int limit = 20}) {}
  @override
  Future<void> loadRecommendedCommunities(String userId) async {}
  @override
  Future<void> incrementReactionCount(String communityId) async {}
  @override
  Future<void> loadDiscoverFirstPage(
      {String? orderField, bool? descending}) async {}
  @override
  Future<void> goToDiscoverPage(int page) async {}
}

// ─── Event ────────────────────────────────────────────────────────────────────

class FakeEventProvider extends ChangeNotifier implements EventProvider {
  @override
  List<EventModel> events = [];
  @override
  List<MessageModel> eventMessages = [];
  @override
  List<EventModel> publishedEvents = [];
  @override
  bool isLoading = false;
  @override
  String? error;

  @override
  void reassemble() {}
  @override
  void loadPublishedEvents() {}
  @override
  void clearPublishedEvents() {}
  @override
  void loadEvents(String communityId) {}
  @override
  void clearEvents() {}
  @override
  String displayNameOf(String uid) => '';
  @override
  Future<void> fetchDisplayName(String uid) async {}
  @override
  void loadEventMessages(String communityId, String eventId) {}
  @override
  void clearEventMessages() {}
  @override
  Future<void> sendEventMessage(
    String communityId,
    String eventId, {
    required String text,
    String imageURL = '',
    String? replyToId,
    String? replyToSenderName,
    String? replyToText,
  }) async {}
  @override
  Future<void> sendEventImageMessage(
      String communityId, String eventId, Uint8List bytes) async {}
  @override
  Future<void> createEvent({
    required String communityId,
    required String title,
    required String description,
    required String location,
    required List<CategoryModel> tags,
    required Timestamp startDate,
    required Timestamp endDate,
    required String roomId,
    String? imageUrl,
    int? maxAttendees,
    required bool isPublished,
  }) async {}
  @override
  Future<void> joinEvent(String communityId, String eventId) async {}
  @override
  Future<void> leaveEvent(String communityId, String eventId) async {}
  @override
  Future<void> deleteEvent(String communityId, String eventId) async {}
  @override
  Future<void> deleteEventMessage(
      String communityId, String eventId, String messageId) async {}
}

// ─── Profile ──────────────────────────────────────────────────────────────────

class FakeProfileProvider extends ChangeNotifier implements ProfileProvider {
  @override
  UserModel? profile;
  @override
  ReviewsResult? reviewsResult;
  @override
  UserModel? viewedProfile;
  @override
  ReviewsResult? viewedReviewsResult;
  @override
  bool isLoading = false;
  @override
  String? error;
  @override
  List<String> categories = [];

  String _username = 'TestUser';
  String _bio = 'Test bio';

  @override
  String get username => _username;
  @override
  String get bio => _bio;
  @override
  Uint8List? get avatarBytes => null;
  @override
  Uint8List? get coverBytes => null;
  @override
  String? get coverBannerUrl => null;
  @override
  Set<String> get selectedInterests => {};

  @override
  void saveProfile(
      {required String username, required String bio, Set<String>? interests}) {
    _username = username;
    _bio = bio;
    notifyListeners();
  }

  @override
  Future<void> loadCategories() async {}
  @override
  void saveInterests(Set<String> interests) {}
  @override
  void updateAvatar(Uint8List bytes) {}
  @override
  Future<void> updateCover(Uint8List bytes) async {}
  @override
  void logout() {}
  @override
  Future<void> loadProfile(String userId) async {}
  @override
  Future<void> loadViewedProfile(String userId) async {}
  @override
  Future<void> updateProfile(String userId, Map<String, dynamic> data,
      {Uint8List? avatarBytes}) async {}
  @override
  Future<void> deleteProfile(String userId) async {}
  @override
  Future<void> loadReviews(String targetUserId) async {}
  @override
  Future<void> createReview(
    String targetUserId, {
    required String communityId,
    required double score,
    required String comment,
  }) async {}
  @override
  Future<void> deleteReview(String targetUserId, String reviewId) async {}
  @override
  Future<void> updateReview(
      String targetUserId, String reviewId, Map<String, dynamic> data) async {}
  @override
  Future<void> submitReport({
    required String targetId,
    required String reason,
    required String description,
  }) async {}
  @override
  Future<String?> fetchCommunityName(String communityId) async => null;
  @override
  Future<UserModel> fetchUserById(String userId) async => UserModel(
        uid: userId,
        displayName: 'Test',
        email: 'test@test.com',
        phoneNumber: '',
        photoURL: '',
        bio: '',
        interests: [],
        role: 'user',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        mutedCommunities: [],
      );
  @override
  Future<ReviewsResult> fetchReviewsForUser(String userId) async =>
      const ReviewsResult(reviews: [], averageScore: 0);
}

// ─── Report ───────────────────────────────────────────────────────────────────

class FakeReportProvider extends ChangeNotifier implements ReportProvider {
  @override
  List<ReportModel> reports = [];
  @override
  ReportState state = ReportState.idle;
  @override
  String? error;

  @override
  Stream<List<ReportModel>> get pendingReportsStream => Stream.value([]);

  @override
  void resetState() {}
  @override
  Future<void> submitReport(ReportModel report) async {}
  @override
  Future<void> loadReportsByCommunity(String communityId) async {}
  @override
  Future<void> updateReportStatus(String reportId, ReportStatus status) async {}
}

// ─── Category ─────────────────────────────────────────────────────────────────

class FakeCategoryProvider extends ChangeNotifier implements CategoryProvider {
  @override
  bool isLoading = false;
  @override
  String? error;

  @override
  List<CategoryModel> get approvedCategories => [];

  @override
  Future<List<CategoryModel>> getDefaultCategories() async => [];
  @override
  Future<void> createUserCategory(String name, String createdBy) async {}
  @override
  Future<void> incrementUsageCount(String categoryId) async {}
}

// ─── Rating ───────────────────────────────────────────────────────────────────

class FakeRatingProvider extends ChangeNotifier implements RatingProvider {
  final List<RatingModel> _ratings = [];

  @override
  List<RatingModel> get ratings => List.unmodifiable(_ratings);

  @override
  void addRating(RatingModel rating) {
    _ratings.add(rating);
    notifyListeners();
  }
}
