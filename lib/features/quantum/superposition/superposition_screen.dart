import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Quantum Superposition Simulation
/// 양자 중첩 시뮬레이션 (ψ = α|0⟩ + β|1⟩)
class SuperpositionScreen extends StatefulWidget {
  const SuperpositionScreen({super.key});

  @override
  State<SuperpositionScreen> createState() => _SuperpositionScreenState();
}

class _SuperpositionScreenState extends State<SuperpositionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const double _defaultAlpha = 0.707; // |α|² = 0.5
  static const double _defaultPhase = 0.0;

  double alpha = _defaultAlpha; // Coefficient for |0⟩
  double phase = _defaultPhase; // Relative phase
  bool isRunning = true;
  bool isMeasured = false;
  bool? measurementResult; // true = |0⟩, false = |1⟩

  double time = 0;
  bool isKorean = true;
  int measureCount0 = 0;
  int measureCount1 = 0;
  final math.Random _random = math.Random();

  double get beta => math.sqrt(1 - alpha * alpha);

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
      time += 0.03;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      alpha = _defaultAlpha;
      phase = _defaultPhase;
      isMeasured = false;
      measurementResult = null;
      measureCount0 = 0;
      measureCount1 = 0;
    });
  }

  void _measure() {
    HapticFeedback.heavyImpact();
    setState(() {
      isMeasured = true;
      // Probability of measuring |0⟩ is |α|²
      final prob0 = alpha * alpha;
      measurementResult = _random.nextDouble() < prob0;

      if (measurementResult!) {
        measureCount0++;
      } else {
        measureCount1++;
      }
    });

    // Reset to superposition after showing result
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          isMeasured = false;
          measurementResult = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prob0 = alpha * alpha;
    final prob1 = beta * beta;
    final totalMeasurements = measureCount0 + measureCount1;

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
              isKorean ? '양자 중첩' : 'Quantum Superposition',
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
          title: isKorean ? '양자 중첩' : 'Quantum Superposition',
          formula: '|ψ⟩ = α|0⟩ + βe^(iφ)|1⟩',
          formulaDescription: isKorean
              ? '양자 시스템은 여러 상태의 중첩으로 존재할 수 있습니다. |α|² + |β|² = 1이며, '
                  '측정 시 확률 |α|²로 |0⟩, 확률 |β|²로 |1⟩ 상태로 붕괴합니다.'
              : 'Quantum systems can exist in superposition of multiple states. |α|² + |β|² = 1. '
                  'Upon measurement, collapses to |0⟩ with probability |α|², or |1⟩ with probability |β|².',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: SuperpositionPainter(
                time: time,
                alpha: alpha,
                beta: beta,
                phase: phase,
                isMeasured: isMeasured,
                measurementResult: measurementResult,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '|0⟩ 진폭 (α)' : 'Amplitude α for |0⟩',
                  value: alpha,
                  min: 0,
                  max: 1,
                  defaultValue: _defaultAlpha,
                  formatValue: (v) => '${v.toStringAsFixed(2)} (${(v * v * 100).toInt()}%)',
                  onChanged: (v) => setState(() => alpha = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '상대 위상 (φ)' : 'Relative Phase (φ)',
                    value: phase,
                    min: 0,
                    max: 2 * math.pi,
                    defaultValue: _defaultPhase,
                    formatValue: (v) => '${(v * 180 / math.pi).toInt()}°',
                    onChanged: (v) => setState(() => phase = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                prob0: prob0,
                prob1: prob1,
                measureCount0: measureCount0,
                measureCount1: measureCount1,
                totalMeasurements: totalMeasurements,
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
                label: isKorean ? '측정' : 'Measure',
                icon: Icons.radio_button_checked,
                onPressed: _measure,
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
  final double prob0;
  final double prob1;
  final int measureCount0;
  final int measureCount1;
  final int totalMeasurements;
  final bool isKorean;

  const _PhysicsInfo({
    required this.prob0,
    required this.prob1,
    required this.measureCount0,
    required this.measureCount1,
    required this.totalMeasurements,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    final expProb0 = totalMeasurements > 0 ? measureCount0 / totalMeasurements : 0.0;
    final expProb1 = totalMeasurements > 0 ? measureCount1 / totalMeasurements : 0.0;

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
                label: 'P(|0⟩)',
                value: '${(prob0 * 100).toInt()}%',
              ),
              _InfoItem(
                label: 'P(|1⟩)',
                value: '${(prob1 * 100).toInt()}%',
              ),
              _InfoItem(
                label: isKorean ? '측정 횟수' : 'Measurements',
                value: '$totalMeasurements',
              ),
            ],
          ),
          if (totalMeasurements > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoItem(
                  label: isKorean ? '실험 |0⟩' : 'Exp. |0⟩',
                  value: '${(expProb0 * 100).toInt()}% ($measureCount0)',
                ),
                _InfoItem(
                  label: isKorean ? '실험 |1⟩' : 'Exp. |1⟩',
                  value: '${(expProb1 * 100).toInt()}% ($measureCount1)',
                ),
              ],
            ),
          ],
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

class SuperpositionPainter extends CustomPainter {
  final double time;
  final double alpha;
  final double beta;
  final double phase;
  final bool isMeasured;
  final bool? measurementResult;

  SuperpositionPainter({
    required this.time,
    required this.alpha,
    required this.beta,
    required this.phase,
    required this.isMeasured,
    required this.measurementResult,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    if (isMeasured && measurementResult != null) {
      _drawCollapsedState(canvas, size);
    } else {
      _drawSuperpositionState(canvas, size);
      _drawBlochSphere(canvas, size);
    }

    _drawProbabilityBars(canvas, size);
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

  void _drawSuperpositionState(Canvas canvas, Size size) {
    final centerX = size.width * 0.25;
    final centerY = size.height * 0.45;

    // Draw |0⟩ component
    final state0Y = centerY - 60;
    final state0Size = 30.0 + alpha * 30;
    _drawStateOrb(canvas, centerX, state0Y, state0Size, const Color(0xFF48BB78), '|0⟩', alpha);

    // Draw |1⟩ component
    final state1Y = centerY + 60;
    final state1Size = 30.0 + beta * 30;
    _drawStateOrb(canvas, centerX, state1Y, state1Size, const Color(0xFFFC8181), '|1⟩', beta);

    // Draw superposition connection
    final connectionPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Wavy connection representing superposition
    final wavePath = Path();
    wavePath.moveTo(centerX, state0Y + state0Size / 2);
    for (double y = state0Y + state0Size / 2; y < state1Y - state1Size / 2; y += 3) {
      final wave = 15 * math.sin((y - state0Y) * 0.1 + time * 3);
      wavePath.lineTo(centerX + wave, y);
    }
    canvas.drawPath(wavePath, connectionPaint);

    // Phase indicator
    final phaseX = centerX + 70;
    final phaseY = centerY;
    final phaseRadius = 25.0;

    canvas.drawCircle(
      Offset(phaseX, phaseY),
      phaseRadius,
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final phaseArrowX = phaseX + phaseRadius * math.cos(phase + time);
    final phaseArrowY = phaseY + phaseRadius * math.sin(phase + time);

    canvas.drawLine(
      Offset(phaseX, phaseY),
      Offset(phaseArrowX, phaseArrowY),
      Paint()
        ..color = const Color(0xFF805AD5)
        ..strokeWidth = 2,
    );
  }

  void _drawStateOrb(Canvas canvas, double x, double y, double size, Color color, String label, double amplitude) {
    // Glow
    final glowGradient = RadialGradient(
      colors: [
        color.withValues(alpha: 0.6 * amplitude),
        color.withValues(alpha: 0.2 * amplitude),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(x, y), radius: size * 1.5));

    canvas.drawCircle(
      Offset(x, y),
      size * 1.5,
      Paint()..shader = glowGradient,
    );

    // Orb with pulsing
    final pulseSize = size + 5 * math.sin(time * 3) * amplitude;
    canvas.drawCircle(
      Offset(x, y),
      pulseSize,
      Paint()..color = color.withValues(alpha: 0.8),
    );

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 7));
  }

  void _drawCollapsedState(Canvas canvas, Size size) {
    final centerX = size.width * 0.25;
    final centerY = size.height * 0.45;

    final isZero = measurementResult!;
    final stateY = centerY;
    final color = isZero ? const Color(0xFF48BB78) : const Color(0xFFFC8181);
    final label = isZero ? '|0⟩' : '|1⟩';

    // Flash effect
    canvas.drawCircle(
      Offset(centerX, stateY),
      100,
      Paint()..color = color.withValues(alpha: 0.2),
    );

    _drawStateOrb(canvas, centerX, stateY, 50, color, label, 1.0);

    // "Collapsed!" indicator
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Measured!',
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, stateY + 70));
  }

  void _drawBlochSphere(Canvas canvas, Size size) {
    final centerX = size.width * 0.7;
    final centerY = size.height * 0.4;
    final radius = 70.0;

    // Sphere outline
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Equator
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, centerY), width: radius * 2, height: radius * 0.5),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke,
    );

    // Axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    // Z axis
    canvas.drawLine(
      Offset(centerX, centerY - radius - 10),
      Offset(centerX, centerY + radius + 10),
      axisPaint,
    );

    // Calculate Bloch vector position
    final theta = 2 * math.acos(alpha);
    final phi = phase + time * 0.5;

    final blochX = radius * math.sin(theta) * math.cos(phi);
    final blochZ = -radius * math.cos(theta);

    final screenX = centerX + blochX;
    final screenY = centerY + blochZ;

    // Bloch vector
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(screenX, screenY),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2.5,
    );

    // Vector tip
    canvas.drawCircle(
      Offset(screenX, screenY),
      6,
      Paint()..color = AppColors.accent,
    );
    canvas.drawCircle(
      Offset(screenX, screenY),
      10,
      Paint()..color = AppColors.accent.withValues(alpha: 0.3),
    );

    // Labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: '|0⟩',
      style: TextStyle(color: const Color(0xFF48BB78), fontSize: 11, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + 5, centerY - radius - 20));

    textPainter.text = TextSpan(
      text: '|1⟩',
      style: TextStyle(color: const Color(0xFFFC8181), fontSize: 11, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + 5, centerY + radius + 5));
  }

  void _drawProbabilityBars(Canvas canvas, Size size) {
    final barX = size.width * 0.55;
    final barY = size.height * 0.75;
    final barWidth = 40.0;
    final maxHeight = 60.0;

    // |0⟩ probability bar
    final prob0Height = alpha * alpha * maxHeight;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY - prob0Height, barWidth, prob0Height),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF48BB78).withValues(alpha: 0.7),
    );

    // |1⟩ probability bar
    final prob1Height = beta * beta * maxHeight;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX + barWidth + 20, barY - prob1Height, barWidth, prob1Height),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFC8181).withValues(alpha: 0.7),
    );

    // Labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: '|0⟩',
      style: TextStyle(color: const Color(0xFF48BB78), fontSize: 11),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(barX + barWidth / 2 - 8, barY + 5));

    textPainter.text = TextSpan(
      text: '|1⟩',
      style: TextStyle(color: const Color(0xFFFC8181), fontSize: 11),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(barX + barWidth + 20 + barWidth / 2 - 8, barY + 5));
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // State vector
    textPainter.text = TextSpan(
      text: '|ψ⟩ = ${alpha.toStringAsFixed(2)}|0⟩ + ${beta.toStringAsFixed(2)}e^(i${(phase * 180 / math.pi).toInt()}°)|1⟩',
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 12,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.05));

    // Bloch sphere label
    textPainter.text = TextSpan(
      text: 'Bloch Sphere',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.7 - textPainter.width / 2, size.height * 0.6));
  }

  @override
  bool shouldRepaint(covariant SuperpositionPainter oldDelegate) =>
      time != oldDelegate.time ||
      alpha != oldDelegate.alpha ||
      phase != oldDelegate.phase ||
      isMeasured != oldDelegate.isMeasured ||
      measurementResult != oldDelegate.measurementResult;
}
