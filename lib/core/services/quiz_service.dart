import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../models/quiz_question.dart';
import 'firebase_ai_service.dart';

/// AI 퀴즈 생성 서비스 — GPT-4o-mini (Remote Config에서 키 로드)
class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  String? _openAiKey;

  /// Remote Config에서 OpenAI 키 로드
  String _getOpenAiKey() {
    if (_openAiKey != null && _openAiKey!.isNotEmpty) return _openAiKey!;
    try {
      _openAiKey = FirebaseRemoteConfig.instance.getString('openai_api_key');
    } catch (_) {}
    return _openAiKey ?? '';
  }

  /// 시뮬레이션 기반 퀴즈 생성
  Future<QuizQuestion?> generateQuiz({
    required String simId,
    required String title,
    required String description,
    required String category,
    required String languageCode,
    String? formula,
    AiLevel? difficulty,
  }) async {
    try {
      debugPrint('[QuizService] Generating quiz for: $title ($category)');

      final key = _getOpenAiKey();
      String result;

      if (key.isNotEmpty) {
        // GPT-4o-mini — JSON mode로 안정적 출력
        result = await _callGpt(
          title: title,
          description: description,
          category: category,
          languageCode: languageCode,
          formula: formula,
          difficulty: difficulty,
          apiKey: key,
        );
      } else {
        // Fallback: Gemini
        debugPrint('[QuizService] No OpenAI key, falling back to Gemini');
        result = await FirebaseAiService().generateQuiz(
          title: title,
          description: description,
          category: category,
          languageCode: languageCode,
          formula: formula,
          difficulty: difficulty,
        );
      }

      debugPrint('[QuizService] Response length: ${result.length}');

      if (result.startsWith('Error:')) {
        debugPrint('[QuizService] AI error: $result');
        return null;
      }

      final jsonStr = _extractJson(result);
      if (jsonStr == null) {
        debugPrint('[QuizService] Failed to extract JSON');
        return null;
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return QuizQuestion.fromJson(json);
    } catch (e) {
      debugPrint('[QuizService] Failed: $e');
      return null;
    }
  }

  /// GPT-4o-mini 직접 호출 (JSON mode)
  Future<String> _callGpt({
    required String title,
    required String description,
    required String category,
    required String languageCode,
    String? formula,
    AiLevel? difficulty,
    required String apiKey,
  }) async {
    final lang = languageCode == 'ko' ? 'Korean' : 'English';
    final desc = description.isNotEmpty ? 'Description: $description\n' : '';
    final difficultyDesc = switch (difficulty) {
      AiLevel.middle => 'easy (middle school)',
      AiLevel.high => 'intermediate (high school)',
      AiLevel.university => 'hard (university)',
      AiLevel.general => 'moderate (general)',
      null => 'intermediate',
    };

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'response_format': {'type': 'json_object'},
      'max_tokens': 1024,
      'messages': [
        {
          'role': 'system',
          'content': 'You are a quiz generator. Respond with valid JSON only. '
              'NEVER use special Unicode math symbols, LaTeX, or markdown. '
              'Write formulas in plain ASCII: x^2, Sigma(p^2), sqrt(x). '
              'Output: {"question":"...","choices":["A) ...","B) ...","C) ...","D) ..."],"correctIndex":0,"explanation":"..."}'
        },
        {
          'role': 'user',
          'content': 'Generate a $difficultyDesc quiz about "$title" ($category). '
              '${desc}${formula != null && formula.isNotEmpty ? 'Formula: $formula. ' : ''}'
              'ALL text in $lang. Generate a UNIQUE question. Use plain ASCII for all formulas.'
        },
      ],
    });

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      return 'Error:HTTP_${response.statusCode}';
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) return 'Error:NO_CHOICES';

    return choices[0]['message']['content'] as String? ?? 'Error:EMPTY';
  }

  /// AI 응답에서 JSON 추출
  String? _extractJson(String text) {
    // ```json ... ``` 블록
    final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(text);
    if (codeBlockMatch != null) {
      final inner = codeBlockMatch.group(1) ?? '';
      final s = inner.indexOf('{');
      final e = inner.lastIndexOf('}');
      if (s != -1 && e > s) return inner.substring(s, e + 1);
    }

    // 직접 JSON
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) return text.substring(start, end + 1);

    return null;
  }
}
