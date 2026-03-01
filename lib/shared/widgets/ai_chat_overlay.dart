import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/ai_persona.dart';
import '../../core/providers/ai_chat_provider.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/ad_service.dart';
import 'subscription_dialog.dart';

/// AI 채팅 오버레이 (드래그 가능한 FAB + 이동/리사이즈 가능한 채팅 패널)
class AiChatOverlay extends ConsumerStatefulWidget {
  final String simId;
  final String title;
  final String description;
  final String category;
  final String? formula;

  const AiChatOverlay({
    super.key,
    required this.simId,
    required this.title,
    required this.description,
    required this.category,
    this.formula,
  });

  @override
  ConsumerState<AiChatOverlay> createState() => _AiChatOverlayState();
}

class _AiChatOverlayState extends ConsumerState<AiChatOverlay>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  // FAB 위치 (드래그 가능)
  Offset? _fabPosition; // null = 초기 위치 (우측 하단)
  bool _fabDragging = false;
  Offset? _fabDragStart;

  // 채팅 패널 위치/크기
  Offset? _panelPosition; // null = FAB 기준 자동 배치
  Size _panelSize = const Size(320, 420);
  bool _panelDragging = false;
  bool _showPersonaSelector = false;

  // 3분 체험 타이머
  DateTime? _trialExpiry;

  late AnimationController _fabAnimController;
  late Animation<double> _fabScale;

  static const double _fabSize = 48.0;
  static const double _minPanelW = 260.0;
  static const double _minPanelH = 280.0;

  AiChatParams get _params => AiChatParams(
    simId: widget.simId,
    title: widget.title,
    description: widget.description,
    category: widget.category,
    formula: widget.formula,
  );

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.elasticOut),
    );
    _fabAnimController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  Offset _defaultFabPosition(Size screen) =>
      Offset(screen.width - _fabSize - 20, screen.height - _fabSize - 160);

  Offset _effectiveFabPos(Size screen) =>
      _fabPosition ?? _defaultFabPosition(screen);

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _isTrialActive =>
      _trialExpiry != null && DateTime.now().isBefore(_trialExpiry!);

  // ── FAB 탭 ──────────────────────────────────────────────
  void _onFabTap() {
    if (_fabDragging) return; // 드래그 중이면 탭 무시
    HapticFeedback.lightImpact();
    final chatNotifier = ref.read(aiChatProvider(_params).notifier);
    final chatState = ref.read(aiChatProvider(_params));
    final isAiAssist = ref.read(isAiAssistProvider);

    if (isAiAssist || _isTrialActive) {
      chatNotifier.toggleChat();
      return;
    }
    if (chatState.isOpen) {
      chatNotifier.closeChat();
      return;
    }
    _showTrialOrSubscribeDialog();
  }

  void _showTrialOrSubscribeDialog() {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.chat_bubble_rounded, color: Color(0xFF7C3AED), size: 20),
            const SizedBox(width: 8),
            Text(
              isKo ? 'AI 챗봇' : 'AI Chatbot',
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isKo
                  ? 'AI 챗봇으로 시뮬레이션에 대해\n자유롭게 질문할 수 있습니다.'
                  : 'Chat with AI about any simulation\nand get instant answers.',
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _startTrial();
                },
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: Text(isKo ? '광고 보고 3분 체험' : 'Watch ad for 3min trial'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  SubscriptionDialog.show(context);
                },
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(isKo ? '구독하고 무제한 사용 (₩4,990/월)' : 'Subscribe for unlimited (₩4,990/mo)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC4B5FD),
                  side: BorderSide(color: const Color(0xFF7C3AED).withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startTrial() {
    AdService().showRewardedInterstitialAd(
      onRewarded: () {
        if (!mounted) return;
        setState(() {
          _trialExpiry = DateTime.now().add(const Duration(minutes: 3));
        });
        ref.read(aiChatProvider(_params).notifier).openChat();
        Future.delayed(const Duration(minutes: 3), () {
          if (mounted && _trialExpiry != null) {
            setState(() => _trialExpiry = null);
            ref.read(aiChatProvider(_params).notifier).closeChat();
            final isKo = Localizations.localeOf(context).languageCode == 'ko';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isKo ? 'AI 챗봇 체험이 종료되었습니다' : 'AI chatbot trial has ended'),
                backgroundColor: const Color(0xFF7C3AED),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        });
      },
      onFailed: () {
        if (!mounted) return;
        setState(() {
          _trialExpiry = DateTime.now().add(const Duration(minutes: 1));
        });
        ref.read(aiChatProvider(_params).notifier).openChat();
        Future.delayed(const Duration(minutes: 1), () {
          if (mounted && _trialExpiry != null) {
            setState(() => _trialExpiry = null);
            ref.read(aiChatProvider(_params).notifier).closeChat();
          }
        });
      },
    );
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final isAiAssist = ref.read(isAiAssistProvider);
    if (!isAiAssist && !_isTrialActive) {
      ref.read(aiChatProvider(_params).notifier).closeChat();
      _showTrialOrSubscribeDialog();
      return;
    }

    _textController.clear();
    final langCode = Localizations.localeOf(context).languageCode;
    ref.read(aiChatProvider(_params).notifier).sendMessage(text, langCode);
    _scrollToBottom();
  }

  // ── Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider(_params));
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final screen = MediaQuery.of(context).size;
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;
    final fabPos = _effectiveFabPos(screen);

    ref.listen(aiChatProvider(_params), (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Stack(
      children: [
        // 채팅 패널
        if (chatState.isOpen)
          _buildPositionedPanel(chatState, isKo, screen, fabPos, keyboardH),

        // 드래그 가능한 FAB
        Positioned(
          left: fabPos.dx,
          top: fabPos.dy,
          child: GestureDetector(
            onPanStart: (d) {
              _fabDragging = false;
              _fabDragStart = d.globalPosition;
            },
            onPanUpdate: (d) {
              final dist = (d.globalPosition - _fabDragStart!).distance;
              if (dist > 8) _fabDragging = true;
              if (_fabDragging) {
                setState(() {
                  final pos = _effectiveFabPos(screen) + d.delta;
                  _fabPosition = Offset(
                    pos.dx.clamp(0, screen.width - _fabSize),
                    pos.dy.clamp(0, screen.height - _fabSize),
                  );
                });
              }
            },
            onPanEnd: (_) {
              if (!_fabDragging) _onFabTap();
              _fabDragging = false;
            },
            onTap: _onFabTap,
            child: ScaleTransition(
              scale: _fabScale,
              child: _buildFab(chatState),
            ),
          ),
        ),
      ],
    );
  }

  // ── FAB 위젯 ────────────────────────────────────────────
  Widget _buildFab(AiChatState chatState) {
    final isAiAssist = ref.watch(isAiAssistProvider);
    return Container(
      width: _fabSize,
      height: _fabSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            chatState.isOpen ? Icons.close_rounded : Icons.chat_bubble_rounded,
            color: Colors.white,
            size: 22,
          ),
          if (!isAiAssist && !_isTrialActive)
            Positioned(
              right: 5,
              bottom: 5,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, size: 8, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // ── 채팅 패널 배치 ────────────────────────────────────────
  Widget _buildPositionedPanel(
      AiChatState chatState, bool isKo, Size screen, Offset fabPos, double keyboardH) {
    final maxW = (screen.width - 24).clamp(_minPanelW, 500.0);
    final availableH = screen.height - keyboardH;
    final maxH = (availableH * 0.85).clamp(_minPanelH, 700.0);
    final clampedW = _panelSize.width.clamp(_minPanelW, maxW);
    final clampedH = _panelSize.height.clamp(_minPanelH, maxH);

    // 자동 배치: FAB 위 왼쪽 방향
    final autoPos = Offset(
      (fabPos.dx + _fabSize - clampedW).clamp(8.0, screen.width - clampedW - 8),
      (fabPos.dy - clampedH - 8).clamp(8.0, screen.height - clampedH - 8),
    );
    var pos = _panelPosition ?? autoPos;

    // 키보드가 올라오면 패널 하단이 키보드 위에 오도록 보정
    if (keyboardH > 0) {
      final panelBottom = pos.dy + clampedH;
      final maxBottom = screen.height - keyboardH - 8;
      if (panelBottom > maxBottom) {
        pos = Offset(pos.dx, (maxBottom - clampedH).clamp(4.0, maxBottom));
      }
    }

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: _buildChatPanel(chatState, isKo, screen, clampedW, clampedH),
    );
  }

  Widget _buildChatPanel(
      AiChatState chatState, bool isKo, Size screen, double w, double h) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(chatState, isKo),
                if (_showPersonaSelector)
                  _buildPersonaSelector(chatState, isKo),
                Expanded(
                  child: chatState.messages.isEmpty
                      ? _buildEmptyState(chatState, isKo)
                      : _buildMessageList(chatState, isKo),
                ),
                if (chatState.error != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: Colors.red.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 14, color: Color(0xFFFCA5A5)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isKo ? '메시지 전송 실패. 다시 시도해주세요.' : 'Failed to send. Please try again.',
                            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildInputArea(chatState, isKo),
              ],
            ),
            // 리사이즈 핸들 (우측 하단 — 터치 영역 확대)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) {
                  setState(() {
                    _panelSize = Size(
                      (_panelSize.width + d.delta.dx).clamp(_minPanelW, screen.width - 24),
                      (_panelSize.height + d.delta.dy).clamp(_minPanelH, screen.height * 0.85),
                    );
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.only(right: 6, bottom: 6),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(16),
                    ),
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                  ),
                  child: Icon(Icons.drag_handle_rounded, size: 16,
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 헤더 (드래그로 패널 이동) ────────────────────────────────
  Widget _buildHeader(AiChatState chatState, bool isKo) {
    return GestureDetector(
      onPanStart: (_) => setState(() => _panelDragging = true),
      onPanUpdate: (d) {
        setState(() {
          final screen = MediaQuery.of(context).size;
          final cur = _panelPosition ??
              Offset(
                (_effectiveFabPos(screen).dx + _fabSize - _panelSize.width).clamp(8.0, screen.width - _panelSize.width - 8),
                (_effectiveFabPos(screen).dy - _panelSize.height - 8).clamp(8.0, screen.height - _panelSize.height - 8),
              );
          _panelPosition = Offset(
            (cur.dx + d.delta.dx).clamp(0, screen.width - _minPanelW),
            (cur.dy + d.delta.dy).clamp(0, screen.height - _minPanelH),
          );
        });
      },
      onPanEnd: (_) => setState(() => _panelDragging = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _panelDragging
              ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
              : const Color(0xFF7C3AED).withValues(alpha: 0.06),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          children: [
            Icon(chatState.persona.icon, size: 18, color: chatState.persona.color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatState.persona.name(isKo),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.title,
                    style: TextStyle(color: AppColors.muted, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _headerBtn(Icons.face, () => setState(() => _showPersonaSelector = !_showPersonaSelector),
                isActive: _showPersonaSelector),
            const SizedBox(width: 4),
            _headerBtn(Icons.delete_outline, () => ref.read(aiChatProvider(_params).notifier).clearHistory()),
            const SizedBox(width: 4),
            _headerBtn(Icons.close, () => ref.read(aiChatProvider(_params).notifier).closeChat()),
          ],
        ),
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF7C3AED).withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.muted),
      ),
    );
  }

  // ── 페르소나 선택기 ──────────────────────────────────────
  Widget _buildPersonaSelector(AiChatState chatState, bool isKo) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: aiPersonas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final p = aiPersonas[i];
          final sel = p.id == chatState.personaId;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(aiChatProvider(_params).notifier).changePersona(p.id);
              setState(() => _showPersonaSelector = false);
            },
            child: Container(
              width: 70,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: sel ? p.color.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel ? p.color.withValues(alpha: 0.5) : AppColors.cardBorder,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(p.icon, size: 18, color: p.color),
                  const SizedBox(height: 3),
                  Text(
                    p.name(isKo),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: sel ? p.color : AppColors.muted,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 빈 상태 ─────────────────────────────────────────────
  Widget _buildEmptyState(AiChatState chatState, bool isKo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chatState.persona.icon,
              size: 36,
              color: chatState.persona.color.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              isKo
                  ? '안녕하세요!\n이 시뮬레이션에 대해\n무엇이든 물어보세요.'
                  : 'Hi there!\nAsk me anything about\nthis simulation.',
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── 메시지 리스트 ─────────────────────────────────────────
  Widget _buildMessageList(AiChatState chatState, bool isKo) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatState.messages.length) {
          return _buildTypingIndicator(isKo);
        }
        final msg = chatState.messages[index];
        return _ChatBubble(
          message: msg,
          personaColor: chatState.persona.color,
          personaIcon: chatState.persona.icon,
        );
      },
    );
  }

  Widget _buildTypingIndicator(bool isKo) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isKo ? 'AI가 생각하는 중...' : 'AI is thinking...',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 입력 영역 ─────────────────────────────────────────────
  Widget _buildInputArea(AiChatState chatState, bool isKo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: isKo ? '질문을 입력하세요...' : 'Ask a question...',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFF7C3AED).withValues(alpha: 0.5)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: chatState.isLoading ? null : _sendMessage,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.send_rounded,
                size: 17,
                color: chatState.isLoading ? Colors.white38 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 개별 채팅 말풍선
class _ChatBubble extends StatelessWidget {
  final dynamic message;
  final Color personaColor;
  final IconData personaIcon;

  const _ChatBubble({
    required this.message,
    required this.personaColor,
    required this.personaIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: personaColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(personaIcon, size: 13, color: personaColor),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.18)
                    : const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 12),
                ),
              ),
              child: SelectableText(
                message.content,
                style: TextStyle(
                  color: isUser ? const Color(0xFFDDD6FE) : AppColors.ink,
                  fontSize: 13,
                  height: 1.5,
                  fontFamilyFallback: const ['Noto Sans', 'Roboto', 'sans-serif'],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 28),
        ],
      ),
    );
  }
}
