import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  EventService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _events(String communityId) =>
      _db.collection('communities').doc(communityId).collection('events');

  Stream<List<EventModel>> getEvents(String communityId) {
    return _events(communityId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EventModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Collection-group query across all communities' events subcollections.
  // Returns only events where isPublished == true, ordered by start date.
  // Requires a Firestore composite index: isPublished ASC + startDate ASC.
  Stream<List<EventModel>> getPublishedEvents() {
    return _db
        .collectionGroup('events')
        .where('isPublished', isEqualTo: true)
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EventModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> createEvent(
    String communityId, {
    required String title,
    required String hostName,
    required DateTime startDate,
    required DateTime endDate,
    required String location,
    required String detail,
    required int memberLimit,
    String coverImageUrl = '',
    bool isPublished = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    if (title.trim().isEmpty) throw ArgumentError('Event title must not be empty');

    await _events(communityId).add({
      'communityId': communityId,
      'title': title.trim(),
      'hostName': hostName.trim(),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'date': Timestamp.fromDate(startDate),
      'location': location.trim(),
      'detail': detail.trim(),
      'memberLimit': memberLimit,
      'coverImageUrl': coverImageUrl,
      'createdById': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'isPublished': isPublished,
    });
  }
}
