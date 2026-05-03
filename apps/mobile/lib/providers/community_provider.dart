import 'package:flutter/foundation.dart';
import '../models/community_model.dart';

/// Holds all user-created communities for the current session.
/// Notifies listeners whenever the list changes.
class CommunityProvider extends ChangeNotifier {
  final List<CommunityModel> _communities = [];

  List<CommunityModel> get communities => List.unmodifiable(_communities);

  void addCommunity(CommunityModel community) {
    _communities.add(community);
    notifyListeners();
  }
}
