import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  PaymentService({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // ── Collection ref ─────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _payments(
          String communityId, String eventId, String billId) =>
      _db
          .collection('communities')
          .doc(communityId)
          .collection('events')
          .doc(eventId)
          .collection('bills')
          .doc(billId)
          .collection('payments');

  // ── Payments ───────────────────────────────────────────────────────────────

  Future<Payment> submitPayment({
    required String communityId,
    required String eventId,
    required String billId,
    required String payerUid,
    required String payerName,
    required double amount,
    required Uint8List slipImageBytes,
    required String imageFileName,
  }) async {
    try {
      final storagePath =
          'event_payments/$communityId/$eventId/$billId/$payerUid/$imageFileName';
      final ref = _storage.ref(storagePath);
      await ref.putData(
        slipImageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final receiptUrl = await ref.getDownloadURL();

      final now = DateTime.now();
      final payment = Payment(
        paymentId: '',
        billId: billId,
        userId: payerUid,
        displayName: payerName,
        amountDue: amount,
        receiptUrl: receiptUrl,
        status: PaymentStatus.pending,
        aiVerification: AiVerification(expectedAmount: amount),
        submittedAt: now,
        updatedAt: now,
      );
      final docRef = _payments(communityId, eventId, billId).doc();
      await docRef.set(payment.toFirestore());
      final doc = await docRef.get();
      return Payment.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw Exception('Firebase error submitting payment: ${e.message}');
    }
  }

  Future<void> updatePaymentVerification({
    required String communityId,
    required String eventId,
    required String billId,
    required String paymentId,
    required PaymentStatus status,
    required AiVerification verification,
  }) async {
    try {
      await _payments(communityId, eventId, billId).doc(paymentId).update({
        'status': status.name,
        'aiVerification': verification.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Firebase error updating verification: ${e.message}');
    }
  }

  Stream<List<Payment>> watchPayments({
    required String communityId,
    required String eventId,
    required String billId,
  }) {
    return _payments(communityId, eventId, billId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Payment.fromFirestore).toList());
  }

  Future<Payment?> getPaymentForPayer({
    required String communityId,
    required String eventId,
    required String billId,
    required String payerUid,
  }) async {
    try {
      final snap = await _payments(communityId, eventId, billId)
          .where('userId', isEqualTo: payerUid)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return Payment.fromFirestore(snap.docs.first);
    } on FirebaseException catch (e) {
      throw Exception('Firebase error fetching payment: ${e.message}');
    }
  }

  Future<void> deletePayment({
    required String communityId,
    required String eventId,
    required String billId,
    required String paymentId,
    required String slipStoragePath,
  }) async {
    try {
      await _payments(communityId, eventId, billId).doc(paymentId).delete();
      await _storage.ref(slipStoragePath).delete();
    } on FirebaseException catch (e) {
      throw Exception('Firebase error deleting payment: ${e.message}');
    }
  }

  // Real-time stream of a single payer's payment — used by the attendee view
  // so status updates (verifying → verified/rejected) arrive without polling.
  Stream<Payment?> watchPaymentForPayer({
    required String communityId,
    required String eventId,
    required String billId,
    required String payerUid,
  }) {
    return _payments(communityId, eventId, billId)
        .where('userId', isEqualTo: payerUid)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : Payment.fromFirestore(snap.docs.first));
  }

  // Set status to verifying before AI processes the slip.
  Future<void> markAsVerifying({
    required String communityId,
    required String eventId,
    required String billId,
    required String paymentId,
  }) async {
    try {
      await _payments(communityId, eventId, billId).doc(paymentId).update({
        'status': PaymentStatus.verifying.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Firebase error marking verifying: ${e.message}');
    }
  }
}
