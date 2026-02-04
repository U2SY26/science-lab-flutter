import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Euler's Formula Visualization - e^(iθ) = cos(θ) + i·sin(θ)
/// 오일러 공식 시각화
class EulerFormulaScreen extends StatefulWidget {
  const EulerFormulaScreen({super.key});

  @override
  State<EulerFormulaScreen> createState() => _EulerFormulaScreenState();
}

class _EulerFormulaScreenState extends State<EulerFormulaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double theta = math.pi;
  bool isAnimating = false;
  bool showComponents = true;
  bool showTrail = true;
  bool isKorean = true;

  final List<Offset> _trail = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..addListener(() {
        setState(() {
          theta = _controller.value * 2 * math.pi;
          _trail.add(Offset(math.cos(theta), math.sin(theta)));
          if (_trail.length > 200) _trail.removeAt(0);
        });
      });
  }

  void _animate() {
    HapticFeedback.mediumImpact();
    if (isAnimating) {
      _controller.stop();
    } else {
      _trail.clear();
      _controller.repeat();
    }
    setState(() => isAnimating = !isAnimating);
  }

  void _setSpecialValue(double value) {
    HapticFeedback.selectionClick();
    if (isAnimating) {
      _controller.stop();
      setState(() => isAnimating = false);
    }
    setState(() {
      theta = value;
      _trail.clear();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      theta = math.pi;
      isAnimating = false;
      _trail.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cosTheta = math.cos(theta);
    final sinTheta = math.sin(theta);

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
              isKorean ? '복소수' : 'COMPLEX NUMBERS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '오일러 공식' : "Euler's Formula",
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => isKorean = !isKorean),
            tooltip: isKorean ? 'English' : '한국어',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '복소수' : 'COMPLEX NUMBERS',
          title: isKorean ? '오일러 공식' : "Euler's Formula",
          formula: 'e^(iθ) = cos(θ) + i·sin(θ)',
          formulaDescription: isKorean
              ? '오일러 공식은 복소 지수함수와 삼각함수의 관계를 보여줍니다. θ=π일 때 e^(iπ) + 1 = 0 (수학에서 가장 아름다운 공식)'
              : "Euler's formula connects complex exponentials to trigonometry. At θ=π: e^(iπ) + 1 = 0 (the most beautiful equation)",
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: EulerFormulaPainter(
                theta: theta,
                showComponents: showComponents,
                showTrail: showTrail,
                trail: _trail,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current value display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      'e^(i·${(theta / math.pi).toStringAsFixed(2)}π)',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '= ${cosTheta.toStringAsFixed(3)} + ${sinTheta.toStringAsFixed(3)}i',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _InfoChip(
                          label: 'cos(θ)',
                          value: cosTheta.toStringAsFixed(3),
                          color: Colors.red,
                        ),
                        const SizedBox(width: 16),
                        _InfoChip(
                          label: 'sin(θ)',
                          value: sinTheta.toStringAsFixed(3),
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Special values
              PresetGroup(
                label: isKorean ? '특별한 값' : 'Special Values',
                presets: [
                  PresetButton(
                    label: '0',
                    isSelected: (theta - 0).abs() < 0.01,
                    onPressed: () => _setSpecialValue(0),
                  ),
                  PresetButton(
                    label: 'π/2',
                    isSelected: (theta - math.pi / 2).abs() < 0.01,
                    onPressed: () => _setSpecialValue(math.pi / 2),
                  ),
                  PresetButton(
                    label: 'π',
                    isSelected: (theta - math.pi).abs() < 0.01,
                    onPressed: () => _setSpecialValue(math.pi),
                  ),
                  PresetButton(
                    label: '3π/2',
                    isSelected: (theta - 3 * math.pi / 2).abs() < 0.01,
                    onPressed: () => _setSpecialValue(3 * math.pi / 2),
                  ),
                  PresetButton(
                    label: '2π',
                    isSelected: (theta - 2 * math.pi).abs() < 0.01,
                    onPressed: () => _setSpecialValue(2 * math.pi),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // θ slider
              SimSlider(
                label: 'θ (theta)',
                value: theta,
                min: 0,
                max: 2 * math.pi,
                defaultValue: math.pi,
                formatValue: (v) => '${(v / math.pi).toStringAsFixed(2)}π',
                onChanged: (v) {
                  if (isAnimating) {
                    _controller.stop();
                    setState(() => isAnimating = false);
                  }
                  setState(() => theta = v);
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '성분 표시' : 'Components',
                      value: showComponents,
                      onChanged: (v) => setState(() => showComponents = v),
                    ),
                  ),
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '궤적 표시' : 'Trail',
                      value: showTrail,
                      onChanged: (v) => setState(() => showTrail = v),
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
                label: isAnimating
                    ? (isKorean ? '정지' : 'Stop')
                    : (isKorean ? '회전' : 'Rotate'),
                icon: isAnimating ? Icons.stop : Icons.play_arrow,
                isPrimary: true,
                onPressed: _animate,
              ),
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label = $value',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class EulerFormulaPainter extends CustomPainter {
  final double theta;
  final bool showComponents;
  final bool showTrail;
  final List<Offset> trail;

  EulerFormulaPainter({
    required this.theta,
    required this.showComponents,
    required this.showTrail,
    required this.trail,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) / 2 - 40;

    Offset toScreen(double x, double y) {
      return Offset(centerX + x * radius, centerY - y * radius);
    }

    // Draw grid
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(
        toScreen(i / 2, -1.5),
        toScreen(i / 2, 1.5),
        gridPaint,
      );
      canvas.drawLine(
        toScreen(-1.5, i / 2),
        toScreen(1.5, i / 2),
        gridPaint,
      );
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;

    canvas.drawLine(toScreen(-1.3, 0), toScreen(1.3, 0), axisPaint);
    canvas.drawLine(toScreen(0, -1.3), toScreen(0, 1.3), axisPaint);

    // Axis labels
    _drawText(canvas, 'Re', toScreen(1.35, 0) + const Offset(5, -8), AppColors.muted);
    _drawText(canvas, 'Im', toScreen(0, 1.35) + const Offset(5, 0), AppColors.muted);

    // Draw unit circle
    canvas.drawCircle(
      toScreen(0, 0),
      radius,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw trail
    if (showTrail && trail.length > 1) {
      final trailPath = Path();
      trailPath.moveTo(toScreen(trail[0].dx, trail[0].dy).dx, toScreen(trail[0].dx, trail[0].dy).dy);
      for (int i = 1; i < trail.length; i++) {
        trailPath.lineTo(toScreen(trail[i].dx, trail[i].dy).dx, toScreen(trail[i].dx, trail[i].dy).dy);
      }
      canvas.drawPath(
        trailPath,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final cosTheta = math.cos(theta);
    final sinTheta = math.sin(theta);
    final point = toScreen(cosTheta, sinTheta);

    // Draw angle arc
    final arcPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(
      Rect.fromCircle(center: toScreen(0, 0), radius: radius * 0.3),
      0,
      -theta,
      false,
      arcPaint,
    );

    // Draw components
    if (showComponents) {
      // cos(θ) - horizontal component (red)
      canvas.drawLine(
        toScreen(0, 0),
        toScreen(cosTheta, 0),
        Paint()
          ..color = Colors.red
          ..strokeWidth = 3,
      );

      // sin(θ) - vertical component (green)
      canvas.drawLine(
        toScreen(cosTheta, 0),
        toScreen(cosTheta, sinTheta),
        Paint()
          ..color = Colors.green
          ..strokeWidth = 3,
      );

      // Dashed lines for projection
      final dashPaint = Paint()
        ..color = AppColors.muted.withValues(alpha: 0.4)
        ..strokeWidth = 1;

      canvas.drawLine(toScreen(0, sinTheta), toScreen(cosTheta, sinTheta), dashPaint);
    }

    // Draw radius vector
    canvas.drawLine(
      toScreen(0, 0),
      point,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 3,
    );

    // Draw point e^(iθ)
    canvas.drawCircle(
      point,
      10,
      Paint()..color = AppColors.accent.withValues(alpha: 0.3),
    );
    canvas.drawCircle(point, 6, Paint()..color = AppColors.accent);

    // Draw special points on circle
    final specialPoints = [
      (1.0, 0.0, '1'),
      (-1.0, 0.0, '-1'),
      (0.0, 1.0, 'i'),
      (0.0, -1.0, '-i'),
    ];

    for (final (x, y, label) in specialPoints) {
      canvas.drawCircle(
        toScreen(x, y),
        4,
        Paint()..color = AppColors.muted,
      );
      _drawText(
        canvas,
        label,
        toScreen(x, y) + Offset(x > 0 ? 10 : -20, y > 0 ? -15 : 5),
        AppColors.muted,
      );
    }

    // Label for current point
    _drawText(
      canvas,
      'e^(iθ)',
      point + const Offset(10, -10),
      AppColors.accent,
      fontSize: 14,
    );

    // θ label
    if (theta > 0.1) {
      _drawText(
        canvas,
        'θ',
        toScreen(0.2, 0) + const Offset(0, -15),
        AppColors.accent,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant EulerFormulaPainter oldDelegate) =>
      theta != oldDelegate.theta ||
      showComponents != oldDelegate.showComponents ||
      showTrail != oldDelegate.showTrail ||
      trail.length != oldDelegate.trail.length;
}
