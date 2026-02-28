import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class SpecificHeatScreen extends StatefulWidget {
  const SpecificHeatScreen({super.key});
  @override
  State<SpecificHeatScreen> createState() => _SpecificHeatScreenState();
}

class _SpecificHeatScreenState extends State<SpecificHeatScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _mass = 1;
  double _specificHeat = 4186;
  double _heat = 0, _deltaT = 10;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!_isRunning) return;
    setState(() {
      _time += 0.016;
      _heat = _mass * _specificHeat * _deltaT;
      _deltaT = 10 + 5 * math.sin(_time);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _mass = 1.0; _specificHeat = 4186.0;
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
          Text('물리 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('비열 용량', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '비열 용량',
          formula: 'Q = mcΔT',
          formulaDescription: '다양한 물질의 비열 용량을 비교합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SpecificHeatScreenPainter(
                time: _time,
                mass: _mass,
                specificHeat: _specificHeat,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '질량 (kg)',
                value: _mass,
                min: 0.1,
                max: 10,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' kg',
                onChanged: (v) => setState(() => _mass = v),
              ),
              advancedControls: [
            SimSlider(
                label: '비열 (J/kg·K)',
                value: _specificHeat,
                min: 100,
                max: 5000,
                step: 100,
                defaultValue: 4186,
                formatValue: (v) => v.toStringAsFixed(0) + ' J/kg·K',
                onChanged: (v) => setState(() => _specificHeat = v),
              ),
              ],
            ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(children: [
          _V('Q', (_heat / 1000).toStringAsFixed(1) + ' kJ'),
          _V('ΔT', _deltaT.toStringAsFixed(1) + ' K'),
          _V('c', _specificHeat.toStringAsFixed(0)),
                ]),
              ),
            ],
          ),
          buttons: SimButtonGroup(expanded: true, buttons: [
            SimButton(
              label: _isRunning ? '정지' : '재생',
              icon: _isRunning ? Icons.pause : Icons.play_arrow,
              isPrimary: true,
              onPressed: () { HapticFeedback.selectionClick(); setState(() => _isRunning = !_isRunning); },
            ),
            SimButton(label: '리셋', icon: Icons.refresh, onPressed: _reset),
          ]),
        ),
      ),
    );
  }
}

class _V extends StatelessWidget {
  final String label, value;
  const _V(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
  ]));
}

class _SpecificHeatScreenPainter extends CustomPainter {
  final double time;
  final double mass;
  final double specificHeat;

