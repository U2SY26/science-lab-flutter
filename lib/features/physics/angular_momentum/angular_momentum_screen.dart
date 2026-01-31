import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 각운동량 보존 시뮬레이션 (피겨 스케이터)
class AngularMomentumScreen extends StatefulWidget {
  const AngularMomentumScreen({super.key});

  @override
  State<AngularMomentumScreen> createState() => _AngularMomentumScreenState();
}

class _AngularMomentumScreenState extends State<AngularMomentumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _armExtension = 1.0; // 팔 벌림 정도 (0.3 ~ 1.0)
  bool _isRunning = true;

  double _angle = 0;
  double _initialAngularMomentum = 100; // L = Iω (상수)

  // 관성 모멘트는 팔 벌림에 비례
  double get _momentOfInertia => 0.5 + _armExtension * 2;
  // 각운동량 보존: L = Iω → ω = L/I
  double get _angularVelocity => _initialAngularMomentum / _momentOfInertia;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      _angle += _angularVelocity * 0.002;
      if (_angle > 2 * math.pi) _angle -= 2 * math.pi;
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
              '각운동량 보존',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '각운동량 보존',
          formula: 'L = Iω = const',
          formulaDescription: '피겨 스케이터가 팔을 오므리면 빠르게 회전',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SkaterPainter(
                angle: _angle,
                armExtension: _armExtension,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 물리량 표시
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '각운동량 L = ',
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                        Text(
                          '${_initialAngularMomentum.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          ' (보존됨)',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(
                          label: '관성 모멘트 I',
                          value: _momentOfInertia.toStringAsFixed(2),
                          color: Colors.orange,
                        ),
                        _InfoItem(
                          label: '각속도 ω',
                          value: '${_angularVelocity.toStringAsFixed(1)} rad/s',
                          color: Colors.blue,
                        ),
                        _InfoItem(
                          label: 'RPM',
                          value: '${(_angularVelocity * 60 / (2 * math.pi)).toStringAsFixed(0)}',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 설명
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Text(
                  '💡 팔을 오므리면 관성 모멘트(I)가 감소하고, 각운동량(L)이 보존되어야 하므로 각속도(ω)가 증가합니다.',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),

              // 프리셋
              PresetGroup(
                label: '자세',
                presets: [
                  PresetButton(
                    label: '팔 오므림',
                    isSelected: _armExtension < 0.5,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _armExtension = 0.3);
                    },
                  ),
                  PresetButton(
                    label: '보통',
                    isSelected: _armExtension >= 0.5 && _armExtension <= 0.7,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _armExtension = 0.6);
                    },
                  ),
                  PresetButton(
                    label: '팔 벌림',
                    isSelected: _armExtension > 0.7,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _armExtension = 1.0);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '팔 벌림 정도',
                  value: _armExtension,
                  min: 0.3,
                  max: 1.0,
                  defaultValue: 1.0,
                  formatValue: (v) => '${(v * 100).toInt()}%',
                  onChanged: (v) => setState(() => _armExtension = v),
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

class _SkaterPainter extends CustomPainter {
  final double angle;
  final double armExtension;

  _SkaterPainter({required this.angle, required this.armExtension});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 회전 효과 (바닥 원)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, centerY + 80), width: 120, height: 30),
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(angle);

    // 몸통
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 20), width: 30, height: 60),
        const Radius.circular(10),
      ),
      Paint()..color = AppColors.accent,
    );

    // 머리
    canvas.drawCircle(const Offset(0, -20), 18, Paint()..color = const Color(0xFFFFDBB4));

    // 팔
    final armLength = 30 + armExtension * 40;
    final armY = 10.0;

    // 왼팔
    canvas.drawLine(
      Offset(-10, armY),
      Offset(-armLength, armY - 10),
      Paint()
        ..color = const Color(0xFFFFDBB4)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // 오른팔
    canvas.drawLine(
      Offset(10, armY),
      Offset(armLength, armY - 10),
      Paint()
        ..color = const Color(0xFFFFDBB4)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // 다리
    canvas.drawLine(
      const Offset(-8, 50),
      const Offset(-10, 90),
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.8)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      const Offset(8, 50),
      const Offset(10, 90),
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.8)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();

    // 속도 표시 (회전 속도에 따라 모션 블러 효과)
    final blurCount = (1 / (armExtension + 0.1) * 3).toInt().clamp(0, 8);
    for (int i = 1; i <= blurCount; i++) {
      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.rotate(angle - i * 0.15);
      canvas.drawCircle(
        const Offset(0, -20),
        18,
        Paint()..color = const Color(0xFFFFDBB4).withValues(alpha: 0.1),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SkaterPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.armExtension != armExtension;
  }
}
