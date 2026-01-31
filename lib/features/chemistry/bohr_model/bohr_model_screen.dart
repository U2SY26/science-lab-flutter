import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 보어 원자 모델 시뮬레이션
class BohrModelScreen extends StatefulWidget {
  const BohrModelScreen({super.key});

  @override
  State<BohrModelScreen> createState() => _BohrModelScreenState();
}

class _BohrModelScreenState extends State<BohrModelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int _atomicNumber = 6; // 탄소
  bool _showOrbits = true;
  bool _showLabels = true;
  double _speed = 1.0;

  // 원소 정보
  static const Map<int, String> _elements = {
    1: 'H (수소)',
    2: 'He (헬륨)',
    3: 'Li (리튬)',
    4: 'Be (베릴륨)',
    5: 'B (붕소)',
    6: 'C (탄소)',
    7: 'N (질소)',
    8: 'O (산소)',
    9: 'F (플루오린)',
    10: 'Ne (네온)',
    11: 'Na (나트륨)',
    12: 'Mg (마그네슘)',
    13: 'Al (알루미늄)',
    14: 'Si (규소)',
    15: 'P (인)',
    16: 'S (황)',
    17: 'Cl (염소)',
    18: 'Ar (아르곤)',
  };

  // 전자 배치 (2, 8, 8)
  List<int> get _electronConfig {
    int remaining = _atomicNumber;
    List<int> config = [];
    List<int> maxPerShell = [2, 8, 8, 18, 18, 32];

    for (int max in maxPerShell) {
      if (remaining <= 0) break;
      int electrons = remaining > max ? max : remaining;
      config.add(electrons);
      remaining -= electrons;
    }
    return config;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '화학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '보어 원자 모델',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학',
          title: '보어 원자 모델',
          formula: 'E_n = -13.6/n² eV',
          formulaDescription: '전자가 특정 궤도(에너지 준위)에서만 존재할 수 있다는 보어의 원자 모델',
          simulation: SizedBox(
            height: 350,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BohrModelPainter(
                    atomicNumber: _atomicNumber,
                    electronConfig: _electronConfig,
                    animation: _controller.value * _speed,
                    showOrbits: _showOrbits,
                    showLabels: _showLabels,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 원소 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoItem(
                      label: '원소',
                      value: _elements[_atomicNumber] ?? 'Unknown',
                      color: AppColors.accent,
                    ),
                    _InfoItem(
                      label: '원자번호',
                      value: '$_atomicNumber',
                      color: AppColors.accent2,
                    ),
                    _InfoItem(
                      label: '전자배치',
                      value: _electronConfig.join('-'),
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 원자번호 슬라이더
              ControlGroup(
                primaryControl: SimSlider(
                  label: '원자번호 (Z)',
                  value: _atomicNumber.toDouble(),
                  min: 1,
                  max: 18,
                  defaultValue: 6,
                  formatValue: (v) => '${v.toInt()} (${_elements[v.toInt()]?.split(' ')[0] ?? ""})',
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _atomicNumber = v.toInt());
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '회전 속도',
                    value: _speed,
                    min: 0.1,
                    max: 3.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() => _speed = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 옵션 토글
              Row(
                children: [
                  Expanded(
                    child: _OptionChip(
                      label: '궤도 표시',
                      isSelected: _showOrbits,
                      onTap: () => setState(() => _showOrbits = !_showOrbits),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OptionChip(
                      label: '레이블 표시',
                      isSelected: _showLabels,
                      onTap: () => setState(() => _showLabels = !_showLabels),
                    ),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: 'H (1)',
                icon: Icons.filter_1,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _atomicNumber = 1);
                },
              ),
              SimButton(
                label: 'C (6)',
                icon: Icons.filter_6,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _atomicNumber = 6);
                },
              ),
              SimButton(
                label: 'Ne (10)',
                icon: Icons.filter_9_plus,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _atomicNumber = 10);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : AppColors.simBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.cardBorder,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.accent : AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _BohrModelPainter extends CustomPainter {
  final int atomicNumber;
  final List<int> electronConfig;
  final double animation;
  final bool showOrbits;
  final bool showLabels;

  _BohrModelPainter({
    required this.atomicNumber,
    required this.electronConfig,
    required this.animation,
    required this.showOrbits,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 30;

    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    // 핵 (양성자 + 중성자)
    final nucleusPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    // 핵 글로우
    canvas.drawCircle(
      center,
      25,
      Paint()..color = AppColors.accent.withValues(alpha: 0.2),
    );
    canvas.drawCircle(center, 18, nucleusPaint);

    // 핵 내부 표시 (양성자 수)
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$atomicNumber+',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    // 전자 궤도 및 전자 그리기
    final shellColors = [
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFFFF6B6B),
      const Color(0xFF95E1D3),
    ];

    for (int shell = 0; shell < electronConfig.length; shell++) {
      final radius = 45 + shell * (maxRadius - 45) / electronConfig.length;
      final electronCount = electronConfig[shell];
      final color = shellColors[shell % shellColors.length];

      // 궤도 그리기
      if (showOrbits) {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = color.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      // 에너지 준위 레이블
      if (showLabels) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: 'n=${shell + 1}',
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(center.dx + radius + 5, center.dy - labelPainter.height / 2),
        );
      }

      // 전자 그리기
      for (int e = 0; e < electronCount; e++) {
        final baseAngle = (2 * math.pi * e / electronCount);
        final rotationSpeed = 1.0 / (shell + 1); // 외부 궤도는 더 느리게
        final angle = baseAngle + animation * 2 * math.pi * rotationSpeed;

        final electronPos = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );

        // 전자 글로우
        canvas.drawCircle(
          electronPos,
          8,
          Paint()..color = color.withValues(alpha: 0.3),
        );

        // 전자
        canvas.drawCircle(
          electronPos,
          5,
          Paint()..color = color,
        );

        // 전자 하이라이트
        canvas.drawCircle(
          Offset(electronPos.dx - 1.5, electronPos.dy - 1.5),
          1.5,
          Paint()..color = Colors.white.withValues(alpha: 0.6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BohrModelPainter oldDelegate) {
    return oldDelegate.animation != animation ||
           oldDelegate.atomicNumber != atomicNumber ||
           oldDelegate.showOrbits != showOrbits ||
           oldDelegate.showLabels != showLabels;
  }
}
