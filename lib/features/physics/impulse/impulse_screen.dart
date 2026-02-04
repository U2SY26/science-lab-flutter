import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Impulse and Momentum simulation: J = FΔt = Δp
class ImpulseScreen extends StatefulWidget {
  const ImpulseScreen({super.key});

  @override
  State<ImpulseScreen> createState() => _ImpulseScreenState();
}

class _ImpulseScreenState extends State<ImpulseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  double mass = 2.0; // kg
  double force = 50.0; // N
  double impactTime = 0.5; // s
  double initialVelocity = 0.0; // m/s
  double currentVelocity = 0.0; // m/s
  double position = 0.0;
  double elapsedTime = 0.0;

  bool isRunning = false;
  bool isKorean = true;
  bool forceApplied = false;

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
      elapsedTime += dt;

      if (elapsedTime <= impactTime) {
        // Force is being applied
        forceApplied = true;
        final acceleration = force / mass;
        currentVelocity = initialVelocity + acceleration * elapsedTime;
      } else {
        forceApplied = false;
        // Constant velocity after force stops
      }

      position += currentVelocity * dt;

      if (position > 15) {
        _reset();
      }
    });
  }

  double get impulse => force * impactTime;
  double get momentumChange => mass * (currentVelocity - initialVelocity);
  double get finalVelocity => initialVelocity + (force * impactTime) / mass;

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      position = 0;
      currentVelocity = initialVelocity;
      elapsedTime = 0;
      isRunning = false;
      forceApplied = false;
    });
  }

  void _applyImpulse() {
    HapticFeedback.selectionClick();
    setState(() {
      if (position > 0) _reset();
      currentVelocity = initialVelocity;
      elapsedTime = 0;
      isRunning = true;
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
              isKorean ? '역학 시뮬레이션' : 'MECHANICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '충격량과 운동량' : 'Impulse & Momentum',
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
          category: isKorean ? '역학 시뮬레이션' : 'Mechanics Simulation',
          title: isKorean ? '충격량과 운동량' : 'Impulse & Momentum',
          formula: 'J = FΔt = Δp = mΔv',
          formulaDescription: isKorean
              ? '충격량(J)은 힘과 시간의 곱이며, 운동량의 변화량과 같습니다.'
              : 'Impulse (J) is force times time interval, equal to change in momentum.',
          simulation: CustomPaint(
            painter: ImpulsePainter(
              mass: mass,
              force: force,
              impactTime: impactTime,
              initialVelocity: initialVelocity,
              currentVelocity: currentVelocity,
              position: position,
              elapsedTime: elapsedTime,
              impulse: impulse,
              forceApplied: forceApplied,
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
                  min: 10,
                  max: 200,
                  defaultValue: 50,
                  formatValue: (v) => '${v.toStringAsFixed(0)} N',
                  onChanged: (v) => setState(() => force = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '충돌 시간 (Δt)' : 'Impact Time (Δt)',
                    value: impactTime,
                    min: 0.1,
                    max: 2.0,
                    step: 0.1,
                    defaultValue: 0.5,
                    formatValue: (v) => '${v.toStringAsFixed(1)} s',
                    onChanged: (v) => setState(() => impactTime = v),
                  ),
                  SimSlider(
                    label: isKorean ? '질량 (m)' : 'Mass (m)',
                    value: mass,
                    min: 0.5,
                    max: 10,
                    defaultValue: 2,
                    formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                    onChanged: (v) => setState(() => mass = v),
                  ),
                  SimSlider(
                    label: isKorean ? '초기 속도 (v₀)' : 'Initial Velocity (v₀)',
                    value: initialVelocity,
                    min: 0,
                    max: 5,
                    defaultValue: 0,
                    formatValue: (v) => '${v.toStringAsFixed(1)} m/s',
                    onChanged: (v) => setState(() {
                      initialVelocity = v;
                      if (!isRunning) currentVelocity = v;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ImpulseDisplay(
                impulse: impulse,
                momentumChange: momentumChange,
                initialVelocity: initialVelocity,
                currentVelocity: currentVelocity,
                finalVelocity: finalVelocity,
                mass: mass,
                isKorean: isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '충격 가하기' : 'Apply Impulse',
                icon: Icons.flash_on,
                isPrimary: true,
                onPressed: _applyImpulse,
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

class _ImpulseDisplay extends StatelessWidget {
  final double impulse;
  final double momentumChange;
  final double initialVelocity;
  final double currentVelocity;
  final double finalVelocity;
  final double mass;
  final bool isKorean;

  const _ImpulseDisplay({
    required this.impulse,
    required this.momentumChange,
    required this.initialVelocity,
    required this.currentVelocity,
    required this.finalVelocity,
    required this.mass,
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
                label: isKorean ? '충격량 (J)' : 'Impulse (J)',
                value: '${impulse.toStringAsFixed(1)} N·s',
                color: AppColors.accent2,
              ),
              _InfoItem(
                label: isKorean ? '운동량 변화' : 'Δp',
                value: '${momentumChange.toStringAsFixed(1)} kg·m/s',
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(
                label: isKorean ? '초기 p' : 'Initial p',
                value: '${(mass * initialVelocity).toStringAsFixed(1)} kg·m/s',
                color: AppColors.muted,
              ),
              _InfoItem(
                label: isKorean ? '현재 속도' : 'Current v',
                value: '${currentVelocity.toStringAsFixed(2)} m/s',
                color: AppColors.ink,
              ),
              _InfoItem(
                label: isKorean ? '최종 v' : 'Final v',
                value: '${finalVelocity.toStringAsFixed(2)} m/s',
                color: AppColors.accent,
              ),
            ],
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
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ImpulsePainter extends CustomPainter {
  final double mass;
  final double force;
  final double impactTime;
  final double initialVelocity;
  final double currentVelocity;
  final double position;
  final double elapsedTime;
  final double impulse;
  final bool forceApplied;
  final bool isKorean;

  ImpulsePainter({
    required this.mass,
    required this.force,
    required this.impactTime,
    required this.initialVelocity,
    required this.currentVelocity,
    required this.position,
    required this.elapsedTime,
    required this.impulse,
    required this.forceApplied,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    final groundY = size.height * 0.7;

    // Ground
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 2,
    );

    // Object position
    final objectX = 80 + (position / 15) * (size.width - 160);
    final objectSize = 30.0 + mass * 4;

    // Object shadow
    canvas.drawCircle(
      Offset(objectX + 3, groundY - objectSize / 2 + 3),
      objectSize / 2,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Object (ball)
    final ballGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        forceApplied ? AppColors.accent2 : AppColors.accent,
        forceApplied
            ? AppColors.accent2.withValues(alpha: 0.7)
            : AppColors.accent.withValues(alpha: 0.7),
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(objectX, groundY - objectSize / 2),
      radius: objectSize / 2,
    ));

    canvas.drawCircle(
      Offset(objectX, groundY - objectSize / 2),
      objectSize / 2,
      Paint()..shader = ballGradient,
    );

    // Highlight
    canvas.drawCircle(
      Offset(objectX - objectSize / 4, groundY - objectSize / 2 - objectSize / 4),
      objectSize / 6,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Force arrow (when applied)
    if (forceApplied) {
      final arrowLength = force / 3;
      final arrowStart = Offset(objectX - objectSize / 2 - 10, groundY - objectSize / 2);
      final arrowEnd = Offset(arrowStart.dx - arrowLength, arrowStart.dy);

      // Glow effect
      canvas.drawLine(
        arrowEnd,
        arrowStart,
        Paint()
          ..color = AppColors.accent2.withValues(alpha: 0.3)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawLine(
        arrowEnd,
        arrowStart,
        Paint()
          ..color = AppColors.accent2
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );

      // Arrow head
      final arrowPath = Path()
        ..moveTo(arrowStart.dx, arrowStart.dy)
        ..lineTo(arrowStart.dx - 12, arrowStart.dy - 6)
        ..lineTo(arrowStart.dx - 12, arrowStart.dy + 6)
        ..close();
      canvas.drawPath(arrowPath, Paint()..color = AppColors.accent2);

      // Force label
      _drawText(canvas, 'F = ${force.toStringAsFixed(0)} N',
          Offset(arrowEnd.dx - 60, arrowEnd.dy - 10), AppColors.accent2, 12);
    }

    // Velocity arrow
    if (currentVelocity > 0.1) {
      final vArrowLength = currentVelocity * 10;
      final vArrowStart = Offset(objectX + objectSize / 2 + 5, groundY - objectSize / 2);
      final vArrowEnd = Offset(vArrowStart.dx + vArrowLength, vArrowStart.dy);

      canvas.drawLine(
        vArrowStart,
        vArrowEnd,
        Paint()
          ..color = AppColors.accent
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );

      final arrowPath = Path()
        ..moveTo(vArrowEnd.dx, vArrowEnd.dy)
        ..lineTo(vArrowEnd.dx - 8, vArrowEnd.dy - 4)
        ..lineTo(vArrowEnd.dx - 8, vArrowEnd.dy + 4)
        ..close();
      canvas.drawPath(arrowPath, Paint()..color = AppColors.accent);

      _drawText(canvas, 'v = ${currentVelocity.toStringAsFixed(1)} m/s',
          Offset(vArrowEnd.dx + 5, vArrowEnd.dy - 8), AppColors.accent, 10);
    }

    // Impulse-momentum graph area
    final graphX = 50.0;
    final graphY = 30.0;
    final graphWidth = size.width - 100;
    final graphHeight = size.height * 0.25;

    // Graph background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(graphX, graphY, graphWidth, graphHeight),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.card.withValues(alpha: 0.5),
    );

    // Time progress bar
    final timeProgress = (elapsedTime / impactTime).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(graphX + 10, graphY + graphHeight - 20, (graphWidth - 20) * timeProgress, 10),
        const Radius.circular(5),
      ),
      Paint()..color = forceApplied ? AppColors.accent2 : AppColors.muted,
    );

    // Labels
    _drawText(canvas, isKorean ? '충격량 그래프' : 'Impulse Graph',
        Offset(graphX + 10, graphY + 5), AppColors.ink, 11);
    _drawText(canvas, 'J = FΔt = ${impulse.toStringAsFixed(1)} N·s',
        Offset(graphX + 10, graphY + 22), AppColors.accent, 10);
    _drawText(canvas, 't: ${elapsedTime.toStringAsFixed(2)}s / ${impactTime.toStringAsFixed(1)}s',
        Offset(graphX + 10, graphY + graphHeight - 35), AppColors.muted, 9);
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

  @override
  bool shouldRepaint(covariant ImpulsePainter oldDelegate) => true;
}
