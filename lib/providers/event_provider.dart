import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/event_model.dart';
import '../models/message_model.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _service;
  List<EventModel> events = [];
  List<MessageModel> eventMessages = [];
  List<EventModel> publishedEvents = [];
  bool isLoading = false;
  String? error;

  StreamSubscription<List<EventModel>>? _eventsSub;
  StreamSubscription<List<MessageModel>>? _eventMessagesSub;
  final Map<String, String> _nameCache = {};
  StreamSubscription<List<EventModel>>? _publishedSub;

  EventProvider({EventService? service}) : _service = service ?? EventService();

  // ── Events stream ──────────────────────────────────────────────────────────

 void loadPublishedEvents() {
    _publishedSub?.cancel();
    _publishedSub = _service.getPublishedEvents().listen(
      (list) {
        publishedEvents = list;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  void clearPublishedEvents() {
    publishedEvents = [];
    _publishedSub?.cancel();
    notifyListeners();
  }
  
  void loadEvents(String communityId) {
    _eventsSub?.cancel();
    _eventsSub = _service.getEvents(communityId).listen(
      (list) {
        events = list;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  void clearEvents() {
    events = [];
    _eventsSub?.cancel();
    _eventsSub = null;
    notifyListeners();
  }

  // ── Event chat ─────────────────────────────────────────────────────────────

  String displayNameOf(String uid) => _nameCache[uid] ?? '';

  Future<void> fetchDisplayName(String uid) async {
    if (_nameCache.containsKey(uid)) return;
    _nameCache[uid] = '';
    try {
      _nameCache[uid] = await _service.getUserDisplayName(uid);
    } catch (_) {
      _nameCache[uid] = 'User';
    }
    notifyListeners();
  }

  void loadEventMessages(String communityId, String eventId) {
    _eventMessagesSub?.cancel();
    _eventMessagesSub = _service.getEventMessages(communityId, eventId).listen(
      (list) {
        eventMessages = list;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  void clearEventMessages() {
    eventMessages = [];
    _eventMessagesSub?.cancel();
    _eventMessagesSub = null;
    notifyListeners();
  }

  Future<void> sendEventMessage(
    String communityId,
    String eventId, {
    required String text,
    String imageURL = '',
    String? replyToId,
    String? replyToSenderName,
    String? replyToText,
  }) =>
      _run(() => _service.sendEventMessage(
            communityId,
            eventId,
            text: text,
            imageURL: imageURL,
            replyToId: replyToId,
            replyToSenderName: replyToSenderName,
            replyToText: replyToText,
          ));

  Future<void> sendEventImageMessage(
          String communityId, String eventId, Uint8List bytes) =>
      _run(() =>
          _service.sendEventImageMessage(communityId, eventId, bytes: bytes));

  // ── Event actions ──────────────────────────────────────────────────────────

  Future<void> createEvent({
    required String communityId,
    required String title,
    required String description,
    required String location,
    required List<CategoryModel> tags,
    required Timestamp startDate,
    required Timestamp endDate,
    required String roomId,
    String? imageUrl,
    int? maxAttendees,
    required bool isPublished,  
  }) =>
      _run(() => _service.createEvent(
            communityId: communityId,
            title: title,
            description: description,
            location: location,
            tags: tags,
            startDate: startDate,
            endDate: endDate,
            roomId: roomId,
            imageUrl: imageUrl,
            maxAttendees: maxAttendees,
            isPublished: isPublished,
          ));

  Future<void> joinEvent(String communityId, String eventId) =>
      _run(() => _service.joinEvent(communityId, eventId));

  Future<void> leaveEvent(String communityId, String eventId) =>
      _run(() => _service.leaveEvent(communityId, eventId));

  Future<void> deleteEvent(String communityId, String eventId) =>
      _run(() => _service.deleteEvent(communityId, eventId));

  Future<void> deleteEventMessage(
          String communityId, String eventId, String messageId) =>
      _run(() => _service.deleteEventMessage(communityId, eventId, messageId));

  // ── Helper ─────────────────────────────────────────────────────────────────

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _eventMessagesSub?.cancel();
    void clearEvents() {
      events = [];
      _eventsSub?.cancel();
      notifyListeners();
    }

    // Subscribes to all published events across all communities.
    void loadPublishedEvents() {
      _publishedSub?.cancel();
      _publishedSub = _service.getPublishedEvents().listen(
        (list) {
          publishedEvents = list;
          notifyListeners();
        },
        onError: (e) {
          error = e.toString();
          notifyListeners();
        },
      );
    }

    void clearPublishedEvents() {
      publishedEvents = [];
      _publishedSub?.cancel();
      notifyListeners();
    }

    @override
    void dispose() {
      _eventsSub?.cancel();
      _publishedSub?.cancel();
      super.dispose();
    }
  }
}
