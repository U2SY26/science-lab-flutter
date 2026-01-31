import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 리만 합 시뮬레이션
class RiemannSumScreen extends StatefulWidget {
  const RiemannSumScreen({super.key});

  @override
  State<RiemannSumScreen> createState() => _RiemannSumScreenState();
}

class _RiemannSumScreenState extends State<RiemannSumScreen> {
  String _function = 'x²';
  int _rectangles = 5;
  String _method = 'left';
  double _a = 0;
  double _b = 2;

  double _f(double x) {
    switch (_function) {
      case 'x²':
        return x * x;
      case 'sin(x)':
        return math.sin(x) + 1;
      case '√x':
        return x >= 0 ? math.sqrt(x) : 0;
      case 'x³':
        return x * x * x;
      default:
        return x;
    }
  }

  double get _riemannSum {
    final dx = (_b - _a) / _rectangles;
    double sum = 0;

    for (int i = 0; i < _rectangles; i++) {
      double x;
      switch (_method) {
        case 'left':
          x = _a + i * dx;
          break;
        case 'right':
          x = _a + (i + 1) * dx;
          break;
        case 'midpoint':
          x = _a + (i + 0.5) * dx;
          break;
        default:
          x = _a + i * dx;
      }
      sum += _f(x) * dx;
    }
    return sum;
  }

  double get _exactIntegral {
    switch (_function) {
      case 'x²':
        return (_b * _b * _b - _a * _a * _a) / 3;
      case 'sin(x)':
        return (-math.cos(_b) + math.cos(_a)) + (_b - _a);
      case '√x':
        return (2 / 3) * (math.pow(_b, 1.5) - math.pow(_a, 1.5));
      case 'x³':
        return (math.pow(_b, 4) - math.pow(_a, 4)) / 4;
      default:
        return 0;
    }
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
              '수학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '리만 합',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '리만 합 (Riemann Sum)',
          formula: '∫f(x)dx ≈ Σf(xᵢ)Δx',
          formulaDescription: '사각형 넓이의 합으로 정적분 근사',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _RiemannSumPainter(
                function: _f,
                rectangles: _rectangles,
                method: _method,
                a: _a,
                b: _b,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 적분값 비교
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
                        _InfoItem(label: '리만 합', value: _riemannSum.toStringAsFixed(4), color: Colors.orange),
                        _InfoItem(label: '실제 적분값', value: _exactIntegral.toStringAsFixed(4), color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '오차: ${(_riemannSum - _exactIntegral).abs().toStringAsFixed(4)}',
                      style: TextStyle(
                        color: (_riemannSum - _exactIntegral).abs() < 0.1 ? Colors.green : AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 함수 선택
              PresetGroup(
                label: '함수',
                presets: ['x²', 'sin(x)', '√x', 'x³'].map((f) {
                  return PresetButton(
                    label: 'f(x) = $f',
                    isSelected: _function == f,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _function = f);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 방법 선택
              PresetGroup(
                label: '방법',
                presets: [
                  PresetButton(
                    label: '왼쪽',
                    isSelected: _method == 'left',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _method = 'left');
                    },
                  ),
                  PresetButton(
                    label: '중점',
                    isSelected: _method == 'midpoint',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _method = 'midpoint');
                    },
                  ),
                  PresetButton(
                    label: '오른쪽',
                    isSelected: _method == 'right',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _method = 'right');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '사각형 개수',
                  value: _rectangles.toDouble(),
                  min: 2,
                  max: 50,
                  defaultValue: 5,
                  formatValue: (v) => '${v.toInt()}개',
                  onChanged: (v) => setState(() => _rectangles = v.toInt()),
                ),
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

  const _InfoItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }
}

class _RiemannSumPainter extends CustomPainter {
  final double Function(double) function;
  final int rectangles;
  final String method;
  final double a, b;

  _RiemannSumPainter({
    required this.function,
    required this.rectangles,
    required this.method,
    required this.a,
    required this.b,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 축
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      Paint()..color = AppColors.muted,
    );
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      Paint()..color = AppColors.muted,
    );

    final xScale = graphWidth / 3;
    final yScale = graphHeight / 5;
    final originY = size.height - padding;

    // 사각형 그리기
    final dx = (b - a) / rectangles;
    for (int i = 0; i < rectangles; i++) {
      double x;
      switch (method) {
        case 'left':
          x = a + i * dx;
          break;
        case 'right':
          x = a + (i + 1) * dx;
          break;
        case 'midpoint':
          x = a + (i + 0.5) * dx;
          break;
        default:
          x = a + i * dx;
      }

      final height = function(x);
      final rectLeft = padding + (a + i * dx) * xScale;
      final rectWidth = dx * xScale;
      final rectHeight = height * yScale;

      canvas.drawRect(
        Rect.fromLTWH(rectLeft, originY - rectHeight, rectWidth, rectHeight),
        Paint()..color = Colors.orange.withValues(alpha: 0.3),
      );
      canvas.drawRect(
        Rect.fromLTWH(rectLeft, originY - rectHeight, rectWidth, rectHeight),
        Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // 함수 그래프
    final path = Path();
    for (double px = 0; px <= graphWidth; px += 2) {
      final x = px / xScale;
      final y = function(x);

      final screenX = padding + px;
      final screenY = originY - y * yScale;

      if (px == 0) {
        path.moveTo(screenX, screenY.clamp(padding, size.height - padding));
      } else {
        path.lineTo(screenX, screenY.clamp(padding, size.height - padding));
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 적분 구간 표시
    _drawText(canvas, 'a=$a', Offset(padding + a * xScale - 10, originY + 5), AppColors.muted, fontSize: 10);
    _drawText(canvas, 'b=$b', Offset(padding + b * xScale - 10, originY + 5), AppColors.muted, fontSize: 10);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _RiemannSumPainter oldDelegate) => true;
}
