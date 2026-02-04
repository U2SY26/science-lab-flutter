import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Blackbody Radiation Simulation (Planck's Law)
/// 흑체 복사 시뮬레이션 (플랑크 법칙)
class BlackbodyScreen extends StatefulWidget {
  const BlackbodyScreen({super.key});

  @override
  State<BlackbodyScreen> createState() => _BlackbodyScreenState();
}

class _BlackbodyScreenState extends State<BlackbodyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const double _defaultTemperature = 5000.0;
  static const int _defaultShowClassical = 0;

  double temperature = _defaultTemperature;
  int showClassical = _defaultShowClassical; // 0: Planck only, 1: Both, 2: Classical only
  bool isRunning = true;

  double time = 0;
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
      time += 0.02;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      temperature = _defaultTemperature;
      showClassical = _defaultShowClassical;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBlackbodyColor(double temp) {
    // Approximate blackbody color based on temperature
    if (temp < 1000) return const Color(0xFFFF3300);
    if (temp < 2000) return const Color(0xFFFF6600);
    if (temp < 3000) return const Color(0xFFFF9933);
    if (temp < 4000) return const Color(0xFFFFCC66);
    if (temp < 5000) return const Color(0xFFFFFF99);
    if (temp < 6000) return const Color(0xFFFFFFFF);
    if (temp < 8000) return const Color(0xFFCCCCFF);
    if (temp < 10000) return const Color(0xFF9999FF);
    return const Color(0xFF6666FF);
  }

  @override
  Widget build(BuildContext context) {
    // Wien's displacement law: λ_max = b/T
    final wienConstant = 2.898e6; // nm·K
    final peakWavelength = wienConstant / temperature;

    // Stefan-Boltzmann: P = σT^4
    final stefanBoltzmann = 5.67e-8;
    final powerDensity = stefanBoltzmann * math.pow(temperature, 4);

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
              isKorean ? '양자역학 시뮬레이션' : 'QUANTUM MECHANICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '흑체 복사' : 'Blackbody Radiation',
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
            onPressed: () => setState(() => isKorean = !isKorean),
            tooltip: isKorean ? 'English' : '한국어',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '양자역학 시뮬레이션' : 'QUANTUM MECHANICS',
          title: isKorean ? '흑체 복사 (플랑크 법칙)' : 'Blackbody Radiation (Planck)',
          formula: 'B(ν,T) = (2hν³/c²) × 1/(e^(hν/kT)-1)',
          formulaDescription: isKorean
              ? '플랑크의 흑체 복사 법칙은 양자역학의 시작점입니다. '
                  '빈의 변위 법칙: λmax = b/T, 슈테판-볼츠만 법칙: P = σT⁴'
              : 'Planck\'s blackbody radiation law marks the beginning of quantum mechanics. '
                  'Wien\'s displacement: λmax = b/T, Stefan-Boltzmann: P = σT⁴',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: BlackbodyPainter(
                time: time,
                temperature: temperature,
                showClassical: showClassical,
                blackbodyColor: _getBlackbodyColor(temperature),
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimSegment<int>(
                label: isKorean ? '표시 모드' : 'Display Mode',
                options: {
                  0: isKorean ? '플랑크' : 'Planck',
                  1: isKorean ? '비교' : 'Compare',
                  2: isKorean ? '고전' : 'Classical',
                },
                selected: showClassical,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => showClassical = v);
                },
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '온도 (K)' : 'Temperature (K)',
                  value: temperature,
                  min: 1000,
                  max: 12000,
                  defaultValue: _defaultTemperature,
                  formatValue: (v) => '${v.toInt()} K',
                  onChanged: (v) => setState(() => temperature = v),
                ),
                advancedControls: const [],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                temperature: temperature,
                peakWavelength: peakWavelength,
                powerDensity: powerDensity,
                blackbodyColor: _getBlackbodyColor(temperature),
                isKorean: isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning
                    ? (isKorean ? '정지' : 'Pause')
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

class _PhysicsInfo extends StatelessWidget {
  final double temperature;
  final double peakWavelength;
  final double powerDensity;
  final Color blackbodyColor;
  final bool isKorean;

  const _PhysicsInfo({
    required this.temperature,
    required this.peakWavelength,
    required this.powerDensity,
    required this.blackbodyColor,
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
      child: Row(
        children: [
          _InfoItem(
            label: isKorean ? '온도' : 'Temp',
            value: '${temperature.toInt()} K',
          ),
          _InfoItem(
            label: 'λmax',
            value: '${peakWavelength.toInt()} nm',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  isKorean ? '색상' : 'Color',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 30,
                  height: 18,
                  decoration: BoxDecoration(
                    color: blackbodyColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: blackbodyColor.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
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

  const _InfoItem({required this.label, required this.value});

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
            style: const TextStyle(
              color: AppColors.accent,
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

class BlackbodyPainter extends CustomPainter {
  final double time;
  final double temperature;
  final int showClassical;
  final Color blackbodyColor;

  // Physical constants (scaled for visualization)
  static const double h = 6.626e-34; // Planck constant
  static const double c = 3e8; // Speed of light
  static const double k = 1.381e-23; // Boltzmann constant

  BlackbodyPainter({
    required this.time,
    required this.temperature,
    required this.showClassical,
    required this.blackbodyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawBlackbodyObject(canvas, size);
    _drawSpectrum(canvas, size);
    _drawAxes(canvas, size);
    _drawLabels(canvas, size);
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

  void _drawBlackbodyObject(Canvas canvas, Size size) {
    final objectX = size.width * 0.15;
    final objectY = size.height * 0.25;
    final radius = 40.0;

    // Outer glow based on temperature
    final glowRadius = radius + 20 + 10 * math.sin(time * 2);
    final glowGradient = RadialGradient(
      colors: [
        blackbodyColor.withValues(alpha: 0.6),
        blackbodyColor.withValues(alpha: 0.2),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(objectX, objectY), radius: glowRadius));

    canvas.drawCircle(
      Offset(objectX, objectY),
      glowRadius,
      Paint()..shader = glowGradient,
    );

    // Main blackbody object
    canvas.drawCircle(
      Offset(objectX, objectY),
      radius,
      Paint()..color = blackbodyColor,
    );

    // Temperature label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${temperature.toInt()} K',
        style: TextStyle(
          color: temperature > 6000 ? Colors.black : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(objectX - textPainter.width / 2, objectY - 6));

    // Emission waves
    for (int i = 0; i < 5; i++) {
      final waveRadius = radius + 20 + (time * 30 + i * 20) % 80;
      final alpha = 1.0 - ((waveRadius - radius - 20) / 80);

      canvas.drawCircle(
        Offset(objectX, objectY),
        waveRadius,
        Paint()
          ..color = blackbodyColor.withValues(alpha: alpha * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawSpectrum(Canvas canvas, Size size) {
    final graphLeft = size.width * 0.35;
    final graphRight = size.width - 30;
    final graphTop = size.height * 0.15;
    final graphBottom = size.height * 0.75;
    final graphWidth = graphRight - graphLeft;
    final graphHeight = graphBottom - graphTop;

    // Draw visible spectrum background
    _drawVisibleSpectrum(canvas, graphLeft, graphTop, graphWidth, graphHeight);

    // Calculate peak for normalization
    final wienConstant = 2.898e6;
    final peakWavelength = wienConstant / temperature;

    // Draw Planck curve
    if (showClassical != 2) {
      final planckPath = Path();
      bool started = false;

      for (double x = 0; x < graphWidth; x += 2) {
        final wavelength = 100 + (x / graphWidth) * 2400; // 100nm to 2500nm
        final intensity = _planckIntensity(wavelength, temperature, peakWavelength);
        final screenY = graphBottom - intensity * graphHeight * 0.9;

        if (!started) {
          planckPath.moveTo(graphLeft + x, screenY);
          started = true;
        } else {
          planckPath.lineTo(graphLeft + x, screenY);
        }
      }

      // Glow effect
      canvas.drawPath(
        planckPath,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.3)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke,
      );

      canvas.drawPath(
        planckPath,
        Paint()
          ..color = AppColors.accent
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
    }

    // Draw Rayleigh-Jeans (classical) curve
    if (showClassical >= 1) {
      final classicalPath = Path();
      bool started = false;

      for (double x = 0; x < graphWidth; x += 2) {
        final wavelength = 100 + (x / graphWidth) * 2400;
        final intensity = _rayleighJeansIntensity(wavelength, temperature, peakWavelength);
        final clampedIntensity = intensity.clamp(0.0, 1.5);
        final screenY = graphBottom - clampedIntensity * graphHeight * 0.9;

        if (!started) {
          classicalPath.moveTo(graphLeft + x, screenY);
          started = true;
        } else {
          classicalPath.lineTo(graphLeft + x, screenY);
        }
      }

      canvas.drawPath(
        classicalPath,
        Paint()
          ..color = const Color(0xFFFC8181)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );

      // UV catastrophe label
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'UV Catastrophe!',
          style: TextStyle(
            color: const Color(0xFFFC8181),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(graphLeft + 10, graphTop - 15));
    }

    // Draw peak wavelength marker
    if (showClassical != 2) {
      final peakX = graphLeft + ((peakWavelength - 100) / 2400) * graphWidth;
      if (peakX > graphLeft && peakX < graphRight) {
        canvas.drawLine(
          Offset(peakX, graphTop),
          Offset(peakX, graphBottom),
          Paint()
            ..color = const Color(0xFF48BB78).withValues(alpha: 0.5)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: 'λmax',
            style: TextStyle(
              color: const Color(0xFF48BB78),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(peakX - 12, graphBottom + 5));
      }
    }
  }

  void _drawVisibleSpectrum(Canvas canvas, double left, double top, double width, double height) {
    // Visible spectrum: ~380nm to ~750nm
    final visibleStart = ((380 - 100) / 2400) * width;
    final visibleEnd = ((750 - 100) / 2400) * width;

    final colors = [
      const Color(0xFF9400D3), // Violet 380nm
      const Color(0xFF4B0082), // Indigo
      const Color(0xFF0000FF), // Blue 450nm
      const Color(0xFF00FF00), // Green 520nm
      const Color(0xFFFFFF00), // Yellow 570nm
      const Color(0xFFFF7F00), // Orange 590nm
      const Color(0xFFFF0000), // Red 750nm
    ];

    final gradient = LinearGradient(
      colors: colors,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(left + visibleStart, top, visibleEnd - visibleStart, height));

    canvas.drawRect(
      Rect.fromLTWH(left + visibleStart, top, visibleEnd - visibleStart, height),
      Paint()
        ..shader = gradient
        ..color = Colors.white.withValues(alpha: 0.15),
    );
  }

  double _planckIntensity(double wavelength, double temp, double peakWavelength) {
    // Simplified Planck function normalized to peak
    final x = peakWavelength / wavelength;
    final expTerm = math.exp(5 * (1 - 1 / x));
    final intensity = math.pow(x, 5) / (expTerm - 1);
    return intensity.clamp(0.0, 1.0).toDouble();
  }

  double _rayleighJeansIntensity(double wavelength, double temp, double peakWavelength) {
    // Rayleigh-Jeans law (classical): proportional to T/λ^4
    final x = peakWavelength / wavelength;
    return math.pow(x, 4) * 0.3;
  }

  void _drawAxes(Canvas canvas, Size size) {
    final graphLeft = size.width * 0.35;
    final graphRight = size.width - 30;
    final graphBottom = size.height * 0.75;

    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;

    // X axis
    canvas.drawLine(
      Offset(graphLeft - 10, graphBottom),
      Offset(graphRight, graphBottom),
      axisPaint,
    );

    // Y axis
    canvas.drawLine(
      Offset(graphLeft - 10, size.height * 0.1),
      Offset(graphLeft - 10, graphBottom),
      axisPaint,
    );
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final graphLeft = size.width * 0.35;
    final graphBottom = size.height * 0.75;

    // X axis label
    textPainter.text = TextSpan(
      text: 'Wavelength (nm)',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 11,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.55, graphBottom + 20));

    // Y axis label
    textPainter.text = TextSpan(
      text: 'Intensity',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 11,
      ),
    );
    textPainter.layout();
    canvas.save();
    canvas.translate(graphLeft - 30, size.height * 0.45);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
    canvas.restore();

    // Wavelength markers
    for (int wl = 500; wl <= 2000; wl += 500) {
      final x = graphLeft + ((wl - 100) / 2400) * (size.width - 30 - graphLeft);
      textPainter.text = TextSpan(
        text: '$wl',
        style: TextStyle(
          color: AppColors.muted.withValues(alpha: 0.7),
          fontSize: 9,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, graphBottom + 3));
    }

    // Legend
    if (showClassical >= 1) {
      textPainter.text = TextSpan(
        text: 'Planck',
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - 80, size.height * 0.12));

      textPainter.text = TextSpan(
        text: 'Classical',
        style: TextStyle(
          color: const Color(0xFFFC8181),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - 80, size.height * 0.12 + 15));
    }
  }

  @override
  bool shouldRepaint(covariant BlackbodyPainter oldDelegate) =>
      time != oldDelegate.time ||
      temperature != oldDelegate.temperature ||
      showClassical != oldDelegate.showClassical;
}
