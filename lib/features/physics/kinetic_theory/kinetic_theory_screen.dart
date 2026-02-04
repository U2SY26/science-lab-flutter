import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Kinetic Theory simulation: KE_avg = (3/2)kT
class KineticTheoryScreen extends StatefulWidget {
  const KineticTheoryScreen({super.key});

  @override
  State<KineticTheoryScreen> createState() => _KineticTheoryScreenState();
}

class _KineticTheoryScreenState extends State<KineticTheoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  // Parameters
  double temperature = 300.0; // Kelvin
  int particleCount = 50;
  List<_Particle> particles = [];

  // Constants
  static const double kBoltzmann = 1.38e-23; // J/K

  bool isRunning = true;
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _initParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);
    _controller.repeat();
  }

  void _initParticles() {
    particles = List.generate(particleCount, (i) {
      final speed = _getSpeedFromTemperature();
      final angle = _random.nextDouble() * 2 * math.pi;
      return _Particle(
        x: 50 + _random.nextDouble() * 250,
        y: 50 + _random.nextDouble() * 200,
        vx: speed * math.cos(angle),
        vy: speed * math.sin(angle),
        radius: 4,
      );
    });
  }

  double _getSpeedFromTemperature() {
    // v_rms = sqrt(3kT/m), scaled for visualization
    return math.sqrt(temperature / 100) * 2;
  }

  void _updatePhysics() {
    if (!isRunning) return;

    setState(() {
      for (var p in particles) {
        // Update position
        p.x += p.vx;
        p.y += p.vy;

        // Wall collisions (assuming container 50-300 x, 50-250 y)
        if (p.x < 50 + p.radius || p.x > 300 - p.radius) {
          p.vx = -p.vx;
          p.x = p.x.clamp(50 + p.radius, 300 - p.radius);
        }
        if (p.y < 50 + p.radius || p.y > 250 - p.radius) {
          p.vy = -p.vy;
          p.y = p.y.clamp(50 + p.radius, 250 - p.radius);
        }
      }

      // Particle collisions (simplified)
      for (int i = 0; i < particles.length; i++) {
        for (int j = i + 1; j < particles.length; j++) {
          final p1 = particles[i];
          final p2 = particles[j];
          final dx = p2.x - p1.x;
          final dy = p2.y - p1.y;
          final dist = math.sqrt(dx * dx + dy * dy);

          if (dist < p1.radius + p2.radius) {
            // Simple elastic collision
            final tempVx = p1.vx;
            final tempVy = p1.vy;
            p1.vx = p2.vx;
            p1.vy = p2.vy;
            p2.vx = tempVx;
            p2.vy = tempVy;

            // Separate particles
            final overlap = p1.radius + p2.radius - dist;
            final nx = dx / dist;
            final ny = dy / dist;
            p1.x -= nx * overlap / 2;
            p1.y -= ny * overlap / 2;
            p2.x += nx * overlap / 2;
            p2.y += ny * overlap / 2;
          }
        }
      }
    });
  }

  void _updateTemperature(double newTemp) {
    final oldTemp = temperature;
    temperature = newTemp;

    // Scale velocities according to temperature change
    final scaleFactor = math.sqrt(newTemp / oldTemp);
    for (var p in particles) {
      p.vx *= scaleFactor;
      p.vy *= scaleFactor;
    }
  }

  double get averageKE {
    if (particles.isEmpty) return 0;
    double totalKE = 0;
    for (var p in particles) {
      final v2 = p.vx * p.vx + p.vy * p.vy;
      totalKE += 0.5 * v2; // mass = 1 for simplicity
    }
    return totalKE / particles.length;
  }

  double get theoreticalKE => 1.5 * kBoltzmann * temperature * 1e23; // Scaled

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      temperature = 300;
      _initParticles();
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
              isKorean ? '기체 분자 운동론' : 'Kinetic Theory of Gases',
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
          title: isKorean ? '기체 분자 운동론' : 'Kinetic Theory',
          formula: 'KE_avg = (3/2)kT',
          formulaDescription: isKorean
              ? '기체 분자의 평균 운동에너지는 절대온도에 비례합니다. k는 볼츠만 상수입니다.'
              : 'Average kinetic energy of gas molecules is proportional to absolute temperature. k is Boltzmann constant.',
          simulation: CustomPaint(
            painter: _KineticTheoryPainter(
              particles: particles,
              temperature: temperature,
              isKorean: isKorean,
            ),
            size: Size.infinite,
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PresetGroup(
                label: isKorean ? '온도 프리셋' : 'Temperature Presets',
                presets: [
                  PresetButton(
                    label: isKorean ? '차가움 (100K)' : 'Cold (100K)',
                    isSelected: (temperature - 100).abs() < 10,
                    onPressed: () => setState(() => _updateTemperature(100)),
                  ),
                  PresetButton(
                    label: isKorean ? '상온 (300K)' : 'Room (300K)',
                    isSelected: (temperature - 300).abs() < 10,
                    onPressed: () => setState(() => _updateTemperature(300)),
                  ),
                  PresetButton(
                    label: isKorean ? '뜨거움 (600K)' : 'Hot (600K)',
                    isSelected: (temperature - 600).abs() < 10,
                    onPressed: () => setState(() => _updateTemperature(600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '온도 (T)' : 'Temperature (T)',
                  value: temperature,
                  min: 50,
                  max: 800,
                  defaultValue: 300,
                  formatValue: (v) => '${v.toStringAsFixed(0)} K',
                  onChanged: (v) => setState(() => _updateTemperature(v)),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '입자 수' : 'Particle Count',
                    value: particleCount.toDouble(),
                    min: 10,
                    max: 100,
                    defaultValue: 50,
                    formatValue: (v) => v.toInt().toString(),
                    onChanged: (v) => setState(() {
                      particleCount = v.toInt();
                      _initParticles();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _KineticInfo(
                temperature: temperature,
                averageKE: averageKE,
                particleCount: particleCount,
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
                    : (isKorean ? '재생' : 'Play'),
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => isRunning = !isRunning);
                },
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

class _Particle {
  double x, y, vx, vy;
  double radius;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
  });
}

class _KineticInfo extends StatelessWidget {
  final double temperature;
  final double averageKE;
  final int particleCount;
  final bool isKorean;

  const _KineticInfo({
    required this.temperature,
    required this.averageKE,
    required this.particleCount,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    final vrms = math.sqrt(averageKE * 2);

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
                label: isKorean ? '평균 KE' : 'Avg KE',
                value: averageKE.toStringAsFixed(2),
                color: AppColors.accent,
              ),
              _InfoItem(
                label: isKorean ? 'v_rms' : 'v_rms',
                value: vrms.toStringAsFixed(2),
                color: AppColors.accent2,
              ),
              _InfoItem(
                label: isKorean ? '입자 수' : 'Particles',
                value: particleCount.toString(),
                color: AppColors.ink,
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
              'KE_avg = (3/2) × k × ${temperature.toStringAsFixed(0)}K',
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

class _KineticTheoryPainter extends CustomPainter {
  final List<_Particle> particles;
  final double temperature;
  final bool isKorean;

  _KineticTheoryPainter({
    required this.particles,
    required this.temperature,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    // Container
    final containerRect = Rect.fromLTWH(50, 50, 250, 200);
    canvas.drawRect(
      containerRect,
      Paint()
        ..color = AppColors.cardBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Container fill (slight tint based on temperature)
    final tempColor = _getTemperatureColor();
    canvas.drawRect(
      containerRect,
      Paint()..color = tempColor.withValues(alpha: 0.1),
    );

    // Draw particles
    for (var p in particles) {
      final speed = math.sqrt(p.vx * p.vx + p.vy * p.vy);
      final color = _getSpeedColor(speed);

      // Particle
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.radius,
        Paint()..color = color,
      );

      // Velocity vector (small)
      canvas.drawLine(
        Offset(p.x, p.y),
        Offset(p.x + p.vx * 3, p.y + p.vy * 3),
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }

    // Temperature indicator
    _drawThermometer(canvas, Offset(size.width - 60, 50), 150);

    // Speed distribution histogram (simplified)
    _drawSpeedHistogram(canvas, Offset(50, size.height - 80), 250, 60);

    // Labels
    _drawText(canvas, isKorean ? '기체 분자' : 'Gas Molecules',
        Offset(containerRect.left + 5, containerRect.top + 5), AppColors.muted, 10);
  }

  Color _getTemperatureColor() {
    if (temperature < 200) return Colors.blue;
    if (temperature < 400) return Colors.orange;
    return Colors.red;
  }

  Color _getSpeedColor(double speed) {
    final normalizedSpeed = (speed / 5).clamp(0.0, 1.0);
    return Color.lerp(Colors.blue, Colors.red, normalizedSpeed)!;
  }

  void _drawThermometer(Canvas canvas, Offset position, double height) {
    final normalizedTemp = ((temperature - 50) / 750).clamp(0.0, 1.0);
    final fillHeight = height * normalizedTemp;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx, position.dy, 25, height),
        const Radius.circular(12),
      ),
      Paint()..color = AppColors.cardBorder,
    );

    // Fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx + 4, position.dy + height - fillHeight + 4, 17, fillHeight - 8),
        const Radius.circular(8),
      ),
      Paint()..color = _getTemperatureColor(),
    );

    // Label
    _drawText(canvas, '${temperature.toStringAsFixed(0)}K',
        Offset(position.dx - 5, position.dy + height + 10), AppColors.ink, 11);
  }

  void _drawSpeedHistogram(Canvas canvas, Offset position, double width, double height) {
    // Calculate speed distribution
    final List<int> bins = List.filled(10, 0);
    for (var p in particles) {
      final speed = math.sqrt(p.vx * p.vx + p.vy * p.vy);
      final binIndex = ((speed / 6) * 10).clamp(0, 9).toInt();
      bins[binIndex]++;
    }

    final maxCount = bins.reduce(math.max);
    if (maxCount == 0) return;

    final binWidth = width / 10;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx - 5, position.dy - 5, width + 10, height + 20),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.card.withValues(alpha: 0.5),
    );

    // Bars
    for (int i = 0; i < bins.length; i++) {
      final barHeight = (bins[i] / maxCount) * (height - 15);
      final color = _getSpeedColor(i * 0.6);

      canvas.drawRect(
        Rect.fromLTWH(
          position.dx + i * binWidth + 2,
          position.dy + height - 15 - barHeight,
          binWidth - 4,
          barHeight,
        ),
        Paint()..color = color,
      );
    }

    // Axis
    canvas.drawLine(
      Offset(position.dx, position.dy + height - 15),
      Offset(position.dx + width, position.dy + height - 15),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 1,
    );

    // Labels
    _drawText(canvas, isKorean ? '속력 분포' : 'Speed Distribution',
        Offset(position.dx, position.dy - 18), AppColors.muted, 9);
    _drawText(canvas, isKorean ? '느림' : 'Slow',
        Offset(position.dx, position.dy + height), AppColors.muted, 8);
    _drawText(canvas, isKorean ? '빠름' : 'Fast',
        Offset(position.dx + width - 25, position.dy + height), AppColors.muted, 8);
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
  bool shouldRepaint(covariant _KineticTheoryPainter oldDelegate) => true;
}
