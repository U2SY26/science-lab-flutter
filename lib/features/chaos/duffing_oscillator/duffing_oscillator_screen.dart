import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DuffingOscillatorScreen extends StatefulWidget {
  const DuffingOscillatorScreen({super.key});
  @override
  State<DuffingOscillatorScreen> createState() => _DuffingOscillatorScreenState();
}

class _DuffingOscillatorScreenState extends State<DuffingOscillatorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _drivingForce = 0.3;
  double _damping = 0.2;
  double _x = 0, _dx = 0;

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
      final dt = 0.016;
      final ddx = _drivingForce * math.cos(_time) - _damping * _dx - _x - _x * _x * _x;
      _dx += ddx * dt;
      _x += _dx * dt;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _drivingForce = 0.3; _damping = 0.2; _x = 0; _dx = 0;
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
          Text('카오스/복잡계 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('더핑 진동자', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스/복잡계 시뮬레이션',
          title: '더핑 진동자',
          formula: 'ẍ + δẋ + αx + βx³ = γcos(ωt)',
          formulaDescription: '강제 더핑 진동자에서 카오스를 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DuffingOscillatorScreenPainter(
                time: _time,
                drivingForce: _drivingForce,
                damping: _damping,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '구동력 γ',
                value: _drivingForce,
                min: 0,
                max: 1,
                step: 0.01,
                defaultValue: 0.3,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _drivingForce = v),
              ),
              advancedControls: [
            SimSlider(
                label: '감쇠 δ',
                value: _damping,
                min: 0,
                max: 1,
                step: 0.01,
                defaultValue: 0.2,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _damping = v),
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
          _V('x', _x.toStringAsFixed(3)),
          _V('ẋ', _dx.toStringAsFixed(3)),
          _V('γ', _drivingForce.toStringAsFixed(2)),
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

class _DuffingOscillatorScreenPainter extends CustomPainter {
  final double time;
  final double drivingForce;
  final double damping;

  _DuffingOscillatorScreenPainter({
    required this.time,
    required this.drivingForce,
    required this.damping,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 1 || size.height < 1) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Layout: phase portrait (top ~70%), potential curve (bottom ~25%), gap 5%
    final phaseH = size.height * 0.68;
    final potTop = size.height * 0.74;
    final potH = size.height * 0.22;
    const double pad = 24.0;
    final plotW = size.width - pad * 2;

    // Axes for phase portrait
    final axisPaint = Paint()..color = AppColors.simGrid..strokeWidth = 0.8;
    // x-axis at center of phase plot
    canvas.drawLine(Offset(pad, phaseH / 2), Offset(pad + plotW, phaseH / 2), axisPaint);
    // y-axis at center
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, phaseH), axisPaint);

    // Map phase (x, dx) to canvas coords
    // x range: -2..2, dx range: -2..2
    const double xRange = 2.2, dxRange = 2.2;
    Offset toPhase(double x, double dx) => Offset(
      pad + (x + xRange) / (2 * xRange) * plotW,
      phaseH / 2 - dx / dxRange * (phaseH / 2 - 4),
    );

    // Generate trail: integrate Duffing backwards from current time to build history
    const int trailLen = 1500;
    const double dt = 0.008;
    // Start from a fixed initial condition and integrate forward to time
    double px = 0.5, pdx = 0.0;
    final totalSteps = (time / dt).toInt();
    // Warm up with fast loop
    const int warmup = 200;
    for (int i = 0; i < warmup; i++) {
      final ddx = drivingForce * math.cos(i * dt) - damping * pdx - px - px * px * px;
      pdx += ddx * dt;
      px += pdx * dt;
    }
    // Collect trail
    final trail = <Offset>[];
    for (int i = 0; i < totalSteps % 3000 + trailLen; i++) {
      final t = (warmup + i) * dt;
      final ddx = drivingForce * math.cos(t) - damping * pdx - px - px * px * px;
      pdx += ddx * dt;
      px += pdx * dt;
      if (i >= totalSteps % 3000) {
        trail.add(toPhase(px.clamp(-xRange, xRange), pdx.clamp(-dxRange, dxRange)));
      }
    }

    // Draw trail with age-based color: old=muted, recent=cyan, tip=white
    if (trail.length >= 2) {
      for (int i = 0; i < trail.length - 1; i++) {
        final t = i / trail.length.toDouble();
        Color col;
        if (t < 0.5) {
          col = Color.lerp(AppColors.muted.withValues(alpha: 0.2),
              AppColors.accent.withValues(alpha: 0.6), t * 2)!;
        } else {
          col = Color.lerp(AppColors.accent.withValues(alpha: 0.6),
              Colors.white.withValues(alpha: 0.9), (t - 0.5) * 2)!;
        }
        canvas.drawLine(trail[i], trail[i + 1],
            Paint()..color = col..strokeWidth = 0.9..style = PaintingStyle.stroke);
      }
      // Current point
      canvas.drawCircle(trail.last, 3, Paint()..color = Colors.white);
    }

    // Poincaré section dots: record x, dx when cos(t)=1 (t = 2πn)
    final sectionPaint = Paint()..color = AppColors.accent2.withValues(alpha: 0.7);
    double sx = 0.5, sdx = 0.0;
    for (int i = 0; i < warmup; i++) {
      final ddx2 = drivingForce * math.cos(i * dt) - damping * sdx - sx - sx * sx * sx;
      sdx += ddx2 * dt;
      sx += sdx * dt;
    }
    int sectionCount = 0;
    for (int i = 0; i < 8000 && sectionCount < 200; i++) {
      final t0 = (warmup + i) * dt;
      final t1 = (warmup + i + 1) * dt;
      final ddx2 = drivingForce * math.cos(t0) - damping * sdx - sx - sx * sx * sx;
      sdx += ddx2 * dt;
      sx += sdx * dt;
      // Detect crossing of t = 2πn (when cos transitions through 1)
      if (math.sin(t0) > 0 && math.sin(t1) <= 0) {
        final pt = toPhase(sx.clamp(-xRange, xRange), sdx.clamp(-dxRange, dxRange));
        canvas.drawCircle(pt, 2, sectionPaint);
        sectionCount++;
      }
    }

    // Phase portrait labels
    final xLabelTp = TextPainter(
      text: const TextSpan(text: 'x', style: TextStyle(color: AppColors.muted, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    xLabelTp.paint(canvas, Offset(pad + plotW + 2, phaseH / 2 - 6));
    final dxLabelTp = TextPainter(
      text: const TextSpan(text: 'ẋ', style: TextStyle(color: AppColors.muted, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    dxLabelTp.paint(canvas, Offset(size.width / 2 + 3, 2));

    // Double-well potential V(x) = -x²/2 + x⁴/4
    final potPaint = Paint()..color = AppColors.accent.withValues(alpha: 0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final potPath = Path();
    const int potPts = 80;
    const double potXRange = 2.0;
    double minV = double.infinity, maxV = double.negativeInfinity;
    for (int i = 0; i <= potPts; i++) {
      final xp = -potXRange + i * 2 * potXRange / potPts;
      final v = -xp * xp / 2 + xp * xp * xp * xp / 4;
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final potVRange = maxV - minV;
    bool first = true;
    for (int i = 0; i <= potPts; i++) {
      final xp = -potXRange + i * 2 * potXRange / potPts;
      final v = -xp * xp / 2 + xp * xp * xp * xp / 4;
      final cx2 = pad + (xp + potXRange) / (2 * potXRange) * plotW;
      final cy2 = potVRange > 0 ? potTop + potH - (v - minV) / potVRange * potH * 0.9 : potTop + potH / 2;
      if (first) { potPath.moveTo(cx2, cy2); first = false; }
      else { potPath.lineTo(cx2, cy2); }
    }
    canvas.drawPath(potPath, potPaint);

    // Mark equilibria (wells) at x=±1
    for (final wellX in [-1.0, 1.0]) {
      final v = -wellX * wellX / 2 + wellX * wellX * wellX * wellX / 4;
      final cx2 = pad + (wellX + potXRange) / (2 * potXRange) * plotW;
      final cy2 = potVRange > 0 ? potTop + potH - (v - minV) / potVRange * potH * 0.9 : potTop + potH / 2;
      canvas.drawCircle(Offset(cx2, cy2), 4, Paint()..color = AppColors.accent2);
    }

    // Potential label
    final potLabel = TextPainter(
      text: const TextSpan(text: 'V(x) = -x²/2 + x⁴/4', style: TextStyle(color: AppColors.muted, fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    potLabel.paint(canvas, Offset((size.width - potLabel.width) / 2, potTop - 1));
  }

  @override
  bool shouldRepaint(covariant _DuffingOscillatorScreenPainter oldDelegate) => true;
}
