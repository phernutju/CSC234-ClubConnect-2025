import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';
import '../models/event_model.dart';
import '../models/message_model.dart';
import 'attendee_service.dart';
import 'storage_service.dart';

class EventService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final StorageService _storage;

  final AttendeeService _attendees;

  EventService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    StorageService? storage,
    AttendeeService? attendees,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? StorageService(),
        _attendees = attendees ?? AttendeeService();

  // ── Collection refs ────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _events(String communityId) =>
      _db.collection('communities').doc(communityId).collection('events');

  CollectionReference<Map<String, dynamic>> _eventMessages(
          String communityId, String eventId) =>
      _events(communityId).doc(eventId).collection('messages');

  // ── Events ─────────────────────────────────────────────────────────────────

  Stream<List<EventModel>> getEvents(String communityId) {
    final events = _events(communityId);  
    return _events(communityId)
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => EventModel.fromDoc(doc)).toList();
    });
  }

  Future<void> createEvent({
    required String communityId,
    required String title,
    required String description,
    required List<CategoryModel> tags,
    required Timestamp startDate,
    required Timestamp endDate,
    required String roomId,
    String? imageUrl,
    int? maxAttendees,
  }) async {
    try {
      final user = _requireAuth();
      final eventRef = _events(communityId).doc();
      final createdAt = FieldValue.serverTimestamp();

      await eventRef.set({
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'createdAt': createdAt,
        'createdBy': user.uid,
        'attendees': [user.uid],
        'tags': tags.map((t) => t.toJson()).toList(),
        'roomId': roomId,
        'maxAttendees': maxAttendees,
        'startDate': startDate,
        'endDate': endDate,
      });

      // Seed host in attendees subcollection (best-effort).
      await _attendees.seedHost(communityId, eventRef.id, user.uid);
    } on FirebaseException catch (e) {
      throw Exception(
        'Firebase error while creating event: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Unexpected error while creating event: $e',
      );
    }
  }

  Future<void> joinEvent(String communityId, String eventId) async {
    final user = _requireAuth();
    final eventRef = _events(communityId).doc(eventId);
    final doc = await eventRef.get();

    if (!doc.exists) throw Exception('Event not found');

    final event = EventModel.fromDoc(doc);
    if (event.isFull) throw Exception('Event is full');
    if (event.isAttending(user.uid))
      throw Exception('Already attending this event');

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
    if (!event.isAttending(user.uid))
      throw Exception('Not attending this event');

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

  // ── Event messages ─────────────────────────────────────────────────────────

  Stream<List<MessageModel>> getEventMessages(
      String communityId, String eventId) {
    return _eventMessages(communityId, eventId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MessageModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendEventMessage(
    String communityId,
    String eventId, {
    required String text,
    String imageURL = '',
    String? replyToId,
    String? replyToSenderName,
    String? replyToText,
  }) async {
    final user = _requireAuth();
    final trimmed = text.trim();
    if (trimmed.isEmpty && imageURL.isEmpty) {
      throw ArgumentError('Message must have text or an image');
    }
    await _eventMessages(communityId, eventId).add({
      'senderId': user.uid,
      'text': trimmed,
      'imageURL': imageURL,
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': [user.uid],
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (replyToText != null) 'replyToText': replyToText,
    });
  }

  Future<void> sendEventImageMessage(
    String communityId,
    String eventId, {
    required Uint8List bytes,
  }) async {
    _requireAuth();
    final imageURL = await _storage.uploadChatImage(bytes, 'event_$eventId');
    await sendEventMessage(communityId, eventId, text: '', imageURL: imageURL);
  }

  Future<void> deleteEventMessage(
      String communityId, String eventId, String messageId) async {
    final user = _requireAuth();
    final doc =
        await _eventMessages(communityId, eventId).doc(messageId).get();
    if (!doc.exists) throw Exception('Message not found');
    if (doc.data()?['senderId'] != user.uid) {
      throw Exception('Can only delete your own messages');
    }
    await _eventMessages(communityId, eventId).doc(messageId).delete();
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<String> getUserDisplayName(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['displayName'] as String? ?? 'User';
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  User _requireAuth() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return user;
  }
}
