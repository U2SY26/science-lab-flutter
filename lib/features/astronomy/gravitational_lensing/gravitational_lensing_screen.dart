import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Gravitational Lensing Simulation
class GravitationalLensingScreen extends StatefulWidget {
  const GravitationalLensingScreen({super.key});

  @override
  State<GravitationalLensingScreen> createState() => _GravitationalLensingScreenState();
}

class _GravitationalLensingScreenState extends State<GravitationalLensingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _lensMass = 1.0; // Mass of the lens (in solar masses)
  double _sourceDistance = 0.5; // Distance to the source (normalized)
  double _sourceOffset = 0.0; // Vertical offset of source from optical axis
  bool _isAnimating = false;
  double _animationSpeed = 1.0;
  bool _showRays = true;
  bool _showEinsteinRing = true;
  bool _isKorean = true;

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
      _sourceOffset = math.sin(_controller.value * 2 * math.pi * _animationSpeed) * 0.3;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _lensMass = 1.0;
      _sourceOffset = 0.0;
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
    // Calculate Einstein radius
    final einsteinRadius = math.sqrt(_lensMass * _sourceDistance / (1 - _sourceDistance)) * 0.2;

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
              _isKorean ? '중력 렌즈' : 'Gravitational Lensing',
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
          title: _isKorean ? '중력 렌즈' : 'Gravitational Lensing',
          formula: 'θE = √(4GM/c²) × √(DLS/(DL×DS))',
          formulaDescription: _isKorean
              ? '아인슈타인 고리: 빛이 대질량 천체 주변을 지나면서 휘어지는 현상입니다. 광원이 렌즈와 완벽하게 정렬되면 고리 형태로 보입니다.'
              : 'Einstein Ring: Light bends around massive objects. When source aligns perfectly with lens, a ring forms.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: GravitationalLensingPainter(
                lensMass: _lensMass,
                sourceDistance: _sourceDistance,
                sourceOffset: _sourceOffset,
                showRays: _showRays,
                showEinsteinRing: _showEinsteinRing,
                einsteinRadius: einsteinRadius,
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
                  label: _isKorean ? '렌즈 질량' : 'Lens Mass',
                  value: _lensMass,
                  min: 0.5,
                  max: 3.0,
                  defaultValue: 1.0,
                  formatValue: (v) => '${v.toStringAsFixed(1)} M☉',
                  onChanged: (v) => setState(() => _lensMass = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '광원 거리' : 'Source Distance',
                    value: _sourceDistance,
                    min: 0.2,
                    max: 0.9,
                    defaultValue: 0.5,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _sourceDistance = v),
                  ),
                  SimSlider(
                    label: _isKorean ? '광원 오프셋' : 'Source Offset',
                    value: _sourceOffset,
                    min: -0.5,
                    max: 0.5,
                    defaultValue: 0.0,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _sourceOffset = v),
                  ),
                  SimSlider(
                    label: _isKorean ? '애니메이션 속도' : 'Animation Speed',
                    value: _animationSpeed,
                    min: 0.5,
                    max: 2.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() => _animationSpeed = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '광선 표시' : 'Show Light Rays',
                    value: _showRays,
                    onChanged: (v) => setState(() => _showRays = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '아인슈타인 고리' : 'Einstein Ring',
                    value: _showEinsteinRing,
                    onChanged: (v) => setState(() => _showEinsteinRing = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                einsteinRadius: einsteinRadius,
                isKorean: _isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isAnimating
                    ? (_isKorean ? '정지' : 'Stop')
                    : (_isKorean ? '애니메이션' : 'Animate'),
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

class _InfoCard extends StatelessWidget {
  final double einsteinRadius;
  final bool isKorean;

  const _InfoCard({required this.einsteinRadius, required this.isKorean});

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.circle_outlined, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                isKorean ? '아인슈타인 반경' : 'Einstein Radius',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'θE = ${(einsteinRadius * 100).toStringAsFixed(1)}°',
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

class GravitationalLensingPainter extends CustomPainter {
  final double lensMass;
  final double sourceDistance;
  final double sourceOffset;
  final bool showRays;
  final bool showEinsteinRing;
  final double einsteinRadius;
  final bool isKorean;

  GravitationalLensingPainter({
    required this.lensMass,
    required this.sourceDistance,
    required this.sourceOffset,
    required this.showRays,
    required this.showEinsteinRing,
    required this.einsteinRadius,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050510),
    );

    // Stars background
    _drawStars(canvas, size);

    // Draw source galaxy (behind the lens)
    final sourceY = centerY + sourceOffset * size.height * 0.3;
    _drawSourceGalaxy(canvas, size.width * 0.85, sourceY);

    // Draw gravitational lens (massive object in the middle)
    _drawLens(canvas, centerX, centerY);

    // Draw Einstein ring if enabled
    if (showEinsteinRing && sourceOffset.abs() < 0.1) {
      _drawEinsteinRing(canvas, centerX, centerY, einsteinRadius * size.width);
    }

    // Draw light rays
    if (showRays) {
      _drawLightRays(canvas, size, centerX, centerY, sourceY);
    }

    // Draw observer
    _drawObserver(canvas, size.width * 0.1, centerY);

    // Draw lensed images
    _drawLensedImages(canvas, size, centerX, centerY, sourceY);

    // Labels
    _drawLabels(canvas, size, centerX, centerY, sourceY);
  }

  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42);
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.0 + 0.2;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = Colors.white.withValues(alpha: random.nextDouble() * 0.4 + 0.1),
      );
    }
  }

  void _drawSourceGalaxy(Canvas canvas, double x, double y) {
    // Galaxy glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF9370DB),
          const Color(0xFF9370DB).withValues(alpha: 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 25));
    canvas.drawCircle(Offset(x, y), 25, glowPaint);

    // Galaxy core
    canvas.drawCircle(Offset(x, y), 8, Paint()..color = const Color(0xFFE6E6FA));
  }

  void _drawLens(Canvas canvas, double x, double y) {
    final lensRadius = 15 + lensMass * 10;

    // Lens halo (dark matter representation)
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1E90FF).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: lensRadius * 3));
    canvas.drawCircle(Offset(x, y), lensRadius * 3, haloPaint);

    // Lens body
    final lensPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700),
          const Color(0xFFFF8C00),
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: lensRadius));
    canvas.drawCircle(Offset(x, y), lensRadius, lensPaint);
  }

  void _drawEinsteinRing(Canvas canvas, double x, double y, double radius) {
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()
        ..color = const Color(0xFF9370DB).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  void _drawLightRays(Canvas canvas, Size size, double cx, double cy, double sourceY) {
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Draw multiple rays from source bending around the lens
    for (double offset = -0.3; offset <= 0.3; offset += 0.1) {
      final path = Path();
      path.moveTo(size.width * 0.85, sourceY);

      // Bend point near lens
      final bendFactor = lensMass * 0.15;
      final bendY = cy + (sourceY - cy) * 0.5 + offset * size.height * 0.2;
      path.quadraticBezierTo(
        cx + 30,
        bendY - bendFactor * size.height * (sourceY > cy ? 1 : -1),
        size.width * 0.1,
        cy - offset * size.height * 0.3,
      );

      canvas.drawPath(path, rayPaint);
    }
  }

  void _drawObserver(Canvas canvas, double x, double y) {
    // Observer icon (telescope)
    final observerPaint = Paint()..color = const Color(0xFF87CEEB);
    canvas.drawCircle(Offset(x, y), 12, observerPaint);
    canvas.drawRect(
      Rect.fromLTWH(x + 5, y - 3, 20, 6),
      observerPaint,
    );
  }

  void _drawLensedImages(Canvas canvas, Size size, double cx, double cy, double sourceY) {
    if (sourceOffset.abs() < 0.05) return; // Einstein ring instead of images

    final imageRadius = 6.0;
    final imageOffset = einsteinRadius * size.width * 1.2;

    // Two lensed images (above and below the lens)
    final image1Y = cy - imageOffset * (sourceOffset > 0 ? 1.5 : 0.8);
    final image2Y = cy + imageOffset * (sourceOffset > 0 ? 0.8 : 1.5);

    // Image 1 (primary, brighter)
    final image1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF9370DB),
          const Color(0xFF9370DB).withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, image1Y), radius: imageRadius));
    canvas.drawCircle(Offset(cx - 20, image1Y), imageRadius, image1Paint);

    // Image 2 (secondary, dimmer, often inverted)
    final image2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF9370DB).withValues(alpha: 0.6),
          const Color(0xFF9370DB).withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, image2Y), radius: imageRadius * 0.7));
    canvas.drawCircle(Offset(cx - 20, image2Y), imageRadius * 0.7, image2Paint);
  }

  void _drawLabels(Canvas canvas, Size size, double cx, double cy, double sourceY) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Lens label
    textPainter.text = TextSpan(
      text: isKorean ? '중력 렌즈' : 'Lens',
      style: TextStyle(color: AppColors.accent, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy + 35));

    // Source label
    textPainter.text = TextSpan(
      text: isKorean ? '광원' : 'Source',
      style: const TextStyle(color: Color(0xFF9370DB), fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.85 - textPainter.width / 2, sourceY + 30));

    // Observer label
    textPainter.text = TextSpan(
      text: isKorean ? '관측자' : 'Observer',
      style: const TextStyle(color: Color(0xFF87CEEB), fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.1 - textPainter.width / 2, cy + 20));
  }

  @override
  bool shouldRepaint(covariant GravitationalLensingPainter oldDelegate) {
    return lensMass != oldDelegate.lensMass ||
        sourceDistance != oldDelegate.sourceDistance ||
        sourceOffset != oldDelegate.sourceOffset ||
        showRays != oldDelegate.showRays ||
        showEinsteinRing != oldDelegate.showEinsteinRing;
  }
}
