import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Complex Plane Visualization
/// 복소 평면 시각화
class ComplexPlaneScreen extends StatefulWidget {
  const ComplexPlaneScreen({super.key});

  @override
  State<ComplexPlaneScreen> createState() => _ComplexPlaneScreenState();
}

class _ComplexPlaneScreenState extends State<ComplexPlaneScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Complex number z = a + bi
  double realPart = 2.0;
  double imagPart = 1.5;
  int operationIndex = 0; // 0: none, 1: conjugate, 2: square, 3: inverse, 4: multiply by i
  bool showPolar = true;
  bool showConjugate = false;
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  double get _magnitude => math.sqrt(realPart * realPart + imagPart * imagPart);
  double get _argument => math.atan2(imagPart, realPart);

  // Get result of operation
  (double, double) get _operationResult {
    switch (operationIndex) {
      case 1: // Conjugate: a - bi
        return (realPart, -imagPart);
      case 2: // Square: (a+bi)² = a²-b² + 2abi
        return (realPart * realPart - imagPart * imagPart, 2 * realPart * imagPart);
      case 3: // Inverse: 1/(a+bi) = (a-bi)/(a²+b²)
        final denom = realPart * realPart + imagPart * imagPart;
        if (denom < 0.001) return (0, 0);
        return (realPart / denom, -imagPart / denom);
      case 4: // Multiply by i: i(a+bi) = -b + ai
        return (-imagPart, realPart);
      default:
        return (realPart, imagPart);
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      realPart = 2.0;
      imagPart = 1.5;
      operationIndex = 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _operationResult;
    final resultMag = math.sqrt(result.$1 * result.$1 + result.$2 * result.$2);
    final resultArg = math.atan2(result.$2, result.$1);

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
              isKorean ? '복소 평면' : 'Complex Plane',
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
          title: isKorean ? '복소 평면' : 'Complex Plane',
          formula: 'z = a + bi = r·e^(iθ)',
          formulaDescription: isKorean
              ? '복소수는 실수부와 허수부로 구성됩니다. 극좌표로도 표현 가능합니다.'
              : 'Complex numbers have real and imaginary parts. Can also be expressed in polar form.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: ComplexPlanePainter(
                realPart: realPart,
                imagPart: imagPart,
                showPolar: showPolar,
                showConjugate: showConjugate,
                operationResult: result,
                operationIndex: operationIndex,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Complex number display
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
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'z',
                              style: TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${realPart.toStringAsFixed(2)} ${imagPart >= 0 ? '+' : '-'} ${imagPart.abs().toStringAsFixed(2)}i',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 16,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        if (operationIndex > 0)
                          Column(
                            children: [
                              Text(
                                _getOperationLabel(),
                                style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${result.$1.toStringAsFixed(2)} ${result.$2 >= 0 ? '+' : '-'} ${result.$2.abs().toStringAsFixed(2)}i',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 16,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (showPolar)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _InfoChip(label: '|z|', value: _magnitude.toStringAsFixed(2), color: AppColors.accent),
                          _InfoChip(label: 'arg(z)', value: '${(_argument * 180 / math.pi).toStringAsFixed(1)}°', color: AppColors.accent),
                          if (operationIndex > 0) ...[
                            _InfoChip(label: '|w|', value: resultMag.toStringAsFixed(2), color: Colors.orange),
                            _InfoChip(label: 'arg(w)', value: '${(resultArg * 180 / math.pi).toStringAsFixed(1)}°', color: Colors.orange),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Operations
              PresetGroup(
                label: isKorean ? '연산' : 'Operations',
                presets: [
                  PresetButton(
                    label: isKorean ? '없음' : 'None',
                    isSelected: operationIndex == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => operationIndex = 0);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '켤레 z*' : 'Conj z*',
                    isSelected: operationIndex == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => operationIndex = 1);
                    },
                  ),
                  PresetButton(
                    label: 'z²',
                    isSelected: operationIndex == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => operationIndex = 2);
                    },
                  ),
                  PresetButton(
                    label: '1/z',
                    isSelected: operationIndex == 3,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => operationIndex = 3);
                    },
                  ),
                  PresetButton(
                    label: 'i·z',
                    isSelected: operationIndex == 4,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => operationIndex = 4);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Input sliders
              SimSlider(
                label: isKorean ? '실수부 (a)' : 'Real Part (a)',
                value: realPart,
                min: -3,
                max: 3,
                defaultValue: 2,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => realPart = v),
              ),
              const SizedBox(height: 8),
              SimSlider(
                label: isKorean ? '허수부 (b)' : 'Imaginary Part (b)',
                value: imagPart,
                min: -3,
                max: 3,
                defaultValue: 1.5,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => imagPart = v),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '극좌표 표시' : 'Polar Form',
                      value: showPolar,
                      onChanged: (v) => setState(() => showPolar = v),
                    ),
                  ),
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '켤레 표시' : 'Show Conjugate',
                      value: showConjugate,
                      onChanged: (v) => setState(() => showConjugate = v),
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

  String _getOperationLabel() {
    switch (operationIndex) {
      case 1:
        return 'z*';
      case 2:
        return 'z²';
      case 3:
        return '1/z';
      case 4:
        return 'i·z';
      default:
        return '';
    }
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
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 10)),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class ComplexPlanePainter extends CustomPainter {
  final double realPart;
  final double imagPart;
  final bool showPolar;
  final bool showConjugate;
  final (double, double) operationResult;
  final int operationIndex;

  ComplexPlanePainter({
    required this.realPart,
    required this.imagPart,
    required this.showPolar,
    required this.showConjugate,
    required this.operationResult,
    required this.operationIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = math.min(size.width, size.height) / 8;

    Offset toScreen(double x, double y) {
      return Offset(centerX + x * scale, centerY - y * scale);
    }

    // Draw grid
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int i = -3; i <= 3; i++) {
      canvas.drawLine(toScreen(i.toDouble(), -3), toScreen(i.toDouble(), 3), gridPaint);
      canvas.drawLine(toScreen(-3, i.toDouble()), toScreen(3, i.toDouble()), gridPaint);
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;

    canvas.drawLine(toScreen(-3.5, 0), toScreen(3.5, 0), axisPaint);
    canvas.drawLine(toScreen(0, -3.5), toScreen(0, 3.5), axisPaint);

    // Axis labels
    _drawText(canvas, 'Re', toScreen(3.5, 0) + const Offset(5, -8), AppColors.muted);
    _drawText(canvas, 'Im', toScreen(0, 3.5) + const Offset(5, 0), AppColors.muted);

    // Unit circle
    canvas.drawCircle(
      toScreen(0, 0),
      scale,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final origin = toScreen(0, 0);
    final zPoint = toScreen(realPart, imagPart);

    // Draw polar representation
    if (showPolar) {
      // Angle arc
      final magnitude = math.sqrt(realPart * realPart + imagPart * imagPart);
      final argument = math.atan2(imagPart, realPart);

      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: scale * magnitude * 0.3),
        0,
        -argument,
        false,
        Paint()
          ..color = Colors.purple.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      _drawText(canvas, 'θ', origin + Offset(30 * math.cos(-argument / 2), 30 * math.sin(-argument / 2)), Colors.purple);
    }

    // Draw conjugate
    if (showConjugate) {
      final conjPoint = toScreen(realPart, -imagPart);
      canvas.drawLine(
        origin,
        conjPoint,
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.5)
          ..strokeWidth = 2,
      );
      canvas.drawCircle(conjPoint, 6, Paint()..color = Colors.grey);
      _drawText(canvas, 'z*', conjPoint + const Offset(10, 5), Colors.grey);
    }

    // Draw operation result
    if (operationIndex > 0) {
      final resultPoint = toScreen(operationResult.$1, operationResult.$2);
      canvas.drawLine(
        origin,
        resultPoint,
        Paint()
          ..color = Colors.orange
          ..strokeWidth = 2,
      );
      canvas.drawCircle(resultPoint, 8, Paint()..color = Colors.orange.withValues(alpha: 0.3));
      canvas.drawCircle(resultPoint, 5, Paint()..color = Colors.orange);

      // Arrow for transformation
      _drawArrow(canvas, zPoint, resultPoint, Colors.orange.withValues(alpha: 0.5));
    }

    // Draw z vector
    canvas.drawLine(
      origin,
      zPoint,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 3,
    );

    // Draw components
    canvas.drawLine(
      origin,
      toScreen(realPart, 0),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      toScreen(realPart, 0),
      zPoint,
      Paint()
        ..color = Colors.green.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );

    // Draw z point
    canvas.drawCircle(zPoint, 8, Paint()..color = AppColors.accent.withValues(alpha: 0.3));
    canvas.drawCircle(zPoint, 5, Paint()..color = AppColors.accent);
    _drawText(canvas, 'z', zPoint + const Offset(10, -10), AppColors.accent, fontSize: 14);

    // Component labels
    _drawText(canvas, 'a', toScreen(realPart / 2, 0) + const Offset(0, 12), Colors.red, fontSize: 11);
    _drawText(canvas, 'b', toScreen(realPart, imagPart / 2) + const Offset(8, 0), Colors.green, fontSize: 11);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final midX = (from.dx + to.dx) / 2;
    final midY = (from.dy + to.dy) / 2;
    final direction = Offset(to.dx - from.dx, to.dy - from.dy);
    final length = direction.distance;
    if (length < 20) return;

    final unit = direction / length;
    final normal = Offset(-unit.dy, unit.dx);
    final arrowSize = 8.0;

    final tip = Offset(midX + unit.dx * 10, midY + unit.dy * 10);
    final left = tip - unit * arrowSize + normal * arrowSize / 2;
    final right = tip - unit * arrowSize - normal * arrowSize / 2;

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
  bool shouldRepaint(covariant ComplexPlanePainter oldDelegate) =>
      realPart != oldDelegate.realPart ||
      imagPart != oldDelegate.imagPart ||
      showPolar != oldDelegate.showPolar ||
      showConjugate != oldDelegate.showConjugate ||
      operationIndex != oldDelegate.operationIndex;
}
