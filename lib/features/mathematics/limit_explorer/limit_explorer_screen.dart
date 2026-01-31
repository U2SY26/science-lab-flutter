import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 극한 탐색기 시뮬레이션
class LimitExplorerScreen extends StatefulWidget {
  const LimitExplorerScreen({super.key});

  @override
  State<LimitExplorerScreen> createState() => _LimitExplorerScreenState();
}

class _LimitExplorerScreenState extends State<LimitExplorerScreen> {
  String _limitType = 'sinx/x';
  double _epsilon = 0.5;

  final Map<String, double> _limits = {
    'sinx/x': 1.0,
    '(1+1/n)^n': math.e,
    '(x²-1)/(x-1)': 2.0,
    'tanx/x': 1.0,
  };

  double _f(double x) {
    switch (_limitType) {
      case 'sinx/x':
        return x == 0 ? double.nan : math.sin(x) / x;
      case '(1+1/n)^n':
        return x == 0 ? double.nan : math.pow(1 + 1 / x, x).toDouble();
      case '(x²-1)/(x-1)':
        return x == 1 ? double.nan : (x * x - 1) / (x - 1);
      case 'tanx/x':
        return x == 0 ? double.nan : math.tan(x) / x;
      default:
        return 0;
    }
  }

  double get _approachPoint {
    switch (_limitType) {
      case 'sinx/x':
      case 'tanx/x':
        return 0;
      case '(1+1/n)^n':
        return double.infinity;
      case '(x²-1)/(x-1)':
        return 1;
      default:
        return 0;
    }
  }

  List<_ApproachValue> get _approachValues {
    final values = <_ApproachValue>[];
    final point = _approachPoint;

    if (point.isFinite) {
      for (int i = 1; i <= 5; i++) {
        final delta = _epsilon / math.pow(10, i - 1);
        values.add(_ApproachValue(
          x: point + delta,
          fx: _f(point + delta),
          label: '+${delta.toStringAsFixed(i + 1)}',
        ));
        values.add(_ApproachValue(
          x: point - delta,
          fx: _f(point - delta),
          label: '-${delta.toStringAsFixed(i + 1)}',
        ));
      }
    } else {
      // n → ∞
      for (int i = 1; i <= 5; i++) {
        final n = math.pow(10, i).toDouble();
        values.add(_ApproachValue(
          x: n,
          fx: _f(n),
          label: 'n=${n.toInt()}',
        ));
      }
    }
    return values;
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
              '극한',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '극한 탐색기',
          formula: 'lim[x→a] f(x) = L',
          formulaDescription: 'x가 a에 가까워질 때 f(x)의 수렴값',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _LimitPainter(
                function: _f,
                limitType: _limitType,
                epsilon: _epsilon,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 극한값 표시
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'lim = ',
                          style: TextStyle(color: AppColors.muted, fontSize: 18),
                        ),
                        Text(
                          _limits[_limitType]!.toStringAsFixed(6),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    if (_limitType == '(1+1/n)^n')
                      const Text('= e', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 수렴 표
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    const Text('접근값 표', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._approachValues.take(6).map((v) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(v.label, style: const TextStyle(color: AppColors.muted, fontSize: 11, fontFamily: 'monospace')),
                              Text(
                                v.fx.isFinite ? v.fx.toStringAsFixed(6) : 'undefined',
                                style: TextStyle(
                                  color: v.fx.isFinite ? AppColors.accent : Colors.red,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 극한 선택
              PresetGroup(
                label: '극한',
                presets: _limits.keys.map((l) {
                  return PresetButton(
                    label: l,
                    isSelected: _limitType == l,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _limitType = l);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              if (_approachPoint.isFinite)
                ControlGroup(
                  primaryControl: SimSlider(
                    label: 'ε (접근 거리)',
                    value: _epsilon,
                    min: 0.01,
                    max: 1.0,
                    defaultValue: 0.5,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _epsilon = v),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApproachValue {
  final double x;
  final double fx;
  final String label;

  _ApproachValue({required this.x, required this.fx, required this.label});
}

class _LimitPainter extends CustomPainter {
  final double Function(double) function;
  final String limitType;
  final double epsilon;

  _LimitPainter({required this.function, required this.limitType, required this.epsilon});

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

    // 그래프 범위
    double xMin, xMax, yMin, yMax;
    if (limitType == '(1+1/n)^n') {
      xMin = 0;
      xMax = 100;
      yMin = 0;
      yMax = 4;
    } else {
      xMin = -3;
      xMax = 3;
      yMin = -2;
      yMax = 2;
    }

    final xScale = graphWidth / (xMax - xMin);
    final yScale = graphHeight / (yMax - yMin);

    // 함수 그래프
    final path = Path();
    bool firstPoint = true;

    for (double px = 0; px <= graphWidth; px += 2) {
      final x = xMin + px / xScale;
      final y = function(x);

      if (y.isFinite && y > yMin - 1 && y < yMax + 1) {
        final screenX = padding + px;
        final screenY = centerY - (y - (yMax + yMin) / 2) * yScale;

        if (firstPoint) {
          path.moveTo(screenX, screenY.clamp(padding, size.height - padding));
          firstPoint = false;
        } else {
          path.lineTo(screenX, screenY.clamp(padding, size.height - padding));
        }
      } else {
        firstPoint = true;
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 극한점 표시
    double limitX, limitY;
    switch (limitType) {
      case 'sinx/x':
      case 'tanx/x':
        limitX = 0;
        limitY = 1;
        break;
      case '(x²-1)/(x-1)':
        limitX = 1;
        limitY = 2;
        break;
      default:
        limitX = xMax;
        limitY = math.e;
    }

    final screenLimitX = padding + (limitX - xMin) * xScale;
    final screenLimitY = centerY - (limitY - (yMax + yMin) / 2) * yScale;

    // 극한 점 (빈 원)
    canvas.drawCircle(
      Offset(screenLimitX, screenLimitY),
      6,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 수평 점선 (극한값)
    _drawDashedLine(
      canvas,
      Offset(padding, screenLimitY),
      Offset(size.width - padding, screenLimitY),
      Colors.green.withValues(alpha: 0.5),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final dashLength = 5.0;
    final gapLength = 3.0;
    final count = (distance / (dashLength + gapLength)).floor();

    for (int i = 0; i < count; i++) {
      final startFraction = i * (dashLength + gapLength) / distance;
      final endFraction = (i * (dashLength + gapLength) + dashLength) / distance;
      canvas.drawLine(
        Offset(start.dx + dx * startFraction, start.dy + dy * startFraction),
        Offset(start.dx + dx * endFraction, start.dy + dy * endFraction),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LimitPainter oldDelegate) => true;
}
