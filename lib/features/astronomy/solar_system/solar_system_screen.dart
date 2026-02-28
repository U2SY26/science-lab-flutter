import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';
import '../../../shared/painters/projection_3d.dart';

/// Solar System Simulation
class SolarSystemScreen extends StatefulWidget {
  const SolarSystemScreen({super.key});

  @override
  State<SolarSystemScreen> createState() => _SolarSystemScreenState();
}

class _SolarSystemScreenState extends State<SolarSystemScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _time = 0.0;
  bool _isAnimating = true;
  double _animationSpeed = 1.0;
  bool _showOrbits = true;
  bool _showLabels = true;
  bool _isKorean = true;
  int _selectedPlanet = -1;

  // Planet data: [name, nameKr, orbitRadius, orbitalPeriod, size, color]
  static const List<Map<String, dynamic>> _planets = [
    {'name': 'Mercury', 'nameKr': '수성', 'orbit': 0.12, 'period': 0.24, 'size': 4.0, 'color': 0xFFB0B0B0},
    {'name': 'Venus', 'nameKr': '금성', 'orbit': 0.18, 'period': 0.62, 'size': 6.0, 'color': 0xFFE6C35C},
    {'name': 'Earth', 'nameKr': '지구', 'orbit': 0.25, 'period': 1.0, 'size': 6.5, 'color': 0xFF4169E1},
    {'name': 'Mars', 'nameKr': '화성', 'orbit': 0.32, 'period': 1.88, 'size': 5.0, 'color': 0xFFCD5C5C},
    {'name': 'Jupiter', 'nameKr': '목성', 'orbit': 0.45, 'period': 11.86, 'size': 14.0, 'color': 0xFFD4A574},
    {'name': 'Saturn', 'nameKr': '토성', 'orbit': 0.58, 'period': 29.46, 'size': 12.0, 'color': 0xFFE8D4A2},
    {'name': 'Uranus', 'nameKr': '천왕성', 'orbit': 0.70, 'period': 84.01, 'size': 9.0, 'color': 0xFF7EC8E3},
    {'name': 'Neptune', 'nameKr': '해왕성', 'orbit': 0.82, 'period': 164.8, 'size': 8.5, 'color': 0xFF4169E1},
  ];

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
      _time += 0.002 * _animationSpeed;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _isAnimating = true;
      _selectedPlanet = -1;
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
              _isKorean ? '태양계' : 'Solar System',
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: _isKorean ? '천문학 시뮬레이션' : 'ASTRONOMY SIMULATION',
          title: _isKorean ? '태양계' : 'Solar System',
          formula: 'T² = (4π²/GM) × a³',
          formulaDescription: _isKorean
              ? '태양계의 8개 행성이 각자의 궤도를 따라 공전합니다. 행성의 공전 주기는 케플러 제3법칙을 따릅니다.'
              : 'The 8 planets orbit the Sun following Kepler\'s third law of planetary motion.',
          simulation: SizedBox(
            height: 350,
            child: GestureDetector(
              onTapDown: (details) => _handleTap(details, context),
              child: CustomPaint(
                painter: SolarSystemPainter(
                  time: _time,
                  showOrbits: _showOrbits,
                  showLabels: _showLabels,
                  selectedPlanet: _selectedPlanet,
                  isKorean: _isKorean,
                  planets: _planets,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Planet selection
              PresetGroup(
                label: _isKorean ? '행성 선택' : 'Select Planet',
                presets: List.generate(_planets.length, (index) {
                  return PresetButton(
                    label: _isKorean ? _planets[index]['nameKr'] : _planets[index]['name'],
                    isSelected: _selectedPlanet == index,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPlanet = _selectedPlanet == index ? -1 : index);
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: _isKorean ? '시간 속도' : 'Time Speed',
                  value: _animationSpeed,
                  min: 0.1,
                  max: 5.0,
                  defaultValue: 1.0,
                  formatValue: (v) => '${v.toStringAsFixed(1)}x',
                  onChanged: (v) => setState(() => _animationSpeed = v),
                ),
                advancedControls: [
                  SimToggle(
                    label: _isKorean ? '궤도 표시' : 'Show Orbits',
                    value: _showOrbits,
                    onChanged: (v) => setState(() => _showOrbits = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '라벨 표시' : 'Show Labels',
                    value: _showLabels,
                    onChanged: (v) => setState(() => _showLabels = v),
                  ),
                ],
              ),
              if (_selectedPlanet >= 0) ...[
                const SizedBox(height: 12),
                _PlanetInfoCard(
                  planet: _planets[_selectedPlanet],
                  isKorean: _isKorean,
                ),
              ],
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

  void _handleTap(TapDownDetails details, BuildContext context) {
    // Tap detection logic would go here
  }
}

class _PlanetInfoCard extends StatelessWidget {
  final Map<String, dynamic> planet;
  final bool isKorean;

  const _PlanetInfoCard({required this.planet, required this.isKorean});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(planet['color']).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Color(planet['color']),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isKorean ? planet['nameKr'] : planet['name'],
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? '공전 주기: ${planet['period']} 지구년'
                : 'Orbital Period: ${planet['period']} Earth years',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class SolarSystemPainter extends CustomPainter {
  final double time;
  final bool showOrbits;
  final bool showLabels;
  final int selectedPlanet;
  final bool isKorean;
  final List<Map<String, dynamic>> planets;

  SolarSystemPainter({
    required this.time,
    required this.showOrbits,
    required this.showLabels,
    required this.selectedPlanet,
    required this.isKorean,
    required this.planets,
  });

  // Orbital inclinations (radians) per planet for 3D tilt
  static const List<double> _inclinations = [
    0.122, 0.059, 0.0, 0.032, 0.023, 0.043, 0.013, 0.031,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0D1A20),
    );

    _drawMilkyWay(canvas, size);
    _drawStars(canvas, size);

    final cx = size.width / 2;
    final cy = size.height * 0.46;
    final maxR = math.min(size.width * 0.46, size.height * 0.46);

    // Isometric projection: tilt the solar system view
    // rotX ~0.45 (tilted 3D view), rotY tracks time for slow auto-spin
    final proj = Projection3D(
      rotX: 0.42,
      rotY: 0.3 + time * 0.004,
      scale: maxR,
      center: Offset(cx, cy),
    );

    // Draw orbits first (back to front)
    if (showOrbits) {
      _drawOrbits(canvas, proj, maxR);
    }

    // Draw Sun (always on top via depth-neutral center)
    _drawSun(canvas, Offset(cx, cy), time);

    // Compute planet 3D positions, sort by depth
    final planetData = <Map<String, dynamic>>[];
    for (int i = 0; i < planets.length; i++) {
      final p = planets[i];
      final orbitNorm = p['orbit'] as double;
      final period = p['period'] as double;
      final incl = _inclinations[i];
      final angle = time * 2 * math.pi / period;
      // 3D orbit position with inclination
      final rx = orbitNorm * math.cos(angle);
      final ry = orbitNorm * math.sin(angle) * math.sin(incl);
      final rz = orbitNorm * math.sin(angle) * math.cos(incl);
      final pos2d = proj.project(rx, ry, rz);
      final depth = proj.depth(rx, ry, rz);
      planetData.add({
        ...p,
        'index': i,
        'pos2d': pos2d,
        'depth': depth,
        'rx': rx, 'ry': ry, 'rz': rz,
      });
    }
    // Sort: farthest first
    planetData.sort((a, b) => (a['depth'] as double).compareTo(b['depth'] as double));

    for (final pd in planetData) {
      final i = pd['index'] as int;
      final pos2d = pd['pos2d'] as Offset;
      final planetSize = (pd['size'] as double);
      final color = Color(pd['color'] as int);
      final isSelected = i == selectedPlanet;

      // Saturn: draw back ring half before planet
      if (pd['name'] == 'Saturn') {
        _drawSaturnRingHalf(canvas, pos2d, planetSize, false);
      }

      _drawPlanet(canvas, pos2d, planetSize, color, isSelected, pd['name'] as String);

      // Saturn: draw front ring half after planet
      if (pd['name'] == 'Saturn') {
        _drawSaturnRingHalf(canvas, pos2d, planetSize, true);
      }

      if (showLabels && (isSelected || selectedPlanet < 0)) {
        _drawPlanetLabel(canvas, pos2d, planetSize, isKorean ? pd['nameKr'] as String : pd['name'] as String, color, isSelected);
      }
    }

    // Draw asteroid belt hint between Mars and Jupiter
    _drawAsteroidBelt(canvas, proj, maxR);
  }

  void _drawMilkyWay(Canvas canvas, Size size) {
    // Soft diagonal band of diffuse stars
    final rng = math.Random(77);
    final bandAngle = 0.35; // radians
    for (int i = 0; i < 120; i++) {
      // Position along the band
      final along = rng.nextDouble() * size.width * 1.4 - size.width * 0.2;
      final across = (rng.nextDouble() - 0.5) * size.height * 0.55;
      final x = along * math.cos(bandAngle) - across * math.sin(bandAngle);
      final y = along * math.sin(bandAngle) + across * math.cos(bandAngle) + size.height * 0.1;
      final r = rng.nextDouble() * 0.9 + 0.1;
      final alpha = rng.nextDouble() * 0.18 + 0.04;
      canvas.drawCircle(
        Offset(x, y), r,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final rng = math.Random(99);
    for (int i = 0; i < 200; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.4 + 0.2;
      final bright = rng.nextDouble();
      final alpha = bright * 0.55 + 0.1;
      if (bright > 0.85) {
        // Bright star with small glow
        canvas.drawCircle(
          Offset(x, y), r * 2.5,
          Paint()
            ..color = Colors.white.withValues(alpha: alpha * 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
      canvas.drawCircle(Offset(x, y), r, Paint()..color = Colors.white.withValues(alpha: alpha));
    }
  }

  void _drawOrbits(Canvas canvas, Projection3D proj, double maxR) {
    for (int i = 0; i < planets.length; i++) {
      final p = planets[i];
      final orbitNorm = p['orbit'] as double;
      final incl = _inclinations[i];
      final isSelected = i == selectedPlanet;
      final color = Color(p['color'] as int);

      // Draw ellipse as polyline in 3D
      final path = Path();
      const nSegs = 80;
      for (int j = 0; j <= nSegs; j++) {
        final theta = j * 2 * math.pi / nSegs;
        final rx = orbitNorm * math.cos(theta);
        final ry = orbitNorm * math.sin(theta) * math.sin(incl);
        final rz = orbitNorm * math.sin(theta) * math.cos(incl);
        final p2d = proj.project(rx, ry, rz);
        if (j == 0) {
          path.moveTo(p2d.dx, p2d.dy);
        } else {
          path.lineTo(p2d.dx, p2d.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = isSelected
              ? color.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.12)
          ..strokeWidth = isSelected ? 1.5 : 0.6
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawAsteroidBelt(Canvas canvas, Projection3D proj, double maxR) {
    final rng = math.Random(55);
    const innerNorm = 0.385;
    const outerNorm = 0.415;
    for (int i = 0; i < 60; i++) {
      final theta = rng.nextDouble() * 2 * math.pi;
      final r = innerNorm + rng.nextDouble() * (outerNorm - innerNorm);
      final rx = r * math.cos(theta);
      final rz = r * math.sin(theta);
      final ry = (rng.nextDouble() - 0.5) * 0.015;
      final p2d = proj.project(rx, ry, rz);
      canvas.drawCircle(
        p2d, 0.8,
        Paint()..color = Colors.white.withValues(alpha: rng.nextDouble() * 0.25 + 0.05),
      );
    }
  }

  void _drawSun(Canvas canvas, Offset center, double t) {
    // Outer corona layers
    for (int layer = 5; layer >= 1; layer--) {
      final r = 20.0 + layer * 9.0;
      final alpha = 0.04 + 0.02 * (6 - layer) / 5.0;
      canvas.drawCircle(
        center, r,
        Paint()
          ..color = const Color(0xFFFF8C00).withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, layer * 3.5),
      );
    }
    // Radial gradient body
    final gradient = RadialGradient(
      colors: [
        const Color(0xFFFFFFCC),
        const Color(0xFFFFD700),
        const Color(0xFFFF8C00),
        const Color(0xFFFF4500).withValues(alpha: 0),
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: 28));
    canvas.drawCircle(center, 28, Paint()..shader = gradient);

    // Surface flares (8 directions)
    for (int f = 0; f < 8; f++) {
      final angle = f * math.pi / 4 + t * 0.3;
      final flareLen = 18.0 + 6.0 * math.sin(t * 2.1 + f * 0.7);
      final tip = Offset(
        center.dx + (22 + flareLen) * math.cos(angle),
        center.dy + (22 + flareLen) * math.sin(angle),
      );
      canvas.drawLine(
        center, tip,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.18)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  void _drawPlanet(Canvas canvas, Offset pos, double radius, Color color, bool isSelected, String name) {
    if (isSelected) {
      // Selection ring
      canvas.drawCircle(
        pos, radius + 6,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        pos, radius + 8,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Planet glow
    canvas.drawCircle(
      pos, radius * 1.8,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Sphere with radial gradient (light from upper-left)
    final gradient = RadialGradient(
      center: const Alignment(-0.35, -0.45),
      radius: 0.9,
      colors: [
        Color.lerp(color, Colors.white, 0.5)!,
        color,
        Color.lerp(color, Colors.black, 0.45)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: pos, radius: radius));
    canvas.drawCircle(pos, radius, Paint()..shader = gradient);

    // Earth: add continent hint
    if (name == 'Earth') {
      canvas.drawCircle(
        Offset(pos.dx - radius * 0.2, pos.dy + radius * 0.1),
        radius * 0.35,
        Paint()..color = const Color(0xFF228B22).withValues(alpha: 0.55),
      );
    }
    // Jupiter: banding stripes
    if (name == 'Jupiter') {
      for (int b = 0; b < 4; b++) {
        final bY = pos.dy - radius * 0.5 + b * radius * 0.35;
        canvas.drawRect(
          Rect.fromLTWH(pos.dx - radius, bY, radius * 2, radius * 0.15),
          Paint()..color = const Color(0xFFAA7744).withValues(alpha: 0.22),
        );
      }
    }
  }

  void _drawSaturnRingHalf(Canvas canvas, Offset pos, double planetSize, bool frontHalf) {
    final rW = planetSize * 2.8;
    final rH = planetSize * 0.55;
    // Outer ring
    for (int ring = 0; ring < 3; ring++) {
      final scale = 1.0 + ring * 0.12;
      final alpha = 0.35 - ring * 0.08;
      final ringPaint = Paint()
        ..color = const Color(0xFFE8D4A2).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 - ring * 0.5;
      // Draw either top half (back) or bottom half (front)
      final rect = Rect.fromCenter(center: pos, width: rW * scale, height: rH * scale);
      canvas.drawArc(
        rect,
        frontHalf ? 0 : math.pi,
        math.pi,
        false,
        ringPaint,
      );
    }
  }

  void _drawPlanetLabel(Canvas canvas, Offset pos, double radius, String name, Color color, bool isSelected) {
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: isSelected ? color : color.withValues(alpha: 0.75),
          fontSize: isSelected ? 10.0 : 8.5,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          shadows: const [Shadow(blurRadius: 4, color: Color(0xFF0D1A20))],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + radius + 3));
  }

  @override
  bool shouldRepaint(covariant SolarSystemPainter old) => true;
}
