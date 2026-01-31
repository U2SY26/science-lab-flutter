import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 마찰과 경사면 시뮬레이션
class FrictionScreen extends StatefulWidget {
  const FrictionScreen({super.key});

  @override
  State<FrictionScreen> createState() => _FrictionScreenState();
}

class _FrictionScreenState extends State<FrictionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _angle = 30; // 경사각 (도)
  double _mass = 2.0; // 질량 (kg)
  double _frictionCoeff = 0.3; // 마찰계수
  bool _isRunning = false;

  double _position = 0; // 물체 위치
  double _velocity = 0; // 속도
  double _time = 0;

  static const double _g = 9.8;

  double get _angleRad => _angle * math.pi / 180;
  double get _gravityComponent => _mass * _g * math.sin(_angleRad);
  double get _normalForce => _mass * _g * math.cos(_angleRad);
  double get _frictionForce => _frictionCoeff * _normalForce;
  double get _netForce => _gravityComponent - _frictionForce;
  double get _acceleration => _netForce / _mass;
  bool get _willSlide => _gravityComponent > _frictionForce;
  double get _criticalAngle => math.atan(_frictionCoeff) * 180 / math.pi;

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
      if (_willSlide && _position < 1.0) {
        _velocity += _acceleration * 0.016;
        _position += _velocity * 0.01;
        if (_position >= 1.0) {
          _position = 1.0;
          _isRunning = false;
          _controller.stop();
        }
      }
    });
  }

  void _start() {
    HapticFeedback.mediumImpact();
    if (!_willSlide) return;
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
              '마찰과 경사면',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '마찰과 경사면',
          formula: 'f = μN = μmg cosθ',
          formulaDescription: '경사면에서 마찰력과 중력의 상호작용',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _FrictionPainter(
                angle: _angle,
                position: _position,
                willSlide: _willSlide,
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
                          _willSlide ? '미끄러짐' : '정지 상태',
                          style: TextStyle(
                            color: _willSlide ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '임계각: ${_criticalAngle.toStringAsFixed(1)}°',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '중력 성분', value: '${_gravityComponent.toStringAsFixed(2)} N', color: Colors.orange),
                        _InfoItem(label: '마찰력', value: '${_frictionForce.toStringAsFixed(2)} N', color: Colors.blue),
                        _InfoItem(label: '가속도', value: '${_acceleration.toStringAsFixed(2)} m/s²', color: AppColors.accent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '속도', value: '${_velocity.toStringAsFixed(2)} m/s', color: Colors.green),
                        _InfoItem(label: '시간', value: '${_time.toStringAsFixed(2)} s', color: Colors.cyan),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '경사각 θ (°)',
                  value: _angle,
                  min: 0,
                  max: 60,
                  defaultValue: 30,
                  formatValue: (v) => '${v.toInt()}°',
                  onChanged: (v) {
                    setState(() {
                      _angle = v;
                      _reset();
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '마찰계수 μ',
                    value: _frictionCoeff,
                    min: 0,
                    max: 1.0,
                    defaultValue: 0.3,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) {
                      setState(() {
                        _frictionCoeff = v;
                        _reset();
                      });
                    },
                  ),
                  SimSlider(
                    label: '질량 m (kg)',
                    value: _mass,
                    min: 0.5,
                    max: 10,
                    defaultValue: 2.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                    onChanged: (v) {
                      setState(() {
                        _mass = v;
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

class _FrictionPainter extends CustomPainter {
  final double angle;
  final double position;
  final bool willSlide;

  _FrictionPainter({required this.angle, required this.position, required this.willSlide});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final rampLength = size.width * 0.7;
    final rampHeight = rampLength * math.tan(angle * math.pi / 180);

    // 경사면
    final rampStart = Offset(centerX - rampLength / 2, centerY + rampHeight / 2);
    final rampEnd = Offset(centerX + rampLength / 2, centerY - rampHeight / 2);

    canvas.drawLine(
      rampStart,
      rampEnd,
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 3,
    );

    // 바닥
    canvas.drawLine(
      Offset(rampStart.dx - 20, rampStart.dy),
      Offset(rampStart.dx + 50, rampStart.dy),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );

    // 물체 위치 계산
    final objectProgress = position;
    final objectX = rampStart.dx + (rampEnd.dx - rampStart.dx) * objectProgress;
    final objectY = rampStart.dy + (rampEnd.dy - rampStart.dy) * objectProgress;

    // 물체
    canvas.save();
    canvas.translate(objectX, objectY - 15);
    canvas.rotate(-angle * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 40, height: 30),
        const Radius.circular(4),
      ),
      Paint()..color = willSlide ? Colors.red : Colors.green,
    );
    canvas.restore();

    // 각도 표시
    final arcPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(
      Rect.fromCircle(center: rampStart, radius: 40),
      0,
      -angle * math.pi / 180,
      false,
      arcPaint,
    );

    _drawText(canvas, 'θ = ${angle.toInt()}°', Offset(rampStart.dx + 50, rampStart.dy - 10), AppColors.accent);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 12)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _FrictionPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.position != position;
  }
}
