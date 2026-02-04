import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// N-Body Gravitational Simulation
class NBodyScreen extends StatefulWidget {
  const NBodyScreen({super.key});

  @override
  State<NBodyScreen> createState() => _NBodyScreenState();
}

class _NBodyScreenState extends State<NBodyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int _numBodies = 5;
  double _gravitationalConstant = 1.0;
  double _timeStep = 0.5;
  bool _isAnimating = true;
  bool _showTrails = true;
  bool _showVelocities = false;
  bool _isKorean = true;

  late List<Body> _bodies;
  final List<List<Offset>> _trails = [];

  @override
  void initState() {
    super.initState();
    _initBodies();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateSimulation);
    _controller.repeat();
  }

  void _initBodies() {
    final random = math.Random(42);
    _bodies = [];
    _trails.clear();

    // Central massive body (like a star)
    _bodies.add(Body(
      x: 0,
      y: 0,
      vx: 0,
      vy: 0,
      mass: 100,
      color: const Color(0xFFFFD700),
      radius: 15,
    ));
    _trails.add([]);

    // Orbiting bodies
    for (int i = 1; i < _numBodies; i++) {
      final orbitRadius = 50 + i * 30.0 + random.nextDouble() * 20;
      final angle = random.nextDouble() * 2 * math.pi;
      final x = orbitRadius * math.cos(angle);
      final y = orbitRadius * math.sin(angle);

      // Circular orbit velocity
      final speed = math.sqrt(_gravitationalConstant * 100 / orbitRadius) * 0.8;
      final vx = -speed * math.sin(angle);
      final vy = speed * math.cos(angle);

      _bodies.add(Body(
        x: x,
        y: y,
        vx: vx,
        vy: vy,
        mass: 1 + random.nextDouble() * 5,
        color: _getBodyColor(i),
        radius: 5 + random.nextDouble() * 3,
      ));
      _trails.add([]);
    }
  }

  Color _getBodyColor(int index) {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFF4169E1),
      const Color(0xFFCD5C5C),
      const Color(0xFF32CD32),
      const Color(0xFF9370DB),
      const Color(0xFFFF6B35),
      const Color(0xFF00CED1),
      const Color(0xFFFF69B4),
    ];
    return colors[index % colors.length];
  }

  void _updateSimulation() {
    if (!_isAnimating) return;

    setState(() {
      // Calculate forces and update velocities
      for (int i = 0; i < _bodies.length; i++) {
        double ax = 0, ay = 0;

        for (int j = 0; j < _bodies.length; j++) {
          if (i == j) continue;

          final dx = _bodies[j].x - _bodies[i].x;
          final dy = _bodies[j].y - _bodies[i].y;
          final distSq = dx * dx + dy * dy + 100; // Softening to prevent singularities
          final dist = math.sqrt(distSq);

          final force = _gravitationalConstant * _bodies[j].mass / distSq;
          ax += force * dx / dist;
          ay += force * dy / dist;
        }

        _bodies[i].vx += ax * _timeStep;
        _bodies[i].vy += ay * _timeStep;
      }

      // Update positions and trails
      for (int i = 0; i < _bodies.length; i++) {
        _bodies[i].x += _bodies[i].vx * _timeStep;
        _bodies[i].y += _bodies[i].vy * _timeStep;

        // Add to trail
        if (_showTrails) {
          _trails[i].add(Offset(_bodies[i].x, _bodies[i].y));
          if (_trails[i].length > 100) {
            _trails[i].removeAt(0);
          }
        }
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _initBodies();
    });
  }

  void _changeNumBodies(int num) {
    setState(() {
      _numBodies = num;
      _initBodies();
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
              _isKorean ? 'N체 문제' : 'N-Body Simulation',
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
          title: _isKorean ? 'N체 문제' : 'N-Body Simulation',
          formula: 'F = G × m₁m₂/r²',
          formulaDescription: _isKorean
              ? 'N체 문제는 상호 중력으로 상호작용하는 여러 천체의 운동을 계산합니다. 3체 이상에서는 일반적으로 해석적 해가 없어 수치적 방법이 필요합니다.'
              : 'The N-body problem calculates motion of multiple bodies interacting via gravity. For 3+ bodies, no general analytical solution exists, requiring numerical methods.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: NBodyPainter(
                bodies: _bodies,
                trails: _trails,
                showTrails: _showTrails,
                showVelocities: _showVelocities,
                isKorean: _isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PresetGroup(
                label: _isKorean ? '천체 수' : 'Number of Bodies',
                presets: [3, 4, 5, 6, 8].map((n) {
                  return PresetButton(
                    label: '$n',
                    isSelected: _numBodies == n,
                    onPressed: () => _changeNumBodies(n),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: _isKorean ? '중력 상수' : 'Gravitational Constant',
                  value: _gravitationalConstant,
                  min: 0.5,
                  max: 2.0,
                  defaultValue: 1.0,
                  formatValue: (v) => 'G = ${v.toStringAsFixed(2)}',
                  onChanged: (v) => setState(() => _gravitationalConstant = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '시간 단계' : 'Time Step',
                    value: _timeStep,
                    min: 0.1,
                    max: 1.0,
                    defaultValue: 0.5,
                    formatValue: (v) => 'dt = ${v.toStringAsFixed(2)}',
                    onChanged: (v) => setState(() => _timeStep = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '궤적 표시' : 'Show Trails',
                    value: _showTrails,
                    onChanged: (v) => setState(() {
                      _showTrails = v;
                      if (!v) {
                        for (var trail in _trails) {
                          trail.clear();
                        }
                      }
                    }),
                  ),
                  SimToggle(
                    label: _isKorean ? '속도 벡터' : 'Velocity Vectors',
                    value: _showVelocities,
                    onChanged: (v) => setState(() => _showVelocities = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                numBodies: _numBodies,
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

class Body {
  double x, y;
  double vx, vy;
  double mass;
  Color color;
  double radius;

  Body({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.mass,
    required this.color,
    required this.radius,
  });
}

class _InfoCard extends StatelessWidget {
  final int numBodies;
  final bool isKorean;

  const _InfoCard({
    required this.numBodies,
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
              Icon(Icons.blur_circular, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                isKorean ? '$numBodies체 시뮬레이션' : '$numBodies-Body System',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? numBodies >= 3
                    ? '혼돈적 거동이 나타날 수 있음'
                    : '안정적인 2체 궤도'
                : numBodies >= 3
                    ? 'Chaotic behavior may emerge'
                    : 'Stable two-body orbit',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class NBodyPainter extends CustomPainter {
  final List<Body> bodies;
  final List<List<Offset>> trails;
  final bool showTrails;
  final bool showVelocities;
  final bool isKorean;

  NBodyPainter({
    required this.bodies,
    required this.trails,
    required this.showTrails,
    required this.showVelocities,
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

    // Draw trails
    if (showTrails) {
      for (int i = 0; i < trails.length && i < bodies.length; i++) {
        if (trails[i].length < 2) continue;

        final trailPath = Path();
        bool first = true;

        for (final point in trails[i]) {
          final screenX = centerX + point.dx;
          final screenY = centerY + point.dy;

          if (first) {
            trailPath.moveTo(screenX, screenY);
            first = false;
          } else {
            trailPath.lineTo(screenX, screenY);
          }
        }

        canvas.drawPath(
          trailPath,
          Paint()
            ..color = bodies[i].color.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // Draw bodies
    for (int i = 0; i < bodies.length; i++) {
      final body = bodies[i];
      final screenX = centerX + body.x;
      final screenY = centerY + body.y;

      // Skip if outside canvas
      if (screenX < -50 || screenX > size.width + 50 ||
          screenY < -50 || screenY > size.height + 50) {
        continue;
      }

      // Glow
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            body.color,
            body.color.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(screenX, screenY), radius: body.radius * 2));
      canvas.drawCircle(Offset(screenX, screenY), body.radius * 2, glowPaint);

      // Body
      final bodyGradient = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white,
          body.color,
        ],
      ).createShader(Rect.fromCircle(center: Offset(screenX, screenY), radius: body.radius));
      canvas.drawCircle(Offset(screenX, screenY), body.radius, Paint()..shader = bodyGradient);

      // Velocity vector
      if (showVelocities) {
        final vScale = 10.0;
        final vx = screenX + body.vx * vScale;
        final vy = screenY + body.vy * vScale;

        canvas.drawLine(
          Offset(screenX, screenY),
          Offset(vx, vy),
          Paint()
            ..color = const Color(0xFF00FF88)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Legend
    _drawLegend(canvas, size);
  }

  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42);
    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(
        Offset(x, y),
        random.nextDouble() * 0.8 + 0.2,
        Paint()..color = Colors.white.withValues(alpha: random.nextDouble() * 0.3 + 0.1),
      );
    }
  }

  void _drawLegend(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: isKorean ? '중심: 항성, 주변: 행성' : 'Center: Star, Orbiting: Planets',
      style: const TextStyle(color: Colors.white54, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height - 20));
  }

  @override
  bool shouldRepaint(covariant NBodyPainter oldDelegate) {
    return true; // Always repaint for smooth animation
  }
}
