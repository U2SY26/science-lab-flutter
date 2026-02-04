import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Wave Superposition simulation
class WaveSuperpositionScreen extends StatefulWidget {
  const WaveSuperpositionScreen({super.key});

  @override
  State<WaveSuperpositionScreen> createState() => _WaveSuperpositionScreenState();
}

class _WaveSuperpositionScreenState extends State<WaveSuperpositionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Wave 1 parameters
  double amplitude1 = 30.0;
  double frequency1 = 1.0;
  double phase1 = 0.0;

  // Wave 2 parameters
  double amplitude2 = 30.0;
  double frequency2 = 1.5;
  double phase2 = 0.0;

  double time = 0.0;
  bool isRunning = true;
  bool showWave1 = true;
  bool showWave2 = true;
  bool showResultant = true;
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
      amplitude1 = 30;
      amplitude2 = 30;
      frequency1 = 1.0;
      frequency2 = 1.5;
      phase1 = 0;
      phase2 = 0;
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
              isKorean ? '파동의 중첩' : 'Wave Superposition',
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
          title: isKorean ? '파동의 중첩' : 'Wave Superposition',
          formula: 'y = y₁ + y₂ = A₁sin(ω₁t + φ₁) + A₂sin(ω₂t + φ₂)',
          formulaDescription: isKorean
              ? '두 파동이 만나면 각 지점에서 변위가 더해집니다 (중첩의 원리).'
              : 'When two waves meet, their displacements add at each point (principle of superposition).',
          simulation: CustomPaint(
            painter: WaveSuperpositionPainter(
              amplitude1: amplitude1,
              frequency1: frequency1,
              phase1: phase1,
              amplitude2: amplitude2,
              frequency2: frequency2,
              phase2: phase2,
              time: time,
              showWave1: showWave1,
              showWave2: showWave2,
              showResultant: showResultant,
              isKorean: isKorean,
            ),
            size: Size.infinite,
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wave toggles
              Row(
                children: [
                  _WaveToggle(
                    label: isKorean ? '파동 1' : 'Wave 1',
                    color: AppColors.accent,
                    value: showWave1,
                    onChanged: (v) => setState(() => showWave1 = v),
                  ),
                  const SizedBox(width: 12),
                  _WaveToggle(
                    label: isKorean ? '파동 2' : 'Wave 2',
                    color: AppColors.accent2,
                    value: showWave2,
                    onChanged: (v) => setState(() => showWave2 = v),
                  ),
                  const SizedBox(width: 12),
                  _WaveToggle(
                    label: isKorean ? '합성파' : 'Resultant',
                    color: Colors.greenAccent,
                    value: showResultant,
                    onChanged: (v) => setState(() => showResultant = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '진폭 1 (A₁)' : 'Amplitude 1 (A₁)',
                  value: amplitude1,
                  min: 5,
                  max: 50,
                  defaultValue: 30,
                  formatValue: (v) => '${v.toStringAsFixed(0)} px',
                  onChanged: (v) => setState(() => amplitude1 = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '주파수 1 (f₁)' : 'Frequency 1 (f₁)',
                    value: frequency1,
                    min: 0.5,
                    max: 3,
                    step: 0.1,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)} Hz',
                    onChanged: (v) => setState(() => frequency1 = v),
                  ),
                  SimSlider(
                    label: isKorean ? '위상 1 (φ₁)' : 'Phase 1 (φ₁)',
                    value: phase1,
                    min: 0,
                    max: 2 * math.pi,
                    step: 0.1,
                    defaultValue: 0,
                    formatValue: (v) => '${(v * 180 / math.pi).toStringAsFixed(0)}°',
                    onChanged: (v) => setState(() => phase1 = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '진폭 2 (A₂)' : 'Amplitude 2 (A₂)',
                  value: amplitude2,
                  min: 5,
                  max: 50,
                  defaultValue: 30,
                  formatValue: (v) => '${v.toStringAsFixed(0)} px',
                  onChanged: (v) => setState(() => amplitude2 = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '주파수 2 (f₂)' : 'Frequency 2 (f₂)',
                    value: frequency2,
                    min: 0.5,
                    max: 3,
                    step: 0.1,
                    defaultValue: 1.5,
                    formatValue: (v) => '${v.toStringAsFixed(1)} Hz',
                    onChanged: (v) => setState(() => frequency2 = v),
                  ),
                  SimSlider(
                    label: isKorean ? '위상 2 (φ₂)' : 'Phase 2 (φ₂)',
                    value: phase2,
                    min: 0,
                    max: 2 * math.pi,
                    step: 0.1,
                    defaultValue: 0,
                    formatValue: (v) => '${(v * 180 / math.pi).toStringAsFixed(0)}°',
                    onChanged: (v) => setState(() => phase2 = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InterferenceInfo(
                frequency1: frequency1,
                frequency2: frequency2,
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

class _WaveToggle extends StatelessWidget {
  final String label;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _WaveToggle({
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value ? color : AppColors.muted),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: value ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: value ? color : AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterferenceInfo extends StatelessWidget {
  final double frequency1;
  final double frequency2;
  final bool isKorean;

  const _InterferenceInfo({
    required this.frequency1,
    required this.frequency2,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    final beatFreq = (frequency1 - frequency2).abs();
    final interferenceType = beatFreq < 0.1
        ? (isKorean ? '보강 간섭' : 'Constructive')
        : (beatFreq > 0.5 ? (isKorean ? '맥놀이' : 'Beats') : (isKorean ? '부분 간섭' : 'Partial'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  isKorean ? '맥놀이 주파수' : 'Beat Frequency',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                Text(
                  '${beatFreq.toStringAsFixed(2)} Hz',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  isKorean ? '간섭 유형' : 'Interference Type',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                Text(
                  interferenceType,
                  style: const TextStyle(
                    color: AppColors.accent2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class WaveSuperpositionPainter extends CustomPainter {
  final double amplitude1;
  final double frequency1;
  final double phase1;
  final double amplitude2;
  final double frequency2;
  final double phase2;
  final double time;
  final bool showWave1;
  final bool showWave2;
  final bool showResultant;
  final bool isKorean;

  WaveSuperpositionPainter({
    required this.amplitude1,
    required this.frequency1,
    required this.phase1,
    required this.amplitude2,
    required this.frequency2,
    required this.phase2,
    required this.time,
    required this.showWave1,
    required this.showWave2,
    required this.showResultant,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    final centerY = size.height / 2;
    final startX = 30.0;
    final endX = size.width - 30;

    // Draw center line
    canvas.drawLine(
      Offset(startX, centerY),
      Offset(endX, centerY),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // Draw waves
    if (showWave1) {
      _drawWave(canvas, size, centerY, startX, endX, amplitude1, frequency1, phase1,
          AppColors.accent.withValues(alpha: 0.7), 2);
    }

    if (showWave2) {
      _drawWave(canvas, size, centerY, startX, endX, amplitude2, frequency2, phase2,
          AppColors.accent2.withValues(alpha: 0.7), 2);
    }

    if (showResultant) {
      _drawResultantWave(canvas, size, centerY, startX, endX);
    }

    // Labels
    _drawText(canvas, 'y', Offset(10, centerY - 10), AppColors.muted, 12);
    _drawText(canvas, 'x', Offset(endX + 5, centerY - 10), AppColors.muted, 12);

    // Legend
    double legendY = 20;
    if (showWave1) {
      _drawLegendItem(canvas, Offset(20, legendY), AppColors.accent,
          isKorean ? '파동 1: y₁ = A₁sin(ω₁t + φ₁)' : 'Wave 1: y₁ = A₁sin(ω₁t + φ₁)');
      legendY += 18;
    }
    if (showWave2) {
      _drawLegendItem(canvas, Offset(20, legendY), AppColors.accent2,
          isKorean ? '파동 2: y₂ = A₂sin(ω₂t + φ₂)' : 'Wave 2: y₂ = A₂sin(ω₂t + φ₂)');
      legendY += 18;
    }
    if (showResultant) {
      _drawLegendItem(canvas, Offset(20, legendY), Colors.greenAccent,
          isKorean ? '합성파: y = y₁ + y₂' : 'Resultant: y = y₁ + y₂');
    }
  }

  void _drawWave(Canvas canvas, Size size, double centerY, double startX, double endX,
      double amplitude, double frequency, double phase, Color color, double strokeWidth) {
    final path = Path();
    bool started = false;

    for (double x = startX; x <= endX; x += 2) {
      final normalizedX = (x - startX) / (endX - startX) * 4 * math.pi;
      final y = centerY - amplitude * math.sin(normalizedX * frequency + time * frequency * 2 + phase);

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
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawResultantWave(Canvas canvas, Size size, double centerY, double startX, double endX) {
    final path = Path();
    bool started = false;

    for (double x = startX; x <= endX; x += 2) {
      final normalizedX = (x - startX) / (endX - startX) * 4 * math.pi;
      final y1 = amplitude1 * math.sin(normalizedX * frequency1 + time * frequency1 * 2 + phase1);
      final y2 = amplitude2 * math.sin(normalizedX * frequency2 + time * frequency2 * 2 + phase2);
      final y = centerY - (y1 + y2);

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
        ..color = Colors.greenAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawLegendItem(Canvas canvas, Offset position, Color color, String text) {
    canvas.drawLine(
      position,
      Offset(position.dx + 20, position.dy),
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    _drawText(canvas, text, Offset(position.dx + 25, position.dy - 6), color, 10);
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
  bool shouldRepaint(covariant WaveSuperpositionPainter oldDelegate) => true;
}
