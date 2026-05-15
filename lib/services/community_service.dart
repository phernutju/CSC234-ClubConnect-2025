import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ── Communities ────────────────────────────────────────────────────────────

  Stream<List<CommunityModel>> getCommunities() {
    if (_auth.currentUser == null) return Stream.error(Exception('Not authenticated'));
    return _communities
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CommunityModel.fromJson(doc))
              .toList(),
        );
  }

  // Alternative: Get communities with limit for performance
  Stream<List<CommunityModel>> getCommunitiesLimited({int limit = 20}) {
    if (_auth.currentUser == null) return Stream.error(Exception('Not authenticated'));
    return _communities
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CommunityModel.fromJson(doc))
              .toList(),
        );
  }

  /// Get only the first 10 communities from Firestore.
  Stream<List<CommunityModel>> getFirst10Communities() {
    return getCommunitiesLimited(limit: 10);
  }

  // Alternative: Get communities by specific IDs
  Stream<List<CommunityModel>> getCommunitiesByIds(List<String> communityIds) {
    if (_auth.currentUser == null) return Stream.error(Exception('Not authenticated'));
    if (communityIds.isEmpty) return Stream.value([]);

    return _communities
        .where(FieldPath.documentId, whereIn: communityIds)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CommunityModel.fromJson(doc))
              .toList(),
        );
  }

  // Get communities filtered by category name (client-side, tags are stored as maps)
  Stream<List<CommunityModel>> getCommunitiesByCategory(String categoryName) {
    if (_auth.currentUser == null) return Stream.error(Exception('Not authenticated'));
    return _communities
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CommunityModel.fromJson(doc))
              .where((c) => c.tags.any((t) => t.name == categoryName))
              .toList(),
        );
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
          (snap) => snap.docs
              .map((doc) => CommunityModel.fromJson(doc))
              .toList(),
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
      coverImageURL = await _storage.uploadCommunityImage(coverImageBytes, communityRef.id);
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
    final createdById =
        communityDoc.data()?['createdById'] as String?;

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

    if (createdById != null && createdById != user.uid) {
      final joinerName = await getUserDisplayName(user.uid);
      await _notifications.createNotification(createdById, {
        'communityId': communityId,
        'mentionedBy': user.uid,
        'title': joinerName,
        'description': '$joinerName joined $communityName',
        'type': 'join',
      });
    }
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
    if (_auth.currentUser == null) return Stream.error(Exception('Not authenticated'));
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
    if (_auth.currentUser == null) return Stream.error(Exception('Not authenticated'));
    return _messages(communityId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> sendMessage(
    String communityId, {
    required String text,
    String imageURL = '',
    String rules = '',
    String? replyToId,
    String? replyToSenderName,
    String? replyToText,
    String? replyToSenderId,
    List<String> mentions = const [],
  }) async {
    final user = _requireAuth();
    await _requireMemberDoc(communityId, user.uid);

    final trimmed = text.trim();
    if (trimmed.isEmpty && imageURL.isEmpty) {
      throw ArgumentError('Message must have text or an image');
    }

    // Check if user is muted before adding message
    if (trimmed.isNotEmpty) {
      final userDoc = await _db.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
      if ((userDoc.data()?['isMuted'] as bool?) == true) {
        throw const ContentViolationException(
          'You have been restricted from sending messages.',
          violationCount: -1,
        );
      }
    }

    final ref = await _messages(communityId).add({
      'senderId': user.uid,
      'text': trimmed,
      'imageURL': imageURL,
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': [user.uid],
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (replyToText != null) 'replyToText': replyToText,
      if (mentions.isNotEmpty) 'mentions': mentions,
    });

    if (trimmed.isNotEmpty) {
      final result = await GeminiService.moderateMessage(trimmed, rules: rules);
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
          'mentionedBy': user.uid,
          'title': senderName,
          'description': '$senderName mentioned you in $communityName',
          'type': 'mention',
        });
      }
    }
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
    return doc.data()?['displayName'] as String? ?? 'User';
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
