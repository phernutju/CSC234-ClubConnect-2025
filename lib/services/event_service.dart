import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  EventService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ── Collection refs ────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _events(String communityId) =>
      _db.collection('community').doc(communityId).collection('events');

  // ── Events ─────────────────────────────────────────────────────────────────

  Stream<List<EventModel>> getEvents(String communityId) {
    return _events(communityId)
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => EventModel.fromDoc(doc))
              .toList(),
        );
  }

  Future<void> createEvent({
    required String communityId,
    required String title,
    required String description,
    required List<CategoryModel> tags,
    required Timestamp date,
    required Timestamp endDate,
    required String roomId,
    String? imageUrl,
    int? maxAttendees,
  }) async {
    final user = _requireAuth();
    final eventRef = _events(communityId).doc();

    await eventRef.set({
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'createdBy': user.uid,
      'attendees': [user.uid],
      'tags': tags.map((t) => t.toJson()).toList(),
      'roomId': roomId,
      'maxAttendees': maxAttendees,
      'date': date,
      'endDate': endDate,
    });
  }

  Future<void> joinEvent(String communityId, String eventId) async {
    final user = _requireAuth();
    final eventRef = _events(communityId).doc(eventId);
    final doc = await eventRef.get();

    if (!doc.exists) throw Exception('Event not found');

    final event = EventModel.fromDoc(doc);
    if (event.isFull) throw Exception('Event is full');
    if (event.isAttending(user.uid)) throw Exception('Already attending this event');

    await eventRef.update({
      'attendees': FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> leaveEvent(String communityId, String eventId) async {
    final user = _requireAuth();
    final eventRef = _events(communityId).doc(eventId);
    final doc = await eventRef.get();

    if (!doc.exists) throw Exception('Event not found');

    final event = EventModel.fromDoc(doc);
    if (!event.isAttending(user.uid)) throw Exception('Not attending this event');

    await eventRef.update({
      'attendees': FieldValue.arrayRemove([user.uid]),
    });
  }

  Future<void> deleteEvent(String communityId, String eventId) async {
    final user = _requireAuth();
    final doc = await _events(communityId).doc(eventId).get();

    if (!doc.exists) throw Exception('Event not found');
    if (doc.data()?['createdBy'] != user.uid) {
      throw Exception('Only the event creator can delete this event');
    }

    await _events(communityId).doc(eventId).delete();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  User _requireAuth() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return user;
  }
}
