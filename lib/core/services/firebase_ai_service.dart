import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_ai/firebase_ai.dart';
import '../models/chat_message.dart';

enum AiLevel { middle, high, university, general }

class FirebaseAiService {
  static final FirebaseAiService _instance = FirebaseAiService._internal();
  factory FirebaseAiService() => _instance;
  FirebaseAiService._internal();

  static const _requestTimeout = Duration(seconds: 30);

  GenerativeModel? _flashModel;
  GenerativeModel? _proModel;

  bool _initialized = false;
  bool get isAvailable => _initialized;

  void initialize() {
    if (_initialized) return;
    _flashModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
    );
    _proModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-pro',
    );
    _initialized = true;
    debugPrint('[FirebaseAiService] Initialized: Flash + Pro models');
  }

  GenerativeModel _model(bool isPro) =>
      isPro ? (_proModel ?? _flashModel!) : _flashModel!;

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

    try {
      final model = _model(isPro);
      final response = await model.generateContent([
        Content.system(systemPrompt),
        Content.text(userPrompt),
      ]).timeout(_requestTimeout);

      return response.text ?? 'Could not generate response.';
    } on TimeoutException {
      debugPrint('[FirebaseAiService] Request timed out');
      return 'Error:TIMEOUT';
    } catch (e) {
      debugPrint('[FirebaseAiService] Exception: $e');
      return _mapError(e);
    }
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

    try {
      final model = _model(isPro);
      final chat = model.startChat(
        history: [
          Content.system(systemPrompt),
          ..._convertHistory(history),
        ],
      );
      final response = await chat.sendMessage(
        Content.text(userMessage),
      ).timeout(_requestTimeout);

      return response.text ?? 'Could not generate response.';
    } on TimeoutException {
      return 'Error:TIMEOUT';
    } catch (e) {
      debugPrint('[FirebaseAiService] Chat exception: $e');
      return _mapError(e);
    }
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

    try {
      final model = _model(isPro);
      final chat = model.startChat(
        history: [
          Content.system(systemPrompt),
          ..._convertHistory(history),
        ],
      );
      final response = await chat.sendMessage(
        Content.text(userMessage),
      ).timeout(_requestTimeout);

      return response.text ?? 'Could not generate response.';
    } on TimeoutException {
      return 'Error:TIMEOUT';
    } catch (e) {
      debugPrint('[FirebaseAiService] General chat exception: $e');
      return _mapError(e);
    }
  }

  // ── History Conversion ──────────────────────────────────────
  List<Content> _convertHistory(List<ChatMessage> history) {
    return history.take(20).map((m) {
      if (m.role == 'user') return Content.text(m.content);
      return Content('model', [TextPart(m.content)]);
    }).toList();
  }

  // ── Error Mapping ───────────────────────────────────────────
  String _mapError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('PERMISSION_DENIED') || msg.contains('401')) return 'Error:AUTH';
    if (msg.contains('RESOURCE_EXHAUSTED') || msg.contains('429')) return 'Error:RATE_LIMIT';
    if (msg.contains('UNAVAILABLE') || msg.contains('503')) return 'Error:SERVER';
    if (msg.contains('SocketException') || msg.contains('HandshakeException')) return 'Error:NETWORK';
    return 'Error:UNKNOWN';
  }

  // ── System Prompts (ported from GeminiService) ──────────────
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
- You MUST respond in the language with code "$langCode". If unsure, use English.''';
  }

  static String _generalChatSystemPrompt({
    required String langCode,
    String? personaPrompt,
  }) {
    final persona = personaPrompt ?? 'You are a friendly, encouraging science tutor.';
    return '''$persona

You are the AI guide for "Visual Science Lab", an interactive science simulation education app with 256+ simulations across 14 categories:
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
- You MUST respond in the language with code "$langCode". If unsure, use English.''';
  }
}
