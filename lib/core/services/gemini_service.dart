import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

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
- Write formulas in plain text with Unicode symbols (e.g. ∇·E = ρ/ε₀, ∂ψ/∂t = -iĤψ/ℏ)
- Use Unicode superscripts/subscripts and math symbols (², ³, ₀, ₁, ∫, Σ, ∂, ∇, ∞, ≈, ≤, ≥, →, ⟨, ⟩)
- For complex equations, write them on separate lines for clarity
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
          'model': 'gpt-5.2-pro-2025-12-11',
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
}
