import 'dart:convert';
import 'package:http/http.dart' as http;

enum AiLevel { middle, high, university, general }

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const _apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

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
- Use markdown formatting (headings ##, bold **, lists -)
- For any math formula, use LaTeX notation wrapped in \$\$ for display math or \$ for inline math (e.g. \$E = mc^2\$)
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
- Use markdown formatting (headings ##, bold **, lists -)
- For any math formula, use LaTeX notation wrapped in \$\$ for display math or \$ for inline math (e.g. \$F = ma\$, \$\$E = \\frac{1}{2}mv^2\$\$)
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
- Use markdown formatting (headings ##, bold **, lists -)
- For any math formula, use LaTeX notation wrapped in \$\$ for display math or \$ for inline math (e.g. \$\\nabla \\cdot \\mathbf{E} = \\frac{\\rho}{\\epsilon_0}\$)
- Use display math \$\$ for important derivations and multi-line equations
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
- Use markdown formatting (headings ##, bold **, lists -)
- If you mention any formula, use LaTeX notation wrapped in \$ (e.g. \$E = mc^2\$)
- Keep it around 200-400 words
- $langInstruction''';
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
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ??
            'Could not generate response.';
      } else {
        return 'Error: API response code ${response.statusCode}';
      }
    } catch (e) {
      if (!isAvailable) {
        return 'Error: OpenAI API key is not configured.';
      }
      return 'Error: $e';
    }
  }
}
