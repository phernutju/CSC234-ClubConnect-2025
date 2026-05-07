/// TODO: Replace stubs with real API calls.
/// Backend team: implement these methods.
class ChatService {
  /// TODO: GET /api/communities/{communityName}/messages
  static Future<List<Map<String, dynamic>>> fetchMessages(
      String communityName) async {
    return [];
  }

  /// TODO: POST /api/communities/{communityName}/messages
  static Future<void> sendMessage(String communityName, String text) async {}

  /// TODO: POST /api/messages/{messageId}/report
  static Future<void> reportMessage(
    String messageId,
    String reason,
    String description,
  ) async {}
}
