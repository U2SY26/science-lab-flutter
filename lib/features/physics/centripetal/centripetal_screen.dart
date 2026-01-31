import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 구심력 시뮬레이션
class CentripetalScreen extends StatefulWidget {
  const CentripetalScreen({super.key});

  @override
  State<CentripetalScreen> createState() => _CentripetalScreenState();
}

class _CentripetalScreenState extends State<CentripetalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _radius = 100; // 반지름 (픽셀)
  double _mass = 1.0; // 질량 (kg)
  double _angularVelocity = 2.0; // 각속도 (rad/s)
  bool _showVectors = true;

  double get _linearVelocity => _angularVelocity * _radius / 50; // 선속도
  double get _centripetalForce => _mass * _linearVelocity * _linearVelocity / (_radius / 50);
  double get _centripetalAcceleration => _linearVelocity * _linearVelocity / (_radius / 50);
  double get _period => 2 * math.pi / _angularVelocity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
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
              '구심력',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '구심력',
          formula: 'F = mv²/r = mω²r',
          formulaDescription: '원운동하는 물체에 작용하는 중심 방향의 힘',
          simulation: SizedBox(
            height: 350,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CentripetalPainter(
                    radius: _radius,
                    angle: _controller.value * _angularVelocity * 10,
                    showVectors: _showVectors,
                    centripetalForce: _centripetalForce,
                  ),
                  size: Size.infinite,
                );
              },
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
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '선속도 v', value: '${_linearVelocity.toStringAsFixed(2)} m/s', color: Colors.green),
                        _InfoItem(label: '구심력 F', value: '${_centripetalForce.toStringAsFixed(2)} N', color: Colors.red),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '구심가속도 a', value: '${_centripetalAcceleration.toStringAsFixed(2)} m/s²', color: Colors.orange),
                        _InfoItem(label: '주기 T', value: '${_period.toStringAsFixed(2)} s', color: Colors.cyan),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 벡터 표시 토글
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showVectors = !_showVectors);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _showVectors ? AppColors.accent.withValues(alpha: 0.2) : AppColors.simBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _showVectors ? AppColors.accent : AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showVectors ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 18,
                        color: _showVectors ? AppColors.accent : AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '속도/가속도 벡터 표시',
                        style: TextStyle(
                          color: _showVectors ? AppColors.accent : AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '각속도 ω (rad/s)',
                  value: _angularVelocity,
                  min: 0.5,
                  max: 5.0,
                  defaultValue: 2.0,
                  formatValue: (v) => '${v.toStringAsFixed(1)} rad/s',
                  onChanged: (v) => setState(() => _angularVelocity = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '반지름 r',
                    value: _radius,
                    min: 50,
                    max: 140,
                    defaultValue: 100,
                    formatValue: (v) => '${(v / 50).toStringAsFixed(1)} m',
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                  SimSlider(
                    label: '질량 m (kg)',
                    value: _mass,
                    min: 0.5,
                    max: 5.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                    onChanged: (v) => setState(() => _mass = v),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '느리게',
                icon: Icons.slow_motion_video,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _angularVelocity = 1.0);
                },
              ),
              SimButton(
                label: '보통',
                icon: Icons.speed,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _angularVelocity = 2.0);
                },
              ),
              SimButton(
                label: '빠르게',
                icon: Icons.fast_forward,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _angularVelocity = 4.0);
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
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _CentripetalPainter extends CustomPainter {
  final double radius;
  final double angle;
  final bool showVectors;
  final double centripetalForce;

  _CentripetalPainter({
    required this.radius,
    required this.angle,
    required this.showVectors,
    required this.centripetalForce,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 원형 경로
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 중심점
    canvas.drawCircle(Offset(centerX, centerY), 5, Paint()..color = AppColors.muted);

    // 물체 위치
    final objectX = centerX + radius * math.cos(angle);
    final objectY = centerY + radius * math.sin(angle);

    // 반지름 선
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(objectX, objectY),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // 물체
    canvas.drawCircle(
      Offset(objectX, objectY),
      15,
      Paint()..color = AppColors.accent,
    );

    if (showVectors) {
      // 속도 벡터 (접선 방향)
      final velocityAngle = angle + math.pi / 2;
      final velocityLength = 50.0;
      _drawArrow(
        canvas,
        Offset(objectX, objectY),
        Offset(
          objectX + velocityLength * math.cos(velocityAngle),
          objectY + velocityLength * math.sin(velocityAngle),
        ),
        Colors.green,
        'v',
      );

      // 구심력/가속도 벡터 (중심 방향)
      final forceLength = (centripetalForce * 10).clamp(20.0, 60.0);
      final forceAngle = angle + math.pi;
      _drawArrow(
        canvas,
        Offset(objectX, objectY),
        Offset(
          objectX + forceLength * math.cos(forceAngle),
          objectY + forceLength * math.sin(forceAngle),
        ),
        Colors.red,
        'F',
      );
    }

    // 범례
    if (showVectors) {
      _drawLegend(canvas, size);
    }

    // 반지름 라벨
    _drawText(canvas, 'r', Offset(centerX + radius / 2 - 10, centerY - 15), AppColors.muted);
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color, String label) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, paint);

    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowSize = 10.0;

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - arrowSize * math.cos(angle - math.pi / 6), end.dy - arrowSize * math.sin(angle - math.pi / 6))
      ..lineTo(end.dx - arrowSize * math.cos(angle + math.pi / 6), end.dy - arrowSize * math.sin(angle + math.pi / 6))
      ..close();

    canvas.drawPath(path, Paint()..color = color);

    _drawText(canvas, label, Offset(end.dx + 5, end.dy - 15), color, fontSize: 14, fontWeight: FontWeight.bold);
  }

  void _drawLegend(Canvas canvas, Size size) {
    _drawText(canvas, 'v: 선속도 (접선 방향)', Offset(10, size.height - 40), Colors.green, fontSize: 10);
    _drawText(canvas, 'F: 구심력 (중심 방향)', Offset(10, size.height - 25), Colors.red, fontSize: 10);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12, FontWeight fontWeight = FontWeight.normal}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _CentripetalPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.radius != radius || oldDelegate.showVectors != showVectors;
  }
}
