import 'package:flutter/foundation.dart';
import '../models/community_model.dart';
import '../models/rule_model.dart';

/// Manages all community data for the current session.
/// Notifies listeners whenever the community lists change.
class CommunityProvider extends ChangeNotifier {
  // TESTING ONLY - remove when backend connected
  static const List<CommunityModel> _dummyCommunities = [
    CommunityModel(
      name: 'Badminton Thonburi',
      description:
          'Weekly badminton. Sunday meetups in Thonburi. Beginners welcome. Like Family',
      memberCount: 10,
      category: 'Sports',
      hostName: 'Host name',
      hostRating: 4.9,
      rules: [
        RuleModel(
          title: 'Be Respectful & Kind',
          description:
              'Treat everyone with respect. Bullying, harassment, and hate speech are strictly prohibited.',
        ),
        RuleModel(
          title: 'No Spam or Promos',
          description:
              'Please do not post spam, self-promotion, or irrelevant links.',
        ),
        RuleModel(
          title: 'Stay on Topic',
          description:
              "Ensure your posts and discussions are relevant to the group's main theme.",
        ),
      ],
    ),
    CommunityModel(
      name: 'Coding KMUTT',
      description: 'A place for coders to share knowledge and grow together',
      memberCount: 8,
      category: 'Coding',
      hostName: 'CodeMaster',
      hostRating: 4.7,
      rules: [
        RuleModel(
          title: 'Share Knowledge',
          description: 'Help each other learn and grow.',
        ),
        RuleModel(
          title: 'No Copy Paste',
          description: 'Always credit original sources.',
        ),
      ],
    ),
    CommunityModel(
      name: 'Valorant Thailand',
      description: 'Join us for weekly gaming sessions and tournaments',
      memberCount: 25,
      category: 'Gaming',
      hostName: 'GamerPro',
      hostRating: 4.5,
      rules: [
        RuleModel(
          title: 'No Toxic Behavior',
          description: 'Keep the environment friendly and fun.',
        ),
        RuleModel(
          title: 'Fair Play Only',
          description: 'No cheating or exploiting bugs.',
        ),
      ],
    ),
    CommunityModel(
      name: 'Cafe Gurllll',
      description: 'Coffee lovers unite! Share your favorite spots',
      memberCount: 15,
      category: 'Food',
      hostName: 'CafeHost',
      hostRating: 4.8,
      rules: [
        RuleModel(
          title: 'Be Kind',
          description: 'Respect all members and their opinions.',
        ),
      ],
    ),
  ];

  final List<CommunityModel> _created = [];
  final List<CommunityModel> _joined  = [];

  /// Names of communities whose notifications are muted by the user.
  final Set<String> _mutedCommunities = {};

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
    return _dummyCommunities
        .where((c) => !myNames.contains(c.name))
        .toList();
  }

  /// Adds a user-created community directly to My Club.
  void addCommunity(CommunityModel community) {
    _created.add(community);
    notifyListeners();
  }

  /// Joins a Discover community, incrementing its member count by 1.
  void joinCommunity(CommunityModel community) {
    _joined.add(community.copyWith(memberCount: community.memberCount + 1));
    notifyListeners();
  }

  /// Removes a community from My Club (works for both created and joined).
  void leaveCommunity(String communityName) {
    _created.removeWhere((c) => c.name == communityName);
    _joined.removeWhere((c) => c.name == communityName);
    notifyListeners();
  }

  /// Updates an existing community matched by [currentName].
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
