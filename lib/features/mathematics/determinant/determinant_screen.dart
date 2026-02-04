import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Determinant Visualization - Area/Volume Scaling
/// 행렬식 시각화 - 면적/부피 스케일링
class DeterminantScreen extends StatefulWidget {
  const DeterminantScreen({super.key});

  @override
  State<DeterminantScreen> createState() => _DeterminantScreenState();
}

class _DeterminantScreenState extends State<DeterminantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Matrix elements [a, b; c, d]
  double a = 2.0, b = 0.5, c = 0.0, d = 1.5;
  bool showOriginal = true;
  bool showArea = true;
  double animationProgress = 1.0;
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
        setState(() {
          animationProgress = Curves.easeInOut.transform(_controller.value);
        });
      });
  }

  double get _determinant => a * d - b * c;

  void _animate() {
    HapticFeedback.mediumImpact();
    _controller.reset();
    _controller.forward();
  }

  void _setPreset(int preset) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (preset) {
        case 0: // Unit (det = 1)
          a = 1;
          b = 0;
          c = 0;
          d = 1;
          break;
        case 1: // Double area (det = 2)
          a = 2;
          b = 0;
          c = 0;
          d = 1;
          break;
        case 2: // Shear (det = 1)
          a = 1;
          b = 1;
          c = 0;
          d = 1;
          break;
        case 3: // Flip (det = -1)
          a = 1;
          b = 0;
          c = 0;
          d = -1;
          break;
        case 4: // Singular (det = 0)
          a = 1;
          b = 2;
          c = 0.5;
          d = 1;
          break;
      }
    });
    _animate();
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      a = 2;
      b = 0.5;
      c = 0;
      d = 1.5;
      animationProgress = 1;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final det = _determinant;

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
              isKorean ? '행렬식' : 'Determinant',
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
          title: isKorean ? '행렬식 (면적 스케일링)' : 'Determinant (Area Scaling)',
          formula: 'det(A) = ad - bc',
          formulaDescription: isKorean
              ? '행렬식은 변환 후 면적이 얼마나 변하는지를 나타냅니다. 음수면 방향이 뒤집힙니다.'
              : 'The determinant indicates how area changes after transformation. Negative means orientation is flipped.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: DeterminantPainter(
                a: a,
                b: b,
                c: c,
                d: d,
                showOriginal: showOriginal,
                showArea: showArea,
                animationProgress: animationProgress,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Determinant display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: det.abs() < 0.01
                      ? Colors.red.withValues(alpha: 0.1)
                      : det < 0
                          ? Colors.orange.withValues(alpha: 0.1)
                          : AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: det.abs() < 0.01
                        ? Colors.red
                        : det < 0
                            ? Colors.orange
                            : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          isKorean ? '행렬식' : 'Determinant',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'det(A) = ${det.toStringAsFixed(3)}',
                          style: TextStyle(
                            color: det.abs() < 0.01
                                ? Colors.red
                                : det < 0
                                    ? Colors.orange
                                    : AppColors.accent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          det.abs() < 0.01
                              ? (isKorean ? '특이 행렬 (면적 = 0)' : 'Singular (Area = 0)')
                              : det < 0
                                  ? (isKorean ? '방향 뒤집힘' : 'Orientation Flipped')
                                  : (isKorean ? '면적 ${det.toStringAsFixed(2)}배' : 'Area × ${det.toStringAsFixed(2)}'),
                          style: TextStyle(
                            color: det.abs() < 0.01
                                ? Colors.red
                                : det < 0
                                    ? Colors.orange
                                    : Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Presets
              PresetGroup(
                label: isKorean ? '프리셋' : 'Presets',
                presets: [
                  PresetButton(
                    label: isKorean ? '항등' : 'Identity',
                    isSelected: false,
                    onPressed: () => _setPreset(0),
                  ),
                  PresetButton(
                    label: isKorean ? '2배 확대' : '2× Scale',
                    isSelected: false,
                    onPressed: () => _setPreset(1),
                  ),
                  PresetButton(
                    label: isKorean ? '밀림' : 'Shear',
                    isSelected: false,
                    onPressed: () => _setPreset(2),
                  ),
                  PresetButton(
                    label: isKorean ? '반사' : 'Flip',
                    isSelected: false,
                    onPressed: () => _setPreset(3),
                  ),
                  PresetButton(
                    label: isKorean ? '특이' : 'Singular',
                    isSelected: false,
                    onPressed: () => _setPreset(4),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Matrix sliders
              ControlGroup(
                primaryControl: Row(
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
                        defaultValue: 0.5,
                        formatValue: (v) => v.toStringAsFixed(1),
                        onChanged: (v) => setState(() => b = v),
                      ),
                    ),
                  ],
                ),
                advancedControls: [
                  Row(
                    children: [
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: SimSlider(
                          label: 'd',
                          value: d,
                          min: -3,
                          max: 3,
                          defaultValue: 1.5,
                          formatValue: (v) => v.toStringAsFixed(1),
                          onChanged: (v) => setState(() => d = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '원본 표시' : 'Show Original',
                      value: showOriginal,
                      onChanged: (v) => setState(() => showOriginal = v),
                    ),
                  ),
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '면적 표시' : 'Show Area',
                      value: showArea,
                      onChanged: (v) => setState(() => showArea = v),
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
                label: isKorean ? '애니메이션' : 'Animate',
                icon: Icons.play_arrow,
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

class DeterminantPainter extends CustomPainter {
  final double a, b, c, d;
  final bool showOriginal;
  final bool showArea;
  final double animationProgress;

  DeterminantPainter({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.showOriginal,
    required this.showArea,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 8;

    Offset toScreen(double x, double y) {
      return Offset(centerX + x * scale, centerY - y * scale);
    }

    Offset transform(double x, double y, double t) {
      final newX = (1 - t) * x + t * (a * x + b * y);
      final newY = (1 - t) * y + t * (c * x + d * y);
      return toScreen(newX, newY);
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
      canvas.drawLine(toScreen(i.toDouble(), -3), toScreen(i.toDouble(), 3), gridPaint);
      canvas.drawLine(toScreen(-3, i.toDouble()), toScreen(3, i.toDouble()), gridPaint);
    }

    // Draw original unit square
    if (showOriginal) {
      final origPath = Path();
      origPath.moveTo(toScreen(0, 0).dx, toScreen(0, 0).dy);
      origPath.lineTo(toScreen(1, 0).dx, toScreen(1, 0).dy);
      origPath.lineTo(toScreen(1, 1).dx, toScreen(1, 1).dy);
      origPath.lineTo(toScreen(0, 1).dx, toScreen(0, 1).dy);
      origPath.close();

      canvas.drawPath(
        origPath,
        Paint()..color = Colors.grey.withValues(alpha: 0.2),
      );
      canvas.drawPath(
        origPath,
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Draw transformed parallelogram
    final t = animationProgress;
    final det = a * d - b * c;

    final transPath = Path();
    transPath.moveTo(transform(0, 0, t).dx, transform(0, 0, t).dy);
    transPath.lineTo(transform(1, 0, t).dx, transform(1, 0, t).dy);
    transPath.lineTo(transform(1, 1, t).dx, transform(1, 1, t).dy);
    transPath.lineTo(transform(0, 1, t).dx, transform(0, 1, t).dy);
    transPath.close();

    // Fill color based on determinant
    final fillColor = det.abs() < 0.01
        ? Colors.red.withValues(alpha: 0.3)
        : det < 0
            ? Colors.orange.withValues(alpha: 0.3)
            : AppColors.accent.withValues(alpha: 0.3);

    canvas.drawPath(transPath, Paint()..color = fillColor);
    canvas.drawPath(
      transPath,
      Paint()
        ..color = det.abs() < 0.01
            ? Colors.red
            : det < 0
                ? Colors.orange
                : AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw basis vectors
    final origin = transform(0, 0, t);

    // e1
    final e1 = transform(1, 0, t);
    canvas.drawLine(
      origin,
      e1,
      Paint()
        ..color = Colors.red
        ..strokeWidth = 3,
    );
    _drawArrow(canvas, origin, e1, Colors.red);

    // e2
    final e2 = transform(0, 1, t);
    canvas.drawLine(
      origin,
      e2,
      Paint()
        ..color = Colors.green
        ..strokeWidth = 3,
    );
    _drawArrow(canvas, origin, e2, Colors.green);

    // Show area label
    if (showArea) {
      final centroid = Offset(
        (transform(0, 0, t).dx + transform(1, 0, t).dx + transform(1, 1, t).dx + transform(0, 1, t).dx) / 4,
        (transform(0, 0, t).dy + transform(1, 0, t).dy + transform(1, 1, t).dy + transform(0, 1, t).dy) / 4,
      );

      final currentDet = (1 - t) * 1 + t * det;
      _drawText(
        canvas,
        'Area = ${currentDet.abs().toStringAsFixed(2)}',
        centroid,
        Colors.white,
        background: Colors.black54,
      );
    }

    // Draw labels
    _drawText(canvas, 'e₁', e1 + const Offset(5, -15), Colors.red);
    _drawText(canvas, 'e₂', e2 + const Offset(-15, -5), Colors.green);
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

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {Color? background}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    if (background != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: pos,
            width: textPainter.width + 12,
            height: textPainter.height + 8,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = background,
      );
    }

    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant DeterminantPainter oldDelegate) => true;
}
