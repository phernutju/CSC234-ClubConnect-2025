import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/event_bill_model.dart';

class BillService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  BillService({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // ── Refs ──────────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _bills(
          String communityId, String eventId) =>
      _db
          .collection('communities')
          .doc(communityId)
          .collection('events')
          .doc(eventId)
          .collection('event_bills');

  CollectionReference<Map<String, dynamic>> _participants(
          String communityId, String eventId, String billId) =>
      _bills(communityId, eventId).doc(billId).collection('participants');

  // ── Bills CRUD ────────────────────────────────────────────────────────────────

  Future<String> createBill(
      String communityId, String eventId, EventBillModel bill) async {
    final ref = _bills(communityId, eventId).doc();
    await ref.set(bill.toMap());
    return ref.id;
  }

  Future<void> updateBill(
      String communityId, String eventId, EventBillModel bill) async {
    await _bills(communityId, eventId).doc(bill.id).update(bill.toMap());
  }

  Future<void> deleteBill(
      String communityId, String eventId, String billId) async {
    final participantSnap =
        await _participants(communityId, eventId, billId).get();
    final batch = _db.batch();
    for (final doc in participantSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_bills(communityId, eventId).doc(billId));
    await batch.commit();
  }

  Future<List<EventBillModel>> fetchBills(
      String communityId, String eventId) async {
    final snap = await _bills(communityId, eventId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((doc) => EventBillModel.fromFirestore(doc))
        .toList();
  }

  Stream<List<EventBillModel>> streamBills(
      String communityId, String eventId) {
    return _bills(communityId, eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => EventBillModel.fromFirestore(doc)).toList());
  }

  Future<EventBillModel?> fetchBillById(
      String communityId, String eventId, String billId) async {
    final doc = await _bills(communityId, eventId).doc(billId).get();
    if (!doc.exists) return null;
    return EventBillModel.fromFirestore(doc);
  }

  // ── Participants ──────────────────────────────────────────────────────────────

  Future<void> addParticipant(String communityId, String eventId,
      String billId, BillParticipantModel participant) async {
    await _participants(communityId, eventId, billId)
        .doc(participant.userId)
        .set(participant.toMap());
  }

  Future<void> updateParticipant(String communityId, String eventId,
      String billId, BillParticipantModel participant) async {
    await _participants(communityId, eventId, billId)
        .doc(participant.userId)
        .update(participant.toMap());
  }

  Future<void> removeParticipant(String communityId, String eventId,
      String billId, String userId) async {
    await _participants(communityId, eventId, billId).doc(userId).delete();
  }

  Future<List<BillParticipantModel>> fetchParticipants(
      String communityId, String eventId, String billId) async {
    final snap = await _participants(communityId, eventId, billId).get();
    return snap.docs
        .map((doc) => BillParticipantModel.fromFirestore(doc))
        .toList();
  }

  Stream<List<BillParticipantModel>> streamParticipants(
      String communityId, String eventId, String billId) {
    return _participants(communityId, eventId, billId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BillParticipantModel.fromFirestore(doc))
            .toList());
  }

  Future<void> markAsPaid(String communityId, String eventId, String billId,
      String userId) async {
    await _participants(communityId, eventId, billId).doc(userId).update({
      'isPaid': true,
      'paidAt': Timestamp.now(),
    });
  }

  Future<void> markAsUnpaid(String communityId, String eventId, String billId,
      String userId) async {
    await _participants(communityId, eventId, billId).doc(userId).update({
      'isPaid': false,
      'paidAt': null,
    });
  }

  // ── Status sync ───────────────────────────────────────────────────────────────

  Future<void> syncBillStatus(String communityId, String eventId,
      String billId, List<BillParticipantModel> participants) async {
    final BillStatus derived;
    if (participants.isEmpty) {
      derived = BillStatus.pending;
    } else {
      final paidCount = participants.where((p) => p.isPaid).length;
      if (paidCount == 0) {
        derived = BillStatus.pending;
      } else if (paidCount == participants.length) {
        derived = BillStatus.settled;
      } else {
        derived = BillStatus.partial;
      }
    }

    final doc = await _bills(communityId, eventId).doc(billId).get();
    if (!doc.exists) return;
    final current = BillStatus.values.firstWhere(
      (e) => e.name == (doc.data()?['status'] as String?),
      orElse: () => BillStatus.pending,
    );
    if (current == derived) return;

    await _bills(communityId, eventId)
        .doc(billId)
        .update({'status': derived.name});
  }

  // ── QR upload ─────────────────────────────────────────────────────────────────

  Future<String> uploadQrImage(String communityId, String eventId,
      String billId, Uint8List bytes) async {
    final ref = _storage
        .ref()
        .child('bill_qr/$communityId/$eventId/$billId/qr.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _bills(communityId, eventId)
        .doc(billId)
        .update({'qrImageUrl': url});
    return url;
  }
}
