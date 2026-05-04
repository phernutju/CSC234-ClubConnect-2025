/// Represents a single notification (mention) received by the user.
/// Replace the dummy list with a real data source when backend is connected.
class NotificationModel {
  final String id;
  final String senderName;
  final String communityName;
  final String messageSnippet;
  final DateTime timestamp;

  const NotificationModel({
    required this.id,
    required this.senderName,
    required this.communityName,
    required this.messageSnippet,
    required this.timestamp,
  });
}
