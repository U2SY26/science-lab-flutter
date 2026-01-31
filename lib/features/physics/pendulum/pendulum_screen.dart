import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 단진자 시뮬레이션 화면
class PendulumScreen extends StatefulWidget {
  const PendulumScreen({super.key});

  @override
  State<PendulumScreen> createState() => _PendulumScreenState();
}

class _PendulumScreenState extends State<PendulumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 물리 파라미터 (기본값)
  static const double _defaultLength = 150;
  static const double _defaultGravity = 9.8;
  static const double _defaultDamping = 0.995;
  static const double _defaultAngle = math.pi / 4;

  double length = _defaultLength;
  double gravity = _defaultGravity;
  double damping = _defaultDamping;
  bool isRunning = true;
  bool showTrail = true;

  // 물리 상태
  double angle = _defaultAngle;
  double angularVelocity = 0;
  List<Offset> trail = [];

  // 프리셋
  String? _selectedPreset;

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
      // 물리 계산 (PendulumSim.tsx에서 포팅)
      final angularAcceleration = (-gravity / length) * math.sin(angle);
      angularVelocity += angularAcceleration * 0.3;
      angularVelocity *= damping;
      angle += angularVelocity * 0.3;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      angle = _defaultAngle;
      angularVelocity = 0;
      trail.clear();
      _selectedPreset = null;
    });
  }

  void _kick() {
    HapticFeedback.lightImpact();
    setState(() {
      angularVelocity += 0.15;
    });
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'earth':
          gravity = 9.8;
          length = 150;
          damping = 0.995;
          break;
        case 'moon':
          gravity = 1.62;
          length = 150;
          damping = 0.999;
          break;
        case 'jupiter':
          gravity = 24.79;
          length = 150;
          damping = 0.99;
          break;
        case 'long':
          length = 220;
          gravity = 9.8;
          damping = 0.995;
          break;
        case 'short':
          length = 80;
          gravity = 9.8;
          damping = 0.995;
          break;
      }
      angle = _defaultAngle;
      angularVelocity = 0;
      trail.clear();
    });
  }

  // 주기 계산
  double get period => 2 * math.pi * math.sqrt(length / 100 / gravity);

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
              '물리 시뮬레이션',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '단진자 운동',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              showTrail ? Icons.timeline : Icons.timeline_outlined,
              color: showTrail ? AppColors.accent : AppColors.muted,
            ),
            onPressed: () => setState(() => showTrail = !showTrail),
            tooltip: '궤적 표시',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '단진자 운동',
          formula: 'T = 2π√(L/g)',
          formulaDescription: '주기 T는 줄 길이 L과 중력가속도 g에 의해 결정됩니다.',
          simulation: GestureDetector(
            onPanUpdate: (details) {
              if (!isRunning) return;
              // 드래그로 추에 힘 가하기
              final force = details.delta.dx * 0.001;
              setState(() {
                angularVelocity += force;
              });
            },
            child: SizedBox(
              height: 350,
              child: CustomPaint(
                painter: PendulumPainter(
                  angle: angle,
                  length: length,
                  angularVelocity: angularVelocity,
                  trail: trail,
                  showTrail: showTrail,
                  isRunning: isRunning,
                  period: period,
                  onTrailUpdate: (newTrail) {
                    trail = newTrail;
                  },
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프리셋 버튼
              PresetGroup(
                label: '환경 프리셋',
                presets: [
                  PresetButton(
                    label: '지구',
                    isSelected: _selectedPreset == 'earth',
                    onPressed: () => _applyPreset('earth'),
                  ),
                  PresetButton(
                    label: '달',
                    isSelected: _selectedPreset == 'moon',
                    onPressed: () => _applyPreset('moon'),
                  ),
                  PresetButton(
                    label: '목성',
                    isSelected: _selectedPreset == 'jupiter',
                    onPressed: () => _applyPreset('jupiter'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 컨트롤 그룹
              ControlGroup(
                primaryControl: SimSlider(
                  label: '줄 길이 (L)',
                  value: length,
                  min: 80,
                  max: 220,
                  defaultValue: _defaultLength,
                  formatValue: (v) => '${v.toInt()} px',
                  onChanged: (v) => setState(() {
                    length = v;
                    _selectedPreset = null;
                  }),
                ),
                advancedControls: [
                  SimSlider(
                    label: '중력 (g)',
                    value: gravity,
                    min: 1,
                    max: 30,
                    step: 0.1,
                    defaultValue: _defaultGravity,
                    formatValue: (v) => '${v.toStringAsFixed(1)} m/s²',
                    onChanged: (v) => setState(() {
                      gravity = v;
                      _selectedPreset = null;
                    }),
                  ),
                  SimSlider(
                    label: '감쇠 계수',
                    value: damping,
                    min: 0.95,
                    max: 1,
                    step: 0.001,
                    defaultValue: _defaultDamping,
                    formatValue: (v) => v >= 1 ? '없음' : '${((1 - v) * 100).toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      damping = v;
                      _selectedPreset = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 물리량 표시
              _PhysicsInfo(
                angle: angle,
                angularVelocity: angularVelocity,
                period: period,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning ? '정지' : '재생',
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => isRunning = !isRunning);
                },
              ),
              SimButton(
                label: '힘 주기',
                icon: Icons.touch_app,
                onPressed: _kick,
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
  final double angle;
  final double angularVelocity;
  final double period;

  const _PhysicsInfo({
    required this.angle,
    required this.angularVelocity,
    required this.period,
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
      child: Row(
        children: [
          _InfoItem(
            label: '각도',
            value: '${(angle * 180 / math.pi).toStringAsFixed(1)}°',
          ),
          _InfoItem(
            label: '각속도',
            value: '${angularVelocity.toStringAsFixed(3)} rad/s',
          ),
          _InfoItem(
            label: '주기',
            value: '${period.toStringAsFixed(2)} s',
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

/// 단진자 페인터
class PendulumPainter extends CustomPainter {
  final double angle;
  final double length;
  final double angularVelocity;
  final List<Offset> trail;
  final bool showTrail;
  final bool isRunning;
  final double period;
  final Function(List<Offset>) onTrailUpdate;

  PendulumPainter({
    required this.angle,
    required this.length,
    required this.angularVelocity,
    required this.trail,
    required this.showTrail,
    required this.isRunning,
    required this.period,
    required this.onTrailUpdate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pivotX = size.width / 2;
    final pivotY = 50.0;

    final bobX = pivotX + length * math.sin(angle);
    final bobY = pivotY + length * math.cos(angle);
    final bobOffset = Offset(bobX, bobY);

    // 궤적 업데이트
    if (showTrail && isRunning) {
      final newTrail = List<Offset>.from(trail);
      newTrail.add(bobOffset);
      if (newTrail.length > 200) newTrail.removeAt(0);
      onTrailUpdate(newTrail);
    }

    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    // 그리드
    _drawGrid(canvas, size);

    // 궤적 그리기
    if (showTrail && trail.length > 1) {
      final trailPath = Path()..moveTo(trail.first.dx, trail.first.dy);
      for (int i = 1; i < trail.length; i++) {
        trailPath.lineTo(trail[i].dx, trail[i].dy);
      }

      // 그라데이션 궤적
      for (int i = 1; i < trail.length; i++) {
        final progress = i / trail.length;
        canvas.drawLine(
          trail[i - 1],
          trail[i],
          Paint()
            ..color = AppColors.trailColor.withValues(alpha: progress * 0.8)
            ..strokeWidth = 2 + progress
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // 피벗 고정점
    _drawPivot(canvas, Offset(pivotX, pivotY));

    // 막대 그리기
    final rodPaint = Paint()
      ..color = AppColors.rod
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pivotX, pivotY), bobOffset, rodPaint);

    // 추 그리기 (향상된 그라데이션)
    _drawBob(canvas, bobOffset);

    // 속도 벡터 표시 (운동 중일 때)
    if (isRunning && angularVelocity.abs() > 0.001) {
      _drawVelocityVector(canvas, bobOffset);
    }
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

  void _drawPivot(Canvas canvas, Offset position) {
    // 외부 링
    canvas.drawCircle(
      position,
      10,
      Paint()
        ..color = AppColors.pivot.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // 내부 원
    canvas.drawCircle(
      position,
      6,
      Paint()..color = AppColors.pivot,
    );
    // 하이라이트
    canvas.drawCircle(
      position + const Offset(-2, -2),
      2,
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  void _drawBob(Canvas canvas, Offset position) {
    const bobRadius = 22.0;

    // 그림자
    canvas.drawCircle(
      position + const Offset(3, 3),
      bobRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // 메인 그라데이션
    final bobGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        AppColors.bobGradient[0],
        AppColors.bobGradient[1],
        AppColors.bobGradient[1].withValues(alpha: 0.8),
      ],
      stops: const [0.0, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: position, radius: bobRadius));

    canvas.drawCircle(
      position,
      bobRadius,
      Paint()..shader = bobGradient,
    );

    // 하이라이트
    canvas.drawCircle(
      position + const Offset(-6, -6),
      6,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // 테두리
    canvas.drawCircle(
      position,
      bobRadius,
      Paint()
        ..color = const Color(0xFF1D5460)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawVelocityVector(Canvas canvas, Offset bobPosition) {
    // 속도 방향 (접선 방향)
    final velocityDirection = Offset(
      math.cos(angle) * angularVelocity.sign,
      -math.sin(angle) * angularVelocity.sign,
    );
    final velocityMagnitude = angularVelocity.abs() * 100;
    final velocityEnd = bobPosition + velocityDirection * velocityMagnitude.clamp(0, 50);

    // 화살표
    final arrowPaint = Paint()
      ..color = AppColors.accent2.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(bobPosition, velocityEnd, arrowPaint);

    // 화살표 머리
    final arrowAngle = math.atan2(
      velocityEnd.dy - bobPosition.dy,
      velocityEnd.dx - bobPosition.dx,
    );
    const arrowHeadLength = 8.0;
    const arrowHeadAngle = 0.5;

    canvas.drawLine(
      velocityEnd,
      velocityEnd -
          Offset(
            arrowHeadLength * math.cos(arrowAngle - arrowHeadAngle),
            arrowHeadLength * math.sin(arrowAngle - arrowHeadAngle),
          ),
      arrowPaint,
    );
    canvas.drawLine(
      velocityEnd,
      velocityEnd -
          Offset(
            arrowHeadLength * math.cos(arrowAngle + arrowHeadAngle),
            arrowHeadLength * math.sin(arrowAngle + arrowHeadAngle),
          ),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant PendulumPainter oldDelegate) => true;
}
