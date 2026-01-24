import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 이중 진자 시뮬레이션 화면 - 혼돈 역학의 대표적 예시
class DoublePendulumScreen extends StatefulWidget {
  const DoublePendulumScreen({super.key});

  @override
  State<DoublePendulumScreen> createState() => _DoublePendulumScreenState();
}

class _DoublePendulumScreenState extends State<DoublePendulumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 기본값
  static const double _defaultL1 = 120;
  static const double _defaultL2 = 120;
  static const double _defaultM1 = 10;
  static const double _defaultM2 = 10;
  static const double _defaultG = 9.8;

  // 파라미터
  double l1 = _defaultL1;
  double l2 = _defaultL2;
  double m1 = _defaultM1;
  double m2 = _defaultM2;
  double g = _defaultG;
  bool isRunning = true;
  bool showTrail = true;
  bool showEnergy = true;

  // 상태
  double a1 = math.pi / 2;
  double a2 = math.pi / 2;
  double a1V = 0;
  double a2V = 0;
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
      // 이중 진자 라그랑지안 방정식
      final num1 = -g * (2 * m1 + m2) * math.sin(a1);
      final num2 = -m2 * g * math.sin(a1 - 2 * a2);
      final num3 = -2 * math.sin(a1 - a2) * m2;
      final num4 = a2V * a2V * l2 + a1V * a1V * l1 * math.cos(a1 - a2);
      final den = l1 * (2 * m1 + m2 - m2 * math.cos(2 * a1 - 2 * a2));
      final a1A = (num1 + num2 + num3 * num4) / den;

      final num5 = 2 * math.sin(a1 - a2);
      final num6 = a1V * a1V * l1 * (m1 + m2);
      final num7 = g * (m1 + m2) * math.cos(a1);
      final num8 = a2V * a2V * l2 * m2 * math.cos(a1 - a2);
      final den2 = l2 * (2 * m1 + m2 - m2 * math.cos(2 * a1 - 2 * a2));
      final a2A = (num5 * (num6 + num7 + num8)) / den2;

      a1V += a1A * 0.1;
      a2V += a2A * 0.1;
      a1 += a1V * 0.1;
      a2 += a2V * 0.1;

      // 감쇠
      a1V *= 0.9999;
      a2V *= 0.9999;
    });
  }

  // 에너지 계산
  double get kineticEnergy {
    final v1 = l1 * a1V;
    final v2x = l1 * a1V * math.cos(a1) + l2 * a2V * math.cos(a2);
    final v2y = l1 * a1V * math.sin(a1) + l2 * a2V * math.sin(a2);
    final v2 = math.sqrt(v2x * v2x + v2y * v2y);
    return 0.5 * m1 * v1 * v1 + 0.5 * m2 * v2 * v2;
  }

  double get potentialEnergy {
    final y1 = -l1 * math.cos(a1);
    final y2 = y1 - l2 * math.cos(a2);
    return m1 * g * y1 + m2 * g * y2;
  }

  double get totalEnergy => kineticEnergy + potentialEnergy;

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      a1 = math.pi / 2;
      a2 = math.pi / 2;
      a1V = 0;
      a2V = 0;
      trail.clear();
      _selectedPreset = null;
    });
  }

  void _randomize() {
    HapticFeedback.lightImpact();
    setState(() {
      a1 = math.Random().nextDouble() * math.pi * 2;
      a2 = math.Random().nextDouble() * math.pi * 2;
      a1V = 0;
      a2V = 0;
      trail.clear();
      _selectedPreset = null;
    });
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;
      trail.clear();
      a1V = 0;
      a2V = 0;

      switch (preset) {
        case 'symmetric':
          l1 = 120;
          l2 = 120;
          m1 = 10;
          m2 = 10;
          a1 = math.pi / 2;
          a2 = math.pi / 2;
          break;
        case 'heavy-top':
          l1 = 100;
          l2 = 140;
          m1 = 15;
          m2 = 5;
          a1 = math.pi * 0.8;
          a2 = math.pi * 0.6;
          break;
        case 'heavy-bottom':
          l1 = 100;
          l2 = 140;
          m1 = 5;
          m2 = 15;
          a1 = math.pi * 0.6;
          a2 = math.pi * 0.8;
          break;
        case 'chaos':
          l1 = 120;
          l2 = 120;
          m1 = 10;
          m2 = 10;
          a1 = math.pi - 0.01; // 거의 수직 - 불안정
          a2 = math.pi - 0.01;
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
              '혼돈 역학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '이중 진자',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
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
          IconButton(
            icon: Icon(
              showEnergy ? Icons.bolt : Icons.bolt_outlined,
              color: showEnergy ? AppColors.accent2 : AppColors.muted,
            ),
            onPressed: () => setState(() => showEnergy = !showEnergy),
            tooltip: '에너지 표시',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '혼돈 역학',
          title: '이중 진자',
          formula: 'd²θ/dt² = f(θ₁, θ₂, ω₁, ω₂)',
          formulaDescription: '초기 조건에 민감한 카오스 시스템의 대표적 예시',
          simulation: SizedBox(
            height: 380,
            child: CustomPaint(
              painter: DoublePendulumPainter(
                a1: a1,
                a2: a2,
                l1: l1,
                l2: l2,
                m1: m1,
                m2: m2,
                trail: trail,
                showTrail: showTrail,
                showEnergy: showEnergy,
                kineticEnergy: kineticEnergy,
                potentialEnergy: potentialEnergy,
                isRunning: isRunning,
                onTrailUpdate: (newTrail) => trail = newTrail,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프리셋
              PresetGroup(
                label: '초기 조건',
                presets: [
                  PresetButton(
                    label: '대칭',
                    isSelected: _selectedPreset == 'symmetric',
                    onPressed: () => _applyPreset('symmetric'),
                  ),
                  PresetButton(
                    label: '위 무거움',
                    isSelected: _selectedPreset == 'heavy-top',
                    onPressed: () => _applyPreset('heavy-top'),
                  ),
                  PresetButton(
                    label: '아래 무거움',
                    isSelected: _selectedPreset == 'heavy-bottom',
                    onPressed: () => _applyPreset('heavy-bottom'),
                  ),
                  PresetButton(
                    label: '카오스',
                    isSelected: _selectedPreset == 'chaos',
                    onPressed: () => _applyPreset('chaos'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: ControlGrid(
                  columns: 2,
                  controls: [
                    SimSlider(
                      label: '길이 1 (L₁)',
                      value: l1,
                      min: 50,
                      max: 150,
                      defaultValue: _defaultL1,
                      formatValue: (v) => '${v.toInt()} px',
                      onChanged: (v) => setState(() {
                        l1 = v;
                        _selectedPreset = null;
                      }),
                    ),
                    SimSlider(
                      label: '길이 2 (L₂)',
                      value: l2,
                      min: 50,
                      max: 150,
                      defaultValue: _defaultL2,
                      formatValue: (v) => '${v.toInt()} px',
                      onChanged: (v) => setState(() {
                        l2 = v;
                        _selectedPreset = null;
                      }),
                    ),
                  ],
                ),
                advancedControls: [
                  ControlGrid(
                    columns: 2,
                    controls: [
                      SimSlider(
                        label: '질량 1 (m₁)',
                        value: m1,
                        min: 1,
                        max: 20,
                        defaultValue: _defaultM1,
                        formatValue: (v) => '${v.toInt()} kg',
                        onChanged: (v) => setState(() {
                          m1 = v;
                          _selectedPreset = null;
                        }),
                      ),
                      SimSlider(
                        label: '질량 2 (m₂)',
                        value: m2,
                        min: 1,
                        max: 20,
                        defaultValue: _defaultM2,
                        formatValue: (v) => '${v.toInt()} kg',
                        onChanged: (v) => setState(() {
                          m2 = v;
                          _selectedPreset = null;
                        }),
                      ),
                    ],
                  ),
                  SimSlider(
                    label: '중력 (g)',
                    value: g,
                    min: 1,
                    max: 25,
                    defaultValue: _defaultG,
                    formatValue: (v) => '${v.toStringAsFixed(1)} m/s²',
                    onChanged: (v) => setState(() {
                      g = v;
                      _selectedPreset = null;
                    }),
                  ),
                ],
              ),
              if (showEnergy) ...[
                const SizedBox(height: 12),
                _EnergyDisplay(
                  kinetic: kineticEnergy,
                  potential: potentialEnergy,
                  total: totalEnergy,
                ),
              ],
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
                label: '랜덤',
                icon: Icons.shuffle,
                onPressed: _randomize,
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

/// 에너지 표시 위젯
class _EnergyDisplay extends StatelessWidget {
  final double kinetic;
  final double potential;
  final double total;

  const _EnergyDisplay({
    required this.kinetic,
    required this.potential,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final maxEnergy = total.abs() * 1.5;
    final kineticRatio = (kinetic.abs() / maxEnergy).clamp(0.0, 1.0);
    final potentialRatio = (potential.abs() / maxEnergy).clamp(0.0, 1.0);

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
          const Text(
            '에너지',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _EnergyBar(
            label: '운동 에너지',
            value: kinetic,
            ratio: kineticRatio,
            color: AppColors.accent,
          ),
          const SizedBox(height: 6),
          _EnergyBar(
            label: '위치 에너지',
            value: potential,
            ratio: potentialRatio,
            color: AppColors.accent2,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '총 에너지',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              Text(
                total.toStringAsFixed(0),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnergyBar extends StatelessWidget {
  final String label;
  final double value;
  final double ratio;
  final Color color;

  const _EnergyBar({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            value.toStringAsFixed(0),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

class DoublePendulumPainter extends CustomPainter {
  final double a1, a2, l1, l2, m1, m2;
  final List<Offset> trail;
  final bool showTrail, showEnergy, isRunning;
  final double kineticEnergy, potentialEnergy;
  final Function(List<Offset>) onTrailUpdate;

  DoublePendulumPainter({
    required this.a1,
    required this.a2,
    required this.l1,
    required this.l2,
    required this.m1,
    required this.m2,
    required this.trail,
    required this.showTrail,
    required this.showEnergy,
    required this.kineticEnergy,
    required this.potentialEnergy,
    required this.isRunning,
    required this.onTrailUpdate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pivotX = size.width / 2;
    final pivotY = size.height * 0.25;

    final x1 = pivotX + l1 * math.sin(a1);
    final y1 = pivotY + l1 * math.cos(a1);
    final x2 = x1 + l2 * math.sin(a2);
    final y2 = y1 + l2 * math.cos(a2);

    // 궤적 저장
    if (showTrail && isRunning) {
      final newTrail = List<Offset>.from(trail);
      newTrail.add(Offset(x2, y2));
      if (newTrail.length > 500) newTrail.removeAt(0);
      onTrailUpdate(newTrail);
    }

    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    // 그리드
    _drawGrid(canvas, size);

    // 궤적 (그라데이션)
    if (showTrail && trail.length > 1) {
      for (int i = 1; i < trail.length; i++) {
        final t = i / trail.length;
        canvas.drawLine(
          trail[i - 1],
          trail[i],
          Paint()
            ..color = Color.lerp(AppColors.accent, AppColors.accent2, t)!
                .withValues(alpha: t * 0.8)
            ..strokeWidth = 1 + t * 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // 피벗 고정점
    _drawPivot(canvas, Offset(pivotX, pivotY));

    // 막대 1
    canvas.drawLine(
      Offset(pivotX, pivotY),
      Offset(x1, y1),
      Paint()
        ..color = AppColors.rod
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // 막대 2
    canvas.drawLine(
      Offset(x1, y1),
      Offset(x2, y2),
      Paint()
        ..color = AppColors.rod.withValues(alpha: 0.8)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // 추 1
    _drawBob(canvas, Offset(x1, y1), m1 + 8, AppColors.accent);

    // 추 2
    _drawBob(canvas, Offset(x2, y2), m2 + 8, AppColors.accent2);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawPivot(Canvas canvas, Offset position) {
    canvas.drawCircle(
      position,
      8,
      Paint()..color = AppColors.pivot,
    );
    canvas.drawCircle(
      position + const Offset(-2, -2),
      2,
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  void _drawBob(Canvas canvas, Offset position, double radius, Color color) {
    // 그림자
    canvas.drawCircle(
      position + const Offset(2, 2),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // 그라데이션
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        color,
        color.withValues(alpha: 0.7),
      ],
    ).createShader(Rect.fromCircle(center: position, radius: radius));

    canvas.drawCircle(
      position,
      radius,
      Paint()..shader = gradient,
    );

    // 하이라이트
    canvas.drawCircle(
      position + Offset(-radius * 0.25, -radius * 0.25),
      radius * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // 테두리
    canvas.drawCircle(
      position,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant DoublePendulumPainter oldDelegate) => true;
}
