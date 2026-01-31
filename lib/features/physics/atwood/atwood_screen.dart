import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 애트우드 기계 시뮬레이션
class AtwoodScreen extends StatefulWidget {
  const AtwoodScreen({super.key});

  @override
  State<AtwoodScreen> createState() => _AtwoodScreenState();
}

class _AtwoodScreenState extends State<AtwoodScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _mass1 = 3.0; // 왼쪽 질량 (kg)
  double _mass2 = 2.0; // 오른쪽 질량 (kg)
  bool _isRunning = false;

  double _position = 0; // 상대 위치 (-1 to 1)
  double _velocity = 0;
  double _time = 0;

  static const double _g = 9.8;

  double get _acceleration => (_mass1 - _mass2) * _g / (_mass1 + _mass2);
  double get _tension => 2 * _mass1 * _mass2 * _g / (_mass1 + _mass2);

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
      _velocity += _acceleration * 0.016;
      _position += _velocity * 0.005;

      // 경계 체크
      if (_position.abs() >= 0.8) {
        _position = _position.sign * 0.8;
        _velocity = 0;
        _isRunning = false;
        _controller.stop();
      }
    });
  }

  void _start() {
    HapticFeedback.mediumImpact();
    if (_mass1 == _mass2) return;
    setState(() {
      _isRunning = true;
      _controller.repeat();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = false;
      _position = 0;
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
              'Atwood 기계',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: 'Atwood 기계',
          formula: 'a = (m₁-m₂)g / (m₁+m₂)',
          formulaDescription: '도르래에 연결된 두 질량의 가속도 운동',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _AtwoodPainter(
                mass1: _mass1,
                mass2: _mass2,
                position: _position,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 정보
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _mass1 > _mass2
                              ? 'm₁ 하강 중'
                              : _mass1 < _mass2
                                  ? 'm₂ 하강 중'
                                  : '평형 상태',
                          style: TextStyle(
                            color: _mass1 == _mass2 ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          't = ${_time.toStringAsFixed(2)} s',
                          style: const TextStyle(color: AppColors.muted, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '가속도 a', value: '${_acceleration.toStringAsFixed(2)} m/s²', color: AppColors.accent),
                        _InfoItem(label: '장력 T', value: '${_tension.toStringAsFixed(2)} N', color: Colors.orange),
                        _InfoItem(label: '속도 v', value: '${_velocity.abs().toStringAsFixed(2)} m/s', color: Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 프리셋
              PresetGroup(
                label: '시나리오',
                presets: [
                  PresetButton(
                    label: '평형',
                    isSelected: _mass1 == _mass2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _mass1 = 2.0;
                        _mass2 = 2.0;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '약간 차이',
                    isSelected: (_mass1 - _mass2).abs() < 1.5 && _mass1 != _mass2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _mass1 = 3.0;
                        _mass2 = 2.0;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '큰 차이',
                    isSelected: (_mass1 - _mass2).abs() >= 1.5,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _mass1 = 5.0;
                        _mass2 = 1.0;
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '질량 m₁ (kg)',
                  value: _mass1,
                  min: 0.5,
                  max: 10,
                  defaultValue: 3.0,
                  formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                  onChanged: (v) {
                    setState(() {
                      _mass1 = v;
                      _reset();
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '질량 m₂ (kg)',
                    value: _mass2,
                    min: 0.5,
                    max: 10,
                    defaultValue: 2.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                    onChanged: (v) {
                      setState(() {
                        _mass2 = v;
                        _reset();
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
                label: _isRunning ? '정지' : '시작',
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _isRunning ? _reset : _start,
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

class _AtwoodPainter extends CustomPainter {
  final double mass1;
  final double mass2;
  final double position;

  _AtwoodPainter({required this.mass1, required this.mass2, required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final pulleyY = 50.0;
    final pulleyRadius = 25.0;

    // 도르래
    canvas.drawCircle(
      Offset(centerX, pulleyY),
      pulleyRadius,
      Paint()
        ..color = AppColors.muted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // 도르래 중심
    canvas.drawCircle(
      Offset(centerX, pulleyY),
      5,
      Paint()..color = AppColors.accent,
    );

    // 줄
    final leftX = centerX - 60;
    final rightX = centerX + 60;
    final baseY = size.height / 2;
    final leftY = baseY - position * 80;
    final rightY = baseY + position * 80;

    // 왼쪽 줄
    canvas.drawLine(
      Offset(leftX, pulleyY + pulleyRadius),
      Offset(leftX, leftY),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2,
    );

    // 오른쪽 줄
    canvas.drawLine(
      Offset(rightX, pulleyY + pulleyRadius),
      Offset(rightX, rightY),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2,
    );

    // 도르래 위 줄
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, pulleyY), radius: pulleyRadius),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 왼쪽 추 (m1)
    final m1Size = 30 + mass1 * 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(leftX, leftY + m1Size / 2), width: 40, height: m1Size),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.red,
    );
    _drawText(canvas, 'm₁', Offset(leftX - 10, leftY + m1Size / 2 - 6), Colors.white, fontSize: 12);

    // 오른쪽 추 (m2)
    final m2Size = 30 + mass2 * 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(rightX, rightY + m2Size / 2), width: 40, height: m2Size),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.blue,
    );
    _drawText(canvas, 'm₂', Offset(rightX - 10, rightY + m2Size / 2 - 6), Colors.white, fontSize: 12);

    // 질량 라벨
    _drawText(canvas, '${mass1.toStringAsFixed(1)} kg', Offset(leftX - 25, leftY + m1Size + 10), Colors.red);
    _drawText(canvas, '${mass2.toStringAsFixed(1)} kg', Offset(rightX - 25, rightY + m2Size + 10), Colors.blue);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 11}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _AtwoodPainter oldDelegate) {
    return oldDelegate.position != position || oldDelegate.mass1 != mass1 || oldDelegate.mass2 != mass2;
  }
}
