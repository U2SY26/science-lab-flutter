import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Quantum Entanglement Simulation
/// 양자 얽힘 시뮬레이션
class EntanglementScreen extends StatefulWidget {
  const EntanglementScreen({super.key});

  @override
  State<EntanglementScreen> createState() => _EntanglementScreenState();
}

class _EntanglementScreenState extends State<EntanglementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const double _defaultSeparation = 150.0;
  static const double _defaultCorrelation = 1.0;

  double separation = _defaultSeparation;
  double correlation = _defaultCorrelation;
  bool isRunning = true;
  int entanglementType = 0; // 0: Bell state, 1: GHZ state

  double time = 0;
  bool isKorean = true;
  final math.Random _random = math.Random();

  // Measurement results
  bool? particleAResult;
  bool? particleBResult;
  int measurementCount = 0;
  int correlatedCount = 0;

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
      separation = _defaultSeparation;
      correlation = _defaultCorrelation;
      particleAResult = null;
      particleBResult = null;
      measurementCount = 0;
      correlatedCount = 0;
    });
  }

  void _measureBoth() {
    HapticFeedback.heavyImpact();
    setState(() {
      // Perfect anti-correlation for Bell state |01⟩ - |10⟩
      final baseResult = _random.nextBool();

      if (_random.nextDouble() < correlation) {
        // Perfectly correlated/anti-correlated
        particleAResult = baseResult;
        particleBResult = entanglementType == 0 ? !baseResult : baseResult;
        correlatedCount++;
      } else {
        // Random (decoherence)
        particleAResult = _random.nextBool();
        particleBResult = _random.nextBool();
        if (particleAResult != particleBResult) correlatedCount++;
      }

      measurementCount++;
    });
  }

  void _measureA() {
    HapticFeedback.selectionClick();
    setState(() {
      particleAResult = _random.nextBool();
      // Instantaneous collapse of B due to entanglement
      if (particleBResult == null && _random.nextDouble() < correlation) {
        particleBResult = entanglementType == 0 ? !particleAResult! : particleAResult;
      }
      measurementCount++;
      if (particleAResult != particleBResult) correlatedCount++;
    });
  }

  void _measureB() {
    HapticFeedback.selectionClick();
    setState(() {
      particleBResult = _random.nextBool();
      // Instantaneous collapse of A due to entanglement
      if (particleAResult == null && _random.nextDouble() < correlation) {
        particleAResult = entanglementType == 0 ? !particleBResult! : particleBResult;
      }
      measurementCount++;
      if (particleAResult != particleBResult) correlatedCount++;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final correlationRate = measurementCount > 0
        ? (correlatedCount / measurementCount * 100)
        : 0.0;

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
              isKorean ? '양자 얽힘' : 'Quantum Entanglement',
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
          title: isKorean ? '양자 얽힘' : 'Quantum Entanglement',
          formula: '|Ψ⟩ = (|01⟩ - |10⟩)/√2',
          formulaDescription: isKorean
              ? '얽힌 입자 쌍은 거리에 관계없이 상관관계를 유지합니다. '
                  '한 입자를 측정하면 다른 입자의 상태가 즉시 결정됩니다 (EPR 역설).'
              : 'Entangled particle pairs maintain correlations regardless of distance. '
                  'Measuring one particle instantly determines the state of the other (EPR paradox).',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: EntanglementPainter(
                time: time,
                separation: separation,
                correlation: correlation,
                entanglementType: entanglementType,
                particleAResult: particleAResult,
                particleBResult: particleBResult,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimSegment<int>(
                label: isKorean ? '얽힘 유형' : 'Entanglement Type',
                options: {
                  0: isKorean ? '벨 상태' : 'Bell State',
                  1: isKorean ? 'GHZ 상태' : 'GHZ State',
                },
                selected: entanglementType,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    entanglementType = v;
                    _reset();
                  });
                },
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '입자 분리 거리' : 'Particle Separation',
                  value: separation,
                  min: 50,
                  max: 250,
                  defaultValue: _defaultSeparation,
                  formatValue: (v) => '${v.toInt()} px',
                  onChanged: (v) => setState(() => separation = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '상관관계 강도' : 'Correlation Strength',
                    value: correlation,
                    min: 0,
                    max: 1,
                    defaultValue: _defaultCorrelation,
                    formatValue: (v) => '${(v * 100).toInt()}%',
                    onChanged: (v) => setState(() => correlation = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                measurementCount: measurementCount,
                correlationRate: correlationRate,
                particleAResult: particleAResult,
                particleBResult: particleBResult,
                isKorean: isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '입자 A 측정' : 'Measure A',
                icon: Icons.radio_button_checked,
                onPressed: _measureA,
              ),
              SimButton(
                label: isKorean ? '동시 측정' : 'Measure Both',
                icon: Icons.compare_arrows,
                isPrimary: true,
                onPressed: _measureBoth,
              ),
              SimButton(
                label: isKorean ? '입자 B 측정' : 'Measure B',
                icon: Icons.radio_button_checked,
                onPressed: _measureB,
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
  final int measurementCount;
  final double correlationRate;
  final bool? particleAResult;
  final bool? particleBResult;
  final bool isKorean;

  const _PhysicsInfo({
    required this.measurementCount,
    required this.correlationRate,
    required this.particleAResult,
    required this.particleBResult,
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
            label: isKorean ? '측정 횟수' : 'Measurements',
            value: '$measurementCount',
          ),
          _InfoItem(
            label: isKorean ? '상관율' : 'Correlation',
            value: '${correlationRate.toStringAsFixed(1)}%',
          ),
          _InfoItem(
            label: 'A | B',
            value: '${_stateString(particleAResult)} | ${_stateString(particleBResult)}',
          ),
        ],
      ),
    );
  }

  String _stateString(bool? result) {
    if (result == null) return '?';
    return result ? '↑' : '↓';
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

class EntanglementPainter extends CustomPainter {
  final double time;
  final double separation;
  final double correlation;
  final int entanglementType;
  final bool? particleAResult;
  final bool? particleBResult;

  EntanglementPainter({
    required this.time,
    required this.separation,
    required this.correlation,
    required this.entanglementType,
    required this.particleAResult,
    required this.particleBResult,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawEntanglementConnection(canvas, size);
    _drawParticles(canvas, size);
    _drawMeasurementResults(canvas, size);
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

  void _drawEntanglementConnection(Canvas canvas, Size size) {
    final centerY = size.height * 0.45;
    final particleAX = size.width / 2 - separation / 2;
    final particleBX = size.width / 2 + separation / 2;

    // Draw wavy entanglement line
    final path = Path();
    path.moveTo(particleAX, centerY);

    for (double x = particleAX; x <= particleBX; x += 2) {
      final progress = (x - particleAX) / (particleBX - particleAX);
      final wave = math.sin(progress * math.pi * 4 + time * 3) * 15 * (1 - math.pow(2 * progress - 1, 2));
      path.lineTo(x, centerY + wave);
    }

    // Glow effect for connection
    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = const Color(0xFF805AD5).withValues(alpha: 0.1 * i * correlation)
        ..strokeWidth = 3.0 + i * 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glowPaint);
    }

    // Main connection line
    final connectionPaint = Paint()
      ..color = const Color(0xFF805AD5).withValues(alpha: 0.8 * correlation)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, connectionPaint);

    // Quantum correlation indicator
    if (particleAResult != null && particleBResult != null) {
      final indicatorPaint = Paint()
        ..color = particleAResult != particleBResult
            ? const Color(0xFF48BB78)
            : const Color(0xFFFC8181)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(particleAX, centerY),
        Offset(particleBX, centerY),
        indicatorPaint,
      );
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    final centerY = size.height * 0.45;
    final particleAX = size.width / 2 - separation / 2;
    final particleBX = size.width / 2 + separation / 2;
    final radius = 30.0;

    // Particle A
    _drawParticle(canvas, particleAX, centerY, radius, particleAResult, 'A');

    // Particle B
    _drawParticle(canvas, particleBX, centerY, radius, particleBResult, 'B');
  }

  void _drawParticle(
    Canvas canvas,
    double x,
    double y,
    double radius,
    bool? result,
    String label,
  ) {
    // Outer glow
    final glowGradient = RadialGradient(
      colors: [
        AppColors.accent.withValues(alpha: 0.5),
        AppColors.accent.withValues(alpha: 0.1),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius * 1.5));

    canvas.drawCircle(
      Offset(x, y),
      radius * 1.5,
      Paint()..shader = glowGradient,
    );

    // Main particle
    final particleColor = result == null
        ? AppColors.accent
        : (result ? const Color(0xFF48BB78) : const Color(0xFFFC8181));

    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()..color = particleColor.withValues(alpha: 0.8),
    );

    // Spin arrow if measured
    if (result != null) {
      final arrowPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final arrowY = result ? -radius * 0.5 : radius * 0.5;
      canvas.drawLine(
        Offset(x, y + arrowY),
        Offset(x, y - arrowY),
        arrowPaint,
      );

      // Arrowhead
      final headY = result ? y - radius * 0.5 : y + radius * 0.5;
      final headDir = result ? -1 : 1;
      canvas.drawLine(
        Offset(x, headY),
        Offset(x - 8, headY + 8 * headDir),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(x, headY),
        Offset(x + 8, headY + 8 * headDir),
        arrowPaint,
      );
    } else {
      // Superposition indicator (rotating arrow)
      final angle = time * 2;
      final arrowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawLine(
        const Offset(0, -15),
        const Offset(0, 15),
        arrowPaint,
      );
      canvas.restore();
    }

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
    textPainter.paint(canvas, Offset(x - 5, y + radius + 10));
  }

  void _drawMeasurementResults(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final centerY = size.height * 0.45;
    final particleAX = size.width / 2 - separation / 2;
    final particleBX = size.width / 2 + separation / 2;

    // Particle A result
    if (particleAResult != null) {
      textPainter.text = TextSpan(
        text: particleAResult! ? '|↑⟩' : '|↓⟩',
        style: TextStyle(
          color: particleAResult! ? const Color(0xFF48BB78) : const Color(0xFFFC8181),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(particleAX - 15, centerY - 70));
    }

    // Particle B result
    if (particleBResult != null) {
      textPainter.text = TextSpan(
        text: particleBResult! ? '|↑⟩' : '|↓⟩',
        style: TextStyle(
          color: particleBResult! ? const Color(0xFF48BB78) : const Color(0xFFFC8181),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(particleBX - 15, centerY - 70));
    }
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // State label
    final stateText = entanglementType == 0
        ? '|Ψ⁻⟩ = (|01⟩ - |10⟩)/√2'
        : '|GHZ⟩ = (|000⟩ + |111⟩)/√2';

    textPainter.text = TextSpan(
      text: stateText,
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 13,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.1));

    // Distance label
    textPainter.text = TextSpan(
      text: 'd = ${separation.toInt()} (distance)',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 11,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.75));

    // EPR note
    textPainter.text = TextSpan(
      text: '"Spooky action at a distance" - Einstein',
      style: TextStyle(
        color: AppColors.muted.withValues(alpha: 0.7),
        fontSize: 10,
        fontStyle: FontStyle.italic,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.88));
  }

  @override
  bool shouldRepaint(covariant EntanglementPainter oldDelegate) =>
      time != oldDelegate.time ||
      separation != oldDelegate.separation ||
      particleAResult != oldDelegate.particleAResult ||
      particleBResult != oldDelegate.particleBResult;
}
