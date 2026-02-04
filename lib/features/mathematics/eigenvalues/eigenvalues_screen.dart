import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Eigenvalues & Eigenvectors Visualization
/// 고유값과 고유벡터 시각화
class EigenvaluesScreen extends StatefulWidget {
  const EigenvaluesScreen({super.key});

  @override
  State<EigenvaluesScreen> createState() => _EigenvaluesScreenState();
}

class _EigenvaluesScreenState extends State<EigenvaluesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Matrix elements [a, b; c, d]
  double a = 2.0, b = 1.0, c = 1.0, d = 2.0;
  bool showEigenvectors = true;
  bool showTransform = true;
  bool isAnimating = false;
  double animationProgress = 0.0;
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() {
        setState(() {
          animationProgress = _controller.value;
        });
      });
    _controller.repeat();
  }

  // Calculate eigenvalues for 2x2 matrix
  List<double> get _eigenvalues {
    // For [a, b; c, d]: λ² - (a+d)λ + (ad-bc) = 0
    final trace = a + d;
    final det = a * d - b * c;
    final discriminant = trace * trace - 4 * det;

    if (discriminant >= 0) {
      final sqrt = math.sqrt(discriminant);
      return [(trace + sqrt) / 2, (trace - sqrt) / 2];
    } else {
      // Complex eigenvalues - return real part
      return [trace / 2, trace / 2];
    }
  }

  bool get _hasComplexEigenvalues {
    final trace = a + d;
    final det = a * d - b * c;
    return trace * trace - 4 * det < 0;
  }

  // Calculate eigenvectors for 2x2 matrix
  List<Offset> get _eigenvectors {
    final eigenvals = _eigenvalues;
    final vectors = <Offset>[];

    for (final lambda in eigenvals) {
      // (A - λI)v = 0
      // [a-λ, b; c, d-λ] * [x, y] = 0
      // Use first row: (a-λ)x + by = 0 → y = -(a-λ)x/b
      if (b.abs() > 0.001) {
        final x = 1.0;
        final y = -(a - lambda) / b;
        final len = math.sqrt(x * x + y * y);
        vectors.add(Offset(x / len, y / len));
      } else if (c.abs() > 0.001) {
        final y = 1.0;
        final x = -(d - lambda) / c;
        final len = math.sqrt(x * x + y * y);
        vectors.add(Offset(x / len, y / len));
      } else {
        // Diagonal matrix
        if ((a - lambda).abs() < 0.001) {
          vectors.add(const Offset(1, 0));
        } else {
          vectors.add(const Offset(0, 1));
        }
      }
    }
    return vectors;
  }

  void _setPreset(int preset) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (preset) {
        case 0: // Symmetric
          a = 2;
          b = 1;
          c = 1;
          d = 2;
          break;
        case 1: // Rotation
          a = 0;
          b = -1;
          c = 1;
          d = 0;
          break;
        case 2: // Shear
          a = 1;
          b = 1;
          c = 0;
          d = 1;
          break;
        case 3: // Scale
          a = 2;
          b = 0;
          c = 0;
          d = 0.5;
          break;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      a = 2;
      b = 1;
      c = 1;
      d = 2;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eigenvals = _eigenvalues;
    final eigenvecs = _eigenvectors;
    final hasComplex = _hasComplexEigenvalues;

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
              isKorean ? '선형대수학' : 'LINEAR ALGEBRA',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '고유값과 고유벡터' : 'Eigenvalues & Eigenvectors',
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
          category: isKorean ? '선형대수학' : 'LINEAR ALGEBRA',
          title: isKorean ? '고유값과 고유벡터' : 'Eigenvalues & Eigenvectors',
          formula: 'Av = λv',
          formulaDescription: isKorean
              ? '고유벡터는 행렬 변환 후에도 방향이 변하지 않는 벡터입니다. 고유값은 그 벡터가 얼마나 늘어나거나 줄어드는지를 나타냅니다.'
              : 'Eigenvectors are vectors that maintain their direction after transformation. Eigenvalues indicate how much they are scaled.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: EigenvaluesPainter(
                a: a,
                b: b,
                c: c,
                d: d,
                eigenvalues: eigenvals,
                eigenvectors: eigenvecs,
                showEigenvectors: showEigenvectors,
                showTransform: showTransform,
                animationProgress: animationProgress,
                hasComplex: hasComplex,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eigenvalue display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _InfoItem(
                          label: 'λ₁',
                          value: hasComplex
                              ? '${eigenvals[0].toStringAsFixed(2)} + ${math.sqrt(-(a + d) * (a + d) / 4 + a * d - b * c).toStringAsFixed(2)}i'
                              : eigenvals[0].toStringAsFixed(3),
                          color: Colors.red,
                        ),
                        _InfoItem(
                          label: 'λ₂',
                          value: hasComplex
                              ? '${eigenvals[1].toStringAsFixed(2)} - ${math.sqrt(-(a + d) * (a + d) / 4 + a * d - b * c).toStringAsFixed(2)}i'
                              : eigenvals[1].toStringAsFixed(3),
                          color: Colors.green,
                        ),
                      ],
                    ),
                    if (hasComplex)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          isKorean ? '복소 고유값 (회전 변환)' : 'Complex eigenvalues (rotation)',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Matrix input
              Row(
                children: [
                  Expanded(
                    child: SimSlider(
                      label: 'a',
                      value: a,
                      min: -3,
                      max: 3,
                      defaultValue: 2,
                      formatValue: (v) => v.toStringAsFixed(1),
                      onChanged: (v) => setState(() => a = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SimSlider(
                      label: 'b',
                      value: b,
                      min: -3,
                      max: 3,
                      defaultValue: 1,
                      formatValue: (v) => v.toStringAsFixed(1),
                      onChanged: (v) => setState(() => b = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SimSlider(
                      label: 'c',
                      value: c,
                      min: -3,
                      max: 3,
                      defaultValue: 1,
                      formatValue: (v) => v.toStringAsFixed(1),
                      onChanged: (v) => setState(() => c = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SimSlider(
                      label: 'd',
                      value: d,
                      min: -3,
                      max: 3,
                      defaultValue: 2,
                      formatValue: (v) => v.toStringAsFixed(1),
                      onChanged: (v) => setState(() => d = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              PresetGroup(
                label: isKorean ? '프리셋' : 'Presets',
                presets: [
                  PresetButton(
                    label: isKorean ? '대칭' : 'Symmetric',
                    isSelected: false,
                    onPressed: () => _setPreset(0),
                  ),
                  PresetButton(
                    label: isKorean ? '회전' : 'Rotation',
                    isSelected: false,
                    onPressed: () => _setPreset(1),
                  ),
                  PresetButton(
                    label: isKorean ? '밀림' : 'Shear',
                    isSelected: false,
                    onPressed: () => _setPreset(2),
                  ),
                  PresetButton(
                    label: isKorean ? '스케일' : 'Scale',
                    isSelected: false,
                    onPressed: () => _setPreset(3),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '고유벡터' : 'Eigenvectors',
                      value: showEigenvectors,
                      onChanged: (v) => setState(() => showEigenvectors = v),
                    ),
                  ),
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '변환 표시' : 'Transform',
                      value: showTransform,
                      onChanged: (v) => setState(() => showTransform = v),
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
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                isPrimary: true,
                onPressed: _reset,
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
  final Color? color;

  const _InfoItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color ?? AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.accent,
              fontSize: 14,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class EigenvaluesPainter extends CustomPainter {
  final double a, b, c, d;
  final List<double> eigenvalues;
  final List<Offset> eigenvectors;
  final bool showEigenvectors;
  final bool showTransform;
  final double animationProgress;
  final bool hasComplex;

  EigenvaluesPainter({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.eigenvalues,
    required this.eigenvectors,
    required this.showEigenvectors,
    required this.showTransform,
    required this.animationProgress,
    required this.hasComplex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 8;

    // Transform point with animation
    Offset transform(double x, double y, double t) {
      final newX = (1 - t) * x + t * (a * x + b * y);
      final newY = (1 - t) * y + t * (c * x + d * y);
      return Offset(centerX + newX * scale, centerY - newY * scale);
    }

    Offset original(double x, double y) {
      return Offset(centerX + x * scale, centerY - y * scale);
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), axisPaint);

    // Draw grid
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    for (int i = -3; i <= 3; i++) {
      canvas.drawLine(original(i.toDouble(), -3), original(i.toDouble(), 3), gridPaint);
      canvas.drawLine(original(-3, i.toDouble()), original(3, i.toDouble()), gridPaint);
    }

    // Draw unit circle and its transformation
    if (showTransform) {
      final t = animationProgress;
      final circlePaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final path = Path();
      for (int i = 0; i <= 100; i++) {
        final angle = 2 * math.pi * i / 100;
        final x = math.cos(angle);
        final y = math.sin(angle);
        final pt = transform(x, y, t);
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(path, circlePaint);
    }

    // Draw eigenvectors
    if (showEigenvectors && !hasComplex) {
      final colors = [Colors.red, Colors.green];

      for (int i = 0; i < eigenvectors.length && i < 2; i++) {
        final vec = eigenvectors[i];
        final lambda = eigenvalues[i];
        final t = animationProgress;

        // Original eigenvector
        final start = original(0, 0);
        final end = original(vec.dx * 2, vec.dy * 2);

        canvas.drawLine(
          start,
          end,
          Paint()
            ..color = colors[i].withValues(alpha: 0.4)
            ..strokeWidth = 2,
        );

        // Transformed eigenvector (should be same direction, scaled by lambda)
        final transformedEnd = transform(vec.dx * 2, vec.dy * 2, t);

        canvas.drawLine(
          start,
          transformedEnd,
          Paint()
            ..color = colors[i]
            ..strokeWidth = 3,
        );

        _drawArrow(canvas, start, transformedEnd, colors[i]);

        // Label
        final labelPos = original(vec.dx * 2.3, vec.dy * 2.3);
        _drawText(canvas, 'v${i + 1} (λ=${lambda.toStringAsFixed(2)})', labelPos, colors[i]);
      }
    }

    // For complex eigenvalues, show rotation
    if (hasComplex) {
      final rotPaint = Paint()
        ..color = Colors.orange.withValues(alpha: 0.7)
        ..strokeWidth = 2;

      // Show rotating vector
      final angle = animationProgress * 2 * math.pi;
      final x = math.cos(angle);
      final y = math.sin(angle);
      final pt = original(x * 1.5, y * 1.5);

      canvas.drawLine(original(0, 0), pt, rotPaint);
      canvas.drawCircle(pt, 5, Paint()..color = Colors.orange);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final direction = (to - from);
    final length = direction.distance;
    if (length < 10) return;

    final unit = direction / length;
    final normal = Offset(-unit.dy, unit.dx);
    final arrowSize = 12.0;

    final tip = to;
    final left = to - unit * arrowSize + normal * arrowSize / 2;
    final right = to - unit * arrowSize - normal * arrowSize / 2;

    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(left.dx, left.dy);
    path.lineTo(right.dx, right.dy);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant EigenvaluesPainter oldDelegate) => true;
}
