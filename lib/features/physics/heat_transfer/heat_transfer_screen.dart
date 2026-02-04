import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Heat Transfer simulation: Q = mcΔT
class HeatTransferScreen extends StatefulWidget {
  const HeatTransferScreen({super.key});

  @override
  State<HeatTransferScreen> createState() => _HeatTransferScreenState();
}

class _HeatTransferScreenState extends State<HeatTransferScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  double mass = 1.0; // kg
  double specificHeat = 4186.0; // J/(kg·K) - water
  double initialTemp = 20.0; // °C
  double finalTemp = 80.0; // °C
  double currentTemp = 20.0;
  double heatAdded = 0.0;

  int materialIndex = 0;
  final List<String> materials = ['Water', 'Iron', 'Aluminum', 'Copper'];
  final List<String> materialsKr = ['물', '철', '알루미늄', '구리'];
  final List<double> specificHeats = [4186, 449, 897, 385]; // J/(kg·K)

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
      if (currentTemp < finalTemp) {
        final tempIncrease = 0.5; // Rate of heating
        currentTemp += tempIncrease;
        heatAdded = mass * specificHeat * (currentTemp - initialTemp);

        if (currentTemp >= finalTemp) {
          currentTemp = finalTemp;
          isRunning = false;
        }
      }
    });
  }

  double get totalHeat => mass * specificHeat * (finalTemp - initialTemp);

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      currentTemp = initialTemp;
      heatAdded = 0;
      isRunning = false;
    });
  }

  void _toggleSimulation() {
    HapticFeedback.selectionClick();
    setState(() {
      if (currentTemp >= finalTemp) {
        currentTemp = initialTemp;
        heatAdded = 0;
      }
      isRunning = !isRunning;
    });
  }

  void _setMaterial(int index) {
    setState(() {
      materialIndex = index;
      specificHeat = specificHeats[index];
      _reset();
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
              isKorean ? '열역학' : 'THERMODYNAMICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '열전달' : 'Heat Transfer',
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
          title: isKorean ? '열전달' : 'Heat Transfer',
          formula: 'Q = mcΔT',
          formulaDescription: isKorean
              ? '열량(Q)은 질량(m), 비열(c), 온도 변화(ΔT)의 곱입니다.'
              : 'Heat (Q) equals mass (m) times specific heat (c) times temperature change (ΔT).',
          simulation: CustomPaint(
            painter: _HeatTransferPainter(
              mass: mass,
              specificHeat: specificHeat,
              initialTemp: initialTemp,
              finalTemp: finalTemp,
              currentTemp: currentTemp,
              heatAdded: heatAdded,
              totalHeat: totalHeat,
              materialIndex: materialIndex,
              isKorean: isKorean,
            ),
            size: Size.infinite,
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material selection
              PresetGroup(
                label: isKorean ? '물질 선택' : 'Material',
                presets: List.generate(materials.length, (i) => PresetButton(
                  label: isKorean ? materialsKr[i] : materials[i],
                  isSelected: materialIndex == i,
                  onPressed: () => _setMaterial(i),
                )),
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '질량 (m)' : 'Mass (m)',
                  value: mass,
                  min: 0.1,
                  max: 5,
                  step: 0.1,
                  defaultValue: 1,
                  formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                  onChanged: (v) => setState(() {
                    mass = v;
                    _reset();
                  }),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '초기 온도 (T₁)' : 'Initial Temp (T₁)',
                    value: initialTemp,
                    min: 0,
                    max: 50,
                    defaultValue: 20,
                    formatValue: (v) => '${v.toStringAsFixed(0)} °C',
                    onChanged: (v) => setState(() {
                      initialTemp = v;
                      if (finalTemp <= initialTemp) finalTemp = initialTemp + 10;
                      _reset();
                    }),
                  ),
                  SimSlider(
                    label: isKorean ? '최종 온도 (T₂)' : 'Final Temp (T₂)',
                    value: finalTemp,
                    min: initialTemp + 10,
                    max: 100,
                    defaultValue: 80,
                    formatValue: (v) => '${v.toStringAsFixed(0)} °C',
                    onChanged: (v) => setState(() {
                      finalTemp = v;
                      _reset();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _HeatDisplay(
                mass: mass,
                specificHeat: specificHeat,
                deltaT: finalTemp - initialTemp,
                currentTemp: currentTemp,
                heatAdded: heatAdded,
                totalHeat: totalHeat,
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
                    : (isKorean ? '가열 시작' : 'Start Heating'),
                icon: isRunning ? Icons.pause : Icons.local_fire_department,
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

class _HeatDisplay extends StatelessWidget {
  final double mass;
  final double specificHeat;
  final double deltaT;
  final double currentTemp;
  final double heatAdded;
  final double totalHeat;
  final bool isKorean;

  const _HeatDisplay({
    required this.mass,
    required this.specificHeat,
    required this.deltaT,
    required this.currentTemp,
    required this.heatAdded,
    required this.totalHeat,
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
                label: isKorean ? '비열 (c)' : 'Specific Heat',
                value: '${specificHeat.toStringAsFixed(0)} J/kg·K',
                color: AppColors.muted,
              ),
              _InfoItem(
                label: isKorean ? '현재 온도' : 'Current Temp',
                value: '${currentTemp.toStringAsFixed(1)} °C',
                color: _getTemperatureColor(currentTemp),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(
                label: isKorean ? '가한 열량' : 'Heat Added',
                value: '${(heatAdded / 1000).toStringAsFixed(1)} kJ',
                color: AppColors.accent2,
              ),
              _InfoItem(
                label: isKorean ? '필요 열량' : 'Total Heat',
                value: '${(totalHeat / 1000).toStringAsFixed(1)} kJ',
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
              'Q = ${mass.toStringAsFixed(1)} × ${specificHeat.toStringAsFixed(0)} × ${deltaT.toStringAsFixed(0)} = ${(totalHeat / 1000).toStringAsFixed(1)} kJ',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 30) return Colors.blue;
    if (temp < 50) return Colors.orange;
    return Colors.red;
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

class _HeatTransferPainter extends CustomPainter {
  final double mass;
  final double specificHeat;
  final double initialTemp;
  final double finalTemp;
  final double currentTemp;
  final double heatAdded;
  final double totalHeat;
  final int materialIndex;
  final bool isKorean;

  _HeatTransferPainter({
    required this.mass,
    required this.specificHeat,
    required this.initialTemp,
    required this.finalTemp,
    required this.currentTemp,
    required this.heatAdded,
    required this.totalHeat,
    required this.materialIndex,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    // Draw beaker/container
    _drawContainer(canvas, size);

    // Draw thermometer
    _drawThermometer(canvas, Offset(size.width - 70, 40), size.height * 0.5);

    // Draw heat source
    _drawHeatSource(canvas, size);

    // Draw specific heat comparison
    _drawSpecificHeatComparison(canvas, size);
  }

  void _drawContainer(Canvas canvas, Size size) {
    final centerX = size.width / 2 - 30;
    final containerY = 60.0;
    final containerWidth = 120.0;
    final containerHeight = size.height * 0.45;

    // Beaker outline
    final beakerPath = Path()
      ..moveTo(centerX - containerWidth / 2, containerY)
      ..lineTo(centerX - containerWidth / 2 + 10, containerY + containerHeight)
      ..lineTo(centerX + containerWidth / 2 - 10, containerY + containerHeight)
      ..lineTo(centerX + containerWidth / 2, containerY);

    canvas.drawPath(
      beakerPath,
      Paint()
        ..color = AppColors.cardBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Liquid fill (color based on temperature)
    final fillColor = _getTemperatureColor(currentTemp);
    final fillHeight = containerHeight * 0.8;

    final liquidPath = Path()
      ..moveTo(centerX - containerWidth / 2 + 5, containerY + containerHeight - fillHeight)
      ..lineTo(centerX - containerWidth / 2 + 12, containerY + containerHeight - 5)
      ..lineTo(centerX + containerWidth / 2 - 12, containerY + containerHeight - 5)
      ..lineTo(centerX + containerWidth / 2 - 5, containerY + containerHeight - fillHeight)
      ..close();

    canvas.drawPath(liquidPath, Paint()..color = fillColor.withValues(alpha: 0.4));

    // Bubbles if heating
    if (currentTemp > initialTemp + 5) {
      final random = math.Random(42);
      final bubbleCount = ((currentTemp - initialTemp) / 10).clamp(0, 10).toInt();
      for (int i = 0; i < bubbleCount; i++) {
        final bubbleX = centerX - 40 + random.nextDouble() * 80;
        final bubbleY = containerY + containerHeight - 30 - random.nextDouble() * (fillHeight - 40);
        canvas.drawCircle(
          Offset(bubbleX, bubbleY),
          2 + random.nextDouble() * 3,
          Paint()..color = Colors.white.withValues(alpha: 0.5),
        );
      }
    }

    // Temperature label on container
    _drawText(
      canvas,
      '${currentTemp.toStringAsFixed(1)}°C',
      Offset(centerX - 25, containerY + containerHeight / 2),
      AppColors.ink,
      14,
    );

    // Mass label
    _drawText(
      canvas,
      'm = ${mass.toStringAsFixed(1)} kg',
      Offset(centerX - 30, containerY + containerHeight + 10),
      AppColors.muted,
      10,
    );
  }

  void _drawThermometer(Canvas canvas, Offset position, double height) {
    final barWidth = 20.0;
    final normalizedTemp = ((currentTemp - 0) / 100).clamp(0.0, 1.0);
    final fillHeight = height * normalizedTemp;

    // Thermometer background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx, position.dy, barWidth, height),
        const Radius.circular(10),
      ),
      Paint()..color = AppColors.cardBorder,
    );

    // Mercury/fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx + 3, position.dy + height - fillHeight + 3, barWidth - 6, fillHeight - 6),
        const Radius.circular(7),
      ),
      Paint()..color = _getTemperatureColor(currentTemp),
    );

    // Bulb at bottom
    canvas.drawCircle(
      Offset(position.dx + barWidth / 2, position.dy + height + 10),
      15,
      Paint()..color = _getTemperatureColor(currentTemp),
    );

    // Scale markers
    for (int t = 0; t <= 100; t += 20) {
      final y = position.dy + height - (t / 100) * height;
      canvas.drawLine(
        Offset(position.dx + barWidth, y),
        Offset(position.dx + barWidth + 5, y),
        Paint()
          ..color = AppColors.muted
          ..strokeWidth = 1,
      );
      _drawText(canvas, '$t°', Offset(position.dx + barWidth + 8, y - 5), AppColors.muted, 8);
    }
  }

  void _drawHeatSource(Canvas canvas, Size size) {
    final flameX = size.width / 2 - 30;
    final flameY = size.height * 0.65;

    // Burner base
    canvas.drawRect(
      Rect.fromCenter(center: Offset(flameX, flameY + 20), width: 80, height: 10),
      Paint()..color = AppColors.muted,
    );

    // Flames (animated-looking)
    if (currentTemp < finalTemp) {
      for (int i = 0; i < 5; i++) {
        final offsetX = (i - 2) * 12.0;
        final flameHeight = 20.0 + math.sin(i * 0.5) * 5;

        final flamePath = Path()
          ..moveTo(flameX + offsetX - 5, flameY + 15)
          ..quadraticBezierTo(
            flameX + offsetX - 3,
            flameY + 15 - flameHeight / 2,
            flameX + offsetX,
            flameY + 15 - flameHeight,
          )
          ..quadraticBezierTo(
            flameX + offsetX + 3,
            flameY + 15 - flameHeight / 2,
            flameX + offsetX + 5,
            flameY + 15,
          )
          ..close();

        canvas.drawPath(
          flamePath,
          Paint()..color = Colors.orange.withValues(alpha: 0.8),
        );
      }

      _drawText(canvas, 'Q', Offset(flameX - 5, flameY + 35), Colors.orange, 12);
    }
  }

  void _drawSpecificHeatComparison(Canvas canvas, Size size) {
    final startX = 20.0;
    final startY = size.height - 70;
    final barWidth = (size.width - 100) / 4;

    final materials = ['Water', 'Fe', 'Al', 'Cu'];
    final specificHeats = [4186.0, 449.0, 897.0, 385.0];
    final maxC = 4186.0;

    _drawText(canvas, isKorean ? '비열 비교' : 'Specific Heat Comparison',
        Offset(startX, startY - 20), AppColors.muted, 10);

    for (int i = 0; i < 4; i++) {
      final x = startX + i * barWidth;
      final barHeight = (specificHeats[i] / maxC) * 40;

      // Bar
      canvas.drawRect(
        Rect.fromLTWH(x, startY + 40 - barHeight, barWidth - 10, barHeight),
        Paint()..color = i == materialIndex ? AppColors.accent : AppColors.muted.withValues(alpha: 0.5),
      );

      // Label
      _drawText(canvas, materials[i], Offset(x, startY + 45), AppColors.muted, 9);
    }
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 30) return Colors.blue;
    if (temp < 50) return Colors.cyan;
    if (temp < 70) return Colors.orange;
    return Colors.red;
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
  bool shouldRepaint(covariant _HeatTransferPainter oldDelegate) => true;
}
