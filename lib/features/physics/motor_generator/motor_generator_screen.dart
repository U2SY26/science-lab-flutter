import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Motor & Generator simulation
class MotorGeneratorScreen extends StatefulWidget {
  const MotorGeneratorScreen({super.key});
  @override
  State<MotorGeneratorScreen> createState() => _MotorGeneratorScreenState();
}

class _MotorGeneratorScreenState extends State<MotorGeneratorScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isMotorMode = true; // true = motor, false = generator
  double magneticField = 0.5; // T
  double current = 2.0; // A (motor mode)
  double rpm = 1000; // RPM (generator mode)
  double rotorAngle = 0;
  bool isRunning = true;
  bool isKorean = true;

  double get torque => isMotorMode ? magneticField * current * 0.1 : 0; // Simplified
  double get emf => isMotorMode ? 0 : magneticField * (rpm / 60) * 0.1; // Simplified
  double get angularVelocity => isMotorMode ? torque * 100 : rpm * 2 * math.pi / 60;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(() {
        if (isRunning) {
          setState(() {
            rotorAngle += angularVelocity * 0.01;
            if (rotorAngle > 2 * math.pi) rotorAngle -= 2 * math.pi;
          });
        }
      })..repeat();
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
          Text(isKorean ? '모터와 발전기' : 'Motor & Generator', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? '모터와 발전기' : 'Motor & Generator',
          formula: isMotorMode ? 'τ = BIL' : 'EMF = BLv',
          formulaDescription: isKorean ? (isMotorMode ? '모터: 전류가 자기장에서 힘을 받아 회전' : '발전기: 코일 회전으로 전자기 유도') : (isMotorMode ? 'Motor: Current in magnetic field creates rotation' : 'Generator: Rotating coil induces EMF'),
          simulation: CustomPaint(painter: _MotorGeneratorPainter(rotorAngle: rotorAngle, isMotorMode: isMotorMode, magneticField: magneticField, current: current, rpm: rpm, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSegment<bool>(label: isKorean ? '모드' : 'Mode', options: {true: isKorean ? '모터' : 'Motor', false: isKorean ? '발전기' : 'Generator'}, selected: isMotorMode, onChanged: (v) => setState(() => isMotorMode = v)),
            const SizedBox(height: 16),
            SimSlider(label: isKorean ? '자기장 (B)' : 'Magnetic Field (B)', value: magneticField, min: 0.1, max: 1.0, defaultValue: 0.5, formatValue: (v) => '${v.toStringAsFixed(2)} T', onChanged: (v) => setState(() => magneticField = v)),
            const SizedBox(height: 12),
            if (isMotorMode)
              SimSlider(label: isKorean ? '전류 (I)' : 'Current (I)', value: current, min: 0.5, max: 5.0, defaultValue: 2.0, formatValue: (v) => '${v.toStringAsFixed(1)} A', onChanged: (v) => setState(() => current = v))
            else
              SimSlider(label: isKorean ? '회전속도' : 'RPM', value: rpm, min: 100, max: 3000, defaultValue: 1000, formatValue: (v) => '${v.toStringAsFixed(0)} RPM', onChanged: (v) => setState(() => rpm = v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  if (isMotorMode) ...[
                    Expanded(child: Column(children: [Text(isKorean ? '토크' : 'Torque', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(torque * 1000).toStringAsFixed(1)} mN·m', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                    Expanded(child: Column(children: [Text(isKorean ? '각속도' : 'Angular Vel', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(angularVelocity * 60 / (2 * math.pi)).toStringAsFixed(0)} RPM', style: TextStyle(color: AppColors.accent2, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  ] else ...[
                    Expanded(child: Column(children: [Text('EMF', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(emf * math.sin(rotorAngle)).toStringAsFixed(2)} V', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                    Expanded(child: Column(children: [Text(isKorean ? '최대 EMF' : 'Peak EMF', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${emf.toStringAsFixed(2)} V', style: TextStyle(color: AppColors.accent2, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  ],
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

class _MotorGeneratorPainter extends CustomPainter {
  final double rotorAngle, magneticField, current, rpm;
  final bool isMotorMode, isKorean;

  _MotorGeneratorPainter({required this.rotorAngle, required this.isMotorMode, required this.magneticField, required this.current, required this.rpm, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height * 0.35;
    final radius = 60.0;

    // Magnet poles
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(centerX - radius - 40, centerY - radius, 30, radius * 2), const Radius.circular(5)), Paint()..color = Colors.red);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(centerX + radius + 10, centerY - radius, 30, radius * 2), const Radius.circular(5)), Paint()..color = Colors.blue);
    _drawText(canvas, 'N', Offset(centerX - radius - 32, centerY - 8), Colors.white, 16);
    _drawText(canvas, 'S', Offset(centerX + radius + 18, centerY - 8), Colors.white, 16);

    // Magnetic field lines
    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(Offset(centerX - radius - 10, centerY + i * 20), Offset(centerX + radius + 10, centerY + i * 20), Paint()..color = AppColors.muted.withValues(alpha: 0.3)..strokeWidth = 1);
    }

    // Rotor (coil)
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(rotorAngle);

    // Coil rectangle
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: radius * 1.5, height: radius * 0.8), Paint()..color = AppColors.accent2..style = PaintingStyle.stroke..strokeWidth = 4);

    // Current direction indicators (motor mode)
    if (isMotorMode) {
      canvas.drawCircle(Offset(-radius * 0.75, 0), 8, Paint()..color = Colors.yellow);
      _drawText(canvas, '⊙', Offset(-radius * 0.75 - 6, -8), Colors.black, 14);
      canvas.drawCircle(Offset(radius * 0.75, 0), 8, Paint()..color = Colors.yellow);
      _drawText(canvas, '⊗', Offset(radius * 0.75 - 6, -8), Colors.black, 14);
    }

    canvas.restore();

    // Axis
    canvas.drawCircle(Offset(centerX, centerY), 8, Paint()..color = Colors.grey[700]!);
    canvas.drawCircle(Offset(centerX, centerY), 4, Paint()..color = Colors.grey[500]!);

    // Brushes and commutator (simplified)
    canvas.drawRect(Rect.fromLTWH(centerX - 5, centerY + radius + 10, 10, 20), Paint()..color = Colors.orange);

    // Labels
    _drawText(canvas, isKorean ? (isMotorMode ? '모터' : '발전기') : (isMotorMode ? 'Motor' : 'Generator'), Offset(centerX - 25, 20), AppColors.ink, 14);

    // EMF/Current graph (generator mode)
    if (!isMotorMode) {
      final graphY = size.height * 0.75;
      final graphWidth = size.width - 60;

      canvas.drawLine(Offset(30, graphY), Offset(30 + graphWidth, graphY), Paint()..color = AppColors.muted..strokeWidth = 1);
      canvas.drawLine(Offset(30, graphY - 40), Offset(30, graphY + 40), Paint()..color = AppColors.muted..strokeWidth = 1);

      final emfPath = Path();
      final emfMax = magneticField * (rpm / 60) * 0.1;
      for (double x = 0; x <= graphWidth; x += 2) {
        final angle = rotorAngle - (graphWidth - x) * 0.02;
        final y = graphY - 35 * math.sin(angle);
        if (x == 0) emfPath.moveTo(30 + x, y); else emfPath.lineTo(30 + x, y);
      }
      canvas.drawPath(emfPath, Paint()..color = Colors.green..style = PaintingStyle.stroke..strokeWidth = 2);

      _drawText(canvas, 'EMF', Offset(35, graphY - 50), Colors.green, 11);
      _drawText(canvas, '${emfMax.toStringAsFixed(2)} V (max)', Offset(size.width - 100, graphY - 50), AppColors.muted, 10);
    }

    // Force arrows (motor mode)
    if (isMotorMode) {
      final forceScale = 30.0;
      final coilX1 = centerX + radius * 0.75 * math.cos(rotorAngle);
      final coilY1 = centerY + radius * 0.75 * math.sin(rotorAngle);
      final forceDir = rotorAngle + math.pi / 2;

      canvas.drawLine(Offset(coilX1, coilY1), Offset(coilX1 + forceScale * math.cos(forceDir), coilY1 + forceScale * math.sin(forceDir)), Paint()..color = Colors.green..strokeWidth = 3);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _MotorGeneratorPainter oldDelegate) => true;
}
