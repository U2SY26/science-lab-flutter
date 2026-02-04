import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Integral Visualizer - Area under the curve
/// 적분 시각화 - 곡선 아래 면적
class IntegralScreen extends StatefulWidget {
  const IntegralScreen({super.key});

  @override
  State<IntegralScreen> createState() => _IntegralScreenState();
}

class _IntegralScreenState extends State<IntegralScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const int _defaultRectangles = 10;
  static const double _defaultLowerBound = 0.0;
  static const double _defaultUpperBound = 3.0;

  int numRectangles = _defaultRectangles;
  double lowerBound = _defaultLowerBound;
  double upperBound = _defaultUpperBound;
  int functionIndex = 0; // 0: x², 1: sin(x), 2: e^x, 3: 1/x
  int methodIndex = 0; // 0: left, 1: right, 2: midpoint, 3: trapezoid
  bool isAnimating = false;
  double animationProgress = 1.0;
  bool isKorean = true;

  final List<String> _functions = ['x²', 'sin(x)', 'eˣ', '√x'];
  final List<String> _methods = ['Left', 'Right', 'Midpoint', 'Trapezoid'];
  final List<String> _methodsKo = ['좌측', '우측', '중점', '사다리꼴'];

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
  }

  double _f(double x) {
    switch (functionIndex) {
      case 0:
        return x * x;
      case 1:
        return math.sin(x) + 1.5;
      case 2:
        return math.exp(x * 0.5);
      case 3:
        return x > 0 ? math.sqrt(x) : 0;
      default:
        return x;
    }
  }

  double _exactIntegral() {
    switch (functionIndex) {
      case 0: // x² -> x³/3
        return (math.pow(upperBound, 3) - math.pow(lowerBound, 3)) / 3;
      case 1: // sin(x)+1.5 -> -cos(x)+1.5x
        return (-math.cos(upperBound) + 1.5 * upperBound) -
            (-math.cos(lowerBound) + 1.5 * lowerBound);
      case 2: // e^(0.5x) -> 2e^(0.5x)
        return 2 * (math.exp(upperBound * 0.5) - math.exp(lowerBound * 0.5));
      case 3: // sqrt(x) -> (2/3)x^(3/2)
        return (2 / 3) *
            (math.pow(upperBound, 1.5) - math.pow(lowerBound > 0 ? lowerBound : 0, 1.5));
      default:
        return 0;
    }
  }

  double _approximateIntegral() {
    if (numRectangles <= 0) return 0;
    final dx = (upperBound - lowerBound) / numRectangles;
    double sum = 0;

    for (int i = 0; i < numRectangles; i++) {
      final x0 = lowerBound + i * dx;
      final x1 = x0 + dx;

      switch (methodIndex) {
        case 0: // Left
          sum += _f(x0) * dx;
          break;
        case 1: // Right
          sum += _f(x1) * dx;
          break;
        case 2: // Midpoint
          sum += _f((x0 + x1) / 2) * dx;
          break;
        case 3: // Trapezoid
          sum += (_f(x0) + _f(x1)) / 2 * dx;
          break;
      }
    }
    return sum;
  }

  void _animate() {
    HapticFeedback.mediumImpact();
    _controller.reset();
    setState(() => isAnimating = true);
    _controller.forward().then((_) {
      setState(() => isAnimating = false);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      numRectangles = _defaultRectangles;
      lowerBound = _defaultLowerBound;
      upperBound = _defaultUpperBound;
      animationProgress = 1.0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exact = _exactIntegral();
    final approx = _approximateIntegral();
    final error = (approx - exact).abs();
    final errorPercent = exact != 0 ? (error / exact.abs() * 100) : 0;

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
              isKorean ? '미적분학' : 'CALCULUS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '적분 시각화' : 'Integral Visualizer',
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
          category: isKorean ? '미적분학' : 'CALCULUS',
          title: isKorean ? '적분 시각화' : 'Integral Visualizer',
          formula: '∫f(x)dx = lim[n→∞] Σf(xᵢ)Δx',
          formulaDescription: isKorean
              ? '정적분은 곡선 아래의 면적을 의미합니다. 직사각형의 개수가 증가할수록 근사값이 정확해집니다.'
              : 'The definite integral represents the area under the curve. More rectangles yield better approximation.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: IntegralPainter(
                function: _f,
                lowerBound: lowerBound,
                upperBound: upperBound,
                numRectangles: numRectangles,
                methodIndex: methodIndex,
                animationProgress: animationProgress,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Results display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _InfoItem(
                      label: isKorean ? '근사값' : 'Approx',
                      value: approx.toStringAsFixed(4),
                    ),
                    _InfoItem(
                      label: isKorean ? '정확값' : 'Exact',
                      value: exact.toStringAsFixed(4),
                    ),
                    _InfoItem(
                      label: isKorean ? '오차율' : 'Error',
                      value: '${errorPercent.toStringAsFixed(2)}%',
                      color: errorPercent < 1
                          ? Colors.green
                          : errorPercent < 5
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Function selection
              PresetGroup(
                label: isKorean ? '함수 선택' : 'Function',
                presets: List.generate(_functions.length, (i) {
                  return PresetButton(
                    label: 'f(x)=${_functions[i]}',
                    isSelected: functionIndex == i,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => functionIndex = i);
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Method selection
              PresetGroup(
                label: isKorean ? '근사 방법' : 'Method',
                presets: List.generate(_methods.length, (i) {
                  return PresetButton(
                    label: isKorean ? _methodsKo[i] : _methods[i],
                    isSelected: methodIndex == i,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => methodIndex = i);
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '직사각형 개수' : 'Number of Rectangles',
                  value: numRectangles.toDouble(),
                  min: 1,
                  max: 100,
                  defaultValue: _defaultRectangles.toDouble(),
                  formatValue: (v) => '${v.toInt()}',
                  onChanged: (v) => setState(() => numRectangles = v.toInt()),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '하한 (a)' : 'Lower Bound (a)',
                    value: lowerBound,
                    min: -2,
                    max: upperBound - 0.5,
                    defaultValue: _defaultLowerBound,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => lowerBound = v),
                  ),
                  SimSlider(
                    label: isKorean ? '상한 (b)' : 'Upper Bound (b)',
                    value: upperBound,
                    min: lowerBound + 0.5,
                    max: 5,
                    defaultValue: _defaultUpperBound,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => upperBound = v),
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
                isLoading: isAnimating,
                onPressed: isAnimating ? null : _animate,
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

class IntegralPainter extends CustomPainter {
  final double Function(double) function;
  final double lowerBound;
  final double upperBound;
  final int numRectangles;
  final int methodIndex;
  final double animationProgress;

  IntegralPainter({
    required this.function,
    required this.lowerBound,
    required this.upperBound,
    required this.numRectangles,
    required this.methodIndex,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // Determine scale
    final xMin = math.min(lowerBound - 0.5, -0.5);
    final xMax = math.max(upperBound + 0.5, 4.0);
    final xScale = graphWidth / (xMax - xMin);

    double yMin = 0;
    double yMax = 0;
    for (double x = xMin; x <= xMax; x += 0.1) {
      final y = function(x);
      if (y.isFinite) {
        yMin = math.min(yMin, y);
        yMax = math.max(yMax, y);
      }
    }
    yMax = math.max(yMax, 1) * 1.2;
    yMin = math.min(yMin, 0) - 0.2;
    final yScale = graphHeight / (yMax - yMin);

    double toScreenX(double x) => padding + (x - xMin) * xScale;
    double toScreenY(double y) => padding + graphHeight - (y - yMin) * yScale;

    // Draw grid
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int i = xMin.floor(); i <= xMax.ceil(); i++) {
      final x = toScreenX(i.toDouble());
      canvas.drawLine(Offset(x, padding), Offset(x, size.height - padding), gridPaint);
    }
    for (int i = yMin.floor(); i <= yMax.ceil(); i++) {
      final y = toScreenY(i.toDouble());
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;

    final xAxisY = toScreenY(0);
    final yAxisX = toScreenX(0);
    canvas.drawLine(Offset(padding, xAxisY), Offset(size.width - padding, xAxisY), axisPaint);
    canvas.drawLine(Offset(yAxisX, padding), Offset(yAxisX, size.height - padding), axisPaint);

    // Draw rectangles (animated)
    final visibleRects = (numRectangles * animationProgress).ceil();
    final dx = (upperBound - lowerBound) / numRectangles;

    for (int i = 0; i < visibleRects && i < numRectangles; i++) {
      final x0 = lowerBound + i * dx;
      final x1 = x0 + dx;
      double height;

      switch (methodIndex) {
        case 0: // Left
          height = function(x0);
          break;
        case 1: // Right
          height = function(x1);
          break;
        case 2: // Midpoint
          height = function((x0 + x1) / 2);
          break;
        case 3: // Trapezoid
          height = (function(x0) + function(x1)) / 2;
          break;
        default:
          height = function(x0);
      }

      if (height.isFinite) {
        final rectLeft = toScreenX(x0);
        final rectRight = toScreenX(x1);
        final rectTop = toScreenY(height);
        final rectBottom = toScreenY(0);

        // Fill
        canvas.drawRect(
          Rect.fromLTRB(rectLeft, rectTop, rectRight, rectBottom),
          Paint()..color = AppColors.accent.withValues(alpha: 0.3),
        );

        // Outline
        canvas.drawRect(
          Rect.fromLTRB(rectLeft, rectTop, rectRight, rectBottom),
          Paint()
            ..color = AppColors.accent.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        // For trapezoid, draw the sloped top
        if (methodIndex == 3) {
          final h0 = function(x0);
          final h1 = function(x1);
          canvas.drawLine(
            Offset(toScreenX(x0), toScreenY(h0)),
            Offset(toScreenX(x1), toScreenY(h1)),
            Paint()
              ..color = AppColors.accent
              ..strokeWidth = 2,
          );
        }
      }
    }

    // Draw function curve
    final curvePath = Path();
    bool started = false;
    for (double x = xMin; x <= xMax; x += 0.02) {
      final y = function(x);
      if (y.isFinite && y.abs() < 100) {
        final screenX = toScreenX(x);
        final screenY = toScreenY(y);
        if (!started) {
          curvePath.moveTo(screenX, screenY);
          started = true;
        } else {
          curvePath.lineTo(screenX, screenY);
        }
      }
    }
    canvas.drawPath(
      curvePath,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Draw bounds markers
    final boundsPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.7)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(toScreenX(lowerBound), padding),
      Offset(toScreenX(lowerBound), size.height - padding),
      boundsPaint,
    );
    canvas.drawLine(
      Offset(toScreenX(upperBound), padding),
      Offset(toScreenX(upperBound), size.height - padding),
      boundsPaint,
    );

    // Labels
    _drawText(canvas, 'a', Offset(toScreenX(lowerBound) - 5, size.height - padding + 5), Colors.red);
    _drawText(canvas, 'b', Offset(toScreenX(upperBound) - 5, size.height - padding + 5), Colors.red);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant IntegralPainter oldDelegate) =>
      animationProgress != oldDelegate.animationProgress ||
      numRectangles != oldDelegate.numRectangles ||
      methodIndex != oldDelegate.methodIndex ||
      lowerBound != oldDelegate.lowerBound ||
      upperBound != oldDelegate.upperBound;
}
