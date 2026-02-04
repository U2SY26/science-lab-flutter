import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// RLC Circuit simulation: resonance and impedance
class RlcCircuitScreen extends StatefulWidget {
  const RlcCircuitScreen({super.key});
  @override
  State<RlcCircuitScreen> createState() => _RlcCircuitScreenState();
}

class _RlcCircuitScreenState extends State<RlcCircuitScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double resistance = 100; // Ohms
  double inductance = 0.1; // H
  double capacitance = 10e-6; // F
  double frequency = 100; // Hz
  double voltage = 10; // V
  double time = 0;
  bool isRunning = true;
  bool isKorean = true;

  double get omega => 2 * math.pi * frequency;
  double get xl => omega * inductance; // Inductive reactance
  double get xc => 1 / (omega * capacitance); // Capacitive reactance
  double get impedance => math.sqrt(resistance * resistance + math.pow(xl - xc, 2));
  double get current => voltage / impedance;
  double get phase => math.atan2(xl - xc, resistance);
  double get resonantFreq => 1 / (2 * math.pi * math.sqrt(inductance * capacitance));
  double get qualityFactor => (1 / resistance) * math.sqrt(inductance / capacitance);
  double get powerFactor => resistance / impedance;

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
          Text(isKorean ? '전자기학' : 'ELECTROMAGNETISM', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? 'RLC 회로' : 'RLC Circuit', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? 'RLC 회로' : 'RLC Circuit',
          formula: 'Z = √(R² + (XL - XC)²)',
          formulaDescription: isKorean ? 'RLC 회로의 임피던스와 공진 현상을 탐구합니다.' : 'Explore impedance and resonance in RLC circuits.',
          simulation: CustomPaint(painter: _RlcCircuitPainter(time: time, omega: omega, current: current, phase: phase, voltage: voltage, xl: xl, xc: xc, resistance: resistance, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '저항 (R)' : 'Resistance (R)', value: resistance, min: 10, max: 500, defaultValue: 100, formatValue: (v) => '${v.toStringAsFixed(0)} Ω', onChanged: (v) => setState(() => resistance = v)),
            const SizedBox(height: 8),
            SimSlider(label: isKorean ? '인덕턴스 (L)' : 'Inductance (L)', value: inductance * 1000, min: 10, max: 500, defaultValue: 100, formatValue: (v) => '${v.toStringAsFixed(0)} mH', onChanged: (v) => setState(() => inductance = v / 1000)),
            const SizedBox(height: 8),
            SimSlider(label: isKorean ? '전기용량 (C)' : 'Capacitance (C)', value: capacitance * 1e6, min: 1, max: 100, defaultValue: 10, formatValue: (v) => '${v.toStringAsFixed(0)} μF', onChanged: (v) => setState(() => capacitance = v * 1e-6)),
            const SizedBox(height: 8),
            SimSlider(label: isKorean ? '주파수 (f)' : 'Frequency (f)', value: frequency, min: 10, max: 500, defaultValue: 100, formatValue: (v) => '${v.toStringAsFixed(0)} Hz', onChanged: (v) => setState(() => frequency = v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text('Z', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${impedance.toStringAsFixed(1)} Ω', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('I', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(current * 1000).toStringAsFixed(1)} mA', style: TextStyle(color: AppColors.accent2, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('f₀', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${resonantFreq.toStringAsFixed(1)} Hz', style: TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Column(children: [Text('Q', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text(qualityFactor.toStringAsFixed(2), style: TextStyle(color: Colors.orange, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('cos φ', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text(powerFactor.toStringAsFixed(3), style: TextStyle(color: Colors.purple, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('φ', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(phase * 180 / math.pi).toStringAsFixed(1)}°', style: TextStyle(color: Colors.red, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            SimButtonGroup(expanded: true, buttons: [
              SimButton(label: isRunning ? (isKorean ? '정지' : 'Stop') : (isKorean ? '시작' : 'Start'), icon: isRunning ? Icons.pause : Icons.play_arrow, isPrimary: true, onPressed: () => setState(() => isRunning = !isRunning)),
              SimButton(label: isKorean ? '공진' : 'Resonate', icon: Icons.graphic_eq, onPressed: () => setState(() => frequency = resonantFreq)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _RlcCircuitPainter extends CustomPainter {
  final double time, omega, current, phase, voltage, xl, xc, resistance;
  final bool isKorean;

  _RlcCircuitPainter({required this.time, required this.omega, required this.current, required this.phase, required this.voltage, required this.xl, required this.xc, required this.resistance, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final graphY = size.height * 0.6;
    final graphWidth = size.width - 60;
    final graphHeight = 60.0;

    // Circuit diagram
    final circuitY = 60.0;

    // Wires
    canvas.drawLine(Offset(40, circuitY), Offset(80, circuitY), Paint()..color = AppColors.muted..strokeWidth = 2);
    canvas.drawLine(Offset(130, circuitY), Offset(170, circuitY), Paint()..color = AppColors.muted..strokeWidth = 2);
    canvas.drawLine(Offset(220, circuitY), Offset(260, circuitY), Paint()..color = AppColors.muted..strokeWidth = 2);
    canvas.drawLine(Offset(310, circuitY), Offset(340, circuitY), Paint()..color = AppColors.muted..strokeWidth = 2);
    canvas.drawLine(Offset(340, circuitY), Offset(340, circuitY + 40), Paint()..color = AppColors.muted..strokeWidth = 2);
    canvas.drawLine(Offset(40, circuitY + 40), Offset(340, circuitY + 40), Paint()..color = AppColors.muted..strokeWidth = 2);
    canvas.drawLine(Offset(40, circuitY), Offset(40, circuitY + 40), Paint()..color = AppColors.muted..strokeWidth = 2);

    // Resistor
    _drawResistor(canvas, Offset(105, circuitY), 'R');

    // Inductor
    _drawInductor(canvas, Offset(195, circuitY), 'L');

    // Capacitor
    _drawCapacitor(canvas, Offset(285, circuitY), 'C');

    // AC source symbol
    canvas.drawCircle(Offset(40, circuitY + 20), 10, Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawLine(Offset(35, circuitY + 20), Offset(40, circuitY + 15), Paint()..color = Colors.red..strokeWidth = 2);
    canvas.drawLine(Offset(40, circuitY + 15), Offset(45, circuitY + 25), Paint()..color = Colors.red..strokeWidth = 2);

    // Voltage and current waveforms
    canvas.drawLine(Offset(30, graphY), Offset(30 + graphWidth, graphY), Paint()..color = AppColors.muted..strokeWidth = 1);
    canvas.drawLine(Offset(30, graphY - graphHeight), Offset(30, graphY + graphHeight), Paint()..color = AppColors.muted..strokeWidth = 1);

    // Voltage curve (reference)
    final voltagePath = Path();
    for (double x = 0; x <= graphWidth; x += 2) {
      final t = time + x * 0.01;
      final y = graphY - graphHeight * 0.8 * math.sin(omega * t);
      if (x == 0) voltagePath.moveTo(30 + x, y); else voltagePath.lineTo(30 + x, y);
    }
    canvas.drawPath(voltagePath, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2);

    // Current curve (phase shifted)
    final currentPath = Path();
    for (double x = 0; x <= graphWidth; x += 2) {
      final t = time + x * 0.01;
      final y = graphY - graphHeight * 0.8 * (current / (voltage / resistance)) * math.sin(omega * t - phase);
      if (x == 0) currentPath.moveTo(30 + x, y); else currentPath.lineTo(30 + x, y);
    }
    canvas.drawPath(currentPath, Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 2);

    // Labels
    _drawText(canvas, 'V', Offset(35, graphY - graphHeight - 15), Colors.blue, 11);
    _drawText(canvas, 'I', Offset(55, graphY - graphHeight - 15), Colors.red, 11);

    // Phasor diagram
    final phasorX = centerX;
    final phasorY = size.height * 0.85;
    final phasorRadius = 40.0;

    canvas.drawCircle(Offset(phasorX, phasorY), phasorRadius, Paint()..color = AppColors.muted.withValues(alpha: 0.3)..style = PaintingStyle.stroke);

    // Voltage phasor
    final vAngle = omega * time;
    canvas.drawLine(Offset(phasorX, phasorY), Offset(phasorX + phasorRadius * math.cos(vAngle), phasorY - phasorRadius * math.sin(vAngle)), Paint()..color = Colors.blue..strokeWidth = 3);

    // Current phasor
    final iAngle = omega * time - phase;
    canvas.drawLine(Offset(phasorX, phasorY), Offset(phasorX + phasorRadius * 0.8 * math.cos(iAngle), phasorY - phasorRadius * 0.8 * math.sin(iAngle)), Paint()..color = Colors.red..strokeWidth = 3);

    _drawText(canvas, isKorean ? '위상도' : 'Phasor', Offset(phasorX - 20, phasorY + phasorRadius + 5), AppColors.muted, 10);
  }

  void _drawResistor(Canvas canvas, Offset center, String label) {
    final path = Path()..moveTo(center.dx - 25, center.dy);
    for (int i = 0; i < 4; i++) {
      path.lineTo(center.dx - 15 + i * 10, center.dy + (i.isEven ? -8 : 8));
    }
    path.lineTo(center.dx + 25, center.dy);
    canvas.drawPath(path, Paint()..color = AppColors.accent2..style = PaintingStyle.stroke..strokeWidth = 2);
    _drawText(canvas, label, Offset(center.dx - 5, center.dy + 12), AppColors.accent2, 10);
  }

  void _drawInductor(Canvas canvas, Offset center, String label) {
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(Rect.fromCenter(center: Offset(center.dx - 15 + i * 10, center.dy), width: 10, height: 15), math.pi, math.pi, false, Paint()..color = AppColors.accent..style = PaintingStyle.stroke..strokeWidth = 2);
    }
    _drawText(canvas, label, Offset(center.dx - 5, center.dy + 12), AppColors.accent, 10);
  }

  void _drawCapacitor(Canvas canvas, Offset center, String label) {
    canvas.drawLine(Offset(center.dx - 25, center.dy), Offset(center.dx - 5, center.dy), Paint()..color = AppColors.muted..strokeWidth = 2);
    canvas.drawLine(Offset(center.dx - 5, center.dy - 12), Offset(center.dx - 5, center.dy + 12), Paint()..color = Colors.blue..strokeWidth = 3);
    canvas.drawLine(Offset(center.dx + 5, center.dy - 12), Offset(center.dx + 5, center.dy + 12), Paint()..color = Colors.blue..strokeWidth = 3);
    canvas.drawLine(Offset(center.dx + 5, center.dy), Offset(center.dx + 25, center.dy), Paint()..color = AppColors.muted..strokeWidth = 2);
    _drawText(canvas, label, Offset(center.dx - 5, center.dy + 15), Colors.blue, 10);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _RlcCircuitPainter oldDelegate) => true;
}
