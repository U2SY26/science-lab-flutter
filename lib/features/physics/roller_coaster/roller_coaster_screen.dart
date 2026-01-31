import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 롤러코스터 에너지 보존 시뮬레이션
class RollerCoasterScreen extends StatefulWidget {
  const RollerCoasterScreen({super.key});

  @override
  State<RollerCoasterScreen> createState() => _RollerCoasterScreenState();
}

class _RollerCoasterScreenState extends State<RollerCoasterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _initialHeight = 150; // 초기 높이
  double _friction = 0.0; // 마찰 계수
  bool _isRunning = false;

  double _position = 0; // 트랙 위치 (0~1)
  double _velocity = 0;
  double _time = 0;

  static const double _g = 9.8;

  // 트랙 형태 정의 (높이 함수)
  double _getTrackHeight(double x) {
    // 언덕이 있는 롤러코스터 트랙
    return 150 * math.pow(1 - x, 2) * math.cos(x * math.pi * 2) + 50 * math.sin(x * math.pi * 3) + 80;
  }

  double _getTrackSlope(double x) {
    const dx = 0.01;
    return (_getTrackHeight(x + dx) - _getTrackHeight(x - dx)) / (2 * dx);
  }

  double get _currentHeight => _getTrackHeight(_position);
  double get _potentialEnergy => _initialHeight - _currentHeight;
  double get _kineticEnergy => 0.5 * _velocity * _velocity;
  double get _totalEnergy => _potentialEnergy + _kineticEnergy;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update);
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      _time += 0.016;

      // 에너지 보존에 기반한 운동
      final slope = _getTrackSlope(_position);
      final acceleration = -_g * slope / (1 + slope * slope) - _friction * _velocity;

      _velocity += acceleration * 0.01;
      _position += _velocity * 0.002;

      // 경계 처리
      if (_position >= 0.95) {
        _position = 0.95;
        _velocity = -_velocity * 0.8;
      }
      if (_position <= 0.05) {
        _position = 0.05;
        _velocity = -_velocity * 0.8;
      }

      // 멈춤 조건
      if (_velocity.abs() < 0.1 && _friction > 0) {
        _velocity = 0;
      }
    });
  }

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = true;
      _controller.repeat();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = false;
      _position = 0.05;
      _velocity = 0;
      _time = 0;
      _controller.stop();
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
              '롤러코스터',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '롤러코스터 역학',
          formula: 'E = mgh + ½mv²',
          formulaDescription: '역학적 에너지 보존: 위치 에너지 ↔ 운동 에너지',
          simulation: SizedBox(
            height: 350,
            child: Column(
              children: [
                // 롤러코스터 시각화
                Expanded(
                  flex: 3,
                  child: CustomPaint(
                    painter: _RollerCoasterPainter(
                      position: _position,
                      getHeight: _getTrackHeight,
                    ),
                    size: Size.infinite,
                  ),
                ),
                // 에너지 바
                Expanded(
                  flex: 1,
                  child: _EnergyBar(
                    potential: (_initialHeight - _currentHeight).clamp(0, _initialHeight),
                    kinetic: _kineticEnergy.clamp(0, _initialHeight),
                    maxEnergy: _initialHeight,
                  ),
                ),
              ],
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 에너지 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '위치 에너지', value: '${_potentialEnergy.abs().toStringAsFixed(0)} J', color: Colors.orange),
                        _InfoItem(label: '운동 에너지', value: '${_kineticEnergy.toStringAsFixed(0)} J', color: Colors.green),
                        _InfoItem(label: '높이', value: '${_currentHeight.toStringAsFixed(0)} m', color: AppColors.accent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '속도', value: '${_velocity.abs().toStringAsFixed(1)} m/s', color: Colors.blue),
                        _InfoItem(label: '시간', value: '${_time.toStringAsFixed(1)} s', color: Colors.cyan),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 마찰 프리셋
              PresetGroup(
                label: '마찰',
                presets: [
                  PresetButton(
                    label: '없음',
                    isSelected: _friction == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _friction = 0;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '약간',
                    isSelected: _friction == 0.5,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _friction = 0.5;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '강함',
                    isSelected: _friction == 1.5,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _friction = 1.5;
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '초기 높이 (m)',
                  value: _initialHeight,
                  min: 80,
                  max: 200,
                  defaultValue: 150,
                  formatValue: (v) => '${v.toInt()} m',
                  onChanged: (v) {
                    setState(() {
                      _initialHeight = v;
                      _reset();
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '마찰 계수',
                    value: _friction,
                    min: 0,
                    max: 2,
                    defaultValue: 0,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) {
                      setState(() {
                        _friction = v;
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
                label: _isRunning ? '정지' : '출발!',
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _isRunning ? () => setState(() => _isRunning = false) : _start,
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

class _EnergyBar extends StatelessWidget {
  final double potential;
  final double kinetic;
  final double maxEnergy;

  const _EnergyBar({
    required this.potential,
    required this.kinetic,
    required this.maxEnergy,
  });

  @override
  Widget build(BuildContext context) {
    final potentialRatio = (potential / maxEnergy).clamp(0.0, 1.0);
    final kineticRatio = (kinetic / maxEnergy).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('에너지', style: TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 4),
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.simBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Flexible(
                  flex: (potentialRatio * 100).toInt().clamp(1, 100),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.horizontal(
                        left: const Radius.circular(12),
                        right: kineticRatio < 0.01 ? const Radius.circular(12) : Radius.zero,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: (kineticRatio * 100).toInt().clamp(1, 100),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.horizontal(
                        right: const Radius.circular(12),
                        left: potentialRatio < 0.01 ? const Radius.circular(12) : Radius.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, color: Colors.orange),
                  const SizedBox(width: 4),
                  const Text('위치 E', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                ],
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, color: Colors.green),
                  const SizedBox(width: 4),
                  const Text('운동 E', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RollerCoasterPainter extends CustomPainter {
  final double position;
  final double Function(double) getHeight;

  _RollerCoasterPainter({required this.position, required this.getHeight});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 20.0;
    final trackWidth = size.width - padding * 2;
    final trackHeight = size.height - padding * 2;
    final baseY = size.height - padding;

    // 트랙 그리기
    final trackPath = Path();
    for (double x = 0; x <= 1; x += 0.01) {
      final px = padding + x * trackWidth;
      final py = baseY - (getHeight(x) / 200) * trackHeight;

      if (x == 0) {
        trackPath.moveTo(px, py);
      } else {
        trackPath.lineTo(px, py);
      }
    }

    canvas.drawPath(
      trackPath,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke,
    );

    // 트랙 지지대
    for (double x = 0; x <= 1; x += 0.1) {
      final px = padding + x * trackWidth;
      final py = baseY - (getHeight(x) / 200) * trackHeight;
      canvas.drawLine(
        Offset(px, py),
        Offset(px, baseY),
        Paint()
          ..color = AppColors.muted.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );
    }

    // 카트 위치
    final cartX = padding + position * trackWidth;
    final cartY = baseY - (getHeight(position) / 200) * trackHeight;

    // 카트 그리기
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cartX, cartY - 10), width: 30, height: 20),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.red,
    );

    // 바퀴
    canvas.drawCircle(Offset(cartX - 8, cartY), 5, Paint()..color = AppColors.ink);
    canvas.drawCircle(Offset(cartX + 8, cartY), 5, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(covariant _RollerCoasterPainter oldDelegate) {
    return oldDelegate.position != position;
  }
}
