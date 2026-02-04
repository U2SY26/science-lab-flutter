import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Carnot Cycle simulation: η = 1 - Tc/Th
class CarnotCycleScreen extends StatefulWidget {
  const CarnotCycleScreen({super.key});

  @override
  State<CarnotCycleScreen> createState() => _CarnotCycleScreenState();
}

class _CarnotCycleScreenState extends State<CarnotCycleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  double hotTemp = 600.0; // Th (K)
  double coldTemp = 300.0; // Tc (K)
  int currentStage = 0; // 0-3 for four stages
  double animProgress = 0.0;

  bool isRunning = false;
  bool isKorean = true;

  final List<String> stageNames = [
    'Isothermal Expansion',
    'Adiabatic Expansion',
    'Isothermal Compression',
    'Adiabatic Compression',
  ];
  final List<String> stageNamesKr = [
    '등온 팽창',
    '단열 팽창',
    '등온 압축',
    '단열 압축',
  ];

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
      animProgress += 0.008;
      if (animProgress >= 1.0) {
        animProgress = 0.0;
        currentStage = (currentStage + 1) % 4;
      }
    });
  }

  double get efficiency => 1 - coldTemp / hotTemp;
  double get carnotEfficiency => efficiency * 100;

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      currentStage = 0;
      animProgress = 0;
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
              isKorean ? '카르노 사이클' : 'Carnot Cycle',
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
          title: isKorean ? '카르노 사이클' : 'Carnot Cycle',
          formula: 'η = 1 - Tc/Th',
          formulaDescription: isKorean
              ? '카르노 효율은 이상적인 열기관의 최대 효율입니다. Th는 고온부, Tc는 저온부 온도입니다.'
              : 'Carnot efficiency is the maximum efficiency of an ideal heat engine. Th is hot reservoir, Tc is cold reservoir temperature.',
          simulation: CustomPaint(
            painter: _CarnotCyclePainter(
              hotTemp: hotTemp,
              coldTemp: coldTemp,
              currentStage: currentStage,
              animProgress: animProgress,
              efficiency: efficiency,
              isKorean: isKorean,
            ),
            size: Size.infinite,
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current stage indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStageIcon(currentStage),
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isKorean ? stageNamesKr[currentStage] : stageNames[currentStage],
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '고온부 온도 (Th)' : 'Hot Reservoir (Th)',
                  value: hotTemp,
                  min: 400,
                  max: 1000,
                  defaultValue: 600,
                  formatValue: (v) => '${v.toStringAsFixed(0)} K',
                  onChanged: (v) => setState(() {
                    hotTemp = v;
                    if (hotTemp <= coldTemp) coldTemp = hotTemp - 50;
                  }),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '저온부 온도 (Tc)' : 'Cold Reservoir (Tc)',
                    value: coldTemp,
                    min: 200,
                    max: hotTemp - 50,
                    defaultValue: 300,
                    formatValue: (v) => '${v.toStringAsFixed(0)} K',
                    onChanged: (v) => setState(() => coldTemp = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _EfficiencyDisplay(
                hotTemp: hotTemp,
                coldTemp: coldTemp,
                efficiency: carnotEfficiency,
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
                    : (isKorean ? '사이클 시작' : 'Start Cycle'),
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

  IconData _getStageIcon(int stage) {
    switch (stage) {
      case 0:
        return Icons.expand;
      case 1:
        return Icons.trending_down;
      case 2:
        return Icons.compress;
      case 3:
        return Icons.trending_up;
      default:
        return Icons.loop;
    }
  }
}

class _EfficiencyDisplay extends StatelessWidget {
  final double hotTemp;
  final double coldTemp;
  final double efficiency;
  final bool isKorean;

  const _EfficiencyDisplay({
    required this.hotTemp,
    required this.coldTemp,
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
                label: 'Th',
                value: '${hotTemp.toStringAsFixed(0)} K',
                color: Colors.red,
              ),
              _InfoItem(
                label: 'Tc',
                value: '${coldTemp.toStringAsFixed(0)} K',
                color: Colors.blue,
              ),
              _InfoItem(
                label: isKorean ? '효율 (η)' : 'Efficiency (η)',
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
              'η = 1 - ${coldTemp.toStringAsFixed(0)}/${hotTemp.toStringAsFixed(0)} = ${(efficiency).toStringAsFixed(1)}%',
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

class _CarnotCyclePainter extends CustomPainter {
  final double hotTemp;
  final double coldTemp;
  final int currentStage;
  final double animProgress;
  final double efficiency;
  final bool isKorean;

  _CarnotCyclePainter({
    required this.hotTemp,
    required this.coldTemp,
    required this.currentStage,
    required this.animProgress,
    required this.efficiency,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    // PV diagram
    _drawPVDiagram(canvas, size);

    // Heat reservoirs
    _drawReservoirs(canvas, size);

    // Stage description
    _drawStageInfo(canvas, size);
  }

  void _drawPVDiagram(Canvas canvas, Size size) {
    final graphX = 30.0;
    final graphY = 30.0;
    final graphWidth = size.width * 0.45;
    final graphHeight = size.height * 0.6;

    // Axes
    canvas.drawLine(
      Offset(graphX, graphY + graphHeight),
      Offset(graphX + graphWidth, graphY + graphHeight),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(graphX, graphY),
      Offset(graphX, graphY + graphHeight),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 2,
    );

    // Labels
    _drawText(canvas, 'V', Offset(graphX + graphWidth + 5, graphY + graphHeight - 10), AppColors.muted, 12);
    _drawText(canvas, 'P', Offset(graphX - 5, graphY - 15), AppColors.muted, 12);

    // Carnot cycle path points (simplified)
    final points = <Offset>[
      Offset(graphX + 40, graphY + 30), // A (high P, low V)
      Offset(graphX + graphWidth - 60, graphY + 60), // B (lower P, higher V)
      Offset(graphX + graphWidth - 30, graphY + graphHeight - 40), // C (low P, high V)
      Offset(graphX + 70, graphY + graphHeight - 70), // D (higher P, lower V)
    ];

    // Draw cycle path segments
    // Isothermal expansion (A->B) - curve
    _drawIsotherm(canvas, points[0], points[1], Colors.red.withValues(alpha: 0.7), currentStage == 0);

    // Adiabatic expansion (B->C) - steeper curve
    _drawAdiabat(canvas, points[1], points[2], AppColors.accent.withValues(alpha: 0.7), currentStage == 1);

    // Isothermal compression (C->D) - curve
    _drawIsotherm(canvas, points[2], points[3], Colors.blue.withValues(alpha: 0.7), currentStage == 2);

    // Adiabatic compression (D->A) - steeper curve
    _drawAdiabat(canvas, points[3], points[0], AppColors.accent2.withValues(alpha: 0.7), currentStage == 3);

    // Draw points
    for (int i = 0; i < points.length; i++) {
      final isActive = i == currentStage || (i + 1) % 4 == currentStage;
      canvas.drawCircle(
        points[i],
        isActive ? 8 : 5,
        Paint()..color = isActive ? AppColors.accent : AppColors.muted,
      );
      _drawText(canvas, String.fromCharCode(65 + i), points[i].translate(8, -12), AppColors.ink, 11);
    }

    // Current position indicator
    final startPoint = points[currentStage];
    final endPoint = points[(currentStage + 1) % 4];
    final currentX = startPoint.dx + (endPoint.dx - startPoint.dx) * animProgress;
    final currentY = startPoint.dy + (endPoint.dy - startPoint.dy) * animProgress;

    canvas.drawCircle(
      Offset(currentX, currentY),
      6,
      Paint()..color = AppColors.accent2,
    );

    // Legend
    final legendY = graphY + graphHeight + 20;
    _drawLegendItem(canvas, Offset(graphX, legendY), Colors.red, isKorean ? '등온' : 'Isothermal');
    _drawLegendItem(canvas, Offset(graphX + 80, legendY), AppColors.accent, isKorean ? '단열' : 'Adiabatic');
  }

  void _drawIsotherm(Canvas canvas, Offset start, Offset end, Color color, bool highlight) {
    final path = Path()..moveTo(start.dx, start.dy);

    // Curved path for isotherm (hyperbola-like)
    for (double t = 0; t <= 1; t += 0.05) {
      final x = start.dx + (end.dx - start.dx) * t;
      final curveOffset = math.sin(t * math.pi) * 20;
      final y = start.dy + (end.dy - start.dy) * t - curveOffset;
      path.lineTo(x, y);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight ? 4 : 2,
    );
  }

  void _drawAdiabat(Canvas canvas, Offset start, Offset end, Color color, bool highlight) {
    final path = Path()..moveTo(start.dx, start.dy);

    // Steeper curve for adiabat
    for (double t = 0; t <= 1; t += 0.05) {
      final x = start.dx + (end.dx - start.dx) * t;
      final curveOffset = math.sin(t * math.pi) * 10;
      final y = start.dy + (end.dy - start.dy) * t + curveOffset;
      path.lineTo(x, y);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight ? 4 : 2,
    );
  }

  void _drawReservoirs(Canvas canvas, Size size) {
    final reservoirX = size.width * 0.65;
    final hotY = 50.0;
    final coldY = size.height * 0.5;
    final engineY = (hotY + coldY) / 2 + 30;

    // Hot reservoir
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(reservoirX, hotY), width: 100, height: 40),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.red.withValues(alpha: 0.3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(reservoirX, hotY), width: 100, height: 40),
        const Radius.circular(8),
      ),
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _drawText(canvas, 'Th = ${hotTemp.toStringAsFixed(0)}K', Offset(reservoirX - 35, hotY - 8), Colors.red, 11);

    // Cold reservoir
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(reservoirX, coldY), width: 100, height: 40),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.blue.withValues(alpha: 0.3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(reservoirX, coldY), width: 100, height: 40),
        const Radius.circular(8),
      ),
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _drawText(canvas, 'Tc = ${coldTemp.toStringAsFixed(0)}K', Offset(reservoirX - 35, coldY - 8), Colors.blue, 11);

    // Engine
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(reservoirX, engineY), width: 60, height: 50),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.accent.withValues(alpha: 0.3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(reservoirX, engineY), width: 60, height: 50),
        const Radius.circular(8),
      ),
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _drawText(canvas, isKorean ? '엔진' : 'Engine', Offset(reservoirX - 15, engineY - 8), AppColors.accent, 10);

    // Heat flow arrows
    if (currentStage == 0) {
      // Qh in
      _drawArrow(canvas, Offset(reservoirX, hotY + 25), Offset(reservoirX, engineY - 30), Colors.red);
      _drawText(canvas, 'Qh', Offset(reservoirX + 10, (hotY + engineY) / 2 - 10), Colors.red, 10);
    } else if (currentStage == 2) {
      // Qc out
      _drawArrow(canvas, Offset(reservoirX, engineY + 30), Offset(reservoirX, coldY - 25), Colors.blue);
      _drawText(canvas, 'Qc', Offset(reservoirX + 10, (engineY + coldY) / 2), Colors.blue, 10);
    }

    // Work output
    if (currentStage == 0 || currentStage == 1) {
      _drawArrow(canvas, Offset(reservoirX + 35, engineY), Offset(reservoirX + 70, engineY), AppColors.accent2);
      _drawText(canvas, 'W', Offset(reservoirX + 55, engineY - 15), AppColors.accent2, 10);
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 10 * math.cos(angle - 0.4), end.dy - 10 * math.sin(angle - 0.4))
      ..lineTo(end.dx - 10 * math.cos(angle + 0.4), end.dy - 10 * math.sin(angle + 0.4))
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = color);
  }

  void _drawStageInfo(Canvas canvas, Size size) {
    final stageDescriptions = isKorean
        ? ['A→B: 열 흡수, 등온 팽창', 'B→C: 단열 팽창, 온도 하강', 'C→D: 열 방출, 등온 압축', 'D→A: 단열 압축, 온도 상승']
        : ['A→B: Heat in, isothermal expansion', 'B→C: Adiabatic expansion, temp drops', 'C→D: Heat out, isothermal compression', 'D→A: Adiabatic compression, temp rises'];

    final infoY = size.height - 35;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, infoY - 5, size.width - 40, 30),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.card.withValues(alpha: 0.8),
    );
    _drawText(canvas, stageDescriptions[currentStage], Offset(30, infoY), AppColors.ink, 11);
  }

  void _drawLegendItem(Canvas canvas, Offset position, Color color, String text) {
    canvas.drawLine(
      position,
      Offset(position.dx + 20, position.dy),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );
    _drawText(canvas, text, Offset(position.dx + 25, position.dy - 6), color, 9);
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
  bool shouldRepaint(covariant _CarnotCyclePainter oldDelegate) => true;
}
