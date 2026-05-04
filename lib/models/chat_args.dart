class ChatArgs {
  final String communityName;
  final String communityId;
  final String memberCount;
  final String communityRules;

  const ChatArgs({
    required this.communityName,
    required this.communityId,
    this.memberCount = '',
    this.communityRules = '',
  });
}
