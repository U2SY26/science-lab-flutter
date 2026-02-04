import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Bloch Sphere Simulation
/// 블로흐 구 시뮬레이션
class BlochSphereScreen extends StatefulWidget {
  const BlochSphereScreen({super.key});

  @override
  State<BlochSphereScreen> createState() => _BlochSphereScreenState();
}

class _BlochSphereScreenState extends State<BlochSphereScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Bloch sphere angles
  static const double _defaultTheta = 45.0;
  static const double _defaultPhi = 0.0;

  double theta = _defaultTheta; // Polar angle (0 to 180)
  double phi = _defaultPhi; // Azimuthal angle (0 to 360)
  bool isRunning = true;
  bool autoRotate = false;
  double viewAngle = 0;

  double time = 0;
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);
    _controller.repeat();
  }

  void _updatePhysics() {
    if (!isRunning) return;
    setState(() {
      time += 0.02;
      if (autoRotate) {
        phi = (phi + 1) % 360;
      }
      viewAngle += 0.005;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      theta = _defaultTheta;
      phi = _defaultPhi;
      autoRotate = false;
    });
  }

  // Qubit state from Bloch sphere angles
  double get alpha => math.cos(theta * math.pi / 360);
  double get betaMagnitude => math.sin(theta * math.pi / 360);
  double get betaReal => betaMagnitude * math.cos(phi * math.pi / 180);
  double get betaImag => betaMagnitude * math.sin(phi * math.pi / 180);

  double get prob0 => alpha * alpha;
  double get prob1 => betaMagnitude * betaMagnitude;

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
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKorean ? '양자역학 시뮬레이션' : 'QUANTUM MECHANICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '블로흐 구' : 'Bloch Sphere',
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
            onPressed: () => setState(() => isKorean = !isKorean),
            tooltip: isKorean ? 'English' : '한국어',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '양자역학 시뮬레이션' : 'QUANTUM MECHANICS',
          title: isKorean ? '블로흐 구' : 'Bloch Sphere',
          formula: '|ψ⟩ = cos(θ/2)|0⟩ + e^(iφ)sin(θ/2)|1⟩',
          formulaDescription: isKorean
              ? '블로흐 구는 단일 큐비트의 모든 가능한 양자 상태를 시각화합니다. '
                  '북극은 |0⟩, 남극은 |1⟩, 적도는 동등한 중첩 상태입니다.'
              : 'The Bloch sphere visualizes all possible quantum states of a single qubit. '
                  'North pole is |0⟩, south pole is |1⟩, equator represents equal superpositions.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: BlochSpherePainter(
                time: time,
                theta: theta,
                phi: phi,
                viewAngle: viewAngle,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimSegment<bool>(
                label: isKorean ? '자동 회전' : 'Auto Rotate',
                options: {
                  false: isKorean ? '끄기' : 'Off',
                  true: isKorean ? '켜기' : 'On',
                },
                selected: autoRotate,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => autoRotate = v);
                },
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '극각 θ (도)' : 'Polar Angle θ (deg)',
                  value: theta,
                  min: 0,
                  max: 180,
                  defaultValue: _defaultTheta,
                  formatValue: (v) => '${v.toInt()}°',
                  onChanged: (v) => setState(() => theta = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '방위각 φ (도)' : 'Azimuthal Angle φ (deg)',
                    value: phi,
                    min: 0,
                    max: 360,
                    defaultValue: _defaultPhi,
                    formatValue: (v) => '${v.toInt()}°',
                    onChanged: (v) => setState(() => phi = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                theta: theta,
                phi: phi,
                prob0: prob0,
                prob1: prob1,
                alpha: alpha,
                betaReal: betaReal,
                betaImag: betaImag,
                isKorean: isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning
                    ? (isKorean ? '정지' : 'Pause')
                    : (isKorean ? '재생' : 'Play'),
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => isRunning = !isRunning);
                },
              ),
              SimButton(
                label: '|0⟩',
                icon: Icons.north,
                onPressed: () => setState(() {
                  theta = 0;
                  phi = 0;
                }),
              ),
              SimButton(
                label: '|+⟩',
                icon: Icons.east,
                onPressed: () => setState(() {
                  theta = 90;
                  phi = 0;
                }),
              ),
              SimButton(
                label: '|1⟩',
                icon: Icons.south,
                onPressed: () => setState(() {
                  theta = 180;
                  phi = 0;
                }),
              ),
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
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

