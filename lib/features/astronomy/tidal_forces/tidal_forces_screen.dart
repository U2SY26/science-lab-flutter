import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Tidal Forces Simulation
class TidalForcesScreen extends StatefulWidget {
  const TidalForcesScreen({super.key});

  @override
  State<TidalForcesScreen> createState() => _TidalForcesScreenState();
}

class _TidalForcesScreenState extends State<TidalForcesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _moonDistance = 1.0; // Normalized distance (1 = current Moon distance)
  double _time = 0.0;
  bool _isAnimating = true;
  double _animationSpeed = 1.0;
  bool _showForceVectors = true;
  bool _showTidalBulge = true;
  bool _showMoon = true;
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
      _time += 0.01 * _animationSpeed;
      if (_time >= 2 * math.pi) _time -= 2 * math.pi;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _moonDistance = 1.0;
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
    // Tidal force scales with 1/r^3
    final tidalStrength = 1 / math.pow(_moonDistance, 3);

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
              _isKorean ? '조석력' : 'Tidal Forces',
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
          title: _isKorean ? '조석력' : 'Tidal Forces',
          formula: 'F_tidal ∝ M/r³',
          formulaDescription: _isKorean
              ? '조석력은 두 점 사이의 중력 차이로 발생합니다. 달이 지구 가까운 쪽과 먼 쪽에 작용하는 중력 차이가 조수를 만듭니다. 힘은 거리의 세제곱에 반비례합니다.'
              : 'Tidal force arises from the difference in gravitational pull between two points. The Moon\'s pull on Earth\'s near and far sides creates tides. Force scales as 1/r³.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: TidalForcesPainter(
                moonDistance: _moonDistance,
                time: _time,
                tidalStrength: tidalStrength,
                showForceVectors: _showForceVectors,
                showTidalBulge: _showTidalBulge,
                showMoon: _showMoon,
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
                  label: _isKorean ? '달 거리' : 'Moon Distance',
                  value: _moonDistance,
                  min: 0.5,
                  max: 2.0,
                  defaultValue: 1.0,
                  formatValue: (v) => '${(v * 384400).toStringAsFixed(0)} km',
                  onChanged: (v) => setState(() => _moonDistance = v),
                ),
                advancedControls: [
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
                    label: _isKorean ? '힘 벡터 표시' : 'Force Vectors',
                    value: _showForceVectors,
                    onChanged: (v) => setState(() => _showForceVectors = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '조수 팽창 표시' : 'Tidal Bulge',
                    value: _showTidalBulge,
                    onChanged: (v) => setState(() => _showTidalBulge = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '달 표시' : 'Show Moon',
                    value: _showMoon,
                    onChanged: (v) => setState(() => _showMoon = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                tidalStrength: tidalStrength,
                moonDistance: _moonDistance,
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

class _InfoCard extends StatelessWidget {
  final double tidalStrength;
  final double moonDistance;
  final bool isKorean;

  const _InfoCard({
    required this.tidalStrength,
    required this.moonDistance,
    required this.isKorean,
  });

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
              Icon(Icons.waves, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                isKorean ? '상대적 조석력' : 'Relative Tidal Strength',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${tidalStrength.toStringAsFixed(2)}x',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? '달이 가까워지면 조석력은 기하급수적으로 증가합니다'
                : 'Tidal force increases dramatically as Moon approaches',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class TidalForcesPainter extends CustomPainter {
  final double moonDistance;
  final double time;
  final double tidalStrength;
  final bool showForceVectors;
  final bool showTidalBulge;
  final bool showMoon;
  final bool isKorean;

  TidalForcesPainter({
    required this.moonDistance,
    required this.time,
    required this.tidalStrength,
    required this.showForceVectors,
    required this.showTidalBulge,
    required this.showMoon,
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

    // Stars
    _drawStars(canvas, size);

    // Draw Earth with tidal bulge
    _drawEarth(canvas, centerX, centerY, size);

    // Draw Moon
    if (showMoon) {
      _drawMoon(canvas, centerX, centerY, size);
    }

    // Draw force vectors
    if (showForceVectors) {
      _drawForceVectors(canvas, centerX, centerY, size);
    }

    // Labels
    _drawLabels(canvas, size, centerX, centerY);
  }

  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42);
    for (int i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(
        Offset(x, y),
        random.nextDouble() * 1.0 + 0.3,
        Paint()..color = Colors.white.withValues(alpha: random.nextDouble() * 0.4 + 0.1),
      );
    }
  }

  void _drawEarth(Canvas canvas, double cx, double cy, Size size) {
    final baseRadius = 50.0;

    // Moon angle (rotating)
    final moonAngle = time;

    // Tidal bulge elongation toward/away from Moon
    final bulgeAmount = tidalStrength * 8;

    if (showTidalBulge) {
      // Draw ocean (tidal bulge)
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(moonAngle);

      // Water bulge (elongated ellipse)
      final waterPaint = Paint()
        ..color = const Color(0xFF1E90FF).withValues(alpha: 0.6);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: (baseRadius + bulgeAmount) * 2,
          height: (baseRadius - bulgeAmount * 0.3) * 2,
        ),
        waterPaint,
      );

      canvas.restore();
    }

    // Earth core (solid)
    final earthGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        const Color(0xFF4169E1),
        const Color(0xFF1E3A8A),
        const Color(0xFF0F172A),
      ],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: baseRadius - 5));

    canvas.drawCircle(Offset(cx, cy), baseRadius - 5, Paint()..shader = earthGradient);

    // Continents (simplified)
    final landPaint = Paint()..color = const Color(0xFF228B22).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx - 15, cy - 10), 12, landPaint);
    canvas.drawCircle(Offset(cx + 10, cy + 15), 15, landPaint);
    canvas.drawCircle(Offset(cx + 20, cy - 15), 8, landPaint);

    // High tide markers
    if (showTidalBulge) {
      final highTideColor = const Color(0xFF00CED1);

      // Near side high tide
      final nearX = cx + (baseRadius + bulgeAmount) * math.cos(moonAngle);
      final nearY = cy + (baseRadius + bulgeAmount) * math.sin(moonAngle);
      canvas.drawCircle(Offset(nearX, nearY), 5, Paint()..color = highTideColor);

      // Far side high tide
      final farX = cx - (baseRadius + bulgeAmount) * math.cos(moonAngle);
      final farY = cy - (baseRadius + bulgeAmount) * math.sin(moonAngle);
      canvas.drawCircle(Offset(farX, farY), 5, Paint()..color = highTideColor);

      // Low tide markers (90 degrees offset)
      final lowTideColor = const Color(0xFF4682B4);
      final lowAngle = moonAngle + math.pi / 2;
      final lowX1 = cx + (baseRadius - bulgeAmount * 0.3) * math.cos(lowAngle);
      final lowY1 = cy + (baseRadius - bulgeAmount * 0.3) * math.sin(lowAngle);
      canvas.drawCircle(Offset(lowX1, lowY1), 4, Paint()..color = lowTideColor);

      final lowX2 = cx - (baseRadius - bulgeAmount * 0.3) * math.cos(lowAngle);
      final lowY2 = cy - (baseRadius - bulgeAmount * 0.3) * math.sin(lowAngle);
      canvas.drawCircle(Offset(lowX2, lowY2), 4, Paint()..color = lowTideColor);
    }
  }

  void _drawMoon(Canvas canvas, double cx, double cy, Size size) {
    final moonOrbitRadius = 80 + moonDistance * 60;
    final moonAngle = time;
    final moonX = cx + moonOrbitRadius * math.cos(moonAngle);
    final moonY = cy + moonOrbitRadius * math.sin(moonAngle);

    // Moon orbit
    canvas.drawCircle(
      Offset(cx, cy),
      moonOrbitRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Moon shadow
    canvas.drawCircle(
      Offset(moonX + 1, moonY + 1),
      15,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Moon
    final moonGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        const Color(0xFFD4D4D4),
        const Color(0xFF888888),
      ],
    ).createShader(Rect.fromCircle(center: Offset(moonX, moonY), radius: 15));

    canvas.drawCircle(Offset(moonX, moonY), 15, Paint()..shader = moonGradient);

    // Craters
    final craterPaint = Paint()..color = const Color(0xFF666666);
    canvas.drawCircle(Offset(moonX - 4, moonY - 3), 3, craterPaint);
    canvas.drawCircle(Offset(moonX + 5, moonY + 2), 2.5, craterPaint);
  }

  void _drawForceVectors(Canvas canvas, double cx, double cy, Size size) {
    final moonAngle = time;
    final earthRadius = 50.0;

    // Draw differential gravity vectors around Earth
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final pointX = cx + earthRadius * math.cos(angle);
      final pointY = cy + earthRadius * math.sin(angle);

      // Calculate tidal force direction and magnitude
      // Tidal force points away from center toward/away from Moon
      final toMoonAngle = moonAngle;
      final relativeAngle = angle - toMoonAngle;

      // Tidal force is radial (toward/away from Moon direction)
      final forceMagnitude = tidalStrength * 20 * math.cos(relativeAngle);
      final forceAngle = relativeAngle.abs() < math.pi / 2 ? toMoonAngle : toMoonAngle + math.pi;

      if (forceMagnitude.abs() > 2) {
        final endX = pointX + forceMagnitude * math.cos(forceAngle);
        final endY = pointY + forceMagnitude * math.sin(forceAngle);

        final arrowPaint = Paint()
          ..color = forceMagnitude > 0
              ? const Color(0xFF00FF88).withValues(alpha: 0.8)
              : const Color(0xFFFF6B6B).withValues(alpha: 0.8)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(Offset(pointX, pointY), Offset(endX, endY), arrowPaint);

        // Arrow head
        final arrowHeadAngle = math.atan2(endY - pointY, endX - pointX);
        canvas.drawLine(
          Offset(endX, endY),
          Offset(
            endX - 6 * math.cos(arrowHeadAngle - 0.5),
            endY - 6 * math.sin(arrowHeadAngle - 0.5),
          ),
          arrowPaint,
        );
        canvas.drawLine(
          Offset(endX, endY),
          Offset(
            endX - 6 * math.cos(arrowHeadAngle + 0.5),
            endY - 6 * math.sin(arrowHeadAngle + 0.5),
          ),
          arrowPaint,
        );
      }
    }
  }

  void _drawLabels(Canvas canvas, Size size, double cx, double cy) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Earth label
    textPainter.text = TextSpan(
      text: isKorean ? '지구' : 'Earth',
      style: TextStyle(color: AppColors.accent, fontSize: 11),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy + 60));

    // Tide explanation
    if (showTidalBulge) {
      textPainter.text = TextSpan(
        text: isKorean ? '만조' : 'High Tide',
        style: const TextStyle(color: Color(0xFF00CED1), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, size.height - 40));

      textPainter.text = TextSpan(
        text: isKorean ? '간조' : 'Low Tide',
        style: const TextStyle(color: Color(0xFF4682B4), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, size.height - 25));
    }
  }

  @override
  bool shouldRepaint(covariant TidalForcesPainter oldDelegate) {
    return moonDistance != oldDelegate.moonDistance ||
        time != oldDelegate.time ||
        showForceVectors != oldDelegate.showForceVectors ||
        showTidalBulge != oldDelegate.showTidalBulge ||
        showMoon != oldDelegate.showMoon;
  }
}
