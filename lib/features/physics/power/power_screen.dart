import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Power simulation: P = W/t
class PowerScreen extends StatefulWidget {
  const PowerScreen({super.key});

  @override
  State<PowerScreen> createState() => _PowerScreenState();
}

class _PowerScreenState extends State<PowerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  double force = 100.0; // N
  double distance = 0.0; // m (current)
  double maxDistance = 10.0; // m (target)
  double time = 0.0; // s
  double velocity = 2.0; // m/s

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
      time += dt;
      distance += velocity * dt;

      if (distance >= maxDistance) {
        distance = maxDistance;
        isRunning = false;
      }
    });
  }

  double get work => force * distance;
  double get power => time > 0 ? work / time : 0;
  double get instantPower => force * velocity;

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      distance = 0;
      time = 0;
      isRunning = false;
    });
  }

  void _toggleSimulation() {
    HapticFeedback.selectionClick();
    setState(() {
      if (distance >= maxDistance) {
        distance = 0;
        time = 0;
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
              isKorean ? '일률 (파워)' : 'Power',
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
          title: isKorean ? '일률 (파워)' : 'Power',
          formula: 'P = W/t = Fv',
          formulaDescription: isKorean
              ? '일률(P)은 단위 시간당 한 일의 양입니다. 힘과 속도의 곱과 같습니다.'
              : 'Power (P) is the rate at which work is done. It equals force times velocity.',
          simulation: CustomPaint(
            painter: PowerPainter(
              force: force,
              distance: distance,
              maxDistance: maxDistance,
              time: time,
              velocity: velocity,
              work: work,
              power: power,
              instantPower: instantPower,
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
                  max: 500,
                  defaultValue: 100,
                  formatValue: (v) => '${v.toStringAsFixed(0)} N',
                  onChanged: (v) => setState(() => force = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '속도 (v)' : 'Velocity (v)',
                    value: velocity,
                    min: 0.5,
                    max: 10,
                    defaultValue: 2,
                    formatValue: (v) => '${v.toStringAsFixed(1)} m/s',
                    onChanged: (v) => setState(() => velocity = v),
                  ),
                  SimSlider(
                    label: isKorean ? '목표 거리' : 'Target Distance',
                    value: maxDistance,
                    min: 5,
                    max: 20,
                    defaultValue: 10,
                    formatValue: (v) => '${v.toStringAsFixed(0)} m',
                    onChanged: (v) => setState(() => maxDistance = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PowerDisplay(
                work: work,
                time: time,
                power: power,
                instantPower: instantPower,
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

class _PowerDisplay extends StatelessWidget {
  final double work;
  final double time;
  final double power;
  final double instantPower;
  final double distance;
  final bool isKorean;

  const _PowerDisplay({
    required this.work,
    required this.time,
    required this.power,
    required this.instantPower,
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
                value: '${work.toStringAsFixed(0)} J',
                color: AppColors.accent,
              ),
              _InfoItem(
                label: isKorean ? '시간 (t)' : 'Time (t)',
                value: '${time.toStringAsFixed(2)} s',
                color: AppColors.muted,
              ),
              _InfoItem(
                label: isKorean ? '거리 (d)' : 'Distance (d)',
                value: '${distance.toStringAsFixed(2)} m',
                color: AppColors.ink,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(
                label: isKorean ? '평균 일률' : 'Avg Power',
                value: '${power.toStringAsFixed(1)} W',
                color: AppColors.accent2,
              ),
              _InfoItem(
                label: isKorean ? '순간 일률 (Fv)' : 'Inst. Power (Fv)',
                value: '${instantPower.toStringAsFixed(1)} W',
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

class PowerPainter extends CustomPainter {
  final double force;
  final double distance;
  final double maxDistance;
  final double time;
  final double velocity;
  final double work;
  final double power;
  final double instantPower;
  final bool isKorean;

  PowerPainter({
    required this.force,
    required this.distance,
    required this.maxDistance,
    required this.time,
    required this.velocity,
    required this.work,
    required this.power,
    required this.instantPower,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    // Ground line
    final groundY = size.height * 0.65;
    canvas.drawLine(
      Offset(30, groundY),
      Offset(size.width - 30, groundY),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 2,
    );

    // Progress track
    final trackStartX = 50.0;
    final trackEndX = size.width - 50;
    final trackWidth = trackEndX - trackStartX;

    // Track background
    canvas.drawLine(
      Offset(trackStartX, groundY - 20),
      Offset(trackEndX, groundY - 20),
      Paint()
        ..color = AppColors.cardBorder
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Progress
    final progress = distance / maxDistance;
    canvas.drawLine(
      Offset(trackStartX, groundY - 20),
      Offset(trackStartX + trackWidth * progress, groundY - 20),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Cart/Object
    final cartX = trackStartX + trackWidth * progress;
    final cartSize = 40.0;
    final cartRect = Rect.fromCenter(
      center: Offset(cartX, groundY - 45),
      width: cartSize,
      height: cartSize * 0.7,
    );

    // Cart body
    final cartGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.7)],
    ).createShader(cartRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cartRect, const Radius.circular(5)),
      Paint()..shader = cartGradient,
    );

    // Wheels
    final wheelRadius = 8.0;
    canvas.drawCircle(
      Offset(cartX - 12, groundY - 20),
      wheelRadius,
      Paint()..color = AppColors.ink,
    );
    canvas.drawCircle(
      Offset(cartX + 12, groundY - 20),
      wheelRadius,
      Paint()..color = AppColors.ink,
    );

    // Force arrow
    final arrowLength = force / 10;
    final arrowStart = Offset(cartX + cartSize / 2, groundY - 45);
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
      ..lineTo(arrowEnd.dx - 8, arrowEnd.dy - 4)
      ..lineTo(arrowEnd.dx - 8, arrowEnd.dy + 4)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = AppColors.accent2);

    // Power meter visualization
    final meterX = size.width - 80;
    final meterY = 40.0;
    final meterHeight = size.height * 0.35;
    final maxPower = 5000.0;
    final powerFill = (power / maxPower).clamp(0.0, 1.0);

    // Meter background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(meterX, meterY, 30, meterHeight),
        const Radius.circular(5),
      ),
      Paint()..color = AppColors.cardBorder,
    );

    // Meter fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          meterX,
          meterY + meterHeight * (1 - powerFill),
          30,
          meterHeight * powerFill,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = AppColors.accent2,
    );

    // Meter label
    _drawText(canvas, isKorean ? '일률' : 'Power', Offset(meterX - 5, meterY - 18), AppColors.muted, 10);
    _drawText(canvas, '${power.toStringAsFixed(0)}W', Offset(meterX - 5, meterY + meterHeight + 5), AppColors.accent2, 11);

    // Distance markers
    for (int i = 0; i <= maxDistance.toInt(); i += 2) {
      final markerX = trackStartX + (i / maxDistance) * trackWidth;
      canvas.drawLine(
        Offset(markerX, groundY),
        Offset(markerX, groundY + 8),
        Paint()
          ..color = AppColors.muted
          ..strokeWidth = 1,
      );
      _drawText(canvas, '${i}m', Offset(markerX - 8, groundY + 12), AppColors.muted, 9);
    }

    // Formula display
    _drawText(
      canvas,
      'P = W/t = ${work.toStringAsFixed(0)}/${time.toStringAsFixed(2)} = ${power.toStringAsFixed(1)} W',
      Offset(50, 30),
      AppColors.ink,
      12,
    );
    _drawText(
      canvas,
      'P = Fv = ${force.toStringAsFixed(0)} × ${velocity.toStringAsFixed(1)} = ${instantPower.toStringAsFixed(1)} W',
      Offset(50, 50),
      AppColors.accent,
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

  @override
  bool shouldRepaint(covariant PowerPainter oldDelegate) => true;
}
