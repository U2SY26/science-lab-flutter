import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Series & Parallel Circuits simulation
class SeriesParallelScreen extends StatefulWidget {
  const SeriesParallelScreen({super.key});
  @override
  State<SeriesParallelScreen> createState() => _SeriesParallelScreenState();
}

class _SeriesParallelScreenState extends State<SeriesParallelScreen> {
  double r1 = 100, r2 = 200, r3 = 300;
  double voltage = 12;
  bool isSeries = true;
  bool isKorean = true;

  double get totalResistance => isSeries ? r1 + r2 + r3 : 1 / (1/r1 + 1/r2 + 1/r3);
  double get totalCurrent => voltage / totalResistance;
  double get i1 => isSeries ? totalCurrent : voltage / r1;
  double get i2 => isSeries ? totalCurrent : voltage / r2;
  double get i3 => isSeries ? totalCurrent : voltage / r3;
  double get v1 => isSeries ? totalCurrent * r1 : voltage;
  double get v2 => isSeries ? totalCurrent * r2 : voltage;
  double get v3 => isSeries ? totalCurrent * r3 : voltage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isKorean ? '전자기학' : 'ELECTROMAGNETISM', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '직렬·병렬 회로' : 'Series & Parallel', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? '직렬·병렬 회로' : 'Series & Parallel Circuits',
          formula: isSeries ? 'R_total = R₁ + R₂ + R₃' : '1/R_total = 1/R₁ + 1/R₂ + 1/R₃',
          formulaDescription: isKorean ? (isSeries ? '직렬: 전류 동일, 전압 분배' : '병렬: 전압 동일, 전류 분배') : (isSeries ? 'Series: Same current, voltage divides' : 'Parallel: Same voltage, current divides'),
          simulation: CustomPaint(painter: _SeriesParallelPainter(r1: r1, r2: r2, r3: r3, voltage: voltage, isSeries: isSeries, totalCurrent: totalCurrent, v1: v1, v2: v2, v3: v3, i1: i1, i2: i2, i3: i3, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSegment<bool>(label: isKorean ? '회로 유형' : 'Circuit Type', options: {true: isKorean ? '직렬' : 'Series', false: isKorean ? '병렬' : 'Parallel'}, selected: isSeries, onChanged: (v) => setState(() => isSeries = v)),
            const SizedBox(height: 16),
            SimSlider(label: 'R₁', value: r1, min: 10, max: 500, defaultValue: 100, formatValue: (v) => '${v.toStringAsFixed(0)} Ω', onChanged: (v) => setState(() => r1 = v)),
            const SizedBox(height: 8),
            SimSlider(label: 'R₂', value: r2, min: 10, max: 500, defaultValue: 200, formatValue: (v) => '${v.toStringAsFixed(0)} Ω', onChanged: (v) => setState(() => r2 = v)),
            const SizedBox(height: 8),
            SimSlider(label: 'R₃', value: r3, min: 10, max: 500, defaultValue: 300, formatValue: (v) => '${v.toStringAsFixed(0)} Ω', onChanged: (v) => setState(() => r3 = v)),
            const SizedBox(height: 8),
            SimSlider(label: isKorean ? '전압 (V)' : 'Voltage (V)', value: voltage, min: 1, max: 24, defaultValue: 12, formatValue: (v) => '${v.toStringAsFixed(0)} V', onChanged: (v) => setState(() => voltage = v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text('R_total', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${totalResistance.toStringAsFixed(1)} Ω', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('I_total', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(totalCurrent * 1000).toStringAsFixed(1)} mA', style: TextStyle(color: AppColors.accent2, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('P_total', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(voltage * totalCurrent * 1000).toStringAsFixed(1)} mW', style: TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SeriesParallelPainter extends CustomPainter {
  final double r1, r2, r3, voltage, totalCurrent, v1, v2, v3, i1, i2, i3;
  final bool isSeries, isKorean;

  _SeriesParallelPainter({required this.r1, required this.r2, required this.r3, required this.voltage, required this.isSeries, required this.totalCurrent, required this.v1, required this.v2, required this.v3, required this.i1, required this.i2, required this.i3, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (isSeries) {
      _drawSeriesCircuit(canvas, size);
    } else {
      _drawParallelCircuit(canvas, size);
    }
  }

  void _drawSeriesCircuit(Canvas canvas, Size size) {
    final y = size.height / 2;
    final wireColor = AppColors.muted;

    // Battery
    canvas.drawRect(Rect.fromCenter(center: Offset(40, y), width: 8, height: 30), Paint()..color = Colors.red);
    canvas.drawRect(Rect.fromCenter(center: Offset(46, y), width: 4, height: 20), Paint()..color = Colors.red);
    _drawText(canvas, '+', Offset(35, y - 25), Colors.red, 12);
    _drawText(canvas, '${voltage.toStringAsFixed(0)}V', Offset(30, y + 25), AppColors.muted, 9);

    // Wires and resistors
    canvas.drawLine(Offset(50, y), Offset(80, y), Paint()..color = wireColor..strokeWidth = 2);
    _drawResistor(canvas, Offset(110, y), r1, '${v1.toStringAsFixed(1)}V');
    canvas.drawLine(Offset(140, y), Offset(170, y), Paint()..color = wireColor..strokeWidth = 2);
    _drawResistor(canvas, Offset(200, y), r2, '${v2.toStringAsFixed(1)}V');
    canvas.drawLine(Offset(230, y), Offset(260, y), Paint()..color = wireColor..strokeWidth = 2);
    _drawResistor(canvas, Offset(290, y), r3, '${v3.toStringAsFixed(1)}V');
    canvas.drawLine(Offset(320, y), Offset(350, y), Paint()..color = wireColor..strokeWidth = 2);

    // Return path
    canvas.drawLine(Offset(350, y), Offset(350, y + 50), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(40, y + 50), Offset(350, y + 50), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(40, y), Offset(40, y + 50), Paint()..color = wireColor..strokeWidth = 2);

    // Current arrow
    _drawText(canvas, 'I = ${(totalCurrent * 1000).toStringAsFixed(1)} mA →', Offset(150, y - 40), AppColors.accent, 10);
  }

  void _drawParallelCircuit(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final wireColor = AppColors.muted;

    // Battery
    canvas.drawRect(Rect.fromCenter(center: Offset(40, centerY), width: 8, height: 30), Paint()..color = Colors.red);
    canvas.drawRect(Rect.fromCenter(center: Offset(46, centerY), width: 4, height: 20), Paint()..color = Colors.red);
    _drawText(canvas, '${voltage.toStringAsFixed(0)}V', Offset(30, centerY + 25), AppColors.muted, 9);

    // Main wires
    canvas.drawLine(Offset(50, centerY), Offset(100, centerY), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(100, centerY - 60), Offset(100, centerY + 60), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(280, centerY - 60), Offset(280, centerY + 60), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(280, centerY), Offset(330, centerY), Paint()..color = wireColor..strokeWidth = 2);

    // Three parallel branches
    canvas.drawLine(Offset(100, centerY - 60), Offset(140, centerY - 60), Paint()..color = wireColor..strokeWidth = 2);
    _drawResistor(canvas, Offset(190, centerY - 60), r1, '${(i1 * 1000).toStringAsFixed(1)}mA');
    canvas.drawLine(Offset(240, centerY - 60), Offset(280, centerY - 60), Paint()..color = wireColor..strokeWidth = 2);

    canvas.drawLine(Offset(100, centerY), Offset(140, centerY), Paint()..color = wireColor..strokeWidth = 2);
    _drawResistor(canvas, Offset(190, centerY), r2, '${(i2 * 1000).toStringAsFixed(1)}mA');
    canvas.drawLine(Offset(240, centerY), Offset(280, centerY), Paint()..color = wireColor..strokeWidth = 2);

    canvas.drawLine(Offset(100, centerY + 60), Offset(140, centerY + 60), Paint()..color = wireColor..strokeWidth = 2);
    _drawResistor(canvas, Offset(190, centerY + 60), r3, '${(i3 * 1000).toStringAsFixed(1)}mA');
    canvas.drawLine(Offset(240, centerY + 60), Offset(280, centerY + 60), Paint()..color = wireColor..strokeWidth = 2);

    // Return path
    canvas.drawLine(Offset(330, centerY), Offset(330, centerY + 90), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(40, centerY + 90), Offset(330, centerY + 90), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(40, centerY), Offset(40, centerY + 90), Paint()..color = wireColor..strokeWidth = 2);

    _drawText(canvas, 'I_total = ${(totalCurrent * 1000).toStringAsFixed(1)} mA', Offset(60, centerY - 80), AppColors.accent, 10);
  }

  void _drawResistor(Canvas canvas, Offset center, double resistance, String label) {
    final path = Path()..moveTo(center.dx - 30, center.dy);
    for (int i = 0; i < 5; i++) {
      path.lineTo(center.dx - 20 + i * 10, center.dy + (i.isEven ? -10 : 10));
    }
    path.lineTo(center.dx + 30, center.dy);
    canvas.drawPath(path, Paint()..color = AppColors.accent2..style = PaintingStyle.stroke..strokeWidth = 2);
    _drawText(canvas, '${resistance.toStringAsFixed(0)}Ω', Offset(center.dx - 15, center.dy + 15), AppColors.accent2, 9);
    _drawText(canvas, label, Offset(center.dx - 20, center.dy - 25), AppColors.muted, 8);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _SeriesParallelPainter oldDelegate) => true;
}
