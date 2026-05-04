import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static GenerativeModel? _model;

  static GenerativeModel get _instance {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    );
    return _model!;
  }

  /// Returns true if the message violates community rules or contains
  /// profanity/hate speech. False means the message is safe to send.
  static Future<bool> moderateMessage(String text, {String rules = ''}) async {
    if (text.trim().isEmpty) return false;

    final rulesSection = rules.isNotEmpty
        ? 'Community rules:\n$rules\n\n'
        : '';

    final prompt = '''
${rulesSection}You are a content moderator. Analyze the following message and determine if it contains profanity, hate speech, harassment, or violates community standards.

Message: "$text"

Reply with ONLY one word: "FLAGGED" if the message is inappropriate, or "SAFE" if it is acceptable.
''';

    final response = await _instance.generateContent([Content.text(prompt)]);
    final result = response.text?.trim().toUpperCase() ?? 'SAFE';
    return result.contains('FLAGGED');
  }
}
