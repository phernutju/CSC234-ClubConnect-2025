import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service;

  List<Payment> payments = [];
  Payment? myPayment;
  bool isSubmitting = false;
  bool isLoading = false;
  String? errorMessage;

  StreamSubscription<List<Payment>>? _paymentsSub;
  StreamSubscription<Payment?>? _myPaymentSub;

  PaymentProvider({PaymentService? service})
      : _service = service ?? PaymentService();

  // ── Payments stream ────────────────────────────────────────────────────────

  Future<void> loadPayments(
      String communityId, String eventId, String billId) async {
    _paymentsSub?.cancel();
    _paymentsSub = _service
        .watchPayments(
          communityId: communityId,
          eventId: eventId,
          billId: billId,
        )
        .listen(
          (list) {
            payments = list;
            notifyListeners();
          },
          onError: (Object e) {
            errorMessage = e.toString();
            notifyListeners();
          },
        );
  }

  // ── My payment stream ──────────────────────────────────────────────────────

  // Real-time subscription — attendee view updates live as AI verifies slip.
  void watchMyPayment({
    required String communityId,
    required String eventId,
    required String billId,
    required String payerUid,
  }) {
    _myPaymentSub?.cancel();
    _myPaymentSub = _service
        .watchPaymentForPayer(
          communityId: communityId,
          eventId: eventId,
          billId: billId,
          payerUid: payerUid,
        )
        .listen(
          (payment) {
            myPayment = payment;
            notifyListeners();
          },
          onError: (Object e) {
            errorMessage = e.toString();
            notifyListeners();
          },
        );
  }

  // ── Payment actions ────────────────────────────────────────────────────────

  Future<void> loadMyPayment({
    required String communityId,
    required String eventId,
    required String billId,
    required String payerUid,
  }) =>
      _run(() async {
        myPayment = await _service.getPaymentForPayer(
          communityId: communityId,
          eventId: eventId,
          billId: billId,
          payerUid: payerUid,
        );
      });

  Future<void> submitPayment({
    required String communityId,
    required String eventId,
    required String billId,
    required String payerUid,
    required String payerName,
    required double amount,
    required Uint8List slipImageBytes,
    required String imageFileName,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      myPayment = await _service.submitPayment(
        communityId: communityId,
        eventId: eventId,
        billId: billId,
        payerUid: payerUid,
        payerName: payerName,
        amount: amount,
        slipImageBytes: slipImageBytes,
        imageFileName: imageFileName,
      );
      // TODO: call GeminiService.verifyPaymentSlip(myPayment!) here,
      // then call verifyPayment() with the returned AiVerification result.
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> verifyPayment({
    required String communityId,
    required String eventId,
    required String billId,
    required String paymentId,
    required PaymentStatus status,
    required AiVerification verification,
  }) =>
      _run(() => _service.updatePaymentVerification(
            communityId: communityId,
            eventId: eventId,
            billId: billId,
            paymentId: paymentId,
            status: status,
            verification: verification,
          ));

  Future<void> markAsVerifying({
    required String communityId,
    required String eventId,
    required String billId,
    required String paymentId,
  }) =>
      _run(() => _service.markAsVerifying(
            communityId: communityId,
            eventId: eventId,
            billId: billId,
            paymentId: paymentId,
          ));

  Future<void> deletePayment({
    required String communityId,
    required String eventId,
    required String billId,
    required String paymentId,
    required String slipStoragePath,
  }) =>
      _run(() => _service.deletePayment(
            communityId: communityId,
            eventId: eventId,
            billId: billId,
            paymentId: paymentId,
            slipStoragePath: slipStoragePath,
          ));

  void clearPayments() {
    _paymentsSub?.cancel();
    _myPaymentSub?.cancel();
    _paymentsSub = null;
    _myPaymentSub = null;
    payments = [];
    myPayment = null;
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
    _paymentsSub?.cancel();
    _myPaymentSub?.cancel();
    super.dispose();
  }
}
