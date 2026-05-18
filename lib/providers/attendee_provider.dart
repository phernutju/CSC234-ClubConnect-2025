import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/attendee_model.dart';
import '../services/attendee_service.dart';

class AttendeeProvider extends ChangeNotifier {
  final AttendeeService _service;

  List<AttendeeModel> attendees = [];
  bool isAttending = false;
  bool isLoading = false;
  String? error;

  StreamSubscription<List<AttendeeModel>>? _attendeesSub;

  AttendeeProvider({AttendeeService? service})
      : _service = service ?? AttendeeService();

  // ── Stream ─────────────────────────────────────────────────────────────────

  void loadAttendees(String communityId, String eventId) {
    _attendeesSub?.cancel();
    _attendeesSub = _service.getAttendees(communityId, eventId).listen(
      (list) {
        attendees = list;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  void clearAttendees() {
    attendees = [];
    isAttending = false;
    _attendeesSub?.cancel();
    _attendeesSub = null;
    notifyListeners();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> checkIsAttending(String communityId, String eventId) async {
    try {
      isAttending = await _service.isAttending(communityId, eventId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> joinEvent(String communityId, String eventId) =>
      _run(() async {
        await _service.joinEvent(communityId, eventId);
        isAttending = true;
      });

  Future<void> leaveEvent(String communityId, String eventId) =>
      _run(() async {
        await _service.leaveEvent(communityId, eventId);
        isAttending = false;
      });

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
    _attendeesSub?.cancel();
    super.dispose();
  }
}
