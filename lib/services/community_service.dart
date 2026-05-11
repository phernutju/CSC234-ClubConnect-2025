import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_model.dart';
import '../models/member_model.dart';
import '../models/message_model.dart';
import '../models/rule_model.dart';
import 'storage_service.dart';

class CommunityService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final StorageService _storage;

  static const _allowedCommunityFields = {
    'communityName',
    'category',
    'description',
    'coverImageURL',
    'rules',
  };

  CommunityService({FirebaseFirestore? db, FirebaseAuth? auth, StorageService? storage})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance,
      _storage = storage ?? StorageService();

  // ── Collection refs ────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _communities =>
      _db.collection('communities');

  CollectionReference<Map<String, dynamic>> _messages(String communityId) =>
      _communities.doc(communityId).collection('messages');

  CollectionReference<Map<String, dynamic>> _members(String communityId) =>
      _communities.doc(communityId).collection('members');

  // ── Communities ────────────────────────────────────────────────────────────

  Stream<List<CommunityModel>> getCommunities() {
    return _communities
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CommunityModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  // Alternative: Get communities with limit for performance
  Stream<List<CommunityModel>> getCommunitiesLimited({int limit = 20}) {
    return _communities
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CommunityModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get only the first 10 communities from Firestore.
  Stream<List<CommunityModel>> getFirst10Communities() {
    return getCommunitiesLimited(limit: 10);
  }

  // Alternative: Get communities by specific IDs
  Stream<List<CommunityModel>> getCommunitiesByIds(List<String> communityIds) {
    if (communityIds.isEmpty) return Stream.value([]);

    return _communities
        .where(FieldPath.documentId, whereIn: communityIds)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CommunityModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get communities filtered by category
  Stream<List<CommunityModel>> getCommunitiesByCategory(String category) {
    return _communities
        .where('category', arrayContains: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CommunityModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get communities the user is a member of
  Stream<List<CommunityModel>> getMyCommunities() async* {
    final user = _requireAuth();

    // ✅ Fetch communities ONCE
    final communitiesSnapshot = await _communities.get();
    final communityDocs = communitiesSnapshot.docs;

    // ✅ Check membership
    final memberChecks = await Future.wait(
      communityDocs.map((doc) => _members(doc.id).doc(user.uid).get()),
    );

    // ✅ Extract IDs safely
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

    // ⚠️ Firestore limit: whereIn max 10
    final limitedIds = communityIds.take(10).toList();

    yield* _communities
        .where(FieldPath.documentId, whereIn: limitedIds)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CommunityModel.fromJson(doc.data(), doc.id))
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
    return CommunityModel.fromJson(doc.data()!, doc.id);
  }

  Future<void> createCommunity({
    required String communityName,
    required List<String> category,
    required String description,
    required List<RuleModel> rules,
    Uint8List? coverImageBytes,
  }) async {
    final user = _requireAuth();
    final communityRef = _communities.doc();
    final createdAt = FieldValue.serverTimestamp();
    print('Creating community with name: $communityName');
    String coverImageURL = '';
    if (coverImageBytes != null) {
      coverImageURL = await _storage.uploadCommunityImage(coverImageBytes, communityRef.id);
    }
    print('Uploaded cover image, URL: $coverImageURL');
    final batch = _db.batch();
    batch.set(communityRef, {
      'communityId': communityRef.id,
      'communityName': communityName,
      'category': category,
      'description': description,
      'coverImageURL': coverImageURL,
      'rules': rules.map((r) => r.toJson()).toList(),
      'memberCount': 1,
      'createdAt': createdAt,
      'updatedAt': createdAt,
      'createdById': user.uid,
    });
    batch.set(_members(communityRef.id).doc(user.uid), {
      'joinedAt': createdAt,
      'role': 'creator',
    });
    await batch.commit();
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

    if (updates.containsKey('category')) {
      final cat = updates['category'];
      if (cat is! List || cat.any((e) => e is! String)) {
        throw ArgumentError('category must be a List<String>');
      }
    }

    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _communities.doc(communityId).update(updates);
  }

  // ── Membership ─────────────────────────────────────────────────────────────

  Future<void> joinCommunity(String communityId) async {
    final user = _requireAuth();

    final memberRef = _members(communityId).doc(user.uid);
    if ((await memberRef.get()).exists) {
      throw Exception('Already a member of this community');
    }

    final displayName = await getUserDisplayName(user.uid);

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
      'text': '$displayName joined the group',
      'imageURL': '',
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': [],
    });
    await batch.commit();
  }

  Future<void> leaveCommunity(String communityId) async {
    final user = _requireAuth();
    final memberDoc = await _requireMemberDoc(communityId, user.uid);
    final member = MemberModel.fromJson(memberDoc.data()!, memberDoc.id);

    if (member.role == 'creator') {
      throw Exception('Transfer ownership before leaving');
    }

    final batch = _db.batch();
    batch.delete(_members(communityId).doc(user.uid));
    batch.update(_communities.doc(communityId), {
      'memberCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> kickMember(String communityId, String userId) async {
    _requireAuth();
    final batch = _db.batch();
    batch.delete(_members(communityId).doc(userId));
    batch.update(_communities.doc(communityId), {
      'memberCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Stream<List<MemberModel>> getMembers(String communityId) {
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
    return _messages(communityId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MessageModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> sendMessage(
    String communityId, {
    required String text,
    String imageURL = '',
    String? replyToId,
    String? replyToSenderName,
    String? replyToText,
  }) async {
    final user = _requireAuth();
    await _requireMemberDoc(communityId, user.uid);

    final trimmed = text.trim();
    if (trimmed.isEmpty && imageURL.isEmpty) {
      throw ArgumentError('Message must have text or an image');
    }

    await _messages(communityId).add({
      'senderId': user.uid,
      'text': trimmed,
      'imageURL': imageURL,
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': [user.uid],
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (replyToText != null) 'replyToText': replyToText,
    });
  }

  Future<void> sendImageMessage(
    String communityId, {
    required Uint8List bytes,
  }) async {
    _requireAuth();
    final imageURL = await _storage.uploadChatImage(bytes, communityId);
    await sendMessage(communityId, text: '', imageURL: imageURL);
  }

  Future<void> markMessageSeen(String communityId, String messageId) async {
    final user = _requireAuth();
    await _messages(communityId).doc(messageId).update({
      'seenBy': FieldValue.arrayUnion([user.uid]),
    });
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
