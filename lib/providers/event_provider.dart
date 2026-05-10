import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _service;
  List<EventModel> events = [];
  bool isLoading = false;
  String? error;

  StreamSubscription<List<EventModel>>? _eventsSub;

  EventProvider({EventService? service})
      : _service = service ?? EventService();

  // ── Events stream ──────────────────────────────────────────────────────────

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

  // ── Event actions ──────────────────────────────────────────────────────────

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
  }) =>
      _run(() => _service.createEvent(
            communityId: communityId,
            title: title,
            description: description,
            tags: tags,
            startDate: startDate,
            endDate: endDate,
            roomId: roomId,
            imageUrl: imageUrl,
            maxAttendees: maxAttendees,
          ));

  Future<void> joinEvent(String communityId, String eventId) =>
      _run(() => _service.joinEvent(communityId, eventId));

  Future<void> leaveEvent(String communityId, String eventId) =>
      _run(() => _service.leaveEvent(communityId, eventId));

  Future<void> deleteEvent(String communityId, String eventId) =>
      _run(() => _service.deleteEvent(communityId, eventId));

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
    super.dispose();
  }
}
