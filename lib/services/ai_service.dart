// lib/services/ai_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../main.dart' show ngrokApiUrl, geminiApiKey;

class AiResult {
  final double bullyScore;
  final double sarcasmScore;
  final bool   flagged;
  final String prediction;
  final String sarcasmType;
  final String severity;
  final String agentReasoning;
  final String adminReport;
  final String action;

  const AiResult({
    required this.bullyScore,
    required this.sarcasmScore,
    required this.flagged,
    required this.prediction,
    required this.sarcasmType,
    this.severity       = 'none',      // ← no required
    this.agentReasoning = '',          // ← no required
    this.adminReport    = '',          // ← no required
    this.action         = 'none',      // ← no required
  });

  factory AiResult.safe() => const AiResult(
    bullyScore  : 0.0,
    sarcasmScore: 0.0,
    flagged     : false,
    prediction  : 'Not Cyberbullying',
    sarcasmType : 'None',
  );
}
class AiService {

  // ── Text prediction ────────────────────────────────────────────
  static Future<AiResult> analyse({
    required String text,
    required String senderId,
    required String messageId,
    String emoji = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$ngrokApiUrl/predict/text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text'       : text,
          'sender_id'  : senderId,
          'message_id' : messageId,
          'emoji'      : emoji,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        return AiResult(
          bullyScore    : (d['weighted_score']  ?? 0.0).toDouble(),
          sarcasmScore  : (d['score_sarcasm']   ?? 0.0).toDouble(),
          flagged       : d['flagged']           ?? false,
          prediction    : d['prediction']        ?? 'Not Cyberbullying',
          sarcasmType   : d['sarcasm_type']      ?? 'None',
          severity      : d['severity']          ?? 'none',
          agentReasoning: d['agent_reasoning']   ?? '',
          adminReport   : d['admin_report']      ?? '',
          action        : d['action']            ?? 'none',
        );
      }
    } catch (e) {
      print('❌ AI analyse error: $e');
    }
    return AiResult.safe();
  }

  // ── Multimodal prediction ──────────────────────────────────────
  static Future<AiResult> analyseWithImage({
    required File   imageFile,
    required String caption,
    required String senderId,
    required String messageId,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST', Uri.parse('$ngrokApiUrl/predict/multimodal'));
      request.fields['caption']    = caption;
      request.fields['sender_id']  = senderId;
      request.fields['message_id'] = messageId;
      request.fields['emoji']      = '';
      request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send()
          .timeout(const Duration(seconds: 30));
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final d = jsonDecode(body);
        return AiResult(
          bullyScore    : (d['weighted_score']  ?? 0.0).toDouble(),
          sarcasmScore  : (d['score_sarcasm']   ?? 0.0).toDouble(),
          flagged       : d['flagged']           ?? false,
          prediction    : d['prediction']        ?? 'Not Cyberbullying',
          sarcasmType   : d['sarcasm_type']      ?? 'None',
          severity      : d['severity']          ?? 'none',
          agentReasoning: d['agent_reasoning']   ?? '',
          adminReport   : d['admin_report']      ?? '',
          action        : d['action']            ?? 'none',
        );
      }
    } catch (e) {
      print('❌ analyseWithImage error: $e');
    }
    return AiResult.safe();
  }

  // ── Gemini user analysis for admin ────────────────────────────
  // Called when admin clicks on a user in admin dashboard
static Future<String> analyseUserWithGemini({
  required String username,
  required List<Map<String, dynamic>> flags,
}) async {
  try {
    if (flags.isEmpty) {
      return 'No flagged messages found for this user.';
    }

    // ── Groq API (free, no quota issues) ──────────────────────
    //const groqKey = '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';  // ← paste here
    const groqKey = 'YOUR_GROQ_API_KEY';
    final messages = flags
        .take(5)
        .map((f) =>
            '- "${f['message_text'] ?? ''}" '
            '(score: ${((f['bully_score'] ?? 0.0) * 100)
                .toStringAsFixed(0)}%)')
        .join('\n');

    final prompt =
        'User "$username" sent these harmful messages:\n'
        '$messages\n\n'
        'In exactly 2 sentences: describe their behaviour '
        'pattern and recommend an admin action.';

    print('🤖 Calling Groq for: $username');

    final res = await http.post(
      Uri.parse(
          'https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Content-Type' : 'application/json',
        'Authorization': 'Bearer $groqKey',
      },
      body: jsonEncode({
        'model'      : 'llama-3.3-70b-versatile',
        'messages'   : [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens' : 150,
        'temperature': 0.3,
      }),
    ).timeout(const Duration(seconds: 20));

    print('🤖 Groq status: ${res.statusCode}');

    if (res.statusCode == 200) {
      final d    = jsonDecode(res.body);
      final text = d['choices']?[0]?['message']?['content'];
      if (text != null && text.toString().isNotEmpty) {
        print('✅ Groq analysis done');
        return text.toString().trim();
      }
      return 'Analysis returned empty.';
    } else {
      print('❌ Groq error: ${res.body}');
      return 'Analysis error: ${res.statusCode}';
    }
  } catch (e) {
    print('❌ Analysis exception: $e');
    return 'Unable to generate analysis.';
  }
}
}