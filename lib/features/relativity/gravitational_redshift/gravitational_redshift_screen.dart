import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Gravitational Redshift Simulation
class GravitationalRedshiftScreen extends StatefulWidget {
  const GravitationalRedshiftScreen({super.key});

  @override
  State<GravitationalRedshiftScreen> createState() => _GravitationalRedshiftScreenState();
}

class _GravitationalRedshiftScreenState extends State<GravitationalRedshiftScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _mass = 1.0; // Solar masses
  double _emissionRadius = 3.0; // In Schwarzschild radii
  double _time = 0.0;
  bool _isAnimating = true;
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
      _time += 0.03;
    });
  }

  // Gravitational redshift factor
  double get _redshiftFactor {
    // z = 1/sqrt(1 - rs/r) - 1
    final rsOverR = 1 / _emissionRadius;
    if (rsOverR >= 1) return double.infinity;
    return 1 / math.sqrt(1 - rsOverR) - 1;
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _mass = 1.0;
      _emissionRadius = 3.0;
      _time = 0;
      _isAnimating = true;
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
              _isKorean ? '상대성이론 시뮬레이션' : 'RELATIVITY SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '중력 적색편이' : 'Gravitational Redshift',
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
          category: _isKorean ? '상대성이론 시뮬레이션' : 'RELATIVITY SIMULATION',
          title: _isKorean ? '중력 적색편이' : 'Gravitational Redshift',
          formula: 'z = 1/√(1 - rs/r) - 1',
          formulaDescription: _isKorean
              ? '중력장에서 방출된 빛은 중력 우물을 탈출하면서 에너지를 잃고 적색편이됩니다. 이는 시간 지연의 직접적인 결과입니다.'
              : 'Light emitted from a gravitational field loses energy escaping the gravity well, causing redshift. This is a direct consequence of time dilation.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: GravitationalRedshiftPainter(
                mass: _mass,
                emissionRadius: _emissionRadius,
                redshiftFactor: _redshiftFactor,
                time: _time,
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
                  label: _isKorean ? '방출 반경 (r/rs)' : 'Emission Radius (r/rs)',
                  value: _emissionRadius,
                  min: 1.5,
                  max: 10.0,
                  defaultValue: 3.0,
                  formatValue: (v) => '${v.toStringAsFixed(1)} rs',
                  onChanged: (v) => setState(() => _emissionRadius = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '천체 질량' : 'Object Mass',
                    value: _mass,
                    min: 0.5,
                    max: 5.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)} M☉',
                    onChanged: (v) => setState(() => _mass = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                redshiftFactor: _redshiftFactor,
                emissionRadius: _emissionRadius,
                isKorean: _isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isAnimating
                    ? (_isKorean ? '정지' : 'Pause')
                    : (_isKorean ? '재생' : 'Play'),
                icon: _isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isAnimating = !_isAnimating);
                },
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
  final double redshiftFactor;
  final double emissionRadius;
  final bool isKorean;

  const _InfoCard({
    required this.redshiftFactor,
    required this.emissionRadius,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    final timeDilation = 1 / math.sqrt(1 - 1 / emissionRadius);

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
              const Icon(Icons.trending_up, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                isKorean ? '적색편이 z' : 'Redshift z',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                redshiftFactor.isFinite ? redshiftFactor.toStringAsFixed(4) : '∞',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer, size: 14, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                isKorean ? '시간 지연 인자' : 'Time Dilation Factor',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const Spacer(),
              Text(
                timeDilation.isFinite ? '${timeDilation.toStringAsFixed(3)}x' : '∞',
                style: const TextStyle(color: Colors.orange, fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? '파장 증가: ${((1 + redshiftFactor) * 100 - 100).toStringAsFixed(1)}%'
                : 'Wavelength increase: ${((1 + redshiftFactor) * 100 - 100).toStringAsFixed(1)}%',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class GravitationalRedshiftPainter extends CustomPainter {
  final double mass;
  final double emissionRadius;
  final double redshiftFactor;
  final double time;
  final bool isKorean;

  GravitationalRedshiftPainter({
    required this.mass,
    required this.emissionRadius,
    required this.redshiftFactor,
    required this.time,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.3;
    final centerY = size.height / 2;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0A0A1A),
    );

    // Draw massive object
    _drawMassiveObject(canvas, centerX, centerY);

    // Draw emission point
    _drawEmissionPoint(canvas, centerX, centerY, size);

    // Draw photon path with redshift
    _drawPhotonPath(canvas, centerX, centerY, size);

    // Draw observer
    _drawObserver(canvas, size);

    // Draw spectrum comparison
    _drawSpectrumComparison(canvas, size);

    // Labels
    _drawLabels(canvas, size, centerX, centerY);
  }

  void _drawMassiveObject(Canvas canvas, double cx, double cy) {
    final radius = 30 * math.sqrt(mass);

    // Event horizon (Schwarzschild radius)
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()..color = Colors.black,
    );

    // Glow around
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFFF4500).withValues(alpha: 0.3),
          Colors.transparent,
        ],
        stops: const [0.8, 0.95, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius * 1.5));
    canvas.drawCircle(Offset(cx, cy), radius * 1.5, glowPaint);

    // Event horizon edge
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = Colors.red.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawEmissionPoint(Canvas canvas, double cx, double cy, Size size) {
    final baseRadius = 30 * math.sqrt(mass);
    final emissionX = cx + baseRadius * emissionRadius;

    // Emission point
    canvas.drawCircle(
      Offset(emissionX, cy),
      8,
      Paint()..color = Colors.blue,
    );

    // Emission indicator
    canvas.drawCircle(
      Offset(emissionX, cy),
      12,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Radius indicator line
    canvas.drawLine(
      Offset(cx, cy),
      Offset(emissionX, cy),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
  }

  void _drawPhotonPath(Canvas canvas, double cx, double cy, Size size) {
    final baseRadius = 30 * math.sqrt(mass);
    final emissionX = cx + baseRadius * emissionRadius;
    final observerX = size.width - 50;

    // Animated photon position
    final progress = (time % 2) / 2;
    final photonX = emissionX + (observerX - emissionX) * progress;

    // Calculate color shift based on position
    final localRedshift = redshiftFactor * progress;
    final wavelengthFactor = 1 + localRedshift;

    // Blue to red gradient along path
    final startColor = Colors.blue;
    final endColor = Colors.red;
    final currentColor = Color.lerp(startColor, endColor, progress)!;

    // Photon trail
    final trailPath = Path()
      ..moveTo(emissionX, cy)
      ..lineTo(photonX, cy);

    final trailPaint = Paint()
      ..shader = LinearGradient(
        colors: [startColor, currentColor],
      ).createShader(Rect.fromPoints(Offset(emissionX, cy), Offset(photonX, cy)))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(trailPath, trailPaint);

    // Photon
    canvas.drawCircle(
      Offset(photonX, cy),
      6,
      Paint()..color = currentColor,
    );

    // Wave representation
    _drawWave(canvas, emissionX, cy - 30, photonX - emissionX, startColor, wavelengthFactor);
  }

  void _drawWave(Canvas canvas, double startX, double y, double length, Color color, double stretch) {
    if (length <= 0) return;

    final wavePath = Path();
    final wavelength = 20.0 * stretch;
    final amplitude = 10.0;

    for (double x = 0; x <= length; x += 2) {
      final wx = startX + x;
      final wy = y + amplitude * math.sin(x * 2 * math.pi / wavelength);
      if (x == 0) {
        wavePath.moveTo(wx, wy);
      } else {
        wavePath.lineTo(wx, wy);
      }
    }

    // Color transitions from blue to red
    final t = (stretch - 1).clamp(0.0, 1.0);
    final waveColor = Color.lerp(Colors.blue, Colors.red, t)!;

    canvas.drawPath(
      wavePath,
      Paint()
        ..color = waveColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawObserver(Canvas canvas, Size size) {
    final observerX = size.width - 50;
    final observerY = size.height / 2;

    // Observer (telescope/eye)
    canvas.drawCircle(
      Offset(observerX, observerY),
      15,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      Offset(observerX, observerY),
      6,
      Paint()..color = Colors.grey,
    );
  }

  void _drawSpectrumComparison(Canvas canvas, Size size) {
    final barWidth = 100.0;
    final barHeight = 15.0;
    final leftX = size.width - barWidth - 30;

    // Emitted spectrum (blue)
    final emittedY = size.height - 70;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(leftX, emittedY, barWidth, barHeight),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.blue,
    );

    // Observed spectrum (redshifted)
    final observedY = size.height - 45;
    final observedColor = Color.lerp(Colors.blue, Colors.red, (redshiftFactor / 2).clamp(0.0, 1.0))!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(leftX, observedY, barWidth, barHeight),
        const Radius.circular(3),
      ),
      Paint()..color = observedColor,
    );

    // Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: isKorean ? '방출' : 'Emitted',
      style: const TextStyle(color: Colors.white70, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(leftX - textPainter.width - 5, emittedY + 2));

    textPainter.text = TextSpan(
      text: isKorean ? '관측' : 'Observed',
      style: const TextStyle(color: Colors.white70, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(leftX - textPainter.width - 5, observedY + 2));
  }

  void _drawLabels(Canvas canvas, Size size, double cx, double cy) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Mass label
    textPainter.text = TextSpan(
      text: isKorean ? '대질량 천체' : 'Massive Object',
      style: const TextStyle(color: Colors.red, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy + 50));

    // Emission radius
    final baseRadius = 30 * math.sqrt(mass);
    final emissionX = cx + baseRadius * emissionRadius;
    textPainter.text = TextSpan(
      text: 'r = ${emissionRadius.toStringAsFixed(1)} rs',
      style: const TextStyle(color: Colors.blue, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(emissionX - textPainter.width / 2, cy + 25));

    // Redshift indicator
    textPainter.text = TextSpan(
      text: 'z = ${redshiftFactor.toStringAsFixed(3)}',
      style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 10));
  }

  @override
  bool shouldRepaint(covariant GravitationalRedshiftPainter oldDelegate) {
    return mass != oldDelegate.mass ||
        emissionRadius != oldDelegate.emissionRadius ||
        time != oldDelegate.time;
  }
}
