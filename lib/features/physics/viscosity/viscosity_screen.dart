import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Fluid Viscosity simulation
class ViscosityScreen extends StatefulWidget {
  const ViscosityScreen({super.key});
  @override
  State<ViscosityScreen> createState() => _ViscosityScreenState();
}

class _ViscosityScreenState extends State<ViscosityScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double viscosity = 1.0; // Pa·s (water = 0.001, honey = 10)
  double sphereRadius = 0.01; // m
  double sphereDensity = 2500; // kg/m³ (glass)
  double fluidDensity = 1000; // kg/m³
  double sphereY = 0;
  double sphereVelocity = 0;
  bool isDropping = false;
  bool isKorean = true;

  double get gravity => 9.8;
  double get buoyantForce => (4 / 3) * math.pi * math.pow(sphereRadius, 3) * fluidDensity * gravity;
  double get weight => (4 / 3) * math.pi * math.pow(sphereRadius, 3) * sphereDensity * gravity;
  double get netForce => weight - buoyantForce;
  double get terminalVelocity => (2 * math.pow(sphereRadius, 2) * (sphereDensity - fluidDensity) * gravity) / (9 * viscosity);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(_update)..repeat();
  }

  void _update() {
    if (!isDropping) return;
    setState(() {
      final mass = (4 / 3) * math.pi * math.pow(sphereRadius, 3) * sphereDensity;
      final dragForce = 6 * math.pi * viscosity * sphereRadius * sphereVelocity;
      final acceleration = (netForce - dragForce) / mass;
      sphereVelocity += acceleration * 0.01;
      sphereY += sphereVelocity * 5;

      if (sphereY > 200) {
        sphereY = 0;
        sphereVelocity = 0;
        isDropping = false;
      }
    });
  }

  void _dropSphere() {
    setState(() {
      sphereY = 0;
      sphereVelocity = 0;
      isDropping = true;
    });
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
          Text(isKorean ? '점성' : 'Viscosity', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '유체역학' : 'Fluid Mechanics',
          title: isKorean ? '점성' : 'Viscosity',
          formula: 'Fd = 6πηrv',
          formulaDescription: isKorean ? '스토크스 법칙: 점성 유체 내 구의 항력. 점성이 높을수록 저항이 커집니다.' : "Stokes' Law: Drag on sphere in viscous fluid. Higher viscosity means more resistance.",
          simulation: CustomPaint(painter: _ViscosityPainter(viscosity: viscosity, sphereY: sphereY, sphereVelocity: sphereVelocity, terminalVelocity: terminalVelocity, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '점성 (η)' : 'Viscosity (η)', value: viscosity, min: 0.1, max: 10.0, defaultValue: 1.0, formatValue: (v) => '${v.toStringAsFixed(1)} Pa·s', onChanged: (v) => setState(() => viscosity = v)),
            const SizedBox(height: 12),
            Text(isKorean ? '유체 유형' : 'Fluid Type', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 4),
            PresetGroup(presets: [
              PresetButton(label: isKorean ? '물' : 'Water', isSelected: viscosity < 0.01, onPressed: () => setState(() => viscosity = 0.001)),
              PresetButton(label: isKorean ? '올리브유' : 'Olive Oil', isSelected: viscosity >= 0.08 && viscosity < 0.1, onPressed: () => setState(() => viscosity = 0.08)),
              PresetButton(label: isKorean ? '꿀' : 'Honey', isSelected: viscosity >= 2 && viscosity < 15, onPressed: () => setState(() => viscosity = 10.0)),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text(isKorean ? '현재 속도' : 'Current Velocity', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${sphereVelocity.toStringAsFixed(3)} m/s', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text(isKorean ? '종단 속도' : 'Terminal Velocity', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${terminalVelocity.toStringAsFixed(3)} m/s', style: TextStyle(color: AppColors.accent2, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            SimButtonGroup(expanded: true, buttons: [
              SimButton(label: isKorean ? '구 떨어뜨리기' : 'Drop Sphere', icon: Icons.arrow_downward, isPrimary: true, onPressed: _dropSphere),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _ViscosityPainter extends CustomPainter {
  final double viscosity, sphereY, sphereVelocity, terminalVelocity;
  final bool isKorean;

  _ViscosityPainter({required this.viscosity, required this.sphereY, required this.sphereVelocity, required this.terminalVelocity, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final tubeWidth = 80.0;
    final tubeTop = 30.0;
    final tubeBottom = size.height * 0.65;

    // Viscous fluid color based on viscosity
    final fluidColor = Color.lerp(Colors.lightBlue, Colors.amber.shade800, viscosity / 10)!;

    // Glass tube
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(centerX - tubeWidth / 2, tubeTop, tubeWidth, tubeBottom - tubeTop), const Radius.circular(5)), Paint()..color = fluidColor.withValues(alpha: 0.4));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(centerX - tubeWidth / 2, tubeTop, tubeWidth, tubeBottom - tubeTop), const Radius.circular(5)), Paint()..color = Colors.grey..style = PaintingStyle.stroke..strokeWidth = 3);

    // Falling sphere
    final sphereRadius = 15.0;
    final sphereCenterY = tubeTop + 20 + sphereY;
    if (sphereCenterY < tubeBottom - sphereRadius) {
      canvas.drawCircle(Offset(centerX, sphereCenterY), sphereRadius, Paint()..color = Colors.grey[700]!);
      canvas.drawCircle(Offset(centerX - 5, sphereCenterY - 5), 5, Paint()..color = Colors.white.withValues(alpha: 0.5));

      // Drag force arrow (if moving)
      if (sphereVelocity > 0.001) {
        final dragArrowLength = math.min(sphereVelocity * 200, 50.0);
        canvas.drawLine(Offset(centerX, sphereCenterY - sphereRadius), Offset(centerX, sphereCenterY - sphereRadius - dragArrowLength), Paint()..color = Colors.red..strokeWidth = 3);
        _drawText(canvas, 'Fd', Offset(centerX + 5, sphereCenterY - sphereRadius - dragArrowLength - 15), Colors.red, 10);

        // Velocity arrow
        final velArrowLength = math.min(sphereVelocity * 200, 50.0);
        canvas.drawLine(Offset(centerX + tubeWidth / 2 + 10, sphereCenterY), Offset(centerX + tubeWidth / 2 + 10, sphereCenterY + velArrowLength), Paint()..color = Colors.green..strokeWidth = 3);
        _drawText(canvas, 'v', Offset(centerX + tubeWidth / 2 + 15, sphereCenterY + velArrowLength / 2), Colors.green, 10);
      }
    }

    // Velocity profile (showing parabolic flow)
    final profileX = centerX + tubeWidth / 2 + 50;
    for (double y = tubeTop + 30; y < tubeBottom - 10; y += 15) {
      final distFromCenter = (y - (tubeTop + tubeBottom) / 2).abs();
      final maxDist = (tubeBottom - tubeTop) / 2;
      final velocityScale = 1 - (distFromCenter / maxDist) * (distFromCenter / maxDist);
      final arrowLength = 30 * velocityScale / viscosity.clamp(0.5, 5.0);
      if (arrowLength > 2) {
        canvas.drawLine(Offset(profileX, y), Offset(profileX + arrowLength, y), Paint()..color = Colors.cyan..strokeWidth = 2);
      }
    }
    _drawText(canvas, isKorean ? '속도 프로파일' : 'Velocity Profile', Offset(profileX - 20, tubeBottom + 5), AppColors.muted, 9);

    // Velocity vs time graph
    final graphY = size.height * 0.85;
    final graphWidth = size.width - 60;
    final graphHeight = 40.0;

    canvas.drawLine(Offset(30, graphY), Offset(30 + graphWidth, graphY), Paint()..color = AppColors.muted..strokeWidth = 1);
    canvas.drawLine(Offset(30, graphY - graphHeight), Offset(30, graphY + 5), Paint()..color = AppColors.muted..strokeWidth = 1);

    // Terminal velocity line
    canvas.drawLine(Offset(30, graphY - graphHeight * 0.8), Offset(30 + graphWidth, graphY - graphHeight * 0.8), Paint()..color = Colors.orange.withValues(alpha: 0.5)..strokeWidth = 1);
    _drawText(canvas, 'vt', Offset(30 + graphWidth + 5, graphY - graphHeight * 0.8 - 5), Colors.orange, 9);

    // Exponential approach curve
    final curvePath = Path();
    for (double x = 0; x <= graphWidth; x += 2) {
      final t = x / 50;
      final v = terminalVelocity * (1 - math.exp(-t * viscosity));
      final plotY = graphY - (graphHeight * 0.8 * v / terminalVelocity).clamp(0, graphHeight);
      if (x == 0) {
        curvePath.moveTo(30 + x, plotY);
      } else {
        curvePath.lineTo(30 + x, plotY);
      }
    }
    canvas.drawPath(curvePath, Paint()..color = Colors.cyan..style = PaintingStyle.stroke..strokeWidth = 2);

    _drawText(canvas, isKorean ? '시간' : 'Time', Offset(30 + graphWidth - 20, graphY + 8), AppColors.muted, 9);
    _drawText(canvas, 'v', Offset(15, graphY - graphHeight - 5), AppColors.muted, 9);

    // Fluid label
    _drawText(canvas, 'η = ${viscosity.toStringAsFixed(1)} Pa·s', Offset(centerX - 30, tubeBottom + 10), AppColors.muted, 10);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _ViscosityPainter oldDelegate) => true;
}
