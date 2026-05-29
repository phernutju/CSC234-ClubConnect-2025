import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../models/smart_bill_model.dart';
import '../services/smart_bill_service.dart';
import '../services/notification_service.dart';

class SmartBillProvider extends ChangeNotifier {
  final SmartBillService _service;
  final NotificationService _notifications;

  SmartBillModel? bill;
  List<SmartBillItemModel> items = [];
  SmartPaymentModel? myPayment;
  AiVerificationResult? lastVerification;
  List<SmartPaymentModel> allPayments = [];

  bool isLoading = false;
  bool isVerifying = false;
  String? error;

  StreamSubscription<SmartBillModel?>? _billSub;
  StreamSubscription<List<SmartBillItemModel>>? _itemsSub;
  StreamSubscription<SmartPaymentModel?>? _paymentSub;
  StreamSubscription<List<SmartPaymentModel>>? _allPaymentsSub;

  SmartBillProvider({
    SmartBillService? service,
    NotificationService? notificationService,
  })  : _service = service ?? SmartBillService(),
        _notifications = notificationService ?? NotificationService();

  // ── Streams ───────────────────────────────────────────────────────────────

  void loadBill(String communityId, String eventId, String billId) {
    _billSub?.cancel();
    _itemsSub?.cancel();

    _billSub = _service.streamBill(communityId, eventId, billId).listen(
      (b) {
        bill = b;
        notifyListeners();
      },
      onError: _onError,
    );

    _itemsSub = _service.streamItems(communityId, eventId, billId).listen(
      (list) {
        items = list;
        notifyListeners();
      },
      onError: _onError,
    );
  }

  void loadBillByEvent(String communityId, String eventId) {
    _billSub?.cancel();
    _itemsSub?.cancel();

    _billSub = _service.streamBillByEvent(communityId, eventId).listen(
      (b) {
        final prevId = bill?.id;
        bill = b;
        notifyListeners();
        if (b != null && b.id != prevId) {
          _itemsSub?.cancel();
          _itemsSub = _service.streamItems(communityId, eventId, b.id).listen(
            (list) {
              items = list;
              notifyListeners();
            },
            onError: _onError,
          );
        } else if (b == null) {
          _itemsSub?.cancel();
          items = [];
          notifyListeners();
        }
      },
      onError: _onError,
    );
  }

  Future<SmartBillModel?> fetchBillByEvent(
          String communityId, String eventId) =>
      _service.getBillByEvent(communityId, eventId);

  void loadMyPayment(
      String communityId, String eventId, String billId, String userId) {
    _paymentSub?.cancel();
    _paymentSub = _service
        .streamPaymentByUser(communityId, eventId, billId, userId)
        .listen(
      (p) {
        myPayment = p;
        notifyListeners();
      },
      onError: _onError,
    );
  }

  void loadAllPayments(String communityId, String eventId, String billId) {
    _allPaymentsSub?.cancel();
    _allPaymentsSub =
        _service.streamAllPayments(communityId, eventId, billId).listen(
      (list) {
        allPayments = list;
        notifyListeners();
      },
      onError: _onError,
    );
  }

  Future<bool> deleteBill(
      String communityId, String eventId, String billId) async {
    try {
      await _service.deleteBill(communityId, eventId, billId);
      return true;
    } catch (e, st) {
      error = e.toString();
      _recordError(e, st, 'deleteBill', info: [
        'communityId=$communityId',
        'eventId=$eventId',
        'billId=$billId'
      ]);
      notifyListeners();
      return false;
    }
  }

