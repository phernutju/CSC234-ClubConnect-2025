import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/community_model.dart';
import '../models/member_model.dart';
import '../models/message_model.dart';
import '../services/community_service.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityService _service;

  List<CommunityModel> communities = [];
  CommunityModel? activeCommunity;
  List<MessageModel> messages = [];
  List<MemberModel> members = [];
  bool isLoading = false;
  String? error;

  StreamSubscription<List<CommunityModel>>? _communitiesSub;
  StreamSubscription<List<MessageModel>>? _messagesSub;
  StreamSubscription<List<MemberModel>>? _membersSub;

  CommunityProvider({CommunityService? service})
      : _service = service ?? CommunityService() {
    _communitiesSub = _service.getCommunities().listen(
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
    _messagesSub?.cancel();
    _membersSub?.cancel();
    super.dispose();
  }
}