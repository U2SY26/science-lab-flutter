import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Light Polarization simulation (Malus's Law)
class PolarizationScreen extends StatefulWidget {
  const PolarizationScreen({super.key});
  @override
  State<PolarizationScreen> createState() => _PolarizationScreenState();
}

class _PolarizationScreenState extends State<PolarizationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double analyzerAngle = 0; // degrees
  double time = 0;
  bool isRunning = true;
  bool isKorean = true;

  double get transmittedIntensity => math.pow(math.cos(analyzerAngle * math.pi / 180), 2).toDouble();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(() { if (isRunning) setState(() => time += 0.05); })..repeat();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isKorean ? '광학' : 'OPTICS', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '빛의 편광' : 'Light Polarization', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '광학' : 'Optics',
          title: isKorean ? '빛의 편광' : 'Light Polarization',
          formula: 'I = I₀ cos²θ',
          formulaDescription: isKorean ? '말뤼스의 법칙: 편광판을 통과하는 빛의 세기는 각도의 코사인 제곱에 비례합니다.' : "Malus's Law: Intensity through polarizer is proportional to cos² of the angle.",
          simulation: CustomPaint(painter: _PolarizationPainter(analyzerAngle: analyzerAngle, transmittedIntensity: transmittedIntensity, time: time, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '분석기 각도 (θ)' : 'Analyzer Angle (θ)', value: analyzerAngle, min: 0, max: 180, defaultValue: 0, formatValue: (v) => '${v.toStringAsFixed(0)}°', onChanged: (v) => setState(() => analyzerAngle = v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text('θ', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${analyzerAngle.toStringAsFixed(0)}°', style: TextStyle(color: AppColors.accent, fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('cos²θ', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text(transmittedIntensity.toStringAsFixed(3), style: TextStyle(color: AppColors.accent2, fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('I/I₀', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(transmittedIntensity * 100).toStringAsFixed(0)}%', style: TextStyle(color: Colors.yellow, fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            SimButtonGroup(expanded: true, buttons: [
              SimButton(label: '0°', onPressed: () => setState(() => analyzerAngle = 0)),
              SimButton(label: '45°', onPressed: () => setState(() => analyzerAngle = 45)),
              SimButton(label: '90°', onPressed: () => setState(() => analyzerAngle = 90)),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isKorean ? '특수 각도:' : 'Special Angles:', style: TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(isKorean ? '• 0°: 최대 투과 (100%)\n• 45°: 절반 투과 (50%)\n• 90°: 완전 차단 (0%)' : '• 0°: Maximum transmission (100%)\n• 45°: Half transmission (50%)\n• 90°: Complete blocking (0%)', style: TextStyle(color: AppColors.muted, fontSize: 10, height: 1.4)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PolarizationPainter extends CustomPainter {
  final double analyzerAngle, transmittedIntensity, time;
  final bool isKorean;

  _PolarizationPainter({required this.analyzerAngle, required this.transmittedIntensity, required this.time, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerY = size.height * 0.35;
    final polarizerX = size.width * 0.3;
    final analyzerX = size.width * 0.6;

    // Light source
    canvas.drawCircle(Offset(30, centerY), 15, Paint()..color = Colors.yellow);
    _drawText(canvas, isKorean ? '광원' : 'Source', Offset(20, centerY + 25), AppColors.muted, 10);

    // Unpolarized light waves (multiple directions)
    for (double angle = 0; angle < math.pi; angle += math.pi / 4) {
      final amplitude = 10.0;
      for (double x = 50; x < polarizerX - 20; x += 3) {
        final y = centerY + amplitude * math.sin(x * 0.3 + time) * math.sin(angle);
        canvas.drawCircle(Offset(x, y), 1.5, Paint()..color = Colors.yellow.withValues(alpha: 0.5));
      }
    }

    // Polarizer (vertical)
    _drawPolarizer(canvas, polarizerX, centerY, 0, isKorean ? '편광자' : 'Polarizer');

    // Polarized light (vertical only)
    for (double x = polarizerX + 20; x < analyzerX - 20; x += 3) {
      final y = centerY + 15 * math.sin(x * 0.3 + time);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.yellow);
    }

    // Analyzer (rotated)
    _drawPolarizer(canvas, analyzerX, centerY, analyzerAngle, isKorean ? '분석기' : 'Analyzer');

    // Transmitted light
    if (transmittedIntensity > 0.01) {
      final amplitude = 15.0 * math.sqrt(transmittedIntensity);
      for (double x = analyzerX + 20; x < size.width - 30; x += 3) {
        final baseY = centerY + amplitude * math.sin(x * 0.3 + time);
        // Projected onto analyzer axis
        final projectedY = centerY + (baseY - centerY) * math.cos(analyzerAngle * math.pi / 180);
        canvas.drawCircle(Offset(x, projectedY), 2, Paint()..color = Colors.yellow.withValues(alpha: transmittedIntensity));
      }
    }

    // Detector/screen
    final screenX = size.width - 20;
    canvas.drawRect(Rect.fromCenter(center: Offset(screenX, centerY), width: 10, height: 60), Paint()..color = Colors.yellow.withValues(alpha: transmittedIntensity));
    canvas.drawRect(Rect.fromCenter(center: Offset(screenX, centerY), width: 10, height: 60), Paint()..color = Colors.grey[600]!..style = PaintingStyle.stroke..strokeWidth = 2);
    _drawText(canvas, '${(transmittedIntensity * 100).toStringAsFixed(0)}%', Offset(screenX - 15, centerY + 40), Colors.yellow, 11);

    // Malus's Law graph
    final graphY = size.height * 0.75;
    final graphWidth = size.width - 60;
    final graphHeight = 50.0;

    canvas.drawLine(Offset(30, graphY), Offset(30 + graphWidth, graphY), Paint()..color = AppColors.muted..strokeWidth = 1);
    canvas.drawLine(Offset(30, graphY - graphHeight), Offset(30, graphY + 5), Paint()..color = AppColors.muted..strokeWidth = 1);

    // cos²θ curve
    final curvePath = Path();
    for (double x = 0; x <= graphWidth; x += 2) {
      final theta = x / graphWidth * math.pi; // 0 to 180 degrees
      final intensity = math.pow(math.cos(theta), 2);
      final plotY = graphY - graphHeight * intensity;
      if (x == 0) {
        curvePath.moveTo(30 + x, plotY);
      } else {
        curvePath.lineTo(30 + x, plotY);
      }
    }
    canvas.drawPath(curvePath, Paint()..color = Colors.cyan..style = PaintingStyle.stroke..strokeWidth = 2);

    // Current angle marker
    final markerX = 30 + (analyzerAngle / 180) * graphWidth;
    canvas.drawCircle(Offset(markerX, graphY - graphHeight * transmittedIntensity), 5, Paint()..color = Colors.yellow);
    canvas.drawLine(Offset(markerX, graphY), Offset(markerX, graphY - graphHeight * transmittedIntensity), Paint()..color = Colors.yellow.withValues(alpha: 0.5)..strokeWidth = 1);

    _drawText(canvas, '0°', Offset(25, graphY + 10), AppColors.muted, 9);
    _drawText(canvas, '90°', Offset(30 + graphWidth / 2 - 10, graphY + 10), AppColors.muted, 9);
    _drawText(canvas, '180°', Offset(30 + graphWidth - 15, graphY + 10), AppColors.muted, 9);
    _drawText(canvas, 'I/I₀', Offset(15, graphY - graphHeight - 10), AppColors.muted, 9);
  }

  void _drawPolarizer(Canvas canvas, double x, double y, double angle, String label) {
    canvas.save();
    canvas.translate(x, y);

    // Polarizer frame
    canvas.drawCircle(Offset.zero, 35, Paint()..color = Colors.grey[700]!..style = PaintingStyle.stroke..strokeWidth = 3);

    // Polarization direction lines
    canvas.rotate(angle * math.pi / 180);
    for (double i = -25; i <= 25; i += 8) {
      canvas.drawLine(Offset(i, -30), Offset(i, 30), Paint()..color = Colors.grey[500]!..strokeWidth = 1);
    }
    canvas.restore();

    // Arrow showing polarization axis
    final arrowLength = 45.0;
    final arrowAngle = angle * math.pi / 180;
    canvas.drawLine(
      Offset(x - arrowLength * math.sin(arrowAngle), y - arrowLength * math.cos(arrowAngle)),
      Offset(x + arrowLength * math.sin(arrowAngle), y + arrowLength * math.cos(arrowAngle)),
      Paint()..color = AppColors.accent..strokeWidth = 2,
    );

    _drawText(canvas, label, Offset(x - 20, y + 45), AppColors.muted, 10);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _PolarizationPainter oldDelegate) => true;
}
