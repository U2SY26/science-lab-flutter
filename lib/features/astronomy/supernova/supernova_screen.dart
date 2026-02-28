import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class SupernovaScreen extends StatefulWidget {
  const SupernovaScreen({super.key});
  @override
  State<SupernovaScreen> createState() => _SupernovaScreenState();
}

class _SupernovaScreenState extends State<SupernovaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _progenitorMass = 15;
  
  String _type = "II"; double _remnantMass = 1.4;

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
      _type = _progenitorMass > 40 ? "Ib/c" : "II";
      _remnantMass = _progenitorMass < 25 ? 1.4 : _progenitorMass * 0.1;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _progenitorMass = 15.0;
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
          Text('천문학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('초신성 유형', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '초신성 유형',
          formula: 'E = 10^44 J',
          formulaDescription: '다양한 초신성 유형과 폭발 과정을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SupernovaScreenPainter(
                time: _time,
                progenitorMass: _progenitorMass,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '전구체 질량 (M☉)',
                value: _progenitorMass,
                min: 8,
                max: 60,
                step: 1,
                defaultValue: 15,
                formatValue: (v) => v.toStringAsFixed(0) + ' M☉',
                onChanged: (v) => setState(() => _progenitorMass = v),
              ),
              
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
          _V('유형', _type),
          _V('잔해', _remnantMass.toStringAsFixed(1) + ' M☉'),
          _V('질량', _progenitorMass.toStringAsFixed(0) + ' M☉'),
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

class _SupernovaScreenPainter extends CustomPainter {
  final double time;
  final double progenitorMass;

