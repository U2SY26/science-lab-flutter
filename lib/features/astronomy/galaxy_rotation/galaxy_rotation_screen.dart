import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class GalaxyRotationScreen extends StatefulWidget {
  const GalaxyRotationScreen({super.key});
  @override
  State<GalaxyRotationScreen> createState() => _GalaxyRotationScreenState();
}

class _GalaxyRotationScreenState extends State<GalaxyRotationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _darkMatterRatio = 5;
  
  double _vObs = 220, _vKep = 50;

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
      _vKep = 220 / math.sqrt(1 + _darkMatterRatio);
      _vObs = 220;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _darkMatterRatio = 5.0;
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
          const Text('은하 회전 곡선', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '은하 회전 곡선',
          formula: 'v(r) = √(GM(r)/r)',
          formulaDescription: '은하 회전 곡선과 암흑 물질의 증거를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _GalaxyRotationScreenPainter(
                time: _time,
                darkMatterRatio: _darkMatterRatio,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '암흑물질 비율',
                value: _darkMatterRatio,
                min: 0,
                max: 20,
                step: 0.1,
                defaultValue: 5,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _darkMatterRatio = v),
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
          _V('v_obs', _vObs.toStringAsFixed(0) + ' km/s'),
          _V('v_kep', _vKep.toStringAsFixed(0) + ' km/s'),
          _V('DM', _darkMatterRatio.toStringAsFixed(1) + 'x'),
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

class _GalaxyRotationScreenPainter extends CustomPainter {
  final double time;
  final double darkMatterRatio;

  _GalaxyRotationScreenPainter({
    required this.time,
    required this.darkMatterRatio,
  });

