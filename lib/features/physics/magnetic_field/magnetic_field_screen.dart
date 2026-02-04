import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Magnetic Field simulation: B = μ₀I/2πr
class MagneticFieldScreen extends StatefulWidget {
  const MagneticFieldScreen({super.key});

  @override
  State<MagneticFieldScreen> createState() => _MagneticFieldScreenState();
}

class _MagneticFieldScreenState extends State<MagneticFieldScreen> {
  double current = 5.0; // A
  double distance = 0.05; // m
  bool isKorean = true;

  static const double mu0 = 4 * math.pi * 1e-7;
  double get magneticField => mu0 * current / (2 * math.pi * distance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isKorean ? '전자기학' : 'ELECTROMAGNETISM', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '자기장' : 'Magnetic Field', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? '자기장' : 'Magnetic Field',
          formula: 'B = μ₀I/2πr',
          formulaDescription: isKorean ? '직선 도선 주위의 자기장(B)은 전류(I)에 비례하고 거리(r)에 반비례합니다.' : 'Magnetic field around a straight wire is proportional to current and inversely proportional to distance.',
          simulation: CustomPaint(painter: _MagneticFieldPainter(current: current, distance: distance, magneticField: magneticField, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '전류 (I)' : 'Current (I)', value: current, min: 0.1, max: 20, defaultValue: 5, formatValue: (v) => '${v.toStringAsFixed(1)} A', onChanged: (v) => setState(() => current = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '거리 (r)' : 'Distance (r)', value: distance * 100, min: 1, max: 20, defaultValue: 5, formatValue: (v) => '${v.toStringAsFixed(0)} cm', onChanged: (v) => setState(() => distance = v / 100)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Row(children: [
                Expanded(child: Column(children: [Text(isKorean ? '자기장 (B)' : 'B-Field', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(magneticField * 1e6).toStringAsFixed(2)} μT', style: TextStyle(color: AppColors.accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                Expanded(child: Column(children: [Text(isKorean ? '방향' : 'Direction', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text(current > 0 ? (isKorean ? '반시계 (⊙→)' : 'CCW (⊙→)') : (isKorean ? '시계 (⊗←)' : 'CW (⊗←)'), style: TextStyle(color: AppColors.accent2, fontSize: 12, fontWeight: FontWeight.w600))])),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MagneticFieldPainter extends CustomPainter {
  final double current, distance, magneticField;
  final bool isKorean;

  _MagneticFieldPainter({required this.current, required this.distance, required this.magneticField, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Wire (coming out of screen)
    canvas.drawCircle(Offset(centerX, centerY), 20, Paint()..color = AppColors.muted);
    canvas.drawCircle(Offset(centerX, centerY), 15, Paint()..color = AppColors.accent2);
    // Dot for current out of screen
    canvas.drawCircle(Offset(centerX, centerY), 5, Paint()..color = AppColors.ink);

    // Magnetic field lines (concentric circles)
    for (int i = 1; i <= 5; i++) {
      final radius = 30.0 + i * 25;
      final alpha = 0.5 - i * 0.08;
      canvas.drawCircle(Offset(centerX, centerY), radius, Paint()..color = AppColors.accent.withValues(alpha: alpha)..style = PaintingStyle.stroke..strokeWidth = 2);

      // Direction arrows (right-hand rule)
      for (int j = 0; j < 4; j++) {
        final angle = j * math.pi / 2 + math.pi / 4;
        final arrowX = centerX + radius * math.cos(angle);
        final arrowY = centerY + radius * math.sin(angle);
        final tangentAngle = angle + math.pi / 2 * (current > 0 ? 1 : -1);

        final arrowPath = Path()
          ..moveTo(arrowX, arrowY)
          ..lineTo(arrowX - 8 * math.cos(tangentAngle - 0.4), arrowY - 8 * math.sin(tangentAngle - 0.4))
          ..lineTo(arrowX - 8 * math.cos(tangentAngle + 0.4), arrowY - 8 * math.sin(tangentAngle + 0.4))
          ..close();
        canvas.drawPath(arrowPath, Paint()..color = AppColors.accent.withValues(alpha: alpha));
      }
    }

    // Distance indicator
    final testRadius = distance * 600;
    canvas.drawLine(Offset(centerX, centerY), Offset(centerX + testRadius, centerY), Paint()..color = AppColors.muted..strokeWidth = 1);
    canvas.drawCircle(Offset(centerX + testRadius, centerY), 5, Paint()..color = Colors.green);
    _drawText(canvas, 'r', Offset(centerX + testRadius / 2, centerY + 10), AppColors.muted, 10);

    // Labels
    _drawText(canvas, 'I', Offset(centerX - 5, centerY - 35), AppColors.accent2, 14);
    _drawText(canvas, 'B', Offset(centerX + 80, centerY - 60), AppColors.accent, 14);
    _drawText(canvas, 'B = ${(magneticField * 1e6).toStringAsFixed(2)} μT', Offset(centerX + testRadius + 10, centerY - 10), Colors.green, 10);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _MagneticFieldPainter oldDelegate) => true;
}
