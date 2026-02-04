import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Water Cycle Simulation
class WaterCycleScreen extends StatefulWidget {
  const WaterCycleScreen({super.key});

  @override
  State<WaterCycleScreen> createState() => _WaterCycleScreenState();
}

class _WaterCycleScreenState extends State<WaterCycleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _time = 0.0;
  double _temperature = 25.0; // Celsius
  bool _isAnimating = true;
  bool _showLabels = true;
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

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _temperature = 25.0;
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
              _isKorean ? '지구과학 시뮬레이션' : 'EARTH SCIENCE SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '물의 순환' : 'Water Cycle',
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
          title: _isKorean ? '물의 순환' : 'Water Cycle',
          formula: _isKorean ? '증발 → 응결 → 강수 → 유출' : 'Evaporation → Condensation → Precipitation → Runoff',
          formulaDescription: _isKorean
              ? '물은 태양 에너지에 의해 증발하고, 대기에서 응결하여 구름을 형성하며, 강수로 지표면에 돌아옵니다. 이 과정이 지구의 물 순환입니다.'
              : 'Water evaporates due to solar energy, condenses in the atmosphere to form clouds, and returns to the surface as precipitation. This is Earth\'s water cycle.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: WaterCyclePainter(
                time: _time,
                temperature: _temperature,
                showLabels: _showLabels,
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
                  label: _isKorean ? '온도' : 'Temperature',
                  value: _temperature,
                  min: 10,
                  max: 40,
                  defaultValue: 25,
                  formatValue: (v) => '${v.toStringAsFixed(0)}°C',
                  onChanged: (v) => setState(() => _temperature = v),
                ),
                advancedControls: [
                  SimToggle(
                    label: _isKorean ? '라벨 표시' : 'Show Labels',
                    value: _showLabels,
                    onChanged: (v) => setState(() => _showLabels = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(temperature: _temperature, isKorean: _isKorean),
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
  final double temperature;
  final bool isKorean;

  const _InfoCard({required this.temperature, required this.isKorean});

  @override
  Widget build(BuildContext context) {
    final evaporationRate = (temperature - 10) / 30;

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
              Icon(Icons.water_drop, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                isKorean ? '증발률' : 'Evaporation Rate',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(evaporationRate * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? '높은 온도 → 더 많은 증발 → 더 많은 구름 → 더 많은 강수'
                : 'Higher temp → More evaporation → More clouds → More precipitation',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class WaterCyclePainter extends CustomPainter {
  final double time;
  final double temperature;
  final bool showLabels;
  final bool isKorean;

  WaterCyclePainter({
    required this.time,
    required this.temperature,
    required this.showLabels,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient (sky)
    _drawSky(canvas, size);

    // Sun
    _drawSun(canvas, size);

    // Mountains
    _drawMountains(canvas, size);

    // Ocean
    _drawOcean(canvas, size);

    // Clouds
    _drawClouds(canvas, size);

    // Evaporation
    _drawEvaporation(canvas, size);

    // Precipitation (rain/snow)
    _drawPrecipitation(canvas, size);

    // Runoff and groundwater
    _drawRunoff(canvas, size);

    // Labels
    if (showLabels) {
      _drawLabels(canvas, size);
    }
  }

  void _drawSky(Canvas canvas, Size size) {
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF1E90FF),
        const Color(0xFF87CEEB),
        const Color(0xFFB0E0E6),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.6));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.6),
      Paint()..shader = skyGradient,
    );
  }

  void _drawSun(Canvas canvas, Size size) {
    final sunX = size.width * 0.85;
    final sunY = size.height * 0.15;
    final sunRadius = 30.0 + (temperature - 25) * 0.5;

    // Sun glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700),
          const Color(0xFFFF8C00).withValues(alpha: 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: sunRadius * 2));
    canvas.drawCircle(Offset(sunX, sunY), sunRadius * 2, glowPaint);

    // Sun body
    canvas.drawCircle(Offset(sunX, sunY), sunRadius, Paint()..color = const Color(0xFFFFD700));

    // Sun rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.6)
      ..strokeWidth = 2;

    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 + time * 0.2;
      final innerR = sunRadius + 5;
      final outerR = sunRadius + 15;
      canvas.drawLine(
        Offset(sunX + innerR * math.cos(angle), sunY + innerR * math.sin(angle)),
        Offset(sunX + outerR * math.cos(angle), sunY + outerR * math.sin(angle)),
        rayPaint,
      );
    }
  }

  void _drawMountains(Canvas canvas, Size size) {
    // Background mountain
    final mountain1 = Path()
      ..moveTo(size.width * 0.3, size.height * 0.6)
      ..lineTo(size.width * 0.5, size.height * 0.25)
      ..lineTo(size.width * 0.7, size.height * 0.6)
      ..close();

    canvas.drawPath(
      mountain1,
      Paint()..color = const Color(0xFF4A5568),
    );

    // Snow cap
    final snowCap = Path()
      ..moveTo(size.width * 0.45, size.height * 0.35)
      ..lineTo(size.width * 0.5, size.height * 0.25)
      ..lineTo(size.width * 0.55, size.height * 0.35)
      ..close();

    canvas.drawPath(snowCap, Paint()..color = Colors.white);

    // Foreground hill
    final hill = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.15, size.height * 0.5, size.width * 0.3, size.height * 0.6)
      ..lineTo(0, size.height * 0.6)
      ..close();

    canvas.drawPath(hill, Paint()..color = const Color(0xFF228B22));
  }

  void _drawOcean(Canvas canvas, Size size) {
    // Ocean body
    final oceanGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF1E90FF),
        const Color(0xFF0066CC),
      ],
    ).createShader(Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4));

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
      Paint()..shader = oceanGradient,
    );

    // Waves
    final wavePath = Path();
    wavePath.moveTo(0, size.height * 0.6);

    for (double x = 0; x <= size.width; x += 5) {
      final waveY = size.height * 0.6 + math.sin(x * 0.02 + time * 2) * 5;
      wavePath.lineTo(x, waveY);
    }
    wavePath.lineTo(size.width, size.height * 0.65);
    wavePath.lineTo(0, size.height * 0.65);
    wavePath.close();

    canvas.drawPath(
      wavePath,
      Paint()..color = const Color(0xFF4169E1).withValues(alpha: 0.5),
    );
  }

  void _drawClouds(Canvas canvas, Size size) {
    final cloudCount = ((temperature - 10) / 5).floor().clamp(1, 5);

    for (int i = 0; i < cloudCount; i++) {
      final cloudX = (size.width * 0.2 + i * size.width * 0.15 + time * 10) % (size.width + 100) - 50;
      final cloudY = size.height * 0.1 + i * 20 + math.sin(time + i) * 5;

      _drawCloud(canvas, cloudX, cloudY, 1.0 + i * 0.2);
    }
  }

  void _drawCloud(Canvas canvas, double x, double y, double scale) {
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);

    // Cloud puffs
    canvas.drawCircle(Offset(x, y), 20 * scale, cloudPaint);
    canvas.drawCircle(Offset(x - 20 * scale, y + 5), 15 * scale, cloudPaint);
    canvas.drawCircle(Offset(x + 20 * scale, y + 5), 15 * scale, cloudPaint);
    canvas.drawCircle(Offset(x - 10 * scale, y - 10), 12 * scale, cloudPaint);
    canvas.drawCircle(Offset(x + 10 * scale, y - 10), 12 * scale, cloudPaint);
  }

  void _drawEvaporation(Canvas canvas, Size size) {
    final evaporationRate = (temperature - 10) / 30;
    final particleCount = (evaporationRate * 20).toInt();

    for (int i = 0; i < particleCount; i++) {
      final startX = size.width * 0.1 + (i / particleCount) * size.width * 0.6;
      final progress = (time * 0.5 + i * 0.1) % 1.0;
      final y = size.height * 0.6 - progress * size.height * 0.4;

      // Wavy path for vapor
      final x = startX + math.sin(progress * 10 + i) * 10;

      // Fade out as it rises
      final alpha = (1 - progress) * 0.5;

      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }

    // Evaporation arrows (visible heat waves)
    for (int i = 0; i < 5; i++) {
      final arrowX = size.width * 0.15 + i * size.width * 0.15;
      final arrowY = size.height * 0.55 - math.sin(time * 2 + i) * 10;

      _drawUpArrow(canvas, arrowX, arrowY, Colors.white.withValues(alpha: 0.3));
    }
  }

  void _drawUpArrow(Canvas canvas, double x, double y, Color color) {
    final arrowPath = Path()
      ..moveTo(x, y)
      ..lineTo(x - 5, y + 10)
      ..lineTo(x + 5, y + 10)
      ..close();

    canvas.drawPath(arrowPath, Paint()..color = color);
  }

  void _drawPrecipitation(Canvas canvas, Size size) {
    final precipitationRate = (temperature - 10) / 30;
    final dropCount = (precipitationRate * 30).toInt();

    for (int i = 0; i < dropCount; i++) {
      final startX = size.width * 0.2 + (i / dropCount) * size.width * 0.4;
      final progress = (time * 2 + i * 0.1) % 1.0;
      final y = size.height * 0.15 + progress * size.height * 0.45;
      final x = startX + math.sin(i.toDouble()) * 20;

      // Rain drops
      if (temperature > 5) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x - 2, y + 10),
          Paint()
            ..color = const Color(0xFF1E90FF).withValues(alpha: 0.7)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      } else {
        // Snow flakes
        canvas.drawCircle(
          Offset(x, y),
          3,
          Paint()..color = Colors.white.withValues(alpha: 0.8),
        );
      }
    }
  }

  void _drawRunoff(Canvas canvas, Size size) {
    // River/stream from mountain
    final riverPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.45,
        size.width * 0.4,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.58,
        size.width * 0.3,
        size.height * 0.6,
      );

    canvas.drawPath(
      riverPath,
      Paint()
        ..color = const Color(0xFF4169E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    // Groundwater arrows (underground)
    for (int i = 0; i < 3; i++) {
      final arrowX = size.width * 0.3 + i * size.width * 0.15;
      final arrowY = size.height * 0.75;

      canvas.drawLine(
        Offset(arrowX, arrowY),
        Offset(arrowX - 15, arrowY + 15),
        Paint()
          ..color = const Color(0xFF1E90FF).withValues(alpha: 0.4)
          ..strokeWidth = 2,
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final labels = isKorean
        ? [
            [size.width * 0.1, size.height * 0.45, '증발'],
            [size.width * 0.35, size.height * 0.08, '응결'],
            [size.width * 0.45, size.height * 0.25, '강수'],
            [size.width * 0.4, size.height * 0.5, '유출'],
            [size.width * 0.4, size.height * 0.8, '지하수'],
          ]
        : [
            [size.width * 0.08, size.height * 0.45, 'Evaporation'],
            [size.width * 0.3, size.height * 0.08, 'Condensation'],
            [size.width * 0.45, size.height * 0.25, 'Precipitation'],
            [size.width * 0.38, size.height * 0.5, 'Runoff'],
            [size.width * 0.35, size.height * 0.8, 'Groundwater'],
          ];

    for (final label in labels) {
      textPainter.text = TextSpan(
        text: label[2] as String,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(label[0] as double, label[1] as double));
    }
  }

  @override
  bool shouldRepaint(covariant WaterCyclePainter oldDelegate) {
    return time != oldDelegate.time ||
        temperature != oldDelegate.temperature ||
        showLabels != oldDelegate.showLabels;
  }
}
