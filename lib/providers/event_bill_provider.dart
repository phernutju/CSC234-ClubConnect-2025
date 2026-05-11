import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/event_bill_item.dart';
import '../models/event_bill_model.dart';
import '../services/event_bill_service.dart';

class EventBillProvider extends ChangeNotifier {
  final EventBillService _service;

  EventBill? currentBill;
  List<BillItem> billItems = [];
  bool isLoading = false;
  String? errorMessage;

  StreamSubscription<EventBill>? _billSub;
  StreamSubscription<List<BillItem>>? _itemsSub;

  EventBillProvider({EventBillService? service})
      : _service = service ?? EventBillService();

  // ── Bill stream ────────────────────────────────────────────────────────────

  Future<void> loadBill(
      String communityId, String eventId, String billId) async {
    _billSub?.cancel();
    _itemsSub?.cancel();

    _billSub = _service
        .watchBill(
          communityId: communityId,
          eventId: eventId,
          billId: billId,
        )
        .listen(
          (bill) {
            currentBill = bill;
            notifyListeners();
          },
          onError: (Object e) {
            errorMessage = e.toString();
            notifyListeners();
          },
        );

    _itemsSub = _service
        .watchItems(
          communityId: communityId,
          eventId: eventId,
          billId: billId,
        )
        .listen(
          (items) {
            billItems = items;
            notifyListeners();
          },
          onError: (Object e) {
            errorMessage = e.toString();
            notifyListeners();
          },
        );
  }

  // ── Bill actions ───────────────────────────────────────────────────────────

  Future<void> createBill({
    required String communityId,
    required String eventId,
    required String title,
    required String createdByUid,
    required String hostName,
    required List<String> memberUids,
  }) =>
      _run(() async {
        currentBill = await _service.createBill(
          communityId: communityId,
          eventId: eventId,
          title: title,
          createdByUid: createdByUid,
          hostName: hostName,
          memberUids: memberUids,
        );
      });

  Future<void> addItem({
    required String communityId,
    required String eventId,
    required String billId,
    required String name,
    required double totalPrice,
    required int payerCount,
  }) =>
      _run(() => _service.addItem(
            communityId: communityId,
            eventId: eventId,
            billId: billId,
            name: name,
            totalPrice: totalPrice,
            payerCount: payerCount,
          ));

  Future<void> removeItem({
    required String communityId,
    required String eventId,
    required String billId,
    required String itemId,
  }) =>
      _run(() => _service.removeItem(
            communityId: communityId,
            eventId: eventId,
            billId: billId,
            itemId: itemId,
          ));

  Future<void> updateBillStatus({
    required String communityId,
    required String eventId,
    required String billId,
    required BillStatus status,
  }) =>
      _run(() => _service.updateBillStatus(
            communityId: communityId,
            eventId: eventId,
            billId: billId,
            status: status,
          ));

  Future<void> deleteBill({
    required String communityId,
    required String eventId,
    required String billId,
  }) =>
      _run(() => _service.deleteBill(
            communityId: communityId,
            eventId: eventId,
            billId: billId,
          ));

  void clearBill() {
    _billSub?.cancel();
    _itemsSub?.cancel();
    _billSub = null;
    _itemsSub = null;
    currentBill = null;
    billItems = [];
    errorMessage = null;
    notifyListeners();
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _billSub?.cancel();
    _itemsSub?.cancel();
    super.dispose();
  }
}
