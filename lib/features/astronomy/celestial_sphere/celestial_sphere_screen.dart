import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CelestialSphereScreen extends StatefulWidget {
  const CelestialSphereScreen({super.key});
  @override
  State<CelestialSphereScreen> createState() => _CelestialSphereScreenState();
}

class _CelestialSphereScreenState extends State<CelestialSphereScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _latitude = 37;
  
  double _polarAlt = 37, _equatorAlt = 53;

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
      _polarAlt = _latitude;
      _equatorAlt = 90 - _latitude.abs();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _latitude = 37.0;
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
          const Text('천구', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '천구',
          formula: 'RA, Dec coordinates',
          formulaDescription: '천구 좌표계와 별자리를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CelestialSphereScreenPainter(
                time: _time,
                latitude: _latitude,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '관측 위도 (°)',
                value: _latitude,
                min: -90,
                max: 90,
                step: 1,
                defaultValue: 37,
                formatValue: (v) => v.toStringAsFixed(0) + '°',
                onChanged: (v) => setState(() => _latitude = v),
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
          _V('북극성고도', _polarAlt.toStringAsFixed(0) + '°'),
          _V('천구적도', _equatorAlt.toStringAsFixed(0) + '°'),
          _V('위도', _latitude.toStringAsFixed(0) + '°'),
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

class _CelestialSphereScreenPainter extends CustomPainter {
  final double time;
  final double latitude;

  _CelestialSphereScreenPainter({
    required this.time,
    required this.latitude,
  });

  void _label(Canvas canvas, String text, Offset pos, Color col, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  // Project a point on the celestial sphere (ra, dec in radians)
  // to canvas coordinates using a simple oblique projection.
  // The sphere is tilted by observer latitude.
  Offset _project(double ra, double dec, double cx, double cy, double R,
      double latRad, double siderealTime) {
    final ha = siderealTime - ra;
    final x3 = math.cos(dec) * math.cos(ha);
    final y3 = math.cos(dec) * math.sin(ha);
    final z3 = math.sin(dec);
    final coLat = math.pi / 2 - latRad;
    final y3r = y3 * math.cos(coLat) - z3 * math.sin(coLat);
    return Offset(cx + R * x3, cy - R * y3r);
  }

  bool _isAboveHorizon(double ra, double dec, double latRad, double siderealTime) {
    final ha = siderealTime - ra;
    final y3 = math.cos(dec) * math.sin(ha);
    final z3 = math.sin(dec);
    final coLat = math.pi / 2 - latRad;
    final zAbove = y3 * math.sin(coLat) + z3 * math.cos(coLat);
    return zAbove > -0.05;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final cx = size.width / 2;
    final cy = size.height * 0.50;
    final R = math.min(size.width, size.height) * 0.40;

    final latRad = latitude * math.pi / 180;
    final siderealTime = time * 0.15; // slow rotation

    // ── Sphere wireframe ──
    final wirePaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    // RA lines (meridians) every 30°
    for (int h = 0; h < 12; h++) {
      final ra = h * math.pi / 6;
      final path = Path();
      bool started = false;
      for (double dec = -math.pi / 2; dec <= math.pi / 2; dec += 0.05) {
        final p = _project(ra, dec, cx, cy, R, latRad, siderealTime);
        if (!started) {
          path.moveTo(p.dx, p.dy);
          started = true;
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, wirePaint);
    }

    // Dec lines (parallels) every 30°
    for (int d = -2; d <= 2; d++) {
      final dec = d * math.pi / 6;
      final path = Path();
      bool started = false;
      for (double ra = 0; ra <= 2 * math.pi + 0.1; ra += 0.05) {
        final p = _project(ra, dec, cx, cy, R, latRad, siderealTime);
        if (!started) {
          path.moveTo(p.dx, p.dy);
          started = true;
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, wirePaint);
    }

    // ── Celestial equator (bright) ──
    final equPath = Path();
    bool equStarted = false;
    for (double ra = 0; ra <= 2 * math.pi + 0.1; ra += 0.04) {
      final p = _project(ra, 0, cx, cy, R, latRad, siderealTime);
      if (!equStarted) {
        equPath.moveTo(p.dx, p.dy);
        equStarted = true;
      } else {
        equPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
        equPath,
        Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: 0.55)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke);

    // ── Ecliptic (23.5° tilt) ──
    const eclipticTilt = 23.5 * math.pi / 180;
    final eclPath = Path();
    bool eclStarted = false;
    for (double lam = 0; lam <= 2 * math.pi + 0.1; lam += 0.04) {
      final ecDec = math.asin(math.sin(eclipticTilt) * math.sin(lam));
      final ecRa = math.atan2(
          math.cos(eclipticTilt) * math.sin(lam), math.cos(lam));
      final p = _project(ecRa, ecDec, cx, cy, R, latRad, siderealTime);
      if (!eclStarted) {
        eclPath.moveTo(p.dx, p.dy);
        eclStarted = true;
      } else {
        eclPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
        eclPath,
        Paint()
          ..color = const Color(0xFFFFDD44).withValues(alpha: 0.6)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke);

    // ── Horizon circle ──
    final horizPath = Path();
    bool horizStarted = false;
    // Horizon is the celestial sphere great circle perpendicular to zenith
    // zenith dec = latitude, so horizon = dec = lat - 90 rotated
    for (double az = 0; az <= 2 * math.pi + 0.1; az += 0.04) {
      // In local coords: altitude=0, azimuth=az
      // Convert to equatorial
      final altRad = 0.0;
      final azRad = az;
      final sinDec = math.sin(altRad) * math.sin(latRad) +
          math.cos(altRad) * math.cos(latRad) * math.cos(azRad);
      final dec = math.asin(sinDec.clamp(-1.0, 1.0));
      final cosHA = (math.sin(altRad) - math.sin(dec) * math.sin(latRad)) /
          (math.cos(dec) * math.cos(latRad) + 1e-10);
      final ha = math.acos(cosHA.clamp(-1.0, 1.0)) *
          (math.sin(azRad) > 0 ? 1 : -1);
      final ra = siderealTime - ha;
      final p = _project(ra, dec, cx, cy, R, latRad, siderealTime);
      if (!horizStarted) {
        horizPath.moveTo(p.dx, p.dy);
        horizStarted = true;
      } else {
        horizPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
        horizPath,
        Paint()
          ..color = const Color(0xFF64FF8C).withValues(alpha: 0.5)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke);

    // ── Celestial poles ──
    // North celestial pole
    final ncpPos =
        _project(0, math.pi / 2, cx, cy, R, latRad, siderealTime);
    canvas.drawCircle(ncpPos, 4, Paint()..color = const Color(0xFFFFDD44));
    _label(canvas, '천구북극', Offset(ncpPos.dx + 5, ncpPos.dy - 5),
        const Color(0xFFFFDD44), 8);

    // ── Stars (seeded deterministic) ──
    final rng = math.Random(99);
    final brightStars = [
      // [ra_deg, dec_deg, name, brightness]
      [279.2, 38.8, 'Vega', 1.5],
      [68.0, 16.5, 'Aldebaran', 1.6],
      [88.8, 7.4, 'Betelgeuse', 1.4],
      [114.8, 5.2, 'Rigel', 1.3],
      [101.3, -16.7, 'Sirius', 1.8],
      [113.6, 31.9, 'Castor', 1.2],
      [116.3, 28.0, 'Pollux', 1.4],
      [213.9, 19.2, 'Arcturus', 1.7],
    ];

    // Random background stars
    for (int i = 0; i < 60; i++) {
      final ra = rng.nextDouble() * 2 * math.pi;
      final dec = math.asin(rng.nextDouble() * 2 - 1);
      if (!_isAboveHorizon(ra, dec, latRad, siderealTime)) continue;
      final p = _project(ra, dec, cx, cy, R, latRad, siderealTime);
      canvas.drawCircle(
          p,
          0.8 + rng.nextDouble() * 1.2,
          Paint()
            ..color = const Color(0xFFE0F4FF)
                .withValues(alpha: 0.3 + rng.nextDouble() * 0.4));
    }

    // Bright named stars
    for (final s in brightStars) {
      final ra = (s[0] as double) * math.pi / 180;
      final dec = (s[1] as double) * math.pi / 180;
      if (!_isAboveHorizon(ra, dec, latRad, siderealTime)) continue;
      final p = _project(ra, dec, cx, cy, R, latRad, siderealTime);
      final r = (s[3] as double) + 0.5;
      canvas.drawCircle(
          p,
          r,
          Paint()
            ..color = const Color(0xFFFFDD88).withValues(alpha: 0.9));
      _label(canvas, s[2] as String, Offset(p.dx + r + 2, p.dy - 4),
          const Color(0xFFE0F4FF).withValues(alpha: 0.7), 7);
    }

    // ── Earth at centre ──
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = const Color(0xFF3A6EA5));
    canvas.drawCircle(
        Offset(cx, cy),
        5,
        Paint()
          ..color = const Color(0xFF00D4FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // ── Labels legend ──
    final legY = size.height * 0.92;
    canvas.drawLine(Offset(4, legY), Offset(18, legY),
        Paint()
          ..color = const Color(0xFF00D4FF)
          ..strokeWidth = 1.5);
    _label(canvas, '천구적도', Offset(20, legY - 5), const Color(0xFF00D4FF), 8);

    canvas.drawLine(Offset(78, legY), Offset(92, legY),
        Paint()
          ..color = const Color(0xFFFFDD44)
          ..strokeWidth = 1.5);
    _label(canvas, '황도', Offset(94, legY - 5), const Color(0xFFFFDD44), 8);

    canvas.drawLine(Offset(128, legY), Offset(142, legY),
        Paint()
          ..color = const Color(0xFF64FF8C)
          ..strokeWidth = 1.5);
    _label(canvas, '지평선', Offset(144, legY - 5), const Color(0xFF64FF8C), 8);

    _label(canvas, '위도: ${latitude.toStringAsFixed(0)}°',
        Offset(size.width - 60, legY - 5), const Color(0xFF5A8A9A), 8);
  }

  @override
  bool shouldRepaint(covariant _CelestialSphereScreenPainter oldDelegate) =>
      true;
}
