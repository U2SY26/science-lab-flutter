import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Phase Diagram Simulation
class PhaseDiagramScreen extends ConsumerStatefulWidget {
  const PhaseDiagramScreen({super.key});

  @override
  ConsumerState<PhaseDiagramScreen> createState() => _PhaseDiagramScreenState();
}

class _PhaseDiagramScreenState extends ConsumerState<PhaseDiagramScreen> {
  // Selected substance
  String _substance = 'water';

  // Current point on diagram
  double _temperature = 25; // Celsius
  double _pressure = 1.0; // atm

  // Phase diagram data for different substances
  final Map<String, _PhaseData> _phaseData = {
    'water': _PhaseData(
      triplePoint: const Offset(0.01, 0.006), // T, P
      criticalPoint: const Offset(374, 218), // T, P
      normalBoilingPoint: 100,
      normalMeltingPoint: 0,
      solidLiquidSlope: -1, // Negative slope (water is special)
    ),
    'co2': _PhaseData(
      triplePoint: const Offset(-56.6, 5.11),
      criticalPoint: const Offset(31, 73),
      normalBoilingPoint: -78.5, // Sublimation at 1 atm
      normalMeltingPoint: -78.5,
      solidLiquidSlope: 1,
    ),
    'ethanol': _PhaseData(
      triplePoint: const Offset(-114, 0.00001),
      criticalPoint: const Offset(241, 63),
      normalBoilingPoint: 78.4,
      normalMeltingPoint: -114,
      solidLiquidSlope: 1,
    ),
  };

  String _getCurrentPhase() {
    final data = _phaseData[_substance]!;

    // Simplified phase determination
    if (_pressure < data.triplePoint.dy && _temperature < data.triplePoint.dx) {
      return 'solid';
    }

    if (_temperature >= data.criticalPoint.dx && _pressure >= data.criticalPoint.dy) {
      return 'supercritical';
    }

    // Approximate phase boundaries
    final meltingT = _getMeltingTemperature(_pressure);
    final boilingT = _getBoilingTemperature(_pressure);

    if (_temperature < meltingT) {
      return 'solid';
    } else if (_temperature < boilingT) {
      return 'liquid';
    } else {
      return 'gas';
    }
  }

  double _getMeltingTemperature(double pressure) {
    final data = _phaseData[_substance]!;
    // Clausius-Clapeyron approximation
    return data.normalMeltingPoint + (pressure - 1) * data.solidLiquidSlope * 0.1;
  }

