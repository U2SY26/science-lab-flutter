import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

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

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = math.min(size.width, size.height) / 2 - 20;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050510),
    );

    // Stars
    _drawStars(canvas, size);

    // Draw Sun
    _drawSun(canvas, centerX, centerY);

    // Draw orbits and planets
    for (int i = 0; i < planets.length; i++) {
      final planet = planets[i];
      final orbitRadius = planet['orbit'] * maxRadius;
      final angle = time * 2 * math.pi / planet['period'];

      // Orbit
      if (showOrbits) {
        canvas.drawCircle(
          Offset(centerX, centerY),
          orbitRadius,
          Paint()
            ..color = i == selectedPlanet
                ? Color(planet['color']).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = i == selectedPlanet ? 2 : 0.5,
        );
      }

      // Planet position
      final px = centerX + orbitRadius * math.cos(angle);
      final py = centerY + orbitRadius * math.sin(angle);
      final planetSize = planet['size'].toDouble();

      // Planet
      _drawPlanet(canvas, px, py, planetSize, Color(planet['color']), i == selectedPlanet);

      // Saturn rings
      if (planet['name'] == 'Saturn') {
        _drawSaturnRings(canvas, px, py, planetSize);
      }

      // Label
      if (showLabels && (i == selectedPlanet || selectedPlanet < 0)) {
        _drawLabel(canvas, px, py + planetSize + 8, isKorean ? planet['nameKr'] : planet['name']);
      }
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42);
    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.2 + 0.3;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = Colors.white.withValues(alpha: random.nextDouble() * 0.5 + 0.2),
      );
    }
  }

  void _drawSun(Canvas canvas, double x, double y) {
    // Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700),
          const Color(0xFFFF8C00).withValues(alpha: 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 50));
    canvas.drawCircle(Offset(x, y), 50, glowPaint);

    // Body
    canvas.drawCircle(Offset(x, y), 22, Paint()..color = const Color(0xFFFFD700));
  }

  void _drawPlanet(Canvas canvas, double x, double y, double size, Color color, bool isSelected) {
    if (isSelected) {
      // Selection glow
      canvas.drawCircle(
        Offset(x, y),
        size + 5,
        Paint()..color = color.withValues(alpha: 0.3),
      );
    }

    // Shadow
    canvas.drawCircle(
      Offset(x + 1, y + 1),
      size,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Planet
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [color, color.withValues(alpha: 0.7)],
    ).createShader(Rect.fromCircle(center: Offset(x, y), radius: size));
    canvas.drawCircle(Offset(x, y), size, Paint()..shader = gradient);
  }

  void _drawSaturnRings(Canvas canvas, double x, double y, double size) {
    final ringPaint = Paint()
      ..color = const Color(0xFFE8D4A2).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: size * 3, height: size * 0.8),
      ringPaint,
    );
  }

  void _drawLabel(Canvas canvas, double x, double y, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white70, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant SolarSystemPainter oldDelegate) {
    return time != oldDelegate.time ||
        showOrbits != oldDelegate.showOrbits ||
        showLabels != oldDelegate.showLabels ||
        selectedPlanet != oldDelegate.selectedPlanet;
  }
}
