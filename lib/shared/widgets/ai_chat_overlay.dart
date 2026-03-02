import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/rive_character_mode.dart';
import '../../core/providers/ai_chat_provider.dart';
import '../../core/services/stt_service.dart';
import '../../core/services/tts_service.dart';

import 'rive_character.dart';


/// AI 채팅 오버레이 — 말풍선 스타일
///
/// 캐릭터가 우측 하단에 상시 표시.
/// 탭 → 입력창 슬라이드업. AI 응답 → 말풍선으로 표시.
class AiChatOverlay extends ConsumerStatefulWidget {
  final String? simId;
  final String? title;
  final String? description;
  final String? category;
  final String? formula;

  const AiChatOverlay({
    super.key,
    this.simId,
    this.title,
    this.description,
    this.category,
    this.formula,
  });

  @override
  ConsumerState<AiChatOverlay> createState() => _AiChatOverlayState();
}

class _AiChatOverlayState extends ConsumerState<AiChatOverlay>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  // Rive 캐릭터 speaking 상태
  bool _isSpeaking = false;
  Timer? _speakingTimer;

  // 말풍선 상태
  bool _showBubble = false;
  String _bubbleText = '';
  bool _bubbleIsError = false;
  Timer? _bubbleTimer;

  // STT 상태
  bool _isListening = false;

  // 애니메이션
  late AnimationController _charEntryController;
  late Animation<double> _charEntryScale;
  late AnimationController _inputSlideController;
  late Animation<Offset> _inputSlideAnim;
  late AnimationController _bubbleController;
  late Animation<double> _bubbleOpacity;
  late Animation<double> _bubbleScale;

  static const double _charSize = 96.0;

  AiChatParams get _params {
    if (widget.simId != null) {
      return AiChatParams(
        simId: widget.simId!,
        title: widget.title ?? widget.simId!,
        description: widget.description ?? '',
        category: widget.category ?? '',
        formula: widget.formula,
      );
    }
    return ref.read(globalAiChatParamsProvider);
  }

  @override
  void initState() {
    super.initState();

    // 캐릭터 등장 애니메이션
    _charEntryController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _charEntryScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _charEntryController, curve: Curves.elasticOut),
    );
    _charEntryController.forward();

    // 입력바 슬라이드 애니메이션
    _inputSlideController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _inputSlideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _inputSlideController,
      curve: Curves.easeOutCubic,
    ));

    // 말풍선 애니메이션
    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bubbleOpacity = Tween<double>(begin: 0, end: 1).animate(_bubbleController);
    _bubbleScale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _speakingTimer?.cancel();
    _bubbleTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _charEntryController.dispose();
    _inputSlideController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  /// 캐릭터 위치 — 채팅 열림 시 입력바 위로 이동
  Offset _charPos(Size screen, {bool isChatOpen = false, double keyboardH = 0}) {
    if (isChatOpen) {
      // 입력바 바로 위: keyboardH + margin(12) + barHeight(~56) + gap(8)
      final inputBarTop = keyboardH + 12 + 56 + 8;
      return Offset(screen.width - _charSize - 16, screen.height - _charSize - inputBarTop);
    }
    // 기본: 광고배너 + 네비바 + SafeArea 위
    final bottomPad = MediaQuery.of(context).padding.bottom;
    const adHeight = 50.0;
    const navBarHeight = 70.0;
    const margin = 16.0;
    final bottomOffset = adHeight + navBarHeight + bottomPad + margin;
    return Offset(screen.width - _charSize - 16, screen.height - _charSize - bottomOffset);
  }

  // ── Rive 캐릭터 모드 ──────────────────────────────────────
  RiveCharacterMode _computeCharacterMode(AiChatState chatState) {
    if (chatState.isLoading) return RiveCharacterMode.thinking;
    if (_isSpeaking) return RiveCharacterMode.speaking;
    if (_isListening) return RiveCharacterMode.listening;
    if (chatState.isOpen && _focusNode.hasFocus) return RiveCharacterMode.listening;
    return RiveCharacterMode.idle;
  }

  void _triggerSpeaking() {
    _speakingTimer?.cancel();
    setState(() => _isSpeaking = true);
    _speakingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  // ── 말풍선 표시/숨기기 ──────────────────────────────────────
  void _showSpeechBubble(String text, {bool isError = false}) {
    _bubbleTimer?.cancel();
    setState(() {
      _showBubble = true;
      _bubbleText = text;
      _bubbleIsError = isError;
    });
    _bubbleController.forward(from: 0);
    if (!isError) {
      _bubbleTimer = Timer(const Duration(seconds: 15), _hideSpeechBubble);
    }
  }

  void _hideSpeechBubble() {
    _bubbleTimer?.cancel();
    _bubbleController.reverse().then((_) {
      if (mounted) setState(() => _showBubble = false);
    });
  }

  // ── 캐릭터 탭 ──────────────────────────────────────
  void _onCharacterTap() {
    HapticFeedback.lightImpact();

    final chatNotifier = ref.read(aiChatProvider(_params).notifier);
    final chatState = ref.read(aiChatProvider(_params));

    if (chatState.isOpen) {
      // 입력바 닫기
      _stopListening();
      _inputSlideController.reverse().then((_) {
        chatNotifier.closeChat();
      });
      _focusNode.unfocus();
      return;
    }

    // 입력바 열기
    chatNotifier.openChat();
    _inputSlideController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  // ── STT 토글 ──────────────────────────────────────────────
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    final stt = SttService();
    if (!stt.isAvailable) return;

    final langCode = Localizations.localeOf(context).languageCode;
    final localeId = langCode == 'ko' ? 'ko_KR' : 'en_US';
    setState(() => _isListening = true);

    await stt.startListening(
      localeId: localeId,
      onResult: (text) {
        if (mounted) {
          _textController.text = text;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: text.length),
          );
        }
      },
    );
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    await SttService().stopListening();
    if (mounted) setState(() => _isListening = false);
  }

  // ── 메시지 전송 ──────────────────────────────────────────
  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _stopListening();
    _textController.clear();
    final langCode = Localizations.localeOf(context).languageCode;
    ref.read(aiChatProvider(_params).notifier).sendMessage(text, langCode);

    if (_showBubble) _hideSpeechBubble();
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider(_params));
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final screen = MediaQuery.of(context).size;
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;
    final charPos = _charPos(screen, isChatOpen: chatState.isOpen, keyboardH: keyboardH);

    // AI 응답 감지 — TTS 자동 읽기
    ref.listen(aiChatProvider(_params), (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        if (next.messages.isNotEmpty && next.messages.last.isAssistant) {
          _triggerSpeaking();
          _showSpeechBubble(next.messages.last.content);

          // TTS 자동 읽기
          final langCode = Localizations.localeOf(context).languageCode;
          TtsService().setLanguage(langCode);
          TtsService().speak(next.messages.last.content);
        }
      }
      if (next.error != null && prev?.error == null) {
        _showSpeechBubble(
          isKo ? '메시지 전송 실패. 다시 시도해주세요.' : 'Failed to send. Please try again.',
          isError: true,
        );
      }
    });

    return Stack(
      children: [
        // 말풍선 (캐릭터 위)
        if (_showBubble || chatState.isLoading)
          _buildSpeechBubble(chatState, isKo, screen, charPos),

        // 입력바 (하단 슬라이드)
        if (chatState.isOpen)
          _buildInputBar(chatState, isKo, screen, keyboardH),

        // 캐릭터 (AnimatedPositioned — 채팅 시 입력바 위로 이동)
        _buildCharacter(chatState, screen, charPos),
      ],
    );
  }

  // ── 캐릭터 위젯 ──────────────────────────────────────────
  Widget _buildCharacter(AiChatState chatState, Size screen, Offset charPos) {
    final persona = chatState.persona;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      left: charPos.dx,
      top: charPos.dy,
      child: GestureDetector(
        onTap: _onCharacterTap,
        child: ScaleTransition(
          scale: _charEntryScale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 캐릭터 본체
              SizedBox(
                width: _charSize,
                height: _charSize,
                child: RiveCharacter(
                  personaId: chatState.personaId,
                  mode: _computeCharacterMode(chatState),
                  size: _charSize,
                  visible: true,
                ),
              ),
              // 채팅 열린 상태 표시 (닫기 힌트)
              if (chatState.isOpen)
                Positioned(
                  left: -4,
                  top: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      shape: BoxShape.circle,
                      border: Border.all(color: persona.color.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.close, size: 12, color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 말풍선 ──────────────────────────────────────────────
  Widget _buildSpeechBubble(AiChatState chatState, bool isKo, Size screen, Offset charPos) {
    final maxW = math.min(screen.width - 32, 300.0);
    final bubbleBottom = screen.height - charPos.dy + 8;

    // 로딩 중이면 thinking 말풍선
    if (chatState.isLoading && !_showBubble) {
      return Positioned(
        right: 16,
        bottom: bubbleBottom.clamp(8.0, screen.height - 60),
        child: _ThinkingBubble(isKo: isKo),
      );
    }

    if (!_showBubble) return const SizedBox.shrink();

    final persona = chatState.persona;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bubbleBottom.clamp(8.0, screen.height - 100),
      child: Align(
        alignment: Alignment.bottomRight,
        child: FadeTransition(
          opacity: _bubbleOpacity,
          child: ScaleTransition(
            scale: _bubbleScale,
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: _hideSpeechBubble,
              child: Container(
                constraints: BoxConstraints(maxWidth: maxW, maxHeight: 250),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 말풍선 본체
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _bubbleIsError
                            ? const Color(0xFF2D1B1B)
                            : const Color(0xFF1A1F2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _bubbleIsError
                              ? Colors.red.withValues(alpha: 0.3)
                              : persona.color.withValues(alpha: 0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_bubbleIsError)
                              Padding(
                                padding: const EdgeInsets.only(right: 8, top: 1),
                                child: Icon(Icons.error_outline, size: 16,
                                    color: Colors.red.withValues(alpha: 0.7)),
                              ),
                            Flexible(
                              child: Text(
                                _bubbleText,
                                style: TextStyle(
                                  color: _bubbleIsError
                                      ? const Color(0xFFFCA5A5)
                                      : Colors.white.withValues(alpha: 0.92),
                                  fontSize: 13.5,
                                  height: 1.6,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 꼬리 (우하단 삼각형)
                    Positioned(
                      bottom: -6,
                      right: 16,
                      child: CustomPaint(
                        size: const Size(14, 7),
                        painter: _BubbleTailPainter(
                          fillColor: _bubbleIsError
                              ? const Color(0xFF2D1B1B)
                              : const Color(0xFF1A1F2E),
                          borderColor: _bubbleIsError
                              ? Colors.red.withValues(alpha: 0.3)
                              : persona.color.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 입력바 ────────────────────────────────────────────────
  Widget _buildInputBar(AiChatState chatState, bool isKo, Size screen, double keyboardH) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: keyboardH,
      child: SlideTransition(
        position: _inputSlideAnim,
        child: SafeArea(
          top: false,
          child: Material(
            color: Colors.transparent,
            child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 마이크 버튼 (STT)
                if (SttService().isAvailable)
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _isListening
                            ? Colors.red.withValues(alpha: 0.15)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 20,
                        color: _isListening ? Colors.red : Colors.white54,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? (isKo ? '듣고 있어요...' : 'Listening...')
                          : (isKo ? '질문을 입력하세요...' : 'Ask a question...'),
                      hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: chatState.isLoading ? null : _sendMessage,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: chatState.isLoading
                            ? [Colors.grey.shade800, Colors.grey.shade700]
                            : const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 20,
                      color: chatState.isLoading
                          ? Colors.white38
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

// ── Thinking 말풍선 ──────────────────────────────────────────
class _ThinkingBubble extends StatefulWidget {
  final bool isKo;
  const _ThinkingBubble({required this.isKo});

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _dotController,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final delay = i * 0.3;
              final t = ((_dotController.value - delay) % 1.0).clamp(0.0, 1.0);
              final scale = 0.6 + 0.4 * math.sin(t * math.pi);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ── 말풍선 꼬리 페인터 ────────────────────────────────────────
class _BubbleTailPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  _BubbleTailPainter({required this.fillColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = fillColor..style = PaintingStyle.fill;
    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) =>
      old.fillColor != fillColor || old.borderColor != borderColor;
}