  void _label(Canvas canvas, String text, Offset pos, Color col, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  // Observed flat rotation curve: v_obs(r) = v0 * tanh(r / r_core)^0.5 * (1 + dm)^0.3
  // tanh via exponentials (dart:math has no tanh)
  double _tanh(double x) {
    final e2 = math.exp(2 * x);
    return (e2 - 1) / (e2 + 1);
  }

  double _vObs(double r, double dm) {
    final rCore = 0.15;
    return 220 * math.sqrt(_tanh(r / rCore)) * math.pow(1 + dm * 0.12, 0.3);
  }

  // Keplerian (no dark matter): v_kep(r) = v0 / sqrt(r/r0) for r > bulge
  double _vKep(double r) {
    if (r < 0.1) return 220 * math.sqrt(r / 0.1);
    return 220 / math.sqrt(r / 0.1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final split = size.width * 0.48; // left galaxy | right graph

    // ════════════════════════════════════════════
    // LEFT: Spiral galaxy top-down view
    // ════════════════════════════════════════════
    final gcx = split * 0.5;
    final gcy = size.height * 0.50;
    final maxR = math.min(split * 0.44, size.height * 0.44);

    // Dark matter halo glow
    if (darkMatterRatio > 0) {
      final haloAlpha = (darkMatterRatio / 20.0).clamp(0.0, 0.35);
      canvas.drawCircle(
          Offset(gcx, gcy),
          maxR * 1.15,
          Paint()
            ..color = const Color(0xFF4444AA).withValues(alpha: haloAlpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    }

    // Draw spiral arms (2 arms, each rotated 180°)
    final rng = math.Random(33);
    for (int arm = 0; arm < 2; arm++) {
      final armOffset = arm * math.pi;
      for (int i = 0; i < 120; i++) {
        final t = i / 120.0;
        // Logarithmic spiral: r = a * exp(b * theta)
        final theta = t * 3.5 * math.pi + armOffset;
        final r = maxR * (0.08 + 0.86 * t);
        final angularSpeed = _vObs(t, darkMatterRatio) / (r + 1) * 0.012;
        final animAngle = theta + time * angularSpeed;
        final x = gcx + r * math.cos(animAngle);
        final y = gcy + r * math.sin(animAngle) * 0.38; // elliptical projection
        final scatter = (rng.nextDouble() - 0.5) * maxR * 0.06;
        final sx = x + scatter * math.cos(animAngle + math.pi / 2);
        final sy = y + scatter * math.sin(animAngle + math.pi / 2) * 0.38;
        // Colour: bluer at outer arm, yellower at inner
        final warmFrac = 1.0 - t;
        final col = Color.fromARGB(
          (120 + 80 * t).round().clamp(0, 255),
          (120 + 135 * warmFrac).round().clamp(0, 255),
          (160 + 95 * t).round().clamp(0, 255),
          (200 * warmFrac + 255 * t * 0.3).round().clamp(0, 255),
        );
        canvas.drawCircle(Offset(sx, sy), 0.9 + t * 1.2, Paint()..color = col);
      }
    }

    // Central bulge
    canvas.drawCircle(
        Offset(gcx, gcy),
        maxR * 0.14,
        Paint()
          ..color = const Color(0xFFFFDD88).withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(
        Offset(gcx, gcy), maxR * 0.07, Paint()..color = const Color(0xFFFFEE99));

    // Orbit rings (a few reference circles)
    for (final frac in [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(gcx, gcy),
              width: maxR * 2 * frac,
              height: maxR * 2 * frac * 0.38),
          Paint()
            ..color = const Color(0xFF1A3040).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6);
    }

    // Animated star dots on different orbits
    final starRng = math.Random(77);
    for (int s = 0; s < 18; s++) {
      final orbitFrac = 0.15 + starRng.nextDouble() * 0.85;
      final orbitR = maxR * orbitFrac;
      final baseAngle = starRng.nextDouble() * 2 * math.pi;
      final speed = _vObs(orbitFrac, darkMatterRatio) / (orbitR + 1) * 0.018;
      final angle = baseAngle + time * speed;
      final sx = gcx + orbitR * math.cos(angle);
      final sy = gcy + orbitR * 0.38 * math.sin(angle);
      canvas.drawCircle(
          Offset(sx, sy),
          1.8,
          Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.75));
    }

    _label(canvas, '나선은하 (위에서)', Offset(4, 8), const Color(0xFF5A8A9A), 9);

    // ════════════════════════════════════════════
    // RIGHT: Rotation curve graph
    // ════════════════════════════════════════════
    final gLeft = split + 6;
    final gRight = size.width - 6.0;
    final gTop = size.height * 0.08;
    final gBottom = size.height * 0.92;
    final gW = gRight - gLeft;
    final gH = gBottom - gTop;

    // Background
    canvas.drawRect(
        Rect.fromLTWH(gLeft, gTop, gW, gH),
        Paint()..color = const Color(0xFF0A1520));
    canvas.drawRect(
        Rect.fromLTWH(gLeft, gTop, gW, gH),
        Paint()
          ..color = const Color(0xFF1A3040)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);

    // Axes
    final axisPaint = Paint()
      ..color = const Color(0xFF5A8A9A)
      ..strokeWidth = 0.8;
    canvas.drawLine(
        Offset(gLeft + 2, gBottom - 2), Offset(gRight - 2, gBottom - 2), axisPaint);
    canvas.drawLine(
        Offset(gLeft + 2, gTop + 2), Offset(gLeft + 2, gBottom - 2), axisPaint);

    _label(canvas, 'v (km/s)', Offset(gLeft + 3, gTop + 2),
        const Color(0xFF5A8A9A), 8);
    _label(canvas, 'r →', Offset(gRight - 18, gBottom - 12),
        const Color(0xFF5A8A9A), 8);

    // Scale: r 0..1 on x, v 0..280 km/s on y
    const vMax = 280.0;
    const rMin = 0.02;
    const rMax = 1.0;
    final innerLeft = gLeft + 2;
    final innerW = gW - 4;
    final innerH = gH - 4;

    double rToX(double r) =>
        innerLeft + (r - rMin) / (rMax - rMin) * innerW;
    double vToY(double v) =>
        gBottom - 2 - (v / vMax).clamp(0.0, 1.0) * innerH;

    // Dark matter highlight region (mismatch between Kep and Obs)
    final highlightPath = Path();
    highlightPath.moveTo(rToX(0.3), vToY(_vKep(0.3)));
    for (double r = 0.3; r <= rMax; r += 0.02) {
      highlightPath.lineTo(rToX(r), vToY(_vKep(r)));
    }
    for (double r = rMax; r >= 0.3; r -= 0.02) {
      highlightPath.lineTo(rToX(r), vToY(_vObs(r, darkMatterRatio)));
    }
    highlightPath.close();
    canvas.drawPath(
        highlightPath,
        Paint()
          ..color = const Color(0xFF4444AA).withValues(alpha: 0.18));

    // Keplerian curve (dashed orange)
    final kepPath = Path();
    bool kepStarted = false;
    for (double r = rMin; r <= rMax; r += 0.02) {
      final x = rToX(r);
      final y = vToY(_vKep(r));
      if (!kepStarted) {
        kepPath.moveTo(x, y);
        kepStarted = true;
      } else {
        kepPath.lineTo(x, y);
      }
    }
    // Draw as dashed
    const dashLen = 6.0;
    final kepMetrics = kepPath.computeMetrics();
    for (final metric in kepMetrics) {
      double dist = 0;
      while (dist < metric.length) {
        final seg = metric.extractPath(dist, dist + dashLen);
        canvas.drawPath(
            seg,
            Paint()
              ..color = const Color(0xFFFF6B35).withValues(alpha: 0.8)
              ..strokeWidth = 1.5
              ..style = PaintingStyle.stroke);
        dist += dashLen * 2;
      }
    }

    // Observed flat curve (solid cyan)
    final obsPath = Path();
    bool obsStarted = false;
    for (double r = rMin; r <= rMax; r += 0.015) {
      final x = rToX(r);
      final y = vToY(_vObs(r, darkMatterRatio));
      if (!obsStarted) {
        obsPath.moveTo(x, y);
        obsStarted = true;
      } else {
        obsPath.lineTo(x, y);
      }
    }
    canvas.drawPath(
        obsPath,
        Paint()
          ..color = const Color(0xFF00D4FF)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke);

    // Observation data points with error bars
    final dataRng = math.Random(42);
    for (int i = 2; i <= 9; i++) {
      final r = i / 10.0;
      final vMean = _vObs(r, darkMatterRatio);
      final err = 8 + dataRng.nextDouble() * 12;
      final x = rToX(r);
      final yMid = vToY(vMean);
      final yUp = vToY(vMean + err);
      final yDn = vToY(vMean - err);
      // Error bar
      canvas.drawLine(
          Offset(x, yUp),
          Offset(x, yDn),
          Paint()
            ..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)
            ..strokeWidth = 1.2);
      canvas.drawLine(
          Offset(x - 3, yUp), Offset(x + 3, yUp),
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..strokeWidth = 1);
      canvas.drawLine(
          Offset(x - 3, yDn), Offset(x + 3, yDn),
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..strokeWidth = 1);
      // Data point
      canvas.drawCircle(Offset(x, yMid), 2.5, Paint()..color = const Color(0xFF00D4FF));
    }

    // Y-axis ticks
    for (final v in [0, 100, 200]) {
      final y = vToY(v.toDouble());
      canvas.drawLine(Offset(gLeft + 2, y), Offset(gLeft + 6, y), axisPaint);
      _label(canvas, '$v', Offset(gLeft + 8, y - 5),
          const Color(0xFF5A8A9A), 7);
    }

    // Legend
    final legY = gTop + 6;
    canvas.drawLine(Offset(gLeft + 4, legY + 4), Offset(gLeft + 16, legY + 4),
        Paint()
          ..color = const Color(0xFF00D4FF)
          ..strokeWidth = 1.8);
    _label(canvas, '관측', Offset(gLeft + 18, legY), const Color(0xFF00D4FF), 8);

    canvas.drawLine(Offset(gLeft + 44, legY + 4), Offset(gLeft + 56, legY + 4),
        Paint()
          ..color = const Color(0xFFFF6B35)
          ..strokeWidth = 1.5);
    _label(canvas, '케플러 예측', Offset(gLeft + 58, legY),
        const Color(0xFFFF6B35), 8);

    // Dark matter label
    _label(canvas, '암흑물질 영역', Offset(gLeft + gW * 0.45, gTop + gH * 0.45),
        const Color(0xFF8888CC).withValues(alpha: 0.7), 8);

    _label(canvas, '암흑물질 비율: ${darkMatterRatio.toStringAsFixed(1)}x',
        Offset(gLeft + 4, gBottom - 14), const Color(0xFF5A8A9A), 8);
  }

  @override
  bool shouldRepaint(covariant _GalaxyRotationScreenPainter oldDelegate) =>
      true;
}
