import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Heat Equation Visualization (PDE)
/// 열 방정식 시각화 (편미분방정식)
class HeatEquationScreen extends StatefulWidget {
  const HeatEquationScreen({super.key});

  @override
  State<HeatEquationScreen> createState() => _HeatEquationScreenState();
}

class _HeatEquationScreenState extends State<HeatEquationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Heat diffusion coefficient
  double alpha = 0.5;
  // Grid size
  int gridSize = 50;
  // Time step
  double dt = 0.1;
  // Simulation time
  double time = 0;

  bool isRunning = false;
  bool isKorean = true;

  // Temperature field (1D for simplicity)
  List<double> temperature = [];

  // Initial condition type
  int initialCondition = 0; // 0: spike, 1: step, 2: sine

  @override
  void initState() {
    super.initState();
    _initializeTemperature();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_simulate);
  }

  void _initializeTemperature() {
    temperature = List.generate(gridSize, (i) {
      final x = i / (gridSize - 1);
      switch (initialCondition) {
        case 0: // Spike in center
          return (i == gridSize ~/ 2) ? 1.0 : 0.0;
        case 1: // Step function
          return x < 0.5 ? 1.0 : 0.0;
        case 2: // Sine wave
          return math.sin(2 * math.pi * x);
        default:
          return 0.0;
      }
    });
    time = 0;
  }

  void _simulate() {
    if (!isRunning) return;

    setState(() {
      // Explicit finite difference method for heat equation
      // du/dt = alpha * d2u/dx2
      final dx = 1.0 / (gridSize - 1);
      final newTemp = List<double>.from(temperature);

      // Stability condition: alpha * dt / dx^2 < 0.5
      final r = alpha * dt / (dx * dx);

      for (int i = 1; i < gridSize - 1; i++) {
        newTemp[i] = temperature[i] +
            r * (temperature[i + 1] - 2 * temperature[i] + temperature[i - 1]);
      }

      // Boundary conditions: fixed at 0
      newTemp[0] = 0;
      newTemp[gridSize - 1] = 0;

      temperature = newTemp;
      time += dt;
    });

    if (isRunning) {
      _controller.forward(from: 0);
    }
  }

  void _toggleSimulation() {
    HapticFeedback.mediumImpact();
    setState(() {
      isRunning = !isRunning;
      if (isRunning) {
        _controller.forward(from: 0);
      } else {
        _controller.stop();
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      isRunning = false;
      _initializeTemperature();
    });
  }

  double get _maxTemp => temperature.reduce(math.max);
  double get _minTemp => temperature.reduce(math.min);

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
              isKorean ? '편미분방정식' : 'PDEs',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '열 방정식' : 'Heat Equation',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => isKorean = !isKorean),
            tooltip: isKorean ? 'English' : '한국어',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '편미분방정식' : 'PDEs',
          title: isKorean ? '열 방정식' : 'Heat Equation',
          formula: '∂u/∂t = α ∂²u/∂x²',
          formulaDescription: isKorean
              ? '열 방정식은 열이 물질을 통해 확산되는 방식을 설명합니다. 시간이 지남에 따라 온도 분포가 균일해집니다.'
              : 'The heat equation describes how heat diffuses through a material. Over time, the temperature distribution becomes uniform.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: HeatEquationPainter(
                temperature: temperature,
                time: time,
                alpha: alpha,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _InfoItem(
                      label: isKorean ? '시간' : 'Time',
                      value: 't = ${time.toStringAsFixed(2)}',
                      color: AppColors.accent,
                    ),
                    _InfoItem(
                      label: isKorean ? '최대 온도' : 'Max Temp',
                      value: _maxTemp.toStringAsFixed(3),
                    ),
                    _InfoItem(
                      label: isKorean ? '최소 온도' : 'Min Temp',
                      value: _minTemp.toStringAsFixed(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Initial condition
              PresetGroup(
                label: isKorean ? '초기 조건' : 'Initial Condition',
                presets: [
                  PresetButton(
                    label: isKorean ? '스파이크' : 'Spike',
                    isSelected: initialCondition == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        initialCondition = 0;
                        _initializeTemperature();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '계단' : 'Step',
                    isSelected: initialCondition == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        initialCondition = 1;
                        _initializeTemperature();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '사인파' : 'Sine',
                    isSelected: initialCondition == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        initialCondition = 2;
                        _initializeTemperature();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SimSlider(
                label: 'α (${isKorean ? '확산 계수' : 'diffusion coefficient'})',
                value: alpha,
                min: 0.1,
                max: 1.0,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => alpha = v),
              ),
              const SizedBox(height: 12),

              // Explanation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKorean ? '유한 차분법:' : 'Finite Difference Method:',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isKorean
                          ? 'u(x,t+dt) ≈ u(x,t) + α·dt/dx² · [u(x+dx) - 2u(x) + u(x-dx)]'
                          : 'u(x,t+dt) ≈ u(x,t) + α·dt/dx² · [u(x+dx) - 2u(x) + u(x-dx)]',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning
                    ? (isKorean ? '일시정지' : 'Pause')
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

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class HeatEquationPainter extends CustomPainter {
  final List<double> temperature;
  final double time;
  final double alpha;
  final bool isKorean;

  HeatEquationPainter({
    required this.temperature,
    required this.time,
    required this.alpha,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (temperature.isEmpty) return;

    final padding = 40.0;
    final graphWidth = size.width - 2 * padding;
    final graphHeight = size.height - 2 * padding - 20;
    final graphTop = padding + 10;

    // Find range for normalization
    double maxT = 1.0;
    double minT = -1.0;
    for (final t in temperature) {
      if (t > maxT) maxT = t;
      if (t < minT) minT = t;
    }
    final range = maxT - minT;

    // Draw grid
    final gridPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = graphTop + graphHeight * i / 4;
      canvas.drawLine(
        Offset(padding, y),
        Offset(padding + graphWidth, y),
        gridPaint,
      );
    }

    // Draw zero line
    if (minT <= 0 && maxT >= 0) {
      final zeroY = graphTop + graphHeight * (maxT / range);
      canvas.drawLine(
        Offset(padding, zeroY),
        Offset(padding + graphWidth, zeroY),
        Paint()
          ..color = AppColors.muted
          ..strokeWidth = 1,
      );
    }

    // Draw temperature distribution as filled gradient
    final path = Path();
    final zeroY = graphTop + graphHeight * (maxT / range);

    path.moveTo(padding, zeroY);

    for (int i = 0; i < temperature.length; i++) {
      final x = padding + graphWidth * i / (temperature.length - 1);
      final normalizedT = range > 0 ? (maxT - temperature[i]) / range : 0.5;
      final y = graphTop + graphHeight * normalizedT;

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(padding + graphWidth, zeroY);
    path.close();

    // Fill with gradient based on temperature
    canvas.drawPath(
      path,
      Paint()..color = Colors.orange.withValues(alpha: 0.3),
    );

    // Draw temperature curve
    final curvePath = Path();
    for (int i = 0; i < temperature.length; i++) {
      final x = padding + graphWidth * i / (temperature.length - 1);
      final normalizedT = range > 0 ? (maxT - temperature[i]) / range : 0.5;
      final y = graphTop + graphHeight * normalizedT;

      if (i == 0) {
        curvePath.moveTo(x, y);
      } else {
        curvePath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      curvePath,
      Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Draw heat map below
    final heatMapHeight = 20.0;
    final heatMapTop = graphTop + graphHeight + 10;

    for (int i = 0; i < temperature.length; i++) {
      final x = padding + graphWidth * i / (temperature.length - 1);
      final width = graphWidth / (temperature.length - 1) + 1;

      // Map temperature to color (blue = cold, red = hot)
      final normalizedT = range > 0 ? (temperature[i] - minT) / range : 0.5;
      final color = Color.lerp(Colors.blue, Colors.red, normalizedT)!;

      canvas.drawRect(
        Rect.fromLTWH(x - width / 2, heatMapTop, width, heatMapHeight),
        Paint()..color = color,
      );
    }

    // Draw border around heat map
    canvas.drawRect(
      Rect.fromLTWH(padding, heatMapTop, graphWidth, heatMapHeight),
      Paint()
        ..color = AppColors.cardBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Labels
    _drawText(
      canvas,
      isKorean ? '온도 분포 u(x,t)' : 'Temperature Distribution u(x,t)',
      Offset(size.width / 2, 15),
      AppColors.muted,
      fontSize: 11,
    );

    _drawText(
      canvas,
      'x = 0',
      Offset(padding, size.height - 10),
      AppColors.muted,
      fontSize: 10,
    );

    _drawText(
      canvas,
      'x = 1',
      Offset(padding + graphWidth, size.height - 10),
      AppColors.muted,
      fontSize: 10,
    );
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color,
      {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant HeatEquationPainter oldDelegate) =>
      temperature != oldDelegate.temperature || time != oldDelegate.time;
}
