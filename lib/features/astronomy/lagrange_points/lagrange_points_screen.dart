import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class LagrangePointsScreen extends StatefulWidget {
  const LagrangePointsScreen({super.key});
  @override
  State<LagrangePointsScreen> createState() => _LagrangePointsScreenState();
}

class _LagrangePointsScreenState extends State<LagrangePointsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _massRatio2 = 0.01;
  
  double _l1 = 0.99, _l2 = 1.01, _l3 = -1.0;

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
      final mu = _massRatio2 / (1 + _massRatio2);
      _l1 = 1 - math.pow(mu / 3, 1/3).toDouble();
      _l2 = 1 + math.pow(mu / 3, 1/3).toDouble();
      _l3 = -(1 + 5 * mu / 12);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _massRatio2 = 0.01;
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
          const Text('라그랑주 점', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '라그랑주 점',
          formula: 'L1-L5 equilibria',
          formulaDescription: '두 천체 시스템의 5개 라그랑주 점을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _LagrangePointsScreenPainter(
                time: _time,
                massRatio2: _massRatio2,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '질량 비 (m₂/m₁)',
                value: _massRatio2,
                min: 0.001,
                max: 0.5,
                step: 0.001,
                defaultValue: 0.01,
                formatValue: (v) => v.toStringAsFixed(3),
                onChanged: (v) => setState(() => _massRatio2 = v),
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
          _V('L1', _l1.toStringAsFixed(4) + ' AU'),
          _V('L2', _l2.toStringAsFixed(4) + ' AU'),
          _V('L3', _l3.toStringAsFixed(4) + ' AU'),
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

class _LagrangePointsScreenPainter extends CustomPainter {
  final double time;
  final double massRatio2;

  _LagrangePointsScreenPainter({
    required this.time,
    required this.massRatio2,
  });

  void _label(Canvas canvas, String text, Offset pos, Color col, double fs,
      {bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        center ? Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2) : pos);
  }

  // Draw a small cross marker for Lagrange points
  void _drawCross(Canvas canvas, Offset pos, Color col, double sz) {
    final p = Paint()
      ..color = col
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(pos.dx - sz, pos.dy), Offset(pos.dx + sz, pos.dy), p);
    canvas.drawLine(Offset(pos.dx, pos.dy - sz), Offset(pos.dx, pos.dy + sz), p);
  }

  // Draw equilateral potential contours (simplified lobes)
  void _drawContours(Canvas canvas, Size size, Offset sun, Offset earth,
      double orbitR, Paint p) {
    final cx = (sun.dx + earth.dx) / 2;
    final cy = (sun.dy + earth.dy) / 2;
    // Draw 3 simplified oval contours around each body and the system
    for (double scale in [0.22, 0.38, 0.55]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: sun, width: orbitR * scale * 0.9, height: orbitR * scale),
        p,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: earth,
            width: orbitR * scale * 0.25,
            height: orbitR * scale * 0.28),
        p,
      );
    }
    // Outer figure-8 lobe (very simplified)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: orbitR * 2.35,
          height: orbitR * 1.05),
      p,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final mu = massRatio2 / (1 + massRatio2);
    // L1, L2, L3 positions (normalized, sun at origin, earth at 1)
    final l1Norm = 1.0 - math.pow(mu / 3, 1.0 / 3.0).toDouble();
    final l2Norm = 1.0 + math.pow(mu / 3, 1.0 / 3.0).toDouble();
    final l3Norm = -(1.0 + 5 * mu / 12);

    final cx = size.width / 2;
    final cy = size.height * 0.48;

    // Orbit radius in pixels
    final orbitR = math.min(size.width * 0.36, size.height * 0.38);

    // Rotating angle for animation
    final rotAngle = time * 0.25;

    // Sun position (fixed at bary-centre for display simplicity, mass1 >> mass2)
    // Barycenter offset: sun is at -mu * a from barycentre
    final sunX = cx - mu * orbitR * math.cos(rotAngle);
    final sunY = cy - mu * orbitR * math.sin(rotAngle);
    final earthX = cx + (1 - mu) * orbitR * math.cos(rotAngle);
    final earthY = cy + (1 - mu) * orbitR * math.sin(rotAngle);

    final sunPos = Offset(sunX, sunY);
    final earthPos = Offset(earthX, earthY);

    // ── Potential contours (faint) ──
    _drawContours(
        canvas,
        size,
        sunPos,
        earthPos,
        orbitR,
        Paint()
          ..color = const Color(0xFF1A3040).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);

    // ── Orbit circle ──
    canvas.drawCircle(
      Offset(cx, cy),
      orbitR,
      Paint()
        ..color = const Color(0xFF1A3040)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // ── Lagrange points ──
    // L1 — between sun and earth
    final l1X = cx + l1Norm * orbitR * math.cos(rotAngle);
    final l1Y = cy + l1Norm * orbitR * math.sin(rotAngle);
    // L2 — beyond earth
    final l2X = cx + l2Norm * orbitR * math.cos(rotAngle);
    final l2Y = cy + l2Norm * orbitR * math.sin(rotAngle);
    // L3 — opposite side
    final l3X = cx + l3Norm * orbitR * math.cos(rotAngle);
    final l3Y = cy + l3Norm * orbitR * math.sin(rotAngle);
    // L4 — +60° from earth
    final l4X = cx + orbitR * math.cos(rotAngle + math.pi / 3);
    final l4Y = cy + orbitR * math.sin(rotAngle + math.pi / 3);
    // L5 — -60° from earth
    final l5X = cx + orbitR * math.cos(rotAngle - math.pi / 3);
    final l5Y = cy + orbitR * math.sin(rotAngle - math.pi / 3);

    // Unstable points: L1, L2, L3 (orange)
    for (final pos in [
      Offset(l1X, l1Y),
      Offset(l2X, l2Y),
      Offset(l3X, l3Y)
    ]) {
      canvas.drawCircle(pos, 5,
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.25));
      _drawCross(canvas, pos, const Color(0xFFFF6B35), 5);
    }

    // Stable points: L4, L5 (green) + trojan swarms
    for (final pos in [Offset(l4X, l4Y), Offset(l5X, l5Y)]) {
      canvas.drawCircle(pos, 7,
          Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.2));
      _drawCross(canvas, pos, const Color(0xFF64FF8C), 5);
    }

    // Trojan asteroid swarms around L4 and L5
    final rng = math.Random(55);
    for (final centre in [Offset(l4X, l4Y), Offset(l5X, l5Y)]) {
      for (int i = 0; i < 10; i++) {
        final angle = rng.nextDouble() * 2 * math.pi;
        final dist = 6 + rng.nextDouble() * 14;
        canvas.drawCircle(
          Offset(centre.dx + dist * math.cos(angle),
              centre.dy + dist * math.sin(angle)),
          1.2,
          Paint()
            ..color = const Color(0xFF64FF8C).withValues(alpha: 0.45),
        );
      }
    }

    // Small objects near L1, L2, L3 (unstable)
    for (final centre in [Offset(l1X, l1Y), Offset(l2X, l2Y), Offset(l3X, l3Y)]) {
      canvas.drawCircle(
        Offset(centre.dx + 3 * math.cos(time * 2.1),
            centre.dy + 3 * math.sin(time * 1.7)),
        1.5,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6),
      );
    }

    // ── Sun ──
    canvas.drawCircle(sunPos, 12,
        Paint()..color = const Color(0xFFFFDD44).withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(sunPos, 9, Paint()..color = const Color(0xFFFFDD44));
    _label(canvas, '태양', Offset(sunX - 8, sunY + 12),
        const Color(0xFFFFDD44), 8);

    // ── Earth ──
    canvas.drawCircle(earthPos, 6, Paint()..color = const Color(0xFF3A9EC5));
    canvas.drawCircle(
        earthPos, 6,
        Paint()
          ..color = const Color(0xFF00D4FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    _label(canvas, '지구', Offset(earthX - 8, earthY + 8),
        const Color(0xFF00D4FF), 8);

    // ── Lagrange point labels ──
    void lLabel(String text, Offset pt, Color col, String? mission) {
      _label(canvas, text, Offset(pt.dx + 7, pt.dy - 5), col, 9);
      if (mission != null) {
        _label(canvas, mission, Offset(pt.dx + 7, pt.dy + 5),
            col.withValues(alpha: 0.7), 7);
      }
    }

    lLabel('L1', Offset(l1X, l1Y), const Color(0xFFFF6B35), 'SOHO');
    lLabel('L2', Offset(l2X, l2Y), const Color(0xFFFF6B35), 'JWST');
    lLabel('L3', Offset(l3X, l3Y), const Color(0xFFFF6B35), null);
    lLabel('L4', Offset(l4X, l4Y), const Color(0xFF64FF8C), '트로이');
    lLabel('L5', Offset(l5X, l5Y), const Color(0xFF64FF8C), '트로이');

    // ── Legend bottom ──
    final legY = size.height * 0.91;
    _drawCross(canvas, Offset(12, legY), const Color(0xFFFF6B35), 4);
    _label(canvas, '불안정', Offset(20, legY - 5),
        const Color(0xFFFF6B35), 8);
    _drawCross(canvas, Offset(72, legY), const Color(0xFF64FF8C), 4);
    _label(canvas, '안정 (트로이군)', Offset(80, legY - 5),
        const Color(0xFF64FF8C), 8);
  }

  @override
  bool shouldRepaint(covariant _LagrangePointsScreenPainter oldDelegate) => true;
}