  double _getBoilingTemperature(double pressure) {
    final data = _phaseData[_substance]!;
    // Clausius-Clapeyron approximation
    if (pressure <= 0) return -273;
    return data.normalBoilingPoint + 30 * math.log(pressure);
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);
    final currentPhase = _getCurrentPhase();
    final data = _phaseData[_substance]!;

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
              isKorean ? '화학' : 'CHEMISTRY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '상 다이어그램' : 'Phase Diagram',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '화학' : 'Chemistry',
          title: isKorean ? '상 다이어그램' : 'Phase Diagram',
          formula: 'dP/dT = DS/DV = DH/(T*DV)',
          formulaDescription: isKorean
              ? 'Clausius-Clapeyron 방정식은 상 경계의 기울기를 설명합니다. 온도와 압력에 따라 물질의 상이 결정됩니다.'
              : 'The Clausius-Clapeyron equation describes phase boundary slopes. Temperature and pressure determine the phase of matter.',
          simulation: GestureDetector(
            onPanUpdate: (details) {
              final box = context.findRenderObject() as RenderBox;
              final localPos = box.globalToLocal(details.globalPosition);
              final fraction = localPos.dx / box.size.width;
              final fractionY = 1 - localPos.dy / (box.size.height * 0.8);

              setState(() {
                _temperature = -100 + fraction * 500;
                _pressure = math.max(0.001, fractionY * 300);
              });
            },
            child: SizedBox(
              height: 350,
              child: CustomPaint(
                painter: _PhaseDiagramPainter(
                  substance: _substance,
                  phaseData: data,
                  currentT: _temperature,
                  currentP: _pressure,
                  currentPhase: currentPhase,
                  isKorean: isKorean,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current state info
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
                        _InfoItem(
                          label: isKorean ? '온도' : 'Temperature',
                          value: '${_temperature.toStringAsFixed(1)} C',
                          color: Colors.orange,
                        ),
                        _InfoItem(
                          label: isKorean ? '압력' : 'Pressure',
                          value: '${_pressure.toStringAsFixed(2)} atm',
                          color: Colors.blue,
                        ),
                        _InfoItem(
                          label: isKorean ? '현재 상' : 'Phase',
                          value: _getPhaseLabel(currentPhase, isKorean),
                          color: _getPhaseColor(currentPhase),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Substance selection
              PresetGroup(
                label: isKorean ? '물질' : 'Substance',
                presets: [
                  PresetButton(
                    label: isKorean ? '물 (H2O)' : 'Water (H2O)',
                    isSelected: _substance == 'water',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _substance = 'water';
                        _temperature = 25;
                        _pressure = 1;
                      });
                    },
                  ),
                  PresetButton(
                    label: 'CO2',
                    isSelected: _substance == 'co2',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _substance = 'co2';
                        _temperature = 25;
                        _pressure = 1;
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '에탄올' : 'Ethanol',
                    isSelected: _substance == 'ethanol',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _substance = 'ethanol';
                        _temperature = 25;
                        _pressure = 1;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick presets
              PresetGroup(
                label: isKorean ? '특수점' : 'Special Points',
                presets: [
                  PresetButton(
                    label: isKorean ? '삼중점' : 'Triple Point',
                    isSelected: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _temperature = data.triplePoint.dx;
                        _pressure = data.triplePoint.dy;
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '임계점' : 'Critical Point',
                    isSelected: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _temperature = data.criticalPoint.dx;
                        _pressure = data.criticalPoint.dy;
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '표준 상태' : 'Standard',
                    isSelected: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _temperature = 25;
                        _pressure = 1;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '온도 (C)' : 'Temperature (C)',
                  value: _temperature,
                  min: -100,
                  max: 400,
                  defaultValue: 25,
                  formatValue: (v) => '${v.toStringAsFixed(0)} C',
                  onChanged: (v) => setState(() => _temperature = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '압력 (atm)' : 'Pressure (atm)',
                    value: _pressure,
                    min: 0.001,
                    max: 300,
                    defaultValue: 1,
                    formatValue: (v) => '${v.toStringAsFixed(2)} atm',
                    onChanged: (v) => setState(() => _pressure = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPhaseLabel(String phase, bool isKorean) {
    final labels = {
      'solid': isKorean ? '고체' : 'Solid',
      'liquid': isKorean ? '액체' : 'Liquid',
      'gas': isKorean ? '기체' : 'Gas',
      'supercritical': isKorean ? '초임계' : 'Supercritical',
    };
    return labels[phase] ?? phase;
  }

  Color _getPhaseColor(String phase) {
    switch (phase) {
      case 'solid': return Colors.blue;
      case 'liquid': return Colors.green;
      case 'gas': return Colors.orange;
      case 'supercritical': return Colors.purple;
      default: return AppColors.muted;
    }
  }
}

class _PhaseData {
  final Offset triplePoint; // (T, P)
  final Offset criticalPoint; // (T, P)
  final double normalBoilingPoint;
  final double normalMeltingPoint;
  final double solidLiquidSlope;

  _PhaseData({
    required this.triplePoint,
    required this.criticalPoint,
    required this.normalBoilingPoint,
    required this.normalMeltingPoint,
    required this.solidLiquidSlope,
  });
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
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PhaseDiagramPainter extends CustomPainter {
  final String substance;
  final _PhaseData phaseData;
  final double currentT;
  final double currentP;
  final String currentPhase;
  final bool isKorean;

  _PhaseDiagramPainter({
    required this.substance,
    required this.phaseData,
    required this.currentT,
    required this.currentP,
    required this.currentPhase,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 50.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // Temperature range: -100 to 400 C
    // Pressure range: 0.001 to 300 atm (log scale)
    final tMin = -100.0;
    final tMax = 400.0;
    final pMin = 0.001;
    final pMax = 300.0;

    Offset toScreen(double t, double p) {
      final x = padding + (t - tMin) / (tMax - tMin) * graphWidth;
      final y = size.height - padding - (math.log(p) - math.log(pMin)) / (math.log(pMax) - math.log(pMin)) * graphHeight;
      return Offset(x, y);
    }

    // Draw phase regions with colors
    _drawPhaseRegions(canvas, size, padding, graphWidth, graphHeight, toScreen);

    // Draw axes
    final axisPaint = Paint()
      ..color = AppColors.muted
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );

    // Axis labels
    _drawText(canvas, 'P (atm)', Offset(5, padding - 20), AppColors.muted, 11);
    _drawText(canvas, 'T (C)', Offset(size.width - padding - 30, size.height - 20), AppColors.muted, 11);

    // Temperature scale
    for (int t = -100; t <= 400; t += 100) {
      final x = padding + (t - tMin) / (tMax - tMin) * graphWidth;
      canvas.drawLine(
        Offset(x, size.height - padding),
        Offset(x, size.height - padding + 5),
        axisPaint,
      );
      _drawText(canvas, '$t', Offset(x - 15, size.height - padding + 8), AppColors.muted, 9);
    }

    // Pressure scale (log)
    for (final p in [0.01, 0.1, 1, 10, 100]) {
      final y = size.height - padding - (math.log(p) - math.log(pMin)) / (math.log(pMax) - math.log(pMin)) * graphHeight;
      canvas.drawLine(
        Offset(padding - 5, y),
        Offset(padding, y),
        axisPaint,
      );
      _drawText(canvas, p < 1 ? p.toString() : p.toInt().toString(), Offset(padding - 35, y - 5), AppColors.muted, 9);
    }

    // Draw phase boundaries
    _drawPhaseBoundaries(canvas, toScreen);

    // Draw special points
    _drawSpecialPoints(canvas, toScreen);

    // Draw current point
    final currentPos = toScreen(currentT, currentP);
    if (currentPos.dx >= padding && currentPos.dx <= size.width - padding &&
        currentPos.dy >= padding && currentPos.dy <= size.height - padding) {
      canvas.drawCircle(currentPos, 10, Paint()..color = Colors.white.withValues(alpha: 0.3));
      canvas.drawCircle(currentPos, 6, Paint()..color = Colors.white);
      canvas.drawCircle(currentPos, 6, Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }

    // Phase labels
    _drawText(canvas, isKorean ? '고체' : 'SOLID', Offset(padding + 20, size.height - padding - 50), Colors.blue.withValues(alpha: 0.7), 14, fontWeight: FontWeight.bold);
    _drawText(canvas, isKorean ? '액체' : 'LIQUID', Offset(padding + graphWidth * 0.4, padding + graphHeight * 0.3), Colors.green.withValues(alpha: 0.7), 14, fontWeight: FontWeight.bold);
    _drawText(canvas, isKorean ? '기체' : 'GAS', Offset(padding + graphWidth * 0.6, size.height - padding - 80), Colors.orange.withValues(alpha: 0.7), 14, fontWeight: FontWeight.bold);
  }

  void _drawPhaseRegions(Canvas canvas, Size size, double padding, double graphWidth, double graphHeight, Offset Function(double, double) toScreen) {
    // Simplified colored regions
    // This is approximate; real phase diagrams have more complex shapes
  }

  void _drawPhaseBoundaries(Canvas canvas, Offset Function(double, double) toScreen) {
    final boundaryPaint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Solid-Liquid boundary (from triple point upward)
    final slPath = Path();
    final tripleScreen = toScreen(phaseData.triplePoint.dx, phaseData.triplePoint.dy);
    slPath.moveTo(tripleScreen.dx, tripleScreen.dy);

    for (double p = phaseData.triplePoint.dy; p <= 300; p *= 1.5) {
      final t = phaseData.normalMeltingPoint + (p - 1) * phaseData.solidLiquidSlope * 0.1;
      final pos = toScreen(t, p);
      slPath.lineTo(pos.dx, pos.dy);
    }
    canvas.drawPath(slPath, boundaryPaint);

    // Liquid-Gas boundary (from triple point to critical point)
    final lgPath = Path();
    lgPath.moveTo(tripleScreen.dx, tripleScreen.dy);

    for (double t = phaseData.triplePoint.dx; t <= phaseData.criticalPoint.dx; t += 5) {
      final p = math.exp((t - phaseData.normalBoilingPoint) / 30);
      final pos = toScreen(t, p.clamp(phaseData.triplePoint.dy, phaseData.criticalPoint.dy));
      lgPath.lineTo(pos.dx, pos.dy);
    }
    canvas.drawPath(lgPath, boundaryPaint);

    // Solid-Gas boundary (from triple point to left)
    final sgPath = Path();
    sgPath.moveTo(tripleScreen.dx, tripleScreen.dy);

    for (double t = phaseData.triplePoint.dx; t >= -100; t -= 10) {
      final p = phaseData.triplePoint.dy * math.exp((t - phaseData.triplePoint.dx) / 50);
      if (p < 0.001) break;
      final pos = toScreen(t, p);
      sgPath.lineTo(pos.dx, pos.dy);
    }
    canvas.drawPath(sgPath, boundaryPaint);
  }

  void _drawSpecialPoints(Canvas canvas, Offset Function(double, double) toScreen) {
    // Triple point
    final triplePos = toScreen(phaseData.triplePoint.dx, phaseData.triplePoint.dy);
    canvas.drawCircle(triplePos, 6, Paint()..color = Colors.red);
    _drawText(canvas, isKorean ? '삼중점' : 'Triple', Offset(triplePos.dx + 8, triplePos.dy - 5), Colors.red, 10);

    // Critical point
    final criticalPos = toScreen(phaseData.criticalPoint.dx, phaseData.criticalPoint.dy);
    canvas.drawCircle(criticalPos, 6, Paint()..color = Colors.purple);
    _drawText(canvas, isKorean ? '임계점' : 'Critical', Offset(criticalPos.dx + 8, criticalPos.dy - 5), Colors.purple, 10);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize,
      {FontWeight fontWeight = FontWeight.normal}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _PhaseDiagramPainter oldDelegate) {
    return oldDelegate.currentT != currentT || oldDelegate.currentP != currentP || oldDelegate.substance != substance;
  }
}
