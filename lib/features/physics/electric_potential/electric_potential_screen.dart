import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Electric Potential simulation: V = kq/r
class ElectricPotentialScreen extends StatefulWidget {
  const ElectricPotentialScreen({super.key});

  @override
  State<ElectricPotentialScreen> createState() => _ElectricPotentialScreenState();
}

class _ElectricPotentialScreenState extends State<ElectricPotentialScreen> {
  double charge = 2.0; // μC
  double distance = 0.1; // m
  bool isKorean = true;

  static const double k = 8.99e9;
  double get potential => k * (charge * 1e-6) / distance;
  double get electricField => k * (charge * 1e-6).abs() / (distance * distance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isKorean ? '전자기학' : 'ELECTROMAGNETISM', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '전위' : 'Electric Potential', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? '전위' : 'Electric Potential',
          formula: 'V = kq/r',
          formulaDescription: isKorean ? '전위(V)는 단위 전하당 전기적 위치에너지입니다.' : 'Electric potential (V) is electrical potential energy per unit charge.',
          simulation: CustomPaint(painter: _ElectricPotentialPainter(charge: charge, distance: distance, potential: potential, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '전하 (q)' : 'Charge (q)', value: charge, min: -5, max: 5, defaultValue: 2, formatValue: (v) => '${v.toStringAsFixed(1)} μC', onChanged: (v) => setState(() => charge = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '거리 (r)' : 'Distance (r)', value: distance, min: 0.02, max: 0.5, step: 0.01, defaultValue: 0.1, formatValue: (v) => '${(v * 100).toStringAsFixed(0)} cm', onChanged: (v) => setState(() => distance = v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text(isKorean ? '전위 (V)' : 'Potential', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(potential / 1000).toStringAsFixed(1)} kV', style: TextStyle(color: AppColors.accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text(isKorean ? '전기장 (E)' : 'E-Field', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(electricField / 1000).toStringAsFixed(1)} kV/m', style: TextStyle(color: AppColors.accent2, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ElectricPotentialPainter extends CustomPainter {
  final double charge, distance, potential;
  final bool isKorean;

  _ElectricPotentialPainter({required this.charge, required this.distance, required this.potential, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final chargeColor = charge > 0 ? Colors.red : Colors.blue;

    // Equipotential lines
    for (int i = 1; i <= 5; i++) {
      final radius = i * 30.0;
      canvas.drawCircle(Offset(centerX, centerY), radius, Paint()..color = chargeColor.withValues(alpha: 0.3 - i * 0.05)..style = PaintingStyle.stroke..strokeWidth = 1);
    }

    // Electric field lines
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final endX = centerX + 120 * math.cos(angle);
      final endY = centerY + 120 * math.sin(angle);
      canvas.drawLine(Offset(centerX, centerY), Offset(endX, endY), Paint()..color = AppColors.muted.withValues(alpha: 0.3)..strokeWidth = 1);
    }

    // Charge
    canvas.drawCircle(Offset(centerX, centerY), 25, Paint()..color = chargeColor.withValues(alpha: 0.3));
    canvas.drawCircle(Offset(centerX, centerY), 25, Paint()..color = chargeColor..style = PaintingStyle.stroke..strokeWidth = 2);
    _drawText(canvas, charge > 0 ? '+' : '−', Offset(centerX - 6, centerY - 10), chargeColor, 18);

    // Distance marker
    final testPointX = centerX + distance * 300;
    canvas.drawLine(Offset(centerX, centerY + 40), Offset(testPointX, centerY + 40), Paint()..color = AppColors.muted..strokeWidth = 1);
    canvas.drawCircle(Offset(testPointX, centerY), 5, Paint()..color = AppColors.accent);
    _drawText(canvas, 'r', Offset((centerX + testPointX) / 2 - 5, centerY + 45), AppColors.muted, 12);
    _drawText(canvas, 'V = ${(potential / 1000).toStringAsFixed(1)} kV', Offset(testPointX + 10, centerY - 10), AppColors.accent, 11);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _ElectricPotentialPainter oldDelegate) => true;
}
