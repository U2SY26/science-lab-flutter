import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Earthquake Waves (P-waves, S-waves) Simulation
class EarthquakeWavesScreen extends StatefulWidget {
  const EarthquakeWavesScreen({super.key});

  @override
  State<EarthquakeWavesScreen> createState() => _EarthquakeWavesScreenState();
}

class _EarthquakeWavesScreenState extends State<EarthquakeWavesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _time = 0.0;
  double _magnitude = 5.0;
  bool _isAnimating = false;
  bool _showPWaves = true;
  bool _showSWaves = true;
  bool _showSurfaceWaves = true;
  bool _isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _updateAnimation() {
    if (!_isAnimating) return;
    setState(() {
      _time += 0.05;
      if (_time > 10) _time = 0;
    });
  }

  void _triggerEarthquake() {
    HapticFeedback.heavyImpact();
    setState(() {
      _time = 0;
      _isAnimating = true;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _isAnimating = false;
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
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKorean ? '지구과학 시뮬레이션' : 'EARTH SCIENCE SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '지진파' : 'Earthquake Waves',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => _isKorean = !_isKorean),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: _isKorean ? '지구과학 시뮬레이션' : 'EARTH SCIENCE SIMULATION',
          title: _isKorean ? '지진파 (P파, S파)' : 'Earthquake Waves (P, S waves)',
          formula: 'vP ≈ 6 km/s, vS ≈ 3.5 km/s',
          formulaDescription: _isKorean
              ? 'P파(종파)는 빠르고 물질을 압축/팽창시킵니다. S파(횡파)는 느리고 물질을 가로로 흔듭니다. S파는 액체를 통과하지 못합니다.'
              : 'P-waves (longitudinal) are fast and compress material. S-waves (transverse) are slower and shake material sideways. S-waves cannot pass through liquids.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: EarthquakeWavesPainter(
                time: _time,
                magnitude: _magnitude,
                showPWaves: _showPWaves,
                showSWaves: _showSWaves,
                showSurfaceWaves: _showSurfaceWaves,
                isAnimating: _isAnimating,
                isKorean: _isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: _isKorean ? '지진 규모' : 'Magnitude',
                  value: _magnitude,
                  min: 3.0,
                  max: 8.0,
                  defaultValue: 5.0,
                  formatValue: (v) => 'M ${v.toStringAsFixed(1)}',
                  onChanged: (v) => setState(() => _magnitude = v),
                ),
                advancedControls: [
                  SimToggle(
                    label: _isKorean ? 'P파 표시' : 'Show P-waves',
                    value: _showPWaves,
                    onChanged: (v) => setState(() => _showPWaves = v),
                  ),
                  SimToggle(
                    label: _isKorean ? 'S파 표시' : 'Show S-waves',
                    value: _showSWaves,
                    onChanged: (v) => setState(() => _showSWaves = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '표면파 표시' : 'Surface Waves',
                    value: _showSurfaceWaves,
                    onChanged: (v) => setState(() => _showSurfaceWaves = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(time: _time, isKorean: _isKorean),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isKorean ? '지진 발생!' : 'Trigger Quake!',
                icon: Icons.warning,
                isPrimary: true,
                onPressed: _triggerEarthquake,
              ),
              SimButton(
                label: _isKorean ? '리셋' : 'Reset',
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

class _InfoCard extends StatelessWidget {
  final double time;
  final bool isKorean;

  const _InfoCard({required this.time, required this.isKorean});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                isKorean ? 'P파 (종파, 압축파)' : 'P-wave (Primary, Compression)',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 12, height: 12, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                isKorean ? 'S파 (횡파, 전단파)' : 'S-wave (Secondary, Shear)',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 12, height: 12, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                isKorean ? '표면파 (레일리파, 러브파)' : 'Surface waves (Rayleigh, Love)',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EarthquakeWavesPainter extends CustomPainter {
  final double time;
  final double magnitude;
  final bool showPWaves;
  final bool showSWaves;
  final bool showSurfaceWaves;
  final bool isAnimating;
  final bool isKorean;

  EarthquakeWavesPainter({
    required this.time,
    required this.magnitude,
    required this.showPWaves,
    required this.showSWaves,
    required this.showSurfaceWaves,
    required this.isAnimating,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background - Earth cross-section
    _drawBackground(canvas, size);

    if (!isAnimating && time == 0) {
      _drawWaitingState(canvas, size);
      return;
    }

    // Earthquake focus
    final focusX = size.width * 0.2;
    final focusY = size.height * 0.5;

    // Draw focus point
    _drawFocus(canvas, focusX, focusY);

    // Draw P-waves
    if (showPWaves) {
      _drawPWaves(canvas, focusX, focusY, size);
    }

    // Draw S-waves
    if (showSWaves) {
      _drawSWaves(canvas, focusX, focusY, size);
    }

    // Draw surface waves
    if (showSurfaceWaves) {
      _drawSurfaceWaves(canvas, size);
    }

    // Draw seismograph
    _drawSeismograph(canvas, size);

    // Labels
    _drawLabels(canvas, size, focusX, focusY);
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Surface
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.2),
      Paint()..color = const Color(0xFF228B22).withValues(alpha: 0.5),
    );

    // Crust
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.2, size.width, size.height * 0.3),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8B4513),
            const Color(0xFFA0522D),
          ],
        ).createShader(Rect.fromLTWH(0, size.height * 0.2, size.width, size.height * 0.3)),
    );

    // Mantle
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFF4500),
            const Color(0xFFDC143C),
          ],
        ).createShader(Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5)),
    );

    // Buildings on surface
    for (double x = 50; x < size.width; x += 80) {
      final buildingHeight = 20 + (x.hashCode % 30);
      final buildingWidth = 25.0;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.2 - buildingHeight, buildingWidth, buildingHeight.toDouble()),
        Paint()..color = Colors.grey.shade700,
      );
    }
  }

  void _drawWaitingState(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: isKorean ? '지진 발생 버튼을 누르세요' : 'Press Trigger Quake button',
        style: const TextStyle(color: Colors.white54, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2),
    );
  }

  void _drawFocus(Canvas canvas, double x, double y) {
    // Epicenter on surface
    canvas.drawCircle(
      Offset(x, 50),
      8,
      Paint()..color = Colors.red,
    );

    // Focus (hypocenter)
    final focusGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.yellow,
          Colors.orange,
          Colors.red.withValues(alpha: 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 30));
    canvas.drawCircle(Offset(x, y), 30, focusGlow);
    canvas.drawCircle(Offset(x, y), 10, Paint()..color = Colors.yellow);

    // Line from focus to epicenter
    canvas.drawLine(
      Offset(x, y),
      Offset(x, 50),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawPWaves(Canvas canvas, double fx, double fy, Size size) {
    final pSpeed = 6.0; // Relative speed
    final pRadius = time * pSpeed * 20 * (magnitude / 5);

    if (pRadius < 5) return;

    // P-wave circles
    for (int i = 0; i < 3; i++) {
      final r = pRadius - i * 20;
      if (r > 0) {
        canvas.drawCircle(
          Offset(fx, fy),
          r,
          Paint()
            ..color = Colors.red.withValues(alpha: 0.5 - i * 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 - i.toDouble(),
        );
      }
    }

    // Compression visualization
    final compressPoints = 16;
    for (int i = 0; i < compressPoints; i++) {
      final angle = i * 2 * math.pi / compressPoints;
      final compression = math.sin(pRadius * 0.1 - time * 5) * 5;
      final r = pRadius + compression;

      if (r > 5) {
        final x = fx + r * math.cos(angle);
        final y = fy + r * math.sin(angle);
        canvas.drawCircle(
          Offset(x, y),
          3,
          Paint()..color = Colors.red.withValues(alpha: 0.8),
        );
      }
    }
  }

  void _drawSWaves(Canvas canvas, double fx, double fy, Size size) {
    final sSpeed = 3.5; // Slower than P-waves
    final sRadius = time * sSpeed * 20 * (magnitude / 5);

    if (sRadius < 5 || sRadius < 30) return; // S-waves arrive later

    // S-wave circles
    for (int i = 0; i < 3; i++) {
      final r = sRadius - i * 15;
      if (r > 0) {
        canvas.drawCircle(
          Offset(fx, fy),
          r,
          Paint()
            ..color = Colors.blue.withValues(alpha: 0.5 - i * 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 - i.toDouble(),
        );
      }
    }

    // Shear motion visualization
    final shearPoints = 20;
    for (int i = 0; i < shearPoints; i++) {
      final angle = i * 2 * math.pi / shearPoints;
      final r = sRadius;
      final perpOffset = math.sin(angle * 3 + time * 8) * 8;

      final x = fx + r * math.cos(angle) + perpOffset * math.sin(angle);
      final y = fy + r * math.sin(angle) - perpOffset * math.cos(angle);

      if (r > 10) {
        canvas.drawCircle(
          Offset(x, y),
          3,
          Paint()..color = Colors.blue.withValues(alpha: 0.8),
        );
      }
    }
  }

  void _drawSurfaceWaves(Canvas canvas, Size size) {
    final surfaceY = size.height * 0.2;
    final waveSpeed = 2.5;
    final waveStart = size.width * 0.2;
    final waveFront = waveStart + time * waveSpeed * 30;

    if (waveFront < waveStart) return;

    final path = Path();
    path.moveTo(0, surfaceY);

    for (double x = 0; x < size.width; x += 3) {
      double y = surfaceY;

      if (x > waveStart && x < waveFront) {
        final distFromFront = waveFront - x;
        final amplitude = math.min(distFromFront / 50, 1.0) * magnitude * 2;
        y = surfaceY - amplitude * math.sin((x - waveStart) * 0.1 + time * 5);
      }

      path.lineTo(x, y);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawSeismograph(Canvas canvas, Size size) {
    final graphLeft = size.width * 0.55;
    final graphTop = 20.0;
    final graphWidth = size.width * 0.4;
    final graphHeight = 60.0;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(graphLeft, graphTop, graphWidth, graphHeight),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF1A1A2E),
    );

    // Seismograph trace
    final path = Path();
    path.moveTo(graphLeft, graphTop + graphHeight / 2);

    for (double x = 0; x < graphWidth; x += 2) {
      final t = (time - (graphWidth - x) / 50).clamp(0.0, 10.0);
      double amplitude = 0;

      if (t > 0 && t < 8) {
        // P-wave arrival
        if (t > 0.5 && t < 2) {
          amplitude += math.sin(t * 20) * 10 * (magnitude / 5);
        }
        // S-wave arrival
        if (t > 1.5 && t < 4) {
          amplitude += math.sin(t * 15) * 15 * (magnitude / 5);
        }
        // Surface waves
        if (t > 2.5 && t < 7) {
          amplitude += math.sin(t * 8) * 20 * (magnitude / 5) * (1 - (t - 2.5) / 4.5);
        }
      }

      path.lineTo(graphLeft + x, graphTop + graphHeight / 2 - amplitude);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: isKorean ? '지진계' : 'Seismograph',
        style: const TextStyle(color: Colors.white70, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(graphLeft + 5, graphTop + 5));
  }

  void _drawLabels(Canvas canvas, Size size, double fx, double fy) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Focus label
    textPainter.text = TextSpan(
      text: isKorean ? '진원' : 'Focus',
      style: const TextStyle(color: Colors.yellow, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(fx + 15, fy - 5));

    // Epicenter label
    textPainter.text = TextSpan(
      text: isKorean ? '진앙' : 'Epicenter',
      style: const TextStyle(color: Colors.red, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(fx + 15, 45));
  }

  @override
  bool shouldRepaint(covariant EarthquakeWavesPainter oldDelegate) {
    return time != oldDelegate.time ||
        magnitude != oldDelegate.magnitude ||
        showPWaves != oldDelegate.showPWaves ||
        showSWaves != oldDelegate.showSWaves ||
        showSurfaceWaves != oldDelegate.showSurfaceWaves ||
        isAnimating != oldDelegate.isAnimating;
  }
}
