import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/community_model.dart';
import '../models/member_model.dart';
import '../models/message_model.dart';
import '../models/rule_model.dart';
import '../services/community_service.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityService _service;
  final Set<String> _mutedCommunities = {};
  final Map<String, String> _nameCache = {};
  List<CommunityModel> communities = [];
  List<CommunityModel> myCommunities = [];
  CommunityModel? activeCommunity;
  List<MessageModel> messages = [];
  List<MemberModel> members = [];
  bool isLoading = false;
  bool isUploading = false;
  String? error;

  StreamSubscription<List<CommunityModel>>? _communitiesSub;
  StreamSubscription<List<CommunityModel>>? _myCommunitiesSub;
  StreamSubscription<List<MessageModel>>? _messagesSub;
  StreamSubscription<List<MemberModel>>? _membersSub;


  Set<String> get mutedCommunityNames => Set.unmodifiable(_mutedCommunities);

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

  /// Fetches and caches the display name for [uid] from Firestore.
  /// No-ops if already cached. Notifies listeners when the name arrives.
  Future<void> fetchDisplayName(String uid) async {
    if (_nameCache.containsKey(uid)) return;
    _nameCache[uid] = ''; // mark as in-flight to prevent duplicate fetches
    try {
      _nameCache[uid] = await _service.getUserDisplayName(uid);
    } catch (_) {
      _nameCache[uid] = 'User';
    }
    notifyListeners();
  }

  void _listenToCommunities(Stream<List<CommunityModel>> stream) {
    _communitiesSub?.cancel();
    _communitiesSub = stream.listen(
      (list) {
        communities = list;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
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

  CommunityProvider({CommunityService? service})
      : _service = service ?? CommunityService() {
    _listenToCommunities(_service.getCommunities());
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
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );

    _membersSub = _service.getMembers(community.id).listen(
      (list) {
        members = list;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );

    notifyListeners();
  }

  void clearActiveCommunity() {
    activeCommunity = null;
    messages = [];
    members = [];
    _messagesSub?.cancel();
    _membersSub?.cancel();
    notifyListeners();
  }

  // ── Community actions ──────────────────────────────────────────────────────

  Future<void> editCommunity(
    String communityId,
    Map<String, dynamic> data,
  ) =>
      _run(() => _service.editCommunity(communityId, data));

  Future<void> joinCommunity(String communityId) =>
      _run(() => _service.joinCommunity(communityId));

  Future<void> leaveCommunity(String communityId) =>
      _run(() async {
        await _service.leaveCommunity(communityId);
        if (activeCommunity?.id == communityId) clearActiveCommunity();
      });

  Future<void> addCommunity({
    required String communityName,
    required List<String> category,
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
  }) =>
      _run(() => _service.sendMessage(
            communityId,
            text: text,
            imageURL: imageURL,
          ));

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
    _communitiesSub?.cancel();
    _myCommunitiesSub?.cancel();
    _messagesSub?.cancel();
    _membersSub?.cancel();
    super.dispose();
  }
}