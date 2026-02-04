import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Torque simulation: τ = rFsinθ
class TorqueScreen extends StatefulWidget {
  const TorqueScreen({super.key});

  @override
  State<TorqueScreen> createState() => _TorqueScreenState();
}

class _TorqueScreenState extends State<TorqueScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  double force = 50.0; // N
  double radius = 0.5; // m (lever arm)
  double angle = 90.0; // degrees (angle between r and F)
  double rotation = 0.0; // current rotation angle
  double angularVelocity = 0.0;

  bool isRunning = false;
  bool isKorean = true;

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
      final dt = 0.016;
      // Simplified moment of inertia for a rod
      final momentOfInertia = 0.5 * radius * radius;
      final angularAcceleration = torque / momentOfInertia;

      angularVelocity += angularAcceleration * dt * 0.01;
      angularVelocity *= 0.995; // damping
      rotation += angularVelocity;
    });
  }

  double get torque => force * radius * math.sin(angle * math.pi / 180);

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      rotation = 0;
      angularVelocity = 0;
      isRunning = false;
    });
  }

  void _toggleSimulation() {
    HapticFeedback.selectionClick();
    setState(() => isRunning = !isRunning);
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
              isKorean ? '회전 역학' : 'ROTATIONAL MECHANICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '토크 (돌림힘)' : 'Torque',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Text(
              isKorean ? 'EN' : '한',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => setState(() => isKorean = !isKorean),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '회전 역학' : 'Rotational Mechanics',
          title: isKorean ? '토크 (돌림힘)' : 'Torque',
          formula: 'τ = rF sin θ',
          formulaDescription: isKorean
              ? '토크(τ)는 회전축에서 힘의 작용점까지의 거리(r)와 힘(F), 그리고 두 벡터 사이 각도의 사인 값의 곱입니다.'
              : 'Torque (τ) is the product of the lever arm (r), force (F), and sine of the angle between them.',
          simulation: CustomPaint(
            painter: TorquePainter(
              force: force,
              radius: radius,
              angle: angle,
              rotation: rotation,
              torque: torque,
              isKorean: isKorean,
            ),
            size: Size.infinite,
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '힘 (F)' : 'Force (F)',
                  value: force,
                  min: 0,
                  max: 100,
                  defaultValue: 50,
                  formatValue: (v) => '${v.toStringAsFixed(0)} N',
                  onChanged: (v) => setState(() => force = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '팔 길이 (r)' : 'Lever Arm (r)',
                    value: radius,
                    min: 0.1,
                    max: 1.5,
                    step: 0.1,
                    defaultValue: 0.5,
                    formatValue: (v) => '${v.toStringAsFixed(1)} m',
                    onChanged: (v) => setState(() => radius = v),
                  ),
                  SimSlider(
                    label: isKorean ? '각도 (θ)' : 'Angle (θ)',
                    value: angle,
                    min: 0,
                    max: 180,
                    defaultValue: 90,
                    formatValue: (v) => '${v.toStringAsFixed(0)}°',
                    onChanged: (v) => setState(() => angle = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _TorqueDisplay(
                torque: torque,
                force: force,
                radius: radius,
                angle: angle,
                rotation: rotation,
                isKorean: isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning
                    ? (isKorean ? '정지' : 'Stop')
                    : (isKorean ? '회전' : 'Rotate'),
                icon: isRunning ? Icons.pause : Icons.rotate_right,
                isPrimary: true,
                onPressed: _toggleSimulation,
              ),
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
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

class _TorqueDisplay extends StatelessWidget {
  final double torque;
  final double force;
  final double radius;
  final double angle;
  final double rotation;
  final bool isKorean;

  const _TorqueDisplay({
    required this.torque,
    required this.force,
    required this.radius,
    required this.angle,
    required this.rotation,
    required this.isKorean,
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
      child: Column(
        children: [
          Row(
            children: [
              _InfoItem(
                label: isKorean ? '토크 (τ)' : 'Torque (τ)',
                value: '${torque.toStringAsFixed(1)} N·m',
                color: AppColors.accent2,
              ),
              _InfoItem(
                label: 'sin θ',
                value: math.sin(angle * math.pi / 180).toStringAsFixed(3),
                color: AppColors.accent,
              ),
              _InfoItem(
                label: isKorean ? '회전각' : 'Rotation',
                value: '${(rotation * 180 / math.pi % 360).toStringAsFixed(1)}°',
                color: AppColors.ink,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'τ = ${radius.toStringAsFixed(1)} × ${force.toStringAsFixed(0)} × sin(${angle.toStringAsFixed(0)}°) = ${torque.toStringAsFixed(1)} N·m',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.color,
  });

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
            style: TextStyle(
              color: color,
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

class TorquePainter extends CustomPainter {
  final double force;
  final double radius;
  final double angle;
  final double rotation;
  final double torque;
  final bool isKorean;

  TorquePainter({
    required this.force,
    required this.radius,
    required this.angle,
    required this.rotation,
    required this.torque,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final leverLength = radius * 120; // Scale for visualization

    // Save canvas state
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(rotation);

    // Draw pivot point
    canvas.drawCircle(
      Offset.zero,
      12,
      Paint()..color = AppColors.pivot,
    );
    canvas.drawCircle(
      Offset.zero,
      8,
      Paint()..color = AppColors.ink,
    );

    // Draw lever arm (wrench shape)
    final leverPath = Path()
      ..moveTo(-15, -8)
      ..lineTo(leverLength - 20, -8)
      ..lineTo(leverLength - 20, -15)
      ..lineTo(leverLength, 0)
      ..lineTo(leverLength - 20, 15)
      ..lineTo(leverLength - 20, 8)
      ..lineTo(-15, 8)
      ..close();

    canvas.drawPath(
      leverPath,
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      leverPath,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Radius vector (r)
    canvas.drawLine(
      Offset.zero,
      Offset(leverLength, 0),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // r label
    _drawRotatedText(canvas, 'r', Offset(leverLength / 2, -20), AppColors.accent, 12, -rotation);

    canvas.restore();

    // Draw force vector at the end of lever
    final forceAngleRad = (angle - 90) * math.pi / 180 + rotation;
    final leverEndX = centerX + leverLength * math.cos(rotation);
    final leverEndY = centerY + leverLength * math.sin(rotation);

    final forceLength = force * 0.8;
    final forceEndX = leverEndX + forceLength * math.cos(forceAngleRad);
    final forceEndY = leverEndY + forceLength * math.sin(forceAngleRad);

    // Force arrow
    canvas.drawLine(
      Offset(leverEndX, leverEndY),
      Offset(forceEndX, forceEndY),
      Paint()
        ..color = AppColors.accent2
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Arrow head
    final arrowAngle = math.atan2(forceEndY - leverEndY, forceEndX - leverEndX);
    final arrowPath = Path()
      ..moveTo(forceEndX, forceEndY)
      ..lineTo(
        forceEndX - 12 * math.cos(arrowAngle - 0.4),
        forceEndY - 12 * math.sin(arrowAngle - 0.4),
      )
      ..lineTo(
        forceEndX - 12 * math.cos(arrowAngle + 0.4),
        forceEndY - 12 * math.sin(arrowAngle + 0.4),
      )
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = AppColors.accent2);

    // Force label
    _drawText(canvas, 'F', Offset(forceEndX + 5, forceEndY - 15), AppColors.accent2, 14);

    // Draw angle arc
    if (angle > 0 && angle < 180) {
      final arcRadius = 30.0;
      final startAngle = rotation;
      final sweepAngle = (angle - 90) * math.pi / 180;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(leverEndX, leverEndY), radius: arcRadius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Angle label
      final angleLabelAngle = startAngle + sweepAngle / 2;
      _drawText(
        canvas,
        'θ',
        Offset(
          leverEndX + (arcRadius + 15) * math.cos(angleLabelAngle),
          leverEndY + (arcRadius + 15) * math.sin(angleLabelAngle) - 8,
        ),
        AppColors.accent,
        12,
      );
    }

    // Rotation direction indicator
    if (torque.abs() > 0.1) {
      final rotDir = torque > 0 ? 1 : -1;
      final arcStart = -math.pi / 4;
      final arcSweep = math.pi / 2 * rotDir;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: leverLength + 30),
        arcStart,
        arcSweep,
        false,
        Paint()
          ..color = AppColors.accent2.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );

      // Arrow at end of arc
      final arrowEndAngle = arcStart + arcSweep;
      final arrowTipX = centerX + (leverLength + 30) * math.cos(arrowEndAngle);
      final arrowTipY = centerY + (leverLength + 30) * math.sin(arrowEndAngle);

      final tangentAngle = arrowEndAngle + math.pi / 2 * rotDir;
      final rotArrowPath = Path()
        ..moveTo(arrowTipX, arrowTipY)
        ..lineTo(
          arrowTipX - 10 * math.cos(tangentAngle - 0.5),
          arrowTipY - 10 * math.sin(tangentAngle - 0.5),
        )
        ..lineTo(
          arrowTipX - 10 * math.cos(tangentAngle + 0.5),
          arrowTipY - 10 * math.sin(tangentAngle + 0.5),
        )
        ..close();
      canvas.drawPath(rotArrowPath, Paint()..color = AppColors.accent2.withValues(alpha: 0.5));
    }

    // Formula display
    _drawText(
      canvas,
      'τ = rF sin θ',
      Offset(20, 20),
      AppColors.ink,
      14,
    );
    _drawText(
      canvas,
      '= ${radius.toStringAsFixed(1)} × ${force.toStringAsFixed(0)} × ${math.sin(angle * math.pi / 180).toStringAsFixed(2)}',
      Offset(20, 40),
      AppColors.muted,
      12,
    );
    _drawText(
      canvas,
      '= ${torque.toStringAsFixed(1)} N·m',
      Offset(20, 58),
      AppColors.accent2,
      12,
    );
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

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  void _drawRotatedText(Canvas canvas, String text, Offset position, Color color, double fontSize, double angle) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);
    _drawText(canvas, text, Offset.zero, color, fontSize);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TorquePainter oldDelegate) => true;
}
