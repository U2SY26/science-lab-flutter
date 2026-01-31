import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 원 정리 시뮬레이션
class CircleTheoremsScreen extends StatefulWidget {
  const CircleTheoremsScreen({super.key});

  @override
  State<CircleTheoremsScreen> createState() => _CircleTheoremsScreenState();
}

class _CircleTheoremsScreenState extends State<CircleTheoremsScreen> {
  String _theorem = 'inscribed';
  double _angle1 = 0.5;
  double _angle2 = 2.0;
  double _angle3 = 4.0;

  final Map<String, String> _theoremNames = {
    'inscribed': '원주각 정리',
    'central': '중심각 정리',
    'tangent': '접선 정리',
    'chord': '현-접선각',
  };

  final Map<String, String> _descriptions = {
    'inscribed': '같은 호에 대한 원주각은 동일',
    'central': '중심각 = 원주각 × 2',
    'tangent': '접선과 반지름은 수직',
    'chord': '접선과 현이 이루는 각 = 원주각',
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
              '원 정리',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: _theoremNames[_theorem]!,
          formula: _theorem == 'central' ? '중심각 = 2 × 원주각' : '∠ABC = ∠ADC',
          formulaDescription: _descriptions[_theorem]!,
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _CircleTheoremPainter(
                theorem: _theorem,
                angle1: _angle1,
                angle2: _angle2,
                angle3: _angle3,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 정리 선택
              PresetGroup(
                label: '정리',
                presets: _theoremNames.keys.map((t) {
                  return PresetButton(
                    label: _theoremNames[t]!,
                    isSelected: _theorem == t,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _theorem = t);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 설명
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
                    Text(
                      _theoremNames[_theorem]!,
                      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTheoremExplanation(),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '점 A 위치',
                  value: _angle1,
                  min: 0,
                  max: 2 * math.pi,
                  defaultValue: 0.5,
                  formatValue: (v) => '${(v * 180 / math.pi).toInt()}°',
                  onChanged: (v) => setState(() => _angle1 = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '점 B 위치',
                    value: _angle2,
                    min: 0,
                    max: 2 * math.pi,
                    defaultValue: 2.0,
                    formatValue: (v) => '${(v * 180 / math.pi).toInt()}°',
                    onChanged: (v) => setState(() => _angle2 = v),
                  ),
                  SimSlider(
                    label: '점 C 위치',
                    value: _angle3,
                    min: 0,
                    max: 2 * math.pi,
                    defaultValue: 4.0,
                    formatValue: (v) => '${(v * 180 / math.pi).toInt()}°',
                    onChanged: (v) => setState(() => _angle3 = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTheoremExplanation() {
    switch (_theorem) {
      case 'inscribed':
        return '원에 내접하는 각 중 같은 호를 바라보는 원주각은 모두 같습니다. 점을 움직여 확인해보세요.';
      case 'central':
        return '중심각은 같은 호에 대한 원주각의 2배입니다. 중심에서 호를 바라보는 각과 원주에서 바라보는 각을 비교해보세요.';
      case 'tangent':
        return '접선과 그 접점을 지나는 반지름은 항상 수직입니다 (90°).';
      case 'chord':
        return '접선과 현이 이루는 각은 그 현에 대한 원주각과 같습니다.';
      default:
        return '';
    }
  }
}

class _CircleTheoremPainter extends CustomPainter {
  final String theorem;
  final double angle1, angle2, angle3;

  _CircleTheoremPainter({
    required this.theorem,
    required this.angle1,
    required this.angle2,
    required this.angle3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) * 0.35;

    // 원 그리기
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 중심점
    canvas.drawCircle(Offset(centerX, centerY), 4, Paint()..color = AppColors.ink);

    switch (theorem) {
      case 'inscribed':
        _drawInscribedAngle(canvas, centerX, centerY, radius);
        break;
      case 'central':
        _drawCentralAngle(canvas, centerX, centerY, radius);
        break;
      case 'tangent':
        _drawTangent(canvas, centerX, centerY, radius);
        break;
      case 'chord':
        _drawChordTangent(canvas, centerX, centerY, radius);
        break;
    }
  }

  void _drawInscribedAngle(Canvas canvas, double cx, double cy, double r) {
    // 호의 양 끝점
    final pA = Offset(cx + r * math.cos(angle1), cy + r * math.sin(angle1));
    final pB = Offset(cx + r * math.cos(angle2), cy + r * math.sin(angle2));
    // 원주각의 꼭짓점
    final pC = Offset(cx + r * math.cos(angle3), cy + r * math.sin(angle3));

    // 점 표시
    canvas.drawCircle(pA, 6, Paint()..color = Colors.red);
    canvas.drawCircle(pB, 6, Paint()..color = Colors.red);
    canvas.drawCircle(pC, 6, Paint()..color = Colors.green);

    // 원주각 그리기
    canvas.drawLine(pC, pA, Paint()..color = Colors.green..strokeWidth = 2);
    canvas.drawLine(pC, pB, Paint()..color = Colors.green..strokeWidth = 2);

    // 호 강조
    final arcPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final startAngle = angle1;
    var sweepAngle = angle2 - angle1;
    if (sweepAngle < 0) sweepAngle += 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // 각도 표시
    final inscribedAngle = _calculateInscribedAngle(pA, pB, pC);
    _drawText(canvas, 'A', pA + const Offset(10, 0), Colors.red);
    _drawText(canvas, 'B', pB + const Offset(10, 0), Colors.red);
    _drawText(canvas, '∠C = ${inscribedAngle.toStringAsFixed(1)}°', pC + const Offset(10, -15), Colors.green);
  }

  void _drawCentralAngle(Canvas canvas, double cx, double cy, double r) {
    final pA = Offset(cx + r * math.cos(angle1), cy + r * math.sin(angle1));
    final pB = Offset(cx + r * math.cos(angle2), cy + r * math.sin(angle2));
    final pC = Offset(cx + r * math.cos(angle3), cy + r * math.sin(angle3));
    final center = Offset(cx, cy);

    // 중심각
    canvas.drawLine(center, pA, Paint()..color = Colors.red..strokeWidth = 2);
    canvas.drawLine(center, pB, Paint()..color = Colors.red..strokeWidth = 2);

    // 원주각
    canvas.drawLine(pC, pA, Paint()..color = Colors.green..strokeWidth = 2);
    canvas.drawLine(pC, pB, Paint()..color = Colors.green..strokeWidth = 2);

    canvas.drawCircle(pA, 6, Paint()..color = Colors.orange);
    canvas.drawCircle(pB, 6, Paint()..color = Colors.orange);
    canvas.drawCircle(pC, 6, Paint()..color = Colors.green);

    var centralAngle = (angle2 - angle1).abs() * 180 / math.pi;
    if (centralAngle > 180) centralAngle = 360 - centralAngle;
    final inscribedAngle = _calculateInscribedAngle(pA, pB, pC);

    _drawText(canvas, '중심각 = ${centralAngle.toStringAsFixed(1)}°', Offset(cx - 50, cy + r + 20), Colors.red);
    _drawText(canvas, '원주각 = ${inscribedAngle.toStringAsFixed(1)}°', Offset(cx - 50, cy + r + 35), Colors.green);
  }

  void _drawTangent(Canvas canvas, double cx, double cy, double r) {
    final tangentPoint = Offset(cx + r * math.cos(angle1), cy + r * math.sin(angle1));

    // 반지름
    canvas.drawLine(
      Offset(cx, cy),
      tangentPoint,
      Paint()..color = Colors.blue..strokeWidth = 2,
    );

    // 접선 (반지름에 수직)
    final tangentDir = Offset(-math.sin(angle1), math.cos(angle1));
    final t1 = tangentPoint + tangentDir * 80;
    final t2 = tangentPoint - tangentDir * 80;

    canvas.drawLine(t1, t2, Paint()..color = Colors.green..strokeWidth = 2);
    canvas.drawCircle(tangentPoint, 6, Paint()..color = Colors.red);

    // 직각 표시
    final cornerSize = 15.0;
    final corner1 = tangentPoint + tangentDir * cornerSize;
    final radiusDir = Offset(math.cos(angle1), math.sin(angle1));
    final corner2 = tangentPoint - radiusDir * cornerSize;
    final corner3 = corner1 - radiusDir * cornerSize;

    final cornerPath = Path()
      ..moveTo(corner1.dx, corner1.dy)
      ..lineTo(corner3.dx, corner3.dy)
      ..lineTo(corner2.dx, corner2.dy);

    canvas.drawPath(cornerPath, Paint()..color = Colors.red..strokeWidth = 1.5..style = PaintingStyle.stroke);

    _drawText(canvas, '90°', tangentPoint + const Offset(20, -20), Colors.red);
  }

  void _drawChordTangent(Canvas canvas, double cx, double cy, double r) {
    final tangentPoint = Offset(cx + r, cy);
    final chordEnd = Offset(cx + r * math.cos(angle2), cy + r * math.sin(angle2));
    final inscribedPoint = Offset(cx + r * math.cos(angle3), cy + r * math.sin(angle3));

    // 접선
    canvas.drawLine(
      tangentPoint + const Offset(0, -80),
      tangentPoint + const Offset(0, 80),
      Paint()..color = Colors.green..strokeWidth = 2,
    );

    // 현
    canvas.drawLine(tangentPoint, chordEnd, Paint()..color = Colors.blue..strokeWidth = 2);

    // 원주각
    canvas.drawLine(inscribedPoint, tangentPoint, Paint()..color = Colors.orange..strokeWidth = 2);
    canvas.drawLine(inscribedPoint, chordEnd, Paint()..color = Colors.orange..strokeWidth = 2);

    canvas.drawCircle(tangentPoint, 6, Paint()..color = Colors.red);
    canvas.drawCircle(chordEnd, 6, Paint()..color = Colors.blue);
    canvas.drawCircle(inscribedPoint, 6, Paint()..color = Colors.orange);

    final inscribedAngle = _calculateInscribedAngle(tangentPoint, chordEnd, inscribedPoint);
    _drawText(canvas, '원주각 = ${inscribedAngle.toStringAsFixed(1)}°', Offset(cx - 60, cy + r + 20), Colors.orange);
  }

  double _calculateInscribedAngle(Offset a, Offset b, Offset vertex) {
    final va = a - vertex;
    final vb = b - vertex;
    final dot = va.dx * vb.dx + va.dy * vb.dy;
    final magA = math.sqrt(va.dx * va.dx + va.dy * va.dy);
    final magB = math.sqrt(vb.dx * vb.dx + vb.dy * vb.dy);
    final cosAngle = dot / (magA * magB);
    return math.acos(cosAngle.clamp(-1, 1)) * 180 / math.pi;
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
  bool shouldRepaint(covariant _CircleTheoremPainter oldDelegate) => true;
}
