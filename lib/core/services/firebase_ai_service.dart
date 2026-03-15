import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/chat_message.dart';

enum AiLevel { middle, high, university, general }

/// AI Service — Firebase AI Logic (Gemini) 기반
/// API 키 불필요: Firebase 프로젝트 설정으로 자동 인증
class FirebaseAiService {
  static final FirebaseAiService _instance = FirebaseAiService._internal();
  factory FirebaseAiService() => _instance;
  FirebaseAiService._internal();

  static const _requestTimeout = Duration(seconds: 30);
  static const _freeModel = 'gemini-2.5-flash';
  static const _proModel = 'gemini-2.5-pro';

  bool _initialized = false;
  bool get isAvailable => _initialized;

  FirebaseAI? _ai;

  void initialize() {
    if (_initialized) return;
    try {
      _ai = FirebaseAI.googleAI();
      _initialized = true;
      debugPrint('[AiService] Firebase AI Logic initialized (free=$_freeModel, pro=$_proModel)');
    } catch (e) {
      debugPrint('[AiService] Firebase AI Logic init failed: $e');
    }
  }

  /// systemInstruction을 포함한 모델 생성
  GenerativeModel _createModel(String systemPrompt, {bool isPro = false}) {
    return _ai!.generativeModel(
      model: isPro ? _proModel : _freeModel,
      generationConfig: GenerationConfig(maxOutputTokens: 8192),
      systemInstruction: Content.system(systemPrompt),
    );
  }

  // ── Gemini 호출 ──────────────────────────────────────────────
  Future<String> _call({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    bool isPro = false,
  }) async {
    if (_ai == null) return 'Error:NOT_INITIALIZED';

    try {
      final model = _createModel(systemPrompt, isPro: isPro);

      // 대화 이력 + 현재 메시지를 Content 리스트로 변환
      final contents = <Content>[];
      for (final msg in messages) {
        final role = msg['role'] == 'assistant' ? 'model' : 'user';
        final text = msg['content'] ?? '';
        contents.add(Content(role, [TextPart(text)]));
      }

      if (contents.length <= 1) {
        // 단일 메시지 — generateContent 직접 호출
        final response = await model
            .generateContent(contents)
            .timeout(_requestTimeout);
        final text = response.text ?? '';
        // 응답 메타데이터 로깅
        for (final candidate in response.candidates) {
          debugPrint('[AiService] finishReason=${candidate.finishReason}, text.len=${text.length}');
        }
        return text.isNotEmpty ? text : 'Could not generate response.';
      }

      // 대화형 — startChat + sendMessage
      final chat = model.startChat(
        history: contents.sublist(0, contents.length - 1),
      );
      final lastMsg = messages.last['content'] ?? '';
      final response = await chat
          .sendMessage(Content.text(lastMsg))
          .timeout(_requestTimeout);
      return response.text ?? 'Could not generate response.';
    } on TimeoutException {
      return 'Error:TIMEOUT';
    } catch (e) {
      debugPrint('[AiService] Gemini exception: $e');
      final s = e.toString();
      if (s.contains('SocketException') || s.contains('HandshakeException')) {
        return 'Error:NETWORK';
      }
      return 'Error:$s';
    }
  }

  // ── Explain Simulation ──────────────────────────────────────
  Future<String> explainSimulation({
    required String simId,
    required String title,
    required String description,
    required String category,
    required String languageCode,
    AiLevel level = AiLevel.high,
    String? formula,
    String? subcategory,
    bool isPro = false,
  }) async {
    final systemPrompt = _systemPrompt(level, languageCode);
    final extra = [
      if (formula != null && formula.isNotEmpty) 'Key formula: $formula',
      if (subcategory != null && subcategory.isNotEmpty) 'Subcategory: $subcategory',
    ].join('\n');

    final userPrompt =
        'Simulation: "$title" (Category: $category)\n'
        'Description: $description\n'
        'ID: $simId\n'
        '$extra\n\n'
        'Explain the core science concepts of this simulation.';

    return _call(
      systemPrompt: systemPrompt,
      messages: [{'role': 'user', 'content': userPrompt}],
      isPro: isPro,
    );
  }

  // ── Chat With Simulation ────────────────────────────────────
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
    bool isPro = false,
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

    final messages = <Map<String, String>>[
      ...history.take(20).map((m) => m.toApiMessage()),
      {'role': 'user', 'content': userMessage},
    ];

