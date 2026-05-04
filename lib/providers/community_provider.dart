import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';

class CommunityProvider extends ChangeNotifier {
  final _service = CommunityService();

  List<CommunityModel> _allCommunities = [];
  final List<CommunityModel> _created = [];
  final List<CommunityModel> _joined  = [];
  StreamSubscription<List<CommunityModel>>? _sub;

  final Set<String> _mutedCommunities = {};

  CommunityProvider() {
    _sub = _service.getCommunities().listen((list) {
      _allCommunities = list;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool isMuted(String communityName) => _mutedCommunities.contains(communityName);
  Set<String> get mutedCommunityNames => Set.unmodifiable(_mutedCommunities);

  void toggleMute(String communityName) {
    if (_mutedCommunities.contains(communityName)) {
      _mutedCommunities.remove(communityName);
    } else {
      _mutedCommunities.add(communityName);
    }
    notifyListeners();
  }

  List<CommunityModel> get communities => [..._created, ..._joined];

  List<CommunityModel> get discoverCommunities {
    final myIds = {
      ..._created.map((c) => c.id),
      ..._joined.map((c) => c.id),
    };
    return _allCommunities.where((c) => c.id.isNotEmpty && !myIds.contains(c.id)).toList();
  }

  void addCommunity(CommunityModel community) {
    _created.add(community);
    notifyListeners();
  }

  Future<void> joinCommunity(CommunityModel community) async {
    _joined.add(community.copyWith(memberCount: community.memberCount + 1));
    notifyListeners();
    if (community.id.isNotEmpty) {
      try {
        await _service.joinCommunity(community.id);
      } catch (_) {
        // Already a member or other transient error — local state is sufficient
      }
    }
  }

  void leaveCommunity(String communityName) {
    _created.removeWhere((c) => c.name == communityName);
    _joined.removeWhere((c) => c.name == communityName);
    notifyListeners();
  }

  void updateCommunity(String currentName, CommunityModel updated) {
    final ci = _created.indexWhere((c) => c.name == currentName);
    if (ci != -1) {
      _created[ci] = updated;
      notifyListeners();
      return;
    }
    final ji = _joined.indexWhere((c) => c.name == currentName);
    if (ji != -1) {
      _joined[ji] = updated;
      notifyListeners();
    }
  }
}
