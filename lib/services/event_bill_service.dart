import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_bill_item.dart';
import '../models/event_bill_model.dart';

class EventBillService {
  final FirebaseFirestore _db;

  EventBillService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── Collection refs ────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _bills(
          String communityId, String eventId) =>
      _db
          .collection('communities')
          .doc(communityId)
          .collection('events')
          .doc(eventId)
          .collection('bills');

  CollectionReference<Map<String, dynamic>> _items(
          String communityId, String eventId, String billId) =>
      _bills(communityId, eventId).doc(billId).collection('items');

  // ── Bills ──────────────────────────────────────────────────────────────────

  Future<EventBill> createBill({
    required String communityId,
    required String eventId,
    required String title,
    required String createdByUid,
    required String hostName,
    required List<String> memberUids,
  }) async {
    try {
      final now = DateTime.now();
      final members = memberUids
          .map((uid) => BillMember(uid: uid, displayName: ''))
          .toList();
      final bill = EventBill(
        billId: '',
        name: title,
        hostId: createdByUid,
        hostName: hostName,
        hostPromptPayQrUrl: '',
        members: members,
        totalAmount: 0,
        status: BillStatus.draft,
        createdAt: now,
        updatedAt: now,
      );
      final ref = _bills(communityId, eventId).doc();
      await ref.set(bill.toFirestore());
      final doc = await ref.get();
      return EventBill.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw Exception('Firebase error creating bill: ${e.message}');
    }
  }

  Future<BillItem> addItem({
    required String communityId,
    required String eventId,
    required String billId,
    required String name,
    required double totalPrice,
    required int payerCount,
  }) async {
    try {
      final pricePerPayer = payerCount > 0 ? totalPrice / payerCount : 0.0;
      final item = BillItem(
        itemId: '',
        name: name,
        price: totalPrice,
        payerIds: [],
        payerCount: payerCount,
        pricePerPayer: pricePerPayer,
      );
      final ref = _items(communityId, eventId, billId).doc();
      await ref.set(item.toFirestore());
      await _bills(communityId, eventId).doc(billId).update({
        'totalAmount': FieldValue.increment(totalPrice),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final doc = await ref.get();
      return BillItem.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw Exception('Firebase error adding item: ${e.message}');
    }
  }

  Future<void> removeItem({
    required String communityId,
    required String eventId,
    required String billId,
    required String itemId,
  }) async {
    try {
      final itemRef = _items(communityId, eventId, billId).doc(itemId);
      final doc = await itemRef.get();
      if (!doc.exists) return;
      final price = (doc.data()?['price'] ?? 0).toDouble();
      await itemRef.delete();
      await _bills(communityId, eventId).doc(billId).update({
        'totalAmount': FieldValue.increment(-price),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Firebase error removing item: ${e.message}');
    }
  }

  Future<EventBill?> getBill({
    required String communityId,
    required String eventId,
    required String billId,
  }) async {
    try {
      final doc = await _bills(communityId, eventId).doc(billId).get();
      if (!doc.exists) return null;
      return EventBill.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw Exception('Firebase error fetching bill: ${e.message}');
    }
  }

  Stream<EventBill> watchBill({
    required String communityId,
    required String eventId,
    required String billId,
  }) {
    return _bills(communityId, eventId)
        .doc(billId)
        .snapshots()
        .where((doc) => doc.exists)
        .map((doc) => EventBill.fromFirestore(doc));
  }

  Stream<List<BillItem>> watchItems({
    required String communityId,
    required String eventId,
    required String billId,
  }) {
    return _items(communityId, eventId, billId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(BillItem.fromFirestore).toList());
  }

  Future<void> updateBillStatus({
    required String communityId,
    required String eventId,
    required String billId,
    required BillStatus status,
  }) async {
    try {
      await _bills(communityId, eventId).doc(billId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Firebase error updating bill status: ${e.message}');
    }
  }

  Future<void> deleteBill({
    required String communityId,
    required String eventId,
    required String billId,
  }) async {
    try {
      final itemsSnap = await _items(communityId, eventId, billId).get();
      final batch = _db.batch();
      for (final doc in itemsSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_bills(communityId, eventId).doc(billId));
      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception('Firebase error deleting bill: ${e.message}');
    }
  }
}
