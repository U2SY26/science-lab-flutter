import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firebase_ai_service.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/subscription_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/community_service.dart';
import '../../features/community/presentation/widgets/comment_section.dart';
import '../../features/community/presentation/widgets/quiz_dialog.dart';
import 'ad_banner.dart';
import 'subscription_dialog.dart';
import 'fullscreen_sim_view.dart';

/// Helper to check if current locale is Korean
bool _isKoreanLocale(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'ko';
}

const int _maxAiUses = 3;
const String _aiRemainingKey = 'ai_explanation_remaining';
const String _aiDateKey = 'ai_explanation_date';

/// S-001~S-030: 개선된 시뮬레이션 컨테이너 위젯
class SimulationContainer extends StatefulWidget {
  final String category;
  final String title;
  final String? formula;
  final String? formulaDescription;
  final Widget simulation;
  final Widget? controls;
  final Widget? buttons;
  final VoidCallback? onShare;
  final VoidCallback? onHelp;
  final VoidCallback? onFullscreen;
  final String? simId;

  /// 전체화면에서 독립 실행할 시뮬레이션 빌더 (제공 시 전체화면 버튼 활성화)
  final Widget Function()? simulationBuilder;

  const SimulationContainer({
    super.key,
    required this.category,
    required this.title,
    this.formula,
    this.formulaDescription,
    required this.simulation,
    this.controls,
    this.buttons,
    this.onShare,
    this.onHelp,
    this.onFullscreen,
    this.simId,
    this.simulationBuilder,
  });

  @override
  State<SimulationContainer> createState() => _SimulationContainerState();
}

class _SimulationContainerState extends State<SimulationContainer> {
  // S-013, S-017: 수식 섹션 접힘 상태
  bool _isFormulaExpanded = false;

  // S-011: 로딩 상태
  final bool _isLoading = false;

  // AI explanation state
  bool _isAiOpen = false;
  bool _isAiLoading = false;
  AiLevel _aiLevel = AiLevel.high;
  final Map<AiLevel, String> _aiCache = {};
  String? _aiError;

  // AI usage limit
  int _aiRemaining = _maxAiUses;
  bool _isAiUnlimited = false;
  bool _isAiExhausted = false;

  @override
  void initState() {
    super.initState();
    _loadAiRemaining();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ProviderScope에서 구독 상태 읽기
    final container = ProviderScope.containerOf(context, listen: false);
    final sub = container.read(subscriptionProvider);
    _isAiUnlimited = sub.isAiUnlimited;
    // 구독 상태 변경 리스닝
    container.listen<SubscriptionState>(subscriptionProvider, (prev, next) {
      if (mounted) {
        setState(() {
          _isAiUnlimited = next.isAiUnlimited;
        });
      }
    });
  }

