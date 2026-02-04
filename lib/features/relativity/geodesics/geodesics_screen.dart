import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Geodesics Simulation
class GeodesicsScreen extends StatefulWidget {
  const GeodesicsScreen({super.key});

  @override
  State<GeodesicsScreen> createState() => _GeodesicsScreenState();
}

class _GeodesicsScreenState extends State<GeodesicsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _mass = 1.0;
  double _impactParameter = 3.0; // How close the geodesic passes
  double _time = 0.0;
  bool _isAnimating = true;
  bool _showMultiplePaths = true;
  bool _showCurvature = true;
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
      _time += 0.02;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _mass = 1.0;
      _impactParameter = 3.0;
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
              _isKorean ? '상대성이론 시뮬레이션' : 'RELATIVITY SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '측지선' : 'Geodesics',
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
          category: _isKorean ? '상대성이론 시뮬레이션' : 'RELATIVITY SIMULATION',
          title: _isKorean ? '측지선' : 'Geodesics',
          formula: 'd²xμ/dτ² + Γμνρ(dxν/dτ)(dxρ/dτ) = 0',
          formulaDescription: _isKorean
              ? '측지선은 휘어진 시공간에서의 "직선"입니다. 자유 낙하하는 물체와 빛은 측지선을 따라 이동합니다. 이것이 일반 상대성이론에서 중력의 본질입니다.'
              : 'Geodesics are "straight lines" in curved spacetime. Free-falling objects and light follow geodesics. This is the essence of gravity in General Relativity.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: GeodesicsPainter(
                mass: _mass,
                impactParameter: _impactParameter,
                time: _time,
                showMultiplePaths: _showMultiplePaths,
                showCurvature: _showCurvature,
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
                  label: _isKorean ? '충돌 매개변수' : 'Impact Parameter',
                  value: _impactParameter,
                  min: 1.5,
                  max: 8.0,
                  defaultValue: 3.0,
                  formatValue: (v) => '${v.toStringAsFixed(1)} rs',
                  onChanged: (v) => setState(() => _impactParameter = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '질량' : 'Mass',
                    value: _mass,
                    min: 0.5,
                    max: 3.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)} M☉',
                    onChanged: (v) => setState(() => _mass = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '여러 경로' : 'Multiple Paths',
                    value: _showMultiplePaths,
                    onChanged: (v) => setState(() => _showMultiplePaths = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '곡률 표시' : 'Show Curvature',
                    value: _showCurvature,
                    onChanged: (v) => setState(() => _showCurvature = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(impactParameter: _impactParameter, isKorean: _isKorean),
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
  final double impactParameter;
  final bool isKorean;

  const _InfoCard({required this.impactParameter, required this.isKorean});

  @override
  Widget build(BuildContext context) {
    String pathType;
    if (impactParameter < 1.5) {
      pathType = isKorean ? '포획 (블랙홀 진입)' : 'Capture (falls into BH)';
    } else if (impactParameter < 2.6) {
      pathType = isKorean ? '광자구 근처' : 'Near photon sphere';
    } else if (impactParameter < 4.0) {
      pathType = isKorean ? '강한 휘어짐' : 'Strong deflection';
    } else {
      pathType = isKorean ? '약한 휘어짐' : 'Weak deflection';
    }

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
              Icon(Icons.route, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                isKorean ? '경로 유형' : 'Path Type',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                pathType,
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? '측지선: 시공간에서 두 사건 사이의 극값 경로'
                : 'Geodesic: Extremal path between events in spacetime',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class GeodesicsPainter extends CustomPainter {
  final double mass;
  final double impactParameter;
  final double time;
  final bool showMultiplePaths;
  final bool showCurvature;
  final bool isKorean;

  GeodesicsPainter({
    required this.mass,
    required this.impactParameter,
    required this.time,
    required this.showMultiplePaths,
    required this.showCurvature,
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

    // Draw curved spacetime grid
    if (showCurvature) {
      _drawCurvedGrid(canvas, centerX, centerY, size);
    }

    // Draw massive object
    _drawMassiveObject(canvas, centerX, centerY);

    // Draw photon sphere
    _drawPhotonSphere(canvas, centerX, centerY);

    // Draw geodesics
    if (showMultiplePaths) {
      _drawMultipleGeodesics(canvas, centerX, centerY, size);
    }

    // Draw main animated geodesic
    _drawAnimatedGeodesic(canvas, centerX, centerY, size);

    // Labels
    _drawLabels(canvas, size, centerX, centerY);
  }

  void _drawCurvedGrid(Canvas canvas, double cx, double cy, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Radial lines
    for (int i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      final innerRadius = 30.0 * math.sqrt(mass);
      final outerRadius = math.min(size.width, size.height) / 2;
      canvas.drawLine(
        Offset(cx + innerRadius * math.cos(angle), cy + innerRadius * math.sin(angle)),
        Offset(cx + outerRadius * math.cos(angle), cy + outerRadius * math.sin(angle)),
        gridPaint,
      );
    }

    // Concentric circles (with spacing affected by curvature)
    for (double r = 40; r < math.min(size.width, size.height) / 2; r += 20) {
      canvas.drawCircle(Offset(cx, cy), r, gridPaint);
    }
  }

  void _drawMassiveObject(Canvas canvas, double cx, double cy) {
    final radius = 25 * math.sqrt(mass);

    // Black hole
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()..color = Colors.black,
    );

    // Edge glow
    final edgeGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFFF4500).withValues(alpha: 0.5),
          Colors.transparent,
        ],
        stops: const [0.7, 0.95, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius * 1.3));
    canvas.drawCircle(Offset(cx, cy), radius * 1.3, edgeGlow);

    // Event horizon
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = Colors.red.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawPhotonSphere(Canvas canvas, double cx, double cy) {
    final rs = 25 * math.sqrt(mass);
    final photonSphereRadius = rs * 1.5;

    canvas.drawCircle(
      Offset(cx, cy),
      photonSphereRadius,
      Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawMultipleGeodesics(Canvas canvas, double cx, double cy, Size size) {
    final impacts = [2.0, 3.0, 4.0, 5.0, 7.0];
    final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.cyan];

    for (int i = 0; i < impacts.length; i++) {
      _drawGeodesicPath(canvas, cx, cy, size, impacts[i], colors[i].withValues(alpha: 0.4));
    }
  }

  void _drawGeodesicPath(Canvas canvas, double cx, double cy, Size size, double b, Color color) {
    final rs = 25 * math.sqrt(mass);
    final path = Path();

    // Simplified geodesic calculation
    bool first = true;
    for (double t = -math.pi * 0.8; t <= math.pi * 0.8; t += 0.05) {
      // Approximate geodesic bending
      final closestApproach = b * rs;
      final bendAngle = (rs / closestApproach) * 2;

      // Parametric curve
      double r, angle;
      if (t < 0) {
        r = closestApproach / math.cos(t * (1 + bendAngle * 0.5));
        angle = t + math.pi;
      } else {
        r = closestApproach / math.cos(t * (1 + bendAngle * 0.5));
        angle = -t + bendAngle;
      }

      if (r > 500 || r < rs) continue;

      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);

      if (x < 0 || x > size.width || y < 0 || y > size.height) continue;

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawAnimatedGeodesic(Canvas canvas, double cx, double cy, Size size) {
    final rs = 25 * math.sqrt(mass);
    final closestApproach = impactParameter * rs;
    final bendAngle = (rs / closestApproach) * 2;

    // Draw full path
    final path = Path();
    bool first = true;
    final points = <Offset>[];

    for (double t = -math.pi * 0.7; t <= math.pi * 0.7; t += 0.03) {
      double r, angle;
      if (t < 0) {
        r = closestApproach / math.max(0.1, math.cos(t * (1 + bendAngle * 0.3)));
        angle = t + math.pi;
      } else {
        r = closestApproach / math.max(0.1, math.cos(t * (1 + bendAngle * 0.3)));
        angle = -t + bendAngle * 0.8;
      }

      if (r > 400 || r < rs) continue;

      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);

      points.add(Offset(x, y));

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw path
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Animated particle
    if (points.isNotEmpty) {
      final progress = (time * 0.5) % 1.0;
      final index = (progress * (points.length - 1)).floor().clamp(0, points.length - 1);
      final particle = points[index];

      // Glow
      canvas.drawCircle(
        particle,
        12,
        Paint()..color = AppColors.accent.withValues(alpha: 0.3),
      );

      // Particle
      canvas.drawCircle(
        particle,
        6,
        Paint()..color = AppColors.accent,
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size, double cx, double cy) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Event horizon label
    textPainter.text = TextSpan(
      text: isKorean ? '사건의 지평선 (rs)' : 'Event Horizon (rs)',
      style: const TextStyle(color: Colors.red, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + 35, cy + 35));

    // Photon sphere label
    textPainter.text = TextSpan(
      text: isKorean ? '광자구 (1.5rs)' : 'Photon Sphere (1.5rs)',
      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + 50, cy - 10));

    // Impact parameter
    textPainter.text = TextSpan(
      text: 'b = ${impactParameter.toStringAsFixed(1)} rs',
      style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 10));

    // Geodesic label
    textPainter.text = TextSpan(
      text: isKorean ? '측지선 (빛/자유낙하 경로)' : 'Geodesic (light/freefall path)',
      style: TextStyle(color: AppColors.accent, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height - 20));
  }

  @override
  bool shouldRepaint(covariant GeodesicsPainter oldDelegate) {
    return mass != oldDelegate.mass ||
        impactParameter != oldDelegate.impactParameter ||
        time != oldDelegate.time ||
        showMultiplePaths != oldDelegate.showMultiplePaths ||
        showCurvature != oldDelegate.showCurvature;
  }
}