class _PhysicsInfo extends StatelessWidget {
  final double theta;
  final double phi;
  final double prob0;
  final double prob1;
  final double alpha;
  final double betaReal;
  final double betaImag;
  final bool isKorean;

  const _PhysicsInfo({
    required this.theta,
    required this.phi,
    required this.prob0,
    required this.prob1,
    required this.alpha,
    required this.betaReal,
    required this.betaImag,
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
        children: [
          Row(
            children: [
              _InfoItem(
                label: '(θ, φ)',
                value: '(${theta.toInt()}°, ${phi.toInt()}°)',
              ),
              _InfoItem(
                label: 'P(|0⟩)',
                value: '${(prob0 * 100).toInt()}%',
              ),
              _InfoItem(
                label: 'P(|1⟩)',
                value: '${(prob1 * 100).toInt()}%',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '|ψ⟩ = ${alpha.toStringAsFixed(2)}|0⟩ + (${betaReal.toStringAsFixed(2)}${betaImag >= 0 ? "+" : ""}${betaImag.toStringAsFixed(2)}i)|1⟩',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class BlochSpherePainter extends CustomPainter {
  final double time;
  final double theta;
  final double phi;
  final double viewAngle;

  BlochSpherePainter({
    required this.time,
    required this.theta,
    required this.phi,
    required this.viewAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawSphere(canvas, size);
    _drawAxes(canvas, size);
    _drawStateVector(canvas, size);
    _drawSpecialStates(canvas, size);
    _drawLabels(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawSphere(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.45;
    final radius = 120.0;

    // Main sphere outline
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Equator with rotation
    _drawEllipse(canvas, centerX, centerY, radius, radius * 0.3, viewAngle);

    // Vertical meridian
    _drawEllipse(canvas, centerX, centerY, radius * 0.3, radius, viewAngle + math.pi / 2);

    // Additional meridians for 3D effect
    for (double angle = 0; angle < math.pi; angle += math.pi / 4) {
      final tilt = math.cos(angle + viewAngle) * radius;
      if (tilt.abs() < radius * 0.95) {
        _drawEllipse(canvas, centerX, centerY, tilt.abs(), radius,
            viewAngle, alpha: 0.15);
      }
    }

    // Latitude lines
    for (double lat = -60; lat <= 60; lat += 30) {
      if (lat == 0) continue;
      final latRadius = radius * math.cos(lat * math.pi / 180);
      final latY = centerY - radius * math.sin(lat * math.pi / 180);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, latY),
          width: latRadius * 2,
          height: latRadius * 0.3 * 2,
        ),
        Paint()
          ..color = AppColors.muted.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _drawEllipse(Canvas canvas, double cx, double cy, double rx, double ry,
      double rotation, {double alpha = 0.25}) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      Paint()
        ..color = AppColors.muted.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  void _drawAxes(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.45;
    final radius = 120.0;

    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;

    // Z axis (vertical)
    canvas.drawLine(
      Offset(centerX, centerY - radius - 20),
      Offset(centerX, centerY + radius + 20),
      axisPaint,
    );

    // X axis (with perspective)
    final xAxisEnd = radius + 20;
    canvas.drawLine(
      Offset(centerX - xAxisEnd * math.cos(viewAngle), centerY + xAxisEnd * 0.3 * math.sin(viewAngle)),
      Offset(centerX + xAxisEnd * math.cos(viewAngle), centerY - xAxisEnd * 0.3 * math.sin(viewAngle)),
      axisPaint,
    );

    // Y axis (with perspective)
    canvas.drawLine(
      Offset(centerX - xAxisEnd * math.sin(viewAngle), centerY - xAxisEnd * 0.3 * math.cos(viewAngle)),
      Offset(centerX + xAxisEnd * math.sin(viewAngle), centerY + xAxisEnd * 0.3 * math.cos(viewAngle)),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.4)
        ..strokeWidth = 1,
    );
  }

  void _drawStateVector(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.45;
    final radius = 120.0;

    final thetaRad = theta * math.pi / 180;
    final phiRad = phi * math.pi / 180;

    // Calculate 3D position
    final x = radius * math.sin(thetaRad) * math.cos(phiRad + viewAngle);
    final y = radius * math.sin(thetaRad) * math.sin(phiRad + viewAngle);
    final z = -radius * math.cos(thetaRad);

    // Project to 2D
    final screenX = centerX + x;
    final screenY = centerY + z;

    // Draw projection on equator
    if (theta > 5 && theta < 175) {
      final projX = centerX + radius * math.sin(thetaRad) * math.cos(phiRad + viewAngle);
      final projY = centerY + y * 0.3;

      // Projection line
      canvas.drawLine(
        Offset(screenX, screenY),
        Offset(projX, projY),
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );

      // Projection point
      canvas.drawCircle(
        Offset(projX, projY),
        4,
        Paint()..color = AppColors.accent.withValues(alpha: 0.4),
      );
    }

    // State vector
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(screenX, screenY),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 3,
    );

    // Arrowhead
    final arrowSize = 12.0;
    final angle = math.atan2(screenY - centerY, screenX - centerX);

    canvas.drawLine(
      Offset(screenX, screenY),
      Offset(
        screenX - arrowSize * math.cos(angle - 0.4),
        screenY - arrowSize * math.sin(angle - 0.4),
      ),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(screenX, screenY),
      Offset(
        screenX - arrowSize * math.cos(angle + 0.4),
        screenY - arrowSize * math.sin(angle + 0.4),
      ),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 3,
    );

    // State point
    canvas.drawCircle(
      Offset(screenX, screenY),
      8,
      Paint()..color = AppColors.accent,
    );

    // Glow effect
    final glowGradient = RadialGradient(
      colors: [
        AppColors.accent.withValues(alpha: 0.5),
        AppColors.accent.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: Offset(screenX, screenY), radius: 20));

    canvas.drawCircle(
      Offset(screenX, screenY),
      20,
      Paint()..shader = glowGradient,
    );
  }

  void _drawSpecialStates(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.45;
    final radius = 120.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // |0⟩ (North pole)
    textPainter.text = TextSpan(
      text: '|0⟩',
      style: TextStyle(
        color: const Color(0xFF48BB78),
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + 10, centerY - radius - 25));

    canvas.drawCircle(
      Offset(centerX, centerY - radius),
      5,
      Paint()..color = const Color(0xFF48BB78),
    );

    // |1⟩ (South pole)
    textPainter.text = TextSpan(
      text: '|1⟩',
      style: TextStyle(
        color: const Color(0xFFFC8181),
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + 10, centerY + radius + 10));

    canvas.drawCircle(
      Offset(centerX, centerY + radius),
      5,
      Paint()..color = const Color(0xFFFC8181),
    );

    // |+⟩ (on equator, phi=0)
    final plusX = centerX + radius * math.cos(viewAngle);
    final plusY = centerY - radius * 0.3 * math.sin(viewAngle);
    textPainter.text = TextSpan(
      text: '|+⟩',
      style: TextStyle(
        color: const Color(0xFF63B3ED),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(plusX + 5, plusY - 15));

    canvas.drawCircle(
      Offset(plusX, plusY),
      4,
      Paint()..color = const Color(0xFF63B3ED),
    );

    // |-⟩ (on equator, phi=π)
    final minusX = centerX - radius * math.cos(viewAngle);
    final minusY = centerY + radius * 0.3 * math.sin(viewAngle);
    textPainter.text = TextSpan(
      text: '|-⟩',
      style: TextStyle(
        color: const Color(0xFF63B3ED),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(minusX - 20, minusY - 15));

    canvas.drawCircle(
      Offset(minusX, minusY),
      4,
      Paint()..color = const Color(0xFF63B3ED),
    );
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final centerX = size.width / 2;
    final radius = 120.0;

    // Axis labels
    textPainter.text = TextSpan(
      text: 'Z',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX - 20, size.height * 0.45 - radius - 35));

    textPainter.text = TextSpan(
      text: 'X',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + radius + 25, size.height * 0.45 - 5));

    // Current state info
    textPainter.text = TextSpan(
      text: 'θ = ${theta.toInt()}°, φ = ${phi.toInt()}°',
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 12,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.88));

    // Title
    textPainter.text = TextSpan(
      text: 'Bloch Sphere Representation',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.93));
  }

  @override
  bool shouldRepaint(covariant BlochSpherePainter oldDelegate) =>
      time != oldDelegate.time ||
      theta != oldDelegate.theta ||
      phi != oldDelegate.phi ||
      viewAngle != oldDelegate.viewAngle;
}
