import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _service;
  List<EventModel> events = [];
  List<EventModel> publishedEvents = [];
  bool isLoading = false;
  String? error;

  StreamSubscription<List<EventModel>>? _eventsSub;
  StreamSubscription<List<EventModel>>? _publishedSub;

  EventProvider({EventService? service}) : _service = service ?? EventService();

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
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _service.createEvent(
        communityId,
        title: title,
        hostName: hostName,
        startDate: startDate,
        endDate: endDate,
        location: location,
        detail: detail,
        memberLimit: memberLimit,
        coverImageUrl: coverImageUrl,
        isPublished: isPublished,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

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
