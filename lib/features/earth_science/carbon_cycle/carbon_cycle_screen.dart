import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CarbonCycleScreen extends StatefulWidget {
  final bool isKorean;

  const CarbonCycleScreen({super.key, required this.isKorean});

  @override
  State<CarbonCycleScreen> createState() => _CarbonCycleScreenState();
}

class _CarbonCycleScreenState extends State<CarbonCycleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _photosynthesisRate = 0.5;
  double _respirationRate = 0.5;
  double _fossilFuelEmission = 0.3;
  double _oceanAbsorption = 0.4;
  double _animationSpeed = 1.0;
  double _time = 0.0;
  bool _showLabels = true;

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
    setState(() {
      _time += 0.02 * _animationSpeed;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _photosynthesisRate = 0.5;
      _respirationRate = 0.5;
      _fossilFuelEmission = 0.3;
      _oceanAbsorption = 0.4;
      _animationSpeed = 1.0;
      _time = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimulationContainer(
      category: widget.isKorean ? '지구과학' : 'Earth Science',
      title: widget.isKorean ? '탄소 순환' : 'Carbon Cycle',
      formula: widget.isKorean
          ? 'CO₂ + H₂O → C₆H₁₂O₆ + O₂ (광합성)\nC₆H₁₂O₆ + O₂ → CO₂ + H₂O (호흡)'
          : 'CO₂ + H₂O → C₆H₁₂O₆ + O₂ (photosynthesis)\nC₆H₁₂O₆ + O₂ → CO₂ + H₂O (respiration)',
      simulation: CustomPaint(
        painter: CarbonCyclePainter(
          time: _time,
          photosynthesisRate: _photosynthesisRate,
          respirationRate: _respirationRate,
          fossilFuelEmission: _fossilFuelEmission,
          oceanAbsorption: _oceanAbsorption,
          showLabels: _showLabels,
        ),
        size: Size.infinite,
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ControlGroup(
            primaryControl: SimSlider(
              label: widget.isKorean ? '광합성률' : 'Photosynthesis Rate',
              value: _photosynthesisRate,
              min: 0.1,
              max: 1.0,
              formatValue: (v) => '${(v * 100).toInt()}%',
              onChanged: (v) => setState(() => _photosynthesisRate = v),
            ),
            advancedControls: [
              SimSlider(
                label: widget.isKorean ? '호흡률' : 'Respiration Rate',
                value: _respirationRate,
                min: 0.1,
                max: 1.0,
                formatValue: (v) => '${(v * 100).toInt()}%',
                onChanged: (v) => setState(() => _respirationRate = v),
              ),
              SimSlider(
                label: widget.isKorean ? '화석연료 배출' : 'Fossil Fuel Emission',
                value: _fossilFuelEmission,
                min: 0.0,
                max: 1.0,
                formatValue: (v) => '${(v * 100).toInt()}%',
                onChanged: (v) => setState(() => _fossilFuelEmission = v),
              ),
              SimSlider(
                label: widget.isKorean ? '해양 흡수' : 'Ocean Absorption',
                value: _oceanAbsorption,
                min: 0.1,
                max: 1.0,
                formatValue: (v) => '${(v * 100).toInt()}%',
                onChanged: (v) => setState(() => _oceanAbsorption = v),
              ),
              SimSlider(
                label: widget.isKorean ? '애니메이션 속도' : 'Animation Speed',
                value: _animationSpeed,
                min: 0.1,
                max: 3.0,
                formatValue: (v) => '${v.toStringAsFixed(1)}x',
                onChanged: (v) => setState(() => _animationSpeed = v),
              ),
              SimToggle(
                label: widget.isKorean ? '라벨 표시' : 'Show Labels',
                value: _showLabels,
                onChanged: (v) => setState(() => _showLabels = v),
              ),
            ],
            advancedLabel: widget.isKorean ? '고급 설정' : 'Advanced Settings',
          ),
          const SizedBox(height: 16),
          PresetGroup(
            label: widget.isKorean ? '시나리오' : 'Scenarios',
            presets: [
              PresetButton(
                label: widget.isKorean ? '균형' : 'Balanced',
                onPressed: () => setState(() {
                  _photosynthesisRate = 0.5;
                  _respirationRate = 0.5;
                  _fossilFuelEmission = 0.3;
                  _oceanAbsorption = 0.4;
                }),
              ),
              PresetButton(
                label: widget.isKorean ? '산업화' : 'Industrial',
                onPressed: () => setState(() {
                  _photosynthesisRate = 0.4;
                  _respirationRate = 0.6;
                  _fossilFuelEmission = 0.9;
                  _oceanAbsorption = 0.3;
                }),
              ),
              PresetButton(
                label: widget.isKorean ? '자연상태' : 'Natural',
                onPressed: () => setState(() {
                  _photosynthesisRate = 0.7;
                  _respirationRate = 0.4;
                  _fossilFuelEmission = 0.0;
                  _oceanAbsorption = 0.5;
                }),
              ),
            ],
          ),
        ],
      ),
      buttons: SimButtonGroup(
        buttons: [
          SimButton(
            label: widget.isKorean ? '초기화' : 'Reset',
            icon: Icons.refresh,
            onPressed: _reset,
          ),
        ],
      ),
    );
  }
}

