import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Light Refraction simulation: Snell's Law
class RefractionScreen extends StatefulWidget {
  const RefractionScreen({super.key});
  @override
  State<RefractionScreen> createState() => _RefractionScreenState();
}

class _RefractionScreenState extends State<RefractionScreen> {
  double incidentAngle = 45; // degrees
  double n1 = 1.0; // Air
  double n2 = 1.5; // Glass
  bool isKorean = true;

  String get medium1Name => n1 == 1.0 ? (isKorean ? '공기' : 'Air') : n1 == 1.33 ? (isKorean ? '물' : 'Water') : (isKorean ? '유리' : 'Glass');
  String get medium2Name => n2 == 1.0 ? (isKorean ? '공기' : 'Air') : n2 == 1.33 ? (isKorean ? '물' : 'Water') : (isKorean ? '유리' : 'Glass');

  double get incidentRad => incidentAngle * math.pi / 180;
  double get sinRefracted => (n1 / n2) * math.sin(incidentRad);
  double get refractedAngle => sinRefracted.abs() <= 1 ? math.asin(sinRefracted) * 180 / math.pi : 90;
  double get criticalAngle => n1 > n2 ? math.asin(n2 / n1) * 180 / math.pi : 90;
  bool get isTotalReflection => n1 > n2 && incidentAngle >= criticalAngle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isKorean ? '광학' : 'OPTICS', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '빛의 굴절' : 'Light Refraction', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '광학' : 'Optics',
          title: isKorean ? '빛의 굴절' : 'Light Refraction',
          formula: 'n₁sinθ₁ = n₂sinθ₂',
          formulaDescription: isKorean ? '스넬의 법칙: 빛이 매질 경계면에서 굴절됩니다.' : "Snell's Law: Light bends at the boundary between media.",
          simulation: CustomPaint(painter: _RefractionPainter(incidentAngle: incidentAngle, n1: n1, n2: n2, refractedAngle: refractedAngle, isTotalReflection: isTotalReflection, criticalAngle: criticalAngle, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '입사각 (θ₁)' : 'Incident Angle (θ₁)', value: incidentAngle, min: 0, max: 89, defaultValue: 45, formatValue: (v) => '${v.toStringAsFixed(0)}°', onChanged: (v) => setState(() => incidentAngle = v)),
            const SizedBox(height: 16),
            Text(isKorean ? '매질 1 (위)' : 'Medium 1 (top)', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 4),
            PresetGroup(presets: [
              PresetButton(label: '${isKorean ? "공기" : "Air"} (1.00)', isSelected: n1 == 1.0, onPressed: () => setState(() => n1 = 1.0)),
              PresetButton(label: '${isKorean ? "물" : "Water"} (1.33)', isSelected: n1 == 1.33, onPressed: () => setState(() => n1 = 1.33)),
              PresetButton(label: '${isKorean ? "유리" : "Glass"} (1.50)', isSelected: n1 == 1.5, onPressed: () => setState(() => n1 = 1.5)),
            ]),
            const SizedBox(height: 12),
            Text(isKorean ? '매질 2 (아래)' : 'Medium 2 (bottom)', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 4),
            PresetGroup(presets: [
              PresetButton(label: '${isKorean ? "공기" : "Air"} (1.00)', isSelected: n2 == 1.0, onPressed: () => setState(() => n2 = 1.0)),
              PresetButton(label: '${isKorean ? "물" : "Water"} (1.33)', isSelected: n2 == 1.33, onPressed: () => setState(() => n2 = 1.33)),
              PresetButton(label: '${isKorean ? "유리" : "Glass"} (1.50)', isSelected: n2 == 1.5, onPressed: () => setState(() => n2 = 1.5)),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text('θ₁', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${incidentAngle.toStringAsFixed(1)}°', style: TextStyle(color: Colors.yellow, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('θ₂', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text(isTotalReflection ? 'TIR' : '${refractedAngle.toStringAsFixed(1)}°', style: TextStyle(color: isTotalReflection ? Colors.red : Colors.blue, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('θc', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text(n1 > n2 ? '${criticalAngle.toStringAsFixed(1)}°' : 'N/A', style: TextStyle(color: Colors.orange, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
                if (isTotalReflection) ...[
                  const SizedBox(height: 8),
                  Text(isKorean ? '⚠ 전반사 발생!' : '⚠ Total Internal Reflection!', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RefractionPainter extends CustomPainter {
  final double incidentAngle, n1, n2, refractedAngle, criticalAngle;
  final bool isTotalReflection, isKorean;

  _RefractionPainter({required this.incidentAngle, required this.n1, required this.n2, required this.refractedAngle, required this.isTotalReflection, required this.criticalAngle, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Medium 1 (top)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, centerY), Paint()..color = Colors.lightBlue.withValues(alpha: 0.2));

    // Medium 2 (bottom)
    canvas.drawRect(Rect.fromLTWH(0, centerY, size.width, centerY), Paint()..color = Colors.blue.withValues(alpha: n2 * 0.3));

    // Interface line
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), Paint()..color = AppColors.muted..strokeWidth = 2);

    // Normal line (dashed)
    for (double y = 20; y < size.height - 20; y += 10) {
      canvas.drawLine(Offset(centerX, y), Offset(centerX, y + 5), Paint()..color = AppColors.muted.withValues(alpha: 0.5)..strokeWidth = 1);
    }
    _drawText(canvas, isKorean ? '법선' : 'Normal', Offset(centerX + 5, 25), AppColors.muted, 10);

    // Incident ray
    final incidentRad = incidentAngle * math.pi / 180;
    final rayLength = 120.0;
    final incidentStartX = centerX - rayLength * math.sin(incidentRad);
    final incidentStartY = centerY - rayLength * math.cos(incidentRad);
    canvas.drawLine(Offset(incidentStartX, incidentStartY), Offset(centerX, centerY), Paint()..color = Colors.yellow..strokeWidth = 3);
    _drawArrow(canvas, Offset(incidentStartX, incidentStartY), Offset(centerX, centerY), Colors.yellow);

    // Incident angle arc
    canvas.drawArc(Rect.fromCenter(center: Offset(centerX, centerY), width: 60, height: 60), -math.pi / 2, -incidentRad, false, Paint()..color = Colors.yellow.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
    _drawText(canvas, 'θ₁', Offset(centerX - 35, centerY - 45), Colors.yellow, 12);

    if (isTotalReflection) {
      // Reflected ray (total internal reflection)
      final reflectedEndX = centerX + rayLength * math.sin(incidentRad);
      final reflectedEndY = centerY - rayLength * math.cos(incidentRad);
      canvas.drawLine(Offset(centerX, centerY), Offset(reflectedEndX, reflectedEndY), Paint()..color = Colors.red..strokeWidth = 3);
      _drawArrow(canvas, Offset(centerX, centerY), Offset(reflectedEndX, reflectedEndY), Colors.red);
      _drawText(canvas, isKorean ? '전반사' : 'TIR', Offset(reflectedEndX - 20, reflectedEndY + 10), Colors.red, 11);
    } else {
      // Refracted ray
      final refractedRad = refractedAngle * math.pi / 180;
      final refractedEndX = centerX + rayLength * math.sin(refractedRad);
      final refractedEndY = centerY + rayLength * math.cos(refractedRad);
      canvas.drawLine(Offset(centerX, centerY), Offset(refractedEndX, refractedEndY), Paint()..color = Colors.blue..strokeWidth = 3);
      _drawArrow(canvas, Offset(centerX, centerY), Offset(refractedEndX, refractedEndY), Colors.blue);

      // Refracted angle arc
      canvas.drawArc(Rect.fromCenter(center: Offset(centerX, centerY), width: 50, height: 50), math.pi / 2, -refractedRad, false, Paint()..color = Colors.blue.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
      _drawText(canvas, 'θ₂', Offset(centerX + 25, centerY + 30), Colors.blue, 12);

      // Partial reflection
      final reflectedEndX = centerX + rayLength * 0.3 * math.sin(incidentRad);
      final reflectedEndY = centerY - rayLength * 0.3 * math.cos(incidentRad);
      canvas.drawLine(Offset(centerX, centerY), Offset(reflectedEndX, reflectedEndY), Paint()..color = Colors.yellow.withValues(alpha: 0.4)..strokeWidth = 2);
    }

    // Medium labels
    _drawText(canvas, 'n₁ = ${n1.toStringAsFixed(2)}', Offset(20, 30), AppColors.ink, 12);
    _drawText(canvas, 'n₂ = ${n2.toStringAsFixed(2)}', Offset(20, centerY + 20), AppColors.ink, 12);
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
  bool shouldRepaint(covariant _RefractionPainter oldDelegate) => true;
}
