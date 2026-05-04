import 'package:flutter/foundation.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';

/// Manages all community data for the current session.
/// Notifies listeners whenever the community lists change.
class CommunityProvider extends ChangeNotifier {
  List<CommunityModel> _discover = [];
  final List<CommunityModel> _created = [];
  final List<CommunityModel> _joined  = [];
  final Set<String> _mutedCommunities = {};

  CommunityProvider() {
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    _discover = await CommunityService.fetchCommunities();
    notifyListeners();
  }

  bool isMuted(String communityName) => _mutedCommunities.contains(communityName);

  /// Read-only view of all muted community names (used by NotificationScreen).
  Set<String> get mutedCommunityNames => Set.unmodifiable(_mutedCommunities);

  void toggleMute(String communityName) {
    if (_mutedCommunities.contains(communityName)) {
      _mutedCommunities.remove(communityName);
    } else {
      _mutedCommunities.add(communityName);
    }
    notifyListeners();
  }

  /// Communities the user belongs to (created or joined) — My Club tab.
  List<CommunityModel> get communities => [..._created, ..._joined];

  /// Communities available to join — Discover tab.
  /// Excludes anything the user already created or joined.
  List<CommunityModel> get discoverCommunities {
    final myNames = {
      ..._created.map((c) => c.name),
      ..._joined.map((c) => c.name),
    };
    return _discover.where((c) => !myNames.contains(c.name)).toList();
  }

  /// Adds a user-created community directly to My Club.
  void addCommunity(CommunityModel community) {
    _created.add(community);
    CommunityService.createCommunity(community);
    notifyListeners();
  }

  /// Joins a Discover community, incrementing its member count by 1.
  void joinCommunity(CommunityModel community) {
    _joined.add(community.copyWith(memberCount: community.memberCount + 1));
    CommunityService.joinCommunity(community.name);
    notifyListeners();
  }

  /// Removes a community from My Club (works for both created and joined).
  void leaveCommunity(String communityName) {
    _created.removeWhere((c) => c.name == communityName);
    _joined.removeWhere((c) => c.name == communityName);
    CommunityService.leaveCommunity(communityName);
    notifyListeners();
  }

  /// Updates an existing community matched by [currentName].
  void updateCommunity(String currentName, CommunityModel updated) {
    final ci = _created.indexWhere((c) => c.name == currentName);
    if (ci != -1) {
      _created[ci] = updated;
      CommunityService.updateCommunity(currentName, updated);
      notifyListeners();
      return;
    }
    final ji = _joined.indexWhere((c) => c.name == currentName);
    if (ji != -1) {
      _joined[ji] = updated;
      CommunityService.updateCommunity(currentName, updated);
      notifyListeners();
    }
  }
}
