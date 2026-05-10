import 'event_model.dart';

/// Payload passed via GoRouter `extra` when navigating to `/event-chat`.
class EventChatArgs {
  final EventModel event;
  final String memberCount;

  const EventChatArgs({
    required this.event,
    required this.memberCount,
  });
}
