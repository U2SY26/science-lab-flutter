import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 테일러 급수 시뮬레이션
class TaylorSeriesScreen extends StatefulWidget {
  const TaylorSeriesScreen({super.key});

  @override
  State<TaylorSeriesScreen> createState() => _TaylorSeriesScreenState();
}

class _TaylorSeriesScreenState extends State<TaylorSeriesScreen> {
  String _function = 'sin(x)';
  int _terms = 3;
  double _center = 0;

  final Map<String, String> _formulas = {
    'sin(x)': 'sin(x) = x - x³/3! + x⁵/5! - ...',
    'cos(x)': 'cos(x) = 1 - x²/2! + x⁴/4! - ...',
    'e^x': 'eˣ = 1 + x + x²/2! + x³/3! + ...',
    'ln(1+x)': 'ln(1+x) = x - x²/2 + x³/3 - ...',
  };

  double _originalFunction(double x) {
    switch (_function) {
      case 'sin(x)':
        return math.sin(x);
      case 'cos(x)':
        return math.cos(x);
      case 'e^x':
        return math.exp(x);
      case 'ln(1+x)':
        return x > -1 ? math.log(1 + x) : double.nan;
      default:
        return 0;
    }
  }

  double _taylorApprox(double x) {
    final a = _center;
    double sum = 0;

    switch (_function) {
      case 'sin(x)':
        for (int n = 0; n < _terms; n++) {
          final power = 2 * n + 1;
          sum += math.pow(-1, n) * math.pow(x - a, power) / _factorial(power);
        }
        break;
      case 'cos(x)':
        for (int n = 0; n < _terms; n++) {
          final power = 2 * n;
          sum += math.pow(-1, n) * math.pow(x - a, power) / _factorial(power);
        }
        break;
      case 'e^x':
        for (int n = 0; n < _terms; n++) {
          sum += math.pow(x - a, n) / _factorial(n);
        }
        sum *= math.exp(a);
        break;
      case 'ln(1+x)':
        for (int n = 1; n <= _terms; n++) {
          sum += math.pow(-1, n + 1) * math.pow(x, n) / n;
        }
        break;
    }
    return sum;
  }

  double _factorial(int n) {
    if (n <= 1) return 1;
    double result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
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
              '테일러 급수',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '테일러 급수',
          formula: _formulas[_function] ?? '',
          formulaDescription: '함수를 무한 다항식으로 근사하는 전개식',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _TaylorSeriesPainter(
                originalFunction: _originalFunction,
                taylorApprox: _taylorApprox,
                terms: _terms,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 함수 선택
              PresetGroup(
                label: '함수',
                presets: _formulas.keys.map((f) {
                  return PresetButton(
                    label: f,
                    isSelected: _function == f,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _function = f);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 항 개수 표시
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('항 개수: ', style: TextStyle(color: AppColors.muted)),
                    Text(
                      '$_terms',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '(항이 많을수록 정확)',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '항 개수',
                  value: _terms.toDouble(),
                  min: 1,
                  max: 10,
                  defaultValue: 3,
                  formatValue: (v) => '${v.toInt()}항',
                  onChanged: (v) => setState(() => _terms = v.toInt()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaylorSeriesPainter extends CustomPainter {
  final double Function(double) originalFunction;
  final double Function(double) taylorApprox;
  final int terms;

  _TaylorSeriesPainter({
    required this.originalFunction,
    required this.taylorApprox,
    required this.terms,
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

    // 원래 함수 (파랑)
    final originalPath = Path();
    final xRange = 6.0;

    for (double px = 0; px <= graphWidth; px += 2) {
      final x = (px / graphWidth - 0.5) * xRange;
      final y = originalFunction(x);

      if (y.isFinite && y.abs() < 5) {
        final screenX = padding + px;
        final screenY = centerY - y * graphHeight / 4;

        if (px == 0) {
          originalPath.moveTo(screenX, screenY.clamp(padding, size.height - padding));
        } else {
          originalPath.lineTo(screenX, screenY.clamp(padding, size.height - padding));
        }
      }
    }

    canvas.drawPath(
      originalPath,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 테일러 근사 (빨강)
    final taylorPath = Path();

    for (double px = 0; px <= graphWidth; px += 2) {
      final x = (px / graphWidth - 0.5) * xRange;
      final y = taylorApprox(x);

      if (y.isFinite && y.abs() < 5) {
        final screenX = padding + px;
        final screenY = centerY - y * graphHeight / 4;

        if (px == 0) {
          taylorPath.moveTo(screenX, screenY.clamp(padding, size.height - padding));
        } else {
          taylorPath.lineTo(screenX, screenY.clamp(padding, size.height - padding));
        }
      }
    }

    canvas.drawPath(
      taylorPath,
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 범례
    _drawLegend(canvas, size);
  }

  void _drawLegend(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width - 100, 20),
      Offset(size.width - 80, 20),
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2,
    );
    _drawText(canvas, '원래 함수', Offset(size.width - 75, 14), Colors.blue, fontSize: 10);

    canvas.drawLine(
      Offset(size.width - 100, 35),
      Offset(size.width - 80, 35),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2,
    );
    _drawText(canvas, '테일러 근사', Offset(size.width - 75, 29), Colors.red, fontSize: 10);
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
  bool shouldRepaint(covariant _TaylorSeriesPainter oldDelegate) => true;
}
