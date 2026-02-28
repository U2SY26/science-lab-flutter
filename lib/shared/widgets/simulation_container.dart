import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/iap_service.dart';
import 'ad_banner.dart';
import 'fullscreen_sim_view.dart';

/// Helper to check if current locale is Korean
bool _isKoreanLocale(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'ko';
}

const int _maxAiUses = 3;
const String _aiRemainingKey = 'ai_explanation_remaining';

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
  bool _isLoading = false;

  // AI explanation state
  bool _isAiOpen = false;
  bool _isAiLoading = false;
  AiLevel _aiLevel = AiLevel.high;
  final Map<AiLevel, String> _aiCache = {};
  String? _aiError;

  // AI usage limit
  int _aiRemaining = _maxAiUses;
  bool _adsRemoved = false;

  @override
  void initState() {
    super.initState();
    _loadAiRemaining();
    _adsRemoved = IAPService().adsRemoved;
  }

  Future<void> _loadAiRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aiRemaining = prefs.getInt(_aiRemainingKey) ?? _maxAiUses;
    });
  }

  Future<void> _saveAiRemaining(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_aiRemainingKey, value);
  }

  bool _consumeAiUse() {
    if (_adsRemoved) return true; // 광고 제거 구매자는 무제한
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
      // 사용 횟수 소진 - 보상형 광고 다이얼로그 표시
      _showRewardedAdDialog();
      return;
    }

    setState(() {
      _isAiLoading = true;
      _aiError = null;
    });

    final langCode = Localizations.localeOf(context).languageCode;

    final result = await GeminiService().explainSimulation(
      simId: widget.simId ?? widget.title,
      title: widget.title,
      description: widget.formulaDescription ?? widget.title,
      category: widget.category,
      languageCode: langCode,
      level: targetLevel,
      formula: widget.formula,
      subcategory: null,
    );

    if (!mounted) return;

    setState(() {
      _isAiLoading = false;
      if (result.startsWith('Error')) {
        _aiError = result;
        // 에러 시 사용 횟수 환불
        if (!_adsRemoved) {
          _aiRemaining++;
          _saveAiRemaining(_aiRemaining);
        }
      } else {
        _aiCache[targetLevel] = result;
      }
    });
  }

  void _showRewardedAdDialog() {
    final isKo = _isKoreanLocale(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isKo ? 'AI 해설 횟수 소진' : 'AI Explanations Used Up',
          style: const TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          isKo
              ? '무료 AI 해설 횟수를 모두 사용했습니다.\n광고를 시청하면 3회 더 사용할 수 있습니다.'
              : 'You\'ve used all free AI explanations.\nWatch an ad to get 3 more.',
          style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              isKo ? '취소' : 'Cancel',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _watchRewardedAd();
            },
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: Text(isKo ? '광고 보고 3회 충전' : 'Watch ad for 3 more'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _watchRewardedAd() {
    AdService().showRewardedInterstitialAd(
      onRewarded: () {
        _rechargeAiUses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isKoreanLocale(context) ? 'AI 해설 3회 충전 완료!' : '3 AI explanations recharged!'),
              backgroundColor: const Color(0xFF7C3AED),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      },
      onFailed: () {
        // 광고 로드 실패 시 무료로 1회 제공
        if (mounted) {
          setState(() => _aiRemaining = 1);
          _saveAiRemaining(1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isKoreanLocale(context)
                  ? '광고를 불러올 수 없어 1회 무료 제공합니다'
                  : 'Ad unavailable. 1 free explanation granted.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      },
    );
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

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
                        onTap: widget.onFullscreen ??
                            () => openFullscreenSim(
                                  context,
                                  simulationBuilder:
                                      widget.simulationBuilder!,
                                  title: widget.title,
                                ),
                        tooltip:
                            _isKoreanLocale(context) ? '전체화면' : 'Fullscreen',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // AI 해설 영역: 수준 선택 + 버튼 + 패널
          if (GeminiService().isAvailable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 수준 선택 (항상 노출)
                  _AiLevelSelector(
                    currentLevel: _aiLevel,
                    onLevelChange: _changeAiLevel,
                    isLoading: _isAiLoading,
                  ),
                  const SizedBox(height: 8),
                  // AI 버튼 + 남은 횟수
                  _AiButton(
                    isActive: _isAiOpen,
                    onTap: _toggleAi,
                    remaining: _adsRemoved ? null : _aiRemaining,
                    maxUses: _maxAiUses,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

          // AI 해설 패널
          if (_isAiOpen)
            _AiExplanationPanel(
              isLoading: _isAiLoading,
              explanation: _aiCache[_aiLevel],
              error: _aiError,
              onRetry: _fetchAiExplanation,
              onClose: () => setState(() => _isAiOpen = false),
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: widget.controls!,
            ),

          // S-025~S-030: 버튼 그룹
          if (widget.buttons != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: widget.buttons!,
            ),

          // 하단 여백 (배너 광고는 Scaffold 외부에서 표시)
          SizedBox(height: isLandscape ? 20 : 24),
        ],
      ),
    );
  }
}

/// AI 수준 선택기 (항상 노출)
class _AiLevelSelector extends StatelessWidget {
  final AiLevel currentLevel;
  final ValueChanged<AiLevel> onLevelChange;
  final bool isLoading;

  const _AiLevelSelector({
    required this.currentLevel,
    required this.onLevelChange,
    required this.isLoading,
  });

  static const _levelLabelsKo = {
    AiLevel.middle: '중학생',
    AiLevel.high: '고등학생',
    AiLevel.university: '대학/전공',
    AiLevel.general: '일반인',
  };

  static const _levelLabelsEn = {
    AiLevel.middle: 'Middle',
    AiLevel.high: 'High School',
    AiLevel.university: 'University',
    AiLevel.general: 'General',
  };

  @override
  Widget build(BuildContext context) {
    final isKo = _isKoreanLocale(context);
    final labels = isKo ? _levelLabelsKo : _levelLabelsEn;

    return Row(
      children: [
        Text(
          isKo ? '설명 수준' : 'Level',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7C3AED).withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: AiLevel.values.map((level) {
              final isActive = level == currentLevel;
              return GestureDetector(
                onTap: isLoading ? null : () => onLevelChange(level),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                          : const Color(0xFF7C3AED).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    labels[level]!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? const Color(0xFFA777FF)
                          : const Color(0xFF7C3AED).withValues(alpha: 0.6),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// AI 해설 버튼 (남은 횟수 표시)
class _AiButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  final int? remaining; // null이면 무제한 (광고 제거 구매자)
  final int maxUses;

  const _AiButton({
    required this.isActive,
    required this.onTap,
    this.remaining,
    required this.maxUses,
  });

  @override
  Widget build(BuildContext context) {
    final isKo = _isKoreanLocale(context);
    return Tooltip(
      message: isKo ? 'AI 해설' : 'AI Explanation',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [const Color(0xFF7C3AED).withValues(alpha: 0.3), const Color(0xFF3B82F6).withValues(alpha: 0.3)]
                  : [const Color(0xFF7C3AED).withValues(alpha: 0.15), const Color(0xFF3B82F6).withValues(alpha: 0.15)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.6)
                  : const Color(0xFF7C3AED).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '✦',
                style: TextStyle(
                  fontSize: 14,
                  color: isActive ? const Color(0xFFDDD6FE) : const Color(0xFFC4B5FD),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isKo ? (isActive ? '닫기' : 'AI 해설') : (isActive ? 'Close' : 'AI Explain'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? const Color(0xFFDDD6FE) : const Color(0xFFC4B5FD),
                ),
              ),
              if (remaining != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$remaining/$maxUses',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC4B5FD),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// AI 해설 패널 (수준 선택 제거 - 상위로 이동)
class _AiExplanationPanel extends StatelessWidget {
  final bool isLoading;
  final String? explanation;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _AiExplanationPanel({
    required this.isLoading,
    this.explanation,
    this.error,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isKo = _isKoreanLocale(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text('✦', style: TextStyle(fontSize: 16, color: Color(0xFFC4B5FD))),
                const SizedBox(width: 6),
                Text(
                  isKo ? 'AI 해설' : 'AI Explanation',
                  style: const TextStyle(
                    color: Color(0xFFC4B5FD),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: Icon(Icons.close, size: 18, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content
            if (isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Color(0xFF7C3AED),
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isKo ? 'AI 도움말 생성중...' : 'Generating AI help...',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else if (error != null)
              Column(
                children: [
                  Text(error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(
                      isKo ? '다시 시도' : 'Retry',
                      style: const TextStyle(color: Color(0xFFFCA5A5)),
                    ),
                  ),
                ],
              )
            else if (explanation != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    explanation!,
                    style: const TextStyle(color: AppColors.ink, fontSize: 13, height: 1.7),
                  ),
                  const SizedBox(height: 12),
                  // 네이티브 광고 (AI 해설 내)
                  const NativeAdWidget(),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Powered by GPT',
                      style: TextStyle(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
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
          child: Icon(
            icon,
            size: 18,
            color: AppColors.muted,
          ),
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
            color: isExpanded ? AppColors.accent.withValues(alpha: 0.3) : AppColors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.functions,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                // S-014: 수식 폰트 (수학 기호 지원)
                Expanded(
                  child: Text(
                    formula,
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
                        content: Text(_isKoreanLocale(context) ? '수식이 복사되었습니다' : 'Formula copied'),
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
