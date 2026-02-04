import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Reynolds Number simulation
class ReynoldsScreen extends StatefulWidget {
  const ReynoldsScreen({super.key});
  @override
  State<ReynoldsScreen> createState() => _ReynoldsScreenState();
}

class _ReynoldsScreenState extends State<ReynoldsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double velocity = 1.0; // m/s
  double diameter = 0.05; // m (pipe diameter)
  double density = 1000; // kg/m³
  double viscosity = 0.001; // Pa·s (water)
  double time = 0;
  bool isRunning = true;
  bool isKorean = true;

  double get reynoldsNumber => (density * velocity * diameter) / viscosity;
  String get flowType {
    if (reynoldsNumber < 2300) return isKorean ? '층류' : 'Laminar';
    if (reynoldsNumber < 4000) return isKorean ? '천이 영역' : 'Transitional';
    return isKorean ? '난류' : 'Turbulent';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(() { if (isRunning) setState(() => time += 0.03); })..repeat();
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
          Text(isKorean ? '레이놀즈 수' : 'Reynolds Number', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '유체역학' : 'Fluid Mechanics',
          title: isKorean ? '레이놀즈 수' : 'Reynolds Number',
          formula: 'Re = ρvD/μ',
          formulaDescription: isKorean ? 'Re < 2300: 층류 (smooth)\nRe > 4000: 난류 (chaotic)' : 'Re < 2300: Laminar (smooth)\nRe > 4000: Turbulent (chaotic)',
          simulation: CustomPaint(painter: _ReynoldsPainter(reynoldsNumber: reynoldsNumber, time: time, velocity: velocity, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '유속 (v)' : 'Velocity (v)', value: velocity, min: 0.1, max: 5.0, defaultValue: 1.0, formatValue: (v) => '${v.toStringAsFixed(1)} m/s', onChanged: (v) => setState(() => velocity = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '관 직경 (D)' : 'Pipe Diameter (D)', value: diameter * 100, min: 1, max: 20, defaultValue: 5, formatValue: (v) => '${v.toStringAsFixed(0)} cm', onChanged: (v) => setState(() => diameter = v / 100)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '점성 (μ)' : 'Viscosity (μ)', value: viscosity * 1000, min: 0.5, max: 10, defaultValue: 1, formatValue: (v) => '${v.toStringAsFixed(1)} mPa·s', onChanged: (v) => setState(() => viscosity = v / 1000)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: reynoldsNumber < 2300 ? Colors.green.withValues(alpha: 0.1) : reynoldsNumber < 4000 ? Colors.orange.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: reynoldsNumber < 2300 ? Colors.green : reynoldsNumber < 4000 ? Colors.orange : Colors.red),
              ),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text('Re', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text(reynoldsNumber.toStringAsFixed(0), style: TextStyle(color: AppColors.accent, fontSize: 16, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text(isKorean ? '흐름 유형' : 'Flow Type', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text(flowType, style: TextStyle(color: reynoldsNumber < 2300 ? Colors.green : reynoldsNumber < 4000 ? Colors.orange : Colors.red, fontSize: 14, fontWeight: FontWeight.w600))])),
                ]),
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

class _ReynoldsPainter extends CustomPainter {
  final double reynoldsNumber, time, velocity;
  final bool isKorean;

  _ReynoldsPainter({required this.reynoldsNumber, required this.time, required this.velocity, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerY = size.height * 0.35;
    final pipeHeight = 70.0;

    // Pipe
    canvas.drawRect(Rect.fromLTWH(30, centerY - pipeHeight / 2, size.width - 60, pipeHeight), Paint()..color = Colors.grey[800]!);
    canvas.drawRect(Rect.fromLTWH(35, centerY - pipeHeight / 2 + 5, size.width - 70, pipeHeight - 10), Paint()..color = Colors.lightBlue.withValues(alpha: 0.3));

    final random = math.Random(42);

    if (reynoldsNumber < 2300) {
      // Laminar flow - smooth parallel streamlines
      for (int i = 0; i < 8; i++) {
        final y = centerY - pipeHeight / 2 + 10 + i * (pipeHeight - 20) / 7;
        final distFromCenter = (y - centerY).abs();
        final maxDist = (pipeHeight - 20) / 2;
        final velocityScale = 1 - (distFromCenter / maxDist) * (distFromCenter / maxDist);

        // Smooth streamline
        final path = Path();
        for (double x = 35; x < size.width - 35; x += 2) {
          final px = x;
          final py = y;
          if (x == 35) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        canvas.drawPath(path, Paint()..color = Colors.cyan.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2);

        // Particles moving along streamlines
        for (int j = 0; j < 5; j++) {
          final particleX = ((35 + j * 70 + time * velocity * 100 * velocityScale) % (size.width - 70)) + 35;
          canvas.drawCircle(Offset(particleX, y), 4, Paint()..color = Colors.cyan);
        }
      }
      _drawText(canvas, isKorean ? '층류 (Re < 2300)' : 'Laminar Flow (Re < 2300)', Offset(size.width / 2 - 60, centerY + pipeHeight / 2 + 10), Colors.green, 11);
    } else if (reynoldsNumber < 4000) {
      // Transitional flow - some waviness
      for (int i = 0; i < 8; i++) {
        final y = centerY - pipeHeight / 2 + 10 + i * (pipeHeight - 20) / 7;

        final path = Path();
        for (double x = 35; x < size.width - 35; x += 2) {
          final waveAmplitude = 3 * random.nextDouble();
          final py = y + waveAmplitude * math.sin(x * 0.1 + time + i);
          if (x == 35) {
            path.moveTo(x, py);
          } else {
            path.lineTo(x, py);
          }
        }
        canvas.drawPath(path, Paint()..color = Colors.cyan.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 2);
      }

      // Particles with slight randomness
      for (int i = 0; i < 30; i++) {
        final baseX = (i * 15 + time * velocity * 80) % (size.width - 70) + 35;
        final baseY = centerY + (random.nextDouble() - 0.5) * (pipeHeight - 20);
        final offsetY = 5 * math.sin(baseX * 0.1 + time);
        canvas.drawCircle(Offset(baseX, baseY + offsetY), 3, Paint()..color = Colors.cyan);
      }
      _drawText(canvas, isKorean ? '천이 영역 (2300 < Re < 4000)' : 'Transitional (2300 < Re < 4000)', Offset(size.width / 2 - 80, centerY + pipeHeight / 2 + 10), Colors.orange, 11);
    } else {
      // Turbulent flow - chaotic eddies
      for (int i = 0; i < 50; i++) {
        final baseX = (i * 10 + time * velocity * 60 + random.nextDouble() * 20) % (size.width - 70) + 35;
        final baseY = centerY + (random.nextDouble() - 0.5) * (pipeHeight - 15);

        // Random motion
        final offsetX = 8 * math.sin(time * 3 + i * 0.5) * random.nextDouble();
        final offsetY = 8 * math.cos(time * 2 + i * 0.7) * random.nextDouble();

        canvas.drawCircle(Offset(baseX + offsetX, baseY + offsetY), 3, Paint()..color = Colors.cyan.withValues(alpha: 0.7));
      }

      // Draw some eddies
      for (int i = 0; i < 5; i++) {
        final eddyX = 60 + ((i * 60 + time * 30) % (size.width - 120));
        final eddyY = centerY + (random.nextDouble() - 0.5) * 30;
        final eddyRadius = 10 + random.nextDouble() * 10;

        canvas.drawArc(Rect.fromCenter(center: Offset(eddyX, eddyY), width: eddyRadius * 2, height: eddyRadius * 2), time + i, math.pi * 1.5, false, Paint()..color = Colors.cyan.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2);
      }
      _drawText(canvas, isKorean ? '난류 (Re > 4000)' : 'Turbulent Flow (Re > 4000)', Offset(size.width / 2 - 60, centerY + pipeHeight / 2 + 10), Colors.red, 11);
    }

    // Reynolds number scale at bottom
    final scaleY = size.height * 0.8;
    final scaleWidth = size.width - 60;

    canvas.drawLine(Offset(30, scaleY), Offset(30 + scaleWidth, scaleY), Paint()..color = AppColors.muted..strokeWidth = 2);

    // Laminar region
    canvas.drawRect(Rect.fromLTWH(30, scaleY - 15, scaleWidth * 0.3, 30), Paint()..color = Colors.green.withValues(alpha: 0.3));
    // Transitional region
    canvas.drawRect(Rect.fromLTWH(30 + scaleWidth * 0.3, scaleY - 15, scaleWidth * 0.2, 30), Paint()..color = Colors.orange.withValues(alpha: 0.3));
    // Turbulent region
    canvas.drawRect(Rect.fromLTWH(30 + scaleWidth * 0.5, scaleY - 15, scaleWidth * 0.5, 30), Paint()..color = Colors.red.withValues(alpha: 0.3));

    // Current Re marker
    final rePosition = (reynoldsNumber / 10000).clamp(0.0, 1.0) * scaleWidth;
    canvas.drawLine(Offset(30 + rePosition, scaleY - 20), Offset(30 + rePosition, scaleY + 20), Paint()..color = AppColors.accent..strokeWidth = 3);

    _drawText(canvas, '0', Offset(25, scaleY + 20), AppColors.muted, 9);
    _drawText(canvas, '2300', Offset(30 + scaleWidth * 0.23 - 15, scaleY + 20), AppColors.muted, 9);
    _drawText(canvas, '4000', Offset(30 + scaleWidth * 0.4 - 15, scaleY + 20), AppColors.muted, 9);
    _drawText(canvas, '10000', Offset(30 + scaleWidth - 20, scaleY + 20), AppColors.muted, 9);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _ReynoldsPainter oldDelegate) => true;
}
