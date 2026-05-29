import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/smart_bill_model.dart';
import 'ai_service.dart';

class SmartBillService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Refs ──────────────────────────────────────────────────────────────────

  CollectionReference _billsCol(String communityId, String eventId) => _db
      .collection('communities')
      .doc(communityId)
      .collection('events')
      .doc(eventId)
      .collection('event_bills');

  CollectionReference _itemsCol(
          String communityId, String eventId, String billId) =>
      _billsCol(communityId, eventId).doc(billId).collection('items');

  CollectionReference _paymentsCol(
          String communityId, String eventId, String billId) =>
      _billsCol(communityId, eventId).doc(billId).collection('payments');

  // ── Bill ──────────────────────────────────────────────────────────────────

  Future<SmartBillModel> createBill(
      String communityId, String eventId, SmartBillModel bill) async {
    final ref = _billsCol(communityId, eventId).doc();
    final created = bill.copyWith(id: ref.id);
    await ref.set(created.toFirestore());
    return created;
  }

  Future<SmartBillModel?> getBill(
      String communityId, String eventId, String billId) async {
    final doc = await _billsCol(communityId, eventId).doc(billId).get();
    if (!doc.exists) return null;
    return SmartBillModel.fromFirestore(doc);
  }

  Stream<SmartBillModel?> streamBill(
          String communityId, String eventId, String billId) =>
      _billsCol(communityId, eventId)
          .doc(billId)
          .snapshots()
          .map((d) => d.exists ? SmartBillModel.fromFirestore(d) : null);

  Stream<SmartBillModel?> streamBillByEvent(
          String communityId, String eventId) =>
      _billsCol(communityId, eventId).limit(1).snapshots().map((s) =>
          s.docs.isEmpty ? null : SmartBillModel.fromFirestore(s.docs.first));

  Future<SmartBillModel?> getBillByEvent(
      String communityId, String eventId) async {
    final snap = await _billsCol(communityId, eventId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return SmartBillModel.fromFirestore(snap.docs.first);
  }

  Future<void> updateBill(
          String communityId, String eventId, SmartBillModel bill) =>
      _billsCol(communityId, eventId).doc(bill.id).update(bill.toFirestore());

  // ── Items ─────────────────────────────────────────────────────────────────

  Future<SmartBillItemModel> addItem(String communityId, String eventId,
      String billId, SmartBillItemModel item) async {
    final ref = _itemsCol(communityId, eventId, billId).doc();
    final created = item.copyWith(id: ref.id);
    await ref.set(created.toFirestore());
    return created;
  }

  Future<void> updateItem(String communityId, String eventId, String billId,
          SmartBillItemModel item) =>
      _itemsCol(communityId, eventId, billId)
          .doc(item.id)
          .update(item.toFirestore());

  Future<void> deleteItem(
          String communityId, String eventId, String billId, String itemId) =>
      _itemsCol(communityId, eventId, billId).doc(itemId).delete();

  Future<List<SmartBillItemModel>> getItems(
      String communityId, String eventId, String billId) async {
    final snap = await _itemsCol(communityId, eventId, billId).get();
    return snap.docs.map((d) => SmartBillItemModel.fromFirestore(d)).toList();
  }

  Stream<List<SmartBillItemModel>> streamItems(
          String communityId, String eventId, String billId) =>
      _itemsCol(communityId, eventId, billId).snapshots().map((s) =>
          s.docs.map((d) => SmartBillItemModel.fromFirestore(d)).toList());

  // ── Payments ──────────────────────────────────────────────────────────────

  Future<SmartPaymentModel> createPayment(String communityId, String eventId,
      String billId, SmartPaymentModel payment) async {
    final ref = _paymentsCol(communityId, eventId, billId).doc(payment.userId);
    await ref.set(payment.toFirestore());
    return payment.copyWith(id: ref.id);
  }

  Future<void> updatePayment(String communityId, String eventId, String billId,
          SmartPaymentModel payment) =>
      _paymentsCol(communityId, eventId, billId)
          .doc(payment.id)
          .update(payment.toFirestore());

  Future<SmartPaymentModel?> getPaymentByUser(
      String communityId, String eventId, String billId, String userId) async {
    final doc =
        await _paymentsCol(communityId, eventId, billId).doc(userId).get();
    if (!doc.exists) return null;
    return SmartPaymentModel.fromFirestore(doc);
  }

  Stream<SmartPaymentModel?> streamPaymentByUser(
          String communityId, String eventId, String billId, String userId) =>
      _paymentsCol(communityId, eventId, billId)
          .doc(userId)
          .snapshots()
          .map((d) => d.exists ? SmartPaymentModel.fromFirestore(d) : null);

  Stream<List<SmartPaymentModel>> streamAllPayments(
          String communityId, String eventId, String billId) =>
      _paymentsCol(communityId, eventId, billId).snapshots().map((s) =>
          s.docs.map((d) => SmartPaymentModel.fromFirestore(d)).toList());

  Future<void> verifyPaymentManually(
          String communityId, String eventId, String billId, String userId) =>
      _paymentsCol(communityId, eventId, billId)
          .doc(userId)
          .update({'status': 'verified'});

  Future<void> rejectPaymentManually(
          String communityId, String eventId, String billId, String userId) =>
      _paymentsCol(communityId, eventId, billId)
          .doc(userId)
          .update({'status': 'rejected'});

  Future<void> unverifyPaymentManually(
          String communityId, String eventId, String billId, String userId) =>
      _paymentsCol(communityId, eventId, billId)
          .doc(userId)
          .update({'status': 'pending'});

  Future<void> deleteBill(String communityId, String eventId, String billId) =>
      _billsCol(communityId, eventId).doc(billId).delete();

  Future<void> settleBill(String communityId, String eventId, String billId) =>
      _billsCol(communityId, eventId).doc(billId).update({
        'status': SmartBillStatus.settled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ── Storage ───────────────────────────────────────────────────────────────

  Future<String> uploadQrImage(String communityId, String eventId,
      String billId, Uint8List bytes) async {
    try {
      final ref = _storage
          .ref('communities/$communityId/events/$eventId/bills/$billId/qr.jpg');
      final task =
          await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return task.ref.getDownloadURL();
    } catch (e, st) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'SmartBillService.uploadQrImage failed',
        information: [
          'communityId=$communityId',
          'eventId=$eventId',
          'billId=$billId',
          'bytes=${bytes.length}',
        ],
      );
      rethrow;
    }
  }

  Future<String> uploadSlip(String communityId, String eventId, String billId,
      String userId, Uint8List bytes) async {
    try {
      final ref = _storage.ref(
          'communities/$communityId/events/$eventId/bills/$billId/slips/$userId.jpg');
      final task =
          await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return task.ref.getDownloadURL();
    } catch (e, st) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'SmartBillService.uploadSlip failed',
        information: [
          'communityId=$communityId',
          'eventId=$eventId',
          'billId=$billId',
          'userId=$userId',
          'bytes=${bytes.length}',
        ],
      );
      rethrow;
    }
  }

  // ── AI Verification stub ──────────────────────────────────────────────────

  Future<AiVerificationResult> verifySlip(
      Uint8List slipBytes, double expectedAmount) async {
    try {
      return await GeminiService.verifyPaymentSlip(slipBytes, expectedAmount);
    } catch (e, st) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'SmartBillService.verifySlip (AI) failed',
        information: [
          'expectedAmount=$expectedAmount',
          'slipBytes=${slipBytes.length}',
        ],
      );
      rethrow;
    }
  }
}
