import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 원뿔 곡선 시뮬레이션
class ConicSectionsScreen extends StatefulWidget {
  const ConicSectionsScreen({super.key});

  @override
  State<ConicSectionsScreen> createState() => _ConicSectionsScreenState();
}

class _ConicSectionsScreenState extends State<ConicSectionsScreen> {
  String _conic = 'ellipse';
  double _a = 2.0;
  double _b = 1.5;

  final Map<String, String> _formulas = {
    'circle': 'x² + y² = r²',
    'ellipse': 'x²/a² + y²/b² = 1',
    'parabola': 'y² = 4px',
    'hyperbola': 'x²/a² - y²/b² = 1',
  };

  final Map<String, String> _descriptions = {
    'circle': '이심률 e = 0',
    'ellipse': '0 < e < 1',
    'parabola': 'e = 1',
    'hyperbola': 'e > 1',
  };

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
              '원뿔 곡선',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '원뿔 곡선 (Conic Sections)',
          formula: _formulas[_conic]!,
          formulaDescription: _descriptions[_conic]!,
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _ConicPainter(
                conic: _conic,
                a: _a,
                b: _b,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 원뿔 곡선 선택
              PresetGroup(
                label: '곡선 종류',
                presets: [
                  PresetButton(
                    label: '원',
                    isSelected: _conic == 'circle',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _conic = 'circle');
                    },
                  ),
                  PresetButton(
                    label: '타원',
                    isSelected: _conic == 'ellipse',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _conic = 'ellipse');
                    },
                  ),
                  PresetButton(
                    label: '포물선',
                    isSelected: _conic == 'parabola',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _conic = 'parabola');
                    },
                  ),
                  PresetButton(
                    label: '쌍곡선',
                    isSelected: _conic == 'hyperbola',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _conic = 'hyperbola');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 정보 표시
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getConicInfo(), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: _conic == 'parabola' ? 'p (초점 거리)' : 'a (장축/가로)',
                  value: _a,
                  min: 0.5,
                  max: 3,
                  defaultValue: 2.0,
                  formatValue: (v) => v.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _a = v),
                ),
                advancedControls: _conic != 'circle' && _conic != 'parabola'
                    ? [
                        SimSlider(
                          label: 'b (단축/세로)',
                          value: _b,
                          min: 0.5,
                          max: 3,
                          defaultValue: 1.5,
                          formatValue: (v) => v.toStringAsFixed(1),
                          onChanged: (v) => setState(() => _b = v),
                        ),
                      ]
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getConicInfo() {
    switch (_conic) {
      case 'circle':
        return '원: 한 점(중심)에서 같은 거리에 있는 모든 점의 집합\n반지름 r = ${_a.toStringAsFixed(1)}';
      case 'ellipse':
        final c = math.sqrt((_a * _a - _b * _b).abs());
        final e = c / math.max(_a, _b);
        return '타원: 두 초점으로부터 거리의 합이 일정한 점의 집합\n이심률 e = ${e.toStringAsFixed(3)}';
      case 'parabola':
        return '포물선: 초점과 준선으로부터 같은 거리에 있는 점의 집합\n초점 거리 p = ${_a.toStringAsFixed(1)}';
      case 'hyperbola':
        final c = math.sqrt(_a * _a + _b * _b);
        final e = c / _a;
        return '쌍곡선: 두 초점으로부터 거리의 차가 일정한 점의 집합\n이심률 e = ${e.toStringAsFixed(3)}';
      default:
        return '';
    }
  }
}

class _ConicPainter extends CustomPainter {
  final String conic;
  final double a, b;

  _ConicPainter({
    required this.conic,
    required this.a,
    required this.b,
  });

  // sinh and cosh helpers (not in dart:math)
  double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
  double _cosh(double x) => (math.exp(x) + math.exp(-x)) / 2;

  late Size _size;

  @override
  void paint(Canvas canvas, Size size) {
    _size = size;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 8;

    // 축
    canvas.drawLine(
      Offset(30, centerY),
      Offset(size.width - 30, centerY),
      Paint()..color = AppColors.muted.withValues(alpha: 0.3),
    );
    canvas.drawLine(
      Offset(centerX, 30),
      Offset(centerX, size.height - 30),
      Paint()..color = AppColors.muted.withValues(alpha: 0.3),
    );

    switch (conic) {
      case 'circle':
        _drawCircle(canvas, centerX, centerY, scale);
        break;
      case 'ellipse':
        _drawEllipse(canvas, centerX, centerY, scale);
        break;
      case 'parabola':
        _drawParabola(canvas, centerX, centerY, scale);
        break;
      case 'hyperbola':
        _drawHyperbola(canvas, centerX, centerY, scale);
        break;
    }
  }

  void _drawCircle(Canvas canvas, double cx, double cy, double scale) {
    final r = a * scale;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = Colors.blue.withValues(alpha: 0.2),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 중심점
    canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = Colors.red);
    _drawText(canvas, 'O', Offset(cx + 8, cy - 15), Colors.red);

