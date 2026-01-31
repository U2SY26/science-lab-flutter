import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 미분 시각화 시뮬레이션
class DerivativeScreen extends StatefulWidget {
  const DerivativeScreen({super.key});

  @override
  State<DerivativeScreen> createState() => _DerivativeScreenState();
}

class _DerivativeScreenState extends State<DerivativeScreen> {
  String _function = 'x²';
  double _xPoint = 1.0;
  double _h = 1.0;
  bool _showSecant = true;
  bool _showTangent = true;

  final Map<String, String> _derivatives = {
    'x²': '2x',
    'x³': '3x²',
    'sin(x)': 'cos(x)',
    'eˣ': 'eˣ',
  };

  double _f(double x) {
    switch (_function) {
      case 'x²':
        return x * x;
      case 'x³':
        return x * x * x;
      case 'sin(x)':
        return math.sin(x);
      case 'eˣ':
        return math.exp(x);
      default:
        return x;
    }
  }

  double _fPrime(double x) {
    switch (_function) {
      case 'x²':
        return 2 * x;
      case 'x³':
        return 3 * x * x;
      case 'sin(x)':
        return math.cos(x);
      case 'eˣ':
        return math.exp(x);
      default:
        return 1;
    }
  }

  double get _secantSlope => (_f(_xPoint + _h) - _f(_xPoint)) / _h;
  double get _tangentSlope => _fPrime(_xPoint);

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
              '미분',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '미분 시각화',
          formula: "f'(x) = lim[h→0] (f(x+h) - f(x)) / h",
          formulaDescription: '할선의 기울기가 접선의 기울기로 수렴',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _DerivativePainter(
                function: _f,
                derivative: _fPrime,
                xPoint: _xPoint,
                h: _h,
                showSecant: _showSecant,
                showTangent: _showTangent,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 기울기 비교
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
                        _InfoItem(label: '할선 기울기', value: _secantSlope.toStringAsFixed(3), color: Colors.orange),
                        _InfoItem(label: '접선 기울기', value: _tangentSlope.toStringAsFixed(3), color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'h → 0 일수록 할선 → 접선',
                      style: TextStyle(
                        color: (_secantSlope - _tangentSlope).abs() < 0.1 ? Colors.green : AppColors.muted,
                        fontSize: 11,
                        fontWeight: (_secantSlope - _tangentSlope).abs() < 0.1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 함수 선택
              PresetGroup(
                label: '함수',
                presets: _derivatives.keys.map((f) {
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
              const SizedBox(height: 12),

              // 도함수 표시
              Center(
                child: Text(
                  "f'(x) = ${_derivatives[_function]}",
                  style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // 표시 옵션
              Row(
                children: [
                  Expanded(
                    child: _OptionChip(
                      label: '할선',
                      isSelected: _showSecant,
                      color: Colors.orange,
                      onTap: () => setState(() => _showSecant = !_showSecant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OptionChip(
                      label: '접선',
                      isSelected: _showTangent,
                      color: Colors.green,
                      onTap: () => setState(() => _showTangent = !_showTangent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: 'h 값 (작을수록 정확)',
                  value: _h,
                  min: 0.01,
                  max: 2.0,
                  defaultValue: 1.0,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _h = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: 'x 위치',
                    value: _xPoint,
                    min: -2,
                    max: 2,
                    defaultValue: 1.0,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _xPoint = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.simBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : AppColors.cardBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: isSelected ? color : AppColors.muted, fontSize: 12),
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

class _DerivativePainter extends CustomPainter {
  final double Function(double) function;
  final double Function(double) derivative;
  final double xPoint;
  final double h;
  final bool showSecant;
  final bool showTangent;

  _DerivativePainter({
    required this.function,
    required this.derivative,
    required this.xPoint,
    required this.h,
    required this.showSecant,
    required this.showTangent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 30.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 축
    canvas.drawLine(
      Offset(padding, centerY),
      Offset(size.width - padding, centerY),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );
    canvas.drawLine(
      Offset(centerX, padding),
      Offset(centerX, size.height - padding),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );

    final xScale = graphWidth / 6; // -3 to 3
    final yScale = graphHeight / 6;

    // 함수 그래프
    final path = Path();
    for (double px = 0; px <= graphWidth; px += 2) {
      final x = (px - graphWidth / 2) / xScale;
      final y = function(x);

      if (y.isFinite && y.abs() < 10) {
        final screenX = padding + px;
        final screenY = centerY - y * yScale;

        if (px == 0) {
          path.moveTo(screenX, screenY.clamp(padding, size.height - padding));
        } else {
          path.lineTo(screenX, screenY.clamp(padding, size.height - padding));
        }
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 점 (x, f(x))
    final pointX = centerX + xPoint * xScale;
    final pointY = centerY - function(xPoint) * yScale;

    canvas.drawCircle(Offset(pointX, pointY), 6, Paint()..color = Colors.blue);

    // 할선 (secant line)
    if (showSecant) {
      final point2X = centerX + (xPoint + h) * xScale;
      final point2Y = centerY - function(xPoint + h) * yScale;

      canvas.drawCircle(Offset(point2X, point2Y), 4, Paint()..color = Colors.orange);

      // 할선 연장
      final secantSlope = (function(xPoint + h) - function(xPoint)) / h;
      final lineStartX = padding;
      final lineEndX = size.width - padding;
      final lineStartY = pointY - (pointX - lineStartX) / xScale * secantSlope * yScale;
      final lineEndY = pointY - (pointX - lineEndX) / xScale * secantSlope * yScale;

      canvas.drawLine(
        Offset(lineStartX, lineStartY.clamp(padding, size.height - padding)),
        Offset(lineEndX, lineEndY.clamp(padding, size.height - padding)),
        Paint()
          ..color = Colors.orange.withValues(alpha: 0.7)
          ..strokeWidth = 2,
      );
    }

    // 접선 (tangent line)
    if (showTangent) {
      final tangentSlope = derivative(xPoint);
      final lineStartX = padding;
      final lineEndX = size.width - padding;
      final lineStartY = pointY - (pointX - lineStartX) / xScale * tangentSlope * yScale;
      final lineEndY = pointY - (pointX - lineEndX) / xScale * tangentSlope * yScale;

      canvas.drawLine(
        Offset(lineStartX, lineStartY.clamp(padding, size.height - padding)),
        Offset(lineEndX, lineEndY.clamp(padding, size.height - padding)),
        Paint()
          ..color = Colors.green
          ..strokeWidth = 2,
      );
    }

    // 범례
    if (showSecant) {
      canvas.drawLine(Offset(size.width - 80, 15), Offset(size.width - 60, 15), Paint()..color = Colors.orange..strokeWidth = 2);
      _drawText(canvas, '할선', Offset(size.width - 55, 9), Colors.orange, fontSize: 10);
    }
    if (showTangent) {
      canvas.drawLine(Offset(size.width - 80, 30), Offset(size.width - 60, 30), Paint()..color = Colors.green..strokeWidth = 2);
      _drawText(canvas, '접선', Offset(size.width - 55, 24), Colors.green, fontSize: 10);
    }
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
  bool shouldRepaint(covariant _DerivativePainter oldDelegate) => true;
}
