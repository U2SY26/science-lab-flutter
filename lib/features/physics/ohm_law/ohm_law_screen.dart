import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Ohm's Law simulation: V = IR
class OhmLawScreen extends StatefulWidget {
  const OhmLawScreen({super.key});

  @override
  State<OhmLawScreen> createState() => _OhmLawScreenState();
}

class _OhmLawScreenState extends State<OhmLawScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double voltage = 12.0; // V
  double resistance = 100.0; // Ω
  double electronPhase = 0.0;
  bool isKorean = true;

  double get current => voltage / resistance; // A
  double get power => voltage * current; // W

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(() => setState(() => electronPhase += current * 0.1))
      ..repeat();
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
          Text(isKorean ? '옴의 법칙' : "Ohm's Law", style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? '옴의 법칙' : "Ohm's Law",
          formula: 'V = IR',
          formulaDescription: isKorean ? '전압(V)은 전류(I)와 저항(R)의 곱입니다.' : 'Voltage (V) equals current (I) times resistance (R).',
          simulation: CustomPaint(painter: _OhmLawPainter(voltage: voltage, current: current, resistance: resistance, power: power, electronPhase: electronPhase, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '전압 (V)' : 'Voltage (V)', value: voltage, min: 1, max: 24, defaultValue: 12, formatValue: (v) => '${v.toStringAsFixed(1)} V', onChanged: (v) => setState(() => voltage = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '저항 (R)' : 'Resistance (R)', value: resistance, min: 10, max: 1000, defaultValue: 100, formatValue: (v) => '${v.toStringAsFixed(0)} Ω', onChanged: (v) => setState(() => resistance = v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text('V', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${voltage.toStringAsFixed(1)} V', style: TextStyle(color: Colors.yellow[700], fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('I', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(current * 1000).toStringAsFixed(1)} mA', style: TextStyle(color: AppColors.accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('R', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${resistance.toStringAsFixed(0)} Ω', style: TextStyle(color: AppColors.accent2, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('P', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(power * 1000).toStringAsFixed(1)} mW', style: TextStyle(color: Colors.green, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
                const SizedBox(height: 8),
                Text('I = V/R = ${voltage.toStringAsFixed(1)}/${resistance.toStringAsFixed(0)} = ${(current * 1000).toStringAsFixed(2)} mA', style: const TextStyle(color: AppColors.accent, fontSize: 10, fontFamily: 'monospace')),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _OhmLawPainter extends CustomPainter {
  final double voltage, current, resistance, power, electronPhase;
  final bool isKorean;

  _OhmLawPainter({required this.voltage, required this.current, required this.resistance, required this.power, required this.electronPhase, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerY = size.height / 2;

    // Battery
    final batteryX = 60.0;
    canvas.drawRect(Rect.fromCenter(center: Offset(batteryX, centerY), width: 10, height: 40), Paint()..color = Colors.red);
    canvas.drawRect(Rect.fromCenter(center: Offset(batteryX + 8, centerY), width: 5, height: 25), Paint()..color = Colors.red);
    _drawText(canvas, '+', Offset(batteryX - 5, centerY - 35), Colors.red, 14);
    _drawText(canvas, '−', Offset(batteryX - 5, centerY + 25), Colors.blue, 14);
    _drawText(canvas, '${voltage.toStringAsFixed(0)}V', Offset(batteryX - 15, centerY + 45), AppColors.muted, 10);

    // Wires
    final wireColor = AppColors.muted;
    final resistorX = size.width / 2;

    // Top wire
    canvas.drawLine(Offset(batteryX, centerY - 20), Offset(batteryX, centerY - 60), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(batteryX, centerY - 60), Offset(size.width - 60, centerY - 60), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(size.width - 60, centerY - 60), Offset(size.width - 60, centerY - 20), Paint()..color = wireColor..strokeWidth = 2);

    // Bottom wire
    canvas.drawLine(Offset(batteryX, centerY + 20), Offset(batteryX, centerY + 60), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(batteryX, centerY + 60), Offset(size.width - 60, centerY + 60), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(size.width - 60, centerY + 60), Offset(size.width - 60, centerY + 20), Paint()..color = wireColor..strokeWidth = 2);

    // Resistor
    final resistorPath = Path()..moveTo(resistorX - 40, centerY);
    for (int i = 0; i < 6; i++) {
      resistorPath.lineTo(resistorX - 30 + i * 12, centerY + (i.isEven ? -15 : 15));
    }
    resistorPath.lineTo(resistorX + 40, centerY);
    canvas.drawPath(resistorPath, Paint()..color = AppColors.accent2..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawLine(Offset(resistorX - 40, centerY), Offset(size.width - 60, centerY), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(batteryX, centerY), Offset(resistorX - 40, centerY), Paint()..color = wireColor..strokeWidth = 2);

    _drawText(canvas, '${resistance.toStringAsFixed(0)}Ω', Offset(resistorX - 15, centerY + 25), AppColors.accent2, 11);

    // Electrons (animated)
    for (int i = 0; i < 8; i++) {
      final phase = (electronPhase + i * 0.4) % 4;
      Offset pos;
      if (phase < 1) { pos = Offset(batteryX + phase * (resistorX - 40 - batteryX), centerY); }
      else if (phase < 2) { pos = Offset(resistorX - 40 + (phase - 1) * 80, centerY); }
      else if (phase < 3) { pos = Offset(resistorX + 40 + (phase - 2) * (size.width - 60 - resistorX - 40), centerY); }
      else { pos = Offset(size.width - 60, centerY - 60 + (phase - 3) * 120); }

      canvas.drawCircle(pos, 4, Paint()..color = AppColors.accent);
    }

    // Current direction arrow
    _drawText(canvas, isKorean ? '전류 방향 →' : 'Current →', Offset(resistorX - 30, centerY - 45), AppColors.accent, 10);

    // Ohm's Law triangle
    final triangleX = size.width - 100;
    final triangleY = size.height - 80;
    final path = Path()..moveTo(triangleX, triangleY - 40)..lineTo(triangleX - 30, triangleY + 20)..lineTo(triangleX + 30, triangleY + 20)..close();
    canvas.drawPath(path, Paint()..color = AppColors.cardBorder..style = PaintingStyle.stroke..strokeWidth = 2);
    _drawText(canvas, 'V', Offset(triangleX - 5, triangleY - 35), Colors.yellow[700]!, 12);
    _drawText(canvas, 'I', Offset(triangleX - 25, triangleY + 5), AppColors.accent, 12);
    _drawText(canvas, 'R', Offset(triangleX + 15, triangleY + 5), AppColors.accent2, 12);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _OhmLawPainter oldDelegate) => true;
}