    // 반지름 표시
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r, cy),
      Paint()..color = Colors.green..strokeWidth = 2,
    );
    _drawText(canvas, 'r', Offset(cx + r / 2 - 5, cy - 15), Colors.green);
  }

  void _drawEllipse(Canvas canvas, double cx, double cy, double scale) {
    final aScaled = a * scale;
    final bScaled = b * scale;

    // 타원
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: aScaled * 2, height: bScaled * 2),
      Paint()..color = Colors.blue.withValues(alpha: 0.2),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: aScaled * 2, height: bScaled * 2),
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 초점
    final c = math.sqrt((aScaled * aScaled - bScaled * bScaled).abs());
    if (a > b) {
      canvas.drawCircle(Offset(cx - c, cy), 5, Paint()..color = Colors.red);
      canvas.drawCircle(Offset(cx + c, cy), 5, Paint()..color = Colors.red);
      _drawText(canvas, 'F₁', Offset(cx - c - 10, cy + 10), Colors.red);
      _drawText(canvas, 'F₂', Offset(cx + c + 5, cy + 10), Colors.red);
    } else {
      canvas.drawCircle(Offset(cx, cy - c), 5, Paint()..color = Colors.red);
      canvas.drawCircle(Offset(cx, cy + c), 5, Paint()..color = Colors.red);
    }

    // 축 표시
    canvas.drawLine(Offset(cx - aScaled, cy), Offset(cx + aScaled, cy), Paint()..color = Colors.green.withValues(alpha: 0.5)..strokeWidth = 1);
    canvas.drawLine(Offset(cx, cy - bScaled), Offset(cx, cy + bScaled), Paint()..color = Colors.orange.withValues(alpha: 0.5)..strokeWidth = 1);
  }

  void _drawParabola(Canvas canvas, double cx, double cy, double scale) {
    final p = a * scale / 2;

    final path = Path();
    for (double t = -3; t <= 3; t += 0.05) {
      final y = t * scale;
      final x = y * y / (4 * p);

      if (t == -3) {
        path.moveTo(cx + x, cy + y);
      } else {
        path.lineTo(cx + x, cy + y);
      }
    }

    canvas.drawPath(path, Paint()..color = Colors.blue.withValues(alpha: 0.3)..strokeWidth = 3..style = PaintingStyle.stroke);
    canvas.drawPath(path, Paint()..color = Colors.blue..strokeWidth = 2..style = PaintingStyle.stroke);

    // 초점
    canvas.drawCircle(Offset(cx + p, cy), 5, Paint()..color = Colors.red);
    _drawText(canvas, 'F', Offset(cx + p + 8, cy - 5), Colors.red);

    // 준선
    canvas.drawLine(
      Offset(cx - p, cy - _size.height / 2 + 30),
      Offset(cx - p, cy + _size.height / 2 - 30),
      Paint()
        ..color = Colors.green
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    _drawText(canvas, '준선', Offset(cx - p - 30, cy - _size.height / 4), Colors.green, fontSize: 10);
  }

  void _drawHyperbola(Canvas canvas, double cx, double cy, double scale) {
    final aScaled = a * scale;
    final bScaled = b * scale;

    // 오른쪽 가지
    final rightPath = Path();
    for (double t = -2; t <= 2; t += 0.05) {
      final y = bScaled * _sinh(t);
      final x = aScaled * _cosh(t);

      if (t == -2) {
        rightPath.moveTo(cx + x, cy + y);
      } else {
        rightPath.lineTo(cx + x, cy + y);
      }
    }

    // 왼쪽 가지
    final leftPath = Path();
    for (double t = -2; t <= 2; t += 0.05) {
      final y = bScaled * _sinh(t);
      final x = -aScaled * _cosh(t);

      if (t == -2) {
        leftPath.moveTo(cx + x, cy + y);
      } else {
        leftPath.lineTo(cx + x, cy + y);
      }
    }

    canvas.drawPath(rightPath, Paint()..color = Colors.blue..strokeWidth = 2..style = PaintingStyle.stroke);
    canvas.drawPath(leftPath, Paint()..color = Colors.blue..strokeWidth = 2..style = PaintingStyle.stroke);

    // 초점
    final c = math.sqrt(aScaled * aScaled + bScaled * bScaled);
    canvas.drawCircle(Offset(cx - c, cy), 5, Paint()..color = Colors.red);
    canvas.drawCircle(Offset(cx + c, cy), 5, Paint()..color = Colors.red);

    // 점근선
    final asymptoteSlope = bScaled / aScaled;
    canvas.drawLine(
      Offset(cx - _size.width / 2, cy + _size.width / 2 * asymptoteSlope),
      Offset(cx + _size.width / 2, cy - _size.width / 2 * asymptoteSlope),
      Paint()..color = Colors.orange.withValues(alpha: 0.5)..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(cx - _size.width / 2, cy - _size.width / 2 * asymptoteSlope),
      Offset(cx + _size.width / 2, cy + _size.width / 2 * asymptoteSlope),
      Paint()..color = Colors.orange.withValues(alpha: 0.5)..strokeWidth = 1,
    );
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _ConicPainter oldDelegate) => true;
}
