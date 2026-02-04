import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Bernoulli's Principle simulation
class BernoulliScreen extends StatefulWidget {
  const BernoulliScreen({super.key});
  @override
  State<BernoulliScreen> createState() => _BernoulliScreenState();
}

class _BernoulliScreenState extends State<BernoulliScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double velocity1 = 2.0; // m/s (wide section)
  double area1 = 0.1; // m² (wide section)
  double area2 = 0.05; // m² (narrow section)
  double pressure1 = 101325; // Pa (atmospheric)
  double density = 1000; // kg/m³ (water)
  double time = 0;
  bool isRunning = true;
  bool isKorean = true;

  // Continuity equation: A1*v1 = A2*v2
  double get velocity2 => velocity1 * area1 / area2;

  // Bernoulli equation: P1 + ½ρv1² = P2 + ½ρv2²
  double get pressure2 => pressure1 + 0.5 * density * (velocity1 * velocity1 - velocity2 * velocity2);

  double get dynamicPressure1 => 0.5 * density * velocity1 * velocity1;
  double get dynamicPressure2 => 0.5 * density * velocity2 * velocity2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(() { if (isRunning) setState(() => time += 0.02); })..repeat();
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
          Text(isKorean ? '유체역학' : 'FLUID MECHANICS', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '베르누이 원리' : "Bernoulli's Principle", style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '유체역학' : 'Fluid Mechanics',
          title: isKorean ? '베르누이 원리' : "Bernoulli's Principle",
          formula: 'P + ½ρv² + ρgh = const',
          formulaDescription: isKorean ? '유속이 빨라지면 압력이 낮아집니다. 비행기 날개의 원리입니다.' : 'As fluid velocity increases, pressure decreases. This is the principle behind airplane wings.',
          simulation: CustomPaint(painter: _BernoulliPainter(velocity1: velocity1, velocity2: velocity2, area1: area1, area2: area2, pressure1: pressure1, pressure2: pressure2, time: time, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '입구 속도 (v₁)' : 'Inlet Velocity (v₁)', value: velocity1, min: 0.5, max: 5.0, defaultValue: 2.0, formatValue: (v) => '${v.toStringAsFixed(1)} m/s', onChanged: (v) => setState(() => velocity1 = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '좁은 부분 면적비' : 'Area Ratio (A₂/A₁)', value: area2 / area1, min: 0.2, max: 0.8, defaultValue: 0.5, formatValue: (v) => v.toStringAsFixed(2), onChanged: (v) => setState(() => area2 = area1 * v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [
                    Text(isKorean ? '넓은 부분' : 'Wide Section', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                    Text('v₁ = ${velocity1.toStringAsFixed(1)} m/s', style: TextStyle(color: Colors.blue, fontSize: 11, fontFamily: 'monospace')),
                    Text('P₁ = ${(pressure1 / 1000).toStringAsFixed(1)} kPa', style: TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'monospace')),
                  ])),
                  Expanded(child: Column(children: [
                    Text(isKorean ? '좁은 부분' : 'Narrow Section', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                    Text('v₂ = ${velocity2.toStringAsFixed(1)} m/s', style: TextStyle(color: Colors.red, fontSize: 11, fontFamily: 'monospace')),
                    Text('P₂ = ${(pressure2 / 1000).toStringAsFixed(1)} kPa', style: TextStyle(color: Colors.orange, fontSize: 11, fontFamily: 'monospace')),
                  ])),
                ]),
                const SizedBox(height: 8),
                Text('ΔP = ${((pressure1 - pressure2) / 1000).toStringAsFixed(2)} kPa', style: TextStyle(color: AppColors.accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 12),
            SimButtonGroup(expanded: true, buttons: [
              SimButton(label: isRunning ? (isKorean ? '정지' : 'Stop') : (isKorean ? '시작' : 'Start'), icon: isRunning ? Icons.pause : Icons.play_arrow, isPrimary: true, onPressed: () => setState(() => isRunning = !isRunning)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _BernoulliPainter extends CustomPainter {
  final double velocity1, velocity2, area1, area2, pressure1, pressure2, time;
  final bool isKorean;

  _BernoulliPainter({required this.velocity1, required this.velocity2, required this.area1, required this.area2, required this.pressure1, required this.pressure2, required this.time, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerY = size.height * 0.35;
    final pipeHeight1 = 80.0;
    final pipeHeight2 = pipeHeight1 * (area2 / area1);

    // Venturi tube shape
    final pipePath = Path();
    pipePath.moveTo(20, centerY - pipeHeight1 / 2);
    pipePath.lineTo(100, centerY - pipeHeight1 / 2);
    pipePath.quadraticBezierTo(140, centerY - pipeHeight1 / 2, 160, centerY - pipeHeight2 / 2);
    pipePath.lineTo(220, centerY - pipeHeight2 / 2);
    pipePath.quadraticBezierTo(240, centerY - pipeHeight2 / 2, 280, centerY - pipeHeight1 / 2);
    pipePath.lineTo(size.width - 20, centerY - pipeHeight1 / 2);
    pipePath.lineTo(size.width - 20, centerY + pipeHeight1 / 2);
    pipePath.lineTo(280, centerY + pipeHeight1 / 2);
    pipePath.quadraticBezierTo(240, centerY + pipeHeight1 / 2, 220, centerY + pipeHeight2 / 2);
    pipePath.lineTo(160, centerY + pipeHeight2 / 2);
    pipePath.quadraticBezierTo(140, centerY + pipeHeight2 / 2, 100, centerY + pipeHeight1 / 2);
    pipePath.lineTo(20, centerY + pipeHeight1 / 2);
    pipePath.close();

    canvas.drawPath(pipePath, Paint()..color = Colors.lightBlue.withValues(alpha: 0.3));
    canvas.drawPath(pipePath, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2);

    // Fluid particles
    final random = math.Random(42);
    for (int i = 0; i < 50; i++) {
      final baseX = (i * 17 + time * velocity1 * 30) % (size.width - 40);
      final x = 20 + baseX;
      final yOffset = (random.nextDouble() - 0.5);

      double pipeHeightAtX;
      double particleSpeed;
      if (x < 100) {
        pipeHeightAtX = pipeHeight1;
        particleSpeed = velocity1;
      } else if (x < 160) {
        final t = (x - 100) / 60;
        pipeHeightAtX = pipeHeight1 + (pipeHeight2 - pipeHeight1) * t;
        particleSpeed = velocity1 + (velocity2 - velocity1) * t;
      } else if (x < 220) {
        pipeHeightAtX = pipeHeight2;
        particleSpeed = velocity2;
      } else if (x < 280) {
        final t = (x - 220) / 60;
        pipeHeightAtX = pipeHeight2 + (pipeHeight1 - pipeHeight2) * t;
        particleSpeed = velocity2 + (velocity1 - velocity2) * t;
      } else {
        pipeHeightAtX = pipeHeight1;
        particleSpeed = velocity1;
      }

      final y = centerY + yOffset * (pipeHeightAtX - 10);
      final particleSize = 3.0 + particleSpeed * 0.5;
      canvas.drawCircle(Offset(x, y), particleSize, Paint()..color = Colors.cyan.withValues(alpha: 0.7));
    }

    // Pressure indicators (manometer tubes)
    final manometer1X = 60.0;
    final manometer2X = 190.0;
    final manometerHeight1 = 30 + (pressure1 - 100000) / 500;
    final manometerHeight2 = 30 + (pressure2 - 100000) / 500;

    // Manometer 1 (wide section)
    canvas.drawRect(Rect.fromLTWH(manometer1X - 5, centerY - pipeHeight1 / 2 - manometerHeight1, 10, manometerHeight1), Paint()..color = Colors.red.withValues(alpha: 0.5));
    canvas.drawRect(Rect.fromLTWH(manometer1X - 5, centerY - pipeHeight1 / 2 - manometerHeight1, 10, manometerHeight1), Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 1);

    // Manometer 2 (narrow section)
    canvas.drawRect(Rect.fromLTWH(manometer2X - 5, centerY - pipeHeight2 / 2 - manometerHeight2, 10, manometerHeight2), Paint()..color = Colors.red.withValues(alpha: 0.5));
    canvas.drawRect(Rect.fromLTWH(manometer2X - 5, centerY - pipeHeight2 / 2 - manometerHeight2, 10, manometerHeight2), Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 1);

    // Labels
    _drawText(canvas, 'A₁', Offset(55, centerY + pipeHeight1 / 2 + 10), Colors.blue, 11);
    _drawText(canvas, 'A₂', Offset(185, centerY + pipeHeight2 / 2 + 10), Colors.blue, 11);
    _drawText(canvas, 'v₁', Offset(55, centerY - 5), Colors.cyan, 11);
    _drawText(canvas, 'v₂', Offset(185, centerY - 5), Colors.cyan, 11);
    _drawText(canvas, 'P₁', Offset(manometer1X - 8, centerY - pipeHeight1 / 2 - manometerHeight1 - 15), Colors.green, 10);
    _drawText(canvas, 'P₂', Offset(manometer2X - 8, centerY - pipeHeight2 / 2 - manometerHeight2 - 15), Colors.orange, 10);

    // Velocity arrows
    _drawArrow(canvas, Offset(30, centerY), Offset(30 + velocity1 * 15, centerY), Colors.cyan);
    _drawArrow(canvas, Offset(175, centerY), Offset(175 + velocity2 * 10, centerY), Colors.cyan);

    // Energy bar chart at bottom
    final chartY = size.height * 0.75;
    final barWidth = 50.0;
    final maxBarHeight = 60.0;

    // Wide section bars
    final staticP1 = maxBarHeight * (pressure1 / 105000);
    final dynamicP1 = maxBarHeight * (0.5 * 1000 * velocity1 * velocity1 / 5000);
    canvas.drawRect(Rect.fromLTWH(60, chartY - staticP1, barWidth / 2, staticP1), Paint()..color = Colors.green);
    canvas.drawRect(Rect.fromLTWH(60 + barWidth / 2, chartY - dynamicP1, barWidth / 2, dynamicP1), Paint()..color = Colors.blue);

    // Narrow section bars
    final staticP2 = maxBarHeight * (pressure2 / 105000);
    final dynamicP2 = maxBarHeight * (0.5 * 1000 * velocity2 * velocity2 / 5000);
    canvas.drawRect(Rect.fromLTWH(200, chartY - staticP2, barWidth / 2, staticP2), Paint()..color = Colors.green);
    canvas.drawRect(Rect.fromLTWH(200 + barWidth / 2, chartY - dynamicP2, barWidth / 2, dynamicP2), Paint()..color = Colors.blue);

    // Chart labels
    canvas.drawLine(Offset(50, chartY), Offset(280, chartY), Paint()..color = AppColors.muted..strokeWidth = 1);
    _drawText(canvas, isKorean ? '넓은 부분' : 'Wide', Offset(60, chartY + 5), AppColors.muted, 9);
    _drawText(canvas, isKorean ? '좁은 부분' : 'Narrow', Offset(195, chartY + 5), AppColors.muted, 9);
    _drawText(canvas, isKorean ? '정압' : 'Static P', Offset(60, chartY + 18), Colors.green, 8);
    _drawText(canvas, isKorean ? '동압' : 'Dynamic P', Offset(110, chartY + 18), Colors.blue, 8);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    canvas.drawLine(from, to, Paint()..color = color..strokeWidth = 3);
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    canvas.drawLine(to, Offset(to.dx - 8 * math.cos(angle - 0.5), to.dy - 8 * math.sin(angle - 0.5)), Paint()..color = color..strokeWidth = 3);
    canvas.drawLine(to, Offset(to.dx - 8 * math.cos(angle + 0.5), to.dy - 8 * math.sin(angle + 0.5)), Paint()..color = color..strokeWidth = 3);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _BernoulliPainter oldDelegate) => true;
}