class CarbonCyclePainter extends CustomPainter {
  final double time;
  final double photosynthesisRate;
  final double respirationRate;
  final double fossilFuelEmission;
  final double oceanAbsorption;
  final bool showLabels;

  CarbonCyclePainter({
    required this.time,
    required this.photosynthesisRate,
    required this.respirationRate,
    required this.fossilFuelEmission,
    required this.oceanAbsorption,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient (sky to underground)
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF87CEEB), // Sky blue
          const Color(0xFF90EE90), // Light green (ground)
          const Color(0xFF8B4513), // Brown (underground)
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Ground line
    final groundY = size.height * 0.6;
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      Paint()
        ..color = const Color(0xFF654321)
        ..strokeWidth = 3,
    );

    // Ocean on the right
    final oceanRect = Rect.fromLTWH(size.width * 0.7, groundY, size.width * 0.3, size.height * 0.4);
    canvas.drawRect(
      oceanRect,
      Paint()..color = const Color(0xFF1E90FF).withValues(alpha: 0.8),
    );

    // Draw components
    _drawSun(canvas, size.width * 0.15, size.height * 0.15);
    _drawAtmosphere(canvas, size, groundY);
    _drawTrees(canvas, size.width * 0.25, groundY);
    _drawFactory(canvas, size.width * 0.55, groundY);
    _drawFossilFuels(canvas, size.width * 0.4, groundY + 40);
    _drawAnimals(canvas, size.width * 0.4, groundY - 20);

    // Draw carbon flow arrows
    _drawCarbonFlows(canvas, size, groundY);

    // Draw CO2 particles
    _drawCO2Particles(canvas, size, groundY);

