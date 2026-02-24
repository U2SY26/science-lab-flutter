import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Photosynthesis Simulation
class PhotosynthesisScreen extends ConsumerStatefulWidget {
  const PhotosynthesisScreen({super.key});

  @override
  ConsumerState<PhotosynthesisScreen> createState() => _PhotosynthesisScreenState();
}

class _PhotosynthesisScreenState extends ConsumerState<PhotosynthesisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  // Photosynthesis parameters
  double _lightIntensity = 50.0; // 0-100%
  double _co2Level = 400.0; // ppm
  double _temperature = 25.0; // Celsius

  // State
  bool _isRunning = false;
  double _oxygenProduced = 0.0;
  double _glucoseProduced = 0.0;

  // Animation particles
  List<Particle> _photons = [];
  List<Particle> _co2Particles = [];
  List<Particle> _o2Particles = [];
  List<Particle> _waterParticles = [];

  // Graph history
  final List<double> _oxygenHistory = [];
  final List<double> _glucoseHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateSimulation);
  }

  void _initializeParticles() {
    _photons = List.generate(10, (i) => Particle(
      x: _random.nextDouble(),
      y: 0,
      vx: 0,
      vy: 0.02,
      color: Colors.yellow,
    ));

    _co2Particles = List.generate(5, (i) => Particle(
      x: 0,
      y: 0.5 + _random.nextDouble() * 0.3,
      vx: 0.01,
      vy: (_random.nextDouble() - 0.5) * 0.01,
      color: Colors.grey,
    ));

    _waterParticles = List.generate(5, (i) => Particle(
      x: 0.5 + _random.nextDouble() * 0.3,
      y: 1,
      vx: 0,
      vy: -0.01,
      color: Colors.blue,
    ));

    _o2Particles = [];
  }

  double _calculatePhotosynthesisRate() {
    // Simplified rate equation considering limiting factors
    // Rate limited by light, CO2, and temperature

    // Light response (hyperbolic)
    final lightFactor = _lightIntensity / (20 + _lightIntensity);

    // CO2 response (hyperbolic)
    final co2Factor = _co2Level / (200 + _co2Level);

    // Temperature response (bell curve, optimal around 25-30C)
    final tempFactor = math.exp(-math.pow(_temperature - 27.5, 2) / 200);

    return lightFactor * co2Factor * tempFactor;
  }

  void _updateSimulation() {
    if (!_isRunning) return;

    setState(() {
      final rate = _calculatePhotosynthesisRate();

      // Update production
      _oxygenProduced += rate * 0.1;
      _glucoseProduced += rate * 0.05;

      // Record history
      _oxygenHistory.add(_oxygenProduced);
      _glucoseHistory.add(_glucoseProduced);
      if (_oxygenHistory.length > 200) {
        _oxygenHistory.removeAt(0);
        _glucoseHistory.removeAt(0);
      }

      // Update photons
      for (int i = 0; i < _photons.length; i++) {
        _photons[i].y += _photons[i].vy * (_lightIntensity / 50);
        if (_photons[i].y > 0.7) {
          _photons[i].y = 0;
          _photons[i].x = _random.nextDouble();
        }
      }

      // Update CO2 particles
      for (int i = 0; i < _co2Particles.length; i++) {
        _co2Particles[i].x += _co2Particles[i].vx;
        _co2Particles[i].y += _co2Particles[i].vy;
        if (_co2Particles[i].x > 0.5) {
          _co2Particles[i].x = 0;
          _co2Particles[i].y = 0.5 + _random.nextDouble() * 0.3;
        }
      }

      // Update water particles
      for (int i = 0; i < _waterParticles.length; i++) {
        _waterParticles[i].y += _waterParticles[i].vy;
        if (_waterParticles[i].y < 0.5) {
          _waterParticles[i].y = 1;
          _waterParticles[i].x = 0.4 + _random.nextDouble() * 0.2;
        }
      }

      // Generate O2 based on rate
      if (_random.nextDouble() < rate * 0.3) {
        _o2Particles.add(Particle(
          x: 0.5 + (_random.nextDouble() - 0.5) * 0.2,
          y: 0.3,
          vx: (_random.nextDouble() - 0.3) * 0.02,
          vy: -0.015,
          color: Colors.cyan,
        ));
      }

      // Update O2 particles
      _o2Particles = _o2Particles.where((p) {
        p.x += p.vx;
        p.y += p.vy;
        return p.y > 0 && p.x > 0 && p.x < 1;
      }).toList();

      // Limit O2 particles
      if (_o2Particles.length > 20) {
        _o2Particles.removeAt(0);
      }
    });
  }

  void _toggleRunning() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = false;
      _controller.stop();
      _oxygenProduced = 0.0;
      _glucoseProduced = 0.0;
      _oxygenHistory.clear();
      _glucoseHistory.clear();
      _o2Particles.clear();
      _initializeParticles();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);
    final rate = _calculatePhotosynthesisRate();

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
              isKorean ? '생물학' : 'BIOLOGY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '광합성' : 'Photosynthesis',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '생물학' : 'Biology',
          title: isKorean ? '광합성' : 'Photosynthesis',
          formula: '6CO2 + 6H2O + light -> C6H12O6 + 6O2',
          formulaDescription: isKorean
              ? '광합성은 빛 에너지를 이용해 이산화탄소와 물을 포도당과 산소로 변환합니다.'
              : 'Photosynthesis uses light energy to convert carbon dioxide and water into glucose and oxygen.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PhotosynthesisPainter(
                photons: _photons,
                co2Particles: _co2Particles,
                waterParticles: _waterParticles,
                o2Particles: _o2Particles,
                oxygenHistory: _oxygenHistory,
                rate: rate,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status info
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
                          label: isKorean ? '광합성 속도' : 'Rate',
                          value: '${(rate * 100).toStringAsFixed(1)}%',
                          color: Colors.green,
                        ),
                        _InfoItem(
                          label: isKorean ? 'O2 생성' : 'O2 Produced',
                          value: _oxygenProduced.toStringAsFixed(1),
                          color: Colors.cyan,
                        ),
                        _InfoItem(
                          label: isKorean ? '포도당' : 'Glucose',
                          value: _glucoseProduced.toStringAsFixed(2),
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Rate indicator
                    Row(
                      children: [
                        Icon(
                          Icons.speed,
                          size: 16,
                          color: rate > 0.5 ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: rate,
                            backgroundColor: AppColors.cardBorder,
                            valueColor: AlwaysStoppedAnimation(
                              rate > 0.5 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Limiting factor indicator
              _buildLimitingFactorIndicator(isKorean),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '빛 강도 (%)' : 'Light Intensity (%)',
                  value: _lightIntensity,
                  min: 0,
                  max: 100,
                  defaultValue: 50,
                  formatValue: (v) => '${v.toInt()}%',
                  onChanged: (v) => setState(() => _lightIntensity = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? 'CO2 농도 (ppm)' : 'CO2 Level (ppm)',
                    value: _co2Level,
                    min: 100,
                    max: 1000,
                    defaultValue: 400,
                    formatValue: (v) => '${v.toInt()} ppm',
                    onChanged: (v) => setState(() => _co2Level = v),
                  ),
                  SimSlider(
                    label: isKorean ? '온도 (C)' : 'Temperature (C)',
                    value: _temperature,
                    min: 0,
                    max: 50,
                    defaultValue: 25,
                    formatValue: (v) => '${v.toInt()}C',
                    onChanged: (v) => setState(() => _temperature = v),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning
                    ? (isKorean ? '일시정지' : 'Pause')
                    : (isKorean ? '시작' : 'Start'),
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleRunning,
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

  Widget _buildLimitingFactorIndicator(bool isKorean) {
    // Determine limiting factor
    final lightFactor = _lightIntensity / (20 + _lightIntensity);
    final co2Factor = _co2Level / (200 + _co2Level);
    final tempFactor = math.exp(-math.pow(_temperature - 27.5, 2) / 200);

    String limitingFactor;
    Color factorColor;

    if (lightFactor <= co2Factor && lightFactor <= tempFactor) {
      limitingFactor = isKorean ? '빛 강도' : 'Light Intensity';
      factorColor = Colors.yellow;
    } else if (co2Factor <= tempFactor) {
      limitingFactor = isKorean ? 'CO2 농도' : 'CO2 Level';
      factorColor = Colors.grey;
    } else {
      limitingFactor = isKorean ? '온도' : 'Temperature';
      factorColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: factorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: factorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: factorColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${isKorean ? '제한 요인: ' : 'Limiting Factor: '}$limitingFactor',
              style: TextStyle(color: factorColor, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
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

class _PhotosynthesisPainter extends CustomPainter {
  final List<Particle> photons;
  final List<Particle> co2Particles;
  final List<Particle> waterParticles;
  final List<Particle> o2Particles;
  final List<double> oxygenHistory;
  final double rate;
  final bool isKorean;

  _PhotosynthesisPainter({
    required this.photons,
    required this.co2Particles,
    required this.waterParticles,
    required this.o2Particles,
    required this.oxygenHistory,
    required this.rate,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Sky background gradient
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.lightBlue[200]!, Colors.lightBlue[50]!],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * 0.6, size.height * 0.4),
      Paint()..shader = skyGradient.createShader(Rect.fromLTWH(0, 0, size.width * 0.6, size.height * 0.4)),
    );

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.7, size.width * 0.6, size.height * 0.3),
      Paint()..color = Colors.brown[300]!,
    );

    // Leaf (chloroplast)
    _drawLeaf(canvas, size);

    // Sun
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.1),
      30,
      Paint()..color = Colors.yellow,
    );

    // Draw photons (light rays)
    for (final photon in photons) {
      final x = photon.x * size.width * 0.4 + size.width * 0.1;
      final y = photon.y * size.height * 0.6;

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = Colors.yellow.withValues(alpha: 0.8),
      );

      // Light ray trail
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y - 15),
        Paint()
          ..color = Colors.yellow.withValues(alpha: 0.3)
          ..strokeWidth = 2,
      );
    }

    // Draw CO2 particles
    for (final particle in co2Particles) {
      final x = particle.x * size.width * 0.3;
      final y = particle.y * size.height;

      _drawMolecule(canvas, x, y, 'CO2', Colors.grey);
    }

    // Draw water particles
    for (final particle in waterParticles) {
      final x = particle.x * size.width * 0.6;
      final y = particle.y * size.height;

      _drawMolecule(canvas, x, y, 'H2O', Colors.blue);
    }

    // Draw O2 particles (output)
    for (final particle in o2Particles) {
      final x = particle.x * size.width * 0.6;
      final y = particle.y * size.height;

      _drawMolecule(canvas, x, y, 'O2', Colors.cyan);
    }

    // Draw rate graph on the right
    _drawRateGraph(canvas, Rect.fromLTWH(size.width * 0.65, 0, size.width * 0.35, size.height));

    // Labels
    _drawText(canvas, isKorean ? '빛 에너지' : 'Light Energy',
        Offset(size.width * 0.05, size.height * 0.02), Colors.orange, 10);
    _drawText(canvas, 'CO2', Offset(5, size.height * 0.45), Colors.grey, 10);
    _drawText(canvas, 'H2O', Offset(size.width * 0.45, size.height * 0.85), Colors.blue, 10);
    _drawText(canvas, 'O2', Offset(size.width * 0.45, size.height * 0.15), Colors.cyan, 10);
  }

  void _drawLeaf(Canvas canvas, Size size) {
    final leafPath = Path();
    final cx = size.width * 0.35;
    final cy = size.height * 0.5;
    final leafWidth = size.width * 0.25;
    final leafHeight = size.height * 0.35;

    // Leaf shape
    leafPath.moveTo(cx, cy - leafHeight / 2);
    leafPath.quadraticBezierTo(cx + leafWidth / 2, cy - leafHeight / 4, cx + leafWidth / 2, cy);
    leafPath.quadraticBezierTo(cx + leafWidth / 2, cy + leafHeight / 4, cx, cy + leafHeight / 2);
    leafPath.quadraticBezierTo(cx - leafWidth / 2, cy + leafHeight / 4, cx - leafWidth / 2, cy);
    leafPath.quadraticBezierTo(cx - leafWidth / 2, cy - leafHeight / 4, cx, cy - leafHeight / 2);

    // Leaf fill with gradient
    final leafGradient = RadialGradient(
      center: Alignment.center,
      radius: 1,
      colors: [
        Color.lerp(Colors.green[400], Colors.green[600], rate)!,
        Colors.green[800]!,
      ],
    );

    canvas.drawPath(leafPath, Paint()
      ..shader = leafGradient.createShader(Rect.fromCenter(center: Offset(cx, cy), width: leafWidth, height: leafHeight)));

    canvas.drawPath(leafPath, Paint()
      ..color = Colors.green[900]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Leaf veins
    final veinPaint = Paint()
      ..color = Colors.green[700]!.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(cx, cy - leafHeight / 2), Offset(cx, cy + leafHeight / 2), veinPaint);
    canvas.drawLine(Offset(cx, cy - leafHeight / 4), Offset(cx + leafWidth / 3, cy - leafHeight / 6), veinPaint);
    canvas.drawLine(Offset(cx, cy - leafHeight / 4), Offset(cx - leafWidth / 3, cy - leafHeight / 6), veinPaint);
    canvas.drawLine(Offset(cx, cy + leafHeight / 4), Offset(cx + leafWidth / 3, cy + leafHeight / 6), veinPaint);
    canvas.drawLine(Offset(cx, cy + leafHeight / 4), Offset(cx - leafWidth / 3, cy + leafHeight / 6), veinPaint);

    // Chloroplasts (small circles inside leaf)
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final r = leafWidth * 0.25;
      final x = cx + r * math.cos(angle);
      final y = cy + r * 0.6 * math.sin(angle);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 15, height: 8),
        Paint()..color = Colors.green[600]!.withValues(alpha: 0.7),
      );
    }
  }

  void _drawMolecule(Canvas canvas, double x, double y, String label, Color color) {
    canvas.drawCircle(Offset(x, y), 8, Paint()..color = color.withValues(alpha: 0.7));
    canvas.drawCircle(Offset(x, y), 8, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    _drawText(canvas, label, Offset(x - 8, y - 4), Colors.white, 8, fontWeight: FontWeight.bold);
  }

  void _drawRateGraph(Canvas canvas, Rect bounds) {
    // Background
    canvas.drawRect(bounds, Paint()..color = AppColors.simBg);

    final padding = 20.0;
    final graphWidth = bounds.width - padding * 2;
    final graphHeight = bounds.height - padding * 2;

    // Title
    _drawText(canvas, isKorean ? 'O2 생성량' : 'O2 Production',
        Offset(bounds.left + padding, bounds.top + 5), AppColors.accent, 10, fontWeight: FontWeight.bold);

    // Axes
    canvas.drawLine(
      Offset(bounds.left + padding, bounds.top + padding + 15),
      Offset(bounds.left + padding, bounds.bottom - padding),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );
    canvas.drawLine(
      Offset(bounds.left + padding, bounds.bottom - padding),
      Offset(bounds.right - padding, bounds.bottom - padding),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );

    if (oxygenHistory.isEmpty) return;

    final maxO2 = oxygenHistory.reduce(math.max);
    if (maxO2 == 0) return;

    // Draw graph
    final path = Path();
    for (int i = 0; i < oxygenHistory.length; i++) {
      final x = bounds.left + padding + (i / oxygenHistory.length) * graphWidth;
      final y = bounds.bottom - padding - (oxygenHistory[i] / maxO2) * (graphHeight - 20);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, Paint()
      ..color = Colors.cyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);

    // Current rate indicator
    final rateY = bounds.top + padding + 30;
    canvas.drawRect(
      Rect.fromLTWH(bounds.left + padding, rateY, graphWidth * rate, 10),
      Paint()..color = Colors.green.withValues(alpha: 0.5),
    );
    canvas.drawRect(
      Rect.fromLTWH(bounds.left + padding, rateY, graphWidth, 10),
      Paint()
        ..color = AppColors.muted
        ..style = PaintingStyle.stroke,
    );
    _drawText(canvas, isKorean ? '속도' : 'Rate',
        Offset(bounds.left + padding, rateY - 12), AppColors.muted, 9);
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
  bool shouldRepaint(covariant _PhotosynthesisPainter oldDelegate) => true;
}
