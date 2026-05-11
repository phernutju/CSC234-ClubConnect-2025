import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/event_bill_model.dart';
import '../services/event_bill_service.dart';

class BillProvider extends ChangeNotifier {
  final BillService _service;
  final FirebaseAuth _auth;

  List<EventBillModel> bills = [];
  EventBillModel? selectedBill;
  List<BillParticipantModel> participants = [];
  bool isLoading = false;
  String? error;

  StreamSubscription<List<EventBillModel>>? _billsSub;
  StreamSubscription<List<BillParticipantModel>>? _participantsSub;

  BillProvider({BillService? service, FirebaseAuth? auth})
      : _service = service ?? BillService(),
        _auth = auth ?? FirebaseAuth.instance;

  // ── Bills ─────────────────────────────────────────────────────────────────────

  void loadBills(String communityId, String eventId) {
    _billsSub?.cancel();
    _billsSub = _service.streamBills(communityId, eventId).listen(
      (list) {
        bills = list;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> selectBill(
      String communityId, String eventId, String billId) async {
    _participantsSub?.cancel();
    await _run(() async {
      selectedBill =
          await _service.fetchBillById(communityId, eventId, billId);
      participants =
          await _service.fetchParticipants(communityId, eventId, billId);
    });
    _participantsSub =
        _service.streamParticipants(communityId, eventId, billId).listen(
      (list) {
        participants = list;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> createBill(
      String communityId, String eventId, EventBillModel bill) async {
    _requireHost(bill.createdBy);
    await _run(() => _service.createBill(communityId, eventId, bill));
  }

  Future<void> updateBill(
      String communityId, String eventId, EventBillModel bill) async {
    _requireHost(bill.createdBy);
    await _run(() async {
      await _service.updateBill(communityId, eventId, bill);
      if (selectedBill?.id == bill.id) selectedBill = bill;
    });
  }

  Future<void> deleteBill(
      String communityId, String eventId, String billId) async {
    final host = selectedBill?.id == billId
        ? selectedBill!.createdBy
        : bills.firstWhere((b) => b.id == billId).createdBy;
    _requireHost(host);
    await _run(() async {
      await _service.deleteBill(communityId, eventId, billId);
      if (selectedBill?.id == billId) {
        selectedBill = null;
        participants = [];
      }
    });
  }

  // ── Participants ──────────────────────────────────────────────────────────────

  Future<void> addParticipant(String communityId, String eventId,
      String billId, BillParticipantModel participant) async {
    _requireHost(selectedBill?.createdBy);
    await _run(() =>
        _service.addParticipant(communityId, eventId, billId, participant));
  }

  Future<void> updateParticipant(String communityId, String eventId,
      String billId, BillParticipantModel participant) async {
    _requireHost(selectedBill?.createdBy);
    await _run(() =>
        _service.updateParticipant(communityId, eventId, billId, participant));
  }

  Future<void> removeParticipant(String communityId, String eventId,
      String billId, String userId) async {
    _requireHost(selectedBill?.createdBy);
    await _run(
        () => _service.removeParticipant(communityId, eventId, billId, userId));
  }

  Future<void> markAsPaid(String communityId, String eventId, String billId,
      String userId) async {
    await _run(() async {
      await _service.markAsPaid(communityId, eventId, billId, userId);
      final updated =
          await _service.fetchParticipants(communityId, eventId, billId);
      participants = updated;
      await _service.syncBillStatus(communityId, eventId, billId, updated);
      selectedBill =
          await _service.fetchBillById(communityId, eventId, billId);
    });
  }

  Future<void> markAsUnpaid(String communityId, String eventId, String billId,
      String userId) async {
    await _run(() async {
      await _service.markAsUnpaid(communityId, eventId, billId, userId);
      final updated =
          await _service.fetchParticipants(communityId, eventId, billId);
      participants = updated;
      await _service.syncBillStatus(communityId, eventId, billId, updated);
      selectedBill =
          await _service.fetchBillById(communityId, eventId, billId);
    });
  }

  Future<void> uploadQrImage(String communityId, String eventId,
      String billId, Uint8List bytes) async {
    _requireHost(selectedBill?.createdBy);
    await _run(() async {
      final url =
          await _service.uploadQrImage(communityId, eventId, billId, bytes);
      if (selectedBill?.id == billId) {
        selectedBill = selectedBill!.copyWith(qrImageUrl: url);
      }
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  void _requireHost(String? hostId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    if (uid != hostId) throw Exception('Only the event host can do this');
  }

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _billsSub?.cancel();
    _participantsSub?.cancel();
    super.dispose();
  }
}
