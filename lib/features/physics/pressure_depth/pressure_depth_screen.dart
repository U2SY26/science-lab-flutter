import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Pressure and Depth simulation
class PressureDepthScreen extends StatefulWidget {
  const PressureDepthScreen({super.key});
  @override
  State<PressureDepthScreen> createState() => _PressureDepthScreenState();
}

class _PressureDepthScreenState extends State<PressureDepthScreen> {
  double depth = 10; // m
  double density = 1000; // kg/m³ (water)
  double atmosphericPressure = 101325; // Pa
  bool isKorean = true;

  double get gravity => 9.8;
  double get gaugePressure => density * gravity * depth;
  double get absolutePressure => atmosphericPressure + gaugePressure;
  double get pressureAtm => absolutePressure / atmosphericPressure;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isKorean ? '유체역학' : 'FLUID MECHANICS', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '압력과 깊이' : 'Pressure and Depth', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '유체역학' : 'Fluid Mechanics',
          title: isKorean ? '압력과 깊이' : 'Pressure and Depth',
          formula: 'P = P₀ + ρgh',
          formulaDescription: isKorean ? '깊이가 깊어질수록 압력이 증가합니다. 10m마다 약 1기압씩 증가합니다.' : 'Pressure increases with depth. Increases by about 1 atm every 10m.',
          simulation: CustomPaint(painter: _PressureDepthPainter(depth: depth, density: density, gaugePressure: gaugePressure, absolutePressure: absolutePressure, pressureAtm: pressureAtm, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '깊이 (h)' : 'Depth (h)', value: depth, min: 0, max: 100, defaultValue: 10, formatValue: (v) => '${v.toStringAsFixed(0)} m', onChanged: (v) => setState(() => depth = v)),
            const SizedBox(height: 16),
            Text(isKorean ? '유체 유형' : 'Fluid Type', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 4),
            PresetGroup(presets: [
              PresetButton(label: '${isKorean ? "담수" : "Fresh Water"} (1000)', isSelected: density == 1000, onPressed: () => setState(() => density = 1000)),
              PresetButton(label: '${isKorean ? "해수" : "Sea Water"} (1025)', isSelected: density == 1025, onPressed: () => setState(() => density = 1025)),
              PresetButton(label: '${isKorean ? "수은" : "Mercury"} (13600)', isSelected: density == 13600, onPressed: () => setState(() => density = 13600)),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text(isKorean ? '게이지 압력' : 'Gauge Pressure', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(gaugePressure / 1000).toStringAsFixed(1)} kPa', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text(isKorean ? '절대 압력' : 'Absolute Pressure', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(absolutePressure / 1000).toStringAsFixed(1)} kPa', style: TextStyle(color: AppColors.accent2, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Column(children: [Text(isKorean ? '기압 단위' : 'In Atmospheres', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${pressureAtm.toStringAsFixed(2)} atm', style: TextStyle(color: Colors.orange, fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isKorean ? '참고:' : 'Note:', style: TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(isKorean ? '• 스쿠버 다이빙 깊이 제한: ~40m\n• 잠수함 운용 깊이: ~300m\n• 마리아나 해구: ~11,000m (1,100 atm!)' : '• Scuba diving limit: ~40m\n• Submarine depth: ~300m\n• Mariana Trench: ~11,000m (1,100 atm!)', style: TextStyle(color: AppColors.muted, fontSize: 10, height: 1.4)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PressureDepthPainter extends CustomPainter {
  final double depth, density, gaugePressure, absolutePressure, pressureAtm;
  final bool isKorean;

  _PressureDepthPainter({required this.depth, required this.density, required this.gaugePressure, required this.absolutePressure, required this.pressureAtm, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final tankLeft = 60.0;
    final tankRight = size.width * 0.5;
    final tankTop = 40.0;
    final tankBottom = size.height * 0.7;
    final tankWidth = tankRight - tankLeft;
    final tankHeight = tankBottom - tankTop;

    // Water tank
    canvas.drawRect(Rect.fromLTWH(tankLeft, tankTop, tankWidth, tankHeight), Paint()..color = Colors.grey[800]!..style = PaintingStyle.stroke..strokeWidth = 3);

    // Water with gradient (darker at bottom)
    for (double y = tankTop; y < tankBottom; y += 2) {
      final progress = (y - tankTop) / tankHeight;
      final alpha = 0.3 + progress * 0.4;
      canvas.drawLine(Offset(tankLeft + 2, y), Offset(tankRight - 2, y), Paint()..color = Colors.blue.withValues(alpha: alpha));
    }

    // Surface
    canvas.drawLine(Offset(tankLeft, tankTop), Offset(tankRight, tankTop), Paint()..color = Colors.lightBlue..strokeWidth = 3);
    _drawText(canvas, isKorean ? '수면' : 'Surface', Offset(tankRight + 5, tankTop - 5), AppColors.muted, 10);
    _drawText(canvas, 'P₀ = 1 atm', Offset(tankRight + 5, tankTop + 10), Colors.cyan, 10);

    // Depth marker
    final depthY = tankTop + (depth / 100) * tankHeight;
    if (depth > 0) {
      canvas.drawLine(Offset(tankLeft - 5, depthY), Offset(tankRight + 5, depthY), Paint()..color = Colors.yellow..strokeWidth = 2);

      // Depth arrow
      canvas.drawLine(Offset(tankLeft - 20, tankTop), Offset(tankLeft - 20, depthY), Paint()..color = Colors.yellow..strokeWidth = 2);
      canvas.drawLine(Offset(tankLeft - 25, tankTop + 5), Offset(tankLeft - 20, tankTop), Paint()..color = Colors.yellow..strokeWidth = 2);
      canvas.drawLine(Offset(tankLeft - 15, tankTop + 5), Offset(tankLeft - 20, tankTop), Paint()..color = Colors.yellow..strokeWidth = 2);
      canvas.drawLine(Offset(tankLeft - 25, depthY - 5), Offset(tankLeft - 20, depthY), Paint()..color = Colors.yellow..strokeWidth = 2);
      canvas.drawLine(Offset(tankLeft - 15, depthY - 5), Offset(tankLeft - 20, depthY), Paint()..color = Colors.yellow..strokeWidth = 2);
      _drawText(canvas, 'h=${depth.toStringAsFixed(0)}m', Offset(tankLeft - 55, (tankTop + depthY) / 2 - 5), Colors.yellow, 10);

      // Pressure at depth
      _drawText(canvas, 'P = ${pressureAtm.toStringAsFixed(1)} atm', Offset(tankRight + 5, depthY - 5), Colors.orange, 10);
    }

    // Diver/object at depth
    if (depth > 0 && depth < 100) {
      final diverX = tankLeft + tankWidth / 2;
      final diverY = depthY;

      // Simple diver representation
      canvas.drawCircle(Offset(diverX, diverY - 10), 8, Paint()..color = Colors.yellow);
      canvas.drawRect(Rect.fromCenter(center: Offset(diverX, diverY + 5), width: 15, height: 20), Paint()..color = Colors.orange);

      // Pressure arrows pointing inward
      final arrowLength = 20 + pressureAtm * 5;
      canvas.drawLine(Offset(diverX - 30, diverY), Offset(diverX - 30 + arrowLength.clamp(10, 40), diverY), Paint()..color = Colors.red..strokeWidth = 2);
      canvas.drawLine(Offset(diverX + 30, diverY), Offset(diverX + 30 - arrowLength.clamp(10, 40), diverY), Paint()..color = Colors.red..strokeWidth = 2);
      canvas.drawLine(Offset(diverX, diverY + 30), Offset(diverX, diverY + 30 - arrowLength.clamp(10, 40)), Paint()..color = Colors.red..strokeWidth = 2);
    }

    // Pressure vs depth graph
    final graphLeft = size.width * 0.6;
    final graphRight = size.width - 30;
    final graphTop = tankTop;
    final graphBottom = tankBottom;
    final graphWidth = graphRight - graphLeft;
    final graphHeight = graphBottom - graphTop;

    // Graph axes
    canvas.drawLine(Offset(graphLeft, graphTop), Offset(graphLeft, graphBottom), Paint()..color = AppColors.muted..strokeWidth = 1);
    canvas.drawLine(Offset(graphLeft, graphBottom), Offset(graphRight, graphBottom), Paint()..color = AppColors.muted..strokeWidth = 1);

    // Depth labels (y-axis, inverted)
    _drawText(canvas, '0m', Offset(graphLeft - 25, graphTop), AppColors.muted, 9);
    _drawText(canvas, '50m', Offset(graphLeft - 30, graphTop + graphHeight / 2), AppColors.muted, 9);
    _drawText(canvas, '100m', Offset(graphLeft - 35, graphBottom - 10), AppColors.muted, 9);

    // Pressure labels (x-axis)
    _drawText(canvas, '1', Offset(graphLeft - 3, graphBottom + 10), AppColors.muted, 9);
    _drawText(canvas, '5', Offset(graphLeft + graphWidth / 2 - 3, graphBottom + 10), AppColors.muted, 9);
    _drawText(canvas, '11', Offset(graphRight - 10, graphBottom + 10), AppColors.muted, 9);
    _drawText(canvas, 'P (atm)', Offset(graphLeft + graphWidth / 2 - 20, graphBottom + 25), AppColors.muted, 10);

    // Pressure line (linear relationship)
    final pressurePath = Path();
    for (double d = 0; d <= 100; d += 1) {
      final p = 1 + (density * 9.8 * d) / 101325; // in atm
      final x = graphLeft + (p - 1) / 10 * graphWidth;
      final y = graphTop + (d / 100) * graphHeight;
      if (d == 0) {
        pressurePath.moveTo(x, y);
      } else {
        pressurePath.lineTo(x, y);
      }
    }
    canvas.drawPath(pressurePath, Paint()..color = Colors.cyan..style = PaintingStyle.stroke..strokeWidth = 2);

    // Current depth marker on graph
    final currentP = pressureAtm;
    final markerX = graphLeft + (currentP - 1) / 10 * graphWidth;
    final markerY = graphTop + (depth / 100) * graphHeight;
    canvas.drawCircle(Offset(markerX.clamp(graphLeft, graphRight), markerY), 6, Paint()..color = Colors.yellow);

    // Labels
    _drawText(canvas, isKorean ? '깊이 (h)' : 'Depth (h)', Offset(graphLeft - 45, graphTop + graphHeight / 2 + 30), AppColors.muted, 9);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _PressureDepthPainter oldDelegate) => true;
}
