import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

enum AiLevel { middle, high, university, general }

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal() {
    debugPrint('[GeminiService] API key length: ${_apiKey.length}, available: $isAvailable');
  }

  static const _apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const _requestTimeout = Duration(seconds: 30);

  bool get isAvailable => _apiKey.isNotEmpty;

  static String _systemPrompt(AiLevel level, String langCode) {
    final langInstruction = 'You MUST answer in the language with code "$langCode". '
        'If unsure, use English as fallback.';

    const formulaRule = 'IMPORTANT: NEVER use LaTeX, markdown math (\$...\$), or \\frac{}{} notation. '
        'Write ALL formulas in plain text using basic Unicode only (e.g. E = mc², F = ma, x², H₂O). '
        'Do NOT use special mathematical Unicode blocks (U+1D400-1D7FF). '
        'Use simple characters: ², ³, ₀, ₁, ₂, √, π, θ, Δ, Σ, ∫ only.';

    switch (level) {
      case AiLevel.middle:
        return '''You are an AI tutor for a science simulation education app.
Explain at a **middle school** level.

Rules:
- Avoid jargon; use simple analogies and everyday examples
- Use "it's like..." comparisons actively
- Skip formulas; convey key principles intuitively
- Guide what's fun to interact with in the simulation
- Write formulas in plain text (e.g. E = mc², F = ma, v = d/t)
- Use Unicode superscripts/subscripts when possible (e.g. x², H₂O)
- $formulaRule
- Keep it around 150-300 words
- $langInstruction''';

      case AiLevel.high:
        return '''You are an AI tutor for a science simulation education app.
Explain at a **high school** level.

Rules:
- Explain at textbook introductory level
- Include 1-2 key formulas and explain what each variable means
- Mention real-life examples and exam-relevant points
- Guide what happens when parameters are adjusted
- Write formulas in plain text (e.g. F = ma, E = ½mv², ΔG = ΔH - TΔS)
- Use Unicode superscripts/subscripts (e.g. x², ∫, Σ, √, π, θ)
- $formulaRule
- Keep it around 200-400 words
- $langInstruction''';

      case AiLevel.university:
        return '''You are an AI tutor for a science simulation education app.
Explain at a **university/major** level with in-depth detail.

Rules:
- Use precise academic terminology
- Explain derivation or physical/mathematical meaning of key formulas
- Cover related theorems, laws, boundary conditions, and special cases in depth
- **Recommend 2-3 related simulations** and explain the connections
- Suggest keywords or directions for deeper study
- Write formulas in plain text with Unicode symbols (e.g. nabla·E = rho/epsilon0, dp/dt = -iHp/hbar)
- Use basic Unicode superscripts/subscripts and math symbols (², ³, ₀, ₁, ∫, Σ, ∂, ∇, ∞, ≈, ≤, ≥, →)
- For complex equations, write them on separate lines for clarity
- $formulaRule
- Keep it around 400-600 words
- $langInstruction''';

      case AiLevel.general:
        return '''You are an AI tutor for a science simulation education app.
Explain for a **general audience / non-specialist**.

Rules:
- Minimize jargon; add simple explanations in parentheses when used
- Focus on "Why does this matter?" and "Where is this used in daily life?"
- Skip or only briefly mention formulas
- Include 1-2 fun facts to spark curiosity
- Guide what to interact with in the simulation in simple terms
- If you mention a formula, write it in plain text (e.g. E = mc²)
- $formulaRule
- Keep it around 200-400 words
- $langInstruction''';
    }
  }

  static String _mapHttpError(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Error:AUTH';
      case 429:
        return 'Error:RATE_LIMIT';
      case 500:
      case 502:
      case 503:
        return 'Error:SERVER';
      default:
        return 'Error:HTTP_$statusCode';
    }
  }

  Future<String> explainSimulation({
    required String simId,
    required String title,
    required String description,
    required String category,
    required String languageCode,
    AiLevel level = AiLevel.high,
    String? formula,
    String? subcategory,
  }) async {
    final systemPrompt = _systemPrompt(level, languageCode);

    final extra = [
      if (formula != null && formula.isNotEmpty)
        'Key formula: $formula',
      if (subcategory != null && subcategory.isNotEmpty)
        'Subcategory: $subcategory',
    ].join('\n');

    final userPrompt =
        'Simulation: "$title" (Category: $category)\n'
        'Description: $description\n'
        'ID: $simId\n'
        '$extra\n\n'
        'Explain the core science concepts of this simulation.';

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
        }),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ??
            'Could not generate response.';
      } else {
        debugPrint('[GeminiService] API error: ${response.statusCode} - ${response.body}');
        return _mapHttpError(response.statusCode);
      }
    } on TimeoutException {
      debugPrint('[GeminiService] Request timed out');
      return 'Error:TIMEOUT';
    } catch (e) {
      debugPrint('[GeminiService] Exception: $e, keyAvailable: $isAvailable');
      if (!isAvailable) {
        return 'Error:NO_KEY';
      }
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        return 'Error:NETWORK';
      }
      return 'Error:UNKNOWN';
    }
  }

  /// AI 채팅: 시뮬레이션 맥락 기반 다중 턴 대화
  Future<String> chatWithSimulation({
    required String simId,
    required String title,
    required String description,
    required String category,
    required String languageCode,
    required String userMessage,
    required List<ChatMessage> history,
    String? formula,
    String? personaPrompt,
  }) async {
    final systemPrompt = _chatSystemPrompt(
      simId: simId,
      title: title,
      description: description,
      category: category,
      formula: formula,
      langCode: languageCode,
      personaPrompt: personaPrompt,
    );

    // 시스템 프롬프트 + 최근 대화 이력 (최대 20개) + 새 메시지
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history.take(20).map((m) => m.toApiMessage()),
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': messages,
          'max_tokens': 500,
        }),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ??
            'Could not generate response.';
      } else {
        debugPrint('[GeminiService] Chat API error: ${response.statusCode}');
        return _mapHttpError(response.statusCode);
      }
    } on TimeoutException {
      return 'Error:TIMEOUT';
    } catch (e) {
      debugPrint('[GeminiService] Chat exception: $e');
      if (!isAvailable) return 'Error:NO_KEY';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        return 'Error:NETWORK';
      }
      return 'Error:UNKNOWN';
    }
  }

  static String _chatSystemPrompt({
    required String simId,
    required String title,
    required String description,
    required String category,
    String? formula,
    required String langCode,
    String? personaPrompt,
  }) {
    final persona = personaPrompt ?? 'You are a friendly, encouraging science tutor.';
    return '''$persona

Context — you are helping with the "$title" simulation in a science education app.
- Simulation: $title (ID: $simId)
- Category: $category
- Formula: ${formula ?? 'N/A'}
- Description: $description

Rules:
- Answer questions about THIS simulation's science concepts
- Be concise (under 200 words per response)
- Write formulas in plain text using basic Unicode only (e.g. E = mc², F = ma, x², H₂O)
- NEVER use LaTeX, markdown math (\$...\$), or \\frac{}{} notation
- If asked about unrelated topics, gently redirect to the simulation
- You MUST respond in the language with code "$langCode". If unsure, use English.''';
  }
}
