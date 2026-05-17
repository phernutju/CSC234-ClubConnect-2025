import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';
import '../models/community_model.dart';
import '../models/member_model.dart';
import '../models/message_model.dart';
import '../models/rule_model.dart';
import 'ai_service.dart';
import 'notification_service.dart';
import 'report_service.dart';
import 'storage_service.dart';

class ContentViolationException implements Exception {
  final String message;
  final int violationCount; // -1 = muted block, 1-N = violation count
  const ContentViolationException(this.message, {this.violationCount = 0});
  bool get isMuteBlock => violationCount == -1;
}

class CommunityService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final StorageService _storage;
  final NotificationService _notifications;
  final ReportService _reportService;

  static const _allowedCommunityFields = {
    'communityName',
    'tags',
    'description',
    'coverImageURL',
    'rules',
  };

  CommunityService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    StorageService? storage,
    NotificationService? notifications,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? StorageService(),
        _notifications = notifications ?? NotificationService(),
        _reportService = ReportService();

  // ── Collection refs ────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _communities =>
      _db.collection('communities');

  CollectionReference<Map<String, dynamic>> _messages(String communityId) =>
      _communities.doc(communityId).collection('messages');

  CollectionReference<Map<String, dynamic>> _members(String communityId) =>
      _communities.doc(communityId).collection('members');

  // Tracks which users were active in a community within the last 24h.
  // Path: community_activity/{communityId}/activeUsers/{userId}
  CollectionReference<Map<String, dynamic>> _activityUsers(
          String communityId) =>
      _db
          .collection('community_activity')
          .doc(communityId)
          .collection('activeUsers');

  // ── Communities ────────────────────────────────────────────────────────────

  Stream<List<CommunityModel>> getCommunities() {
    if (_auth.currentUser == null)
      return Stream.error(Exception('Not authenticated'));
    return _communities.orderBy('createdAt', descending: true).snapshots().map(
          (snap) =>
              snap.docs.map((doc) => CommunityModel.fromJson(doc)).toList(),
        );
  }

  // Alternative: Get communities with limit for performance
  Stream<List<CommunityModel>> getCommunitiesLimited({int limit = 20}) {
    if (_auth.currentUser == null)
      return Stream.error(Exception('Not authenticated'));
    return _communities
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => CommunityModel.fromJson(doc)).toList(),
        );
  }

  /// Get only the first 10 communities from Firestore.
  Stream<List<CommunityModel>> getFirst10Communities() {
    return getCommunitiesLimited(limit: 10);
  }

  // Alternative: Get communities by specific IDs
  Stream<List<CommunityModel>> getCommunitiesByIds(List<String> communityIds) {
    if (_auth.currentUser == null)
      return Stream.error(Exception('Not authenticated'));
    if (communityIds.isEmpty) return Stream.value([]);

    return _communities
        .where(FieldPath.documentId, whereIn: communityIds)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => CommunityModel.fromJson(doc)).toList(),
        );
  }

  // Get communities filtered by category name (client-side, tags are stored as maps)
  Stream<List<CommunityModel>> getCommunitiesByCategory(String categoryName) {
    if (_auth.currentUser == null)
      return Stream.error(Exception('Not authenticated'));
    return _communities.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((doc) => CommunityModel.fromJson(doc))
              .where((c) => c.tags.any((t) => t.name == categoryName))
              .toList(),
        );
  }

  /// Returns a page of communities (newest first) using cursor-based pagination.
  /// Pass the last document from the previous page as [afterDoc] to advance.
  Future<QuerySnapshot<Map<String, dynamic>>> getCommunitiesPage({
    int pageSize = 10,
    DocumentSnapshot<Map<String, dynamic>>? afterDoc,
  }) async {
    Query<Map<String, dynamic>> q = _communities
        .orderBy('createdAt', descending: true)
        .limit(pageSize);
    if (afterDoc != null) q = q.startAfterDocument(afterDoc);
    return q.get();
  }

  /// Returns the total count of all communities using a Firestore aggregate query.
  Future<int> getCommunitiesCount() async {
    final snap = await _communities.count().get();
    return snap.count ?? 0;
  }

  // Get communities the user is a member of
  Stream<List<CommunityModel>> getMyCommunities() async* {
    final user = _requireAuth();

    // Fetch communities ONCE
    final communitiesSnapshot = await _communities.get();
    final communityDocs = communitiesSnapshot.docs;

    // Check membership
    final memberChecks = await Future.wait(
      communityDocs.map((doc) => _members(doc.id).doc(user.uid).get()),
    );

    // Extract IDs safely
    final communityIds = <String>[];

    for (int i = 0; i < memberChecks.length; i++) {
      if (memberChecks[i].exists) {
        communityIds.add(communityDocs[i].id);
      }
    }

    if (communityIds.isEmpty) {
      yield [];
      return;
    }

    // Firestore limit: whereIn max 10
    final limitedIds = communityIds.take(10).toList();

    yield* _communities
        .where(FieldPath.documentId, whereIn: limitedIds)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => CommunityModel.fromJson(doc)).toList(),
        );
  }

  Future<bool> checkIsMember(String communityId) async {
    final user = _requireAuth();
    final doc = await _members(communityId).doc(user.uid).get();
    return doc.exists;
  }

  // Get a specific community by ID
  Future<CommunityModel?> getCommunity(String communityId) async {
    final doc = await _communities.doc(communityId).get();
    if (!doc.exists) return null;
    return CommunityModel.fromJson(doc);
  }

  Future<String> createCommunity({
    required String communityName,
    required List<CategoryModel> category,
    required String description,
    required List<RuleModel> rules,
    Uint8List? coverImageBytes,
  }) async {
    final user = _requireAuth();
    final communityRef = _communities.doc();
    final createdAt = FieldValue.serverTimestamp();
    String coverImageURL = '';
    if (coverImageBytes != null) {
      coverImageURL =
          await _storage.uploadCommunityImage(coverImageBytes, communityRef.id);
    }
    final batch = _db.batch();
    batch.set(communityRef, {
      'communityId': communityRef.id,
      'communityName': communityName,
      'tags': category.map((c) => c.toJson()).toList(),
      'description': description,
      'coverImageURL': coverImageURL,
      'rules': rules.map((r) => r.toJson()).toList(),
      'memberCount': 1,
      'createdAt': createdAt,
      'updatedAt': createdAt,
      'createdBy': user.uid,
      'stats': const CommunityStats().toMap(),
    });
    batch.set(_members(communityRef.id).doc(user.uid), {
      'joinedAt': createdAt,
      'role': 'creator',
    });
    await batch.commit();
    return communityRef.id;
  }

  Future<void> editCommunity(
    String communityId,
    Map<String, dynamic> data,
  ) async {
    final user = _requireAuth();
    await _requireCommunityAdmin(communityId, user.uid);

    final updates = Map<String, dynamic>.from(data)
      ..removeWhere((k, _) => !_allowedCommunityFields.contains(k));
    if (updates.isEmpty) throw ArgumentError('No updatable fields provided');

    if (updates.containsKey('communityName')) {
      final name = updates['communityName'];
      if (name is! String || name.trim().isEmpty) {
        throw ArgumentError('communityName must not be empty');
      }
      updates['communityName'] = name.trim();
    }

    if (updates.containsKey('tags')) {
      final tags = updates['tags'];
      if (tags is! List) {
        throw ArgumentError('tags must be a List');
      }
    }

    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _communities.doc(communityId).update(updates);
  }

  Future<void> deleteCommunity(String communityId) async {
    final user = _requireAuth();
    await _requireCreator(communityId, user.uid);
    await _communities.doc(communityId).delete();
  }

  // ── Membership ─────────────────────────────────────────────────────────────

  Future<void> joinCommunity(String communityId) async {
    final user = _requireAuth();

    final memberRef = _members(communityId).doc(user.uid);
    if ((await memberRef.get()).exists) {
      throw Exception('Already a member of this community');
    }

    final displayName = await getUserDisplayName(user.uid);
    final communityDoc = await _communities.doc(communityId).get();
    final communityName =
        communityDoc.data()?['communityName'] as String? ?? '';
    final createdById = (communityDoc.data()?['createdBy'] ?? communityDoc.data()?['createdById']) as String?;

    final batch = _db.batch();
    batch.set(memberRef, {
      'joinedAt': FieldValue.serverTimestamp(),
      'role': 'user',
    });
    batch.update(_communities.doc(communityId), {
      'memberCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_messages(communityId).doc(), {
      'senderId': 'system',
      'isSystem': true,
      'type': 'joined',
      'senderName': displayName,
      'text': '$displayName joined the group',
      'imageURL': '',
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': [],
    });
    await batch.commit();
    _fireAndForget(_incrementStat(communityId, 'joins24h'));
    _fireAndForget(trackActiveUser(communityId));
  }

  Future<void> leaveCommunity(String communityId) async {
    final user = _requireAuth();
    final memberDoc = await _requireMemberDoc(communityId, user.uid);
    final member = MemberModel.fromJson(memberDoc.data()!, memberDoc.id);

    if (member.role == 'creator') {
      throw Exception('Transfer ownership before leaving');
    }

    final displayName = await getUserDisplayName(user.uid);
    final batch = _db.batch();
    batch.delete(_members(communityId).doc(user.uid));
    batch.update(_communities.doc(communityId), {
      'memberCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_messages(communityId).doc(), {
      'senderId': 'system',
      'isSystem': true,
      'type': 'left',
      'senderName': displayName,
      'text': '$displayName left the group',
      'imageURL': '',
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': [],
    });
    await batch.commit();
  }

  Future<void> kickMember(String communityId, String userId) async {
    _requireAuth();
    final displayName = await getUserDisplayName(userId);
    final batch = _db.batch();
    batch.delete(_members(communityId).doc(userId));
    batch.update(_communities.doc(communityId), {
      'memberCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_messages(communityId).doc(), {
      'senderId': 'system',
      'isSystem': true,
      'type': 'kicked',
      'senderName': displayName,
      'text': '$displayName was removed from the group',
      'imageURL': '',
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': [],
    });
    await batch.commit();
  }

  Stream<List<MemberModel>> getMembers(String communityId) {
    if (_auth.currentUser == null)
      return Stream.error(Exception('Not authenticated'));
    return _members(communityId).snapshots().map(
          (snap) => snap.docs
              .map((doc) => MemberModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> editMember(
    String communityId,
    String userId,
    String newRole,
  ) async {
    const assignableRoles = {'user', 'admin'};
    if (!assignableRoles.contains(newRole)) {
      throw ArgumentError('Role must be "user" or "admin"');
    }

    final current = _requireAuth();
    if (current.uid == userId) throw Exception('Cannot change your own role');

    await _requireCreator(communityId, current.uid);

    final targetDoc = await _members(communityId).doc(userId).get();
    if (!targetDoc.exists) throw Exception('Member not found: $userId');
    if (targetDoc.data()?['role'] == 'creator') {
      throw Exception('Cannot demote the community creator');
    }

    await _members(communityId).doc(userId).update({'role': newRole});
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Stream<List<MessageModel>> getMessages(String communityId) {
    if (_auth.currentUser == null)
      return Stream.error(Exception('Not authenticated'));
    return _messages(communityId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => MessageModel.fromFirestore(doc)).toList(),
        );
  }

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
    if (communityId.isEmpty) throw ArgumentError('communityId must not be empty');
    final user = _requireAuth();
    if (user.uid.isEmpty) throw ArgumentError('uid must not be empty');
    await _requireMemberDoc(communityId, user.uid);

    final communityDoc = await _communities.doc(communityId).get();
    final rulesList = (communityDoc.data()?['rules'] as List<dynamic>?)?.map((r) => RuleModel.fromMap(r)).toList() ?? [];
    final rulesString = rulesList.asMap().entries.map((e) => '${e.key + 1}. ${e.value.text}').join('\n');

    final trimmed = text.trim();
    if (trimmed.isEmpty && imageURL.isEmpty) {
      throw ArgumentError('Message must have text or an image');
    }

    // Fetch user doc: check mute status + get display name for message
    final userDoc = await _db.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
    if (trimmed.isNotEmpty && (userDoc.data()?['isMuted'] as bool?) == true) {
      throw const ContentViolationException(
        'You have been restricted from sending messages.',
        violationCount: -1,
      );
    }
    final senderName = userDoc.data()?['displayName'] as String? ?? '';

    final ref = await _messages(communityId).add({
      'senderId': user.uid,
      'senderName': senderName,
      'text': trimmed,
      'imageURL': imageURL,
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': [user.uid],
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (replyToText != null) 'replyToText': replyToText,
    });
    if (trimmed.isNotEmpty) {
      final result = await GeminiService.moderateMessage(trimmed, rules: rulesString);
      if (result.isViolating) {
        final count = await _reportService.submitAiViolation(
          userId: user.uid,
          communityId: communityId,
          messageId: ref.id,
          messageText: trimmed,
          result: result,
        );
        await ref.delete();
        throw ContentViolationException(
          'Message failed to send. This content goes against our community standards.',
          violationCount: count,
        );
      }
    }
    final needsNotification =
        (replyToSenderId != null && replyToSenderId != user.uid) ||
            mentions.any((uid) => uid != user.uid);
    if (needsNotification) {
      final communityDoc = await _communities.doc(communityId).get();
      final communityName =
          communityDoc.data()?['communityName'] as String? ?? '';
      final senderName = await getUserDisplayName(user.uid);

      if (replyToSenderId != null && replyToSenderId != user.uid) {
        await _notifications.createNotification(replyToSenderId, {
          'communityId': communityId,
          'chatRoomId': communityId,
          if (replyToId != null) 'messageId': replyToId,
          'mentionedBy': user.uid,
          'title': senderName,
          'description':
              '$senderName replied to your message in $communityName',
          'type': 'reply',
        });
      }

      for (final uid in mentions) {
        if (uid == user.uid) continue;
        await _notifications.createNotification(uid, {
          'communityId': communityId,
          'chatRoomId': communityId,
          'messageId': ref.id,
          'mentionedBy': user.uid,
          'title': senderName,
          'description': '$senderName mentioned you in $communityName',
          'type': 'mention',
        });
      }
    }

    _fireAndForget(_incrementStat(communityId, 'messages24h'));
    _fireAndForget(trackActiveUser(communityId));
  }

  Future<void> sendImageMessage(
    String communityId, {
    required Uint8List bytes,
  }) async {
    _requireAuth();
    final isNSFW = await GeminiService.moderateImageBytes(bytes);
    if (isNSFW) {
      throw Exception(
          'Message failed to send. This content goes against our community standards.');
    }
    final imageURL = await _storage.uploadChatImage(bytes, communityId);
    await sendMessage(communityId, text: '', imageURL: imageURL);
  }

  Future<void> markMessageSeen(String communityId, String messageId) async {
    final user = _requireAuth();
    await _messages(communityId).doc(messageId).update({
      'seenBy': FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> deleteMessage(String communityId, String messageId) async {
    final user = _requireAuth();
    final doc = await _messages(communityId).doc(messageId).get();
    if (!doc.exists) throw Exception('Message not found');
    if (doc.data()?['senderId'] != user.uid) {
      throw Exception('Can only delete your own messages');
    }
    await _messages(communityId).doc(messageId).delete();
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<String> getUserDisplayName(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['displayName'] as String? ?? '';
  }

  /// Single doc read returning both displayName and photoURL.
  Future<({String displayName, String photoURL})> getUserInfo(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    return (
      displayName: data?['displayName'] as String? ?? '',
      photoURL: data?['photoURL'] as String? ?? '',
    );
  }

  // ── Trending & Recommendations ─────────────────────────────────────────────

  /// Communities ordered by trendingScore descending.
  /// Requires Firestore composite index: communities / stats.trendingScore DESC
  Stream<List<CommunityModel>> fetchTrendingCommunities({int limit = 20}) {
    return _communities
        .orderBy('stats.trendingScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(CommunityModel.fromJson).toList());
  }

  /// Score formula: tagMatches*5 + trendingBoost (capped 20).
  /// Excludes communities the user already joined.
  /// Falls back to trending list when user has no interests.
  Future<List<CommunityModel>> fetchRecommendedCommunities({
    required String userId,
    required List<String> joinedCommunityIds,
    int limit = 20,
  }) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final interests = List<String>.from(userDoc.data()?['interests'] ?? []);
    final joinedSet = joinedCommunityIds.toSet();

    if (interests.isEmpty) {
      try {
        return await fetchTrendingCommunities(limit: limit).first;
      } catch (_) {
        return [];
      }
    }

    final snap = await _communities.limit(100).get();
    final scored = <_ScoredCommunity>[];

    for (final doc in snap.docs) {
      final community = CommunityModel.fromJson(doc);
      if (joinedSet.contains(community.id)) continue;

      final tagSlugs = community.tags.map((t) => t.slug).toSet();
      final tagMatches = interests.where(tagSlugs.contains).length;
      final trendingBoost =
          (community.stats.trendingScore / 10.0).clamp(0.0, 20.0);
      final score = tagMatches * 5.0 + trendingBoost;

      if (score > 0) scored.add(_ScoredCommunity(community, score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((s) => s.community).toList();
  }

  // ── Activity Tracking ──────────────────────────────────────────────────────

  /// Deduplicates active-user counting to once per user per 24h window.
  ///
  /// Uses a transaction so concurrent calls cannot both pass the 24h check
  /// and double-increment the counter. All reads happen before all writes
  /// (Firestore transaction requirement).
  Future<void> trackActiveUser(String communityId) async {
    final user = _requireAuth();
    final activityRef = _activityUsers(communityId).doc(user.uid);
    final communityRef = _communities.doc(communityId);

    await _db.runTransaction((tx) async {
      final activitySnap = await tx.get(activityRef);
      final now = Timestamp.now();

      final lastActiveAt = activitySnap.data()?['lastActiveAt'] as Timestamp?;
      final shouldCount = !activitySnap.exists ||
          lastActiveAt == null ||
          now.toDate().difference(lastActiveAt.toDate()) >=
              const Duration(hours: 24);

      // Read community doc before any writes (only when we need to update stats).
      DocumentSnapshot<Map<String, dynamic>>? communitySnap;
      if (shouldCount) communitySnap = await tx.get(communityRef);

      // ── Writes ────────────────────────────────────────────────────────────
      // Always refresh lastActiveAt so the 24h window is anchored to latest activity.
      tx.set(activityRef, {'lastActiveAt': now});

      if (!shouldCount || communitySnap == null || !communitySnap.exists)
        return;

      // First activity in this 24h window — increment counter and recalc score.
      final statsMap =
          (communitySnap.data()?['stats'] as Map<String, dynamic>?) ?? {};
      final newActive = (statsMap['activeUsers24h'] as int? ?? 0) + 1;
      final newScore = _computeTrendingScore(<String, dynamic>{
        ...statsMap,
        'activeUsers24h': newActive,
      });

      tx.update(communityRef, {
        'stats.activeUsers24h': FieldValue.increment(1),
        'stats.trendingScore': newScore,
        'stats.lastTrendingUpdate': now,
      });
    });
  }

  /// Call when a user reacts to a message.
  Future<void> incrementReactionCount(String communityId) =>
      _incrementStat(communityId, 'reactions24h');

  /// Increments a 24h stat counter with lazy window reset.
  /// If >24h since statsWindowStart, all counters reset before incrementing.
  Future<void> _incrementStat(String communityId, String field) async {
    final ref = _communities.doc(communityId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final statsMap = (snap.data()?['stats'] as Map<String, dynamic>?) ?? {};
    final windowStart = statsMap['statsWindowStart'] as Timestamp?;
    final now = Timestamp.now();
    final windowExpired = windowStart == null ||
        now.toDate().difference(windowStart.toDate()) >=
            const Duration(hours: 24);

    if (windowExpired) {
      // New 24h window — reset all counters then set this field to 1.
      final fresh = <String, dynamic>{
        'messages24h': 0,
        'activeUsers24h': 0,
        'joins24h': 0,
        'reactions24h': 0,
        'statsWindowStart': now,
        'lastTrendingUpdate': now,
        field: 1,
      };
      fresh['trendingScore'] = _computeTrendingScore(fresh);
      await ref.update({'stats': fresh});
    } else {
      final newScore = _computeTrendingScore({
        'messages24h': (statsMap['messages24h'] as int? ?? 0) +
            (field == 'messages24h' ? 1 : 0),
        'activeUsers24h': (statsMap['activeUsers24h'] as int? ?? 0) +
            (field == 'activeUsers24h' ? 1 : 0),
        'joins24h':
            (statsMap['joins24h'] as int? ?? 0) + (field == 'joins24h' ? 1 : 0),
        'reactions24h': (statsMap['reactions24h'] as int? ?? 0) +
            (field == 'reactions24h' ? 1 : 0),
      });
      await ref.update({
        'stats.$field': FieldValue.increment(1),
        'stats.trendingScore': newScore,
        'stats.lastTrendingUpdate': now,
      });
    }
  }

  /// trendingScore = messages*1 + activeUsers*4 + joins*3 + reactions*2
  static double _computeTrendingScore(Map<String, dynamic> stats) {
    return (stats['messages24h'] as int? ?? 0) * 1.0 +
        (stats['activeUsers24h'] as int? ?? 0) * 4.0 +
        (stats['joins24h'] as int? ?? 0) * 3.0 +
        (stats['reactions24h'] as int? ?? 0) * 2.0;
  }

  /// Runs a future without awaiting it; swallows errors so stats failures
  /// never surface to the user.
  void _fireAndForget(Future<void> future) {
    future.catchError((_) {});
  }

  // Extensibility hook for future ML-based personalization.
  // Increments the per-user interest score for a tag slug.
  // Call after join/message in communities with matching tags.
  // ignore: unused_element
  Future<void> _incrementInterestScore(String userId, String tagSlug) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('interestScores')
        .doc(tagSlug)
        .set({'score': FieldValue.increment(1)}, SetOptions(merge: true));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  User _requireAuth() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return user;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _requireMemberDoc(
    String communityId,
    String uid,
  ) async {
    final doc = await _members(communityId).doc(uid).get();
    if (!doc.exists) throw Exception('Not a member of this community');
    return doc;
  }

  Future<void> _requireCommunityAdmin(String communityId, String uid) async {
    final doc = await _members(communityId).doc(uid).get();
    if (!doc.exists) throw Exception('Not a member of this community');
    final role = doc.data()?['role'] as String? ?? 'user';
    if (role != 'admin' && role != 'creator') {
      throw Exception('Admin or creator permission required');
    }
  }

  Future<void> _requireCreator(String communityId, String uid) async {
    final doc = await _members(communityId).doc(uid).get();
    if (!doc.exists) throw Exception('Not a member of this community');
    if (doc.data()?['role'] != 'creator') {
      throw Exception('Only the community creator can perform this action');
    }
  }
}

// Private value type used only inside fetchRecommendedCommunities.
class _ScoredCommunity {
  final CommunityModel community;
  final double score;
  const _ScoredCommunity(this.community, this.score);
}