  _SpecificHeatScreenPainter({
    required this.time,
    required this.mass,
    required this.specificHeat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Grid
    final gridPaint = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.4)..strokeWidth = 0.5;
    for (double x = 0; x < w; x += 30) { canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint); }
    for (double y = 0; y < h; y += 30) { canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint); }

    // Accumulated time for temperature rise
    final elapsed = time;
    // Water (high c): slow rise; Metal (low c): fast rise
    // Water: c=4186, Metal: c~450 (iron)
    final waterC = specificHeat;
    final metalC = 450.0;
    final heatRate = 500.0; // J/s
    final waterDeltaT = (heatRate * elapsed / (mass * waterC)).clamp(0.0, 80.0);
    final metalDeltaT = (heatRate * elapsed / (mass * metalC)).clamp(0.0, 80.0);

    // --- Two containers side by side ---
    final contW = w * 0.28;
    final contH = h * 0.32;
    final contBot = h * 0.70;
    final waterCx = w * 0.27;
    final metalCx = w * 0.73;

    // Flame glow under each container
    void drawFlame(double cx) {
      canvas.drawCircle(
        Offset(cx, contBot + 16),
        20,
        Paint()
          ..color = const Color(0xFFFF6B35).withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawCircle(
        Offset(cx, contBot + 12),
        10,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Flame tip
      final flamePath = Path()
        ..moveTo(cx - 8, contBot + 18)
        ..quadraticBezierTo(cx, contBot + 2, cx + 8, contBot + 18)
        ..close();
      canvas.drawPath(flamePath, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7));
      final flamePath2 = Path()
        ..moveTo(cx - 4, contBot + 16)
        ..quadraticBezierTo(cx, contBot + 6, cx + 4, contBot + 16)
        ..close();
      canvas.drawPath(flamePath2, Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.6));
    }
    drawFlame(waterCx);
    drawFlame(metalCx);

    // Container fill (liquid/solid color tinted by temperature)
    void drawContainer(double cx, double deltaT, Color baseColor, String label, String subLabel) {
      final tempFrac = (deltaT / 80.0).clamp(0.0, 1.0);
      final fillH = contH * 0.85;
      final fillTop = contBot - fillH;

      // Container body
      canvas.drawRect(
        Rect.fromLTWH(cx - contW / 2, contBot - fillH, contW, fillH),
        Paint()..color = Color.lerp(
          baseColor.withValues(alpha: 0.25),
          const Color(0xFFFF6B35).withValues(alpha: 0.4),
          tempFrac,
        )!,
      );
      canvas.drawRect(
        Rect.fromLTWH(cx - contW / 2, contBot - fillH, contW, fillH),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke,
      );

      // Molecular motion particles (vibrate faster at higher temp)
      final rng = math.Random(42);
      final numParticles = 12;
      for (int i = 0; i < numParticles; i++) {
        final baseX = cx - contW * 0.4 + rng.nextDouble() * contW * 0.8;
        final baseY = fillTop + 8 + rng.nextDouble() * (fillH - 16);
        final vibAmp = 1.0 + tempFrac * 4.0;
        final vibPhase = time * (3 + i * 0.5);
        final px = baseX + vibAmp * math.sin(vibPhase + i);
        final py = baseY + vibAmp * math.cos(vibPhase * 1.3 + i);
        canvas.drawCircle(
          Offset(px, py),
          1.8,
          Paint()..color = baseColor.withValues(alpha: 0.5 + tempFrac * 0.4),
        );
      }

      // Thermometer
      final tmX = cx + contW / 2 + 10;
      final tmBot2 = contBot - 4;
      final tmTop2 = contBot - contH * 0.9;
      final tmH = tmBot2 - tmTop2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(tmX - 3, tmTop2, 6, tmH), const Radius.circular(3)),
        Paint()..color = const Color(0xFF1A3040),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(tmX - 3, tmTop2, 6, tmH), const Radius.circular(3)),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..strokeWidth = 1..style = PaintingStyle.stroke,
      );
      // Mercury column
      final mercH = tmH * (0.1 + tempFrac * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tmX - 2, tmBot2 - mercH, 4, mercH),
          const Radius.circular(2),
        ),
        Paint()..color = Color.lerp(const Color(0xFF00D4FF), const Color(0xFFFF6B35), tempFrac)!,
      );
      canvas.drawCircle(Offset(tmX, tmBot2), 4, Paint()..color = const Color(0xFFFF6B35));

      // Labels
      _drawLabel(canvas, label, Offset(cx, fillTop - 14), baseColor, 10, bold: true);
      _drawLabel(canvas, subLabel, Offset(cx, fillTop - 26), const Color(0xFF5A8A9A), 8);
      _drawLabel(canvas, '+${deltaT.toStringAsFixed(1)}K', Offset(tmX + 18, tmTop2 + tmH * 0.5), const Color(0xFFE0F4FF), 9);
    }

    drawContainer(waterCx, waterDeltaT, const Color(0xFF00D4FF), '물 (H₂O)', 'c = ${specificHeat.toStringAsFixed(0)} J/kg·K');
    drawContainer(metalCx, metalDeltaT, const Color(0xFF64FF8C), '금속 (Fe)', 'c = 450 J/kg·K');

    // Equal heat input arrows
    _drawLabel(canvas, '동일 열량 Q', Offset(w / 2, contBot + 32), const Color(0xFFFF6B35).withValues(alpha: 0.8), 9);

    // --- Temperature vs time graph (bottom) ---
    final gLeft = w * 0.06;
    final gBot = h * 0.97;
    final gW = w * 0.88;
    final gH = h * 0.18;
    final gTop = gBot - gH;

    // Axes
    canvas.drawLine(Offset(gLeft, gBot), Offset(gLeft + gW, gBot), Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(gLeft, gTop), Offset(gLeft, gBot), Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _drawLabel(canvas, 't', Offset(gLeft + gW + 8, gBot - 4), const Color(0xFF5A8A9A), 8);
    _drawLabel(canvas, 'T', Offset(gLeft + 4, gTop + 4), const Color(0xFF5A8A9A), 8);

    // Water curve (gentle slope)
    final waterPath = Path()..moveTo(gLeft, gBot);
    for (double t2 = 0; t2 <= math.min(elapsed, 60.0); t2 += 1) {
      final dT = (heatRate * t2 / (mass * waterC)).clamp(0.0, 80.0);
      final px = gLeft + (t2 / 60.0) * gW;
      final py = gBot - (dT / 80.0) * gH;
      waterPath.lineTo(px, py);
    }
    canvas.drawPath(waterPath, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Metal curve (steeper slope)
    final metalPath = Path()..moveTo(gLeft, gBot);
    for (double t2 = 0; t2 <= math.min(elapsed, 60.0); t2 += 1) {
      final dT = (heatRate * t2 / (mass * metalC)).clamp(0.0, 80.0);
      final px = gLeft + (t2 / 60.0) * gW;
      final py = gBot - (dT / 80.0) * gH;
      metalPath.lineTo(px, py);
    }
    canvas.drawPath(metalPath, Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    _drawLabel(canvas, '물', Offset(gLeft + gW * 0.3, gBot - gH * 0.25), const Color(0xFF00D4FF), 8);
    _drawLabel(canvas, '금속', Offset(gLeft + gW * 0.15, gBot - gH * 0.7), const Color(0xFF64FF8C), 8);

    // Q = mcΔT
    _drawLabel(canvas, 'Q = mcΔT', Offset(w * 0.5, h * 0.74), const Color(0xFFE0F4FF), 10);

    // Title
    _drawLabel(canvas, '비열 용량 비교', Offset(w / 2, 14), const Color(0xFF00D4FF), 12, bold: true);
  }

  void _drawLabel(Canvas canvas, String text, Offset center, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _SpecificHeatScreenPainter oldDelegate) => true;
}