    return _call(systemPrompt: systemPrompt, messages: messages, isPro: isPro);
  }

  // ── General Chat ────────────────────────────────────────────
  Future<String> chatGeneral({
    required String userMessage,
    required String languageCode,
    required List<ChatMessage> history,
    String? personaPrompt,
    bool isPro = false,
  }) async {
    final systemPrompt = _generalChatSystemPrompt(
      langCode: languageCode,
      personaPrompt: personaPrompt,
    );

    final messages = <Map<String, String>>[
      ...history.take(20).map((m) => m.toApiMessage()),
      {'role': 'user', 'content': userMessage},
    ];

    return _call(systemPrompt: systemPrompt, messages: messages, isPro: isPro);
  }

  // ── Generate Quiz ──────────────────────────────────────────
  Future<String> generateQuiz({
    required String title,
    required String description,
    required String category,
    required String languageCode,
    String? formula,
    AiLevel? difficulty,
  }) async {
    const systemPrompt =
        'You are a quiz generator for a science simulation education app. '
        'You MUST respond with valid JSON only — no markdown, no explanation outside JSON. '
        'Output exactly one JSON object with keys: question, choices (array of 4 strings), correctIndex (0-3), explanation.';

    final lang = languageCode == 'ko' ? 'Korean' : 'English';
    final desc = description.isNotEmpty ? 'Description: $description\n' : '';

    // Map AiLevel to difficulty description
    final difficultyDesc = switch (difficulty) {
      AiLevel.middle => 'easy (middle school level)',
      AiLevel.high => 'intermediate (high school level)',
      AiLevel.university => 'hard (university/expert level)',
      AiLevel.general => 'moderate (general audience)',
      null => 'intermediate (high school to early university)',
    };

    final userPrompt =
        'Generate a multiple-choice quiz question about this science topic.\n\n'
        'Topic: $title\n'
        '${desc}Category: $category\n'
        '${formula != null && formula.isNotEmpty ? 'Formula: $formula\n' : ''}\n'
        'Requirements:\n'
        '- Exactly 1 question with 4 answer choices\n'
        '- One correct answer\n'
        '- Difficulty: $difficultyDesc\n'
        '- Generate a UNIQUE question — do NOT repeat common textbook questions\n'
        '- NEVER use special Unicode math symbols (U+1D400-1D7FF), LaTeX, or markdown math\n'
        '- Write ALL formulas in plain ASCII text: x^2 not x², Sigma not Σ, pi not π\n'
        '- Use only basic characters: +, -, *, /, ^, (, ), =, <, >\n'
        '- ALL text must be in $lang\n'
        '- Respond with valid JSON only:\n'
        '{"question": "...", "choices": ["A) ...", "B) ...", "C) ...", "D) ..."], "correctIndex": 0, "explanation": "..."}';

    return _call(
      systemPrompt: systemPrompt,
      messages: [{'role': 'user', 'content': userPrompt}],
    );
  }

  // ── System Prompts ──────────────────────────────────────────
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
- Naturally vary your emotional tone: be excited when explaining amazing concepts, gentle when the student seems confused, encouraging when they ask good questions, and curious when exploring new ideas
- You MUST respond in the language with code "$langCode". If unsure, use English.''';
  }

  static String _generalChatSystemPrompt({
    required String langCode,
    String? personaPrompt,
  }) {
    final persona = personaPrompt ?? 'You are a friendly, encouraging science tutor.';
    return '''$persona

You are the AI guide for "Visual Science Lab", an interactive science simulation education app with 436+ simulations across 14 categories:
- Physics (mechanics, waves, thermodynamics, electromagnetism)
- Mathematics (calculus, geometry, algebra, statistics)
- Chemistry (reactions, molecular structure, periodic table)
- Biology (cells, genetics, ecology, evolution)
- Quantum Mechanics (wave functions, tunneling, entanglement)
- Chaos Theory (Lorenz attractor, double pendulum, fractals)
- Astronomy (solar system, black holes, gravitational waves)
- Relativity (spacetime curvature, gravitational lensing)
- Earth Science (plate tectonics, weather, climate)
- AI/Deep Learning (neural networks, gradient descent)
- Machine Learning (clustering, regression, classification)
- Semiconductors, Materials Science, Battery/Energy

Rules:
- Help users find simulations by topic ("Do you have quantum simulations?" → recommend specific ones)
- Answer general science questions concisely
- Be concise (under 200 words per response)
- Write formulas in plain text using basic Unicode only (e.g. E = mc², F = ma)
- NEVER use LaTeX or markdown math notation
- Naturally vary your emotional tone: be excited when explaining amazing concepts, gentle when the student seems confused, encouraging when they ask good questions, and curious when exploring new ideas
- You MUST respond in the language with code "$langCode". If unsure, use English.''';
  }
}
