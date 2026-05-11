import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendee_model.dart';
import '../models/event_model.dart';

class AttendeeService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  AttendeeService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ── Collection refs ────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _attendees(
          String communityId, String eventId) =>
      _db
          .collection('communities')
          .doc(communityId)
          .collection('events')
          .doc(eventId)
          .collection('attendees');

  CollectionReference<Map<String, dynamic>> _events(String communityId) =>
      _db.collection('communities').doc(communityId).collection('events');

  // ── Read ───────────────────────────────────────────────────────────────────

  Stream<List<AttendeeModel>> getAttendees(
      String communityId, String eventId) {
    return _attendees(communityId, eventId)
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AttendeeModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<bool> isAttending(String communityId, String eventId) async {
    final user = _requireAuth();
    final doc = await _attendees(communityId, eventId).doc(user.uid).get();
    return doc.exists;
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> joinEvent(String communityId, String eventId) async {
    final user = _requireAuth();

    final eventDoc = await _events(communityId).doc(eventId).get();
    if (!eventDoc.exists) throw Exception('Event not found');
    final event = EventModel.fromDoc(eventDoc);
    if (event.isFull) throw Exception('Event is full');

    final alreadyIn =
        await _attendees(communityId, eventId).doc(user.uid).get();
    if (alreadyIn.exists) throw Exception('Already attending this event');

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final displayName =
        userDoc.data()?['displayName'] as String? ?? 'User';
    final avatarUrl = userDoc.data()?['avatarUrl'] as String?;

    final batch = _db.batch();
    batch.set(_attendees(communityId, eventId).doc(user.uid), {
      'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'joinedAt': FieldValue.serverTimestamp(),
      'role': 'attendee',
    });
    batch.update(_events(communityId).doc(eventId), {
      'attendees': FieldValue.arrayUnion([user.uid]),
    });
    await batch.commit();
  }

  Future<void> leaveEvent(String communityId, String eventId) async {
    final user = _requireAuth();

    final doc =
        await _attendees(communityId, eventId).doc(user.uid).get();
    if (!doc.exists) throw Exception('Not attending this event');

    final attendee = AttendeeModel.fromJson(doc.data()!, doc.id);
    if (attendee.isHost) throw Exception('Host cannot leave the event');

    final batch = _db.batch();
    batch.delete(_attendees(communityId, eventId).doc(user.uid));
    batch.update(_events(communityId).doc(eventId), {
      'attendees': FieldValue.arrayRemove([user.uid]),
    });
    await batch.commit();
  }

  // ── Internal helpers (used by EventService on create) ─────────────────────

  Future<void> seedHost(
    String communityId,
    String eventId,
    String uid,
  ) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName =
        userDoc.data()?['displayName'] as String? ?? 'User';
    final avatarUrl = userDoc.data()?['avatarUrl'] as String?;

    await _attendees(communityId, eventId).doc(uid).set({
      'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'joinedAt': FieldValue.serverTimestamp(),
      'role': 'host',
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  User _requireAuth() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return user;
  }
}
