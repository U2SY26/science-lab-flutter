import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ParallaxScreen extends StatefulWidget {
  const ParallaxScreen({super.key});
  @override
  State<ParallaxScreen> createState() => _ParallaxScreenState();
}

class _ParallaxScreenState extends State<ParallaxScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _parallaxAngle = 0.1;
  
  double _distance = 10.0, _distLy = 32.6;

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
      _distance = 1.0 / _parallaxAngle;
      _distLy = _distance * 3.26;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _parallaxAngle = 0.1;
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
          const Text('항성 시차', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '항성 시차',
          formula: 'd = 1/p (pc)',
          formulaDescription: '항성 시차를 이용한 거리 측정을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ParallaxScreenPainter(
                time: _time,
                parallaxAngle: _parallaxAngle,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '시차 (arcsec)',
                value: _parallaxAngle,
                min: 0.001,
                max: 1,
                step: 0.001,
                defaultValue: 0.1,
                formatValue: (v) => v.toStringAsFixed(3) + '"',
                onChanged: (v) => setState(() => _parallaxAngle = v),
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
          _V('거리', _distance.toStringAsFixed(1) + ' pc'),
          _V('거리', _distLy.toStringAsFixed(1) + ' ly'),
          _V('시차', _parallaxAngle.toStringAsFixed(3) + '"'),
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

class _ParallaxScreenPainter extends CustomPainter {
  final double time;
  final double parallaxAngle;

  _ParallaxScreenPainter({
    required this.time,
    required this.parallaxAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // Distance in parsecs
    final distPc = (1.0 / parallaxAngle).clamp(1.0, 1000.0);

    // Layout
    // Top 40%: wide-view space diagram (Sun, Earth orbit, nearby star, distant stars)
    // Bottom 60%: close-up parallax geometry diagram
    final topH = size.height * 0.42;
    final botTop = topH + 4;
    final botH = size.height - botTop - 4;

    // ===== TOP: Space overview =====
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, topH),
        Paint()..color = const Color(0xFF06101A));

    // Distant background stars (no parallax)
    final rng = math.Random(55);
    for (int i = 0; i < 30; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * topH * 0.9;
      canvas.drawCircle(Offset(sx, sy), rng.nextDouble() * 0.8 + 0.2,
          Paint()..color = Colors.white.withValues(alpha: rng.nextDouble() * 0.35 + 0.1));
    }

    // Sun at bottom center of top area
    final sunX = size.width / 2;
    final sunY = topH * 0.82;
    canvas.drawCircle(Offset(sunX, sunY), 10,
        Paint()..color = const Color(0xFFFFDD44));
    canvas.drawCircle(Offset(sunX, sunY), 14,
        Paint()..color = const Color(0xFFFFAA00).withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    _drawLabel(canvas, '태양', Offset(sunX - 8, sunY + 12), const Color(0xFFFFDD44), 8);

    // Earth orbit ellipse
    final orbitRx = size.width * 0.18;
    final orbitRy = topH * 0.12;
    canvas.drawOval(Rect.fromCenter(center: Offset(sunX, sunY), width: orbitRx * 2, height: orbitRy * 2),
        Paint()..color = const Color(0xFF3A6080).withValues(alpha: 0.45)
          ..strokeWidth = 0.8..style = PaintingStyle.stroke);

    // Earth positions (Jan & Jul — opposite sides)
    final earthAngle = time * 0.4;
    final e1x = sunX + orbitRx * math.cos(earthAngle);
    final e1y = sunY + orbitRy * math.sin(earthAngle);
    final e2x = sunX + orbitRx * math.cos(earthAngle + math.pi);
    final e2y = sunY + orbitRy * math.sin(earthAngle + math.pi);

    canvas.drawCircle(Offset(e1x, e1y), 5,
        Paint()..color = const Color(0xFF4488FF));
    canvas.drawCircle(Offset(e1x, e1y), 5,
        Paint()..color = const Color(0xFF2255AA).withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    _drawLabel(canvas, '1월', Offset(e1x + 6, e1y - 6), const Color(0xFF4488FF), 7);

    canvas.drawCircle(Offset(e2x, e2y), 5,
        Paint()..color = const Color(0xFF44AAFF));
    _drawLabel(canvas, '7월', Offset(e2x + 6, e2y - 6), const Color(0xFF44AAFF), 7);

    // Nearby star: position depends on distance (farther = higher up, less shift)
    final starBaseX = sunX + size.width * 0.06; // slight offset from center
    final starBaseY = topH * 0.15;
    // Apparent shift due to parallax
    final shiftPx = (orbitRx * parallaxAngle * 50).clamp(0.0, orbitRx * 0.7);
    final nearStarX1 = starBaseX + shiftPx * math.cos(earthAngle);
    final nearStarX2 = starBaseX + shiftPx * math.cos(earthAngle + math.pi);
    final nearStarY = starBaseY;

    // Observation lines from each Earth position to the star
    canvas.drawLine(Offset(e1x, e1y), Offset(nearStarX1, nearStarY),
        Paint()..color = const Color(0xFF4488FF).withValues(alpha: 0.5)
          ..strokeWidth = 0.8..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(e2x, e2y), Offset(nearStarX2, nearStarY),
        Paint()..color = const Color(0xFF44AAFF).withValues(alpha: 0.5)
          ..strokeWidth = 0.8..style = PaintingStyle.stroke);

    // Parallax angle arc indicator
    if (shiftPx > 2) {
      canvas.drawLine(Offset(nearStarX1, nearStarY), Offset(nearStarX2, nearStarY),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)
            ..strokeWidth = 1.2);
      _drawLabel(canvas, '2p = ${(parallaxAngle * 2).toStringAsFixed(3)}"',
          Offset((nearStarX1 + nearStarX2) / 2 - 20, nearStarY - 12),
          const Color(0xFFFF6B35), 7);
    }

    // Nearby star glow + dot
    canvas.drawCircle(Offset(nearStarX1 * 0.5 + nearStarX2 * 0.5, nearStarY), 8,
        Paint()..color = const Color(0xFFFFCC44).withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(nearStarX1 * 0.5 + nearStarX2 * 0.5, nearStarY), 4,
        Paint()..color = const Color(0xFFFFCC44));
    _drawLabel(canvas, '근처 별', Offset(nearStarX1 * 0.5 + nearStarX2 * 0.5 + 6, nearStarY - 6),
        const Color(0xFFFFCC44), 8);

    // 1 AU baseline label
    canvas.drawLine(Offset(sunX, sunY + 2), Offset(e1x, e1y),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.3)..strokeWidth = 0.6
          ..style = PaintingStyle.stroke);
    _drawLabel(canvas, '1 AU', Offset((sunX + e1x) / 2 + 2, (sunY + e1y) / 2),
        const Color(0xFF5A8A9A), 7);

    // ===== BOTTOM: Parallax geometry diagram =====
    canvas.drawRect(Rect.fromLTWH(0, botTop, size.width, botH),
        Paint()..color = const Color(0xFF050D12));

    // Triangle diagram: Sun at bottom, star at top, Earth positions on sides
    final triCx = size.width * 0.38;
    final triSunY = botTop + botH * 0.88;
    final triStarY = botTop + botH * 0.10;
    final triBaseHalf = math.min(size.width * 0.22, botH * 0.3);
    final triE1x = triCx - triBaseHalf;
    final triE2x = triCx + triBaseHalf;

    // Star position (center top)
    canvas.drawCircle(Offset(triCx, triStarY), 5,
        Paint()..color = const Color(0xFFFFCC44));
    canvas.drawCircle(Offset(triCx, triStarY), 9,
        Paint()..color = const Color(0xFFFFAA00).withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Sun
    canvas.drawCircle(Offset(triCx, triSunY), 7, Paint()..color = const Color(0xFFFFDD44));

    // Earth positions
    canvas.drawCircle(Offset(triE1x, triSunY), 4, Paint()..color = const Color(0xFF4488FF));
    canvas.drawCircle(Offset(triE2x, triSunY), 4, Paint()..color = const Color(0xFF44AAFF));
    _drawLabel(canvas, 'Jan', Offset(triE1x - 8, triSunY + 8), const Color(0xFF4488FF), 7);
    _drawLabel(canvas, 'Jul', Offset(triE2x + 2, triSunY + 8), const Color(0xFF44AAFF), 7);

    // Lines of observation
    canvas.drawLine(Offset(triE1x, triSunY), Offset(triCx, triStarY),
        Paint()..color = const Color(0xFF4488FF).withValues(alpha: 0.6)..strokeWidth = 1.2);
    canvas.drawLine(Offset(triE2x, triSunY), Offset(triCx, triStarY),
        Paint()..color = const Color(0xFF44AAFF).withValues(alpha: 0.6)..strokeWidth = 1.2);

    // Baseline
    canvas.drawLine(Offset(triE1x, triSunY), Offset(triE2x, triSunY),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.7)..strokeWidth = 1.5);
    _drawLabel(canvas, '2 AU', Offset(triCx - 12, triSunY + 8), const Color(0xFF5A8A9A), 7);

    // Parallax angle arc
    final arcR = 18.0;
    final arcAngle1 = math.atan2(triStarY - triSunY, triCx - triE1x);
    final arcAngle2 = math.atan2(triStarY - triSunY, triCx - triE2x);
    final arcPath = Path()..addArc(
      Rect.fromCenter(center: Offset(triCx, triStarY), width: arcR * 2, height: arcR * 2),
      arcAngle1 - math.pi, (arcAngle2 - arcAngle1) * 0.5,
    );
    canvas.drawPath(arcPath,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)..strokeWidth = 1.2..style = PaintingStyle.stroke);
    _drawLabel(canvas, 'p', Offset(triCx + arcR + 2, triStarY - 8), const Color(0xFFFF6B35), 9, bold: true);

    // Formula and result
    final rightX = size.width * 0.62;
    _drawLabel(canvas, 'd = 1/p (파섹)', Offset(rightX, botTop + botH * 0.10), const Color(0xFF00D4FF), 10, bold: true);
    _drawLabel(canvas, 'p = ${parallaxAngle.toStringAsFixed(3)}"', Offset(rightX, botTop + botH * 0.24),
        const Color(0xFF5A8A9A), 9);
    _drawLabel(canvas, 'd = ${distPc.toStringAsFixed(1)} pc', Offset(rightX, botTop + botH * 0.38),
        const Color(0xFFFF6B35), 11, bold: true);
    _drawLabel(canvas, '= ${(distPc * 3.26).toStringAsFixed(1)} ly', Offset(rightX, botTop + botH * 0.52),
        const Color(0xFFFF6B35).withValues(alpha: 0.8), 10);
    _drawLabel(canvas, '1 pc = 3.26 ly', Offset(rightX, botTop + botH * 0.68),
        const Color(0xFF5A8A9A), 8);
    _drawLabel(canvas, '= 3.086×10¹³ km', Offset(rightX, botTop + botH * 0.80),
        const Color(0xFF5A8A9A), 7);
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
  bool shouldRepaint(covariant _ParallaxScreenPainter oldDelegate) => true;
}
