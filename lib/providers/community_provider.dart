import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../models/category_model.dart';
import '../models/community_model.dart';
import '../models/member_model.dart';
import '../models/message_model.dart';
import '../models/rule_model.dart';
import '../services/community_service.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityService _service;
  final Set<String> _mutedCommunities = {};
  final Map<String, String> _nameCache = {};
  final Map<String, String> _photoCache = {};
  final Map<String, String> _communityNameByIdCache = {};
  List<CommunityModel> communities = [];
  List<CommunityModel> myCommunities = [];
  List<CommunityModel> trendingCommunities = [];
  List<CommunityModel> recommendedCommunities = [];
  CommunityModel? activeCommunity;
  List<MessageModel> messages = [];
  List<MemberModel> members = [];
  bool isLoading = false;
  bool isUploading = false;
  bool isTrendingLoading = false;
  bool isRecommendedLoading = false;
  String? error;
  String? trendingError;
  String? recommendedError;
  String? violationWarning;

  void clearError() {
    error = null;
    notifyListeners();
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<CommunityModel>>? _communitiesSub;
  StreamSubscription<List<CommunityModel>>? _myCommunitiesSub;
  StreamSubscription<List<CommunityModel>>? _trendingSub;
  StreamSubscription<List<MessageModel>>? _messagesSub;
  StreamSubscription<List<MemberModel>>? _membersSub;

  bool _pendingNotify = false;

  void _safeNotify() {
    if (_pendingNotify || !hasListeners) return;
    _pendingNotify = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pendingNotify = false;
      if (hasListeners) notifyListeners();
    });
  }

  Set<String> get mutedCommunityNames => Set.unmodifiable(_mutedCommunities);

  bool isMuted(String communityId) => _mutedCommunities.contains(communityId);

  /// Real-time unread indicator for a single community.
  /// Returns a stream that emits true when there are messages the current user hasn't seen.
  Stream<bool> hasUnreadStream(String communityId) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return Stream.value(false);
    return _service.streamHasUnread(communityId, uid);
  }

  void toggleMute(String communityId) {
    if (_mutedCommunities.contains(communityId)) {
      _mutedCommunities.remove(communityId);
    } else {
      _mutedCommunities.add(communityId);
    }
    notifyListeners();
  }

  /// Returns the cached display name for [uid], or empty string if not yet fetched.
  String displayNameOf(String uid) => _nameCache[uid] ?? '';

  /// Returns the cached photo URL for [uid], or empty string if not yet fetched.
  String photoURLOf(String uid) => _photoCache[uid] ?? '';

  /// Returns the community name for [communityId]. Fetches from Firestore if not cached.
  /// Falls back to 'Unknown community' if the community no longer exists.
  Future<String> resolveCommunityName(String communityId) async {
    if (_communityNameByIdCache.containsKey(communityId)) {
      return _communityNameByIdCache[communityId]!;
    }
    debugPrint('[Comments] looking up communityId: $communityId');
    try {
      final community = await _service.getCommunityDebug(communityId);
      final name = community?.communityName ?? 'Unknown community';
      _communityNameByIdCache[communityId] = name;
      return name;
    } catch (e) {
      debugPrint('[Comments] lookup threw: $e');
      _communityNameByIdCache[communityId] = 'Unknown community';
      return 'Unknown community';
    }
  }

  /// Fetches and caches displayName + photoURL for [uid] in one Firestore read.
  /// No-ops if already cached. Notifies listeners when data arrives.
  Future<void> fetchDisplayName(String uid) async {
    if (_nameCache.containsKey(uid)) return;
    _nameCache[uid] = '';
    _photoCache[uid] = '';
    try {
      final info = await _service.getUserInfo(uid);
      _nameCache[uid] = info.displayName;
      _photoCache[uid] = info.photoURL;
    } catch (_) {
      _nameCache[uid] = '';
    }
    _safeNotify();
  }

  /// Subscribes to the member list for [communityId] and auto-fetches
  /// display names + photos as members arrive. Safe to call from UI.
  void loadMembers(String communityId) {
    _membersSub?.cancel();
    _membersSub = _service.getMembers(communityId).listen(
      (list) {
        members = list;
        for (final m in list) {
          fetchDisplayName(m.userId);
        }
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  void _listenToCommunities(Stream<List<CommunityModel>> stream) {
    _communitiesSub?.cancel();
    _communitiesSub = stream.listen(
      (list) {
        communities = list;
        _safeNotify();
      },
      onError: (e) {
        error = e.toString();
        _safeNotify();
      },
    );
  }

  void _listenToMyCommunities(Stream<List<CommunityModel>> stream) {
    _myCommunitiesSub?.cancel();
    _myCommunitiesSub = stream.listen(
      (list) {
        myCommunities = list;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  // ── Discover pagination ────────────────────────────────────────────────────
  List<CommunityModel> discoverPage = [];
  int discoverTotalCount = 0;
  int discoverCurrentPage = 0;
  bool isDiscoverLoading = false;
  final List<DocumentSnapshot<Map<String, dynamic>>?> _discoverCursors = [null];
  String _discoverOrderField = 'createdAt';
  bool _discoverDescending = true;

  int get discoverTotalPages =>
      discoverTotalCount <= 0 ? 0 : ((discoverTotalCount + 9) ~/ 10);

  /// Number of pages for which a start-cursor is cached (i.e. navigable).
  int get discoverKnownPages => _discoverCursors.length;

  CommunityProvider({CommunityService? service})
      : _service = service ?? CommunityService() {
    // Only subscribe to Firestore after Firebase Auth confirms a valid session.
    // authStateChanges() fires asynchronously, so currentUser may be null at
    // construction time even when a session exists — never query before this fires.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _listenToCommunities(_service.getCommunities());
      } else {
        _communitiesSub?.cancel();
        _myCommunitiesSub?.cancel();
        _messagesSub?.cancel();
        _membersSub?.cancel();
        communities = [];
        myCommunities = [];
        activeCommunity = null;
        messages = [];
        members = [];
        notifyListeners();
      }
    });
  }

  void loadCommunities() {
    _listenToCommunities(_service.getCommunities());
  }

  void loadFirst10Communities() {
    _listenToCommunities(_service.getFirst10Communities());
  }

  void loadCommunitiesLimited({int limit = 20}) {
    _listenToCommunities(_service.getCommunitiesLimited(limit: limit));
  }

  void loadCommunitiesByIds(List<String> communityIds) {
    _listenToCommunities(_service.getCommunitiesByIds(communityIds));
  }

  void loadCommunitiesByCategory(String category) {
    _listenToCommunities(_service.getCommunitiesByCategory(category));
  }

  void loadMyCommunities() {
    _listenToMyCommunities(_service.getMyCommunities());
  }

  Future<bool> checkIsMember(String communityId) =>
      _service.checkIsMember(communityId);

  Future<CommunityModel?> fetchCommunity(String communityId) {
    return _service.getCommunity(communityId);
  }

  // ── Active community ───────────────────────────────────────────────────────

  void setActiveCommunity(CommunityModel community) {
    activeCommunity = community;

    _messagesSub?.cancel();
    _membersSub?.cancel();

    _messagesSub = _service.getMessages(community.id).listen(
      (list) {
        messages = list;
        _safeNotify();
      },
      onError: (e) {
        error = e.toString();
        _safeNotify();
      },
    );

    _membersSub = _service.getMembers(community.id).listen(
      (list) {
        members = list;
        _safeNotify();
      },
      onError: (e) {
        error = e.toString();
        _safeNotify();
      },
    );

    _safeNotify();
  }

  void clearActiveCommunity() {
    activeCommunity = null;
    messages = [];
    members = [];
    _messagesSub?.cancel();
    _membersSub?.cancel();
    _safeNotify();
  }

  // ── Community actions ──────────────────────────────────────────────────────

  Future<void> editCommunity(
    String communityId,
    Map<String, dynamic> data,
  ) =>
      _run(() => _service.editCommunity(communityId, data));

  Future<void> joinCommunity(String communityId) =>
      _run(() => _service.joinCommunity(communityId));

  Future<void> leaveCommunity(String communityId) => _run(() async {
        await _service.leaveCommunity(communityId);
        if (activeCommunity?.id == communityId) clearActiveCommunity();
      });

  Future<void> deleteCommunity(String communityId) => _run(() async {
        await _service.deleteCommunity(communityId);
        // Clear active community state so the UI doesn't reference a deleted doc.
        if (activeCommunity?.id == communityId) clearActiveCommunity();
      });

  Future<void> kickMember(String communityId, String userId) =>
      _run(() => _service.kickMember(communityId, userId));

  Future<void> addCommunity({
    required String communityName,
    required List<CategoryModel> category,
    required String description,
    required List<RuleModel> rules,
    Uint8List? coverImageBytes,
  }) =>
      _run(() => _service.createCommunity(
            communityName: communityName,
            category: category,
            description: description,
            rules: rules,
            coverImageBytes: coverImageBytes,
          ));

  // ── Member actions ─────────────────────────────────────────────────────────

  Future<void> editMember(
    String communityId,
    String userId,
    String newRole,
  ) =>
      _run(() => _service.editMember(communityId, userId, newRole));

  // ── Message actions ────────────────────────────────────────────────────────

  Future<void> sendMessage(
    String communityId, {
    required String text,
    String imageURL = '',
    String? replyToId,
    String? replyToSenderName,
    String? replyToText,
    String? replyToSenderId,
    List<String> mentions = const [],
  }) async {
    if (communityId.isEmpty) {
      error = 'Cannot send: community not loaded';
      _safeNotify();
      return;
    }
    error = null;
    _safeNotify();
    try {
      await _service.sendMessage(
        communityId,
        text: text,
        imageURL: imageURL,
        replyToId: replyToId,
        replyToSenderName: replyToSenderName,
        replyToText: replyToText,
        replyToSenderId: replyToSenderId,
        mentions: mentions,
      );
    } on ContentViolationException catch (e) {
      if (!e.isMuteBlock && e.violationCount >= 3 && e.violationCount < 5) {
        final remaining = 5 - e.violationCount;
        violationWarning =
            'Warning: $remaining more violation${remaining == 1 ? '' : 's'} will result in a temporary mute.';
      } else {
        violationWarning = null;
      }
      error = e.message;
      _safeNotify();
    } catch (e) {
      error = e.toString();
      _safeNotify();
    }
  }

  Future<void> sendImageMessage(String communityId, Uint8List bytes) async {
    isUploading = true;
    error = null;
    notifyListeners();
    try {
      await _service.sendImageMessage(communityId, bytes: bytes);
    } catch (e) {
      error = e.toString();
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<void> markMessageSeen(String communityId, String messageId) =>
      _run(() => _service.markMessageSeen(communityId, messageId));

  /// Batch-marks messages seen — fire-and-forget, no loading state.
  Future<void> markMessagesSeenBatch(
    String communityId,
    List<String> messageIds,
  ) async {
    try {
      await _service.markMessagesSeenBatch(communityId, messageIds);
    } catch (_) {
      // Non-critical: silently swallow — read receipt failure must not disrupt chat.
    }
  }

  Future<void> deleteMessage(String communityId, String messageId) =>
      _run(() => _service.deleteMessage(communityId, messageId));

  // ── Trending ───────────────────────────────────────────────────────────────

  void loadTrendingCommunities({int limit = 20}) {
    isTrendingLoading = true;
    trendingError = null;
    notifyListeners();
    _trendingSub?.cancel();
    _trendingSub = _service.fetchTrendingCommunities(limit: limit).listen(
      (list) {
        trendingCommunities = list;
        isTrendingLoading = false;
        notifyListeners();
      },
      onError: (e) {
        trendingError = e.toString();
        isTrendingLoading = false;
        notifyListeners();
      },
    );
  }

  // ── Recommendations ────────────────────────────────────────────────────────

  Future<void> loadRecommendedCommunities(String userId) async {
    isRecommendedLoading = true;
    recommendedError = null;
    notifyListeners();
    try {
      recommendedCommunities = await _service.fetchRecommendedCommunities(
        userId: userId,
        joinedCommunityIds: myCommunities.map((c) => c.id).toList(),
      );
    } catch (e) {
      recommendedError = e.toString();
    } finally {
      isRecommendedLoading = false;
      notifyListeners();
    }
  }

  // ── Reactions ──────────────────────────────────────────────────────────────

  Future<void> incrementReactionCount(String communityId) =>
      _service.incrementReactionCount(communityId);

  // ── Discover pagination ────────────────────────────────────────────────────

  /// Fetches the total community count and the first page simultaneously.
  /// Passing [orderField] / [descending] changes and persists the active sort.
  Future<void> loadDiscoverFirstPage({
    String? orderField,
    bool? descending,
  }) async {
    if (orderField != null) _discoverOrderField = orderField;
    if (descending != null) _discoverDescending = descending;
    isDiscoverLoading = true;
    discoverCurrentPage = 0;
    _discoverCursors
      ..clear()
      ..add(null);
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getCommunitiesCount(),
        _service.getCommunitiesPage(
          orderField: _discoverOrderField,
          descending: _discoverDescending,
        ),
      ]);
      discoverTotalCount = results[0] as int;
      final snap = results[1] as QuerySnapshot<Map<String, dynamic>>;
      discoverPage = snap.docs.map((d) => CommunityModel.fromJson(d)).toList();
      if (snap.docs.length == 10 && _discoverCursors.length < 2) {
        _discoverCursors
            .add(snap.docs.last as DocumentSnapshot<Map<String, dynamic>>);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isDiscoverLoading = false;
      notifyListeners();
    }
  }

  /// Navigates to [page] (0-indexed). Only succeeds when the page's start-cursor
  /// is already cached (i.e. the user has visited all preceding pages first).
  Future<void> goToDiscoverPage(int page) async {
    if (page < 0 || page >= discoverTotalPages) return;
    if (page >= _discoverCursors.length) return;

    isDiscoverLoading = true;
    notifyListeners();
    try {
      final snap = await _service.getCommunitiesPage(
        afterDoc: _discoverCursors[page],
        orderField: _discoverOrderField,
        descending: _discoverDescending,
      );
      discoverPage = snap.docs.map((d) => CommunityModel.fromJson(d)).toList();
      discoverCurrentPage = page;
      final nextPage = page + 1;
      if (snap.docs.length == 10 && nextPage >= _discoverCursors.length) {
        _discoverCursors
            .add(snap.docs.last as DocumentSnapshot<Map<String, dynamic>>);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isDiscoverLoading = false;
      notifyListeners();
    }
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

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

  @override
  void dispose() {
    _authSub?.cancel();
    _communitiesSub?.cancel();
    _myCommunitiesSub?.cancel();
    _trendingSub?.cancel();
    _messagesSub?.cancel();
    _membersSub?.cancel();
    super.dispose();
  }
}
