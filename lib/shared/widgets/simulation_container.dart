import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

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
  });

  @override
  State<SimulationContainer> createState() => _SimulationContainerState();
}

class _SimulationContainerState extends State<SimulationContainer> {
  // S-013, S-017: 수식 섹션 접힘 상태
  bool _isFormulaExpanded = false;

  // S-011: 로딩 상태
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

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
                        tooltip: '도움말',
                      ),
                    if (widget.onShare != null) ...[
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.share_outlined,
                        onTap: widget.onShare!,
                        tooltip: '공유',
                      ),
                    ],
                    if (widget.onFullscreen != null) ...[
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.fullscreen,
                        onTap: widget.onFullscreen!,
                        tooltip: '전체화면',
                      ),
                    ],
                  ],
                ),
              ],
            ),
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
            // S-007: 높이 - 화면의 45% 또는 최소 280px
            height: (screenHeight * 0.45).clamp(280.0, 400.0),
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
        ],
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
                // S-014: 수식 폰트 (LaTeX 스타일)
                Expanded(
                  child: Text(
                    formula,
                    style: const TextStyle(
                      fontFamily: 'monospace',
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
                        content: const Text('수식이 복사되었습니다'),
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
