/// Payload passed via GoRouter `extra` when navigating to `/chat`.
/// Holds the minimum info the chat screen needs to identify and display the community.
class ChatArgs {
  final String communityId;
  final String communityName;
  final String memberCount;

  /// When non-null, the chat screen scrolls to this message after load and
  /// briefly highlights it. Used by notification taps (reply / mention).
  final String? targetMessageId;

  const ChatArgs({
    required this.communityId,
    required this.communityName,
    required this.memberCount,
    this.targetMessageId,
  });
}
