import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Relativistic Doppler Effect Simulation
class RelativisticDopplerScreen extends StatefulWidget {
  const RelativisticDopplerScreen({super.key});

  @override
  State<RelativisticDopplerScreen> createState() => _RelativisticDopplerScreenState();
}

class _RelativisticDopplerScreenState extends State<RelativisticDopplerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _velocity = 0.5; // v/c (positive = approaching, negative = receding)
  double _sourceFrequency = 500; // THz (visible light range)
  double _time = 0.0;
  bool _isAnimating = true;
  bool _showClassical = true;
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
    });
  }

  // Relativistic Doppler factor
  double get _dopplerFactor {
    // For approaching: sqrt((1+v/c)/(1-v/c))
    // For receding: sqrt((1-v/c)/(1+v/c))
    final beta = _velocity.abs();
    if (_velocity >= 0) {
      // Approaching (blueshift)
      return math.sqrt((1 + beta) / (1 - beta));
    } else {
      // Receding (redshift)
      return math.sqrt((1 - beta) / (1 + beta));
    }
  }

  double get _observedFrequency => _sourceFrequency * _dopplerFactor;

  // Classical Doppler for comparison
  double get _classicalDopplerFactor {
    return 1 / (1 - _velocity);
  }

  double get _classicalFrequency => _sourceFrequency * _classicalDopplerFactor;

  Color get _sourceColor => _frequencyToColor(_sourceFrequency);
  Color get _observedColor => _frequencyToColor(_observedFrequency.clamp(380, 750));

  Color _frequencyToColor(double freq) {
    // Map frequency (THz) to visible light color
    // Visible range: ~380-750 THz (400-790 nm wavelength)
    if (freq < 400) {
      // Infrared - show as deep red
      return const Color(0xFF8B0000);
    } else if (freq < 480) {
      // Red to orange
      final t = (freq - 400) / 80;
      return Color.lerp(const Color(0xFFFF0000), const Color(0xFFFF7F00), t)!;
    } else if (freq < 510) {
      // Orange to yellow
      final t = (freq - 480) / 30;
      return Color.lerp(const Color(0xFFFF7F00), const Color(0xFFFFFF00), t)!;
    } else if (freq < 530) {
      // Yellow to green
      final t = (freq - 510) / 20;
      return Color.lerp(const Color(0xFFFFFF00), const Color(0xFF00FF00), t)!;
    } else if (freq < 600) {
      // Green to cyan
      final t = (freq - 530) / 70;
      return Color.lerp(const Color(0xFF00FF00), const Color(0xFF00FFFF), t)!;
    } else if (freq < 670) {
      // Cyan to blue
      final t = (freq - 600) / 70;
      return Color.lerp(const Color(0xFF00FFFF), const Color(0xFF0000FF), t)!;
    } else if (freq < 750) {
      // Blue to violet
      final t = (freq - 670) / 80;
      return Color.lerp(const Color(0xFF0000FF), const Color(0xFF8B00FF), t)!;
    } else {
      // Ultraviolet - show as deep violet
      return const Color(0xFF4B0082);
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _velocity = 0.5;
      _sourceFrequency = 500;
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
              _isKorean ? '상대론적 도플러 효과' : 'Relativistic Doppler Effect',
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
          title: _isKorean ? '상대론적 도플러 효과' : 'Relativistic Doppler Effect',
          formula: "f' = f × √((1+β)/(1-β))",
          formulaDescription: _isKorean
              ? '상대론적 도플러 효과는 시간 지연을 포함합니다. 다가오는 광원은 청색편이(blueshift), 멀어지는 광원은 적색편이(redshift)를 보입니다.'
              : 'Relativistic Doppler includes time dilation. Approaching sources show blueshift, receding sources show redshift.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: RelativisticDopplerPainter(
                velocity: _velocity,
                sourceFrequency: _sourceFrequency,
                observedFrequency: _observedFrequency,
                dopplerFactor: _dopplerFactor,
                time: _time,
                sourceColor: _sourceColor,
                observedColor: _observedColor,
                showClassical: _showClassical,
                classicalFrequency: _classicalFrequency,
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
                  label: _isKorean ? '상대 속도 (v/c)' : 'Relative Velocity (v/c)',
                  value: _velocity,
                  min: -0.9,
                  max: 0.9,
                  defaultValue: 0.5,
                  formatValue: (v) => v >= 0
                      ? '${(v * 100).toStringAsFixed(0)}% c ${_isKorean ? '접근' : 'toward'}'
                      : '${(-v * 100).toStringAsFixed(0)}% c ${_isKorean ? '후퇴' : 'away'}',
                  onChanged: (v) => setState(() => _velocity = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '광원 주파수' : 'Source Frequency',
                    value: _sourceFrequency,
                    min: 400,
                    max: 700,
                    defaultValue: 500,
                    formatValue: (v) => '${v.toStringAsFixed(0)} THz',
                    onChanged: (v) => setState(() => _sourceFrequency = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '고전 도플러 비교' : 'Compare Classical',
                    value: _showClassical,
                    onChanged: (v) => setState(() => _showClassical = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                sourceFrequency: _sourceFrequency,
                observedFrequency: _observedFrequency,
                dopplerFactor: _dopplerFactor,
                velocity: _velocity,
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
  final double sourceFrequency;
  final double observedFrequency;
  final double dopplerFactor;
  final double velocity;
  final bool isKorean;

  const _InfoCard({
    required this.sourceFrequency,
    required this.observedFrequency,
    required this.dopplerFactor,
    required this.velocity,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    final isBlueshift = velocity > 0;

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
              Icon(
                isBlueshift ? Icons.arrow_back : Icons.arrow_forward,
                size: 16,
                color: isBlueshift ? Colors.blue : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isBlueshift
                    ? (isKorean ? '청색편이 (Blueshift)' : 'Blueshift')
                    : (isKorean ? '적색편이 (Redshift)' : 'Redshift'),
                style: TextStyle(
                  color: isBlueshift ? Colors.blue : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                isKorean ? '도플러 인자:' : 'Doppler Factor:',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const Spacer(),
              Text(
                dopplerFactor.toStringAsFixed(3),
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                isKorean ? '관측 주파수:' : 'Observed Frequency:',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${observedFrequency.toStringAsFixed(0)} THz',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                isKorean ? '주파수 변화:' : 'Frequency Shift:',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${((dopplerFactor - 1) * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isBlueshift ? Colors.blue : Colors.red,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RelativisticDopplerPainter extends CustomPainter {
  final double velocity;
  final double sourceFrequency;
  final double observedFrequency;
  final double dopplerFactor;
  final double time;
  final Color sourceColor;
  final Color observedColor;
  final bool showClassical;
  final double classicalFrequency;
  final bool isKorean;

  RelativisticDopplerPainter({
    required this.velocity,
    required this.sourceFrequency,
    required this.observedFrequency,
    required this.dopplerFactor,
    required this.time,
    required this.sourceColor,
    required this.observedColor,
    required this.showClassical,
    required this.classicalFrequency,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0A0A1A),
    );

    // Draw spectrum bar
    _drawSpectrum(canvas, size);

    // Draw wave visualization
    _drawWaves(canvas, size);

    // Draw source and observer
    _drawSourceAndObserver(canvas, size);

    // Draw labels
    _drawLabels(canvas, size);
  }

  void _drawSpectrum(Canvas canvas, Size size) {
    final spectrumTop = 30.0;
    final spectrumHeight = 20.0;
    final spectrumLeft = 40.0;
    final spectrumWidth = size.width - 80;

    // Draw visible spectrum gradient
    for (double x = 0; x < spectrumWidth; x++) {
      final freq = 400 + (x / spectrumWidth) * 350; // 400-750 THz
      final color = _frequencyToColor(freq);
      canvas.drawLine(
        Offset(spectrumLeft + x, spectrumTop),
        Offset(spectrumLeft + x, spectrumTop + spectrumHeight),
        Paint()..color = color,
      );
    }

    // Source frequency marker
    final sourceX = spectrumLeft + ((sourceFrequency - 400) / 350) * spectrumWidth;
    canvas.drawLine(
      Offset(sourceX, spectrumTop - 5),
      Offset(sourceX, spectrumTop + spectrumHeight + 5),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );

    // Observed frequency marker
    final observedX = spectrumLeft + ((observedFrequency.clamp(400, 750) - 400) / 350) * spectrumWidth;
    canvas.drawLine(
      Offset(observedX, spectrumTop - 5),
      Offset(observedX, spectrumTop + spectrumHeight + 5),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2,
    );

    // Arrow showing shift
    if ((observedX - sourceX).abs() > 10) {
      final arrowY = spectrumTop + spectrumHeight + 15;
      canvas.drawLine(
        Offset(sourceX, arrowY),
        Offset(observedX, arrowY),
        Paint()
          ..color = velocity > 0 ? Colors.blue : Colors.red
          ..strokeWidth = 2,
      );
    }
  }

  Color _frequencyToColor(double freq) {
    if (freq < 400) return const Color(0xFF8B0000);
    if (freq < 480) {
      final t = (freq - 400) / 80;
      return Color.lerp(const Color(0xFFFF0000), const Color(0xFFFF7F00), t)!;
    }
    if (freq < 510) {
      final t = (freq - 480) / 30;
      return Color.lerp(const Color(0xFFFF7F00), const Color(0xFFFFFF00), t)!;
    }
    if (freq < 530) {
      final t = (freq - 510) / 20;
      return Color.lerp(const Color(0xFFFFFF00), const Color(0xFF00FF00), t)!;
    }
    if (freq < 600) {
      final t = (freq - 530) / 70;
      return Color.lerp(const Color(0xFF00FF00), const Color(0xFF00FFFF), t)!;
    }
    if (freq < 670) {
      final t = (freq - 600) / 70;
      return Color.lerp(const Color(0xFF00FFFF), const Color(0xFF0000FF), t)!;
    }
    if (freq < 750) {
      final t = (freq - 670) / 80;
      return Color.lerp(const Color(0xFF0000FF), const Color(0xFF8B00FF), t)!;
    }
    return const Color(0xFF4B0082);
  }

  void _drawWaves(Canvas canvas, Size size) {
    final waveTop = 100.0;
    final waveHeight = 80.0;
    final waveCenterY = waveTop + waveHeight / 2;

    // Source wave (original frequency)
    final sourceWavePath = Path();
    final sourceWavelength = 60.0;

    for (double x = 0; x <= size.width; x += 2) {
      final y = waveCenterY - 30 + 25 * math.sin((x + time * 50) * 2 * math.pi / sourceWavelength);
      if (x == 0) {
        sourceWavePath.moveTo(x, y);
      } else {
        sourceWavePath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      sourceWavePath,
      Paint()
        ..color = sourceColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Observed wave (shifted frequency)
    final observedWavePath = Path();
    final observedWavelength = sourceWavelength / dopplerFactor;

    for (double x = 0; x <= size.width; x += 2) {
      final y = waveCenterY + 50 + 25 * math.sin((x + time * 50 * dopplerFactor) * 2 * math.pi / observedWavelength);
      if (x == 0) {
        observedWavePath.moveTo(x, y);
      } else {
        observedWavePath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      observedWavePath,
      Paint()
        ..color = observedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawSourceAndObserver(Canvas canvas, Size size) {
    final y = size.height - 80;

    // Source (star/light source)
    final sourceX = velocity > 0 ? size.width * 0.2 : size.width * 0.8;

    final sourceGlow = Paint()
      ..shader = RadialGradient(
        colors: [sourceColor, sourceColor.withValues(alpha: 0.3), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(sourceX, y), radius: 30));
    canvas.drawCircle(Offset(sourceX, y), 30, sourceGlow);
    canvas.drawCircle(Offset(sourceX, y), 12, Paint()..color = sourceColor);

    // Velocity arrow
    final arrowLength = velocity.abs() * 50;
    final arrowDirection = velocity > 0 ? 1 : -1;
    canvas.drawLine(
      Offset(sourceX, y),
      Offset(sourceX + arrowLength * arrowDirection, y),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );

    // Observer (eye icon)
    final observerX = velocity > 0 ? size.width * 0.8 : size.width * 0.2;
    canvas.drawCircle(
      Offset(observerX, y),
      15,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      Offset(observerX, y),
      6,
      Paint()..color = observedColor,
    );
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Wave labels
    textPainter.text = TextSpan(
      text: isKorean ? '광원 파동' : 'Source Wave',
      style: TextStyle(color: sourceColor, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 95));

    textPainter.text = TextSpan(
      text: isKorean ? '관측된 파동' : 'Observed Wave',
      style: TextStyle(color: observedColor, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 175));

    // Source/Observer labels
    final sourceX = velocity > 0 ? size.width * 0.2 : size.width * 0.8;
    final observerX = velocity > 0 ? size.width * 0.8 : size.width * 0.2;
    final y = size.height - 50;

    textPainter.text = TextSpan(
      text: isKorean ? '광원' : 'Source',
      style: const TextStyle(color: Colors.white70, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(sourceX - textPainter.width / 2, y));

    textPainter.text = TextSpan(
      text: isKorean ? '관측자' : 'Observer',
      style: const TextStyle(color: Colors.white70, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(observerX - textPainter.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant RelativisticDopplerPainter oldDelegate) {
    return velocity != oldDelegate.velocity ||
        sourceFrequency != oldDelegate.sourceFrequency ||
        time != oldDelegate.time ||
        showClassical != oldDelegate.showClassical;
  }
}
