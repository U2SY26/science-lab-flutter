import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Coriolis Effect Simulation
class CoriolisEffectScreen extends StatefulWidget {
  const CoriolisEffectScreen({super.key});

  @override
  State<CoriolisEffectScreen> createState() => _CoriolisEffectScreenState();
}

class _CoriolisEffectScreenState extends State<CoriolisEffectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _time = 0.0;
  double _rotationSpeed = 1.0;
  double _latitude = 45.0; // degrees
  bool _isAnimating = true;
  bool _showEarthRotation = true;
  bool _showProjectile = true;
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
      _time += 0.02 * _rotationSpeed;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _rotationSpeed = 1.0;
      _latitude = 45.0;
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
    // Coriolis parameter
    final coriolisParameter = 2 * 7.29e-5 * math.sin(_latitude * math.pi / 180);

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
              _isKorean ? '지구과학 시뮬레이션' : 'EARTH SCIENCE SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '코리올리 효과' : 'Coriolis Effect',
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
          category: _isKorean ? '지구과학 시뮬레이션' : 'EARTH SCIENCE SIMULATION',
          title: _isKorean ? '코리올리 효과' : 'Coriolis Effect',
          formula: 'f = 2Ω sin(φ)',
          formulaDescription: _isKorean
              ? '코리올리 효과는 회전하는 좌표계에서 나타나는 관성력입니다. 북반구에서는 움직이는 물체가 오른쪽으로, 남반구에서는 왼쪽으로 편향됩니다.'
              : 'The Coriolis effect is an inertial force in rotating reference frames. Moving objects deflect right in NH, left in SH.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: CoriolisEffectPainter(
                time: _time,
                rotationSpeed: _rotationSpeed,
                latitude: _latitude,
                showEarthRotation: _showEarthRotation,
                showProjectile: _showProjectile,
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
                  label: _isKorean ? '위도' : 'Latitude',
                  value: _latitude,
                  min: -90,
                  max: 90,
                  defaultValue: 45,
                  formatValue: (v) => '${v.toStringAsFixed(0)}°${v >= 0 ? 'N' : 'S'}',
                  onChanged: (v) => setState(() => _latitude = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '회전 속도' : 'Rotation Speed',
                    value: _rotationSpeed,
                    min: 0.5,
                    max: 3.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() => _rotationSpeed = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '지구 회전 표시' : 'Earth Rotation',
                    value: _showEarthRotation,
                    onChanged: (v) => setState(() => _showEarthRotation = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '발사체 궤적' : 'Projectile Path',
                    value: _showProjectile,
                    onChanged: (v) => setState(() => _showProjectile = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                latitude: _latitude,
                coriolisParameter: coriolisParameter,
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
  final double latitude;
  final double coriolisParameter;
  final bool isKorean;

  const _InfoCard({
    required this.latitude,
    required this.coriolisParameter,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    final hemisphere = latitude >= 0
        ? (isKorean ? '북반구' : 'Northern Hemisphere')
        : (isKorean ? '남반구' : 'Southern Hemisphere');
    final deflection = latitude >= 0
        ? (isKorean ? '오른쪽으로 편향' : 'Deflects right')
        : (isKorean ? '왼쪽으로 편향' : 'Deflects left');

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
              Icon(Icons.public, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                hemisphere,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                deflection,
                style: TextStyle(
                  color: latitude >= 0 ? Colors.cyan : Colors.orange,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? '코리올리 매개변수 f = ${(coriolisParameter * 1e4).toStringAsFixed(2)} × 10⁻⁴ s⁻¹'
                : 'Coriolis parameter f = ${(coriolisParameter * 1e4).toStringAsFixed(2)} × 10⁻⁴ s⁻¹',
            style: TextStyle(color: AppColors.muted, fontSize: 10, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 4),
          Text(
            isKorean
                ? '적도에서는 0, 극지방에서 최대'
                : 'Zero at equator, maximum at poles',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class CoriolisEffectPainter extends CustomPainter {
  final double time;
  final double rotationSpeed;
  final double latitude;
  final bool showEarthRotation;
  final bool showProjectile;
  final bool isKorean;

  CoriolisEffectPainter({
    required this.time,
    required this.rotationSpeed,
    required this.latitude,
    required this.showEarthRotation,
    required this.showProjectile,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0A0A1A),
    );

    // Draw rotating Earth view from above
    _drawEarthTopView(canvas, centerX, centerY, size);

    // Draw projectile trajectory
    if (showProjectile) {
      _drawProjectileTrajectory(canvas, centerX, centerY, size);
    }

    // Draw wind patterns
    _drawWindPatterns(canvas, centerX, centerY, size);

    // Labels
    _drawLabels(canvas, size, centerX, centerY);
  }

  void _drawEarthTopView(Canvas canvas, double cx, double cy, Size size) {
    final radius = math.min(size.width, size.height) * 0.35;

    // Earth disk
    final earthGradient = RadialGradient(
      colors: [
        const Color(0xFF4169E1),
        const Color(0xFF1E90FF),
        const Color(0xFF0066CC),
      ],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    canvas.drawCircle(Offset(cx, cy), radius, Paint()..shader = earthGradient);

    // Continents (simplified)
    final continentPaint = Paint()..color = const Color(0xFF228B22).withValues(alpha: 0.6);

    // Landmasses (rotating)
    final rotationAngle = showEarthRotation ? time * 0.5 : 0.0;

    for (int i = 0; i < 5; i++) {
      final angle = i * 2 * math.pi / 5 + rotationAngle;
      final dist = radius * (0.3 + (i % 3) * 0.15);
      final landX = cx + dist * math.cos(angle);
      final landY = cy + dist * math.sin(angle);
      final landRadius = 15.0 + (i % 2) * 10;

      canvas.drawCircle(Offset(landX, landY), landRadius, continentPaint);
    }

    // Latitude circles
    final latPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double lat = 30; lat <= 60; lat += 30) {
      final latRadius = radius * math.cos(lat * math.pi / 180);
      canvas.drawCircle(Offset(cx, cy), latRadius, latPaint);
    }

    // Center point (pole)
    canvas.drawCircle(
      Offset(cx, cy),
      5,
      Paint()..color = Colors.white,
    );

    // Rotation direction arrow
    if (showEarthRotation) {
      _drawRotationArrow(canvas, cx, cy, radius);
    }

    // Current latitude indicator
    final latRadius = radius * math.cos(latitude.abs() * math.pi / 180);
    canvas.drawCircle(
      Offset(cx, cy),
      latRadius,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawRotationArrow(Canvas canvas, double cx, double cy, double radius) {
    final arrowRadius = radius + 15;

    // Curved arrow showing rotation
    final path = Path();
    for (double angle = 0; angle < math.pi * 1.5; angle += 0.1) {
      final x = cx + arrowRadius * math.cos(angle);
      final y = cy + arrowRadius * math.sin(angle);
      if (angle == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Arrow head
    final headAngle = math.pi * 1.5;
    final headX = cx + arrowRadius * math.cos(headAngle);
    final headY = cy + arrowRadius * math.sin(headAngle);

    canvas.drawLine(
      Offset(headX, headY),
      Offset(headX + 8, headY - 8),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(headX, headY),
      Offset(headX - 8, headY - 8),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );
  }

  void _drawProjectileTrajectory(Canvas canvas, double cx, double cy, Size size) {
    final radius = math.min(size.width, size.height) * 0.35;
    final latRadius = radius * math.cos(latitude.abs() * math.pi / 180);

    // Starting point
    final startAngle = math.pi;
    final startX = cx + latRadius * math.cos(startAngle);
    final startY = cy + latRadius * math.sin(startAngle);

    // Intended straight path (dotted)
    final intendedEndX = cx + latRadius * math.cos(0);
    final intendedEndY = cy + latRadius * math.sin(0);

    _drawDashedLine(
      canvas,
      Offset(startX, startY),
      Offset(intendedEndX, intendedEndY),
      Colors.grey.withValues(alpha: 0.5),
    );

    // Actual curved path due to Coriolis
    final deflectionSign = latitude >= 0 ? 1.0 : -1.0;
    final deflectionAmount = math.sin(latitude.abs() * math.pi / 180) * 0.3;

    final actualPath = Path();
    actualPath.moveTo(startX, startY);

    for (double t = 0; t <= 1; t += 0.05) {
      final baseAngle = startAngle + t * math.pi;
      final deflection = t * t * deflectionAmount * deflectionSign * math.pi;
      final x = cx + latRadius * math.cos(baseAngle - deflection);
      final y = cy + latRadius * math.sin(baseAngle - deflection);
      actualPath.lineTo(x, y);
    }

    canvas.drawPath(
      actualPath,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Animated projectile
    final progress = (time * 0.5) % 1.0;
    final baseAngle = startAngle + progress * math.pi;
    final deflection = progress * progress * deflectionAmount * deflectionSign * math.pi;
    final projX = cx + latRadius * math.cos(baseAngle - deflection);
    final projY = cy + latRadius * math.sin(baseAngle - deflection);

    canvas.drawCircle(
      Offset(projX, projY),
      6,
      Paint()..color = Colors.red,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final dashLength = 5.0;
    final gapLength = 5.0;

    var currentLength = 0.0;
    var drawing = true;

    while (currentLength < length) {
      final segmentLength = drawing ? dashLength : gapLength;
      final nextLength = math.min(currentLength + segmentLength, length);

      if (drawing) {
        final startX = start.dx + dx * currentLength / length;
        final startY = start.dy + dy * currentLength / length;
        final endX = start.dx + dx * nextLength / length;
        final endY = start.dy + dy * nextLength / length;
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      }

      currentLength = nextLength;
      drawing = !drawing;
    }
  }

  void _drawWindPatterns(Canvas canvas, double cx, double cy, Size size) {
    final radius = math.min(size.width, size.height) * 0.35;

    // Trade winds, westerlies, polar easterlies
    final windZones = [
      [30.0, Colors.orange, 1.0],  // Trade winds
      [45.0, Colors.cyan, -1.0],   // Westerlies
      [70.0, Colors.purple, 1.0],  // Polar easterlies
    ];

    for (final zone in windZones) {
      final zoneLatitude = zone[0] as double;
      final zoneColor = zone[1] as Color;
      final direction = zone[2] as double;

      final zoneRadius = radius * math.cos(zoneLatitude * math.pi / 180);

      // Draw wind arrows around this latitude
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4 + time * 0.2 * direction;
        final arrowX = cx + zoneRadius * math.cos(angle);
        final arrowY = cy + zoneRadius * math.sin(angle);

        // Arrow direction (tangent to circle, deflected)
        final tangentAngle = angle + math.pi / 2 * direction;
        final arrowEndX = arrowX + 15 * math.cos(tangentAngle);
        final arrowEndY = arrowY + 15 * math.sin(tangentAngle);

        canvas.drawLine(
          Offset(arrowX, arrowY),
          Offset(arrowEndX, arrowEndY),
          Paint()
            ..color = zoneColor.withValues(alpha: 0.5)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _drawLabels(Canvas canvas, Size size, double cx, double cy) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final radius = math.min(size.width, size.height) * 0.35;

    // Hemisphere label
    final isNorthern = latitude >= 0;
    textPainter.text = TextSpan(
      text: isKorean
          ? (isNorthern ? '북반구 (위에서 본 모습)' : '남반구 (위에서 본 모습)')
          : (isNorthern ? 'Northern Hemisphere (top view)' : 'Southern Hemisphere (top view)'),
      style: const TextStyle(color: Colors.white70, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 10));

    // Pole label
    textPainter.text = TextSpan(
      text: isKorean ? (isNorthern ? '북극' : '남극') : (isNorthern ? 'N Pole' : 'S Pole'),
      style: const TextStyle(color: Colors.white, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - 20));

    // Rotation direction
    if (showEarthRotation) {
      textPainter.text = TextSpan(
        text: isKorean ? '지구 회전 방향' : 'Earth rotation',
        style: const TextStyle(color: Colors.white54, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(cx + radius + 5, cy - radius - 20));
    }

    // Legend
    if (showProjectile) {
      textPainter.text = TextSpan(
        text: isKorean ? '빨강: 실제 경로, 회색: 의도된 경로' : 'Red: Actual path, Grey: Intended',
        style: const TextStyle(color: Colors.white54, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, size.height - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CoriolisEffectPainter oldDelegate) {
    return time != oldDelegate.time ||
        rotationSpeed != oldDelegate.rotationSpeed ||
        latitude != oldDelegate.latitude ||
        showEarthRotation != oldDelegate.showEarthRotation ||
        showProjectile != oldDelegate.showProjectile;
  }
}
