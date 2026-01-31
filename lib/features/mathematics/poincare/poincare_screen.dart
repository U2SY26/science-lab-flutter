import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 푸앵카레 추측 시각화 (해결됨 - 페렐만)
class PoincareScreen extends StatefulWidget {
  const PoincareScreen({super.key});

  @override
  State<PoincareScreen> createState() => _PoincareScreenState();
}

class _PoincareScreenState extends State<PoincareScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  String _shape = 'sphere';
  double _deformation = 0;
  bool _showLoop = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
              '밀레니엄 난제',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '푸앵카레 추측',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 14),
                SizedBox(width: 4),
                Text('해결됨', style: TextStyle(color: Colors.green, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '밀레니엄 난제',
          title: '푸앵카레 추측 (Poincaré Conjecture)',
          formula: 'π₁(M) = 0 ⟹ M ≅ S³',
          formulaDescription: '단순 연결된 3차원 다양체는 3차원 구와 위상동형',
          simulation: SizedBox(
            height: 300,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _PoincarePainter(
                    shape: _shape,
                    deformation: _deformation,
                    showLoop: _showLoop,
                    animation: _controller.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 설명
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '2003년 페렐만이 증명 (상금 거부)',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '모든 닫힌 루프가 한 점으로 수축될 수 있는 3차원 다양체는 '
                      '3차원 구와 위상적으로 같다는 추측입니다.\n\n'
                      '그리고리 페렐만은 리치 흐름을 사용하여 이를 증명했습니다.',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 도형 선택
              PresetGroup(
                label: '도형',
                presets: [
                  PresetButton(
                    label: '구 (S²)',
                    isSelected: _shape == 'sphere',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _shape = 'sphere');
                    },
                  ),
                  PresetButton(
                    label: '토러스',
                    isSelected: _shape == 'torus',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _shape = 'torus');
                    },
                  ),
                  PresetButton(
                    label: '2중 토러스',
                    isSelected: _shape == 'double-torus',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _shape = 'double-torus');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 루프 표시 토글
              Row(
                children: [
                  const Text('루프 표시', style: TextStyle(color: AppColors.muted)),
                  const Spacer(),
                  Switch(
                    value: _showLoop,
                    onChanged: (v) => setState(() => _showLoop = v),
                    activeColor: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '변형',
                  value: _deformation,
                  min: 0,
                  max: 1,
                  defaultValue: 0,
                  formatValue: (v) => '${(v * 100).toInt()}%',
                  onChanged: (v) => setState(() => _deformation = v),
                ),
              ),

              const SizedBox(height: 16),

              // 핵심 개념 설명
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '단순 연결성 테스트',
                      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TopologyInfo(
                            shape: '구',
                            canShrink: true,
                            isSelected: _shape == 'sphere',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TopologyInfo(
                            shape: '토러스',
                            canShrink: false,
                            isSelected: _shape == 'torus' || _shape == 'double-torus',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopologyInfo extends StatelessWidget {
  final String shape;
  final bool canShrink;
  final bool isSelected;

  const _TopologyInfo({
    required this.shape,
    required this.canShrink,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? (canShrink ? Colors.green : Colors.red).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? (canShrink ? Colors.green : Colors.red).withValues(alpha: 0.5)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Text(shape, style: const TextStyle(color: AppColors.ink, fontSize: 11)),
          const SizedBox(height: 4),
          Icon(
            canShrink ? Icons.check_circle : Icons.cancel,
            color: canShrink ? Colors.green : Colors.red,
            size: 16,
          ),
          Text(
            canShrink ? '수축 가능' : '수축 불가',
            style: TextStyle(
              color: canShrink ? Colors.green : Colors.red,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _PoincarePainter extends CustomPainter {
  final String shape;
  final double deformation;
  final bool showLoop;
  final double animation;

  _PoincarePainter({
    required this.shape,
    required this.deformation,
    required this.showLoop,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.35;

    switch (shape) {
      case 'sphere':
        _drawSphere(canvas, center, radius);
        break;
      case 'torus':
        _drawTorus(canvas, center, radius);
        break;
      case 'double-torus':
        _drawDoubleTorus(canvas, center, radius);
        break;
    }

    // 설명 텍스트
    final text = shape == 'sphere'
        ? '구: 모든 루프가 한 점으로 수축 가능 → 단순 연결'
        : shape == 'torus'
            ? '토러스: 구멍을 감싸는 루프는 수축 불가 → 단순 연결 아님'
            : '2중 토러스: 더 복잡한 위상 → 단순 연결 아님';

    _drawText(canvas, text, Offset(10, size.height - 25), AppColors.muted, fontSize: 10);
  }

  void _drawSphere(Canvas canvas, Offset center, double radius) {
    // 변형된 구
    final deformedRadius = radius * (1 - deformation * 0.3);

    // 구 그리기 (타원으로 3D 효과)
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: deformedRadius * 2, height: deformedRadius * 1.8),
      paint,
    );

    // 경계선
    canvas.drawOval(
      Rect.fromCenter(center: center, width: deformedRadius * 2, height: deformedRadius * 1.8),
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 경도선
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      _drawMeridian(canvas, center, deformedRadius, angle);
    }

    // 위도선
    for (int i = 1; i < 4; i++) {
      final y = center.dy + (i - 2) * deformedRadius * 0.4;
      final w = deformedRadius * math.sqrt(1 - math.pow((i - 2) * 0.4, 2));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, y), width: w * 2, height: w * 0.3),
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // 루프 애니메이션
    if (showLoop) {
      final loopProgress = (animation * 2) % 1.0;
      final loopSize = deformedRadius * 0.4 * (1 - loopProgress);

      if (loopSize > 5) {
        canvas.drawCircle(
          center,
          loopSize,
          Paint()
            ..color = Colors.green.withValues(alpha: 1 - loopProgress)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }

      // 수축 화살표
      _drawText(canvas, '→ 수축 가능!', Offset(center.dx + deformedRadius + 10, center.dy - 10), Colors.green, fontSize: 11);
    }
  }

  void _drawMeridian(Canvas canvas, Offset center, double radius, double angle) {
    final path = Path();
    for (int i = 0; i <= 20; i++) {
      final t = i / 20 * math.pi;
      final x = center.dx + radius * math.sin(t) * math.cos(angle);
      final y = center.dy - radius * math.cos(t) * 0.9;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawTorus(Canvas canvas, Offset center, double radius) {
    final outerRadius = radius;
    final innerRadius = radius * 0.4;

    // 토러스 외곽
    final torusPaint = Paint()
      ..color = Colors.purple.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // 외부 타원
    canvas.drawOval(
      Rect.fromCenter(center: center, width: outerRadius * 2, height: outerRadius * 1.2),
      torusPaint,
    );

    // 내부 구멍 (검은색으로 덮기)
    canvas.drawOval(
      Rect.fromCenter(center: center, width: innerRadius * 2, height: innerRadius * 0.6),
      Paint()..color = AppColors.simBg,
    );

    // 외곽선
    canvas.drawOval(
      Rect.fromCenter(center: center, width: outerRadius * 2, height: outerRadius * 1.2),
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawOval(
      Rect.fromCenter(center: center, width: innerRadius * 2, height: innerRadius * 0.6),
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 루프 - 구멍 주위
    if (showLoop) {
      final loopAngle = animation * 2 * math.pi;
      final loopCenter = Offset(
        center.dx + (innerRadius + (outerRadius - innerRadius) / 2) * 0.8 * math.cos(loopAngle),
        center.dy + (innerRadius * 0.3) * math.sin(loopAngle),
      );

      // 구멍을 감싸는 루프
      final loopPath = Path();
      for (int i = 0; i <= 40; i++) {
        final t = i / 40 * 2 * math.pi;
        final x = center.dx + innerRadius * 1.2 * math.cos(t);
        final y = center.dy + innerRadius * 0.4 * math.sin(t);
        if (i == 0) {
          loopPath.moveTo(x, y);
        } else {
          loopPath.lineTo(x, y);
        }
      }

      canvas.drawPath(
        loopPath,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      // 수축 불가 표시
      _drawText(canvas, '✗ 수축 불가!', Offset(center.dx + outerRadius + 10, center.dy - 10), Colors.red, fontSize: 11);
    }
  }

  void _drawDoubleTorus(Canvas canvas, Offset center, double radius) {
    final smallRadius = radius * 0.45;
    final holeRadius = smallRadius * 0.35;

    // 두 개의 연결된 토러스
    for (int t = 0; t < 2; t++) {
      final offset = t == 0 ? -smallRadius * 0.7 : smallRadius * 0.7;
      final torusCenter = Offset(center.dx + offset, center.dy);

      // 토러스 외곽
      canvas.drawOval(
        Rect.fromCenter(center: torusCenter, width: smallRadius * 1.8, height: smallRadius * 1.1),
        Paint()..color = Colors.orange.withValues(alpha: 0.3),
      );

      // 구멍
      canvas.drawOval(
        Rect.fromCenter(center: torusCenter, width: holeRadius * 2, height: holeRadius * 0.5),
        Paint()..color = AppColors.simBg,
      );

      // 외곽선
      canvas.drawOval(
        Rect.fromCenter(center: torusCenter, width: smallRadius * 1.8, height: smallRadius * 1.1),
        Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      canvas.drawOval(
        Rect.fromCenter(center: torusCenter, width: holeRadius * 2, height: holeRadius * 0.5),
        Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // 루프
    if (showLoop) {
      final firstHoleCenter = Offset(center.dx - smallRadius * 0.7, center.dy);
      final loopPath = Path();
      for (int i = 0; i <= 40; i++) {
        final t = i / 40 * 2 * math.pi;
        final x = firstHoleCenter.dx + holeRadius * 1.2 * math.cos(t);
        final y = firstHoleCenter.dy + holeRadius * 0.4 * math.sin(t);
        if (i == 0) {
          loopPath.moveTo(x, y);
        } else {
          loopPath.lineTo(x, y);
        }
      }

      canvas.drawPath(
        loopPath,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      _drawText(canvas, '✗ 수축 불가!', Offset(center.dx + radius + 10, center.dy - 10), Colors.red, fontSize: 11);
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _PoincarePainter oldDelegate) => true;
}