  _SupernovaScreenPainter({
    required this.time,
    required this.progenitorMass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // Split canvas: left = Type Ia, right = Type II
    final midX = size.width / 2;
    final topH = size.height * 0.70; // upper scene area
    final lcTop = size.height * 0.72; // light curve area

    // Divider
    canvas.drawLine(Offset(midX, 0), Offset(midX, topH),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    // Background stars
    final rng = math.Random(99);
    for (int i = 0; i < 50; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * topH;
      canvas.drawCircle(Offset(sx, sy), rng.nextDouble() * 0.9 + 0.2,
          Paint()..color = Colors.white.withValues(alpha: rng.nextDouble() * 0.4 + 0.1));
    }

    // ---- LEFT: Type Ia ----
    _drawLabel(canvas, 'Type Ia', Offset(6, 6), const Color(0xFF00D4FF), 10, bold: true);
    _drawLabel(canvas, 'WD + 동반성 강착', Offset(6, 18), const Color(0xFF5A8A9A), 8);

    final iaPhase = (time * 0.25) % 1.0; // 0→1 cycle
    final iaX = midX * 0.35;
    final iaY = topH * 0.45;
    // Red giant companion
    final rgX = midX * 0.72;
    final rgY = topH * 0.45;
    canvas.drawCircle(Offset(rgX, rgY), 22,
        Paint()..color = const Color(0xFFFF4400).withValues(alpha: 0.8));
    canvas.drawCircle(Offset(rgX, rgY), 22,
        Paint()..color = const Color(0xFFFF8844).withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

    if (iaPhase < 0.6) {
      // Accretion flow
      final flowPath = Path();
      flowPath.moveTo(rgX - 14, rgY);
      flowPath.cubicTo(rgX - 30, rgY - 20, iaX + 30, rgY - 20, iaX + 10, iaY);
      canvas.drawPath(flowPath,
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)
            ..strokeWidth = 3..style = PaintingStyle.stroke);
      // Accretion disk
      canvas.drawOval(
        Rect.fromCenter(center: Offset(iaX, iaY), width: 34, height: 10),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.5),
      );
      // White dwarf
      canvas.drawCircle(Offset(iaX, iaY), 8,
          Paint()..color = const Color(0xFFCCEEFF));
      canvas.drawCircle(Offset(iaX, iaY), 8,
          Paint()..color = const Color(0xFF88CCFF).withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      _drawLabel(canvas, 'WD', Offset(iaX - 8, iaY + 12), const Color(0xFFCCEEFF), 8);
      _drawLabel(canvas, '적색거성', Offset(rgX - 14, rgY + 26), const Color(0xFFFF8844), 8);
    } else {
      // Explosion
      final expPhase = (iaPhase - 0.6) / 0.4;
      final expR = expPhase * midX * 0.45;
      for (int ring = 0; ring < 3; ring++) {
        final rr = expR * (1 - ring * 0.15);
        final alpha = (1 - expPhase) * (0.7 - ring * 0.2);
        canvas.drawCircle(Offset(iaX, iaY), rr,
            Paint()..color = const Color(0xFFFF8800).withValues(alpha: alpha.clamp(0, 1))
              ..style = PaintingStyle.stroke..strokeWidth = 2 + ring.toDouble());
      }
      // Ejecta
      for (int e = 0; e < 12; e++) {
        final angle = e * math.pi * 2 / 12;
        final er = expR * 0.8;
        canvas.drawCircle(
          Offset(iaX + er * math.cos(angle), iaY + er * math.sin(angle)),
          2.5, Paint()..color = const Color(0xFFFFCC44).withValues(alpha: (1 - expPhase).clamp(0, 1)));
      }
      canvas.drawCircle(Offset(iaX, iaY), 8 * (1 - expPhase * 0.5),
          Paint()..color = Colors.white.withValues(alpha: (1 - expPhase).clamp(0, 1))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    // ---- RIGHT: Type II ----
    _drawLabel(canvas, 'Type II', Offset(midX + 6, 6), const Color(0xFFFF6B35), 10, bold: true);
    _drawLabel(canvas, '핵붕괴 초신성', Offset(midX + 6, 18), const Color(0xFF5A8A9A), 8);

    final iiPhase = (time * 0.25 + 0.5) % 1.0;
    final iiX = midX + (size.width - midX) * 0.45;
    final iiY = topH * 0.45;
    final iiR = 30.0 + (progenitorMass - 8) * 0.6;

    if (iiPhase < 0.55) {
      // Pre-explosion: onion layers
      final layerData = [
        [1.0, const Color(0xFF1A6FA0)],    // H envelope
        [0.72, const Color(0xFF2DA86B)],   // He
        [0.50, const Color(0xFFE8A020)],   // C/O
        [0.32, const Color(0xFFD05010)],   // O/Ne
        [0.18, const Color(0xFF8A4A10)],   // Si
        [0.08, const Color(0xFF606070)],   // Fe core
      ];
      for (final layer in layerData) {
        final r = iiR * (layer[0] as double);
        canvas.drawCircle(Offset(iiX, iiY), r, Paint()..color = (layer[1] as Color));
        canvas.drawCircle(Offset(iiX, iiY), r,
            Paint()..color = Colors.white.withValues(alpha: 0.1)
              ..style = PaintingStyle.stroke..strokeWidth = 0.6);
      }
      // Pulsing Fe core collapse indicator
      final pulse = math.sin(time * 8) * 0.3 + 0.7;
      canvas.drawCircle(Offset(iiX, iiY), iiR * 0.08 * pulse,
          Paint()..color = Colors.white.withValues(alpha: 0.8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      _drawLabel(canvas, 'Fe核', Offset(iiX - 8, iiY - 5), const Color(0xFFE0F4FF), 7);
    } else {
      // Explosion: shockwave propagating out
      final expPhase = (iiPhase - 0.55) / 0.45;
      final shockR = expPhase * iiR * 2.5;
      // Remnant core (neutron star)
      canvas.drawCircle(Offset(iiX, iiY), 6,
          Paint()..color = const Color(0xFF808090));
      // Expanding ejecta shell
      for (int ring = 0; ring < 4; ring++) {
        final rr = shockR * (1 - ring * 0.08);
        final alpha = (1 - expPhase) * (0.6 - ring * 0.12);
        final col = ring == 0 ? const Color(0xFFFFCC44) : const Color(0xFFFF6B35);
        canvas.drawCircle(Offset(iiX, iiY), rr.clamp(0, iiR * 2.8),
            Paint()..color = col.withValues(alpha: alpha.clamp(0, 1))
              ..style = PaintingStyle.stroke..strokeWidth = 3.0 - ring * 0.5);
      }
      // Filaments
      for (int f = 0; f < 10; f++) {
        final angle = f * math.pi * 2 / 10 + time;
        final fr = shockR * (0.7 + (f % 3) * 0.1);
        canvas.drawLine(
          Offset(iiX + fr * 0.4 * math.cos(angle), iiY + fr * 0.4 * math.sin(angle)),
          Offset(iiX + fr * math.cos(angle).clamp(-iiR * 2.5, iiR * 2.5),
                 iiY + fr * math.sin(angle).clamp(-iiR * 2.5, iiR * 2.5)),
          Paint()..color = const Color(0xFFFF8844).withValues(alpha: (1 - expPhase * 0.7).clamp(0, 1))
            ..strokeWidth = 1.0,
        );
      }
    }

    // ---- Light Curve (bottom) ----
    canvas.drawRect(Rect.fromLTWH(0, lcTop, size.width, size.height - lcTop),
        Paint()..color = const Color(0xFF050D12));
    final lcH = size.height - lcTop - 8;
    final lcPadL = 8.0, lcPadR = 8.0;

    _drawLabel(canvas, '광도 곡선', Offset(size.width / 2 - 18, lcTop + 2), const Color(0xFF5A8A9A), 8);

    // Draw Ia curve (symmetric peak, quick decline)
    final iaPath = Path();
    for (int x = 0; x <= 100; x++) {
      final t2 = x / 100.0;
      double lum;
      if (t2 < 0.2) { lum = t2 / 0.2; }
      else { lum = math.exp(-(t2 - 0.2) * 4); }
      final px = lcPadL + t2 * (midX - lcPadL - lcPadR / 2);
      final py = lcTop + lcH - lum * lcH * 0.85;
      if (x == 0) { iaPath.moveTo(px, py); } else { iaPath.lineTo(px, py); }
    }
    canvas.drawPath(iaPath, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.9)
        ..strokeWidth = 1.8..style = PaintingStyle.stroke);

    // Draw II curve (plateau)
    final iiPath = Path();
    for (int x = 0; x <= 100; x++) {
      final t2 = x / 100.0;
      double lum;
      if (t2 < 0.1) { lum = t2 / 0.1 * 0.85; }
      else if (t2 < 0.55) { lum = 0.85 - (t2 - 0.1) * 0.15; } // plateau
      else { lum = math.exp(-(t2 - 0.55) * 5) * 0.78; }
      final px = midX + lcPadL / 2 + t2 * (size.width - midX - lcPadL - lcPadR);
      final py = lcTop + lcH - lum * lcH * 0.85;
      if (x == 0) { iiPath.moveTo(px, py); } else { iiPath.lineTo(px, py); }
    }
    canvas.drawPath(iiPath, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.9)
        ..strokeWidth = 1.8..style = PaintingStyle.stroke);

    // Animate current time marker on both curves
    final tFrac = (time * 0.15) % 1.0;
    final iaMarkerX = lcPadL + tFrac * (midX - lcPadL - lcPadR / 2);
    canvas.drawLine(Offset(iaMarkerX, lcTop + 2), Offset(iaMarkerX, lcTop + lcH),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.5)..strokeWidth = 1);
    final iiMarkerX = midX + lcPadL / 2 + tFrac * (size.width - midX - lcPadL - lcPadR);
    canvas.drawLine(Offset(iiMarkerX, lcTop + 2), Offset(iiMarkerX, lcTop + lcH),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)..strokeWidth = 1);
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _SupernovaScreenPainter oldDelegate) => true;
}
