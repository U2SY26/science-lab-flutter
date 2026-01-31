import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 상전이 시뮬레이션
class PhaseTransitionScreen extends StatefulWidget {
  const PhaseTransitionScreen({super.key});

  @override
  State<PhaseTransitionScreen> createState() => _PhaseTransitionScreenState();
}

class _PhaseTransitionScreenState extends State<PhaseTransitionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _temperature = 25; // 온도 (°C)
  String _substance = '물';
  bool _isRunning = true;

  final _random = math.Random();
  late List<_Particle> _particles;

  // 물질별 상전이 온도
  final Map<String, Map<String, double>> _transitionTemps = {
    '물': {'meltingPoint': 0, 'boilingPoint': 100},
    '에탄올': {'meltingPoint': -114, 'boilingPoint': 78},
    '철': {'meltingPoint': 1538, 'boilingPoint': 2862},
    '질소': {'meltingPoint': -210, 'boilingPoint': -196},
  };

  String get _currentPhase {
    final temps = _transitionTemps[_substance]!;
    if (_temperature < temps['meltingPoint']!) return '고체';
    if (_temperature < temps['boilingPoint']!) return '액체';
    return '기체';
  }

  Color get _phaseColor {
    switch (_currentPhase) {
      case '고체':
        return Colors.blue.shade300;
      case '액체':
        return Colors.blue;
      case '기체':
        return Colors.blue.shade100;
      default:
        return Colors.blue;
    }
  }

  @override
  void initState() {
    super.initState();
    _initParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update);
    _controller.repeat();
  }

  void _initParticles() {
    _particles = List.generate(50, (i) {
      return _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        vx: (_random.nextDouble() - 0.5) * 0.02,
        vy: (_random.nextDouble() - 0.5) * 0.02,
      );
    });
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      final temps = _transitionTemps[_substance]!;
      final phase = _currentPhase;

      // 온도에 따른 입자 움직임
      double speedFactor;
      double vibration;

      switch (phase) {
        case '고체':
          speedFactor = 0.1;
          vibration = 0.005;
          break;
        case '액체':
          speedFactor = 0.5;
          vibration = 0.01;
          break;
        case '기체':
          speedFactor = 2.0;
          vibration = 0.03;
          break;
        default:
          speedFactor = 1.0;
          vibration = 0.01;
      }

      // 온도가 높을수록 더 빠르게
      final tempNormalized = (_temperature - temps['meltingPoint']!) /
          (temps['boilingPoint']! - temps['meltingPoint']! + 1);
      speedFactor *= (1 + tempNormalized.clamp(0, 2));

      for (var p in _particles) {
        if (phase == '고체') {
          // 고체: 격자 위치 주변에서 진동
          p.vx = (p.baseX - p.x) * 0.1 + (_random.nextDouble() - 0.5) * vibration;
          p.vy = (p.baseY - p.y) * 0.1 + (_random.nextDouble() - 0.5) * vibration;
        } else {
          // 액체/기체: 자유 이동
          p.vx += (_random.nextDouble() - 0.5) * vibration * speedFactor;
          p.vy += (_random.nextDouble() - 0.5) * vibration * speedFactor;

          // 속도 제한
          final maxSpeed = 0.02 * speedFactor;
          p.vx = p.vx.clamp(-maxSpeed, maxSpeed);
          p.vy = p.vy.clamp(-maxSpeed, maxSpeed);
        }

        p.x += p.vx;
        p.y += p.vy;

        // 경계 반사
        if (p.x < 0 || p.x > 1) {
          p.vx = -p.vx;
          p.x = p.x.clamp(0.0, 1.0);
        }

        // 액체는 아래에 모임
        if (phase == '액체' && p.y > 0.7) {
          p.vy = -p.vy.abs() * 0.5;
        }

        if (p.y < 0 || p.y > 1) {
          p.vy = -p.vy;
          p.y = p.y.clamp(0.0, 1.0);
        }
      }

      // 고체: 격자 배열로 재배치
      if (phase == '고체') {
        _arrangeAsGrid();
      }
    });
  }

  void _arrangeAsGrid() {
    final cols = 10;
    final rows = 5;
    for (int i = 0; i < _particles.length && i < cols * rows; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      _particles[i].baseX = 0.1 + col * 0.08;
      _particles[i].baseY = 0.6 + row * 0.08;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temps = _transitionTemps[_substance]!;

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
              '상전이',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '상전이 (Phase Transition)',
          formula: 'Q = mL',
          formulaDescription: '온도에 따라 물질의 상태가 변하는 현상',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _PhaseTransitionPainter(
                particles: _particles,
                phase: _currentPhase,
                phaseColor: _phaseColor,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 표시
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _phaseColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _phaseColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(_currentPhase,
                            style: TextStyle(
                              color: _phaseColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            )),
                        Text(_substance, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${_temperature.toInt()}°C',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('현재 온도', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 상전이 온도 표시
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoItem(label: '녹는점', value: '${temps['meltingPoint']!.toInt()}°C', color: Colors.cyan),
                    _InfoItem(label: '끓는점', value: '${temps['boilingPoint']!.toInt()}°C', color: Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 물질 선택
              PresetGroup(
                label: '물질',
                presets: _transitionTemps.keys.map((s) {
                  return PresetButton(
                    label: s,
                    isSelected: _substance == s,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _substance = s;
                        // 해당 물질의 중간 온도로 설정
                        final t = _transitionTemps[s]!;
                        _temperature = (t['meltingPoint']! + t['boilingPoint']!) / 2;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '온도 (°C)',
                  value: _temperature,
                  min: temps['meltingPoint']! - 50,
                  max: temps['boilingPoint']! + 50,
                  defaultValue: 25,
                  formatValue: (v) => '${v.toInt()}°C',
                  onChanged: (v) => setState(() => _temperature = v),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Particle {
  double x, y;
  double vx, vy;
  double baseX, baseY;

  _Particle({required this.x, required this.y, required this.vx, required this.vy})
      : baseX = x,
        baseY = y;
}

class _PhaseTransitionPainter extends CustomPainter {
  final List<_Particle> particles;
  final String phase;
  final Color phaseColor;

  _PhaseTransitionPainter({
    required this.particles,
    required this.phase,
    required this.phaseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // 컨테이너
    final containerRect = Rect.fromLTWH(20, 20, size.width - 40, size.height - 40);
    canvas.drawRRect(
      RRect.fromRectAndRadius(containerRect, const Radius.circular(8)),
      Paint()
        ..color = AppColors.card
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(containerRect, const Radius.circular(8)),
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 입자 그리기
    final particleRadius = phase == '기체' ? 4.0 : 6.0;

    for (var p in particles) {
      final px = containerRect.left + p.x * containerRect.width;
      final py = containerRect.top + p.y * containerRect.height;

      canvas.drawCircle(
        Offset(px, py),
        particleRadius,
        Paint()..color = phaseColor,
      );

      // 하이라이트
      canvas.drawCircle(
        Offset(px - 1, py - 1),
        particleRadius * 0.3,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }

    // 상 라벨
    _drawText(canvas, phase, Offset(size.width / 2 - 20, containerRect.bottom + 5), phaseColor);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _PhaseTransitionPainter oldDelegate) => true;
}
