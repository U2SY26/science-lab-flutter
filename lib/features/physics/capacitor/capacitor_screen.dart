import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Capacitor simulation: C = ε₀A/d
class CapacitorScreen extends StatefulWidget {
  const CapacitorScreen({super.key});

  @override
  State<CapacitorScreen> createState() => _CapacitorScreenState();
}

class _CapacitorScreenState extends State<CapacitorScreen> {
  double area = 0.01; // m²
  double separation = 0.001; // m
  double voltage = 12.0; // V
  bool isKorean = true;

  static const double epsilon0 = 8.85e-12;
  double get capacitance => epsilon0 * area / separation;
  double get charge => capacitance * voltage;
  double get energy => 0.5 * capacitance * voltage * voltage;
  double get electricField => voltage / separation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isKorean ? '전자기학' : 'ELECTROMAGNETISM', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '축전기' : 'Capacitor', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? '축전기' : 'Capacitor',
          formula: 'C = ε₀A/d',
          formulaDescription: isKorean ? '평행판 축전기의 전기용량(C)은 면적(A)에 비례하고 간격(d)에 반비례합니다.' : 'Capacitance of parallel plate capacitor is proportional to area and inversely proportional to separation.',
          simulation: CustomPaint(painter: _CapacitorPainter(area: area, separation: separation, voltage: voltage, capacitance: capacitance, charge: charge, electricField: electricField, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '전압 (V)' : 'Voltage (V)', value: voltage, min: 1, max: 100, defaultValue: 12, formatValue: (v) => '${v.toStringAsFixed(0)} V', onChanged: (v) => setState(() => voltage = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '면적 (A)' : 'Area (A)', value: area * 10000, min: 10, max: 500, defaultValue: 100, formatValue: (v) => '${v.toStringAsFixed(0)} cm²', onChanged: (v) => setState(() => area = v / 10000)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '간격 (d)' : 'Separation (d)', value: separation * 1000, min: 0.1, max: 10, step: 0.1, defaultValue: 1, formatValue: (v) => '${v.toStringAsFixed(1)} mm', onChanged: (v) => setState(() => separation = v / 1000)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text('C', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(capacitance * 1e12).toStringAsFixed(2)} pF', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('Q', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(charge * 1e9).toStringAsFixed(2)} nC', style: TextStyle(color: AppColors.accent2, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('E', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(electricField / 1000).toStringAsFixed(1)} kV/m', style: TextStyle(color: Colors.orange, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('U', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(energy * 1e9).toStringAsFixed(2)} nJ', style: TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CapacitorPainter extends CustomPainter {
  final double area, separation, voltage, capacitance, charge, electricField;
  final bool isKorean;

  _CapacitorPainter({required this.area, required this.separation, required this.voltage, required this.capacitance, required this.charge, required this.electricField, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final plateWidth = 100.0 + area * 3000;
    final plateGap = 30.0 + separation * 5000;

    // Left plate (+)
    canvas.drawRect(Rect.fromCenter(center: Offset(centerX - plateGap / 2, centerY), width: 10, height: plateWidth), Paint()..color = Colors.red.withValues(alpha: 0.7));
    _drawText(canvas, '+', Offset(centerX - plateGap / 2 - 20, centerY - 10), Colors.red, 16);

    // Right plate (-)
    canvas.drawRect(Rect.fromCenter(center: Offset(centerX + plateGap / 2, centerY), width: 10, height: plateWidth), Paint()..color = Colors.blue.withValues(alpha: 0.7));
    _drawText(canvas, '−', Offset(centerX + plateGap / 2 + 10, centerY - 10), Colors.blue, 16);

    // Electric field lines
    for (int i = -3; i <= 3; i++) {
      final y = centerY + i * (plateWidth / 8);
      canvas.drawLine(Offset(centerX - plateGap / 2 + 8, y), Offset(centerX + plateGap / 2 - 8, y), Paint()..color = AppColors.accent.withValues(alpha: 0.4)..strokeWidth = 1);
      // Arrow
      canvas.drawLine(Offset(centerX, y), Offset(centerX - 5, y - 3), Paint()..color = AppColors.accent.withValues(alpha: 0.4)..strokeWidth = 1);
      canvas.drawLine(Offset(centerX, y), Offset(centerX - 5, y + 3), Paint()..color = AppColors.accent.withValues(alpha: 0.4)..strokeWidth = 1);
    }

    // Labels
    _drawText(canvas, 'd = ${(separation * 1000).toStringAsFixed(1)} mm', Offset(centerX - 25, centerY + plateWidth / 2 + 15), AppColors.muted, 10);
    _drawText(canvas, 'E', Offset(centerX + 5, centerY - plateWidth / 2 - 20), AppColors.accent, 12);
    _drawText(canvas, 'V = ${voltage.toStringAsFixed(0)} V', Offset(20, 20), AppColors.ink, 12);
    _drawText(canvas, 'C = ε₀A/d = ${(capacitance * 1e12).toStringAsFixed(2)} pF', Offset(20, 40), AppColors.accent, 11);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _CapacitorPainter oldDelegate) => true;
}
