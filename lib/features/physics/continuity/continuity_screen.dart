import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Continuity Equation simulation
class ContinuityScreen extends StatefulWidget {
  const ContinuityScreen({super.key});
  @override
  State<ContinuityScreen> createState() => _ContinuityScreenState();
}

class _ContinuityScreenState extends State<ContinuityScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double area1 = 0.1; // m²
  double velocity1 = 2.0; // m/s
  double area2 = 0.04; // m²
  double time = 0;
  bool isRunning = true;
  bool isKorean = true;

  double get velocity2 => (area1 * velocity1) / area2;
  double get flowRate => area1 * velocity1; // m³/s

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
          Text(isKorean ? '연속 방정식' : 'Continuity Equation', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '유체역학' : 'Fluid Mechanics',
          title: isKorean ? '연속 방정식' : 'Continuity Equation',
          formula: 'A₁v₁ = A₂v₂',
          formulaDescription: isKorean ? '비압축성 유체의 질량 보존: 좁은 곳에서 빨라지고, 넓은 곳에서 느려집니다.' : 'Mass conservation for incompressible fluids: Fluid speeds up in narrow sections.',
          simulation: CustomPaint(painter: _ContinuityPainter(area1: area1, area2: area2, velocity1: velocity1, velocity2: velocity2, flowRate: flowRate, time: time, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '넓은 부분 면적 (A₁)' : 'Wide Area (A₁)', value: area1 * 100, min: 5, max: 20, defaultValue: 10, formatValue: (v) => '${v.toStringAsFixed(0)} cm²', onChanged: (v) => setState(() => area1 = v / 100)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '좁은 부분 면적 (A₂)' : 'Narrow Area (A₂)', value: area2 * 100, min: 2, max: 10, defaultValue: 4, formatValue: (v) => '${v.toStringAsFixed(0)} cm²', onChanged: (v) => setState(() => area2 = v / 100)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '입구 속도 (v₁)' : 'Inlet Velocity (v₁)', value: velocity1, min: 0.5, max: 5.0, defaultValue: 2.0, formatValue: (v) => '${v.toStringAsFixed(1)} m/s', onChanged: (v) => setState(() => velocity1 = v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text('v₁', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${velocity1.toStringAsFixed(1)} m/s', style: TextStyle(color: Colors.blue, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('v₂', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${velocity2.toStringAsFixed(1)} m/s', style: TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('Q', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(flowRate * 1000).toStringAsFixed(1)} L/s', style: TextStyle(color: Colors.green, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
                const SizedBox(height: 8),
                Text('A₁v₁ = ${(area1 * velocity1 * 1000).toStringAsFixed(2)} = A₂v₂ = ${(area2 * velocity2 * 1000).toStringAsFixed(2)} L/s', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace')),
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

class _ContinuityPainter extends CustomPainter {
  final double area1, area2, velocity1, velocity2, flowRate, time;
  final bool isKorean;

  _ContinuityPainter({required this.area1, required this.area2, required this.velocity1, required this.velocity2, required this.flowRate, required this.time, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerY = size.height * 0.4;
    final pipeHeight1 = 80.0;
    final pipeHeight2 = pipeHeight1 * (area2 / area1).clamp(0.3, 1.0);

    // Pipe shape (converging then diverging)
    final pipePath = Path();
    pipePath.moveTo(20, centerY - pipeHeight1 / 2);
    pipePath.lineTo(80, centerY - pipeHeight1 / 2);
    pipePath.quadraticBezierTo(120, centerY - pipeHeight1 / 2, 140, centerY - pipeHeight2 / 2);
    pipePath.lineTo(240, centerY - pipeHeight2 / 2);
    pipePath.quadraticBezierTo(260, centerY - pipeHeight2 / 2, 300, centerY - pipeHeight1 / 2);
    pipePath.lineTo(size.width - 20, centerY - pipeHeight1 / 2);
    pipePath.lineTo(size.width - 20, centerY + pipeHeight1 / 2);
    pipePath.lineTo(300, centerY + pipeHeight1 / 2);
    pipePath.quadraticBezierTo(260, centerY + pipeHeight1 / 2, 240, centerY + pipeHeight2 / 2);
    pipePath.lineTo(140, centerY + pipeHeight2 / 2);
    pipePath.quadraticBezierTo(120, centerY + pipeHeight1 / 2, 80, centerY + pipeHeight1 / 2);
    pipePath.lineTo(20, centerY + pipeHeight1 / 2);
    pipePath.close();

    canvas.drawPath(pipePath, Paint()..color = Colors.lightBlue.withValues(alpha: 0.3));
    canvas.drawPath(pipePath, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2);

    // Particles
    final random = math.Random(42);
    for (int i = 0; i < 60; i++) {
      final baseProgress = (i / 60 + time * 0.3) % 1.0;

      double x, y, particleSpeed;
      if (baseProgress < 0.25) {
        // Wide section 1
        x = 20 + baseProgress * 4 * 60;
        y = centerY + (random.nextDouble() - 0.5) * (pipeHeight1 - 10);
        particleSpeed = velocity1;
      } else if (baseProgress < 0.35) {
        // Converging section
        final t = (baseProgress - 0.25) / 0.1;
        x = 80 + t * 60;
        final currentHeight = pipeHeight1 + (pipeHeight2 - pipeHeight1) * t;
        y = centerY + (random.nextDouble() - 0.5) * (currentHeight - 10);
        particleSpeed = velocity1 + (velocity2 - velocity1) * t;
      } else if (baseProgress < 0.65) {
        // Narrow section
        x = 140 + (baseProgress - 0.35) * 100 / 0.3;
        y = centerY + (random.nextDouble() - 0.5) * (pipeHeight2 - 10);
        particleSpeed = velocity2;
      } else if (baseProgress < 0.75) {
        // Diverging section
        final t = (baseProgress - 0.65) / 0.1;
        x = 240 + t * 60;
        final currentHeight = pipeHeight2 + (pipeHeight1 - pipeHeight2) * t;
        y = centerY + (random.nextDouble() - 0.5) * (currentHeight - 10);
        particleSpeed = velocity2 + (velocity1 - velocity2) * t;
      } else {
        // Wide section 2
        x = 300 + (baseProgress - 0.75) * 4 * (size.width - 320);
        y = centerY + (random.nextDouble() - 0.5) * (pipeHeight1 - 10);
        particleSpeed = velocity1;
      }

      final particleSize = 2 + particleSpeed * 0.8;
      canvas.drawCircle(Offset(x, y), particleSize, Paint()..color = Colors.cyan.withValues(alpha: 0.8));
    }

    // Velocity arrows
    _drawArrow(canvas, Offset(40, centerY), Offset(40 + velocity1 * 15, centerY), Colors.blue, 'v₁');
    _drawArrow(canvas, Offset(180, centerY), Offset(180 + velocity2 * 10, centerY), Colors.red, 'v₂');
    _drawArrow(canvas, Offset(size.width - 60, centerY), Offset(size.width - 60 + velocity1 * 15, centerY), Colors.blue, 'v₁');

    // Area labels
    _drawText(canvas, 'A₁', Offset(45, centerY + pipeHeight1 / 2 + 10), Colors.blue, 12);
    _drawText(canvas, 'A₂', Offset(180, centerY + pipeHeight2 / 2 + 10), Colors.red, 12);
    _drawText(canvas, 'A₁', Offset(size.width - 55, centerY + pipeHeight1 / 2 + 10), Colors.blue, 12);

    // Flow rate visualization
    final flowY = size.height * 0.8;
    _drawText(canvas, isKorean ? '유량 Q = Av = 일정' : 'Flow Rate Q = Av = constant', Offset(size.width / 2 - 80, flowY), AppColors.accent, 12);

    // Conservation diagram
    final diagramY = size.height * 0.9;
    canvas.drawRect(Rect.fromLTWH(50, diagramY - 20, 50, 40), Paint()..color = Colors.blue.withValues(alpha: 0.3));
    canvas.drawRect(Rect.fromLTWH(110, diagramY - 10, 25, 20), Paint()..color = Colors.red.withValues(alpha: 0.3));
    _drawText(canvas, '×', Offset(102, diagramY - 5), AppColors.muted, 12);
    _drawText(canvas, '=', Offset(140, diagramY - 5), AppColors.muted, 12);

    canvas.drawRect(Rect.fromLTWH(160, diagramY - 10, 25, 20), Paint()..color = Colors.blue.withValues(alpha: 0.3));
    canvas.drawRect(Rect.fromLTWH(195, diagramY - 20, 50, 40), Paint()..color = Colors.red.withValues(alpha: 0.3));
    _drawText(canvas, '×', Offset(187, diagramY - 5), AppColors.muted, 12);

    _drawText(canvas, 'A₁', Offset(65, diagramY + 25), Colors.blue, 9);
    _drawText(canvas, 'v₁', Offset(115, diagramY + 15), Colors.blue, 9);
    _drawText(canvas, 'A₂', Offset(165, diagramY + 15), Colors.red, 9);
    _drawText(canvas, 'v₂', Offset(210, diagramY + 25), Colors.red, 9);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color, String label) {
    canvas.drawLine(from, to, Paint()..color = color..strokeWidth = 3);
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    canvas.drawLine(to, Offset(to.dx - 8 * math.cos(angle - 0.5), to.dy - 8 * math.sin(angle - 0.5)), Paint()..color = color..strokeWidth = 3);
    canvas.drawLine(to, Offset(to.dx - 8 * math.cos(angle + 0.5), to.dy - 8 * math.sin(angle + 0.5)), Paint()..color = color..strokeWidth = 3);
    _drawText(canvas, label, Offset((from.dx + to.dx) / 2 - 8, from.dy - 20), color, 10);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _ContinuityPainter oldDelegate) => true;
}
