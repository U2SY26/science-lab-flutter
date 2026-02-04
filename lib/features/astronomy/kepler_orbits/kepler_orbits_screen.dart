import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Kepler's Laws of Planetary Motion Simulation
class KeplerOrbitsScreen extends StatefulWidget {
  const KeplerOrbitsScreen({super.key});

  @override
  State<KeplerOrbitsScreen> createState() => _KeplerOrbitsScreenState();
}

class _KeplerOrbitsScreenState extends State<KeplerOrbitsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Simulation parameters
  double _eccentricity = 0.5; // Orbital eccentricity (0 = circle, 1 = parabola)
  double _semiMajorAxis = 100.0; // Semi-major axis
  double _time = 0.0;
  bool _isAnimating = false;
  double _animationSpeed = 1.0;
  bool _showAreaSweep = true;
  bool _showVelocityVector = true;
  bool _isKorean = true;

  // Planet position
  double _trueAnomaly = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _updateAnimation() {
    if (!_isAnimating) return;

    setState(() {
      // Kepler's equation: mean anomaly to true anomaly
      _time += 0.01 * _animationSpeed;
      if (_time >= 2 * math.pi) _time -= 2 * math.pi;

      // Solve Kepler's equation iteratively
      _trueAnomaly = _solveKeplerEquation(_time, _eccentricity);
    });
  }

  double _solveKeplerEquation(double meanAnomaly, double e) {
    // Newton-Raphson iteration for eccentric anomaly
    double E = meanAnomaly;
    for (int i = 0; i < 10; i++) {
      E = E - (E - e * math.sin(E) - meanAnomaly) / (1 - e * math.cos(E));
    }
    // Convert eccentric anomaly to true anomaly
    final trueAnomaly = 2 * math.atan(math.sqrt((1 + e) / (1 - e)) * math.tan(E / 2));
    return trueAnomaly;
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _trueAnomaly = 0;
      _isAnimating = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKorean ? '천문학 시뮬레이션' : 'ASTRONOMY SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '케플러의 법칙' : "Kepler's Laws",
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => _isKorean = !_isKorean),
            tooltip: _isKorean ? 'English' : '한국어',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: _isKorean ? '천문학 시뮬레이션' : 'ASTRONOMY SIMULATION',
          title: _isKorean ? '케플러의 법칙' : "Kepler's Laws",
          formula: 'T² = (4π²/GM) × a³',
          formulaDescription: _isKorean
              ? '케플러의 제1법칙: 행성은 타원 궤도를 돈다\n제2법칙: 같은 시간에 같은 면적을 쓸어간다\n제3법칙: 주기의 제곱은 장반경의 세제곱에 비례'
              : "1st Law: Planets orbit in ellipses\n2nd Law: Equal areas swept in equal times\n3rd Law: T² proportional to a³",
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: KeplerOrbitsPainter(
                eccentricity: _eccentricity,
                semiMajorAxis: _semiMajorAxis,
                trueAnomaly: _trueAnomaly,
                showAreaSweep: _showAreaSweep,
                showVelocityVector: _showVelocityVector,
                isKorean: _isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: _isKorean ? '이심률 (Eccentricity)' : 'Eccentricity',
                  value: _eccentricity,
                  min: 0,
                  max: 0.95,
                  defaultValue: 0.5,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _eccentricity = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '장반경' : 'Semi-major Axis',
                    value: _semiMajorAxis,
                    min: 50,
                    max: 150,
                    defaultValue: 100,
                    formatValue: (v) => '${v.toStringAsFixed(0)} AU',
                    onChanged: (v) => setState(() => _semiMajorAxis = v),
                  ),
                  SimSlider(
                    label: _isKorean ? '애니메이션 속도' : 'Animation Speed',
                    value: _animationSpeed,
                    min: 0.5,
                    max: 3.0,
                    step: 0.5,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() => _animationSpeed = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '면적 표시' : 'Show Area Sweep',
                    value: _showAreaSweep,
                    onChanged: (v) => setState(() => _showAreaSweep = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '속도 벡터' : 'Velocity Vector',
                    value: _showVelocityVector,
                    onChanged: (v) => setState(() => _showVelocityVector = v),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isAnimating
                    ? (_isKorean ? '정지' : 'Pause')
                    : (_isKorean ? '재생' : 'Play'),
                icon: _isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isAnimating = !_isAnimating);
                },
              ),
              SimButton(
                label: _isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KeplerOrbitsPainter extends CustomPainter {
  final double eccentricity;
  final double semiMajorAxis;
  final double trueAnomaly;
  final bool showAreaSweep;
  final bool showVelocityVector;
  final bool isKorean;

  KeplerOrbitsPainter({
    required this.eccentricity,
    required this.semiMajorAxis,
    required this.trueAnomaly,
    required this.showAreaSweep,
    required this.showVelocityVector,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width * 0.003;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050510),
    );

    // Draw stars
    _drawStars(canvas, size);

    // Calculate ellipse parameters
    final a = semiMajorAxis * scale;
    final b = a * math.sqrt(1 - eccentricity * eccentricity);
    final focalDistance = a * eccentricity;

    // Sun position (at focus)
    final sunX = centerX + focalDistance;
    final sunY = centerY;

    // Draw orbit
    final orbitPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, centerY), width: a * 2, height: b * 2),
      orbitPaint,
    );

    // Draw area sweep (Kepler's 2nd Law)
    if (showAreaSweep) {
      _drawAreaSweep(canvas, centerX, centerY, sunX, sunY, a, b, focalDistance);
    }

    // Draw Sun
    _drawSun(canvas, sunX, sunY);

    // Calculate planet position
    final r = a * (1 - eccentricity * eccentricity) / (1 + eccentricity * math.cos(trueAnomaly));
    final planetX = sunX + r * math.cos(trueAnomaly);
    final planetY = sunY + r * math.sin(trueAnomaly);

    // Draw radius vector
    canvas.drawLine(
      Offset(sunX, sunY),
      Offset(planetX, planetY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // Draw velocity vector
    if (showVelocityVector) {
      _drawVelocityVector(canvas, planetX, planetY, r, a, eccentricity, trueAnomaly);
    }

    // Draw planet
    _drawPlanet(canvas, planetX, planetY);

    // Draw labels
    _drawLabels(canvas, size, sunX, sunY, centerX, centerY, a, b);
  }

  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42);
    final starPaint = Paint();

    for (int i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.2 + 0.3;
      starPaint.color = Colors.white.withValues(alpha: random.nextDouble() * 0.5 + 0.2);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  void _drawAreaSweep(Canvas canvas, double cx, double cy, double sx, double sy, double a, double b, double fd) {
    final path = Path();
    path.moveTo(sx, sy);

    // Draw swept area
    final startAngle = trueAnomaly - 0.5;
    final endAngle = trueAnomaly;

    for (double angle = startAngle; angle <= endAngle; angle += 0.05) {
      final r = a * (1 - eccentricity * eccentricity) / (1 + eccentricity * math.cos(angle));
      final x = sx + r * math.cos(angle);
      final y = sy + r * math.sin(angle);
      path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawSun(Canvas canvas, double x, double y) {
    // Glow effect
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700),
          const Color(0xFFFF8C00),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 40));
    canvas.drawCircle(Offset(x, y), 40, glowPaint);

    // Sun body
    canvas.drawCircle(
      Offset(x, y),
      18,
      Paint()..color = const Color(0xFFFFD700),
    );
  }

  void _drawPlanet(Canvas canvas, double x, double y) {
    // Shadow
    canvas.drawCircle(
      Offset(x + 2, y + 2),
      10,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Planet gradient
    final planetGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        const Color(0xFF4169E1),
        const Color(0xFF1E3A8A),
      ],
    ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 10));

    canvas.drawCircle(Offset(x, y), 10, Paint()..shader = planetGradient);
  }

  void _drawVelocityVector(Canvas canvas, double px, double py, double r, double a, double e, double theta) {
    // Vis-viva equation for velocity magnitude
    final v = math.sqrt(2 / r - 1 / a) * 30;

    // Velocity direction (perpendicular to radius, with radial component)
    final gamma = math.atan(e * math.sin(theta) / (1 + e * math.cos(theta)));
    final velocityAngle = theta + math.pi / 2 - gamma;

    final vx = px + v * math.cos(velocityAngle);
    final vy = py + v * math.sin(velocityAngle);

    final arrowPaint = Paint()
      ..color = const Color(0xFF00FF88)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(px, py), Offset(vx, vy), arrowPaint);

    // Arrow head
    final arrowSize = 8.0;
    final angle = math.atan2(vy - py, vx - px);
    canvas.drawLine(
      Offset(vx, vy),
      Offset(vx - arrowSize * math.cos(angle - 0.5), vy - arrowSize * math.sin(angle - 0.5)),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(vx, vy),
      Offset(vx - arrowSize * math.cos(angle + 0.5), vy - arrowSize * math.sin(angle + 0.5)),
      arrowPaint,
    );
  }

  void _drawLabels(Canvas canvas, Size size, double sx, double sy, double cx, double cy, double a, double b) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Sun label
    textPainter.text = TextSpan(
      text: isKorean ? '태양 (초점)' : 'Sun (Focus)',
      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(sx - textPainter.width / 2, sy + 25));

    // Semi-major axis label
    textPainter.text = TextSpan(
      text: isKorean ? 'a (장반경)' : 'a (semi-major)',
      style: TextStyle(color: AppColors.accent, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx, cy + b + 10));

    // Eccentricity display
    textPainter.text = TextSpan(
      text: 'e = ${eccentricity.toStringAsFixed(2)}',
      style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height - 25));
  }

  @override
  bool shouldRepaint(covariant KeplerOrbitsPainter oldDelegate) {
    return eccentricity != oldDelegate.eccentricity ||
        semiMajorAxis != oldDelegate.semiMajorAxis ||
        trueAnomaly != oldDelegate.trueAnomaly ||
        showAreaSweep != oldDelegate.showAreaSweep ||
        showVelocityVector != oldDelegate.showVelocityVector;
  }
}
