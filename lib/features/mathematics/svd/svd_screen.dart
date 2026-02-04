import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Singular Value Decomposition Visualization
/// 특이값 분해 시각화
class SvdScreen extends StatefulWidget {
  const SvdScreen({super.key});

  @override
  State<SvdScreen> createState() => _SvdScreenState();
}

class _SvdScreenState extends State<SvdScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Matrix elements [a, b; c, d]
  double a = 2.0, b = 1.0, c = 0.0, d = 1.0;
  int step = 0; // 0: original, 1: V^T, 2: Σ, 3: U (full transform)
  bool showSteps = true;
  double animationProgress = 0.0;
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
        setState(() {
          animationProgress = _controller.value;
        });
      });
  }

  // Simple SVD for 2x2 matrix
  Map<String, dynamic> get _svd {
    // A = UΣV^T
    // For 2x2, we compute A^T A and A A^T eigenvalues
    // A^T A = [a c; b d] * [a b; c d] = [a²+c², ab+cd; ab+cd, b²+d²]

    final ata00 = a * a + c * c;
    final ata01 = a * b + c * d;
    final ata11 = b * b + d * d;

    // Eigenvalues of A^T A
    final trace = ata00 + ata11;
    final det = ata00 * ata11 - ata01 * ata01;
    final disc = math.sqrt(math.max(0, trace * trace / 4 - det));

    final sigma1 = math.sqrt(math.max(0, trace / 2 + disc));
    final sigma2 = math.sqrt(math.max(0, trace / 2 - disc));

    // V: eigenvectors of A^T A
    double v1x, v1y, v2x, v2y;
    if (ata01.abs() > 0.001) {
      final lambda1 = sigma1 * sigma1;
      v1x = ata01;
      v1y = lambda1 - ata00;
      final len1 = math.sqrt(v1x * v1x + v1y * v1y);
      v1x /= len1;
      v1y /= len1;

      v2x = -v1y;
      v2y = v1x;
    } else {
      v1x = 1;
      v1y = 0;
      v2x = 0;
      v2y = 1;
    }

    // U = AV / Σ
    double u1x = 0, u1y = 0, u2x = 0, u2y = 0;
    if (sigma1 > 0.001) {
      u1x = (a * v1x + b * v1y) / sigma1;
      u1y = (c * v1x + d * v1y) / sigma1;
    }
    if (sigma2 > 0.001) {
      u2x = (a * v2x + b * v2y) / sigma2;
      u2y = (c * v2x + d * v2y) / sigma2;
    } else {
      u2x = -u1y;
      u2y = u1x;
    }

    return {
      'sigma1': sigma1,
      'sigma2': sigma2,
      'v1': Offset(v1x, v1y),
      'v2': Offset(v2x, v2y),
      'u1': Offset(u1x, u1y),
      'u2': Offset(u2x, u2y),
    };
  }

  void _nextStep() {
    HapticFeedback.selectionClick();
    setState(() {
      step = (step + 1) % 4;
      _controller.reset();
      _controller.forward();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      a = 2;
      b = 1;
      c = 0;
      d = 1;
      step = 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svd = _svd;
    final stepNames = isKorean
        ? ['원본', 'V^T (회전)', 'Σ (스케일)', 'U (회전)']
        : ['Original', 'V^T (Rotate)', 'Σ (Scale)', 'U (Rotate)'];

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
              isKorean ? '특이값 분해' : 'Singular Value Decomposition',
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
          title: isKorean ? '특이값 분해 (SVD)' : 'Singular Value Decomposition',
          formula: 'A = UΣV^T',
          formulaDescription: isKorean
              ? 'SVD는 모든 행렬을 회전(V^T) → 스케일(Σ) → 회전(U)의 조합으로 분해합니다.'
              : 'SVD decomposes any matrix into rotation (V^T) → scale (Σ) → rotation (U).',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: SvdPainter(
                a: a,
                b: b,
                c: c,
                d: d,
                svd: svd,
                step: step,
                animationProgress: animationProgress,
                showSteps: showSteps,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SVD values display
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
                          label: 'σ₁',
                          value: (svd['sigma1'] as double).toStringAsFixed(3),
                          color: Colors.red,
                        ),
                        _InfoItem(
                          label: 'σ₂',
                          value: (svd['sigma2'] as double).toStringAsFixed(3),
                          color: Colors.green,
                        ),
                        _InfoItem(
                          label: isKorean ? '단계' : 'Step',
                          value: stepNames[step],
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Step selection
              PresetGroup(
                label: isKorean ? '변환 단계' : 'Transformation Step',
                presets: List.generate(4, (i) {
                  return PresetButton(
                    label: stepNames[i],
                    isSelected: step == i,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        step = i;
                        _controller.reset();
                        _controller.forward();
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Matrix input
              ControlGroup(
                primaryControl: SimSlider(
                  label: 'a',
                  value: a,
                  min: -3,
                  max: 3,
                  defaultValue: 2,
                  formatValue: (v) => v.toStringAsFixed(1),
                  onChanged: (v) => setState(() => a = v),
                ),
                advancedControls: [
                  Row(
                    children: [
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: SimSlider(
                          label: 'c',
                          value: c,
                          min: -3,
                          max: 3,
                          defaultValue: 0,
                          formatValue: (v) => v.toStringAsFixed(1),
                          onChanged: (v) => setState(() => c = v),
                        ),
                      ),
                    ],
                  ),
                  SimSlider(
                    label: 'd',
                    value: d,
                    min: -3,
                    max: 3,
                    defaultValue: 1,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => d = v),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '다음 단계' : 'Next Step',
                icon: Icons.arrow_forward,
                isPrimary: true,
                onPressed: _nextStep,
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
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.accent,
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

class SvdPainter extends CustomPainter {
  final double a, b, c, d;
  final Map<String, dynamic> svd;
  final int step;
  final double animationProgress;
  final bool showSteps;

  SvdPainter({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.svd,
    required this.step,
    required this.animationProgress,
    required this.showSteps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 10;

    final sigma1 = svd['sigma1'] as double;
    final sigma2 = svd['sigma2'] as double;
    final v1 = svd['v1'] as Offset;
    final v2 = svd['v2'] as Offset;
    final u1 = svd['u1'] as Offset;
    final u2 = svd['u2'] as Offset;

    Offset toScreen(double x, double y) {
      return Offset(centerX + x * scale, centerY - y * scale);
    }

    // Apply transformation based on step
    Offset transformPoint(double x, double y) {
      double tx = x, ty = y;

      if (step >= 1) {
        // Apply V^T (rotate to align with V basis)
        final newX = v1.dx * x + v1.dy * y;
        final newY = v2.dx * x + v2.dy * y;
        tx = newX;
        ty = newY;
      }

      if (step >= 2) {
        // Apply Σ (scale)
        tx *= sigma1;
        ty *= sigma2;
      }

      if (step >= 3) {
        // Apply U (rotate from U basis)
        final newX = u1.dx * tx + u2.dx * ty;
        final newY = u1.dy * tx + u2.dy * ty;
        tx = newX;
        ty = newY;
      }

      return toScreen(tx, ty);
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

    for (int i = -4; i <= 4; i++) {
      canvas.drawLine(toScreen(i.toDouble(), -4), toScreen(i.toDouble(), 4), gridPaint);
      canvas.drawLine(toScreen(-4, i.toDouble()), toScreen(4, i.toDouble()), gridPaint);
    }

    // Draw unit circle transformation
    final circlePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    for (int i = 0; i <= 100; i++) {
      final angle = 2 * math.pi * i / 100;
      final x = math.cos(angle);
      final y = math.sin(angle);
      final pt = transformPoint(x, y);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, circlePaint);

    // Fill
    canvas.drawPath(
      path,
      Paint()..color = AppColors.accent.withValues(alpha: 0.2),
    );

    // Draw basis vectors
    final origin = transformPoint(0, 0);

    // e1 transformed
    final e1 = transformPoint(1, 0);
    canvas.drawLine(
      origin,
      e1,
      Paint()
        ..color = Colors.red
        ..strokeWidth = 3,
    );
    _drawArrow(canvas, origin, e1, Colors.red);

    // e2 transformed
    final e2 = transformPoint(0, 1);
    canvas.drawLine(
      origin,
      e2,
      Paint()
        ..color = Colors.green
        ..strokeWidth = 3,
    );
    _drawArrow(canvas, origin, e2, Colors.green);

    // Draw labels
    _drawText(canvas, 'e₁\'', e1 + const Offset(10, -10), Colors.red);
    _drawText(canvas, 'e₂\'', e2 + const Offset(10, -10), Colors.green);

    // Step indicator
    final stepLabels = ['I', 'V^T', 'ΣV^T', 'UΣV^T'];
    _drawText(
      canvas,
      stepLabels[step],
      Offset(size.width - 40, 20),
      AppColors.accent,
      fontSize: 16,
    );
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final direction = (to - from);
    final length = direction.distance;
    if (length < 10) return;

    final unit = direction / length;
    final normal = Offset(-unit.dy, unit.dx);
    final arrowSize = 10.0;

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
  bool shouldRepaint(covariant SvdPainter oldDelegate) => true;
}
