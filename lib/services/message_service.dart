import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message_model.dart';
import 'ai_service.dart';

class MessageService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get currentUid => _auth.currentUser?.uid;

  static const int _maxViolations = 3;
  static const Duration _banDuration = Duration(hours: 24);

  // ── Stream ────────────────────────────────────────────────────────────────

  static Stream<List<MessageModel>> messagesStream(String communityId) => _db
      .collection('communities')
      .doc(communityId)
      .collection('messages')
      .orderBy('timestamp')
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());

  // ── Send ──────────────────────────────────────────────────────────────────

  /// Returns null on success, or an error string to show the user.
  static Future<SendResult> sendMessage({
    required String communityId,
    required String text,
    String communityRules = '',
    String? replyToName,
    String? replyToText,
  }) async {
    if (communityId.isEmpty) return SendResult.error('Community not saved yet');
    final user = _auth.currentUser;
    if (user == null) return SendResult.error('Not signed in');

    // 1. Check if user is currently banned
    final banStatus = await getBanStatus(user.uid);
    if (banStatus.isBanned) return SendResult.banned(banStatus.bannedUntil!);

    // 2. Moderate with Gemini
    final bool flagged;
    try {
      flagged = await GeminiService.moderateMessage(
        text,
        rules: communityRules,
      );
    } catch (e) {
      return SendResult.error('Content moderation unavailable: $e');
    }

    if (flagged) {
      // 3a. Increment violation count and ban if threshold reached
      await _recordViolation(user.uid);
      final newStatus = await getBanStatus(user.uid);
      return SendResult.flagged(isBanned: newStatus.isBanned, banUntil: newStatus.bannedUntil);
    }

    // 3b. Save message to Firestore
    final ref = _db
        .collection('communities')
        .doc(communityId)
        .collection('messages')
        .doc();

    await ref.set({
      'msgId': ref.id,
      'senderId': user.uid,
      'senderName': user.displayName ?? 'User',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'flagged': false,
      'replyToName': replyToName,
      'replyToText': replyToText,
    });

    return SendResult.success();
  }

  // ── Ban helpers ───────────────────────────────────────────────────────────

  static Future<BanStatus> getBanStatus(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return BanStatus(isBanned: false);

    final data = doc.data()!;
    final bannedUntil = (data['bannedUntil'] as Timestamp?)?.toDate();
    if (bannedUntil != null && bannedUntil.isAfter(DateTime.now())) {
      return BanStatus(isBanned: true, bannedUntil: bannedUntil);
    }
    return BanStatus(isBanned: false);
  }

  static Future<void> _recordViolation(String uid) async {
    final ref = _db.collection('users').doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['violations'] as int?) ?? 0;
      final next = current + 1;

      final Map<String, dynamic> update = {'violations': next};
      if (next >= _maxViolations) {
        update['bannedUntil'] =
            Timestamp.fromDate(DateTime.now().add(_banDuration));
        update['violations'] = 0; // reset after ban
      }
      tx.set(ref, update, SetOptions(merge: true));
    });
  }
}

// ── Result types ──────────────────────────────────────────────────────────────

enum SendStatus { success, flagged, banned, error }

class SendResult {
  final SendStatus status;
  final String? errorMessage;
  final DateTime? banUntil;
  final bool newBan;

  const SendResult._({
    required this.status,
    this.errorMessage,
    this.banUntil,
    this.newBan = false,
  });

  factory SendResult.success() => const SendResult._(status: SendStatus.success);

  factory SendResult.flagged({bool isBanned = false, DateTime? banUntil}) =>
      SendResult._(
        status: SendStatus.flagged,
        newBan: isBanned,
        banUntil: banUntil,
      );

  factory SendResult.banned(DateTime until) =>
      SendResult._(status: SendStatus.banned, banUntil: until);

  factory SendResult.error(String msg) =>
      SendResult._(status: SendStatus.error, errorMessage: msg);
}

class BanStatus {
  final bool isBanned;
  final DateTime? bannedUntil;
  const BanStatus({required this.isBanned, this.bannedUntil});
}
