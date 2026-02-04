import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class OceanCurrentsScreen extends StatefulWidget {
  final bool isKorean;

  const OceanCurrentsScreen({super.key, required this.isKorean});

  @override
  State<OceanCurrentsScreen> createState() => _OceanCurrentsScreenState();
}

class _OceanCurrentsScreenState extends State<OceanCurrentsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _windStrength = 0.5;
  double _temperatureDifference = 0.5;
  double _coriolisEffect = 0.5;
  double _animationSpeed = 1.0;
  double _time = 0.0;
  bool _showThermohaline = true;
  bool _showSurfaceCurrents = true;

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
      _windStrength = 0.5;
      _temperatureDifference = 0.5;
      _coriolisEffect = 0.5;
      _animationSpeed = 1.0;
      _time = 0.0;
      _showThermohaline = true;
      _showSurfaceCurrents = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimulationContainer(
      category: widget.isKorean ? '지구과학' : 'Earth Science',
      title: widget.isKorean ? '해류' : 'Ocean Currents',
      formula: widget.isKorean
          ? '표층 해류: 바람 + 코리올리 힘\n심층 해류: 온도 + 염분 차이'
          : 'Surface: Wind + Coriolis\nDeep: Thermohaline circulation',
      simulation: CustomPaint(
        painter: OceanCurrentsPainter(
          time: _time,
          windStrength: _windStrength,
          temperatureDifference: _temperatureDifference,
          coriolisEffect: _coriolisEffect,
          showThermohaline: _showThermohaline,
          showSurfaceCurrents: _showSurfaceCurrents,
        ),
        size: Size.infinite,
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ControlGroup(
            primaryControl: SimSlider(
              label: widget.isKorean ? '바람 세기' : 'Wind Strength',
              value: _windStrength,
              min: 0.1,
              max: 1.0,
              formatValue: (v) => '${(v * 100).toInt()}%',
              onChanged: (v) => setState(() => _windStrength = v),
            ),
            advancedControls: [
              SimSlider(
                label: widget.isKorean ? '온도 차이' : 'Temperature Difference',
                value: _temperatureDifference,
                min: 0.1,
                max: 1.0,
                formatValue: (v) => '${(v * 100).toInt()}%',
                onChanged: (v) => setState(() => _temperatureDifference = v),
              ),
              SimSlider(
                label: widget.isKorean ? '코리올리 효과' : 'Coriolis Effect',
                value: _coriolisEffect,
                min: 0.0,
                max: 1.0,
                formatValue: (v) => '${(v * 100).toInt()}%',
                onChanged: (v) => setState(() => _coriolisEffect = v),
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
                label: widget.isKorean ? '표층 해류 표시' : 'Show Surface Currents',
                value: _showSurfaceCurrents,
                onChanged: (v) => setState(() => _showSurfaceCurrents = v),
              ),
              SimToggle(
                label: widget.isKorean ? '심층 순환 표시' : 'Show Thermohaline',
                value: _showThermohaline,
                onChanged: (v) => setState(() => _showThermohaline = v),
              ),
            ],
            advancedLabel: widget.isKorean ? '고급 설정' : 'Advanced Settings',
          ),
          const SizedBox(height: 16),
          PresetGroup(
            label: widget.isKorean ? '해류 유형' : 'Current Types',
            presets: [
              PresetButton(
                label: widget.isKorean ? '걸프 해류' : 'Gulf Stream',
                onPressed: () => setState(() {
                  _windStrength = 0.7;
                  _temperatureDifference = 0.6;
                  _coriolisEffect = 0.8;
                  _showSurfaceCurrents = true;
                }),
              ),
              PresetButton(
                label: widget.isKorean ? '심층 순환' : 'Deep Circulation',
                onPressed: () => setState(() {
                  _windStrength = 0.3;
                  _temperatureDifference = 0.9;
                  _coriolisEffect = 0.4;
                  _showThermohaline = true;
                }),
              ),
              PresetButton(
                label: widget.isKorean ? '적도 해류' : 'Equatorial',
                onPressed: () => setState(() {
                  _windStrength = 0.8;
                  _temperatureDifference = 0.3;
                  _coriolisEffect = 0.2;
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

class OceanCurrentsPainter extends CustomPainter {
  final double time;
  final double windStrength;
  final double temperatureDifference;
  final double coriolisEffect;
  final bool showThermohaline;
  final bool showSurfaceCurrents;

  OceanCurrentsPainter({
    required this.time,
    required this.windStrength,
    required this.temperatureDifference,
    required this.coriolisEffect,
    required this.showThermohaline,
    required this.showSurfaceCurrents,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Ocean background with depth gradient
    final oceanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0077BE), // Surface blue
          const Color(0xFF003366), // Mid blue
          const Color(0xFF001a33), // Deep blue
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), oceanPaint);

    // Draw continents (simplified)
    _drawContinents(canvas, size);

    // Draw temperature zones
    _drawTemperatureZones(canvas, size);

    // Draw thermohaline circulation (deep currents)
    if (showThermohaline) {
      _drawThermohalineCirculation(canvas, size);
    }

    // Draw surface currents
    if (showSurfaceCurrents) {
      _drawSurfaceCurrents(canvas, size);
    }

    // Draw wind arrows
    _drawWindArrows(canvas, size);

    // Draw floating particles
    _drawParticles(canvas, size);

    // Draw legend
    _drawLegend(canvas, size);
  }

  void _drawContinents(Canvas canvas, Size size) {
    final landPaint = Paint()..color = const Color(0xFF2E8B57);

    // Simplified North America
    final naPath = Path();
    naPath.moveTo(size.width * 0.1, size.height * 0.15);
    naPath.lineTo(size.width * 0.25, size.height * 0.1);
    naPath.lineTo(size.width * 0.3, size.height * 0.25);
    naPath.lineTo(size.width * 0.2, size.height * 0.35);
    naPath.lineTo(size.width * 0.1, size.height * 0.3);
    naPath.close();
    canvas.drawPath(naPath, landPaint);

    // Simplified South America
    final saPath = Path();
    saPath.moveTo(size.width * 0.2, size.height * 0.5);
    saPath.lineTo(size.width * 0.25, size.height * 0.45);
    saPath.lineTo(size.width * 0.28, size.height * 0.65);
    saPath.lineTo(size.width * 0.22, size.height * 0.8);
    saPath.lineTo(size.width * 0.18, size.height * 0.6);
    saPath.close();
    canvas.drawPath(saPath, landPaint);

    // Simplified Europe/Africa
    final euPath = Path();
    euPath.moveTo(size.width * 0.45, size.height * 0.15);
    euPath.lineTo(size.width * 0.55, size.height * 0.12);
    euPath.lineTo(size.width * 0.58, size.height * 0.25);
    euPath.lineTo(size.width * 0.52, size.height * 0.35);
    euPath.lineTo(size.width * 0.48, size.height * 0.5);
    euPath.lineTo(size.width * 0.55, size.height * 0.7);
    euPath.lineTo(size.width * 0.48, size.height * 0.75);
    euPath.lineTo(size.width * 0.42, size.height * 0.55);
    euPath.lineTo(size.width * 0.44, size.height * 0.3);
    euPath.close();
    canvas.drawPath(euPath, landPaint);

    // Asia/Australia hint
    final asPath = Path();
    asPath.moveTo(size.width * 0.7, size.height * 0.15);
    asPath.lineTo(size.width * 0.9, size.height * 0.2);
    asPath.lineTo(size.width * 0.85, size.height * 0.35);
    asPath.lineTo(size.width * 0.75, size.height * 0.4);
    asPath.lineTo(size.width * 0.65, size.height * 0.25);
    asPath.close();
    canvas.drawPath(asPath, landPaint);

    // Australia
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.82, size.height * 0.65), width: 50, height: 35),
      landPaint,
    );
  }

  void _drawTemperatureZones(Canvas canvas, Size size) {
    // Warm equatorial zone
    final warmPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2),
      warmPaint,
    );

    // Cold polar zones
    final coldPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.15),
      coldPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15),
      coldPaint,
    );
  }

  void _drawThermohalineCirculation(Canvas canvas, Size size) {
    final deepPaint = Paint()
      ..color = Colors.blue[900]!.withValues(alpha: 0.8 * temperatureDifference)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Deep cold current path
    final deepPath = Path();
    deepPath.moveTo(size.width * 0.5, size.height * 0.1);
    deepPath.quadraticBezierTo(
      size.width * 0.3, size.height * 0.3,
      size.width * 0.2, size.height * 0.5,
    );
    deepPath.quadraticBezierTo(
      size.width * 0.1, size.height * 0.7,
      size.width * 0.3, size.height * 0.85,
    );
    deepPath.quadraticBezierTo(
      size.width * 0.6, size.height * 0.9,
      size.width * 0.8, size.height * 0.7,
    );
    deepPath.quadraticBezierTo(
      size.width * 0.9, size.height * 0.5,
      size.width * 0.7, size.height * 0.3,
    );

    // Animate dash pattern
    final dashOffset = (time * 20) % 40;
    _drawDashedPath(canvas, deepPath, deepPaint, dashOffset);

    // Draw arrows along the path
    _drawPathArrows(canvas, deepPath, Colors.blue[900]!.withValues(alpha: 0.8));
  }

  void _drawSurfaceCurrents(Canvas canvas, Size size) {
    final currentStrength = windStrength * 0.8;

    // Gulf Stream (warm current)
    _drawCurrentArrow(
      canvas,
      Offset(size.width * 0.25, size.height * 0.4),
      Offset(size.width * 0.45, size.height * 0.2),
      Colors.orange.withValues(alpha: currentStrength),
      'Gulf Stream',
    );

    // North Atlantic Drift
    _drawCurrentArrow(
      canvas,
      Offset(size.width * 0.45, size.height * 0.2),
      Offset(size.width * 0.55, size.height * 0.15),
      Colors.orange.withValues(alpha: currentStrength * 0.8),
      '',
    );

    // Canary Current (cold)
    _drawCurrentArrow(
      canvas,
      Offset(size.width * 0.42, size.height * 0.25),
      Offset(size.width * 0.38, size.height * 0.45),
      Colors.cyan.withValues(alpha: currentStrength),
      '',
    );

    // North Equatorial Current
    _drawCurrentArrow(
      canvas,
      Offset(size.width * 0.6, size.height * 0.45),
      Offset(size.width * 0.3, size.height * 0.45),
      Colors.orange.withValues(alpha: currentStrength),
      '',
    );

    // South Equatorial Current
    _drawCurrentArrow(
      canvas,
      Offset(size.width * 0.55, size.height * 0.55),
      Offset(size.width * 0.25, size.height * 0.55),
      Colors.orange.withValues(alpha: currentStrength),
      '',
    );

    // Brazil Current
    _drawCurrentArrow(
      canvas,
      Offset(size.width * 0.28, size.height * 0.55),
      Offset(size.width * 0.25, size.height * 0.7),
      Colors.orange.withValues(alpha: currentStrength * 0.7),
      '',
    );

    // Antarctic Circumpolar
    _drawCurrentArrow(
      canvas,
      Offset(size.width * 0.1, size.height * 0.85),
      Offset(size.width * 0.9, size.height * 0.85),
      Colors.cyan.withValues(alpha: currentStrength),
      '',
    );
  }

  void _drawCurrentArrow(Canvas canvas, Offset start, Offset end, Color color, String label) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Apply Coriolis deflection
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final deflection = coriolisEffect * 20;
    final midX = (start.dx + end.dx) / 2 + deflection * (dy / (dx.abs() + dy.abs() + 0.1));
    final midY = (start.dy + end.dy) / 2;

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(midX, midY, end.dx, end.dy);
    canvas.drawPath(path, paint);

    // Arrow head
    final angle = math.atan2(end.dy - midY, end.dx - midX);
    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - 10 * math.cos(angle - 0.4),
      end.dy - 10 * math.sin(angle - 0.4),
    );
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - 10 * math.cos(angle + 0.4),
      end.dy - 10 * math.sin(angle + 0.4),
    );
    canvas.drawPath(arrowPath, paint);

    // Label
    if (label.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(midX - textPainter.width / 2, midY - 15));
    }
  }

  void _drawWindArrows(Canvas canvas, Size size) {
    final windPaint = Paint()
      ..color = Colors.white.withValues(alpha: windStrength * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Trade winds (easterlies near equator)
    for (int i = 0; i < 5; i++) {
      final y = size.height * (0.4 + i * 0.04);
      final offset = math.sin(time + i) * 5;
      canvas.drawLine(
        Offset(size.width * 0.7 + offset, y),
        Offset(size.width * 0.5 + offset, y),
        windPaint,
      );
    }

    // Westerlies (mid-latitudes)
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.2 + i * 0.05);
      final offset = math.sin(time + i) * 5;
      canvas.drawLine(
        Offset(size.width * 0.3 + offset, y),
        Offset(size.width * 0.5 + offset, y),
        windPaint,
      );
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    final random = math.Random(42);
    final particlePaint = Paint()..color = Colors.white.withValues(alpha: 0.6);

    for (int i = 0; i < 30; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = random.nextDouble() * 0.5 + 0.5;

      // Move particles with currents
      final offsetX = math.sin(time * speed + i) * 20 * windStrength;
      final offsetY = math.cos(time * speed * 0.5 + i) * 10;

      final x = (baseX + offsetX) % size.width;
      final y = (baseY + offsetY).clamp(0.0, size.height);

      canvas.drawCircle(Offset(x, y), 2, particlePaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashOffset) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = dashOffset;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + 15).clamp(0.0, metric.length);
        final extractPath = metric.extractPath(start, end);
        canvas.drawPath(extractPath, paint);
        distance += 25;
      }
    }
  }

  void _drawPathArrows(Canvas canvas, Path path, Color color) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      for (double d = 50; d < metric.length; d += 100) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) {
          _drawSmallArrow(canvas, tangent.position, tangent.angle, color);
        }
      }
    }
  }

  void _drawSmallArrow(Canvas canvas, Offset position, double angle, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(
      position.dx + 8 * math.cos(angle),
      position.dy + 8 * math.sin(angle),
    );
    path.lineTo(
      position.dx - 5 * math.cos(angle - 0.5),
      position.dy - 5 * math.sin(angle - 0.5),
    );
    path.lineTo(
      position.dx - 5 * math.cos(angle + 0.5),
      position.dy - 5 * math.sin(angle + 0.5),
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawLegend(Canvas canvas, Size size) {
    final legendX = size.width - 90;
    final legendY = 10.0;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(legendX - 5, legendY - 5, 90, 60),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Warm current
    canvas.drawLine(
      Offset(legendX, legendY + 10),
      Offset(legendX + 20, legendY + 10),
      Paint()
        ..color = Colors.orange
        ..strokeWidth = 3,
    );
    textPainter.text = const TextSpan(
      text: 'Warm',
      style: TextStyle(color: Colors.white, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(legendX + 25, legendY + 3));

    // Cold current
    canvas.drawLine(
      Offset(legendX, legendY + 30),
      Offset(legendX + 20, legendY + 30),
      Paint()
        ..color = Colors.cyan
        ..strokeWidth = 3,
    );
    textPainter.text = const TextSpan(
      text: 'Cold',
      style: TextStyle(color: Colors.white, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(legendX + 25, legendY + 23));

    // Deep current
    canvas.drawLine(
      Offset(legendX, legendY + 50),
      Offset(legendX + 20, legendY + 50),
      Paint()
        ..color = Colors.blue[900]!
        ..strokeWidth = 3,
    );
    textPainter.text = const TextSpan(
      text: 'Deep',
      style: TextStyle(color: Colors.white, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(legendX + 25, legendY + 43));
  }

  @override
  bool shouldRepaint(covariant OceanCurrentsPainter oldDelegate) {
    return oldDelegate.time != time ||
           oldDelegate.windStrength != windStrength ||
           oldDelegate.temperatureDifference != temperatureDifference ||
           oldDelegate.coriolisEffect != coriolisEffect ||
           oldDelegate.showThermohaline != showThermohaline ||
           oldDelegate.showSurfaceCurrents != showSurfaceCurrents;
  }
}
