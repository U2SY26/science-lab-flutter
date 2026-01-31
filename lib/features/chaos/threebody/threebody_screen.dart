import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 3체 문제 시뮬레이션 화면
class ThreeBodyScreen extends StatefulWidget {
  const ThreeBodyScreen({super.key});

  @override
  State<ThreeBodyScreen> createState() => _ThreeBodyScreenState();
}

class _ThreeBodyScreenState extends State<ThreeBodyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 3개의 천체
  List<_Body> _bodies = [];

  // 궤적
  final List<List<Offset>> _trails = [[], [], []];
  static const int _maxTrailLength = 200;

  // 물리 상수
  double _G = 1.0; // 중력 상수
  double _dt = 0.02; // 시간 간격
  double _totalEnergy = 0;

  // 프리셋
  String _selectedPreset = 'figure8';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_update);
    _initPreset('figure8');
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initPreset(String preset) {
    _selectedPreset = preset;
    _trails[0].clear();
    _trails[1].clear();
    _trails[2].clear();

    switch (preset) {
      case 'figure8':
        // 유명한 8자 궤도 (Chenciner & Montgomery, 2000)
        _bodies = [
          _Body(
            x: -0.97000436,
            y: 0.24308753,
            vx: 0.4662036850,
            vy: 0.4323657300,
            mass: 1.0,
            color: AppColors.accent,
          ),
          _Body(
            x: 0.97000436,
            y: -0.24308753,
            vx: 0.4662036850,
            vy: 0.4323657300,
            mass: 1.0,
            color: AppColors.accent2,
          ),
          _Body(
            x: 0,
            y: 0,
            vx: -0.93240737,
            vy: -0.86473146,
            mass: 1.0,
            color: Colors.green,
          ),
        ];
        break;
      case 'triangle':
        // 정삼각형 회전
        const r = 1.0;
        const v = 0.5;
        for (int i = 0; i < 3; i++) {
          final angle = i * 2 * math.pi / 3;
          final vAngle = angle + math.pi / 2;
          _bodies.add(_Body(
            x: r * math.cos(angle),
            y: r * math.sin(angle),
            vx: v * math.cos(vAngle),
            vy: v * math.sin(vAngle),
            mass: 1.0,
            color: [AppColors.accent, AppColors.accent2, Colors.green][i],
          ));
        }
        break;
      case 'chaos':
        // 불안정한 초기 조건
        _bodies = [
          _Body(x: -1, y: 0, vx: 0, vy: 0.5, mass: 1.0, color: AppColors.accent),
          _Body(x: 1, y: 0, vx: 0, vy: -0.5, mass: 1.0, color: AppColors.accent2),
          _Body(x: 0, y: 1.5, vx: 0.3, vy: 0, mass: 1.0, color: Colors.green),
        ];
        break;
      case 'binary':
        // 이진성 + 행성
        _bodies = [
          _Body(x: -0.5, y: 0, vx: 0, vy: 0.8, mass: 1.0, color: AppColors.accent),
          _Body(x: 0.5, y: 0, vx: 0, vy: -0.8, mass: 1.0, color: AppColors.accent2),
          _Body(x: 2, y: 0, vx: 0, vy: 0.5, mass: 0.1, color: Colors.green),
        ];
        break;
    }

    _calculateEnergy();
  }

  void _calculateEnergy() {
    double ke = 0;
    double pe = 0;

    for (int i = 0; i < 3; i++) {
      ke += 0.5 * _bodies[i].mass * (_bodies[i].vx * _bodies[i].vx + _bodies[i].vy * _bodies[i].vy);
      for (int j = i + 1; j < 3; j++) {
        final dx = _bodies[j].x - _bodies[i].x;
        final dy = _bodies[j].y - _bodies[i].y;
        final r = math.sqrt(dx * dx + dy * dy);
        if (r > 0.01) {
          pe -= _G * _bodies[i].mass * _bodies[j].mass / r;
        }
      }
    }

    _totalEnergy = ke + pe;
  }

  void _update() {
    setState(() {
      // 속도 Verlet 적분법
      final ax = List.filled(3, 0.0);
      final ay = List.filled(3, 0.0);

      // 가속도 계산
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          if (i != j) {
            final dx = _bodies[j].x - _bodies[i].x;
            final dy = _bodies[j].y - _bodies[i].y;
            final r = math.sqrt(dx * dx + dy * dy);
            if (r > 0.05) {
              final a = _G * _bodies[j].mass / (r * r * r);
              ax[i] += a * dx;
              ay[i] += a * dy;
            }
          }
        }
      }

      // 위치와 속도 업데이트
      for (int i = 0; i < 3; i++) {
        _bodies[i].vx += ax[i] * _dt;
        _bodies[i].vy += ay[i] * _dt;
        _bodies[i].x += _bodies[i].vx * _dt;
        _bodies[i].y += _bodies[i].vy * _dt;

        // 궤적 저장
        _trails[i].add(Offset(_bodies[i].x, _bodies[i].y));
        if (_trails[i].length > _maxTrailLength) {
          _trails[i].removeAt(0);
        }
      }

      _calculateEnergy();
    });
  }

  void _togglePause() {
    HapticFeedback.mediumImpact();
    if (_controller.isAnimating) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
    setState(() {});
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _bodies.clear();
      _initPreset(_selectedPreset);
    });
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
              '혼돈 이론',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '3체 문제',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '혼돈 이론',
          title: '3체 문제',
          formula: 'F = G·m₁m₂/r²',
          formulaDescription: '3개 천체의 중력 상호작용 - 해석적 해가 없는 혼돈 시스템',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _ThreeBodyPainter(
                bodies: _bodies,
                trails: _trails,
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
                    label: '8자 궤도',
                    isSelected: _selectedPreset == 'figure8',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _initPreset('figure8'));
                    },
                  ),
                  PresetButton(
                    label: '삼각형',
                    isSelected: _selectedPreset == 'triangle',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _initPreset('triangle'));
                    },
                  ),
                  PresetButton(
                    label: '혼돈',
                    isSelected: _selectedPreset == 'chaos',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _initPreset('chaos'));
                    },
                  ),
                  PresetButton(
                    label: '이진성',
                    isSelected: _selectedPreset == 'binary',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _initPreset('binary'));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 상태 정보
              _EnergyInfo(totalEnergy: _totalEnergy),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: '중력 상수 G',
                  value: _G,
                  min: 0.5,
                  max: 2.0,
                  defaultValue: 1.0,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _G = v),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _controller.isAnimating ? '일시정지' : '재생',
                icon: _controller.isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _togglePause,
              ),
              SimButton(
                label: '초기화',
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

class _Body {
  double x, y;
  double vx, vy;
  double mass;
  Color color;

  _Body({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.mass,
    required this.color,
  });
}

class _EnergyInfo extends StatelessWidget {
  final double totalEnergy;

  const _EnergyInfo({required this.totalEnergy});

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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            '총 에너지: ${totalEnergy.toStringAsFixed(4)}',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeBodyPainter extends CustomPainter {
  final List<_Body> bodies;
  final List<List<Offset>> trails;

  _ThreeBodyPainter({required this.bodies, required this.trails});

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final center = Offset(size.width / 2, size.height / 2);
    const scale = 60.0;

    // 궤적 그리기
    for (int i = 0; i < 3 && i < trails.length; i++) {
      if (trails[i].length < 2) continue;

      final path = Path();
      final first = trails[i].first;
      path.moveTo(center.dx + first.dx * scale, center.dy + first.dy * scale);

      for (int j = 1; j < trails[i].length; j++) {
        final pt = trails[i][j];
        path.lineTo(center.dx + pt.dx * scale, center.dy + pt.dy * scale);
      }

      final paint = Paint()
        ..color = bodies[i].color.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, paint);
    }

    // 천체 그리기
    for (int i = 0; i < bodies.length; i++) {
      final body = bodies[i];
      final pos = Offset(center.dx + body.x * scale, center.dy + body.y * scale);

      // 글로우
      canvas.drawCircle(
        pos,
        15 + body.mass * 5,
        Paint()
          ..color = body.color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // 본체
      canvas.drawCircle(
        pos,
        8 + body.mass * 4,
        Paint()..color = body.color,
      );

      // 하이라이트
      canvas.drawCircle(
        Offset(pos.dx - 2, pos.dy - 2),
        3,
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThreeBodyPainter oldDelegate) => true;
}
