import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';
import 'ai_service.dart';

class ReportService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ReportService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ── Collection ref ─────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  // ── Methods ────────────────────────────────────────────────────────────────

  Future<void> submitReport(ReportModel report) async {
    try {
      _requireAuth();
      final duplicate = await hasUserReportedMessage(
        report.reporterId,
        report.messageId,
      );
      if (duplicate) throw Exception('Already reported this message');

      final ref = _reports.doc();
      await ref.set({
        ...report.toMap(),
        'reportId': ref.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ReportModel>> getReportsByCommunity(String communityId) async {
    final snap = await _reports
        .where('communityId', isEqualTo: communityId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) => ReportModel.fromMap(doc.data())).toList();
  }

  Future<List<ReportModel>> getReportsByUser(String reporterId) async {
    final snap = await _reports
        .where('reporterId', isEqualTo: reporterId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) => ReportModel.fromMap(doc.data())).toList();
  }

  Future<void> updateReportStatus(
    String reportId,
    ReportStatus status,
    String reviewedBy,
  ) async {
    _requireAuth();
    await _reports.doc(reportId).update({
      'status': status.name,
      'reviewedBy': reviewedBy,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> submitAiViolation({
    required String userId,
    required String communityId,
    required String messageId,
    required String messageText,
    required ModerationResult result,
  }) async {
    final userRef = _db.collection('users').doc(userId);
    int newCount = 0;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? {};
      final current = (data['violationCount'] as int?) ?? 0;
      final muteCount = (data['muteCount'] as int?) ?? 0;
      newCount = current + 1;

      final updates = <String, dynamic>{'violationCount': newCount};

      if (newCount >= 5) {
        if (muteCount >= 3) {
          updates['isBanned'] = true;
          updates['isMuted'] = false;
          updates['banReason'] = 'Repeated violations of community guidelines';
          updates['durationLabel'] = 'Permanently';
          updates['bannedAt'] = FieldValue.serverTimestamp();
          updates['violationCount'] = 0;
        } else {
          const muteDurations = [
            Duration(hours: 1),
            Duration(hours: 5),
            Duration(hours: 10),
          ];
          final expiry = DateTime.now().add(muteDurations[muteCount]);
          updates['isMuted'] = true;
          updates['muteCount'] = muteCount + 1;
          updates['muteExpiresAt'] = Timestamp.fromDate(expiry);
          updates['violationCount'] = 0;
        }
      }

      tx.update(userRef, updates);
    });

    ReportReason reason = ReportReason.other;
    final rules = result.violatedRules;
    if (rules.contains(4)) {
      reason = ReportReason.threat;
    } else if (rules.contains(5) || rules.contains(2) || rules.contains(3)) {
      reason = ReportReason.hateSpeech;
    }

    final status = newCount >= 4 ? ReportStatus.urgent : ReportStatus.pending;
    final reportRef = _reports.doc();
    await reportRef.set({
      'reportId': reportRef.id,
      'reporterId': 'system',
      'targetUserId': userId,
      'communityId': communityId,
      'messageId': messageId,
      'messageText': messageText,
      'reason': reason.name,
      'targetType': ReportTargetType.message.name,
      'source': ReportSource.aiDetected.name,
      'status': status.name,
      'description': result.reason,
      'violationCount': newCount,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newCount;
  }

  Stream<List<ReportModel>> streamPendingReports() {
    return _reports
        .where('status',
            whereIn: [ReportStatus.pending.name, ReportStatus.urgent.name])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => ReportModel.fromMap(doc.data())).toList(),
        );
  }

  Future<bool> hasUserReportedMessage(
    String reporterId,
    String messageId,
  ) async {
    final snap = await _reports
        .where('reporterId', isEqualTo: reporterId)
        .where('messageId', isEqualTo: messageId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  User _requireAuth() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return user;
  }
}
