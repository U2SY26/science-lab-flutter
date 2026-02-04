import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Cosmic Expansion (Hubble's Law) Simulation
class CosmicExpansionScreen extends StatefulWidget {
  const CosmicExpansionScreen({super.key});

  @override
  State<CosmicExpansionScreen> createState() => _CosmicExpansionScreenState();
}

class _CosmicExpansionScreenState extends State<CosmicExpansionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _hubbleConstant = 70.0; // km/s/Mpc
  double _time = 0.0;
  bool _isAnimating = true;
  double _animationSpeed = 1.0;
  bool _showRedshift = true;
  bool _showVelocityVectors = true;
  bool _isKorean = true;

  // Galaxies with initial positions
  late List<GalaxyData> _galaxies;

  @override
  void initState() {
    super.initState();
    _initGalaxies();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _initGalaxies() {
    final random = math.Random(42);
    _galaxies = List.generate(25, (index) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * 0.35 + 0.1;
      return GalaxyData(
        initialDistance: distance,
        angle: angle,
        type: random.nextInt(3),
      );
    });
  }

  void _updateAnimation() {
    if (!_isAnimating) return;
    setState(() {
      _time += 0.0005 * _animationSpeed;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _isAnimating = true;
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
              _isKorean ? '우주 팽창 (허블 법칙)' : 'Cosmic Expansion (Hubble\'s Law)',
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
          title: _isKorean ? '우주 팽창 (허블 법칙)' : 'Cosmic Expansion',
          formula: 'v = H₀ × d',
          formulaDescription: _isKorean
              ? '허블 법칙: 은하의 후퇴 속도는 거리에 비례합니다. H₀ ≈ 70 km/s/Mpc. 멀리 있는 은하일수록 더 빠르게 멀어지며, 적색편이가 더 큽니다.'
              : 'Hubble\'s Law: Recession velocity is proportional to distance. H₀ ≈ 70 km/s/Mpc. More distant galaxies recede faster with greater redshift.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: CosmicExpansionPainter(
                hubbleConstant: _hubbleConstant,
                time: _time,
                galaxies: _galaxies,
                showRedshift: _showRedshift,
                showVelocityVectors: _showVelocityVectors,
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
                  label: _isKorean ? '허블 상수 H₀' : 'Hubble Constant H₀',
                  value: _hubbleConstant,
                  min: 50,
                  max: 100,
                  defaultValue: 70,
                  formatValue: (v) => '${v.toStringAsFixed(0)} km/s/Mpc',
                  onChanged: (v) => setState(() => _hubbleConstant = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '우주 시간' : 'Cosmic Time',
                    value: _time,
                    min: 0,
                    max: 1,
                    defaultValue: 0,
                    formatValue: (v) => '${(v * 13.8).toStringAsFixed(1)} Gyr',
                    onChanged: (v) => setState(() => _time = v),
                  ),
                  SimSlider(
                    label: _isKorean ? '애니메이션 속도' : 'Animation Speed',
                    value: _animationSpeed,
                    min: 0.5,
                    max: 3.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() => _animationSpeed = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '적색편이 표시' : 'Show Redshift',
                    value: _showRedshift,
                    onChanged: (v) => setState(() => _showRedshift = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '속도 벡터' : 'Velocity Vectors',
                    value: _showVelocityVectors,
                    onChanged: (v) => setState(() => _showVelocityVectors = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                hubbleConstant: _hubbleConstant,
                time: _time,
                isKorean: _isKorean,
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

class GalaxyData {
  final double initialDistance;
  final double angle;
  final int type; // 0: spiral, 1: elliptical, 2: irregular

  GalaxyData({
    required this.initialDistance,
    required this.angle,
    required this.type,
  });
}

class _InfoCard extends StatelessWidget {
  final double hubbleConstant;
  final double time;
  final bool isKorean;

  const _InfoCard({
    required this.hubbleConstant,
    required this.time,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate Hubble time (age of universe approximation)
    final hubbleTime = 1 / hubbleConstant * 978; // Convert to Gyr

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                isKorean ? '허블 시간' : 'Hubble Time',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${hubbleTime.toStringAsFixed(1)} Gyr',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.expand, size: 16, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                isKorean ? '스케일 팩터' : 'Scale Factor',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'a(t) = ${(1 + time).toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CosmicExpansionPainter extends CustomPainter {
  final double hubbleConstant;
  final double time;
  final List<GalaxyData> galaxies;
  final bool showRedshift;
  final bool showVelocityVectors;
  final bool isKorean;

  CosmicExpansionPainter({
    required this.hubbleConstant,
    required this.time,
    required this.galaxies,
    required this.showRedshift,
    required this.showVelocityVectors,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Background - deep space
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF020208),
    );

    // Draw cosmic microwave background subtle grid
    _drawCosmicGrid(canvas, size, centerX, centerY);

    // Draw reference circles (distance markers)
    _drawDistanceMarkers(canvas, centerX, centerY, size);

    // Draw observer's galaxy at center
    _drawObserverGalaxy(canvas, centerX, centerY);

    // Scale factor for expansion
    final scaleFactor = 1 + time * (hubbleConstant / 70);

    // Draw expanding galaxies
    for (final galaxy in galaxies) {
      final expandedDistance = galaxy.initialDistance * scaleFactor;
      final x = centerX + expandedDistance * size.width * math.cos(galaxy.angle);
      final y = centerY + expandedDistance * size.height * math.sin(galaxy.angle);

      // Skip if outside canvas
      if (x < -20 || x > size.width + 20 || y < -20 || y > size.height + 20) continue;

      // Calculate velocity (Hubble's Law)
      final velocity = hubbleConstant * expandedDistance * 100; // Scaled for visualization

      // Calculate redshift based on velocity
      final redshift = velocity / 300000; // z = v/c approximation

      // Draw velocity vector
      if (showVelocityVectors) {
        final vectorLength = velocity * 0.0005;
        final vx = x + vectorLength * (x - centerX) / expandedDistance / size.width;
        final vy = y + vectorLength * (y - centerY) / expandedDistance / size.height;

        canvas.drawLine(
          Offset(x, y),
          Offset(vx * size.width + (1 - vx) * x, vy * size.height + (1 - vy) * y),
          Paint()
            ..color = Colors.green.withValues(alpha: 0.6)
            ..strokeWidth = 1.5,
        );
      }

      // Draw galaxy with redshift coloring
      _drawGalaxy(canvas, x, y, galaxy.type, redshift, showRedshift);
    }

    // Draw labels
    _drawLabels(canvas, size, centerX, centerY);
  }

  void _drawCosmicGrid(Canvas canvas, Size size, double cx, double cy) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    // Radial lines
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + size.width * math.cos(angle), cy + size.height * math.sin(angle)),
        gridPaint,
      );
    }
  }

  void _drawDistanceMarkers(Canvas canvas, double cx, double cy, Size size) {
    final markerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final radius = i * math.min(size.width, size.height) * 0.2;
      canvas.drawCircle(Offset(cx, cy), radius, markerPaint);
    }
  }

  void _drawObserverGalaxy(Canvas canvas, double x, double y) {
    // Our galaxy (Milky Way representation)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.5),
          const Color(0xFFFFD700).withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 25));
    canvas.drawCircle(Offset(x, y), 25, glowPaint);

    // Core
    canvas.drawCircle(Offset(x, y), 8, Paint()..color = const Color(0xFFFFD700));

    // Spiral arms (simplified)
    final armPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int arm = 0; arm < 2; arm++) {
      final path = Path();
      for (double t = 0; t < 2; t += 0.1) {
        final angle = arm * math.pi + t * 1.5;
        final r = 5 + t * 8;
        final px = x + r * math.cos(angle);
        final py = y + r * math.sin(angle);
        if (t == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(path, armPaint);
    }
  }

  void _drawGalaxy(Canvas canvas, double x, double y, int type, double redshift, bool showRedshift) {
    // Color based on redshift
    Color galaxyColor;
    if (showRedshift) {
      // More redshift = more red
      final blueComponent = (1 - redshift.clamp(0, 1)) * 255;
      final redComponent = 200 + redshift.clamp(0, 1) * 55;
      galaxyColor = Color.fromARGB(255, redComponent.toInt(), 150, blueComponent.toInt());
    } else {
      galaxyColor = const Color(0xFFE6E6FA);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          galaxyColor,
          galaxyColor.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 12));

    canvas.drawCircle(Offset(x, y), 12, glowPaint);

    switch (type) {
      case 0: // Spiral
        _drawSpiralGalaxy(canvas, x, y, galaxyColor);
        break;
      case 1: // Elliptical
        _drawEllipticalGalaxy(canvas, x, y, galaxyColor);
        break;
      case 2: // Irregular
        _drawIrregularGalaxy(canvas, x, y, galaxyColor);
        break;
    }
  }

  void _drawSpiralGalaxy(Canvas canvas, double x, double y, Color color) {
    canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);

    final armPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int arm = 0; arm < 2; arm++) {
      final path = Path();
      for (double t = 0; t < 1.5; t += 0.1) {
        final angle = arm * math.pi + t * 1.2;
        final r = 2 + t * 4;
        final px = x + r * math.cos(angle);
        final py = y + r * math.sin(angle);
        if (t == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(path, armPaint);
    }
  }

  void _drawEllipticalGalaxy(Canvas canvas, double x, double y, Color color) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 10, height: 6),
      Paint()..color = color,
    );
  }

  void _drawIrregularGalaxy(Canvas canvas, double x, double y, Color color) {
    final random = math.Random((x * y).toInt());
    for (int i = 0; i < 5; i++) {
      final dx = (random.nextDouble() - 0.5) * 8;
      final dy = (random.nextDouble() - 0.5) * 8;
      canvas.drawCircle(
        Offset(x + dx, y + dy),
        random.nextDouble() * 2 + 1,
        Paint()..color = color.withValues(alpha: 0.8),
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size, double cx, double cy) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Observer label
    textPainter.text = TextSpan(
      text: isKorean ? '관측자 (우리 은하)' : 'Observer (Milky Way)',
      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy + 30));

    // Hubble constant display
    textPainter.text = TextSpan(
      text: 'H₀ = ${hubbleConstant.toStringAsFixed(0)} km/s/Mpc',
      style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height - 25));

    // Legend
    if (showRedshift) {
      textPainter.text = TextSpan(
        text: isKorean ? '적색편이 ← → 청색' : 'Redshift ← → Blue',
        style: const TextStyle(color: Colors.white54, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, 10));
    }
  }

  @override
  bool shouldRepaint(covariant CosmicExpansionPainter oldDelegate) {
    return hubbleConstant != oldDelegate.hubbleConstant ||
        time != oldDelegate.time ||
        showRedshift != oldDelegate.showRedshift ||
        showVelocityVectors != oldDelegate.showVelocityVectors;
  }
}
