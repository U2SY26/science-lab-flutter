import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Kirchhoff's Laws simulation
class KirchhoffScreen extends StatefulWidget {
  const KirchhoffScreen({super.key});
  @override
  State<KirchhoffScreen> createState() => _KirchhoffScreenState();
}

class _KirchhoffScreenState extends State<KirchhoffScreen> {
  double v1 = 12, v2 = 6;
  double r1 = 100, r2 = 200, r3 = 150;
  bool isKorean = true;

  // Solve using Kirchhoff's laws (simplified 2-loop circuit)
  double get i1 => (v1 * (r2 + r3) - v2 * r3) / (r1 * r2 + r2 * r3 + r1 * r3);
  double get i2 => (v2 * (r1 + r3) - v1 * r3) / (r1 * r2 + r2 * r3 + r1 * r3);
  double get i3 => i1 - i2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isKorean ? '전자기학' : 'ELECTROMAGNETISM', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '키르히호프 법칙' : "Kirchhoff's Laws", style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? '키르히호프 법칙' : "Kirchhoff's Laws",
          formula: 'ΣI = 0 (KCL), ΣV = 0 (KVL)',
          formulaDescription: isKorean ? 'KCL: 노드의 전류 합 = 0\nKVL: 폐회로의 전압 합 = 0' : 'KCL: Sum of currents at node = 0\nKVL: Sum of voltages in loop = 0',
          simulation: CustomPaint(painter: _KirchhoffPainter(v1: v1, v2: v2, r1: r1, r2: r2, r3: r3, i1: i1, i2: i2, i3: i3, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(children: [SimSlider(label: 'V₁', value: v1, min: 1, max: 24, defaultValue: 12, formatValue: (v) => '${v.toStringAsFixed(0)} V', onChanged: (v) => setState(() => v1 = v))])),
              const SizedBox(width: 12),
              Expanded(child: Column(children: [SimSlider(label: 'V₂', value: v2, min: 1, max: 24, defaultValue: 6, formatValue: (v) => '${v.toStringAsFixed(0)} V', onChanged: (v) => setState(() => v2 = v))])),
            ]),
            const SizedBox(height: 12),
            SimSlider(label: 'R₁', value: r1, min: 10, max: 500, defaultValue: 100, formatValue: (v) => '${v.toStringAsFixed(0)} Ω', onChanged: (v) => setState(() => r1 = v)),
            const SizedBox(height: 8),
            SimSlider(label: 'R₂', value: r2, min: 10, max: 500, defaultValue: 200, formatValue: (v) => '${v.toStringAsFixed(0)} Ω', onChanged: (v) => setState(() => r2 = v)),
            const SizedBox(height: 8),
            SimSlider(label: 'R₃', value: r3, min: 10, max: 500, defaultValue: 150, formatValue: (v) => '${v.toStringAsFixed(0)} Ω', onChanged: (v) => setState(() => r3 = v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text('I₁', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(i1 * 1000).toStringAsFixed(2)} mA', style: TextStyle(color: Colors.red, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('I₂', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(i2 * 1000).toStringAsFixed(2)} mA', style: TextStyle(color: Colors.blue, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('I₃', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(i3 * 1000).toStringAsFixed(2)} mA', style: TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
                const SizedBox(height: 8),
                Text('KCL: I₁ = I₂ + I₃ → ${(i1 * 1000).toStringAsFixed(2)} = ${(i2 * 1000).toStringAsFixed(2)} + ${(i3 * 1000).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.accent, fontSize: 9, fontFamily: 'monospace')),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _KirchhoffPainter extends CustomPainter {
  final double v1, v2, r1, r2, r3, i1, i2, i3;
  final bool isKorean;

  _KirchhoffPainter({required this.v1, required this.v2, required this.r1, required this.r2, required this.r3, required this.i1, required this.i2, required this.i3, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerY = size.height / 2;
    final wireColor = AppColors.muted;

    // Two-loop circuit
    // Left loop
    canvas.drawRect(Rect.fromLTWH(40, centerY - 80, 120, 160), Paint()..color = Colors.transparent..style = PaintingStyle.stroke);

    // Right loop
    canvas.drawRect(Rect.fromLTWH(160, centerY - 80, 120, 160), Paint()..color = Colors.transparent..style = PaintingStyle.stroke);

    // Wires
    canvas.drawLine(Offset(40, centerY - 80), Offset(280, centerY - 80), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(40, centerY + 80), Offset(280, centerY + 80), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(40, centerY - 80), Offset(40, centerY + 80), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(160, centerY - 80), Offset(160, centerY + 80), Paint()..color = wireColor..strokeWidth = 2);
    canvas.drawLine(Offset(280, centerY - 80), Offset(280, centerY + 80), Paint()..color = wireColor..strokeWidth = 2);

    // V1 (left battery)
    canvas.drawRect(Rect.fromCenter(center: Offset(40, centerY), width: 8, height: 30), Paint()..color = Colors.red);
    _drawText(canvas, 'V₁=${v1.toStringAsFixed(0)}V', Offset(10, centerY + 20), Colors.red, 9);

    // V2 (right battery)
    canvas.drawRect(Rect.fromCenter(center: Offset(280, centerY), width: 8, height: 30), Paint()..color = Colors.blue);
    _drawText(canvas, 'V₂=${v2.toStringAsFixed(0)}V', Offset(285, centerY + 20), Colors.blue, 9);

    // R1 (top left)
    _drawResistor(canvas, Offset(100, centerY - 80), 'R₁=${r1.toStringAsFixed(0)}Ω');

    // R2 (top right)
    _drawResistor(canvas, Offset(220, centerY - 80), 'R₂=${r2.toStringAsFixed(0)}Ω');

    // R3 (middle vertical)
    _drawResistorVertical(canvas, Offset(160, centerY), 'R₃=${r3.toStringAsFixed(0)}Ω');

    // Current arrows and labels
    _drawText(canvas, 'I₁→', Offset(70, centerY - 95), Colors.red, 10);
    _drawText(canvas, 'I₂→', Offset(190, centerY - 95), Colors.blue, 10);
    _drawText(canvas, '↓I₃', Offset(165, centerY - 10), Colors.green, 10);

    // Node label
    canvas.drawCircle(Offset(160, centerY - 80), 5, Paint()..color = AppColors.accent);
    _drawText(canvas, isKorean ? '노드' : 'Node', Offset(145, centerY - 100), AppColors.accent, 9);

    // Loop labels
    _drawText(canvas, isKorean ? '루프 1' : 'Loop 1', Offset(70, centerY), AppColors.muted, 9);
    _drawText(canvas, isKorean ? '루프 2' : 'Loop 2', Offset(190, centerY), AppColors.muted, 9);
  }

  void _drawResistor(Canvas canvas, Offset center, String label) {
    final path = Path()..moveTo(center.dx - 25, center.dy);
    for (int i = 0; i < 4; i++) {
      path.lineTo(center.dx - 15 + i * 10, center.dy + (i.isEven ? -8 : 8));
    }
    path.lineTo(center.dx + 25, center.dy);
    canvas.drawPath(path, Paint()..color = AppColors.accent2..style = PaintingStyle.stroke..strokeWidth = 2);
    _drawText(canvas, label, Offset(center.dx - 25, center.dy + 10), AppColors.accent2, 8);
  }

  void _drawResistorVertical(Canvas canvas, Offset center, String label) {
    final path = Path()..moveTo(center.dx, center.dy - 25);
    for (int i = 0; i < 4; i++) {
      path.lineTo(center.dx + (i.isEven ? -8 : 8), center.dy - 15 + i * 10);
    }
    path.lineTo(center.dx, center.dy + 25);
    canvas.drawPath(path, Paint()..color = AppColors.accent2..style = PaintingStyle.stroke..strokeWidth = 2);
    _drawText(canvas, label, Offset(center.dx + 10, center.dy - 5), AppColors.accent2, 8);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _KirchhoffPainter oldDelegate) => true;
}