    // Labels
    if (showLabels) {
      _drawLabels(canvas, size, groundY);
    }
  }

  void _drawSun(Canvas canvas, double x, double y) {
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.yellow[200]!, Colors.yellow, Colors.orange],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 30));
    canvas.drawCircle(Offset(x, y), 30, sunPaint);

    // Sun rays
    final rayPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(x + 35 * math.cos(angle), y + 35 * math.sin(angle)),
        Offset(x + 50 * math.cos(angle), y + 50 * math.sin(angle)),
        rayPaint,
      );
    }
  }

  void _drawAtmosphere(Canvas canvas, Size size, double groundY) {
    // Atmosphere CO2 layer
    final atmoPath = Path();
    atmoPath.moveTo(0, 0);
    atmoPath.lineTo(size.width, 0);
    atmoPath.lineTo(size.width, groundY * 0.4);
    atmoPath.quadraticBezierTo(size.width * 0.5, groundY * 0.5, 0, groundY * 0.4);
    atmoPath.close();

    canvas.drawPath(
      atmoPath,
      Paint()..color = Colors.grey.withValues(alpha: 0.15),
    );
  }

  void _drawTrees(Canvas canvas, double x, double groundY) {
    // Tree trunk
    canvas.drawRect(
      Rect.fromLTWH(x - 8, groundY - 60, 16, 60),
      Paint()..color = const Color(0xFF8B4513),
    );

    // Tree crown
    final crownPaint = Paint()..color = const Color(0xFF228B22);
    canvas.drawCircle(Offset(x, groundY - 80), 35, crownPaint);
    canvas.drawCircle(Offset(x - 20, groundY - 60), 25, crownPaint);
    canvas.drawCircle(Offset(x + 20, groundY - 60), 25, crownPaint);

    // Second smaller tree
    canvas.drawRect(
      Rect.fromLTWH(x + 50, groundY - 40, 10, 40),
      Paint()..color = const Color(0xFF8B4513),
    );
    canvas.drawCircle(Offset(x + 55, groundY - 55), 25, crownPaint);
  }

  void _drawFactory(Canvas canvas, double x, double groundY) {
    // Factory building
    canvas.drawRect(
      Rect.fromLTWH(x - 30, groundY - 50, 60, 50),
      Paint()..color = Colors.grey[700]!,
    );

    // Chimney
    canvas.drawRect(
      Rect.fromLTWH(x + 10, groundY - 80, 15, 30),
      Paint()..color = Colors.grey[800]!,
    );

    // Smoke from chimney
    final smokeOffset = math.sin(time * 2) * 5;
    final smokePaint = Paint()..color = Colors.grey.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(x + 17 + smokeOffset, groundY - 90), 8, smokePaint);
    canvas.drawCircle(Offset(x + 20 + smokeOffset * 1.5, groundY - 105), 12, smokePaint);
    canvas.drawCircle(Offset(x + 15 + smokeOffset * 2, groundY - 125), 15, smokePaint);
  }

  void _drawFossilFuels(Canvas canvas, double x, double y) {
    // Underground fossil fuel deposits
    final fuelPaint = Paint()..color = Colors.black.withValues(alpha: 0.8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 30), width: 60, height: 25),
      fuelPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 40, y + 50), width: 40, height: 20),
      fuelPaint,
    );
  }

  void _drawAnimals(Canvas canvas, double x, double y) {
    // Simple animal representation (cow-like)
    final animalPaint = Paint()..color = const Color(0xFF8B4513);
    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 25, height: 15),
      animalPaint,
    );
    // Head
    canvas.drawCircle(Offset(x + 12, y - 3), 7, animalPaint);
  }

  void _drawCarbonFlows(Canvas canvas, Size size, double groundY) {
    final arrowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Photosynthesis arrow (CO2 down to trees) - green
    if (photosynthesisRate > 0.2) {
      arrowPaint.color = Colors.green.withValues(alpha: photosynthesisRate);
      _drawCurvedArrow(canvas,
        Offset(size.width * 0.25, groundY * 0.3),
        Offset(size.width * 0.25, groundY - 100),
        arrowPaint, true);
    }

    // Respiration arrow (from animals up) - red
    if (respirationRate > 0.2) {
      arrowPaint.color = Colors.red.withValues(alpha: respirationRate);
      _drawCurvedArrow(canvas,
        Offset(size.width * 0.4, groundY - 30),
        Offset(size.width * 0.4, groundY * 0.3),
        arrowPaint, false);
    }

    // Fossil fuel emission arrow - dark grey
    if (fossilFuelEmission > 0.1) {
      arrowPaint.color = Colors.grey[800]!.withValues(alpha: fossilFuelEmission);
      _drawCurvedArrow(canvas,
        Offset(size.width * 0.55, groundY - 80),
        Offset(size.width * 0.55, groundY * 0.2),
        arrowPaint, false);
    }

    // Ocean absorption arrow - blue
    if (oceanAbsorption > 0.2) {
      arrowPaint.color = Colors.blue.withValues(alpha: oceanAbsorption);
      _drawCurvedArrow(canvas,
        Offset(size.width * 0.8, groundY * 0.35),
        Offset(size.width * 0.8, groundY + 20),
        arrowPaint, true);
    }
  }

  void _drawCurvedArrow(Canvas canvas, Offset start, Offset end, Paint paint, bool downward) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    final controlOffset = downward ? -20.0 : 20.0;

    path.quadraticBezierTo(midX + controlOffset, midY, end.dx, end.dy);
    canvas.drawPath(path, paint);

    // Arrow head
    final angle = math.atan2(end.dy - midY, end.dx - midX);
    final arrowSize = 8.0;
    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - arrowSize * math.cos(angle - 0.5),
      end.dy - arrowSize * math.sin(angle - 0.5),
    );
    arrowPath.lineTo(
      end.dx - arrowSize * math.cos(angle + 0.5),
      end.dy - arrowSize * math.sin(angle + 0.5),
    );
    arrowPath.close();
    canvas.drawPath(arrowPath, Paint()..color = paint.color);
  }

  void _drawCO2Particles(Canvas canvas, Size size, double groundY) {
    final random = math.Random(42);

    // Atmospheric CO2
    for (int i = 0; i < 20; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * groundY * 0.5;
      final offset = math.sin(time + i) * 10;

      _drawCO2Molecule(canvas, baseX + offset, baseY);
    }

    // Rising CO2 from factory
    if (fossilFuelEmission > 0.2) {
      for (int i = 0; i < (fossilFuelEmission * 5).toInt(); i++) {
        final progress = ((time * 0.5 + i * 0.3) % 1.0);
        final x = size.width * 0.55 + math.sin(progress * math.pi * 2) * 15;
        final y = groundY - 80 - progress * 100;
        _drawCO2Molecule(canvas, x, y);
      }
    }
  }

  void _drawCO2Molecule(Canvas canvas, double x, double y) {
    // Simple CO2 representation
    final moleculePaint = Paint()..color = Colors.grey[600]!.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(x, y), 4, moleculePaint);
    canvas.drawCircle(Offset(x - 5, y), 3, Paint()..color = Colors.red.withValues(alpha: 0.7));
    canvas.drawCircle(Offset(x + 5, y), 3, Paint()..color = Colors.red.withValues(alpha: 0.7));
  }

  void _drawLabels(Canvas canvas, Size size, double groundY) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    final textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    // Atmosphere label
    textPainter.text = TextSpan(text: 'Atmosphere (CO₂)', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.4, 10));

    // Photosynthesis label
    textPainter.text = TextSpan(
      text: 'Photosynthesis',
      style: textStyle.copyWith(color: Colors.green[800]),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.1, groundY * 0.45));

    // Respiration label
    textPainter.text = TextSpan(
      text: 'Respiration',
      style: textStyle.copyWith(color: Colors.red[800]),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.35, groundY * 0.45));

    // Emission label
    textPainter.text = TextSpan(
      text: 'Emissions',
      style: textStyle.copyWith(color: Colors.grey[800]),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.52, groundY * 0.35));

    // Ocean label
    textPainter.text = TextSpan(
      text: 'Ocean Sink',
      style: textStyle.copyWith(color: Colors.blue[800]),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.75, groundY + 10));
  }

  @override
  bool shouldRepaint(covariant CarbonCyclePainter oldDelegate) {
    return oldDelegate.time != time ||
           oldDelegate.photosynthesisRate != photosynthesisRate ||
           oldDelegate.respirationRate != respirationRate ||
           oldDelegate.fossilFuelEmission != fossilFuelEmission ||
           oldDelegate.oceanAbsorption != oceanAbsorption ||
           oldDelegate.showLabels != showLabels;
  }
}
