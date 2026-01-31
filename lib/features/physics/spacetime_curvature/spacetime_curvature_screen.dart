import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 시공간 곡률 시뮬레이션 (일반상대성이론)
class SpacetimeCurvatureScreen extends StatefulWidget {
  const SpacetimeCurvatureScreen({super.key});

  @override
  State<SpacetimeCurvatureScreen> createState() => _SpacetimeCurvatureScreenState();
}

class _SpacetimeCurvatureScreenState extends State<SpacetimeCurvatureScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  List<_MassObject> _masses = [];
  double _gridDensity = 20;
  bool _showGeodesics = true;
  bool _showParticles = true;
  bool _animate = true;
  String _visualization = 'grid';

  List<_TestParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update);
    _controller.repeat();

    // 기본 질량 (태양 같은 큰 질량)
    _masses = [
      _MassObject(position: const Offset(0.5, 0.5), mass: 10, color: Colors.orange),
    ];

    // 테스트 입자들 초기화
    _initParticles();
  }

  void _initParticles() {
    _particles.clear();
    final random = math.Random();
    for (int i = 0; i < 20; i++) {
      _particles.add(_TestParticle(
        position: Offset(random.nextDouble(), random.nextDouble()),
        velocity: Offset(
          (random.nextDouble() - 0.5) * 0.01,
          (random.nextDouble() - 0.5) * 0.01,
        ),
      ));
    }
  }

  void _update() {
    if (!_animate) return;

    setState(() {
      // 입자들을 시공간 곡률에 따라 이동
      for (var particle in _particles) {
        Offset totalAccel = Offset.zero;

        for (var mass in _masses) {
          final dx = mass.position.dx - particle.position.dx;
          final dy = mass.position.dy - particle.position.dy;
          final r = math.sqrt(dx * dx + dy * dy);

          if (r > 0.02) {
            // 일반상대론적 효과를 단순화한 가속도
            final accel = mass.mass * 0.0001 / (r * r);
            totalAccel = Offset(
              totalAccel.dx + accel * dx / r,
              totalAccel.dy + accel * dy / r,
            );
          }
        }

        particle.velocity = Offset(
          particle.velocity.dx + totalAccel.dx,
          particle.velocity.dy + totalAccel.dy,
        );

        particle.position = Offset(
          (particle.position.dx + particle.velocity.dx).clamp(0.0, 1.0),
          (particle.position.dy + particle.velocity.dy).clamp(0.0, 1.0),
        );

        // 속도 감쇠 (시각화를 위해)
        particle.velocity = Offset(
          particle.velocity.dx * 0.999,
          particle.velocity.dy * 0.999,
        );
      }
    });
  }

  void _addMass(Offset position) {
    if (_masses.length < 3) {
      HapticFeedback.mediumImpact();
      setState(() {
        _masses.add(_MassObject(
          position: position,
          mass: 5 + math.Random().nextDouble() * 10,
          color: [Colors.blue, Colors.purple][_masses.length % 2],
        ));
      });
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _masses = [
        _MassObject(position: const Offset(0.5, 0.5), mass: 10, color: Colors.orange),
      ];
      _initParticles();
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
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '물리학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '시공간 곡률',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '일반상대성이론 - 시공간 곡률',
          formula: 'Rμν - ½gμνR = 8πG/c⁴ Tμν',
          formulaDescription: '질량이 시공간을 휘게 하고, 휘어진 시공간이 물체의 운동을 결정',
          simulation: SizedBox(
            height: 320,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    final normalized = Offset(
                      details.localPosition.dx / constraints.maxWidth,
                      details.localPosition.dy / constraints.maxHeight,
                    );
                    _addMass(normalized);
                  },
                  child: CustomPaint(
                    painter: _SpacetimePainter(
                      masses: _masses,
                      particles: _particles,
                      gridDensity: _gridDensity.toInt(),
                      showGeodesics: _showGeodesics,
                      showParticles: _showParticles,
                      visualization: _visualization,
                      time: DateTime.now().millisecondsSinceEpoch / 1000,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아인슈타인 장 방정식 설명
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.withValues(alpha: 0.2),
                      Colors.blue.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Einstein Field Equations',
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 질량은 시공간을 휘게 합니다\n'
                      '• 빛과 물체는 휘어진 시공간을 따라 이동\n'
                      '• 화면을 탭하여 질량 추가 (최대 3개)',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 시각화 모드
              PresetGroup(
                label: '시각화',
                presets: [
                  PresetButton(
                    label: '격자',
                    isSelected: _visualization == 'grid',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _visualization = 'grid');
                    },
                  ),
                  PresetButton(
                    label: '등고선',
                    isSelected: _visualization == 'contour',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _visualization = 'contour');
                    },
                  ),
                  PresetButton(
                    label: '3D 메쉬',
                    isSelected: _visualization == 'mesh',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _visualization = 'mesh');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 옵션들
              Row(
                children: [
                  Expanded(
                    child: _OptionChip(
                      label: '측지선',
                      isSelected: _showGeodesics,
                      onTap: () => setState(() => _showGeodesics = !_showGeodesics),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OptionChip(
                      label: '입자',
                      isSelected: _showParticles,
                      onTap: () => setState(() => _showParticles = !_showParticles),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OptionChip(
                      label: '애니메이션',
                      isSelected: _animate,
                      onTap: () => setState(() => _animate = !_animate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '격자 밀도',
                  value: _gridDensity,
                  min: 10,
                  max: 40,
                  defaultValue: 20,
                  formatValue: (v) => '${v.toInt()}',
                  onChanged: (v) => setState(() => _gridDensity = v),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '리셋',
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

class _MassObject {
  Offset position;
  double mass;
  Color color;

  _MassObject({required this.position, required this.mass, required this.color});
}

class _TestParticle {
  Offset position;
  Offset velocity;

  _TestParticle({required this.position, required this.velocity});
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : AppColors.simBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.accent : AppColors.cardBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: isSelected ? AppColors.accent : AppColors.muted, fontSize: 11),
          ),
        ),
      ),
    );
  }
}

class _SpacetimePainter extends CustomPainter {
  final List<_MassObject> masses;
  final List<_TestParticle> particles;
  final int gridDensity;
  final bool showGeodesics;
  final bool showParticles;
  final String visualization;
  final double time;

  _SpacetimePainter({
    required this.masses,
    required this.particles,
    required this.gridDensity,
    required this.showGeodesics,
    required this.showParticles,
    required this.visualization,
    required this.time,
  });

  double _calculateCurvature(Offset point, Size size) {
    double totalCurvature = 0;

    for (var mass in masses) {
      final massPos = Offset(mass.position.dx * size.width, mass.position.dy * size.height);
      final dx = point.dx - massPos.dx;
      final dy = point.dy - massPos.dy;
      final r = math.sqrt(dx * dx + dy * dy);

      if (r > 5) {
        // 슈바르츠실트 계량을 단순화한 곡률
        totalCurvature += mass.mass * 10 / r;
      }
    }

    return totalCurvature;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 우주 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050510),
    );

    // 별 배경
    _drawStars(canvas, size);

    // 시각화에 따라 그리기
    switch (visualization) {
      case 'grid':
        _drawCurvedGrid(canvas, size);
        break;
      case 'contour':
        _drawContourLines(canvas, size);
        break;
      case 'mesh':
        _draw3DMesh(canvas, size);
        break;
    }

    // 측지선 (빛의 경로)
    if (showGeodesics) {
      _drawGeodesics(canvas, size);
    }

    // 테스트 입자들
    if (showParticles) {
      for (var particle in particles) {
        final pos = Offset(particle.position.dx * size.width, particle.position.dy * size.height);
        canvas.drawCircle(pos, 2, Paint()..color = Colors.cyan.withValues(alpha: 0.8));
      }
    }

    // 질량 객체 (블랙홀/별)
    for (var mass in masses) {
      _drawMassObject(canvas, mass, size);
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42);
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final brightness = random.nextDouble() * 0.5 + 0.2;
      canvas.drawCircle(
        Offset(x, y),
        0.5 + random.nextDouble() * 0.5,
        Paint()..color = Colors.white.withValues(alpha: brightness),
      );
    }
  }

  void _drawCurvedGrid(Canvas canvas, Size size) {
    final stepX = size.width / gridDensity;
    final stepY = size.height / gridDensity;

    // 가로선
    for (int j = 0; j <= gridDensity; j++) {
      final path = Path();
      for (int i = 0; i <= gridDensity; i++) {
        final x = i * stepX;
        final baseY = j * stepY;

        final curvature = _calculateCurvature(Offset(x, baseY), size);
        final displacement = curvature * 0.5;

        final y = baseY + displacement;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.4)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke,
      );
    }

    // 세로선
    for (int i = 0; i <= gridDensity; i++) {
      final path = Path();
      for (int j = 0; j <= gridDensity; j++) {
        final baseX = i * stepX;
        final y = j * stepY;

        final curvature = _calculateCurvature(Offset(baseX, y), size);
        final displacement = curvature * 0.3;

        final x = baseX + displacement * math.sin(y / size.height * math.pi);

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.purple.withValues(alpha: 0.4)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawContourLines(Canvas canvas, Size size) {
    final resolution = 60;
    final cellWidth = size.width / resolution;
    final cellHeight = size.height / resolution;

    // 곡률 필드 시각화
    for (int i = 0; i < resolution; i++) {
      for (int j = 0; j < resolution; j++) {
        final point = Offset((i + 0.5) * cellWidth, (j + 0.5) * cellHeight);
        final curvature = _calculateCurvature(point, size);

        final normalizedCurvature = (curvature / 50).clamp(0.0, 1.0);
        final color = Color.lerp(
          const Color(0xFF050510),
          Colors.deepPurple,
          normalizedCurvature,
        )!;

        canvas.drawRect(
          Rect.fromLTWH(i * cellWidth, j * cellHeight, cellWidth, cellHeight),
          Paint()..color = color,
        );
      }
    }

    // 등고선
    for (double level = 5; level <= 50; level += 10) {
      _drawContourLevel(canvas, size, level);
    }
  }

  void _drawContourLevel(Canvas canvas, Size size, double level) {
    final resolution = 40;
    final stepX = size.width / resolution;
    final stepY = size.height / resolution;

    for (int i = 0; i < resolution; i++) {
      for (int j = 0; j < resolution; j++) {
        final x = (i + 0.5) * stepX;
        final y = (j + 0.5) * stepY;
        final curvature = _calculateCurvature(Offset(x, y), size);

        if ((curvature - level).abs() < 2) {
          canvas.drawCircle(
            Offset(x, y),
            1,
            Paint()..color = Colors.cyan.withValues(alpha: 0.3),
          );
        }
      }
    }
  }

  void _draw3DMesh(Canvas canvas, Size size) {
    final step = size.width / gridDensity;

    for (int i = 0; i < gridDensity; i++) {
      for (int j = 0; j < gridDensity; j++) {
        final x = i * step;
        final y = j * step;

        final curvature = _calculateCurvature(Offset(x + step / 2, y + step / 2), size);
        final depth = curvature * 0.5;

        // 3D 투영 효과
        final projected = Offset(
          x + depth * 0.2,
          y + depth * 0.3,
        );

        final alpha = (0.3 + curvature / 100).clamp(0.0, 0.8);

        canvas.drawRect(
          Rect.fromLTWH(projected.dx, projected.dy, step * 0.9, step * 0.9),
          Paint()
            ..color = Color.lerp(Colors.blue, Colors.purple, curvature / 50)!.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }
    }
  }

  void _drawGeodesics(Canvas canvas, Size size) {
    // 여러 방향에서 오는 빛의 경로 (측지선)
    for (int i = 0; i < 8; i++) {
      final startAngle = i * math.pi / 4;
      final startX = size.width / 2 + math.cos(startAngle) * size.width * 0.4;
      final startY = size.height / 2 + math.sin(startAngle) * size.height * 0.4;

      final path = Path();
      path.moveTo(startX, startY);

      double x = startX;
      double y = startY;
      double vx = -math.cos(startAngle) * 2;
      double vy = -math.sin(startAngle) * 2;

      for (int step = 0; step < 200; step++) {
        // 시공간 곡률에 의한 빛의 휨
        for (var mass in masses) {
          final massPos = Offset(mass.position.dx * size.width, mass.position.dy * size.height);
          final dx = massPos.dx - x;
          final dy = massPos.dy - y;
          final r = math.sqrt(dx * dx + dy * dy);

          if (r > 10) {
            final accel = mass.mass * 0.5 / (r * r);
            vx += accel * dx / r;
            vy += accel * dy / r;
          }
        }

        x += vx;
        y += vy;

        if (x < 0 || x > size.width || y < 0 || y > size.height) break;

        path.lineTo(x, y);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.yellow.withValues(alpha: 0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawMassObject(Canvas canvas, _MassObject mass, Size size) {
    final pos = Offset(mass.position.dx * size.width, mass.position.dy * size.height);
    final radius = 8 + mass.mass * 0.8;

    // 이벤트 호라이즌 (블랙홀 효과)
    for (int i = 5; i > 0; i--) {
      canvas.drawCircle(
        pos,
        radius + i * 8,
        Paint()
          ..color = mass.color.withValues(alpha: 0.05 * i)
          ..style = PaintingStyle.fill,
      );
    }

    // 강착 원반 효과
    final diskPath = Path();
    for (double angle = 0; angle < 2 * math.pi; angle += 0.1) {
      final r = radius + 20 + math.sin(angle * 3 + time * 2) * 5;
      final x = pos.dx + r * math.cos(angle);
      final y = pos.dy + r * math.sin(angle) * 0.3;

      if (angle == 0) {
        diskPath.moveTo(x, y);
      } else {
        diskPath.lineTo(x, y);
      }
    }
    diskPath.close();

    canvas.drawPath(
      diskPath,
      Paint()
        ..color = Colors.orange.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 중심 질량
    final gradient = RadialGradient(
      colors: [
        mass.color,
        mass.color.withValues(alpha: 0.5),
        Colors.black,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    canvas.drawCircle(
      pos,
      radius,
      Paint()..shader = gradient.createShader(Rect.fromCircle(center: pos, radius: radius)),
    );

    // 밝은 테두리
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = mass.color.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SpacetimePainter oldDelegate) => true;
}
