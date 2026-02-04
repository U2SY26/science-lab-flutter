import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Total Internal Reflection simulation
class TotalInternalScreen extends StatefulWidget {
  const TotalInternalScreen({super.key});
  @override
  State<TotalInternalScreen> createState() => _TotalInternalScreenState();
}

class _TotalInternalScreenState extends State<TotalInternalScreen> {
  double incidentAngle = 30; // degrees
  double n1 = 1.5; // Glass (denser medium)
  double n2 = 1.0; // Air (less dense)
  bool isKorean = true;

  double get criticalAngle => math.asin(n2 / n1) * 180 / math.pi;
  bool get isTotalReflection => incidentAngle >= criticalAngle;
  double get refractedAngle {
    final sinRefracted = (n1 / n2) * math.sin(incidentAngle * math.pi / 180);
    return sinRefracted <= 1 ? math.asin(sinRefracted) * 180 / math.pi : 90;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isKorean ? '광학' : 'OPTICS', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '전반사' : 'Total Internal Reflection', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '광학' : 'Optics',
          title: isKorean ? '전반사' : 'Total Internal Reflection',
          formula: 'θc = arcsin(n₂/n₁)',
          formulaDescription: isKorean ? '임계각 이상에서 빛이 완전히 반사됩니다. 광섬유의 원리입니다.' : 'Light is completely reflected above the critical angle. This is the principle of optical fibers.',
          simulation: CustomPaint(painter: _TotalInternalPainter(incidentAngle: incidentAngle, n1: n1, n2: n2, criticalAngle: criticalAngle, refractedAngle: refractedAngle, isTotalReflection: isTotalReflection, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '입사각 (θ)' : 'Incident Angle (θ)', value: incidentAngle, min: 0, max: 89, defaultValue: 30, formatValue: (v) => '${v.toStringAsFixed(0)}°', onChanged: (v) => setState(() => incidentAngle = v)),
            const SizedBox(height: 16),
            Text(isKorean ? '밀한 매질 (아래)' : 'Denser Medium (bottom)', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 4),
            PresetGroup(presets: [
              PresetButton(label: '${isKorean ? "유리" : "Glass"} (1.50)', isSelected: n1 == 1.5, onPressed: () => setState(() => n1 = 1.5)),
              PresetButton(label: '${isKorean ? "다이아몬드" : "Diamond"} (2.42)', isSelected: n1 == 2.42, onPressed: () => setState(() => n1 = 2.42)),
              PresetButton(label: '${isKorean ? "물" : "Water"} (1.33)', isSelected: n1 == 1.33, onPressed: () => setState(() => n1 = 1.33)),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTotalReflection ? Colors.red.withValues(alpha: 0.1) : AppColors.simBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isTotalReflection ? Colors.red : AppColors.cardBorder),
              ),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text(isKorean ? '입사각' : 'θ incident', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${incidentAngle.toStringAsFixed(1)}°', style: TextStyle(color: Colors.yellow, fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text(isKorean ? '임계각' : 'θ critical', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${criticalAngle.toStringAsFixed(1)}°', style: TextStyle(color: Colors.orange, fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: isTotalReflection ? Colors.red : Colors.green, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    isTotalReflection
                      ? (isKorean ? '전반사 발생!' : 'Total Internal Reflection!')
                      : (isKorean ? '부분 굴절' : 'Partial Refraction'),
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isKorean ? '응용 분야:' : 'Applications:', style: TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(isKorean ? '• 광섬유 통신\n• 다이아몬드의 광채\n• 프리즘 (망원경, 쌍안경)' : '• Fiber optic communication\n• Diamond brilliance\n• Prisms (telescopes, binoculars)', style: TextStyle(color: AppColors.muted, fontSize: 10, height: 1.4)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TotalInternalPainter extends CustomPainter {
  final double incidentAngle, n1, n2, criticalAngle, refractedAngle;
  final bool isTotalReflection, isKorean;

  _TotalInternalPainter({required this.incidentAngle, required this.n1, required this.n2, required this.criticalAngle, required this.refractedAngle, required this.isTotalReflection, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.45;

    // Less dense medium (top - air)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, centerY), Paint()..color = Colors.lightBlue.withValues(alpha: 0.1));

    // Denser medium (bottom - glass/water)
    canvas.drawRect(Rect.fromLTWH(0, centerY, size.width, size.height - centerY), Paint()..color = Colors.blue.withValues(alpha: n1 * 0.25));

    // Interface
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), Paint()..color = AppColors.muted..strokeWidth = 2);

    // Normal line
    for (double y = 30; y < size.height - 30; y += 8) {
      canvas.drawLine(Offset(centerX, y), Offset(centerX, y + 4), Paint()..color = AppColors.muted.withValues(alpha: 0.5)..strokeWidth = 1);
    }

    final incidentRad = incidentAngle * math.pi / 180;
    final rayLength = 100.0;

    // Incident ray (from below, going up)
    final incidentStartX = centerX - rayLength * math.sin(incidentRad);
    final incidentStartY = centerY + rayLength * math.cos(incidentRad);
    canvas.drawLine(Offset(incidentStartX, incidentStartY), Offset(centerX, centerY), Paint()..color = Colors.yellow..strokeWidth = 3);
    _drawArrow(canvas, Offset(incidentStartX, incidentStartY), Offset(centerX, centerY), Colors.yellow);

    // Critical angle indicator
    final criticalRad = criticalAngle * math.pi / 180;
    final criticalEndX = centerX + 80 * math.sin(criticalRad);
    final criticalEndY = centerY + 80 * math.cos(criticalRad);
    canvas.drawLine(Offset(centerX, centerY), Offset(criticalEndX, criticalEndY), Paint()..color = Colors.orange.withValues(alpha: 0.5)..strokeWidth = 1..style = PaintingStyle.stroke);

    // Angle arc for incident
    canvas.drawArc(Rect.fromCenter(center: Offset(centerX, centerY), width: 50, height: 50), math.pi / 2, incidentRad, false, Paint()..color = Colors.yellow.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Critical angle arc
    canvas.drawArc(Rect.fromCenter(center: Offset(centerX, centerY), width: 70, height: 70), math.pi / 2, criticalRad, false, Paint()..color = Colors.orange.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2);
    _drawText(canvas, 'θc', Offset(centerX + 45, centerY + 35), Colors.orange, 10);

    if (isTotalReflection) {
      // Total internal reflection - reflected ray
      final reflectedEndX = centerX + rayLength * math.sin(incidentRad);
      final reflectedEndY = centerY + rayLength * math.cos(incidentRad);
      canvas.drawLine(Offset(centerX, centerY), Offset(reflectedEndX, reflectedEndY), Paint()..color = Colors.red..strokeWidth = 3);
      _drawArrow(canvas, Offset(centerX, centerY), Offset(reflectedEndX, reflectedEndY), Colors.red);

      // Highlight the interface
      canvas.drawLine(Offset(centerX - 50, centerY), Offset(centerX + 50, centerY), Paint()..color = Colors.red.withValues(alpha: 0.5)..strokeWidth = 4);

      _drawText(canvas, isKorean ? '전반사' : 'TIR', Offset(reflectedEndX + 5, reflectedEndY - 10), Colors.red, 11);
    } else {
      // Partial refraction
      final refractedRad = refractedAngle * math.pi / 180;
      final refractedEndX = centerX + rayLength * math.sin(refractedRad);
      final refractedEndY = centerY - rayLength * math.cos(refractedRad);
      canvas.drawLine(Offset(centerX, centerY), Offset(refractedEndX, refractedEndY), Paint()..color = Colors.blue..strokeWidth = 3);
      _drawArrow(canvas, Offset(centerX, centerY), Offset(refractedEndX, refractedEndY), Colors.blue);

      // Partial reflection
      final partialReflectedX = centerX + rayLength * 0.4 * math.sin(incidentRad);
      final partialReflectedY = centerY + rayLength * 0.4 * math.cos(incidentRad);
      canvas.drawLine(Offset(centerX, centerY), Offset(partialReflectedX, partialReflectedY), Paint()..color = Colors.yellow.withValues(alpha: 0.4)..strokeWidth = 2);

      _drawText(canvas, isKorean ? '굴절광' : 'Refracted', Offset(refractedEndX + 5, refractedEndY - 10), Colors.blue, 10);
    }

    // Medium labels
    _drawText(canvas, 'n₂ = ${n2.toStringAsFixed(2)} (${isKorean ? "공기" : "Air"})', Offset(20, 20), AppColors.ink, 11);
    _drawText(canvas, 'n₁ = ${n1.toStringAsFixed(2)}', Offset(20, centerY + 15), AppColors.ink, 11);

    // Optical fiber illustration (bottom)
    final fiberY = size.height * 0.85;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(40, fiberY - 15, size.width - 80, 30), const Radius.circular(15)), Paint()..color = Colors.blue.withValues(alpha: 0.3));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(45, fiberY - 10, size.width - 90, 20), const Radius.circular(10)), Paint()..color = Colors.cyan.withValues(alpha: 0.5));

    // Light bouncing in fiber
    double x = 50;
    double y = fiberY;
    double dx = 1;
    double dy = -0.3;
    final fiberPath = Path()..moveTo(x, y);
    for (int i = 0; i < 8; i++) {
      x += dx * 35;
      y += dy * 30;
      if (y < fiberY - 8 || y > fiberY + 8) dy = -dy;
      fiberPath.lineTo(x, y);
    }
    canvas.drawPath(fiberPath, Paint()..color = Colors.yellow..style = PaintingStyle.stroke..strokeWidth = 2);

    _drawText(canvas, isKorean ? '광섬유' : 'Optical Fiber', Offset(centerX - 25, fiberY + 20), AppColors.muted, 10);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final arrowLength = 10.0;
    canvas.drawLine(to, Offset(to.dx - arrowLength * math.cos(angle - 0.4), to.dy - arrowLength * math.sin(angle - 0.4)), Paint()..color = color..strokeWidth = 3);
    canvas.drawLine(to, Offset(to.dx - arrowLength * math.cos(angle + 0.4), to.dy - arrowLength * math.sin(angle + 0.4)), Paint()..color = color..strokeWidth = 3);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _TotalInternalPainter oldDelegate) => true;
}
