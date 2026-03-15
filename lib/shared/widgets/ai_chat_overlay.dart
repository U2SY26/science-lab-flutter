import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/rive_character_mode.dart';
import '../../core/providers/ai_chat_provider.dart';
import '../../core/services/stt_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/subscription_service.dart';
import 'subscription_dialog.dart';

import 'lottie_character.dart';


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

  // 키보드 높이 추적 (dismiss 감지용)
  double _prevKeyboardH = 0;

  // 입력 필드 키보드 연동 애니메이션
  Timer? _inputFieldDelayTimer;

  // 말풍선 상태
  bool _showBubble = false;
  String _bubbleText = '';
  bool _bubbleIsError = false;
  Timer? _bubbleTimer;

  // STT 상태
  bool _isListening = false;

  // 감정 상태 (-1.0 걱정 ~ 0.0 중립 ~ 1.0 흥분)
  double _currentEmotion = 0.0;
  Timer? _emotionResetTimer;

  // 채팅 시간 제한 (무료: 5분/일)
  static const int _maxFreeSeconds = 300;
  static const String _chatTimeDateKey = 'chat_time_date';
  static const String _chatTimeUsedKey = 'chat_time_used';
  int _remainingSeconds = _maxFreeSeconds;
  Timer? _countdownTimer;

  // 애니메이션
  late AnimationController _charEntryController;
  late Animation<double> _charEntryScale;
  late AnimationController _inputSlideController;
  late Animation<Offset> _inputSlideAnim;
  late AnimationController _inputFieldVisController;
  late Animation<double> _inputFieldOpacity;
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
    _loadChatTimeRemaining();

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

    // 입력 필드 가시성 애니메이션 (키보드 연동)
    _inputFieldVisController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _inputFieldOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _inputFieldVisController, curve: Curves.easeOut),
    );

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
    _countdownTimer?.cancel();
    _emotionResetTimer?.cancel();
    _inputFieldDelayTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _charEntryController.dispose();
    _inputSlideController.dispose();
    _inputFieldVisController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  // ── 채팅 시간 제한 (무료: 5분/일) ─────────────────────────
  Future<void> _loadChatTimeRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = prefs.getString(_chatTimeDateKey);
    if (storedDate != today) {
      await prefs.setString(_chatTimeDateKey, today);
      await prefs.setInt(_chatTimeUsedKey, 0);
      if (mounted) setState(() => _remainingSeconds = _maxFreeSeconds);
    } else {
      final used = prefs.getInt(_chatTimeUsedKey) ?? 0;
      if (mounted) {
        setState(() => _remainingSeconds = (_maxFreeSeconds - used).clamp(0, _maxFreeSeconds));
      }
    }
  }

  Future<void> _saveChatTimeUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_chatTimeDateKey, today);
    final used = (_maxFreeSeconds - _remainingSeconds).clamp(0, _maxFreeSeconds);
    await prefs.setInt(_chatTimeUsedKey, used);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // AI 응답 중이면 카운트다운 일시정지
      final chatState = ref.read(aiChatProvider(_params));
      if (chatState.isLoading) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        if (_remainingSeconds % 10 == 0) _saveChatTimeUsed();
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _saveChatTimeUsed();
  }

  // ── 감정 분석 — AI 응답에서 감정 수치 추출 ───────────────
  void _setEmotion(double value) {
    setState(() => _currentEmotion = value);
    _emotionResetTimer?.cancel();
    _emotionResetTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _currentEmotion = 0.0);
    });
  }

  static double _detectEmotion(String text) {
    final lower = text.toLowerCase();
    int score = 0;

    // 흥분/감탄
    const excited = ['amazing', 'incredible', 'wow', 'fantastic', 'brilliant',
      '놀라운', '놀랍', '대단', '멋진', '훌륭', '완벽', '신기'];
    // 행복/격려
    const happy = ['great', 'good', 'correct', 'right', 'well done', 'exactly',
      '잘했', '맞아', '좋은', '정확', '바로', '그렇지', '축하'];
    // 호기심
    const curious = ['interesting', 'fascinating', 'think about', 'what if',
      '흥미로', '생각해', '상상해', '궁금', '재미있'];
    // 걱정/안타까움
    const concerned = ['unfortunately', 'incorrect', 'not quite', 'careful',
      '아쉽', '틀렸', '주의', '조심', '어렵', '헷갈'];

    for (final w in excited) { if (lower.contains(w)) score += 3; }
    for (final w in happy) { if (lower.contains(w)) score += 2; }
    for (final w in curious) { if (lower.contains(w)) score += 1; }
    for (final w in concerned) { if (lower.contains(w)) score -= 2; }

    // 느낌표/물음표 반영
    score += '!'.allMatches(text).length.clamp(0, 3);
    if ('?'.allMatches(text).length >= 2) score += 1;

    return (score / 6.0).clamp(-1.0, 1.0);
  }

  // ── 감정별 색상 ────────────────────────────────────────────
  static Color emotionAccentColor(Color baseColor, double emotion) {
    if (emotion > 0.5) return Color.lerp(baseColor, const Color(0xFFFFD700), 0.5)!;
    if (emotion > 0.2) return Color.lerp(baseColor, const Color(0xFF10B981), 0.3)!;
    if (emotion < -0.3) return Color.lerp(baseColor, const Color(0xFFF59E0B), 0.4)!;
    return baseColor;
  }

  /// 캐릭터 위치 — 채팅 열림 시 입력바 위로 이동
  Offset _charPos(Size screen, {bool isChatOpen = false, double keyboardH = 0}) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    const adH = 50.0;
    const navH = 70.0;
    // 키보드가 보일 때만 캐릭터를 입력바 위로 올림
    if (isChatOpen && keyboardH > 50) {
      // 실제 입력바 위젯 높이: container(margin+padding+row) ≈ 70dp
      const barH = 70.0;
      final charBottom = keyboardH + barH + 8.0;
      return Offset(screen.width - _charSize - 16, screen.height - _charSize - charBottom);
    }
    // 기본: 광고배너 + 네비바 + SafeArea 위
    const margin = 16.0;
    final bottomOffset = adH + navH + bottomPad + margin;
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
    final isAiUnlimited = ref.read(isAiUnlimitedProvider);

    final isVisible = chatState.isOpen || _inputSlideController.value > 0;

    if (isVisible) {
      // ① 닫히는 중(reverse)이면 → 다시 열기
      if (_inputSlideController.status == AnimationStatus.reverse) {
        _inputFieldDelayTimer?.cancel();
        _inputSlideController.forward();
        _inputFieldVisController.forward();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _focusNode.requestFocus();
        });
        return;
      }
      // ② 열려 있거나 열리는 중 → 닫기
      // 입력 필드 먼저 사라지고, 0.5초 후 키보드 내림
      _stopListening();
      _inputFieldDelayTimer?.cancel();
      _inputFieldVisController.reverse().then((_) {
        if (!mounted) return;
        // 입력 필드 사라진 후 0.5초 뒤 키보드 dismiss
        _inputFieldDelayTimer = Timer(const Duration(milliseconds: 500), () {
          _inputFieldDelayTimer = null;
          if (!mounted) return;
          _focusNode.unfocus();
          _stopCountdown();
          _inputSlideController.reverse().then((_) {
            if (mounted) chatNotifier.closeChat();
          });
        });
      });
      return;
    }

    // ③ 완전히 닫혀 있음 → 열기
    // 키보드 먼저 올라오고, 0.5초 후 입력 필드 등장
    chatNotifier.openChat();
    _inputSlideController.forward();
    _inputFieldVisController.value = 0; // 입력 필드는 투명 상태로 시작
    if (!isAiUnlimited && _remainingSeconds > 0) _startCountdown();
    // 즉시 포커스 → 키보드 올라옴
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _focusNode.requestFocus();
    });
    // 0.5초 후 입력 필드 페이드인
    _inputFieldDelayTimer?.cancel();
    _inputFieldDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _inputFieldVisController.forward();
      _inputFieldDelayTimer = null;
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

    // 키보드 상태 변화 감지
    final kbWasUp = _prevKeyboardH > 50;
    final kbIsUp = keyboardH > 50;
    _prevKeyboardH = keyboardH;

    // 키보드가 내려갔을 때 → 채팅 닫기 (캐릭터 탭 닫기 중이면 스킵)
    if (kbWasUp && !kbIsUp && chatState.isOpen && _inputFieldDelayTimer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _inputFieldVisController.reverse();
        _stopCountdown();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _inputSlideController.reverse().then((_) {
            if (mounted) ref.read(aiChatProvider(_params).notifier).closeChat();
          });
        });
      });
    }

    // 전역 페르소나 선택 동기화
    final globalPersonaId = ref.watch(selectedPersonaIdProvider);
    if (chatState.personaId != globalPersonaId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(aiChatProvider(_params).notifier).changePersona(globalPersonaId);
        }
      });
    }

    // AI 응답 감지 — TTS 자동 읽기
    ref.listen(aiChatProvider(_params), (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        if (next.messages.isNotEmpty && next.messages.last.isAssistant) {
          _triggerSpeaking();
          _setEmotion(_detectEmotion(next.messages.last.content));
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
    final isAiUnlimited = ref.watch(isAiUnlimitedProvider);

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
                child: LottieCharacter(
                  personaId: chatState.personaId,
                  mode: _computeCharacterMode(chatState),
                  emotion: _currentEmotion,
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
              // 구독 왕관 버튼 (미구독 시)
              if (!isAiUnlimited && !chatState.isOpen)
                Positioned(
                  right: -6,
                  top: -6,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      SubscriptionDialog.show(context);
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.workspace_premium, size: 14, color: Colors.white),
                    ),
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
    final accentColor = emotionAccentColor(persona.color, _currentEmotion);
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
                              : accentColor.withValues(alpha: 0.35),
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
                              : accentColor.withValues(alpha: 0.35),
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
    final isAiUnlimited = ref.watch(isAiUnlimitedProvider);
    final timeExpired = !isAiUnlimited && _remainingSeconds <= 0;
    final canSend = !chatState.isLoading && !timeExpired;

    // 남은 시간 표시 (무료 사용자)
    String? timerLabel;
    if (!isAiUnlimited) {
      final m = _remainingSeconds ~/ 60;
      final s = _remainingSeconds % 60;
      timerLabel = '$m:${s.toString().padLeft(2, '0')}';
    }

    // 키보드가 없을 때 nav bar + ad banner 위로 올림
    // AiChatOverlay는 MaterialApp.builder의 전체화면 Stack이므로 Scaffold bottomNav를 모름
    const adHeight = 50.0;
    const navBarHeight = 70.0;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final barBottom = keyboardH > 0
        ? keyboardH
        : bottomPad + navBarHeight + adHeight;

    return Positioned(
      left: 0,
      right: 0,
      bottom: barBottom,
      child: SlideTransition(
        position: _inputSlideAnim,
        child: FadeTransition(
          opacity: _inputFieldOpacity,
          child: SafeArea(
          top: false,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 시간 만료 배너
                if (timeExpired)
                  GestureDetector(
                    onTap: () => SubscriptionDialog.show(context),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_off, size: 15, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isKo ? '오늘 무료 채팅 시간(5분)이 끝났습니다. 구독하면 무제한으로 이용할 수 있어요.' : 'Daily free chat (5 min) used up. Subscribe for unlimited.',
                              style: const TextStyle(color: Color(0xFFB794F4), fontSize: 11, height: 1.4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_ios, size: 11, color: Color(0xFF7C3AED)),
                        ],
                      ),
                    ),
                  ),
                // 입력 필드
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: timeExpired
                          ? Colors.white12
                          : const Color(0xFF7C3AED).withValues(alpha: 0.3),
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
                      // 타이머 OR 마이크 버튼
                      if (!isAiUnlimited)
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          child: Text(
                            timerLabel!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _remainingSeconds < 60
                                  ? Colors.orange
                                  : Colors.white38,
                            ),
                          ),
                        )
                      else if (SttService().isAvailable)
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
                          enabled: !timeExpired,
                          style: TextStyle(
                            color: timeExpired ? Colors.white24 : Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: timeExpired
                                ? (isKo ? '오늘 무료 시간 종료' : 'Daily limit reached')
                                : _isListening
                                    ? (isKo ? '듣고 있어요...' : 'Listening...')
                                    : (isKo ? '질문을 입력하세요...' : 'Ask a question...'),
                            hintStyle: TextStyle(
                              color: timeExpired ? Colors.white24 : AppColors.muted,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 6),
                            isDense: true,
                          ),
                          onSubmitted: canSend ? (_) => _sendMessage() : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: canSend ? _sendMessage : null,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: canSend
                                  ? const [Color(0xFF7C3AED), Color(0xFF6D28D9)]
                                  : [Colors.grey.shade800, Colors.grey.shade700],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            size: 20,
                            color: canSend ? Colors.white : Colors.white38,
                          ),
                        ),
                      ),
                    ],
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
