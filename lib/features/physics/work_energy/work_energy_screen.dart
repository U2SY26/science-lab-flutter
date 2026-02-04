import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Work-Energy Theorem simulation: W = ΔKE
class WorkEnergyScreen extends StatefulWidget {
  const WorkEnergyScreen({super.key});

  @override
  State<WorkEnergyScreen> createState() => _WorkEnergyScreenState();
}

class _WorkEnergyScreenState extends State<WorkEnergyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  double mass = 2.0; // kg
  double force = 10.0; // N
  double friction = 0.1; // friction coefficient
  double distance = 0.0; // m (current position)
  double velocity = 0.0; // m/s
  double initialVelocity = 0.0; // m/s

  bool isRunning = false;
  bool isKorean = true;

  // Track energy values
  double workDone = 0.0;
  double initialKE = 0.0;
  double currentKE = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);
    _controller.repeat();
    _calculateEnergies();
  }

  void _updatePhysics() {
    if (!isRunning) return;

    setState(() {
      final dt = 0.016; // ~60fps

      // Net force = Applied force - Friction
      final frictionForce = friction * mass * 9.8;
      final netForce = force - frictionForce;

      // Acceleration
      final acceleration = netForce / mass;

      // Update velocity and position
      velocity += acceleration * dt;
      if (velocity < 0) velocity = 0;

      distance += velocity * dt;

      // Reset if too far
      if (distance > 10) {
        distance = 0;
        velocity = initialVelocity;
      }

      _calculateEnergies();
    });
  }

  void _calculateEnergies() {
    initialKE = 0.5 * mass * initialVelocity * initialVelocity;
    currentKE = 0.5 * mass * velocity * velocity;
    workDone = currentKE - initialKE;
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      distance = 0;
      velocity = initialVelocity;
      isRunning = false;
      _calculateEnergies();
    });
  }

  void _toggleSimulation() {
    HapticFeedback.selectionClick();
    setState(() {
      if (!isRunning && distance == 0) {
        velocity = initialVelocity;
      }
      isRunning = !isRunning;
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
              isKorean ? '일-에너지 정리' : 'Work-Energy Theorem',
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
          title: isKorean ? '일-에너지 정리' : 'Work-Energy Theorem',
          formula: 'W = ΔKE = ½mv₂² - ½mv₁²',
          formulaDescription: isKorean
              ? '물체에 한 일(W)은 운동에너지의 변화량(ΔKE)과 같습니다.'
              : 'The work done on an object equals the change in its kinetic energy.',
          simulation: CustomPaint(
            painter: WorkEnergyPainter(
              mass: mass,
              force: force,
              friction: friction,
              distance: distance,
              velocity: velocity,
              workDone: workDone,
              initialKE: initialKE,
              currentKE: currentKE,
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
                  max: 50,
                  defaultValue: 10,
                  formatValue: (v) => '${v.toStringAsFixed(1)} N',
                  onChanged: (v) => setState(() => force = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '질량 (m)' : 'Mass (m)',
                    value: mass,
                    min: 0.5,
                    max: 10,
                    defaultValue: 2,
                    formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                    onChanged: (v) => setState(() {
                      mass = v;
                      _calculateEnergies();
                    }),
                  ),
                  SimSlider(
                    label: isKorean ? '마찰 계수 (μ)' : 'Friction (μ)',
                    value: friction,
                    min: 0,
                    max: 0.5,
                    step: 0.01,
                    defaultValue: 0.1,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => setState(() => friction = v),
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
                      if (!isRunning) velocity = v;
                      _calculateEnergies();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _EnergyDisplay(
                workDone: workDone,
                initialKE: initialKE,
                currentKE: currentKE,
                velocity: velocity,
                distance: distance,
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
                    : (isKorean ? '시작' : 'Start'),
                icon: isRunning ? Icons.pause : Icons.play_arrow,
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

class _EnergyDisplay extends StatelessWidget {
  final double workDone;
  final double initialKE;
  final double currentKE;
  final double velocity;
  final double distance;
  final bool isKorean;

  const _EnergyDisplay({
    required this.workDone,
    required this.initialKE,
    required this.currentKE,
    required this.velocity,
    required this.distance,
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
                label: isKorean ? '일 (W)' : 'Work (W)',
                value: '${workDone.toStringAsFixed(1)} J',
                color: AppColors.accent,
              ),
              _InfoItem(
                label: isKorean ? '초기 KE' : 'Initial KE',
                value: '${initialKE.toStringAsFixed(1)} J',
                color: AppColors.muted,
              ),
              _InfoItem(
                label: isKorean ? '현재 KE' : 'Current KE',
                value: '${currentKE.toStringAsFixed(1)} J',
                color: AppColors.accent2,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(
                label: isKorean ? '속도' : 'Velocity',
                value: '${velocity.toStringAsFixed(2)} m/s',
                color: AppColors.ink,
              ),
              _InfoItem(
                label: isKorean ? '거리' : 'Distance',
                value: '${distance.toStringAsFixed(2)} m',
                color: AppColors.ink,
              ),
              _InfoItem(
                label: 'ΔKE',
                value: '${(currentKE - initialKE).toStringAsFixed(1)} J',
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

class WorkEnergyPainter extends CustomPainter {
  final double mass;
  final double force;
  final double friction;
  final double distance;
  final double velocity;
  final double workDone;
  final double initialKE;
  final double currentKE;
  final bool isKorean;

  WorkEnergyPainter({
    required this.mass,
    required this.force,
    required this.friction,
    required this.distance,
    required this.velocity,
    required this.workDone,
    required this.initialKE,
    required this.currentKE,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    // Draw grid
    _drawGrid(canvas, size);

    // Ground
    final groundY = size.height * 0.7;
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 2,
    );

    // Block position (scaled)
    final blockX = 50 + (distance / 10) * (size.width - 150);
    final blockSize = 30.0 + mass * 5;

    // Draw block
    final blockRect = Rect.fromCenter(
      center: Offset(blockX, groundY - blockSize / 2),
      width: blockSize,
      height: blockSize,
    );

    // Block shadow
    canvas.drawRect(
      blockRect.shift(const Offset(3, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Block gradient
    final blockGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.accent,
        AppColors.accent.withValues(alpha: 0.7),
      ],
    ).createShader(blockRect);

    canvas.drawRect(blockRect, Paint()..shader = blockGradient);
    canvas.drawRect(
      blockRect,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw force arrow
    if (force > 0) {
      final arrowLength = force * 2;
      final arrowStart = Offset(blockX + blockSize / 2 + 5, groundY - blockSize / 2);
      final arrowEnd = Offset(arrowStart.dx + arrowLength, arrowStart.dy);

      canvas.drawLine(
        arrowStart,
        arrowEnd,
        Paint()
          ..color = AppColors.accent2
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );

      // Arrow head
      final arrowPath = Path()
        ..moveTo(arrowEnd.dx, arrowEnd.dy)
        ..lineTo(arrowEnd.dx - 10, arrowEnd.dy - 5)
        ..lineTo(arrowEnd.dx - 10, arrowEnd.dy + 5)
        ..close();
      canvas.drawPath(arrowPath, Paint()..color = AppColors.accent2);

      // Force label
      _drawText(
        canvas,
        'F = ${force.toStringAsFixed(0)} N',
        Offset(arrowEnd.dx + 5, arrowEnd.dy - 10),
        AppColors.accent2,
        12,
      );
    }

    // Draw friction arrow (opposite direction)
    if (friction > 0 && velocity > 0) {
      final frictionForce = friction * mass * 9.8;
      final frictionLength = frictionForce * 2;
      final frictionStart = Offset(blockX - blockSize / 2 - 5, groundY - blockSize / 2);
      final frictionEnd = Offset(frictionStart.dx - frictionLength, frictionStart.dy);

      canvas.drawLine(
        frictionStart,
        frictionEnd,
        Paint()
          ..color = AppColors.muted
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );

      // Arrow head
      final arrowPath = Path()
        ..moveTo(frictionEnd.dx, frictionEnd.dy)
        ..lineTo(frictionEnd.dx + 8, frictionEnd.dy - 4)
        ..lineTo(frictionEnd.dx + 8, frictionEnd.dy + 4)
        ..close();
      canvas.drawPath(arrowPath, Paint()..color = AppColors.muted);
    }

    // Energy bar visualization
    final barY = size.height * 0.2;
    final barHeight = 20.0;
    final maxEnergy = math.max(currentKE, initialKE) + force * 10;
    final barScale = (size.width - 100) / (maxEnergy > 0 ? maxEnergy : 1);

    // Initial KE bar
    canvas.drawRect(
      Rect.fromLTWH(50, barY, initialKE * barScale, barHeight),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );

    // Current KE bar
    canvas.drawRect(
      Rect.fromLTWH(50, barY + barHeight + 5, currentKE * barScale, barHeight),
      Paint()..color = AppColors.accent2,
    );

    // Labels
    _drawText(
      canvas,
      isKorean ? '초기 KE' : 'Initial KE',
      Offset(50, barY - 15),
      AppColors.muted,
      10,
    );
    _drawText(
      canvas,
      isKorean ? '현재 KE' : 'Current KE',
      Offset(50, barY + barHeight - 5),
      AppColors.accent2,
      10,
    );

    // Distance markers
    for (int i = 0; i <= 10; i += 2) {
      final markerX = 50 + (i / 10) * (size.width - 150);
      canvas.drawLine(
        Offset(markerX, groundY),
        Offset(markerX, groundY + 10),
        Paint()
          ..color = AppColors.muted
          ..strokeWidth = 1,
      );
      _drawText(
        canvas,
        '${i}m',
        Offset(markerX - 8, groundY + 15),
        AppColors.muted,
        9,
      );
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
  bool shouldRepaint(covariant WorkEnergyPainter oldDelegate) => true;
}
