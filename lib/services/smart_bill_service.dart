import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/smart_bill_model.dart';

class SmartBillService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Refs ──────────────────────────────────────────────────────────────────

  CollectionReference get _bills => _db.collection('bills');
  CollectionReference _items(String billId) =>
      _bills.doc(billId).collection('items');
  CollectionReference _payments(String billId) =>
      _bills.doc(billId).collection('payments');

  // ── Bill ──────────────────────────────────────────────────────────────────

  Future<SmartBillModel> createBill(SmartBillModel bill) async {
    final ref = _bills.doc();
    final created = bill.copyWith(id: ref.id);
    await ref.set(created.toFirestore());
    return created;
  }

  Future<SmartBillModel?> getBill(String billId) async {
    final doc = await _bills.doc(billId).get();
    if (!doc.exists) return null;
    return SmartBillModel.fromFirestore(doc);
  }

  Stream<SmartBillModel?> streamBill(String billId) => _bills
      .doc(billId)
      .snapshots()
      .map((d) => d.exists ? SmartBillModel.fromFirestore(d) : null);

  Stream<SmartBillModel?> streamBillByEvent(String eventId) => _bills
      .where('eventId', isEqualTo: eventId)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : SmartBillModel.fromFirestore(s.docs.first));

  Future<void> updateBill(SmartBillModel bill) =>
      _bills.doc(bill.id).update(bill.toFirestore());

  // ── Items ─────────────────────────────────────────────────────────────────

  Future<SmartBillItemModel> addItem(
      String billId, SmartBillItemModel item) async {
    final ref = _items(billId).doc();
    final created = item.copyWith(id: ref.id);
    await ref.set(created.toFirestore());
    return created;
  }

  Future<void> updateItem(String billId, SmartBillItemModel item) =>
      _items(billId).doc(item.id).update(item.toFirestore());

  Future<void> deleteItem(String billId, String itemId) =>
      _items(billId).doc(itemId).delete();

  Future<List<SmartBillItemModel>> getItems(String billId) async {
    final snap = await _items(billId).get();
    return snap.docs
        .map((d) => SmartBillItemModel.fromFirestore(d))
        .toList();
  }

  Stream<List<SmartBillItemModel>> streamItems(String billId) =>
      _items(billId).snapshots().map((s) =>
          s.docs.map((d) => SmartBillItemModel.fromFirestore(d)).toList());

  // ── Payments ──────────────────────────────────────────────────────────────

  Future<SmartPaymentModel> createPayment(
      String billId, SmartPaymentModel payment) async {
    final ref = _payments(billId).doc(payment.userId);
    await ref.set(payment.toFirestore());
    return payment.copyWith(id: ref.id);
  }

  Future<void> updatePayment(
          String billId, SmartPaymentModel payment) =>
      _payments(billId).doc(payment.id).update(payment.toFirestore());

  Future<SmartPaymentModel?> getPaymentByUser(
      String billId, String userId) async {
    final doc = await _payments(billId).doc(userId).get();
    if (!doc.exists) return null;
    return SmartPaymentModel.fromFirestore(doc);
  }

  Stream<SmartPaymentModel?> streamPaymentByUser(
          String billId, String userId) =>
      _payments(billId).doc(userId).snapshots().map(
          (d) => d.exists ? SmartPaymentModel.fromFirestore(d) : null);

  // ── Storage ───────────────────────────────────────────────────────────────

  Future<String> uploadQrImage(String billId, Uint8List bytes) async {
    final ref = _storage.ref('bills/$billId/qr.jpg');
    final task = await ref.putData(
        bytes, SettableMetadata(contentType: 'image/jpeg'));
    return task.ref.getDownloadURL();
  }

  Future<String> uploadSlip(
      String billId, String userId, Uint8List bytes) async {
    final ref = _storage.ref('bills/$billId/slips/$userId.jpg');
    final task = await ref.putData(
        bytes, SettableMetadata(contentType: 'image/jpeg'));
    return task.ref.getDownloadURL();
  }

  // ── AI Verification stub ──────────────────────────────────────────────────

  /// Stub: simulates 2-second network delay and always returns a match.
  Future<AiVerificationResult> verifySlip(
      String slipUrl, double expectedAmount) async {
    await Future.delayed(const Duration(seconds: 2));
    final noise = 0.99 + Random().nextDouble() * 0.02;
    final detected =
        double.parse((expectedAmount * noise).toStringAsFixed(2));
    return AiVerificationResult(
      detectedAmount: detected,
      expectedAmount: expectedAmount,
      recipientMatch: true,
      result: 'match',
    );
  }
}
