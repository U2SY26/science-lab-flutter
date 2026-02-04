import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Heat Engine simulation: η = W/Qh
class HeatEngineScreen extends StatefulWidget {
  const HeatEngineScreen({super.key});

  @override
  State<HeatEngineScreen> createState() => _HeatEngineScreenState();
}

class _HeatEngineScreenState extends State<HeatEngineScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  double heatIn = 1000.0; // Qh (J)
  double heatOut = 600.0; // Qc (J)
  double pistonPosition = 0.0;

  bool isRunning = false;
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _updateAnimation() {
    if (!isRunning) return;

    setState(() {
      pistonPosition += 0.03;
      if (pistonPosition > 2 * math.pi) {
        pistonPosition -= 2 * math.pi;
      }
    });
  }

  double get workOutput => heatIn - heatOut;
  double get efficiency => (workOutput / heatIn) * 100;

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      heatIn = 1000;
      heatOut = 600;
      pistonPosition = 0;
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
              isKorean ? '열역학' : 'THERMODYNAMICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '열기관' : 'Heat Engine',
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
          category: isKorean ? '열역학' : 'Thermodynamics',
          title: isKorean ? '열기관' : 'Heat Engine',
          formula: 'η = W/Qh = (Qh - Qc)/Qh',
          formulaDescription: isKorean
              ? '열기관의 효율(η)은 출력한 일(W)을 흡수한 열(Qh)로 나눈 값입니다.'
              : 'Heat engine efficiency (η) is work output (W) divided by heat input (Qh).',
          simulation: CustomPaint(
            painter: _HeatEnginePainter(
              heatIn: heatIn,
              heatOut: heatOut,
              workOutput: workOutput,
              efficiency: efficiency,
              pistonPosition: pistonPosition,
              isRunning: isRunning,
              isKorean: isKorean,
            ),
            size: Size.infinite,
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '흡수 열량 (Qh)' : 'Heat Input (Qh)',
                  value: heatIn,
                  min: 500,
                  max: 2000,
                  defaultValue: 1000,
                  formatValue: (v) => '${v.toStringAsFixed(0)} J',
                  onChanged: (v) => setState(() {
                    heatIn = v;
                    if (heatOut >= heatIn) heatOut = heatIn - 100;
                  }),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '방출 열량 (Qc)' : 'Heat Output (Qc)',
                    value: heatOut,
                    min: 100,
                    max: heatIn - 50,
                    defaultValue: 600,
                    formatValue: (v) => '${v.toStringAsFixed(0)} J',
                    onChanged: (v) => setState(() => heatOut = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _EfficiencyDisplay(
                heatIn: heatIn,
                heatOut: heatOut,
                workOutput: workOutput,
                efficiency: efficiency,
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
                    : (isKorean ? '엔진 가동' : 'Start Engine'),
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

class _EfficiencyDisplay extends StatelessWidget {
  final double heatIn;
  final double heatOut;
  final double workOutput;
  final double efficiency;
  final bool isKorean;

  const _EfficiencyDisplay({
    required this.heatIn,
    required this.heatOut,
    required this.workOutput,
    required this.efficiency,
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
                label: 'Qh',
                value: '${heatIn.toStringAsFixed(0)} J',
                color: Colors.red,
              ),
              _InfoItem(
                label: 'Qc',
                value: '${heatOut.toStringAsFixed(0)} J',
                color: Colors.blue,
              ),
              _InfoItem(
                label: 'W',
                value: '${workOutput.toStringAsFixed(0)} J',
                color: AppColors.accent2,
              ),
              _InfoItem(
                label: 'η',
                value: '${efficiency.toStringAsFixed(1)}%',
                color: AppColors.accent,
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
              'η = ${workOutput.toStringAsFixed(0)}/${heatIn.toStringAsFixed(0)} = ${efficiency.toStringAsFixed(1)}%',
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

class _HeatEnginePainter extends CustomPainter {
  final double heatIn;
  final double heatOut;
  final double workOutput;
  final double efficiency;
  final double pistonPosition;
  final bool isRunning;
  final bool isKorean;

  _HeatEnginePainter({
    required this.heatIn,
    required this.heatOut,
    required this.workOutput,
    required this.efficiency,
    required this.pistonPosition,
    required this.isRunning,
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

    // Draw hot reservoir
    _drawReservoir(canvas, Offset(centerX - 80, 40), true);

    // Draw cold reservoir
    _drawReservoir(canvas, Offset(centerX - 80, size.height - 80), false);

    // Draw engine
    _drawEngine(canvas, Offset(centerX - 80, size.height / 2 - 20));

    // Draw energy flow diagram
    _drawEnergyFlow(canvas, size);

    // Draw efficiency bar
    _drawEfficiencyBar(canvas, Offset(size.width - 60, 50), size.height * 0.4);

    // Labels
    _drawText(canvas, isKorean ? '열기관 에너지 흐름' : 'Heat Engine Energy Flow',
        Offset(20, 15), AppColors.ink, 12);
  }

  void _drawReservoir(Canvas canvas, Offset center, bool isHot) {
    final color = isHot ? Colors.red : Colors.blue;
    final label = isHot
        ? (isKorean ? '고온부 (Th)' : 'Hot Reservoir')
        : (isKorean ? '저온부 (Tc)' : 'Cold Reservoir');

    // Reservoir box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 120, height: 50),
        const Radius.circular(10),
      ),
      Paint()..color = color.withValues(alpha: 0.2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 120, height: 50),
        const Radius.circular(10),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _drawText(canvas, label, Offset(center.dx - 40, center.dy - 8), color, 10);
  }

  void _drawEngine(Canvas canvas, Offset center) {
    // Engine body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 80, height: 60),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.muted.withValues(alpha: 0.3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 80, height: 60),
        const Radius.circular(8),
      ),
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Piston animation
    if (isRunning) {
      final pistonOffset = math.sin(pistonPosition) * 10;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + pistonOffset),
          width: 50,
          height: 15,
        ),
        Paint()..color = AppColors.accent,
      );
    }

    _drawText(canvas, isKorean ? '엔진' : 'Engine', Offset(center.dx - 15, center.dy - 8), AppColors.ink, 10);

    // Work output arrow
    final workArrowStart = Offset(center.dx + 45, center.dy);
    final workArrowEnd = Offset(center.dx + 90, center.dy);

    canvas.drawLine(
      workArrowStart,
      workArrowEnd,
      Paint()
        ..color = AppColors.accent2
        ..strokeWidth = 3,
    );

    // Arrow head
    final arrowPath = Path()
      ..moveTo(workArrowEnd.dx, workArrowEnd.dy)
      ..lineTo(workArrowEnd.dx - 10, workArrowEnd.dy - 5)
      ..lineTo(workArrowEnd.dx - 10, workArrowEnd.dy + 5)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = AppColors.accent2);

    _drawText(canvas, 'W = ${workOutput.toStringAsFixed(0)} J',
        Offset(workArrowEnd.dx + 5, workArrowEnd.dy - 15), AppColors.accent2, 10);
  }

  void _drawEnergyFlow(Canvas canvas, Size size) {
    final centerX = size.width / 2 - 80;
    final hotY = 70.0;
    final engineY = size.height / 2 - 20;
    final coldY = size.height - 75;

    // Qh arrow (hot to engine)
    _drawFlowArrow(canvas, Offset(centerX, hotY + 30), Offset(centerX, engineY - 35),
        Colors.red, 'Qh = ${heatIn.toStringAsFixed(0)} J', isKorean);

    // Qc arrow (engine to cold)
    _drawFlowArrow(canvas, Offset(centerX, engineY + 35), Offset(centerX, coldY - 30),
        Colors.blue, 'Qc = ${heatOut.toStringAsFixed(0)} J', isKorean);
  }

  void _drawFlowArrow(Canvas canvas, Offset start, Offset end, Color color, String label, bool isKorean) {
    // Animated particles
    if (isRunning) {
      for (int i = 0; i < 3; i++) {
        final t = (pistonPosition / (2 * math.pi) + i * 0.33) % 1.0;
        final x = start.dx + (end.dx - start.dx) * t;
        final y = start.dy + (end.dy - start.dy) * t;
        canvas.drawCircle(
          Offset(x, y),
          4,
          Paint()..color = color.withValues(alpha: 1 - t),
        );
      }
    }

    // Arrow line
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = 3,
    );

    // Arrow head
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 10 * math.cos(angle - 0.4), end.dy - 10 * math.sin(angle - 0.4))
      ..lineTo(end.dx - 10 * math.cos(angle + 0.4), end.dy - 10 * math.sin(angle + 0.4))
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = color);

    // Label
    _drawText(canvas, label, Offset(start.dx + 10, (start.dy + end.dy) / 2 - 8), color, 9);
  }

  void _drawEfficiencyBar(Canvas canvas, Offset position, double height) {
    final barWidth = 25.0;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx, position.dy, barWidth, height),
        const Radius.circular(5),
      ),
      Paint()..color = AppColors.cardBorder,
    );

    // Fill
    final fillHeight = height * (efficiency / 100);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx + 3, position.dy + height - fillHeight + 3, barWidth - 6, fillHeight - 6),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.accent,
    );

    // Label
    _drawText(canvas, 'η', Offset(position.dx + 5, position.dy - 18), AppColors.ink, 12);
    _drawText(canvas, '${efficiency.toStringAsFixed(1)}%',
        Offset(position.dx - 10, position.dy + height + 5), AppColors.accent, 10);
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
  bool shouldRepaint(covariant _HeatEnginePainter oldDelegate) => true;
}