  Future<void> _loadAiRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = prefs.getString(_aiDateKey);
    if (storedDate != today) {
      // 새 날 → 3회 리셋
      await prefs.setString(_aiDateKey, today);
      await prefs.setInt(_aiRemainingKey, _maxAiUses);
      if (mounted) setState(() => _aiRemaining = _maxAiUses);
    } else {
      if (mounted) {
        setState(() {
          _aiRemaining = prefs.getInt(_aiRemainingKey) ?? _maxAiUses;
        });
      }
    }
  }

  Future<void> _saveAiRemaining(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_aiRemainingKey, value);
  }

  bool _consumeAiUse() {
    if (_isAiUnlimited) return true; // AI 구독자는 무제한
    if (_aiRemaining <= 0) return false;
    setState(() => _aiRemaining--);
    _saveAiRemaining(_aiRemaining);
    return true;
  }

  void _rechargeAiUses() {
    setState(() => _aiRemaining = _maxAiUses);
    _saveAiRemaining(_maxAiUses);
  }

  Future<void> _fetchAiExplanation([AiLevel? level]) async {
    final targetLevel = level ?? _aiLevel;
    if (_aiCache.containsKey(targetLevel)) return;

    if (!_consumeAiUse()) {
      // 사용 횟수 소진 - 인라인 패널에서 표시
      setState(() => _isAiExhausted = true);
      return;
    }

    setState(() {
      _isAiLoading = true;
      _aiError = null;
    });

    final langCode = Localizations.localeOf(context).languageCode;

    final result = await FirebaseAiService().explainSimulation(
      simId: widget.simId ?? widget.title,
      title: widget.title,
      description: widget.formulaDescription ?? widget.title,
      category: widget.category,
      languageCode: langCode,
      level: targetLevel,
      formula: widget.formula,
      subcategory: null,
      isPro: _isAiUnlimited,
    );

    if (!mounted) return;

    setState(() {
      _isAiLoading = false;
      if (result.startsWith('Error:')) {
        _aiError = _localizeAiError(result);
        // 에러 시 사용 횟수 환불
        if (!_isAiUnlimited) {
          _aiRemaining++;
          _saveAiRemaining(_aiRemaining);
        }
      } else {
        _aiCache[targetLevel] = result;
      }
    });
  }

  void _showAiSubscriptionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SubscriptionDialog(),
    );
  }

  void _watchRewardedAd() {
    AdService().showRewardedInterstitialAd(
      onRewarded: () {
        _rechargeAiUses();
        if (mounted) {
          setState(() => _isAiExhausted = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isKoreanLocale(context)
                    ? 'AI 해설 3회 충전 완료!'
                    : '3 AI explanations recharged!',
              ),
              backgroundColor: const Color(0xFF7C3AED),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
      onFailed: () {
        // 광고 로드 실패 시 무료로 1회 제공
        if (mounted) {
          setState(() {
            _aiRemaining = 1;
            _isAiExhausted = false;
          });
          _saveAiRemaining(1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isKoreanLocale(context)
                    ? '광고를 불러올 수 없어 1회 무료 제공합니다'
                    : 'Ad unavailable. 1 free explanation granted.',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
    );
  }

  String _localizeAiError(String errorCode) {
    final isKo = _isKoreanLocale(context);
    switch (errorCode) {
      case 'Error:TIMEOUT':
        return isKo
            ? '요청 시간이 초과되었습니다. 다시 시도해주세요.'
            : 'Request timed out. Please try again.';
      case 'Error:AUTH':
        return isKo
            ? 'AI 서비스 인증에 실패했습니다. 잠시 후 다시 시도해주세요.'
            : 'AI auth failed. Please try again later.';
      case 'Error:RATE_LIMIT':
        return isKo
            ? '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.'
            : 'Too many requests. Please try again later.';
      case 'Error:SERVER':
        return isKo
            ? 'AI 서버에 일시적인 문제가 있습니다.'
            : 'AI server is temporarily unavailable.';
      case 'Error:NETWORK':
        return isKo
            ? '네트워크 연결을 확인해주세요.'
            : 'Please check your network connection.';
      case 'Error:NO_KEY':
        return isKo ? 'AI 서비스가 설정되지 않았습니다.' : 'AI service is not configured.';
      case 'Error:NOT_ENABLED':
        return isKo
            ? 'Firebase AI가 활성화되지 않았습니다. Firebase Console에서 AI Logic을 활성화하세요.'
            : 'Firebase AI not enabled. Enable AI Logic in Firebase Console.';
      default:
        return isKo
            ? 'AI 해설을 불러올 수 없습니다. 네트워크를 확인하고 다시 시도해주세요.'
            : 'Could not load AI explanation. Check network and try again.';
    }
  }

  void _toggleAi() {
    HapticFeedback.lightImpact();
    setState(() => _isAiOpen = !_isAiOpen);
    if (_isAiOpen && !_aiCache.containsKey(_aiLevel) && !_isAiLoading) {
      _fetchAiExplanation();
    }
  }

  void _changeAiLevel(AiLevel level) {
    HapticFeedback.selectionClick();
    setState(() => _aiLevel = level);
    if (_isAiOpen && !_aiCache.containsKey(level) && !_isAiLoading) {
      _fetchAiExplanation(level);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          // S-009: 그림자
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // S-002: 카테고리 라벨
                      Text(
                        widget.category.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // S-003: 제목
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // S-004~S-006: 액션 버튼들
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onHelp != null)
                      _ActionButton(
                        icon: Icons.help_outline,
                        onTap: widget.onHelp!,
                        tooltip: _isKoreanLocale(context) ? '도움말' : 'Help',
                      ),
                    if (widget.onShare != null) ...[
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.share_outlined,
                        onTap: widget.onShare!,
                        tooltip: _isKoreanLocale(context) ? '공유' : 'Share',
                      ),
                    ],
                    if (widget.onFullscreen != null ||
                        widget.simulationBuilder != null) ...[
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.fullscreen,
                        onTap:
                            widget.onFullscreen ??
                            () => openFullscreenSim(
                              context,
                              simulationBuilder: widget.simulationBuilder!,
                              title: widget.title,
                            ),
                        tooltip: _isKoreanLocale(context)
                            ? '전체화면'
                            : 'Fullscreen',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // AI 해설 영역: 버튼 + 수준 칩을 한 줄로 통합
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _AiButtonRow(
              isActive: _isAiOpen,
              onTap: _toggleAi,
              remaining: _isAiUnlimited ? null : _aiRemaining,
              maxUses: _maxAiUses,
              currentLevel: _aiLevel,
              onLevelChange: _changeAiLevel,
              isLoading: _isAiLoading,
            ),
          ),
          const SizedBox(height: 8),

          // AI 해설 패널
          if (_isAiOpen)
            _AiExplanationPanel(
              isLoading: _isAiLoading,
              explanation: _aiCache[_aiLevel],
              error: _aiError,
              onRetry: _fetchAiExplanation,
              onClose: () => setState(() {
                _isAiOpen = false;
                _isAiExhausted = false;
              }),
              isExhausted: _isAiExhausted && !_isAiUnlimited,
              onWatchAd: _watchRewardedAd,
              onSubscribe: _showAiSubscriptionDialog,
            ),

          // S-013~S-017: 수식 표시 (접을 수 있는 섹션)
          if (widget.formula != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FormulaSection(
                formula: widget.formula!,
                description: widget.formulaDescription,
                isExpanded: _isFormulaExpanded,
                onToggle: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isFormulaExpanded = !_isFormulaExpanded);
                },
              ),
            ),

          const SizedBox(height: 12),

          // S-007~S-012: 시뮬레이션 영역
          Container(
            // S-007: 높이 - landscape에서는 화면 높이를 최대한 활용
            height: isLandscape
                ? (screenHeight * 0.55).clamp(200.0, 500.0)
                : (screenHeight * 0.45).clamp(280.0, 400.0),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.simBg,
              // S-008: 모서리 반경
              borderRadius: BorderRadius.circular(16),
              // S-010: 테두리
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  widget.simulation,
                  // S-011: 로딩 상태
                  if (_isLoading)
                    Container(
                      color: AppColors.simBg.withValues(alpha: 0.8),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // S-018~S-024: 컨트롤 패널
          if (widget.controls != null)
            Padding(padding: const EdgeInsets.all(20), child: widget.controls!),

          // S-025~S-030: 버튼 그룹
          if (widget.buttons != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: widget.buttons!,
            ),

          // 커뮤니티 섹션 (댓글 + 퀴즈)
          // simId: 명시적 전달 또는 GoRouter 경로에서 자동 추출
          Builder(builder: (context) {
            final effectiveSimId = widget.simId
                ?? GoRouterState.of(context).pathParameters['simId'];
            if (effectiveSimId == null) return const SizedBox.shrink();
            return Column(
              children: [
                const Divider(color: AppColors.cardBorder, height: 32),
                _SimQuizButton(
                  simId: effectiveSimId,
                  title: widget.title,
                  category: widget.category,
                  formula: widget.formula,
                  aiLevel: _aiLevel,
                ),
                const SizedBox(height: 8),
                CommentSection(simId: effectiveSimId),
              ],
            );
          }),

          // 하단 여백 (배너 광고는 Scaffold 외부에서 표시)
          SizedBox(height: isLandscape ? 20 : 24),
        ],
      ),
    );
  }
}

/// 퀴즈 챌린지 버튼 — 반복 도전 가능, XP는 최초 1회만
class _SimQuizButton extends StatefulWidget {
  final String simId;
  final String title;
  final String category;
  final String? formula;
  final AiLevel aiLevel;

  const _SimQuizButton({
    required this.simId,
    required this.title,
    required this.category,
    this.formula,
    required this.aiLevel,
  });

  @override
  State<_SimQuizButton> createState() => _SimQuizButtonState();
}

class _SimQuizButtonState extends State<_SimQuizButton>
    with SingleTickerProviderStateMixin {
  bool _completed = false;
  bool _checked = false;
  late AnimationController _neonCtrl;

  @override
  void initState() {
    super.initState();
    _neonCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _neonCtrl.repeat();
    });
    _checkCompletion();
  }

  @override
  void dispose() {
    _neonCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkCompletion() async {
    try {
      final done = await CommunityService().hasCompletedQuiz(widget.simId);
      if (mounted) setState(() { _completed = done; _checked = true; });
    } catch (_) {
      if (mounted) setState(() => _checked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) return const SizedBox.shrink();

    final isKorean = _isKoreanLocale(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () async {
          await QuizDialog.show(
            context,
            simId: widget.simId,
            title: widget.title,
            description: '',
            category: widget.category,
            formula: widget.formula,
            aiLevel: widget.aiLevel,
          );
          _checkCompletion();
        },
        child: AnimatedBuilder(
          animation: _neonCtrl,
          builder: (context, child) {
            final t = _neonCtrl.value;
            final sweepCenter = t * 1.4 - 0.2;
            final glowColor = HSLColor.fromAHSL(0.3, t * 360, 1, 0.5).toColor();
            return CustomPaint(
              painter: _RainbowBorderPainter(sweepCenter: sweepCenter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1030),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: glowColor, blurRadius: 12, spreadRadius: 1)],
                ),
                child: child,
              ),
            );
          },
          child: Row(
            children: [
              Icon(
                _completed ? Icons.check_circle : Icons.quiz,
                color: _completed ? const Color(0xFF4CAF50) : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _completed
                      ? (isKorean ? '퀴즈 다시 도전' : 'Retake Quiz')
                      : (isKorean ? '퀴즈 챌린지 (+15 XP)' : 'Quiz Challenge (+15 XP)'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// AI 해설 버튼 + 난이도 칩을 한 줄로 통합한 위젯
class _AiButtonRow extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  final int? remaining;
  final int maxUses;
  final AiLevel currentLevel;
  final ValueChanged<AiLevel> onLevelChange;
  final bool isLoading;

  const _AiButtonRow({
    required this.isActive,
    required this.onTap,
    this.remaining,
    required this.maxUses,
    required this.currentLevel,
    required this.onLevelChange,
    required this.isLoading,
  });

  static const _levelLabelsKo = {
    AiLevel.middle: '중학생',
    AiLevel.high: '고등학생',
    AiLevel.university: '대학',
    AiLevel.general: '일반인',
  };

  static const _levelLabelsEn = {
    AiLevel.middle: 'Middle',
    AiLevel.high: 'High',
    AiLevel.university: 'Univ',
    AiLevel.general: 'General',
  };

  @override
  Widget build(BuildContext context) {
    final isKo = _isKoreanLocale(context);
    final labels = isKo ? _levelLabelsKo : _levelLabelsEn;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: isActive ? 0.15 : 0.07),
            const Color(0xFF7C3AED).withValues(alpha: isActive ? 0.15 : 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // AI 해설 toggle button
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.25),
                          const Color(0xFF7C3AED).withValues(alpha: 0.25),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? Icons.close_rounded : Icons.auto_awesome,
                    size: 15,
                    color: isActive ? AppColors.accent : const Color(0xFFC4B5FD),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isKo
                        ? (isActive ? '닫기' : 'AI 해설')
                        : (isActive ? 'Close' : 'AI Explain'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.accent : const Color(0xFFC4B5FD),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 남은 횟수 badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      remaining == null ? '∞' : '$remaining/$maxUses',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Separator
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: AppColors.accent.withValues(alpha: 0.15),
          ),
          // Difficulty chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AiLevel.values.map((level) {
                  final isSelected = level == currentLevel;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: isLoading ? null : () => onLevelChange(level),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accent.withValues(alpha: 0.6)
                                : AppColors.muted.withValues(alpha: 0.25),
                            width: isSelected ? 1.2 : 0.8,
                          ),
                        ),
                        child: Text(
                          labels[level]!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.muted.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AI 해설 패널 — 그라데이션 보더, 개선된 타이포그래피
class _AiExplanationPanel extends StatelessWidget {
  final bool isLoading;
  final String? explanation;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onClose;
  final bool isExhausted;
  final VoidCallback? onWatchAd;
  final VoidCallback? onSubscribe;

  const _AiExplanationPanel({
    required this.isLoading,
    this.explanation,
    this.error,
    required this.onRetry,
    required this.onClose,
    this.isExhausted = false,
    this.onWatchAd,
    this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final isKo = _isKoreanLocale(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Gradient border via outer container
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.4),
              const Color(0xFF7C3AED).withValues(alpha: 0.3),
              AppColors.accent.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(1.2),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.2),
                          const Color(0xFF7C3AED).withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isKo ? 'AI 해설' : 'AI Explanation',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Subtle divider
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.3),
                      const Color(0xFF7C3AED).withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Content
              if (isExhausted)
                _buildExhaustedContent(context, isKo)
              else if (isLoading)
                _buildLoadingContent(isKo)
              else if (error != null)
                _buildErrorContent(context, isKo)
              else if (explanation != null)
                _buildExplanationContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExhaustedContent(BuildContext context, bool isKo) {
    return Column(
      children: [
        Icon(
          Icons.battery_alert_rounded,
          size: 28,
          color: AppColors.accent2.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 8),
        Text(
          isKo
              ? '오늘의 무료 AI 해설을 모두 사용했어요'
              : "You've used today's free AI explanations",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isKo ? '내일 다시 3회 충전됩니다' : 'Resets daily with 3 free uses',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onWatchAd,
            icon: const Icon(Icons.play_circle_outline, size: 16),
            label: Text(
              isKo ? '광고 보고 3회 충전' : 'Watch ad for 3 more',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.bg,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onSubscribe,
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: Text(
              isKo ? 'AI 무제한 구독' : 'Unlimited AI subscription',
              style: const TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContent(bool isKo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isKo ? 'AI가 해설을 작성하고 있어요...' : 'AI is writing an explanation...',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, bool isKo) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCA5A5).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFCA5A5).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: Color(0xFFFCA5A5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error!,
                  style: const TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              isKo ? '다시 시도' : 'Retry',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          explanation!,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13.5,
            height: 1.75,
            fontFamilyFallback: ['Noto Sans', 'Roboto', 'sans-serif'],
          ),
        ),
        const SizedBox(height: 14),
        // 네이티브 광고 (AI 해설 내)
        const NativeAdWidget(),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 10,
                color: AppColors.accent.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 4),
              Text(
                _isKoreanLocale(context) ? 'Firebase AI 기반' : 'Powered by Firebase AI',
                style: TextStyle(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// S-004~S-006: 액션 버튼
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(icon, size: 18, color: AppColors.muted),
        ),
      ),
    );
  }
}

/// S-013~S-017: 수식 섹션
class _FormulaSection extends StatelessWidget {
  final String formula;
  final String? description;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _FormulaSection({
    required this.formula,
    this.description,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isExpanded
                ? AppColors.accent.withValues(alpha: 0.3)
                : AppColors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.functions, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                // S-014: 수식 폰트 (수학 기호 지원 — Noto Sans 우선)
                Expanded(
                  child: Text(
                    formula,
                    style:
                        GoogleFonts.notoSans(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ).copyWith(
                          fontFamilyFallback: const [
                            'Noto Sans KR',
                            'Roboto',
                            'sans-serif',
                          ],
                        ),
                  ),
                ),
                // S-016: 복사 버튼
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: formula));
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isKoreanLocale(context)
                              ? '수식이 복사되었습니다'
                              : 'Formula copied',
                        ),
                        backgroundColor: AppColors.accent,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.copy,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.muted,
                ),
              ],
            ),
            // S-015: 설명 (펼쳤을 때)
            if (isExpanded && description != null) ...[
              const SizedBox(height: 10),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 10),
              Text(
                description!,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 퀴즈 버튼 레인보우 네온 보더 페인터
class _RainbowBorderPainter extends CustomPainter {
  final double sweepCenter;
  _RainbowBorderPainter({required this.sweepCenter});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(sweepCenter - 0.3, 0),
        end: Alignment(sweepCenter + 0.3, 0),
        colors: const [
          Color(0x30FFFFFF),
          Color(0xFFFF0080),
          Color(0xFFFF8C00),
          Color(0xFFFFFF00),
          Color(0xFF00FF88),
          Color(0xFF00CCFF),
          Color(0xFFAA00FF),
          Color(0x30FFFFFF),
        ],
        stops: const [0.0, 0.15, 0.3, 0.45, 0.6, 0.75, 0.9, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _RainbowBorderPainter old) => old.sweepCenter != sweepCenter;
}
