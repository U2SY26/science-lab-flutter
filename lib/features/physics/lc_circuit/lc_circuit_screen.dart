import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// LC Circuit simulation: f = 1/2π√LC
class LcCircuitScreen extends StatefulWidget {
  const LcCircuitScreen({super.key});
  @override
  State<LcCircuitScreen> createState() => _LcCircuitScreenState();
}

class _LcCircuitScreenState extends State<LcCircuitScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double inductance = 0.01; // H (10 mH)
  double capacitance = 100e-6; // F (100 μF)
  double time = 0;
  bool isRunning = true;
  bool isKorean = true;

  double get resonantFreq => 1 / (2 * math.pi * math.sqrt(inductance * capacitance));
  double get period => 1 / resonantFreq;
  double get angularFreq => 2 * math.pi * resonantFreq;
  double get charge => math.cos(angularFreq * time);
  double get current => -math.sin(angularFreq * time);
  double get capacitorEnergy => 0.5 * charge * charge;
  double get inductorEnergy => 0.5 * current * current;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(() { if (isRunning) setState(() => time += 0.001); })..repeat();
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
          Text(isKorean ? '전자기학' : 'ELECTROMAGNETISM', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? 'LC 회로' : 'LC Circuit', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? 'LC 회로' : 'LC Circuit',
          formula: 'f = 1/(2π√LC)',
          formulaDescription: isKorean ? 'LC 회로의 공진 주파수. 에너지가 축전기와 인덕터 사이에서 진동합니다.' : 'Resonant frequency of LC circuit. Energy oscillates between capacitor and inductor.',
          simulation: CustomPaint(painter: _LcCircuitPainter(charge: charge, current: current, capacitorEnergy: capacitorEnergy, inductorEnergy: inductorEnergy, time: time, angularFreq: angularFreq, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '인덕턴스 (L)' : 'Inductance (L)', value: inductance * 1000, min: 1, max: 100, defaultValue: 10, formatValue: (v) => '${v.toStringAsFixed(0)} mH', onChanged: (v) => setState(() { inductance = v / 1000; time = 0; })),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '전기용량 (C)' : 'Capacitance (C)', value: capacitance * 1e6, min: 10, max: 1000, defaultValue: 100, formatValue: (v) => '${v.toStringAsFixed(0)} μF', onChanged: (v) => setState(() { capacitance = v * 1e-6; time = 0; })),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text(isKorean ? '공진 주파수' : 'Resonant Freq', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${resonantFreq.toStringAsFixed(1)} Hz', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text(isKorean ? '주기' : 'Period', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(period * 1000).toStringAsFixed(1)} ms', style: TextStyle(color: AppColors.accent2, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            SimButtonGroup(expanded: true, buttons: [
              SimButton(label: isRunning ? (isKorean ? '정지' : 'Stop') : (isKorean ? '시작' : 'Start'), icon: isRunning ? Icons.pause : Icons.play_arrow, isPrimary: true, onPressed: () => setState(() => isRunning = !isRunning)),
              SimButton(label: isKorean ? '리셋' : 'Reset', icon: Icons.refresh, onPressed: () => setState(() => time = 0)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _LcCircuitPainter extends CustomPainter {
  final double charge, current, capacitorEnergy, inductorEnergy, time, angularFreq;
  final bool isKorean;

  _LcCircuitPainter({required this.charge, required this.current, required this.capacitorEnergy, required this.inductorEnergy, required this.time, required this.angularFreq, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Circuit diagram
    final centerX = size.width / 2;
    final circuitY = 80.0;

    // Capacitor
    canvas.drawLine(Offset(centerX - 60, circuitY - 15), Offset(centerX - 60, circuitY + 15), Paint()..color = Colors.blue..strokeWidth = 3);
    canvas.drawLine(Offset(centerX - 50, circuitY - 15), Offset(centerX - 50, circuitY + 15), Paint()..color = Colors.blue..strokeWidth = 3);
    _drawText(canvas, 'C', Offset(centerX - 60, circuitY + 20), Colors.blue, 12);

    // Inductor
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(Rect.fromCenter(center: Offset(centerX + 30 + i * 15, circuitY), width: 15, height: 20), math.pi, math.pi, false, Paint()..color = AppColors.accent2..style = PaintingStyle.stroke..strokeWidth = 2);
    }
    _drawText(canvas, 'L', Offset(centerX + 50, circuitY + 20), AppColors.accent2, 12);

    // Wires
    canvas.drawLine(Offset(centerX - 100, circuitY), Offset(centerX - 60, circuitY), Paint()..color = AppColors.muted..strokeWidth = 2);
    canvas.drawLine(Offset(centerX - 50, circuitY), Offset(centerX + 30, circuitY), Paint()..color = AppColors.muted..strokeWidth = 2);
    canvas.drawLine(Offset(centerX + 90, circuitY), Offset(centerX + 130, circuitY), Paint()..color = AppColors.muted..strokeWidth = 2);
    canvas.drawLine(Offset(centerX - 100, circuitY), Offset(centerX - 100, circuitY + 40), Paint()..color = AppColors.muted..strokeWidth = 2);
    canvas.drawLine(Offset(centerX + 130, circuitY), Offset(centerX + 130, circuitY + 40), Paint()..color = AppColors.muted..strokeWidth = 2);
    canvas.drawLine(Offset(centerX - 100, circuitY + 40), Offset(centerX + 130, circuitY + 40), Paint()..color = AppColors.muted..strokeWidth = 2);

    // Energy bars
    final barY = size.height * 0.45;
    final barHeight = 60.0;
    final barWidth = 40.0;

    // Capacitor energy bar
    canvas.drawRect(Rect.fromLTWH(centerX - 80, barY, barWidth, barHeight), Paint()..color = AppColors.cardBorder);
    canvas.drawRect(Rect.fromLTWH(centerX - 80, barY + barHeight * (1 - capacitorEnergy), barWidth, barHeight * capacitorEnergy), Paint()..color = Colors.blue);
    _drawText(canvas, 'U_C', Offset(centerX - 75, barY + barHeight + 5), Colors.blue, 10);

    // Inductor energy bar
    canvas.drawRect(Rect.fromLTWH(centerX + 40, barY, barWidth, barHeight), Paint()..color = AppColors.cardBorder);
    canvas.drawRect(Rect.fromLTWH(centerX + 40, barY + barHeight * (1 - inductorEnergy), barWidth, barHeight * inductorEnergy), Paint()..color = AppColors.accent2);
    _drawText(canvas, 'U_L', Offset(centerX + 45, barY + barHeight + 5), AppColors.accent2, 10);

    // Oscillation graph
    final graphY = size.height * 0.75;
    final graphWidth = size.width - 60;

    canvas.drawLine(Offset(30, graphY), Offset(30 + graphWidth, graphY), Paint()..color = AppColors.muted..strokeWidth = 1);
    canvas.drawLine(Offset(30, graphY - 40), Offset(30, graphY + 40), Paint()..color = AppColors.muted..strokeWidth = 1);

    // Charge curve
    final chargePath = Path();
    for (double x = 0; x <= graphWidth; x += 2) {
      final t = time - (graphWidth - x) * 0.0005;
      final y = graphY - 30 * math.cos(angularFreq * t);
      if (x == 0) chargePath.moveTo(30 + x, y); else chargePath.lineTo(30 + x, y);
    }
    canvas.drawPath(chargePath, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2);

    // Current curve
    final currentPath = Path();
    for (double x = 0; x <= graphWidth; x += 2) {
      final t = time - (graphWidth - x) * 0.0005;
      final y = graphY + 30 * math.sin(angularFreq * t);
      if (x == 0) currentPath.moveTo(30 + x, y); else currentPath.lineTo(30 + x, y);
    }
    canvas.drawPath(currentPath, Paint()..color = AppColors.accent2..style = PaintingStyle.stroke..strokeWidth = 2);

    _drawText(canvas, 'Q', Offset(35, graphY - 50), Colors.blue, 10);
    _drawText(canvas, 'I', Offset(55, graphY - 50), AppColors.accent2, 10);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _LcCircuitPainter oldDelegate) => true;
}
