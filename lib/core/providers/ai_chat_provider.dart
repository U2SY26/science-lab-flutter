import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/ai_persona.dart';
import '../services/gemini_service.dart';

/// AI 채팅 상태
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isOpen;
  final String? error;
  final String personaId;  // 현재 선택된 페르소나

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isOpen = false,
    this.error,
    this.personaId = 'tutor',
  });

  AiPersona get persona => getPersonaById(personaId);

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isOpen,
    String? error,
    String? personaId,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isOpen: isOpen ?? this.isOpen,
      error: error,
      personaId: personaId ?? this.personaId,
    );
  }
}

/// 시뮬레이션별 AI 채팅 Notifier
class AiChatNotifier extends StateNotifier<AiChatState> {
  final String simId;
  final String title;
  final String description;
  final String category;
  final String? formula;

  AiChatNotifier({
    required this.simId,
    required this.title,
    required this.description,
    required this.category,
    this.formula,
  }) : super(const AiChatState()) {
    _loadHistory();
  }

  static const int _maxMessages = 50;
  static const String _chatKeyPrefix = 'chat_history_';

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('$_chatKeyPrefix$simId');
      if (json != null && json.isNotEmpty) {
        final messages = ChatMessage.decodeList(json);
        state = state.copyWith(messages: messages);
      }
    } catch (e) {
      debugPrint('[AiChatNotifier] Failed to load history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = state.messages.length > _maxMessages
          ? state.messages.sublist(state.messages.length - _maxMessages)
          : state.messages;
      await prefs.setString('$_chatKeyPrefix$simId', ChatMessage.encodeList(trimmed));
    } catch (e) {
      debugPrint('[AiChatNotifier] Failed to save history: $e');
    }
  }

  void toggleChat() {
    state = state.copyWith(isOpen: !state.isOpen);
  }

  void openChat() {
    state = state.copyWith(isOpen: true);
  }

  void closeChat() {
    state = state.copyWith(isOpen: false);
  }

  void changePersona(String personaId) {
    state = state.copyWith(personaId: personaId);
  }

  Future<void> sendMessage(String text, String languageCode) async {
    if (text.trim().isEmpty || state.isLoading) return;

    final userMsg = ChatMessage.user(text.trim());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    final isKo = languageCode == 'ko';
    final personaPrompt = state.persona.systemPrompt(isKo);

    final result = await GeminiService().chatWithSimulation(
      simId: simId,
      title: title,
      description: description,
      category: category,
      languageCode: languageCode,
      userMessage: text.trim(),
      history: state.messages.where((m) => m != userMsg).toList(),
      formula: formula,
      personaPrompt: personaPrompt,
    );

    if (!mounted) return;

    if (result.startsWith('Error:')) {
      state = state.copyWith(
        isLoading: false,
        error: result,
      );
    } else {
      final assistantMsg = ChatMessage.assistant(result);
      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
      );
      await _saveHistory();
    }
  }

  void clearHistory() async {
    state = state.copyWith(messages: [], error: null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_chatKeyPrefix$simId');
  }
}

/// 시뮬레이션별 AI 채팅 Provider (family)
final aiChatProvider = StateNotifierProvider.family<AiChatNotifier, AiChatState, AiChatParams>(
  (ref, params) => AiChatNotifier(
    simId: params.simId,
    title: params.title,
    description: params.description,
    category: params.category,
    formula: params.formula,
  ),
);

/// AI 채팅 파라미터
class AiChatParams {
  final String simId;
  final String title;
  final String description;
  final String category;
  final String? formula;

  const AiChatParams({
    required this.simId,
    required this.title,
    required this.description,
    required this.category,
    this.formula,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiChatParams &&
          runtimeType == other.runtimeType &&
          simId == other.simId;

  @override
  int get hashCode => simId.hashCode;
}
