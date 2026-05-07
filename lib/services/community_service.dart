import '../models/community_model.dart';
import '../models/rule_model.dart';

/// TODO: Replace stubs with real API calls.
/// Backend team: implement these methods.
class CommunityService {
  /// TODO: GET /api/communities
  static Future<List<CommunityModel>> fetchCommunities() async {
    // Stub data — remove when backend is connected
    return const [
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
  }

  /// TODO: POST /api/communities
  static Future<void> createCommunity(CommunityModel community) async {}

  /// TODO: PUT /api/communities/{name}
  static Future<void> updateCommunity(
      String name, CommunityModel community) async {}

  /// TODO: POST /api/communities/{name}/members
  static Future<void> joinCommunity(String communityName) async {}

  /// TODO: DELETE /api/communities/{name}/members/me
  static Future<void> leaveCommunity(String communityName) async {}
}
