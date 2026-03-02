import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/ai_persona.dart';
import '../services/firebase_ai_service.dart';
import '../services/subscription_service.dart';

/// AI 채팅 상태
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isOpen;
  final String? error;
  final String personaId;

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
  final Ref _ref;

  AiChatNotifier({
    required this.simId,
    required this.title,
    required this.description,
    required this.category,
    this.formula,
    required Ref ref,
  })  : _ref = ref,
        super(const AiChatState()) {
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
    final historyMessages = state.messages.where((m) => m != userMsg).toList();
    final isPro = _ref.read(isAiProProvider);

    final String result;
    if (simId == '_general_') {
      result = await FirebaseAiService().chatGeneral(
        userMessage: text.trim(),
        languageCode: languageCode,
        history: historyMessages,
        personaPrompt: personaPrompt,
        isPro: isPro,
      );
    } else {
      result = await FirebaseAiService().chatWithSimulation(
        simId: simId,
        title: title,
        description: description,
        category: category,
        languageCode: languageCode,
        userMessage: text.trim(),
        history: historyMessages,
        formula: formula,
        personaPrompt: personaPrompt,
        isPro: isPro,
      );
    }

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
    ref: ref,
  ),
);

/// AI 채팅 파라미터
class AiChatParams {
  final String simId;
  final String title;
  final String description;
  final String category;
  final String? formula;

  static const general = AiChatParams(
    simId: '_general_',
    title: 'Visual Science Lab',
    description: 'General science assistant',
    category: 'general',
  );

  bool get isGeneral => simId == '_general_';

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

/// 현재 활성 시뮬레이션 컨텍스트
final currentSimContextProvider = StateProvider<AiChatParams?>((ref) => null);

/// 글로벌 AI 채팅 파라미터
final globalAiChatParamsProvider = Provider<AiChatParams>((ref) {
  return ref.watch(currentSimContextProvider) ?? AiChatParams.general;
});

/// AI 오버레이 표시 여부 (인트로 중 숨김)
final showAiOverlayProvider = StateProvider<bool>((ref) => false);