  Future<bool> settleBill(
      String communityId, String eventId, String billId) async {
    if (!canSettle) return false;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _service.settleBill(communityId, eventId, billId);
      return true;
    } catch (e, st) {
      error = e.toString();
      _recordError(e, st, 'settleBill', info: [
        'communityId=$communityId',
        'eventId=$eventId',
        'billId=$billId'
      ]);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyMemberPayment(
      String communityId, String eventId, String billId, String userId) async {
    try {
      await _service.verifyPaymentManually(
          communityId, eventId, billId, userId);
    } catch (e, st) {
      error = e.toString();
      _recordError(e, st, 'verifyMemberPayment',
          info: ['billId=$billId', 'userId=$userId']);
      notifyListeners();
    }
  }

  Future<void> rejectMemberPayment(
      String communityId, String eventId, String billId, String userId) async {
    try {
      await _service.rejectPaymentManually(
          communityId, eventId, billId, userId);
    } catch (e, st) {
      error = e.toString();
      _recordError(e, st, 'rejectMemberPayment',
          info: ['billId=$billId', 'userId=$userId']);
      notifyListeners();
    }
  }

  Future<void> unverifyMemberPayment(
      String communityId, String eventId, String billId, String userId) async {
    try {
      await _service.unverifyPaymentManually(
          communityId, eventId, billId, userId);
    } catch (e, st) {
      error = e.toString();
      _recordError(e, st, 'unverifyMemberPayment',
          info: ['billId=$billId', 'userId=$userId']);
      notifyListeners();
    }
  }

  // ── Mock injection ────────────────────────────────────────────────────────

  // TODO: replace with Firestore data — remove this method when live
  void loadMock({
    required SmartBillModel mockBill,
    required List<SmartBillItemModel> mockItems,
  }) {
    bill = mockBill;
    items = mockItems;
    notifyListeners();
  }

  // ── Create & Publish ──────────────────────────────────────────────────────

  Future<SmartBillModel?> createAndPublishBill({
    required String communityId,
    required String eventId,
    required String hostId,
    required String name,
    required List<SmartBillMember> members,
    required List<SmartBillItemModel> billItems,
    Uint8List? qrImageBytes,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final total = billItems.fold(0.0, (s, i) => s + i.price);
      var created = await _service.createBill(
        communityId,
        eventId,
        SmartBillModel(
          id: '',
          eventId: eventId,
          name: name,
          hostId: hostId,
          members: members,
          totalAmount: total,
          status: SmartBillStatus.published,
          createdAt: DateTime.now(),
        ),
      );

      if (qrImageBytes != null && qrImageBytes.isNotEmpty) {
        final url = await _service.uploadQrImage(
            communityId, eventId, created.id, qrImageBytes);
        created = created.copyWith(hostPromptPayQrUrl: url);
        await _service.updateBill(communityId, eventId, created);
      }

      for (final item in billItems) {
        await _service.addItem(communityId, eventId, created.id, item);
      }

      // Compute per-member share from items and create a pending payment for each member
      final Map<String, double> memberAmounts = {};
      for (final item in billItems) {
        if (item.payerIds.isEmpty) continue;
        final share = item.price / item.payerIds.length;
        for (final uid in item.payerIds) {
          memberAmounts[uid] = (memberAmounts[uid] ?? 0) + share;
        }
      }
      for (final member in members) {
        await _service.createPayment(
          communityId,
          eventId,
          created.id,
          SmartPaymentModel(
            id: member.uid,
            userId: member.uid,
            amountDue: memberAmounts[member.uid] ?? 0,
            // Host receives money — no slip needed; auto-verify their share
            status: member.uid == hostId ? 'verified' : 'pending',
          ),
        );
      }

      bill = created;
      return created;
    } catch (e, st) {
      error = e.toString();
      _recordError(e, st, 'createAndPublishBill', info: [
        'communityId=$communityId',
        'eventId=$eventId',
        'hostId=$hostId'
      ]);
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Update & Publish ──────────────────────────────────────────────────────

  Future<SmartBillModel?> updateAndPublishBill({
    required String communityId,
    required String eventId,
    required SmartBillModel existingBill,
    required String name,
    required List<SmartBillMember> members,
    required List<SmartBillItemModel> billItems,
    Uint8List? qrImageBytes,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final total = billItems.fold(0.0, (s, i) => s + i.price);

      String qrUrl = existingBill.hostPromptPayQrUrl;
      if (qrImageBytes != null && qrImageBytes.isNotEmpty) {
        qrUrl = await _service.uploadQrImage(
            communityId, eventId, existingBill.id, qrImageBytes);
      }

      final updated = existingBill.copyWith(
        name: name,
        members: members,
        totalAmount: total,
        hostPromptPayQrUrl: qrUrl,
      );
      await _service.updateBill(communityId, eventId, updated);

      // Replace all items
      final oldItems =
          await _service.getItems(communityId, eventId, existingBill.id);
      for (final item in oldItems) {
        await _service.deleteItem(
            communityId, eventId, existingBill.id, item.id);
      }
      for (final item in billItems) {
        await _service.addItem(communityId, eventId, existingBill.id, item);
      }

      // Recalculate per-member amounts and reset payments
      final Map<String, double> memberAmounts = {};
      for (final item in billItems) {
        if (item.payerIds.isEmpty) continue;
        final share = item.price / item.payerIds.length;
        for (final uid in item.payerIds) {
          memberAmounts[uid] = (memberAmounts[uid] ?? 0) + share;
        }
      }
      for (final member in members) {
        await _service.createPayment(
          communityId,
          eventId,
          existingBill.id,
          SmartPaymentModel(
            id: member.uid,
            userId: member.uid,
            amountDue: memberAmounts[member.uid] ?? 0,
            status: member.uid == existingBill.hostId ? 'verified' : 'pending',
          ),
        );
      }

      bill = updated;
      return updated;
    } catch (e, st) {
      error = e.toString();
      _recordError(e, st, 'updateAndPublishBill', info: [
        'communityId=$communityId',
        'eventId=$eventId',
        'billId=${existingBill.id}'
      ]);
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Payment ───────────────────────────────────────────────────────────────

  Future<AiVerificationResult?> submitAndVerify({
    required String communityId,
    required String eventId,
    required String billId,
    required String userId,
    required double amountDue,
    required Uint8List slipBytes,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // Verify with AI first, then upload regardless — fake slips saved as 'review'
      final result = await _service.verifySlip(slipBytes, amountDue);
      lastVerification = result;

      final url = await _service.uploadSlip(
          communityId, eventId, billId, userId, slipBytes);

      final finalStatus = result.isMatch ? 'verified' : 'review';

      await _service.createPayment(
        communityId,
        eventId,
        billId,
        SmartPaymentModel(
          id: userId,
          userId: userId,
          amountDue: amountDue,
          receiptUrl: url,
          status: finalStatus,
          aiVerification: result,
        ),
      );

      // Best-effort: notify host of verification result.
      try {
        final hostId = bill?.hostId;
        if (hostId != null && hostId.isNotEmpty) {
          final payerName = (bill?.members ?? const [])
              .firstWhere(
                (m) => m.uid == userId,
                orElse: () => const SmartBillMember(uid: '', name: 'Member'),
              )
              .name;
          final displayName = payerName.isEmpty ? 'Member' : payerName;
          final amountStr = amountDue.toStringAsFixed(2);
          final isVerified = result.isMatch;
          await _notifications.createNotification(hostId, {
            'communityId': communityId,
            'mentionedBy': userId,
            'title': isVerified
                ? '$displayName has paid'
                : '$displayName payment was rejected',
            'description': isVerified
                ? 'Payment of $amountStr has been verified successfully'
                : 'Payment of $amountStr could not be verified. Amount or recipient did not match.',
            'type': 'system',
          });
        }
      } catch (_) {
        // Notification is best-effort; failures must not affect payment flow.
      }

      notifyListeners();
      return result;
    } catch (e, st) {
      error = e.toString();
      _recordError(e, st, 'submitAndVerify', info: [
        'communityId=$communityId',
        'eventId=$eventId',
        'billId=$billId',
        'userId=$userId',
        'amountDue=$amountDue',
      ]);
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<SmartPaymentModel?> submitPaymentWithSlip({
    required String communityId,
    required String eventId,
    required String billId,
    required String userId,
    required double amountDue,
    required Uint8List slipBytes,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final url = await _service.uploadSlip(
          communityId, eventId, billId, userId, slipBytes);
      final payment = await _service.createPayment(
        communityId,
        eventId,
        billId,
        SmartPaymentModel(
          id: userId,
          userId: userId,
          amountDue: amountDue,
          receiptUrl: url,
          status: 'verifying',
        ),
      );
      myPayment = payment;
      return payment;
    } catch (e, st) {
      error = e.toString();
      _recordError(e, st, 'submitPaymentWithSlip', info: [
        'communityId=$communityId',
        'eventId=$eventId',
        'billId=$billId',
        'userId=$userId',
      ]);
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<AiVerificationResult?> verifySlip(
      Uint8List slipBytes, double expectedAmount) async {
    isVerifying = true;
    error = null;
    notifyListeners();
    try {
      final result = await _service.verifySlip(slipBytes, expectedAmount);
      lastVerification = result;
      return result;
    } catch (e, st) {
      error = e.toString();
      _recordError(e, st, 'verifySlip', info: [
        'expectedAmount=$expectedAmount',
        'slipBytes=${slipBytes.length}'
      ]);
      return null;
    } finally {
      isVerifying = false;
      notifyListeners();
    }
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  Map<String, double> getMemberTotals() {
    final totals = <String, double>{};
    for (final item in items) {
      for (final uid in item.payerIds) {
        totals[uid] = (totals[uid] ?? 0) + item.pricePerPayer;
      }
    }
    return totals;
  }

  double getMemberShare(String uid) => getMemberTotals()[uid] ?? 0;

  bool get canSettle =>
      bill != null &&
      bill!.status == SmartBillStatus.published &&
      bill!.members.isNotEmpty &&
      allPayments.length >= bill!.members.length &&
      allPayments.every((p) => p.status == 'verified');

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _onError(Object e, [StackTrace? st]) {
    error = e.toString();
    FirebaseCrashlytics.instance.recordError(
      e,
      st,
      reason: 'SmartBillProvider stream error',
    );
    notifyListeners();
  }

  void _recordError(
    Object e,
    StackTrace st,
    String op, {
    List<Object> info = const [],
  }) {
    FirebaseCrashlytics.instance.recordError(
      e,
      st,
      reason: 'SmartBillProvider.$op failed',
      information: info,
    );
  }

  void clearBill() {
    _billSub?.cancel();
    _itemsSub?.cancel();
    _paymentSub?.cancel();
    _allPaymentsSub?.cancel();
    bill = null;
    items = [];
    myPayment = null;
    allPayments = [];
    lastVerification = null;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _billSub?.cancel();
    _itemsSub?.cancel();
    _paymentSub?.cancel();
    _allPaymentsSub?.cancel();
    super.dispose();
  }
}
