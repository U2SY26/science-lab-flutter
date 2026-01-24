import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 입자 데이터 클래스
class Particle {
  double x, y;
  double vx, vy;
  double mass;
  double radius;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.mass,
    required this.radius,
    required this.color,
  });
}

/// 입자 충돌 시뮬레이션 화면
class CollisionScreen extends StatefulWidget {
  const CollisionScreen({super.key});

  @override
  State<CollisionScreen> createState() => _CollisionScreenState();
}

class _CollisionScreenState extends State<CollisionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 입자들
  List<Particle> _particles = [];
  bool _isRunning = true;
  bool _elasticCollision = true;
  double _restitution = 1.0; // 반발 계수

  // 프리셋
  String? _selectedPreset;

  // 통계
  double get _totalKE {
    double ke = 0;
    for (final p in _particles) {
      ke += 0.5 * p.mass * (p.vx * p.vx + p.vy * p.vy);
    }
    return ke;
  }

  double get _totalMomentumX {
    double px = 0;
    for (final p in _particles) {
      px += p.mass * p.vx;
    }
    return px;
  }

  double get _totalMomentumY {
    double py = 0;
    for (final p in _particles) {
      py += p.mass * p.vy;
    }
    return py;
  }

  @override
  void initState() {
    super.initState();
    _initParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_update);
    _controller.repeat();
  }

  void _initParticles() {
    _particles = [
      Particle(
        x: 100,
        y: 150,
        vx: 3,
        vy: 0,
        mass: 1,
        radius: 20,
        color: AppColors.accent,
      ),
      Particle(
        x: 250,
        y: 150,
        vx: -2,
        vy: 0,
        mass: 1,
        radius: 20,
        color: AppColors.accent2,
      ),
    ];
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      const dt = 1.0;

      // 위치 업데이트
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
      }

      // 벽 충돌
      for (final p in _particles) {
        if (p.x - p.radius < 0) {
          p.x = p.radius;
          p.vx = -p.vx * _restitution;
        }
        if (p.x + p.radius > 350) {
          p.x = 350 - p.radius;
          p.vx = -p.vx * _restitution;
        }
        if (p.y - p.radius < 0) {
          p.y = p.radius;
          p.vy = -p.vy * _restitution;
        }
        if (p.y + p.radius > 280) {
          p.y = 280 - p.radius;
          p.vy = -p.vy * _restitution;
        }
      }

      // 입자 간 충돌
      for (int i = 0; i < _particles.length; i++) {
        for (int j = i + 1; j < _particles.length; j++) {
          _checkCollision(_particles[i], _particles[j]);
        }
      }
    });
  }

  void _checkCollision(Particle a, Particle b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final dist = math.sqrt(dx * dx + dy * dy);
    final minDist = a.radius + b.radius;

    if (dist < minDist && dist > 0) {
      HapticFeedback.lightImpact();

      // 충돌 법선
      final nx = dx / dist;
      final ny = dy / dist;

      // 상대 속도
      final dvx = a.vx - b.vx;
      final dvy = a.vy - b.vy;
      final dvn = dvx * nx + dvy * ny;

      // 이미 멀어지고 있으면 무시
      if (dvn > 0) return;

      // 충격량 계산
      final impulse = _elasticCollision
          ? (2 * dvn) / (1 / a.mass + 1 / b.mass)
          : ((1 + _restitution) * dvn) / (1 / a.mass + 1 / b.mass);

      // 속도 업데이트
      a.vx -= impulse * nx / a.mass;
      a.vy -= impulse * ny / a.mass;
      b.vx += impulse * nx / b.mass;
      b.vy += impulse * ny / b.mass;

      // 겹침 해결
      final overlap = minDist - dist;
      final totalMass = a.mass + b.mass;
      a.x -= overlap * nx * (b.mass / totalMass);
      a.y -= overlap * ny * (b.mass / totalMass);
      b.x += overlap * nx * (a.mass / totalMass);
      b.y += overlap * ny * (a.mass / totalMass);
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _initParticles();
      _selectedPreset = null;
    });
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'headon':
          _particles = [
            Particle(x: 80, y: 140, vx: 4, vy: 0, mass: 1, radius: 20, color: AppColors.accent),
            Particle(x: 270, y: 140, vx: -4, vy: 0, mass: 1, radius: 20, color: AppColors.accent2),
          ];
          break;
        case 'heavy':
          _particles = [
            Particle(x: 80, y: 140, vx: 3, vy: 0, mass: 3, radius: 30, color: AppColors.accent),
            Particle(x: 260, y: 140, vx: -1, vy: 0, mass: 1, radius: 15, color: AppColors.accent2),
          ];
          break;
        case 'pool':
          _particles = [
            Particle(x: 60, y: 140, vx: 5, vy: 0, mass: 1, radius: 15, color: Colors.white),
            Particle(x: 180, y: 140, vx: 0, vy: 0, mass: 1, radius: 15, color: Colors.red),
            Particle(x: 210, y: 125, vx: 0, vy: 0, mass: 1, radius: 15, color: Colors.blue),
            Particle(x: 210, y: 155, vx: 0, vy: 0, mass: 1, radius: 15, color: Colors.green),
          ];
          break;
        case 'random':
          final rand = math.Random();
          _particles = List.generate(6, (i) {
            return Particle(
              x: 50 + rand.nextDouble() * 250,
              y: 50 + rand.nextDouble() * 180,
              vx: (rand.nextDouble() - 0.5) * 6,
              vy: (rand.nextDouble() - 0.5) * 6,
              mass: 0.5 + rand.nextDouble() * 1.5,
              radius: 10 + rand.nextDouble() * 15,
              color: Color.fromRGBO(
                100 + rand.nextInt(155),
                100 + rand.nextInt(155),
                100 + rand.nextInt(155),
                1,
              ),
            );
          });
          break;
      }
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
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '역학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '입자 충돌',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '역학',
          title: '입자 충돌',
          formula: 'm₁v₁ + m₂v₂ = m₁v₁\' + m₂v₂\'',
          formulaDescription: '운동량 보존과 탄성 충돌',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: CollisionPainter(particles: _particles),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프리셋
              PresetGroup(
                label: '시나리오',
                presets: [
                  PresetButton(
                    label: '정면충돌',
                    isSelected: _selectedPreset == 'headon',
                    onPressed: () => _applyPreset('headon'),
                  ),
                  PresetButton(
                    label: '질량차이',
                    isSelected: _selectedPreset == 'heavy',
                    onPressed: () => _applyPreset('heavy'),
                  ),
                  PresetButton(
                    label: '당구',
                    isSelected: _selectedPreset == 'pool',
                    onPressed: () => _applyPreset('pool'),
                  ),
                  PresetButton(
                    label: '랜덤',
                    isSelected: _selectedPreset == 'random',
                    onPressed: () => _applyPreset('random'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 물리량 정보
              _PhysicsInfo(
                totalKE: _totalKE,
                momentumX: _totalMomentumX,
                momentumY: _totalMomentumY,
                particleCount: _particles.length,
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '반발 계수 (e)',
                  value: _restitution,
                  min: 0,
                  max: 1,
                  defaultValue: 1,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() {
                    _restitution = v;
                    _elasticCollision = v == 1.0;
                  }),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning ? '정지' : '재생',
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isRunning = !_isRunning);
                },
              ),
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

/// 물리량 정보 위젯
class _PhysicsInfo extends StatelessWidget {
  final double totalKE;
  final double momentumX;
  final double momentumY;
  final int particleCount;

  const _PhysicsInfo({
    required this.totalKE,
    required this.momentumX,
    required this.momentumY,
    required this.particleCount,
  });

  @override
  Widget build(BuildContext context) {
    final totalMomentum = math.sqrt(momentumX * momentumX + momentumY * momentumY);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoChip(
              label: '입자 수',
              value: particleCount.toString(),
              icon: Icons.scatter_plot,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _InfoChip(
              label: '운동에너지',
              value: totalKE.toStringAsFixed(1),
              icon: Icons.bolt,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _InfoChip(
              label: '총 운동량',
              value: totalMomentum.toStringAsFixed(2),
              icon: Icons.trending_flat,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.muted;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: chipColor.withValues(alpha: 0.7),
              fontSize: 9,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// 충돌 시뮬레이션 페인터
class CollisionPainter extends CustomPainter {
  final List<Particle> particles;

  CollisionPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // 테두리
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 350, 280),
      Paint()
        ..color = AppColors.cardBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 입자 그리기
    for (final p in particles) {
      // 글로우
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.radius + 5,
        Paint()
          ..color = p.color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // 메인
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.radius,
        Paint()..color = p.color,
      );

      // 테두리
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // 속도 벡터
      final vScale = 5.0;
      canvas.drawLine(
        Offset(p.x, p.y),
        Offset(p.x + p.vx * vScale, p.y + p.vy * vScale),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CollisionPainter oldDelegate) => true;
}
