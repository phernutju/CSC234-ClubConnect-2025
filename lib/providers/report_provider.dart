import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

enum ReportState { idle, submitting, submitted, loading, error }

class ReportProvider extends ChangeNotifier {
  final ReportService _service;
  final FirebaseAuth _auth;

  List<ReportModel> reports = [];
  ReportState state = ReportState.idle;
  String? error;

  StreamSubscription<List<ReportModel>>? _pendingSub;

  ReportProvider({ReportService? service, FirebaseAuth? auth})
      : _service = service ?? ReportService(),
        _auth = auth ?? FirebaseAuth.instance;

  void resetState() {
    state = ReportState.idle;
    error = null;
    notifyListeners();
  }

  // ── Streams ────────────────────────────────────────────────────────────────

  Stream<List<ReportModel>> get pendingReportsStream =>
      _service.streamPendingReports();

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> submitReport(ReportModel report) async {
    state = ReportState.submitting;
    error = null;
    notifyListeners();
    try {
      await _service.submitReport(report);
      state = ReportState.submitted;
    } catch (e) {
      error = e.toString();
      state = ReportState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadReportsByCommunity(String communityId) => _run(() async {
        reports = await _service.getReportsByCommunity(communityId);
      });

  Future<void> updateReportStatus(
    String reportId,
    ReportStatus status,
  ) =>
      _run(() async {
        final uid = _auth.currentUser?.uid ?? '';
        await _service.updateReportStatus(reportId, status, uid);
      });

  // ── Helper ─────────────────────────────────────────────────────────────────

  Future<void> _run(Future<void> Function() action) async {
    state = ReportState.loading;
    error = null;
    notifyListeners();
    try {
      await action();
      state = ReportState.idle;
    } catch (e) {
      error = e.toString();
      state = ReportState.error;
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pendingSub?.cancel();
    super.dispose();
  }
}
