import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Gravitational Field (General Relativity) Simulation
class GravityRelativityScreen extends StatefulWidget {
  const GravityRelativityScreen({super.key});

  @override
  State<GravityRelativityScreen> createState() => _GravityRelativityScreenState();
}

class _GravityRelativityScreenState extends State<GravityRelativityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _mass = 1.0; // Solar masses
  double _time = 0.0;
  bool _isAnimating = true;
  bool _showFieldLines = true;
  bool _showSpacetimeCurvature = true;
  bool _showTestParticles = true;
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
              _isKorean ? '중력장 (일반 상대성)' : 'Gravitational Field (GR)',
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
          title: _isKorean ? '중력장 (일반 상대성)' : 'Gravitational Field',
          formula: 'Gμν + Λgμν = (8πG/c⁴)Tμν',
          formulaDescription: _isKorean
              ? '아인슈타인 장 방정식: 질량과 에너지가 시공간의 곡률을 결정합니다. 중력은 힘이 아니라 시공간의 기하학적 성질입니다.'
              : 'Einstein Field Equations: Mass and energy determine spacetime curvature. Gravity is not a force but a geometric property of spacetime.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: GravityRelativityPainter(
                mass: _mass,
                time: _time,
                showFieldLines: _showFieldLines,
                showSpacetimeCurvature: _showSpacetimeCurvature,
                showTestParticles: _showTestParticles,
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
                  label: _isKorean ? '질량' : 'Mass',
                  value: _mass,
                  min: 0.5,
                  max: 5.0,
                  defaultValue: 1.0,
                  formatValue: (v) => '${v.toStringAsFixed(1)} M☉',
                  onChanged: (v) => setState(() => _mass = v),
                ),
                advancedControls: [
                  SimToggle(
                    label: _isKorean ? '장선 표시' : 'Field Lines',
                    value: _showFieldLines,
                    onChanged: (v) => setState(() => _showFieldLines = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '시공간 곡률' : 'Spacetime Curvature',
                    value: _showSpacetimeCurvature,
                    onChanged: (v) => setState(() => _showSpacetimeCurvature = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '시험 입자' : 'Test Particles',
                    value: _showTestParticles,
                    onChanged: (v) => setState(() => _showTestParticles = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(mass: _mass, isKorean: _isKorean),
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
  final double mass;
  final bool isKorean;

  const _InfoCard({required this.mass, required this.isKorean});

  @override
  Widget build(BuildContext context) {
    final schwarzschildRadius = 2.95 * mass; // km

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
          Text(
            isKorean ? '일반 상대성이론의 핵심:' : 'Key Insight of GR:',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? '"질량은 시공간에게 어떻게 휘어질지 말하고, 시공간은 질량에게 어떻게 움직일지 말한다"'
                : '"Matter tells spacetime how to curve, spacetime tells matter how to move"',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? '슈바르츠실트 반경: ${schwarzschildRadius.toStringAsFixed(1)} km'
                : 'Schwarzschild Radius: ${schwarzschildRadius.toStringAsFixed(1)} km',
            style: TextStyle(color: AppColors.accent, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class GravityRelativityPainter extends CustomPainter {
  final double mass;
  final double time;
  final bool showFieldLines;
  final bool showSpacetimeCurvature;
  final bool showTestParticles;
  final bool isKorean;

  GravityRelativityPainter({
    required this.mass,
    required this.time,
    required this.showFieldLines,
    required this.showSpacetimeCurvature,
    required this.showTestParticles,
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

    // Draw spacetime curvature (embedded surface)
    if (showSpacetimeCurvature) {
      _drawSpacetimeCurvature(canvas, centerX, centerY, size);
    }

    // Draw field lines
    if (showFieldLines) {
      _drawFieldLines(canvas, centerX, centerY);
    }

    // Draw massive object
    _drawMassiveObject(canvas, centerX, centerY);

    // Draw test particles following geodesics
    if (showTestParticles) {
      _drawTestParticles(canvas, centerX, centerY);
    }

    // Labels
    _drawLabels(canvas, size, centerX, centerY);
  }

  void _drawSpacetimeCurvature(Canvas canvas, double cx, double cy, Size size) {
    // Draw a grid that warps around the mass
    final gridPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Horizontal lines (warped)
    for (double y = -150; y <= 150; y += 20) {
      final path = Path();
      bool first = true;

      for (double x = -180; x <= 180; x += 5) {
        final dx = x;
        final dy = y;
        final dist = math.sqrt(dx * dx + dy * dy);

        // Warping effect based on distance and mass
        double warpedY = y;
        if (dist > 20) {
          final warpFactor = mass * 800 / (dist * dist);
          warpedY = y + warpFactor * (y > 0 ? 1 : -1);
        }

        final screenX = cx + x;
        final screenY = cy + warpedY;

        if (first) {
          path.moveTo(screenX, screenY);
          first = false;
        } else {
          path.lineTo(screenX, screenY);
        }
      }

      canvas.drawPath(path, gridPaint);
    }

    // Vertical lines (warped)
    for (double x = -180; x <= 180; x += 20) {
      final path = Path();
      bool first = true;

      for (double y = -150; y <= 150; y += 5) {
        final dx = x;
        final dy = y;
        final dist = math.sqrt(dx * dx + dy * dy);

        double warpedX = x;
        if (dist > 20) {
          final warpFactor = mass * 800 / (dist * dist);
          warpedX = x + warpFactor * (x > 0 ? 1 : -1);
        }

        final screenX = cx + warpedX;
        final screenY = cy + y;

        if (first) {
          path.moveTo(screenX, screenY);
          first = false;
        } else {
          path.lineTo(screenX, screenY);
        }
      }

      canvas.drawPath(path, gridPaint);
    }
  }

  void _drawFieldLines(Canvas canvas, double cx, double cy) {
    final fieldPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    // Radial field lines
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi / 8;
      final innerRadius = 40.0 * math.sqrt(mass);
      final outerRadius = 150.0;

      canvas.drawLine(
        Offset(cx + innerRadius * math.cos(angle), cy + innerRadius * math.sin(angle)),
        Offset(cx + outerRadius * math.cos(angle), cy + outerRadius * math.sin(angle)),
        fieldPaint,
      );
    }

    // Equipotential circles
    for (double r = 60; r <= 150; r += 30) {
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }
  }

  void _drawMassiveObject(Canvas canvas, double cx, double cy) {
    final radius = 25 * math.sqrt(mass);

    // Glow effect
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700),
          const Color(0xFFFF8C00).withValues(alpha: 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius * 2));
    canvas.drawCircle(Offset(cx, cy), radius * 2, glowPaint);

    // Mass body
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          const Color(0xFFFFD700),
          const Color(0xFFFF8C00),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawCircle(Offset(cx, cy), radius, bodyPaint);
  }

  void _drawTestParticles(Canvas canvas, double cx, double cy) {
    // Orbiting test particles
    for (int i = 0; i < 4; i++) {
      final orbitRadius = 70 + i * 25.0;
      final orbitalSpeed = 1 / math.sqrt(orbitRadius / 50);
      final angle = time * orbitalSpeed + i * math.pi / 2;

      final px = cx + orbitRadius * math.cos(angle);
      final py = cy + orbitRadius * math.sin(angle);

      // Particle trail
      final trailPaint = Paint()
        ..color = Colors.cyan.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final trailPath = Path();
      for (double t = 0; t < 1; t += 0.05) {
        final trailAngle = angle - t * 0.5;
        final tx = cx + orbitRadius * math.cos(trailAngle);
        final ty = cy + orbitRadius * math.sin(trailAngle);
        if (t == 0) {
          trailPath.moveTo(tx, ty);
        } else {
          trailPath.lineTo(tx, ty);
        }
      }
      canvas.drawPath(trailPath, trailPaint);

      // Particle
      canvas.drawCircle(
        Offset(px, py),
        4,
        Paint()..color = Colors.cyan,
      );
    }

    // Falling particle (demonstrating geodesic)
    final fallProgress = (time % 3) / 3;
    final fallX = cx + 120 * (1 - fallProgress);
    final fallY = cy - 80 + 80 * fallProgress * fallProgress;

    if (fallProgress < 0.9) {
      canvas.drawCircle(
        Offset(fallX, fallY),
        5,
        Paint()..color = Colors.green,
      );

      // Velocity arrow
      final vx = -30.0;
      final vy = 40 * fallProgress;
      canvas.drawLine(
        Offset(fallX, fallY),
        Offset(fallX + vx * 0.5, fallY + vy * 0.5),
        Paint()
          ..color = Colors.green.withValues(alpha: 0.8)
          ..strokeWidth = 2,
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size, double cx, double cy) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Mass label
    textPainter.text = TextSpan(
      text: '${mass.toStringAsFixed(1)} M☉',
      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy + 35 * math.sqrt(mass)));

    // Curvature indication
    if (showSpacetimeCurvature) {
      textPainter.text = TextSpan(
        text: isKorean ? '시공간 곡률' : 'Spacetime Curvature',
        style: TextStyle(color: AppColors.accent.withValues(alpha: 0.7), fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, size.height - 25));
    }
  }

  @override
  bool shouldRepaint(covariant GravityRelativityPainter oldDelegate) {
    return mass != oldDelegate.mass ||
        time != oldDelegate.time ||
        showFieldLines != oldDelegate.showFieldLines ||
        showSpacetimeCurvature != oldDelegate.showSpacetimeCurvature ||
        showTestParticles != oldDelegate.showTestParticles;
  }
}
