import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../models/smart_bill_model.dart';

class ModerationResult {
  final bool isViolating;
  final List<int> violatedRules;
  final String reason;

  const ModerationResult({
    required this.isViolating,
    required this.violatedRules,
    required this.reason,
  });
}

class GeminiService {
  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const _model = 'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free';
  static const _maxRetries = 3;

  static Future<ModerationResult> moderateMessage(
    String text, {
    String rules = '',
  }) async {
    if (text.trim().isEmpty) {
      return const ModerationResult(
          isViolating: false, violatedRules: [], reason: '');
    }

    // No rules → nothing to violate
    if (rules.trim().isEmpty) {
      return const ModerationResult(
          isViolating: false, violatedRules: [], reason: '');
    }
    final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

    final prompt = '''
You are a content moderator for a community chat room.

Community rules (numbered list):
$rules

Message to evaluate: "$text"

Instructions:
- Judge ONLY against the community rules listed above.
- Do NOT apply any external standards, general profanity policies, or assumptions.
- If the rules do not explicitly prohibit what the message contains, it is NOT a violation.
- If a rule is violated, include its 1-based index in violatedRules.

Respond with a single JSON object only. No markdown, no backticks, no explanation:
If violation: {"isViolating":true,"violatedRules":[<rule numbers>],"reason":"<brief reason>"}
If safe: {"isViolating":false,"violatedRules":[],"reason":""}
''';

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 200,
      'temperature': 0,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': 'You are a content moderation system. '
              'Always respond with a single JSON object only. '
              'No reasoning, no explanation, no markdown.',
        },
        {'role': 'user', 'content': prompt},
      ],
    });
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      // ignore: avoid_print
      print('[AI] status=${response.statusCode} body=${response.body}');

      if (response.statusCode == 429) {
        final errorBody = jsonDecode(response.body);
        final retryAfter =
            (errorBody['error']?['metadata']?['retry_after_seconds'] as num?)
                    ?.toInt() ??
                10;
        if (attempt < _maxRetries - 1) {
          await Future.delayed(Duration(seconds: retryAfter));
          continue;
        }
        return const ModerationResult(
            isViolating: false, violatedRules: [], reason: '');
      }

      if (response.statusCode != 200) {
        return const ModerationResult(
            isViolating: false, violatedRules: [], reason: '');
      }

      String combined = '';
      try {
        final respBody = jsonDecode(response.body);
        // ignore: avoid_print
        print('[AI] FULL=${response.body}');
        final msg = respBody['choices']?[0]?['message'];
        final content = (msg?['content'] as String? ?? '').trim();
        final reasoning = (msg?['reasoning'] as String? ?? '').trim();
        combined = content.isNotEmpty ? content : reasoning;
        // ignore: avoid_print
        print('[AI] raw="$combined"');

        // find JSON containing isViolating anywhere in the text
        final jsonMatch = RegExp(
          r'\{[^{}]*"isViolating"[^{}]*\}',
          dotAll: true,
        ).firstMatch(combined);
        // fallback: any JSON object
        final fallbackMatch = RegExp(r'\{[^{}]+\}').firstMatch(combined);
        final cleaned =
            jsonMatch?.group(0) ?? fallbackMatch?.group(0) ?? combined;

        final parsed = jsonDecode(cleaned);
        // ignore: avoid_print
        print('[AI] parsed isViolating=${parsed['isViolating']}');
        return ModerationResult(
          isViolating: parsed['isViolating'] as bool? ?? false,
          violatedRules: (parsed['violatedRules'] as List<dynamic>?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              [],
          reason: parsed['reason'] as String? ?? '',
        );
      } catch (e) {
        // ignore: avoid_print
        print('[AI] parse error: $e | raw was: $combined');
        // fallback: detect violation from reasoning text keywords
        final lower = combined.toLowerCase();
        final violating = lower.contains('violat') ||
            lower.contains('profanity') ||
            lower.contains('inappropriate') ||
            lower.contains('offensive') ||
            lower.contains('คำหยาบ') ||
            lower.contains('ละเมิด');
        return ModerationResult(
          isViolating: violating,
          violatedRules: [],
          reason: violating ? 'Detected via reasoning fallback' : '',
        );
      }
    }

    return const ModerationResult(
        isViolating: false, violatedRules: [], reason: '');
  }

  static String _mimeType(Uint8List b) {
    if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xD8) return 'image/jpeg';
    if (b.length >= 4 && b[0] == 0x89 && b[1] == 0x50) return 'image/png';
    if (b.length >= 4 && b[0] == 0x52 && b[1] == 0x49) return 'image/webp';
    if (b.length >= 6 && b[0] == 0x47 && b[1] == 0x49) return 'image/gif';
    return 'image/jpeg';
  }

  static Future<bool> moderateImageBytes(Uint8List bytes) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    Uint8List data = bytes;
    String mime = _mimeType(bytes);

    // Try resize to reduce payload; fall back to original if decode fails
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final resized = img.copyResize(decoded, width: 384);
        data = Uint8List.fromList(img.encodePng(resized));
        mime = 'image/png';
      } else {
        // ignore: avoid_print
        print('[IMG] decode returned null, using original bytes');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[IMG] resize error: $e — using original bytes');
    }

    // Skip if still too large (>3MB) — API will reject anyway
    if (data.lengthInBytes > 3 * 1024 * 1024) {
      // ignore: avoid_print
      print(
          '[IMG] image too large (${data.lengthInBytes}), skipping moderation');
      return false;
    }

    final base64Image = base64Encode(data);

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 400,
          'temperature': 0,
          'messages': [
            {
              'role': 'system',
              'content': 'You are an extremely strict content moderation AI for a community platform. '
                  'Your priority is safety. ALWAYS flag content that is questionable or borderline. '
                  'It is better to over-flag than to allow harmful content through.',
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mime;base64,$base64Image',
                  },
                },
                {
                  'type': 'text',
                  'text': 'Examine this image as a strict content moderator. '
                      'Reply {"isNSFW":true} for ANY of the following — even partially visible, implied, or borderline: '
                      '(1) any exposed skin of breasts (including cleavage), genitals, or buttocks; '
                      '(2) sexually suggestive poses, gestures, or objects used in a sexual manner '
                      '(e.g. eating a banana suggestively, phallic objects); '
                      '(3) pornographic or sexually explicit content; '
                      '(4) any firearm, gun, pistol, rifle, or weapon being held or shown; '
                      '(5) knives, swords, or bladed weapons; '
                      '(6) explosives or bombs; '
                      '(7) illegal drugs, syringes, drug paraphernalia, or drug use; '
                      '(8) smoking, vaping, e-cigarettes, or tobacco products. '
                      'When in doubt, reply {"isNSFW":true}. '
                      'Only reply {"isNSFW":false} if the image is clearly safe for all audiences. '
                      'End with the JSON.',
                },
              ],
            },
          ],
        }),
      );

      // ignore: avoid_print
      print('[IMG] status=${response.statusCode} body=${response.body}');
      if (response.statusCode != 200) return false;

      final body = jsonDecode(response.body);
      final msg = body['choices']?[0]?['message'];
      final content = (msg?['content'] as String? ?? '').trim();
      final reasoning = (msg?['reasoning'] as String? ?? '').trim();
      final combined = content.isNotEmpty ? content : reasoning;
      // ignore: avoid_print
      print('[IMG] combined="$combined"');

      final jsonMatch =
          RegExp(r'\{[^{}]*"isNSFW"[^{}]*\}').firstMatch(combined);
      if (jsonMatch == null) {
        final lower = combined.toLowerCase();
        return (lower.contains('nsfw') && !lower.contains('not nsfw')) ||
            lower.contains('explicit') ||
            lower.contains('pornograph') ||
            lower.contains('nudity') ||
            lower.contains('nude') ||
            lower.contains('breast') ||
            lower.contains('genital') ||
            lower.contains('weapon') ||
            lower.contains('drug') ||
            lower.contains('vap') ||
            lower.contains('cigarette') ||
            lower.contains('smoking') ||
            lower.contains('tobacco');
      }
      final parsed = jsonDecode(jsonMatch.group(0)!);
      return parsed['isNSFW'] as bool? ?? false;
    } catch (e) {
      // ignore: avoid_print
      print('[IMG] error: $e');
      return false;
    }
  }

  static Future<bool> moderateImageUrl(String imageUrl) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 50,
          'temperature': 0,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {'url': imageUrl},
                },
                {
                  'type': 'text',
                  'text': 'Is this image sexually explicit, pornographic, or NSFW? '
                      'Reply with JSON only, no explanation: {"isNSFW":true} or {"isNSFW":false}',
                },
              ],
            },
          ],
        }),
      );

      // ignore: avoid_print
      print('[IMG] status=${response.statusCode} body=${response.body}');
      if (response.statusCode != 200) return false;

      final body = jsonDecode(response.body);
      final content =
          (body['choices']?[0]?['message']?['content'] as String? ?? '').trim();
      final jsonMatch = RegExp(r'\{[^{}]*"isNSFW"[^{}]*\}').firstMatch(content);
      final parsed = jsonDecode(jsonMatch?.group(0) ?? content);
      return parsed['isNSFW'] as bool? ?? false;
    } catch (e) {
      // ignore: avoid_print
      print('[IMG] error: $e');
      return false;
    }
  }

  static Future<AiVerificationResult> verifyPaymentSlip(
    Uint8List slipBytes,
    double expectedAmount,
  ) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    final fallback = AiVerificationResult(
      detectedAmount: 0,
      expectedAmount: expectedAmount,
      recipientMatch: false,
      result: 'mismatch',
    );

    // Resize to reduce payload
    Uint8List data = slipBytes;
    try {
      final decoded = img.decodeImage(slipBytes);
      if (decoded != null) {
        final resized = img.copyResize(decoded, width: 512);
        data = Uint8List.fromList(img.encodePng(resized));
      }
    } catch (_) {}
    final base64Image = base64Encode(data);
    final mime = _mimeType(slipBytes);

    try {
      // ignore: avoid_print
      print('[SLIP] calling API with base64 bytes...');
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': 1000,
              'temperature': 0,
              'response_format': {'type': 'json_object'},
              'messages': [
                {
                  'role': 'system',
                  'content': 'You are a strict Thai bank payment slip verifier. '
                      'Your only job is to verify if an image is a genuine Thai bank transfer slip. '
                      'If the image contains a person, animal, food, nature, or anything that is NOT a bank slip, '
                      'you MUST return isRealSlip=false. Never guess or assume. Be strict.',
                },
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'image_url',
                      'image_url': {'url': 'data:$mime;base64,$base64Image'},
                    },
                    {
                      'type': 'text',
                      'text': 'Examine this image carefully.\n\n'
                          'STEP 1 — Is this a Thai bank transfer slip or PromptPay confirmation? '
                          'A valid slip MUST contain ALL of: transaction amount in THB, date/time, bank logo or reference number. '
                          'If the image shows a person, animal, food, scenery, or ANY non-slip content → isRealSlip=false, detectedAmount=0.\n\n'
                          'STEP 2 — Only if isRealSlip=true: does the amount match ${expectedAmount.toStringAsFixed(2)} THB (±1 THB)?\n\n'
                          'Reply JSON only, no markdown:\n'
                          '{"detectedAmount":<number>,"isRealSlip":<true|false>,"amountMatch":<true|false>,"reason":"<one sentence>"}',
                    },
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      // ignore: avoid_print
      print('[SLIP] status=${response.statusCode} body=${response.body}');
      if (response.statusCode != 200) return fallback;

      final body = jsonDecode(response.body);
      final choice = body['choices']?[0];

      // Reasoning model ran out of tokens before producing JSON — retry
      if (choice?['finish_reason'] == 'length' ||
          choice?['native_finish_reason'] == 'length') {
        // ignore: avoid_print
        print('[SLIP] finish_reason=length — truncated, returning fallback');
        return AiVerificationResult(
          detectedAmount: 0,
          expectedAmount: expectedAmount,
          recipientMatch: false,
          result: 'mismatch',
          reason:
              'Verification incomplete (response truncated). Please try again.',
        );
      }

      final msg = choice?['message'];
      final content = (msg?['content'] as String? ?? '').trim();
      final reasoning = (msg?['reasoning'] as String? ?? '').trim();
      // strip markdown code fences if model wraps response
      final combined = (content.isNotEmpty ? content : reasoning)
          .replaceAll(RegExp(r'```[a-z]*\n?', caseSensitive: false), '')
          .replaceAll('```', '')
          .trim();

      // Match JSON that may be unclosed (truncated reasoning) by stopping at
      // the last closing brace or end of string, then try to close it.
      final jsonMatch = RegExp(
        r'\{[^{}]*"detectedAmount"[^{}]*\}',
        dotAll: true,
      ).firstMatch(combined);
      if (jsonMatch == null) return fallback;

      final parsed = jsonDecode(jsonMatch.group(0)!);
      final detected = (parsed['detectedAmount'] as num?)?.toDouble() ?? 0;
      final isReal = parsed['isRealSlip'] as bool? ?? false;
      final amountMatch = parsed['amountMatch'] as bool? ?? false;
      final reason = parsed['reason'] as String? ?? '';
      final isMatch = isReal && amountMatch;
      // ignore: avoid_print
      print('[SLIP] AI Verification Reason: $reason');
      
      print('[SLIP] AI Verification Result: $isMatch ');
      return AiVerificationResult(
        detectedAmount: detected,
        expectedAmount: expectedAmount,
        recipientMatch: isReal,
        result: isMatch ? 'match' : 'mismatch',
        reason: reason,
      );
    } on TimeoutException catch (_) {
      // ignore: avoid_print
      print('[SLIP] timeout after 30s');
      return AiVerificationResult(
        detectedAmount: 0,
        expectedAmount: expectedAmount,
        recipientMatch: false,
        result: 'mismatch',
        reason: 'Verification timed out. Please try again.',
      );
    } catch (e) {
      // ignore: avoid_print
      print('[SLIP] error: $e');
      return fallback;
    }
  }
}
