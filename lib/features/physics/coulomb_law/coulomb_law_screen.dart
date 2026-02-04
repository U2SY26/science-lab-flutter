import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Coulomb's Law simulation: F = kq1q2/r²
class CoulombLawScreen extends StatefulWidget {
  const CoulombLawScreen({super.key});

  @override
  State<CoulombLawScreen> createState() => _CoulombLawScreenState();
}

class _CoulombLawScreenState extends State<CoulombLawScreen> {
  double charge1 = 1.0; // μC
  double charge2 = 1.0; // μC
  double distance = 0.1; // m
  bool isKorean = true;

  static const double k = 8.99e9; // N·m²/C²
  double get force => k * (charge1 * 1e-6) * (charge2 * 1e-6) / (distance * distance);
  bool get isRepulsive => charge1 * charge2 > 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isKorean ? '전자기학' : 'ELECTROMAGNETISM', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
            Text(isKorean ? '쿨롱의 법칙' : "Coulomb's Law", style: const TextStyle(color: AppColors.ink, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? '쿨롱의 법칙' : "Coulomb's Law",
          formula: 'F = kq₁q₂/r²',
          formulaDescription: isKorean
              ? '두 점전하 사이의 전기력은 전하량의 곱에 비례하고 거리의 제곱에 반비례합니다.'
              : 'Electric force between two point charges is proportional to product of charges and inversely proportional to square of distance.',
          simulation: CustomPaint(
            painter: _CoulombLawPainter(charge1: charge1, charge2: charge2, distance: distance, force: force, isRepulsive: isRepulsive, isKorean: isKorean),
            size: Size.infinite,
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimSlider(label: isKorean ? '전하 1 (q₁)' : 'Charge 1 (q₁)', value: charge1, min: -5, max: 5, defaultValue: 1, formatValue: (v) => '${v.toStringAsFixed(1)} μC', onChanged: (v) => setState(() => charge1 = v)),
              const SizedBox(height: 12),
              SimSlider(label: isKorean ? '전하 2 (q₂)' : 'Charge 2 (q₂)', value: charge2, min: -5, max: 5, defaultValue: 1, formatValue: (v) => '${v.toStringAsFixed(1)} μC', onChanged: (v) => setState(() => charge2 = v)),
              const SizedBox(height: 12),
              SimSlider(label: isKorean ? '거리 (r)' : 'Distance (r)', value: distance, min: 0.01, max: 0.5, step: 0.01, defaultValue: 0.1, formatValue: (v) => '${(v * 100).toStringAsFixed(0)} cm', onChanged: (v) => setState(() => distance = v)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: Column(children: [
                        Text(isKorean ? '힘 (F)' : 'Force (F)', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                        Text('${force.toStringAsFixed(2)} N', style: TextStyle(color: AppColors.accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                      ])),
                      Expanded(child: Column(children: [
                        Text(isKorean ? '힘의 종류' : 'Force Type', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                        Text(isRepulsive ? (isKorean ? '척력' : 'Repulsive') : (isKorean ? '인력' : 'Attractive'), style: TextStyle(color: isRepulsive ? Colors.red : Colors.blue, fontSize: 12, fontWeight: FontWeight.w600)),
                      ])),
                    ]),
                    const SizedBox(height: 8),
                    Text('F = 8.99×10⁹ × ${charge1.toStringAsFixed(1)}×10⁻⁶ × ${charge2.toStringAsFixed(1)}×10⁻⁶ / ${distance.toStringAsFixed(2)}²', style: const TextStyle(color: AppColors.accent, fontSize: 10, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoulombLawPainter extends CustomPainter {
  final double charge1, charge2, distance, force;
  final bool isRepulsive, isKorean;

  _CoulombLawPainter({required this.charge1, required this.charge2, required this.distance, required this.force, required this.isRepulsive, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerY = size.height / 2;
    final separation = distance * 400;
    final charge1X = size.width / 2 - separation / 2;
    final charge2X = size.width / 2 + separation / 2;

    // Draw electric field lines
    _drawFieldLines(canvas, Offset(charge1X, centerY), charge1);
    _drawFieldLines(canvas, Offset(charge2X, centerY), charge2);

    // Draw charges
    _drawCharge(canvas, Offset(charge1X, centerY), charge1, 'q₁');
    _drawCharge(canvas, Offset(charge2X, centerY), charge2, 'q₂');

    // Draw force arrows
    final arrowLength = math.min(force * 10, 50.0);
    if (isRepulsive) {
      _drawArrow(canvas, Offset(charge1X - 25, centerY), Offset(charge1X - 25 - arrowLength, centerY), Colors.red);
      _drawArrow(canvas, Offset(charge2X + 25, centerY), Offset(charge2X + 25 + arrowLength, centerY), Colors.red);
    } else {
      _drawArrow(canvas, Offset(charge1X + 25, centerY), Offset(charge1X + 25 + arrowLength, centerY), Colors.blue);
      _drawArrow(canvas, Offset(charge2X - 25, centerY), Offset(charge2X - 25 - arrowLength, centerY), Colors.blue);
    }

    // Distance line
    canvas.drawLine(Offset(charge1X, centerY + 50), Offset(charge2X, centerY + 50), Paint()..color = AppColors.muted..strokeWidth = 1);
    _drawText(canvas, 'r = ${(distance * 100).toStringAsFixed(0)} cm', Offset(size.width / 2 - 30, centerY + 55), AppColors.muted, 10);

    // Formula
    _drawText(canvas, 'F = kq₁q₂/r² = ${force.toStringAsFixed(2)} N', Offset(20, 20), AppColors.ink, 12);
  }

  void _drawCharge(Canvas canvas, Offset center, double charge, String label) {
    final color = charge > 0 ? Colors.red : Colors.blue;
    final radius = 20.0 + charge.abs() * 3;

    canvas.drawCircle(center, radius, Paint()..color = color.withValues(alpha: 0.3));
    canvas.drawCircle(center, radius, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);

    _drawText(canvas, charge > 0 ? '+' : '−', Offset(center.dx - 6, center.dy - 10), color, 18);
    _drawText(canvas, label, Offset(center.dx - 8, center.dy + radius + 5), AppColors.muted, 10);
  }

  void _drawFieldLines(Canvas canvas, Offset center, double charge) {
    final color = charge > 0 ? Colors.red.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2);
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final endX = center.dx + 60 * math.cos(angle);
      final endY = center.dy + 60 * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), Paint()..color = color..strokeWidth = 1);
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    canvas.drawLine(start, end, Paint()..color = color..strokeWidth = 3);
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final path = Path()..moveTo(end.dx, end.dy)..lineTo(end.dx - 10 * math.cos(angle - 0.4), end.dy - 10 * math.sin(angle - 0.4))..lineTo(end.dx - 10 * math.cos(angle + 0.4), end.dy - 10 * math.sin(angle + 0.4))..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _CoulombLawPainter oldDelegate) => true;
}
