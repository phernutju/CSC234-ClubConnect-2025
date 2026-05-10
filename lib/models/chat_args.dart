/// Payload passed via GoRouter `extra` when navigating to `/chat`.
/// Holds the minimum info the chat screen needs to identify and display the community.
class ChatArgs {
  final String communityId;
  final String communityName;
  final String memberCount;

  const ChatArgs({
    required this.communityId,
    required this.communityName,
    required this.memberCount,
  });
}
