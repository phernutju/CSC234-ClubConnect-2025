import 'event_model.dart';

/// Payload passed via GoRouter `extra` when navigating to `/event-chat`.
class EventChatArgs {
  final EventModel event;
  final String memberCount;
  final String communityId;

  const EventChatArgs({
    required this.event,
    required this.memberCount,
    required this.communityId,
  });
}
