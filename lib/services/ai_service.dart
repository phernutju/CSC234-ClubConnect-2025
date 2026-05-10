import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _endpoint =
      'https://openrouter.ai/api/v1/chat/completions';
  static const _model = 'qwen/qwen3-next-80b-a3b-instruct:free';

  static Future<bool> moderateMessage(String text,
      {String rules = ''}) async {
    if (text.trim().isEmpty) return false;

    final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    final rulesSection = rules.isNotEmpty ? rules : '(ไม่มีกฎเพิ่มเติม)';

    final prompt = '''
กฎของชุมชนนี้ (อ่านและเข้าใจก่อนตัดสิน — กฎอาจเขียนในภาษาใดก็ได้):
$rulesSection

ตรวจสอบข้อความต่อไปนี้ว่าละเมิดข้อใดข้อหนึ่งด้านล่างหรือไม่:
1. ละเมิดกฎชุมชนข้างต้น
2. คำหยาบหรือคำด่าทอในภาษาไทย — ตัวอย่าง: ควย, หี, เย็ด, มึง, กู, ไอ้สัตว์, อีสัตว์, ไอ้หน้าหี, ไอ้เหี้ย, สัตว์, แม่ง ฯลฯ (รวมถึงการสะกดแปลกหรือเว้นช่องไฟ)
3. คำหยาบในภาษาอังกฤษ — ตัวอย่าง: fuck, shit, bitch, asshole, bastard ฯลฯ
4. การข่มขู่ คุกคาม หรือล่อลวง
5. การเหยียดเชื้อชาติ ศาสนา หรือเพศ

ข้อความ: "$text"

ตอบ FLAGGED หรือ SAFE เท่านั้น ห้ามอธิบาย ห้ามเพิ่มเนื้อหาอื่นใด
''';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 10,
        'temperature': 0,
        'messages': [
          {
            'role': 'system',
            'content':
                'คุณคือระบบกรองเนื้อหาอัตโนมัติสำหรับแอปชุมชน '
                'ตอบได้เพียงคำเดียวเท่านั้น: FLAGGED หรือ SAFE '
                'ห้ามอธิบาย ห้ามเพิ่มเนื้อหาอื่นใด',
          },
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) return false;

    final body = jsonDecode(response.body);
    final result = (body['choices']?[0]?['message']?['content'] as String?)
            ?.trim()
            .toUpperCase() ??
        'SAFE';
    return result.contains('FLAGGED');
  }
}
