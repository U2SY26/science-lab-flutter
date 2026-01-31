import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 브라운 운동 시뮬레이션
class BrownianScreen extends StatefulWidget {
  const BrownianScreen({super.key});

  @override
  State<BrownianScreen> createState() => _BrownianScreenState();
}

class _BrownianScreenState extends State<BrownianScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _temperature = 300; // K
  int _particleCount = 100;
  bool _showTrail = true;
  bool _isRunning = true;

  final _random = math.Random();
  late _TrackedParticle _trackedParticle;
  late List<_SmallParticle> _smallParticles;

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
    _trackedParticle = _TrackedParticle(
      x: 0.5,
      y: 0.5,
      trail: [],
    );

    _smallParticles = List.generate(_particleCount, (i) {
      return _SmallParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        vx: (_random.nextDouble() - 0.5) * 0.02,
        vy: (_random.nextDouble() - 0.5) * 0.02,
      );
    });
  }

  void _update() {
    if (!_isRunning) return;

    final speedFactor = math.sqrt(_temperature / 300);

    setState(() {
      // 작은 입자들 업데이트
      for (var p in _smallParticles) {
        p.x += p.vx * speedFactor;
        p.y += p.vy * speedFactor;

        // 벽 충돌
        if (p.x < 0 || p.x > 1) {
          p.vx = -p.vx;
          p.x = p.x.clamp(0.0, 1.0);
        }
        if (p.y < 0 || p.y > 1) {
          p.vy = -p.vy;
          p.y = p.y.clamp(0.0, 1.0);
        }

        // 추적 입자와 충돌 체크
        final dx = p.x - _trackedParticle.x;
        final dy = p.y - _trackedParticle.y;
        final dist = math.sqrt(dx * dx + dy * dy);

        if (dist < 0.05) {
          // 충돌 - 추적 입자에 랜덤 충격
          _trackedParticle.vx += (_random.nextDouble() - 0.5) * 0.005 * speedFactor;
          _trackedParticle.vy += (_random.nextDouble() - 0.5) * 0.005 * speedFactor;
        }
      }

      // 추적 입자 업데이트
      _trackedParticle.x += _trackedParticle.vx;
      _trackedParticle.y += _trackedParticle.vy;

      // 감쇠
      _trackedParticle.vx *= 0.99;
      _trackedParticle.vy *= 0.99;

      // 벽 충돌
      if (_trackedParticle.x < 0.05 || _trackedParticle.x > 0.95) {
        _trackedParticle.vx = -_trackedParticle.vx;
        _trackedParticle.x = _trackedParticle.x.clamp(0.05, 0.95);
      }
      if (_trackedParticle.y < 0.05 || _trackedParticle.y > 0.95) {
        _trackedParticle.vy = -_trackedParticle.vy;
        _trackedParticle.y = _trackedParticle.y.clamp(0.05, 0.95);
      }

      // 궤적 기록
      if (_showTrail) {
        _trackedParticle.trail.add(Offset(_trackedParticle.x, _trackedParticle.y));
        if (_trackedParticle.trail.length > 500) {
          _trackedParticle.trail.removeAt(0);
        }
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
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
              '브라운 운동',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '브라운 운동',
          formula: '⟨x²⟩ = 2Dt',
          formulaDescription: '유체 분자의 무작위 충돌에 의한 입자의 불규칙 운동',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BrownianPainter(
                trackedParticle: _trackedParticle,
                smallParticles: _smallParticles,
                showTrail: _showTrail,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 정보 박스
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '브라운 운동이란?',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '1827년 로버트 브라운이 발견한 현상으로, 유체 속의 미세 입자가 분자들의 무작위 충돌로 불규칙하게 움직이는 현상입니다.',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.yellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '추적 입자 (꽃가루)',
                          style: TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '물 분자',
                          style: TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 옵션 토글
              Row(
                children: [
                  Expanded(
                    child: _OptionChip(
                      label: '궤적 표시',
                      isSelected: _showTrail,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showTrail = !_showTrail);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OptionChip(
                      label: _isRunning ? '실행 중' : '정지됨',
                      isSelected: _isRunning,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isRunning = !_isRunning);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '온도 (K)',
                  value: _temperature,
                  min: 100,
                  max: 500,
                  defaultValue: 300,
                  formatValue: (v) => '${v.toInt()} K',
                  onChanged: (v) => setState(() => _temperature = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '분자 수',
                    value: _particleCount.toDouble(),
                    min: 20,
                    max: 200,
                    defaultValue: 100,
                    formatValue: (v) => '${v.toInt()}개',
                    onChanged: (v) {
                      setState(() {
                        _particleCount = v.toInt();
                        _initParticles();
                      });
                    },
                  ),
                ],
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
                label: '궤적 지우기',
                icon: Icons.clear,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _trackedParticle.trail.clear());
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
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : AppColors.simBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.cardBorder,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.accent : AppColors.muted,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackedParticle {
  double x, y;
  double vx = 0, vy = 0;
  List<Offset> trail;

  _TrackedParticle({required this.x, required this.y, required this.trail});
}

class _SmallParticle {
  double x, y, vx, vy;
  _SmallParticle({required this.x, required this.y, required this.vx, required this.vy});
}

class _BrownianPainter extends CustomPainter {
  final _TrackedParticle trackedParticle;
  final List<_SmallParticle> smallParticles;
  final bool showTrail;

  _BrownianPainter({
    required this.trackedParticle,
    required this.smallParticles,
    required this.showTrail,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    // 컨테이너
    final padding = 20.0;
    final containerRect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    canvas.drawRect(
      containerRect,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRect(
      containerRect,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final innerWidth = containerRect.width;
    final innerHeight = containerRect.height;

    // 작은 입자들
    for (var p in smallParticles) {
      final px = padding + p.x * innerWidth;
      final py = padding + p.y * innerHeight;

      canvas.drawCircle(
        Offset(px, py),
        2,
        Paint()..color = Colors.blue.withValues(alpha: 0.4),
      );
    }

    // 궤적
    if (showTrail && trackedParticle.trail.length > 1) {
      final path = Path();
      final trail = trackedParticle.trail;

      path.moveTo(
        padding + trail[0].dx * innerWidth,
        padding + trail[0].dy * innerHeight,
      );

      for (int i = 1; i < trail.length; i++) {
        path.lineTo(
          padding + trail[i].dx * innerWidth,
          padding + trail[i].dy * innerHeight,
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.red.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // 추적 입자
    final trackedX = padding + trackedParticle.x * innerWidth;
    final trackedY = padding + trackedParticle.y * innerHeight;

    // 글로우
    canvas.drawCircle(
      Offset(trackedX, trackedY),
      15,
      Paint()..color = Colors.yellow.withValues(alpha: 0.3),
    );

    canvas.drawCircle(
      Offset(trackedX, trackedY),
      8,
      Paint()..color = Colors.yellow,
    );

    // 하이라이트
    canvas.drawCircle(
      Offset(trackedX - 2, trackedY - 2),
      2,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _BrownianPainter oldDelegate) => true;
}
