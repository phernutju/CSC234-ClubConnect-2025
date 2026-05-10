import 'event_model.dart';

class EventDetailArgs {
  final EventModel event;
  final String communityId;

  const EventDetailArgs({
    required this.event,
    required this.communityId,
  });
}
