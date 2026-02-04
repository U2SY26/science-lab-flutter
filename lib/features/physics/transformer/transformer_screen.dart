import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Transformer simulation: Vs/Vp = Ns/Np
class TransformerScreen extends StatefulWidget {
  const TransformerScreen({super.key});
  @override
  State<TransformerScreen> createState() => _TransformerScreenState();
}

class _TransformerScreenState extends State<TransformerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double primaryVoltage = 120; // V
  int primaryTurns = 100;
  int secondaryTurns = 50;
  double time = 0;
  bool isRunning = true;
  bool isKorean = true;

  double get turnsRatio => secondaryTurns / primaryTurns;
  double get secondaryVoltage => primaryVoltage * turnsRatio;
  double get primaryCurrent => 1.0; // Assume 1A for simplicity
  double get secondaryCurrent => primaryCurrent / turnsRatio; // Power conservation
  double get efficiency => 0.95; // Typical transformer efficiency
  double get power => primaryVoltage * primaryCurrent * efficiency;

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
          Text(isKorean ? '전자기학' : 'ELECTROMAGNETISM', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '변압기' : 'Transformer', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? '변압기' : 'Transformer',
          formula: 'Vs/Vp = Ns/Np',
          formulaDescription: isKorean ? '1차 코일과 2차 코일의 권선비에 따라 전압이 변환됩니다.' : 'Voltage transforms according to the turns ratio of primary and secondary coils.',
          simulation: CustomPaint(painter: _TransformerPainter(time: time, primaryTurns: primaryTurns, secondaryTurns: secondaryTurns, primaryVoltage: primaryVoltage, secondaryVoltage: secondaryVoltage, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '1차 전압 (Vp)' : 'Primary Voltage (Vp)', value: primaryVoltage, min: 10, max: 240, defaultValue: 120, formatValue: (v) => '${v.toStringAsFixed(0)} V', onChanged: (v) => setState(() => primaryVoltage = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '1차 권선수 (Np)' : 'Primary Turns (Np)', value: primaryTurns.toDouble(), min: 10, max: 200, defaultValue: 100, formatValue: (v) => '${v.toStringAsFixed(0)}', onChanged: (v) => setState(() => primaryTurns = v.round())),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '2차 권선수 (Ns)' : 'Secondary Turns (Ns)', value: secondaryTurns.toDouble(), min: 10, max: 200, defaultValue: 50, formatValue: (v) => '${v.toStringAsFixed(0)}', onChanged: (v) => setState(() => secondaryTurns = v.round())),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text('Vs', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${secondaryVoltage.toStringAsFixed(1)} V', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('Ns/Np', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text(turnsRatio.toStringAsFixed(2), style: TextStyle(color: AppColors.accent2, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text(isKorean ? '유형' : 'Type', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text(turnsRatio > 1 ? (isKorean ? '승압' : 'Step-up') : (isKorean ? '강압' : 'Step-down'), style: TextStyle(color: turnsRatio > 1 ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.w600))])),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Column(children: [Text('Is', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${secondaryCurrent.toStringAsFixed(2)} A', style: TextStyle(color: Colors.purple, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('P', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${power.toStringAsFixed(1)} W', style: TextStyle(color: Colors.red, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
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

class _TransformerPainter extends CustomPainter {
  final double time, primaryVoltage, secondaryVoltage;
  final int primaryTurns, secondaryTurns;
  final bool isKorean;

  _TransformerPainter({required this.time, required this.primaryTurns, required this.secondaryTurns, required this.primaryVoltage, required this.secondaryVoltage, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height * 0.35;

    // Iron core
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, centerY), width: 40, height: 120), const Radius.circular(5)), Paint()..color = Colors.grey[600]!);
    canvas.drawRect(Rect.fromCenter(center: Offset(centerX - 60, centerY), width: 20, height: 120), Paint()..color = Colors.grey[600]!);
    canvas.drawRect(Rect.fromCenter(center: Offset(centerX + 60, centerY), width: 20, height: 120), Paint()..color = Colors.grey[600]!);
    canvas.drawRect(Rect.fromLTWH(centerX - 70, centerY - 60, 140, 20), Paint()..color = Colors.grey[600]!);
    canvas.drawRect(Rect.fromLTWH(centerX - 70, centerY + 40, 140, 20), Paint()..color = Colors.grey[600]!);

    // Primary coil (left side)
    final primaryCoilX = centerX - 60;
    final primaryHeight = math.min(primaryTurns / 200 * 80, 80.0);
    for (int i = 0; i < math.min(primaryTurns ~/ 10, 10); i++) {
      final y = centerY - primaryHeight / 2 + i * (primaryHeight / 10);
      canvas.drawArc(Rect.fromCenter(center: Offset(primaryCoilX - 15, y), width: 30, height: 12), -math.pi / 2, math.pi, false, Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 2);
    }
    _drawText(canvas, isKorean ? '1차' : 'Primary', Offset(primaryCoilX - 35, centerY + 70), Colors.red, 10);
    _drawText(canvas, 'Np=$primaryTurns', Offset(primaryCoilX - 35, centerY + 82), Colors.red, 9);

    // Secondary coil (right side)
    final secondaryCoilX = centerX + 60;
    final secondaryHeight = math.min(secondaryTurns / 200 * 80, 80.0);
    for (int i = 0; i < math.min(secondaryTurns ~/ 10, 10); i++) {
      final y = centerY - secondaryHeight / 2 + i * (secondaryHeight / 10);
      canvas.drawArc(Rect.fromCenter(center: Offset(secondaryCoilX + 15, y), width: 30, height: 12), math.pi / 2, math.pi, false, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2);
    }
    _drawText(canvas, isKorean ? '2차' : 'Secondary', Offset(secondaryCoilX, centerY + 70), Colors.blue, 10);
    _drawText(canvas, 'Ns=$secondaryTurns', Offset(secondaryCoilX, centerY + 82), Colors.blue, 9);

    // Magnetic flux lines (animated)
    for (int i = 0; i < 3; i++) {
      final phase = time + i * math.pi * 2 / 3;
      final alpha = (math.sin(phase) + 1) / 2;
      canvas.drawLine(Offset(centerX - 60, centerY - 40 + i * 40), Offset(centerX + 60, centerY - 40 + i * 40), Paint()..color = AppColors.accent.withValues(alpha: alpha * 0.5)..strokeWidth = 2);
    }

    // Input AC symbol
    canvas.drawCircle(Offset(primaryCoilX - 50, centerY), 15, Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 2);
    final acPath = Path()..moveTo(primaryCoilX - 58, centerY)..quadraticBezierTo(primaryCoilX - 50, centerY - 8, primaryCoilX - 50, centerY)..quadraticBezierTo(primaryCoilX - 50, centerY + 8, primaryCoilX - 42, centerY);
    canvas.drawPath(acPath, Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 2);
    _drawText(canvas, '${primaryVoltage.toStringAsFixed(0)}V', Offset(primaryCoilX - 65, centerY + 20), Colors.red, 10);

    // Output indicator
    canvas.drawCircle(Offset(secondaryCoilX + 50, centerY), 15, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2);
    final brightness = (math.sin(time * 2) + 1) / 2;
    canvas.drawCircle(Offset(secondaryCoilX + 50, centerY), 10, Paint()..color = Colors.yellow.withValues(alpha: brightness * secondaryVoltage / 240));
    _drawText(canvas, '${secondaryVoltage.toStringAsFixed(0)}V', Offset(secondaryCoilX + 35, centerY + 20), Colors.blue, 10);

    // Voltage waveforms
    final graphY = size.height * 0.75;
    final graphWidth = size.width - 60;

    canvas.drawLine(Offset(30, graphY), Offset(30 + graphWidth, graphY), Paint()..color = AppColors.muted..strokeWidth = 1);

    // Primary voltage wave
    final primaryPath = Path();
    for (double x = 0; x <= graphWidth / 2 - 10; x += 2) {
      final t = time + x * 0.05;
      final y = graphY - 30 * math.sin(t);
      if (x == 0) primaryPath.moveTo(30 + x, y); else primaryPath.lineTo(30 + x, y);
    }
    canvas.drawPath(primaryPath, Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 2);

    // Secondary voltage wave
    final secondaryPath = Path();
    final ratio = secondaryTurns / primaryTurns;
    for (double x = 0; x <= graphWidth / 2 - 10; x += 2) {
      final t = time + x * 0.05;
      final y = graphY - 30 * ratio * math.sin(t);
      if (x == 0) secondaryPath.moveTo(graphWidth / 2 + 30 + x, y); else secondaryPath.lineTo(graphWidth / 2 + 30 + x, y);
    }
    canvas.drawPath(secondaryPath, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2);

    _drawText(canvas, 'Vp', Offset(35, graphY - 45), Colors.red, 10);
    _drawText(canvas, 'Vs', Offset(graphWidth / 2 + 35, graphY - 45), Colors.blue, 10);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _TransformerPainter oldDelegate) => true;
}
