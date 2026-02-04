import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Sound Waves simulation: v = 331 + 0.6T
class SoundWavesScreen extends StatefulWidget {
  const SoundWavesScreen({super.key});

  @override
  State<SoundWavesScreen> createState() => _SoundWavesScreenState();
}

class _SoundWavesScreenState extends State<SoundWavesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  double temperature = 20.0; // Celsius
  double frequency = 440.0; // Hz (A4 note)
  double time = 0.0;

  bool isRunning = true;
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
      time += 0.016;
    });
  }

  double get soundSpeed => 331.0 + 0.6 * temperature;
  double get wavelength => soundSpeed / frequency;

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      temperature = 20;
      frequency = 440;
      time = 0;
    });
  }

  void _toggleSimulation() {
    HapticFeedback.selectionClick();
    setState(() => isRunning = !isRunning);
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
              isKorean ? '파동 역학' : 'WAVE MECHANICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '음파' : 'Sound Waves',
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
          category: isKorean ? '파동 역학' : 'Wave Mechanics',
          title: isKorean ? '음파' : 'Sound Waves',
          formula: 'v = 331 + 0.6T (m/s)',
          formulaDescription: isKorean
              ? '공기 중 음속(v)은 온도(T, °C)에 따라 변합니다. 파장 λ = v/f'
              : 'Speed of sound (v) in air depends on temperature (T, °C). Wavelength λ = v/f',
          simulation: CustomPaint(
            painter: SoundWavesPainter(
              temperature: temperature,
              frequency: frequency,
              time: time,
              soundSpeed: soundSpeed,
              wavelength: wavelength,
              isKorean: isKorean,
            ),
            size: Size.infinite,
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Temperature presets
              PresetGroup(
                label: isKorean ? '온도 프리셋' : 'Temperature Presets',
                presets: [
                  PresetButton(
                    label: isKorean ? '영하 (-20°C)' : 'Cold (-20°C)',
                    isSelected: (temperature - (-20)).abs() < 1,
                    onPressed: () => setState(() => temperature = -20),
                  ),
                  PresetButton(
                    label: isKorean ? '실온 (20°C)' : 'Room (20°C)',
                    isSelected: (temperature - 20).abs() < 1,
                    onPressed: () => setState(() => temperature = 20),
                  ),
                  PresetButton(
                    label: isKorean ? '더운 (40°C)' : 'Hot (40°C)',
                    isSelected: (temperature - 40).abs() < 1,
                    onPressed: () => setState(() => temperature = 40),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '온도 (T)' : 'Temperature (T)',
                  value: temperature,
                  min: -40,
                  max: 60,
                  defaultValue: 20,
                  formatValue: (v) => '${v.toStringAsFixed(0)} °C',
                  onChanged: (v) => setState(() => temperature = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '주파수 (f)' : 'Frequency (f)',
                    value: frequency,
                    min: 20,
                    max: 2000,
                    defaultValue: 440,
                    formatValue: (v) => '${v.toStringAsFixed(0)} Hz',
                    onChanged: (v) => setState(() => frequency = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Note presets
              PresetGroup(
                label: isKorean ? '음계' : 'Musical Notes',
                presets: [
                  PresetButton(
                    label: 'C4 (262 Hz)',
                    isSelected: (frequency - 262).abs() < 5,
                    onPressed: () => setState(() => frequency = 262),
                  ),
                  PresetButton(
                    label: 'A4 (440 Hz)',
                    isSelected: (frequency - 440).abs() < 5,
                    onPressed: () => setState(() => frequency = 440),
                  ),
                  PresetButton(
                    label: 'C5 (523 Hz)',
                    isSelected: (frequency - 523).abs() < 5,
                    onPressed: () => setState(() => frequency = 523),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SoundInfo(
                soundSpeed: soundSpeed,
                wavelength: wavelength,
                frequency: frequency,
                temperature: temperature,
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

class _SoundInfo extends StatelessWidget {
  final double soundSpeed;
  final double wavelength;
  final double frequency;
  final double temperature;
  final bool isKorean;

  const _SoundInfo({
    required this.soundSpeed,
    required this.wavelength,
    required this.frequency,
    required this.temperature,
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
                label: isKorean ? '음속 (v)' : 'Speed (v)',
                value: '${soundSpeed.toStringAsFixed(1)} m/s',
                color: AppColors.accent,
              ),
              _InfoItem(
                label: isKorean ? '파장 (λ)' : 'Wavelength (λ)',
                value: '${wavelength.toStringAsFixed(2)} m',
                color: AppColors.accent2,
              ),
              _InfoItem(
                label: isKorean ? '주기 (T)' : 'Period (T)',
                value: '${(1000 / frequency).toStringAsFixed(2)} ms',
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
              'v = 331 + 0.6 × ${temperature.toStringAsFixed(0)} = ${soundSpeed.toStringAsFixed(1)} m/s',
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

class SoundWavesPainter extends CustomPainter {
  final double temperature;
  final double frequency;
  final double time;
  final double soundSpeed;
  final double wavelength;
  final bool isKorean;

  SoundWavesPainter({
    required this.temperature,
    required this.frequency,
    required this.time,
    required this.soundSpeed,
    required this.wavelength,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    // Speaker icon position
    final speakerX = 50.0;
    final centerY = size.height * 0.5;

    // Draw speaker
    _drawSpeaker(canvas, Offset(speakerX, centerY));

    // Draw sound waves (circular waves from speaker)
    final maxRadius = size.width - speakerX;
    final waveSpacing = wavelength * 2; // Scaled for visibility
    final numWaves = (maxRadius / waveSpacing).ceil() + 2;

    for (int i = 0; i < numWaves; i++) {
      final baseRadius = (time * soundSpeed * 0.5 + i * waveSpacing) % maxRadius;
      if (baseRadius > 10) {
        final alpha = (1.0 - baseRadius / maxRadius).clamp(0.0, 1.0);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(speakerX, centerY), radius: baseRadius),
          -math.pi / 3,
          2 * math.pi / 3,
          false,
          Paint()
            ..color = AppColors.accent.withValues(alpha: alpha * 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // Draw compression/rarefaction visualization at bottom
    _drawPressureWave(canvas, size);

    // Temperature indicator
    _drawThermometer(canvas, Offset(size.width - 60, 30), size.height * 0.4);

    // Speed comparison bar
    _drawSpeedBar(canvas, size);

    // Labels
    _drawText(canvas, isKorean ? '음원' : 'Source', Offset(speakerX - 15, centerY + 50), AppColors.muted, 10);
  }

  void _drawSpeaker(Canvas canvas, Offset center) {
    // Speaker cone
    final speakerPath = Path()
      ..moveTo(center.dx - 20, center.dy - 15)
      ..lineTo(center.dx - 5, center.dy - 25)
      ..lineTo(center.dx - 5, center.dy + 25)
      ..lineTo(center.dx - 20, center.dy + 15)
      ..close();

    canvas.drawPath(speakerPath, Paint()..color = AppColors.muted);
    canvas.drawPath(
      speakerPath,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Speaker box
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx - 25, center.dy), width: 15, height: 35),
      Paint()..color = AppColors.pivot,
    );
  }

  void _drawPressureWave(Canvas canvas, Size size) {
    final waveY = size.height * 0.85;
    final startX = 60.0;
    final endX = size.width - 30;

    // Axis
    canvas.drawLine(
      Offset(startX, waveY),
      Offset(endX, waveY),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // Pressure wave
    final path = Path();
    bool started = false;

    for (double x = startX; x <= endX; x += 2) {
      final phase = (x - startX) / (endX - startX) * 4 * math.pi;
      final y = waveY - 20 * math.sin(phase - time * frequency * 0.1);

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Labels
    _drawText(canvas, isKorean ? '압축' : 'Compression', Offset(startX, waveY - 35), AppColors.accent2, 9);
    _drawText(canvas, isKorean ? '희박' : 'Rarefaction', Offset(startX, waveY + 10), AppColors.muted, 9);
  }

  void _drawThermometer(Canvas canvas, Offset position, double height) {
    final normalizedTemp = ((temperature + 40) / 100).clamp(0.0, 1.0);
    final fillHeight = height * normalizedTemp;

    // Thermometer outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx, position.dy, 20, height),
        const Radius.circular(10),
      ),
      Paint()
        ..color = AppColors.cardBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx + 3, position.dy + height - fillHeight + 3, 14, fillHeight - 6),
        const Radius.circular(7),
      ),
      Paint()..color = _getTemperatureColor(),
    );

    // Temperature label
    _drawText(canvas, '${temperature.toStringAsFixed(0)}°C',
        Offset(position.dx - 10, position.dy + height + 10), AppColors.ink, 11);
  }

  Color _getTemperatureColor() {
    if (temperature < 0) return Colors.blue;
    if (temperature < 20) return Colors.cyan;
    if (temperature < 35) return Colors.orange;
    return Colors.red;
  }

  void _drawSpeedBar(Canvas canvas, Size size) {
    final barX = 60.0;
    final barY = 20.0;
    final barWidth = size.width - 150;
    final barHeight = 15.0;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.cardBorder,
    );

    // Speed indicator (normalized to 280-380 m/s range)
    final normalizedSpeed = ((soundSpeed - 280) / 100).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth * normalizedSpeed, barHeight),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.accent,
    );

    // Label
    _drawText(canvas, 'v = ${soundSpeed.toStringAsFixed(0)} m/s',
        Offset(barX + barWidth * normalizedSpeed + 5, barY), AppColors.accent, 10);
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
  bool shouldRepaint(covariant SoundWavesPainter oldDelegate) => true;
}
