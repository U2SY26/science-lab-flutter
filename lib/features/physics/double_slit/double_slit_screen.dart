import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Double Slit Interference simulation
class DoubleSlitPhysicsScreen extends StatefulWidget {
  const DoubleSlitPhysicsScreen({super.key});
  @override
  State<DoubleSlitPhysicsScreen> createState() => _DoubleSlitPhysicsScreenState();
}

class _DoubleSlitPhysicsScreenState extends State<DoubleSlitPhysicsScreen> {
  double slitSeparation = 0.5; // mm
  double wavelength = 550; // nm
  double screenDistance = 1000; // mm
  bool isKorean = true;

  double get fringeSpacing => (wavelength * 1e-6 * screenDistance) / slitSeparation; // mm
  double get firstBrightAngle => math.asin(wavelength * 1e-6 / slitSeparation);

  Color get lightColor {
    if (wavelength < 450) return Colors.purple;
    if (wavelength < 495) return Colors.blue;
    if (wavelength < 570) return Colors.green;
    if (wavelength < 590) return Colors.yellow;
    if (wavelength < 620) return Colors.orange;
    return Colors.red;
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
          Text(isKorean ? '이중 슬릿 간섭' : 'Double Slit Interference', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '광학' : 'Optics',
          title: isKorean ? '이중 슬릿 간섭' : 'Double Slit Interference',
          formula: 'd sinθ = mλ',
          formulaDescription: isKorean ? '영의 이중 슬릿 실험: 빛의 파동성을 증명하는 간섭 무늬를 관찰합니다.' : "Young's double slit experiment: Observe interference fringes demonstrating wave nature of light.",
          simulation: CustomPaint(painter: _DoubleSlitPainter(slitSeparation: slitSeparation, wavelength: wavelength, screenDistance: screenDistance, lightColor: lightColor, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '슬릿 간격 (d)' : 'Slit Separation (d)', value: slitSeparation, min: 0.1, max: 1.0, defaultValue: 0.5, formatValue: (v) => '${v.toStringAsFixed(2)} mm', onChanged: (v) => setState(() => slitSeparation = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '파장 (λ)' : 'Wavelength (λ)', value: wavelength, min: 400, max: 700, defaultValue: 550, formatValue: (v) => '${v.toStringAsFixed(0)} nm', onChanged: (v) => setState(() => wavelength = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '스크린 거리 (L)' : 'Screen Distance (L)', value: screenDistance, min: 500, max: 2000, defaultValue: 1000, formatValue: (v) => '${v.toStringAsFixed(0)} mm', onChanged: (v) => setState(() => screenDistance = v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text(isKorean ? '무늬 간격 (Δy)' : 'Fringe Spacing (Δy)', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${fringeSpacing.toStringAsFixed(3)} mm', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text(isKorean ? '첫 번째 극대 각도' : '1st Maximum Angle', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(firstBrightAngle * 180 / math.pi).toStringAsFixed(3)}°', style: TextStyle(color: AppColors.accent2, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text(isKorean ? '빛 색상: ' : 'Light Color: ', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                  Container(width: 20, height: 20, decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.cardBorder))),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DoubleSlitPainter extends CustomPainter {
  final double slitSeparation, wavelength, screenDistance;
  final Color lightColor;
  final bool isKorean;

  _DoubleSlitPainter({required this.slitSeparation, required this.wavelength, required this.screenDistance, required this.lightColor, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final slitX = 70.0;
    final screenX = size.width - 30;
    final centerY = size.height * 0.35;
    final slitOffset = 15.0; // Visual separation

    // Slit barrier
    canvas.drawRect(Rect.fromLTWH(slitX - 5, 20, 10, centerY - slitOffset - 15), Paint()..color = Colors.grey[700]!);
    canvas.drawRect(Rect.fromLTWH(slitX - 5, centerY - slitOffset + 5, 10, 2 * slitOffset - 10), Paint()..color = Colors.grey[700]!);
    canvas.drawRect(Rect.fromLTWH(slitX - 5, centerY + slitOffset + 5, 10, size.height * 0.35), Paint()..color = Colors.grey[700]!);

    // Slit openings
    canvas.drawLine(Offset(slitX, centerY - slitOffset - 5), Offset(slitX, centerY - slitOffset + 5), Paint()..color = Colors.white..strokeWidth = 3);
    canvas.drawLine(Offset(slitX, centerY + slitOffset - 5), Offset(slitX, centerY + slitOffset + 5), Paint()..color = Colors.white..strokeWidth = 3);

    // Slit separation label
    _drawText(canvas, 'd', Offset(slitX + 12, centerY - 5), AppColors.muted, 10);

    // Incident plane wave
    for (double y = 30; y < size.height * 0.5; y += 12) {
      canvas.drawLine(Offset(20, y), Offset(slitX - 8, y), Paint()..color = lightColor.withValues(alpha: 0.4)..strokeWidth = 2);
    }

    // Interference pattern on screen
    final patternHeight = size.height * 0.5;
    final patternY = centerY - patternHeight / 2;

    for (double y = 0; y < patternHeight; y += 1) {
      final yOffset = y - patternHeight / 2;
      final pathDiff = slitSeparation * yOffset / (screenX - slitX) * 10; // Scaled
      final phase = 2 * math.pi * pathDiff / (wavelength * 1e-6);
      final intensity = math.pow(math.cos(phase / 2), 2);

      canvas.drawLine(
        Offset(screenX, patternY + y),
        Offset(screenX + 15, patternY + y),
        Paint()..color = lightColor.withValues(alpha: intensity * 0.9)..strokeWidth = 1,
      );
    }

    // Screen
    canvas.drawLine(Offset(screenX, 20), Offset(screenX, size.height * 0.55), Paint()..color = Colors.grey[600]!..strokeWidth = 3);

    // Diffracted rays from both slits (simplified)
    for (int m = -3; m <= 3; m++) {
      final angle = m * 0.08;
      final endY = centerY + (screenX - slitX) * math.tan(angle);
      if (endY > 30 && endY < size.height * 0.55) {
        canvas.drawLine(Offset(slitX, centerY - slitOffset), Offset(screenX, endY), Paint()..color = lightColor.withValues(alpha: 0.2)..strokeWidth = 1);
        canvas.drawLine(Offset(slitX, centerY + slitOffset), Offset(screenX, endY), Paint()..color = lightColor.withValues(alpha: 0.2)..strokeWidth = 1);
      }
    }

    // Intensity graph
    final graphY = size.height * 0.78;
    final graphWidth = size.width - 60;
    final graphHeight = 40.0;

    canvas.drawLine(Offset(30, graphY), Offset(30 + graphWidth, graphY), Paint()..color = AppColors.muted..strokeWidth = 1);
    canvas.drawLine(Offset(30 + graphWidth / 2, graphY - graphHeight), Offset(30 + graphWidth / 2, graphY + 5), Paint()..color = AppColors.muted..strokeWidth = 1);

    final intensityPath = Path();
    for (double x = 0; x <= graphWidth; x += 1) {
      final xOffset = x - graphWidth / 2;
      final phase = math.pi * xOffset / 15; // Scaled
      final intensity = math.pow(math.cos(phase), 2);
      final plotY = graphY - graphHeight * intensity;
      if (x == 0) {
        intensityPath.moveTo(30 + x, plotY);
      } else {
        intensityPath.lineTo(30 + x, plotY);
      }
    }
    canvas.drawPath(intensityPath, Paint()..color = lightColor..style = PaintingStyle.stroke..strokeWidth = 2);

    _drawText(canvas, isKorean ? '간섭 무늬' : 'Interference Pattern', Offset(30 + graphWidth / 2 - 40, graphY + 10), AppColors.muted, 10);

    // Order labels on pattern
    _drawText(canvas, 'm=0', Offset(30 + graphWidth / 2 - 12, graphY - graphHeight - 12), AppColors.accent, 9);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _DoubleSlitPainter oldDelegate) => true;
}
