/// Payload passed via GoRouter `extra` when navigating to `/chat`.
/// Holds the minimum info the chat app bar needs to display.
class ChatArgs {
  final String communityName;
  final String memberCount;

  const ChatArgs({required this.communityName, required this.memberCount});
}
