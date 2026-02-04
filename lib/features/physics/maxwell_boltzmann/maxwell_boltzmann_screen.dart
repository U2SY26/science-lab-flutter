import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Maxwell-Boltzmann Distribution simulation
class MaxwellBoltzmannScreen extends StatefulWidget {
  const MaxwellBoltzmannScreen({super.key});

  @override
  State<MaxwellBoltzmannScreen> createState() => _MaxwellBoltzmannScreenState();
}

class _MaxwellBoltzmannScreenState extends State<MaxwellBoltzmannScreen> {
  double temperature = 300.0; // K
  double molarMass = 28.0; // g/mol (N2)
  bool isKorean = true;

  double get mostProbableSpeed => math.sqrt(2 * 8.314 * temperature / (molarMass / 1000));
  double get meanSpeed => math.sqrt(8 * 8.314 * temperature / (math.pi * molarMass / 1000));
  double get rmsSpeed => math.sqrt(3 * 8.314 * temperature / (molarMass / 1000));

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
            Text(isKorean ? '열역학' : 'THERMODYNAMICS',
              style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
            Text(isKorean ? '맥스웰-볼츠만 분포' : 'Maxwell-Boltzmann Distribution',
              style: const TextStyle(color: AppColors.ink, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)),
            onPressed: () => setState(() => isKorean = !isKorean),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '열역학' : 'Thermodynamics',
          title: isKorean ? '맥스웰-볼츠만 분포' : 'Maxwell-Boltzmann Distribution',
          formula: 'f(v) = 4π(m/2πkT)^(3/2) v² e^(-mv²/2kT)',
          formulaDescription: isKorean
              ? '기체 분자의 속력 분포를 나타냅니다. 온도가 높을수록 분포가 넓어집니다.'
              : 'Describes the distribution of molecular speeds in a gas. Higher temperature broadens the distribution.',
          simulation: CustomPaint(
            painter: _MaxwellBoltzmannPainter(
              temperature: temperature,
              molarMass: molarMass,
              mostProbableSpeed: mostProbableSpeed,
              meanSpeed: meanSpeed,
              rmsSpeed: rmsSpeed,
              isKorean: isKorean,
            ),
            size: Size.infinite,
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PresetGroup(
                label: isKorean ? '기체 선택' : 'Gas Selection',
                presets: [
                  PresetButton(label: 'H₂ (2)', isSelected: molarMass == 2, onPressed: () => setState(() => molarMass = 2)),
                  PresetButton(label: 'N₂ (28)', isSelected: molarMass == 28, onPressed: () => setState(() => molarMass = 28)),
                  PresetButton(label: 'O₂ (32)', isSelected: molarMass == 32, onPressed: () => setState(() => molarMass = 32)),
                  PresetButton(label: 'CO₂ (44)', isSelected: molarMass == 44, onPressed: () => setState(() => molarMass = 44)),
                ],
              ),
              const SizedBox(height: 16),
              SimSlider(
                label: isKorean ? '온도 (T)' : 'Temperature (T)',
                value: temperature, min: 100, max: 1000, defaultValue: 300,
                formatValue: (v) => '${v.toStringAsFixed(0)} K',
                onChanged: (v) => setState(() => temperature = v),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
                child: Row(
                  children: [
                    Expanded(child: Column(children: [
                      Text(isKorean ? '최빈속력' : 'Most Probable', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                      Text('${mostProbableSpeed.toStringAsFixed(0)} m/s', style: const TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'monospace')),
                    ])),
                    Expanded(child: Column(children: [
                      Text(isKorean ? '평균속력' : 'Mean Speed', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                      Text('${meanSpeed.toStringAsFixed(0)} m/s', style: const TextStyle(color: Colors.orange, fontSize: 11, fontFamily: 'monospace')),
                    ])),
                    Expanded(child: Column(children: [
                      Text(isKorean ? 'RMS 속력' : 'RMS Speed', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                      Text('${rmsSpeed.toStringAsFixed(0)} m/s', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace')),
                    ])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaxwellBoltzmannPainter extends CustomPainter {
  final double temperature;
  final double molarMass;
  final double mostProbableSpeed;
  final double meanSpeed;
  final double rmsSpeed;
  final bool isKorean;

  _MaxwellBoltzmannPainter({required this.temperature, required this.molarMass, required this.mostProbableSpeed, required this.meanSpeed, required this.rmsSpeed, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final graphX = 50.0;
    final graphY = 30.0;
    final graphWidth = size.width - 80;
    final graphHeight = size.height - 100;

    // Axes
    canvas.drawLine(Offset(graphX, graphY + graphHeight), Offset(graphX + graphWidth, graphY + graphHeight), Paint()..color = AppColors.muted..strokeWidth = 2);
    canvas.drawLine(Offset(graphX, graphY), Offset(graphX, graphY + graphHeight), Paint()..color = AppColors.muted..strokeWidth = 2);

    _drawText(canvas, 'v (m/s)', Offset(graphX + graphWidth - 40, graphY + graphHeight + 10), AppColors.muted, 10);
    _drawText(canvas, 'f(v)', Offset(graphX - 25, graphY - 5), AppColors.muted, 10);

    // Draw distribution curve
    final m = molarMass / 1000;
    const k = 1.38e-23;
    final T = temperature;
    final maxV = rmsSpeed * 2.5;

    final path = Path();
    double maxF = 0;

    // First pass to find max
    for (double v = 0; v <= maxV; v += maxV / 100) {
      final f = 4 * math.pi * math.pow(m / (2 * math.pi * k * T), 1.5) * v * v * math.exp(-m * v * v / (2 * k * T));
      if (f > maxF) maxF = f;
    }

    // Draw curve
    bool started = false;
    for (double v = 0; v <= maxV; v += maxV / 200) {
      final f = 4 * math.pi * math.pow(m / (2 * math.pi * k * T), 1.5) * v * v * math.exp(-m * v * v / (2 * k * T));
      final x = graphX + (v / maxV) * graphWidth;
      final y = graphY + graphHeight - (f / maxF) * graphHeight * 0.9;
      if (!started) { path.moveTo(x, y); started = true; } else { path.lineTo(x, y); }
    }

    canvas.drawPath(path, Paint()..color = AppColors.accent..style = PaintingStyle.stroke..strokeWidth = 3);

    // Mark speeds
    final speeds = [mostProbableSpeed, meanSpeed, rmsSpeed];
    final colors = [Colors.green, Colors.orange, AppColors.accent];
    final labels = ['vp', 'v̄', 'vrms'];

    for (int i = 0; i < 3; i++) {
      final x = graphX + (speeds[i] / maxV) * graphWidth;
      canvas.drawLine(Offset(x, graphY), Offset(x, graphY + graphHeight), Paint()..color = colors[i].withValues(alpha: 0.5)..strokeWidth = 1);
      _drawText(canvas, labels[i], Offset(x - 10, graphY + graphHeight + 5), colors[i], 10);
    }

    // Legend
    _drawText(canvas, isKorean ? '온도: ${temperature.toStringAsFixed(0)}K, 분자량: ${molarMass.toStringAsFixed(0)} g/mol' : 'T: ${temperature.toStringAsFixed(0)}K, M: ${molarMass.toStringAsFixed(0)} g/mol', Offset(graphX + 10, graphY + 10), AppColors.ink, 11);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _MaxwellBoltzmannPainter oldDelegate) => true;
}
