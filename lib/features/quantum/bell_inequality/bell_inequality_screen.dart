import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Bell's Inequality Simulation
/// 벨 부등식 시뮬레이션
class BellInequalityScreen extends StatefulWidget {
  const BellInequalityScreen({super.key});

  @override
  State<BellInequalityScreen> createState() => _BellInequalityScreenState();
}

class _BellInequalityScreenState extends State<BellInequalityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const double _defaultAngleA = 0.0;
  static const double _defaultAngleB = 45.0;

  double angleA = _defaultAngleA; // Detector A angle
  double angleB = _defaultAngleB; // Detector B angle
  bool isRunning = true;
  bool useQuantum = true; // true: quantum, false: classical hidden variables

  double time = 0;
  bool isKorean = true;
  final math.Random _random = math.Random();

  // Statistics
  int totalMeasurements = 0;
  int sameResults = 0;
  int differentResults = 0;

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
      angleA = _defaultAngleA;
      angleB = _defaultAngleB;
      totalMeasurements = 0;
      sameResults = 0;
      differentResults = 0;
    });
  }

  void _runExperiment() {
    HapticFeedback.selectionClick();

    for (int i = 0; i < 100; i++) {
      final result = _measurePair();
      if (result.$1 == result.$2) {
        sameResults++;
      } else {
        differentResults++;
      }
      totalMeasurements++;
    }

    setState(() {});
  }

  (bool, bool) _measurePair() {
    final angleArad = angleA * math.pi / 180;
    final angleBrad = angleB * math.pi / 180;
    final angleDiff = (angleB - angleA) * math.pi / 180;

    if (useQuantum) {
      // Quantum mechanics prediction
      // P(same) = cos²(θ/2), P(different) = sin²(θ/2)
      final probSame = math.pow(math.cos(angleDiff / 2), 2);
      final resultA = _random.nextBool();
      final resultB = _random.nextDouble() < probSame ? resultA : !resultA;
      return (resultA, resultB);
    } else {
      // Classical hidden variable prediction
      // Assumes predetermined values along random hidden axis
      final hiddenAngle = _random.nextDouble() * 2 * math.pi;
      final resultA = math.cos(hiddenAngle - angleArad) > 0;
      final resultB = math.cos(hiddenAngle - angleBrad) > 0;
      return (resultA, resultB);
    }
  }

  double get correlationCoefficient {
    if (totalMeasurements == 0) return 0;
    // E(a,b) = (N_same - N_different) / N_total
    return (sameResults - differentResults) / totalMeasurements;
  }

  double get quantumPrediction {
    final angleDiff = (angleB - angleA) * math.pi / 180;
    // Quantum: E(a,b) = -cos(θ) for singlet state
    return -math.cos(angleDiff);
  }

  double get bellLimit {
    // Bell inequality limit for classical theories
    return 2.0;
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
              isKorean ? '양자역학 시뮬레이션' : 'QUANTUM MECHANICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '벨 부등식' : "Bell's Inequality",
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
          title: isKorean ? '벨 부등식' : "Bell's Inequality",
          formula: '|E(a,b) - E(a,c)| + E(b,c) ≤ 2',
          formulaDescription: isKorean
              ? '벨 부등식은 숨은 변수 이론의 한계를 보여줍니다. 양자역학의 예측은 이 한계를 초과하며, '
                  '이는 "으스스한 원격 작용"이 실재함을 증명합니다.'
              : "Bell's inequality shows the limits of hidden variable theories. Quantum mechanics "
                  'predictions exceed this limit, proving "spooky action at a distance" is real.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: BellInequalityPainter(
                time: time,
                angleA: angleA,
                angleB: angleB,
                correlation: correlationCoefficient,
                quantumPrediction: quantumPrediction,
                useQuantum: useQuantum,
                totalMeasurements: totalMeasurements,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimSegment<bool>(
                label: isKorean ? '이론 모델' : 'Theory Model',
                options: {
                  true: isKorean ? '양자역학' : 'Quantum',
                  false: isKorean ? '숨은 변수' : 'Hidden Var.',
                },
                selected: useQuantum,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    useQuantum = v;
                    _reset();
                  });
                },
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '검출기 A 각도' : 'Detector A Angle',
                  value: angleA,
                  min: 0,
                  max: 180,
                  defaultValue: _defaultAngleA,
                  formatValue: (v) => '${v.toInt()}°',
                  onChanged: (v) {
                    setState(() {
                      angleA = v;
                      _reset();
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '검출기 B 각도' : 'Detector B Angle',
                    value: angleB,
                    min: 0,
                    max: 180,
                    defaultValue: _defaultAngleB,
                    formatValue: (v) => '${v.toInt()}°',
                    onChanged: (v) {
                      setState(() {
                        angleB = v;
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                correlation: correlationCoefficient,
                quantumPrediction: quantumPrediction,
                totalMeasurements: totalMeasurements,
                sameResults: sameResults,
                differentResults: differentResults,
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
                label: isKorean ? '실험 (×100)' : 'Experiment',
                icon: Icons.science,
                onPressed: _runExperiment,
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
  final double correlation;
  final double quantumPrediction;
  final int totalMeasurements;
  final int sameResults;
  final int differentResults;
  final bool isKorean;

  const _PhysicsInfo({
    required this.correlation,
    required this.quantumPrediction,
    required this.totalMeasurements,
    required this.sameResults,
    required this.differentResults,
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
                label: 'E(a,b)',
                value: correlation.toStringAsFixed(3),
              ),
              _InfoItem(
                label: isKorean ? 'QM 예측' : 'QM Prediction',
                value: quantumPrediction.toStringAsFixed(3),
              ),
              _InfoItem(
                label: isKorean ? '측정' : 'Measurements',
                value: '$totalMeasurements',
              ),
            ],
          ),
          if (totalMeasurements > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoItem(
                  label: isKorean ? '같음' : 'Same',
                  value: '$sameResults',
                ),
                _InfoItem(
                  label: isKorean ? '다름' : 'Different',
                  value: '$differentResults',
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

class BellInequalityPainter extends CustomPainter {
  final double time;
  final double angleA;
  final double angleB;
  final double correlation;
  final double quantumPrediction;
  final bool useQuantum;
  final int totalMeasurements;

  BellInequalityPainter({
    required this.time,
    required this.angleA,
    required this.angleB,
    required this.correlation,
    required this.quantumPrediction,
    required this.useQuantum,
    required this.totalMeasurements,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawExperimentSetup(canvas, size);
    _drawCorrelationGraph(canvas, size);
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

  void _drawExperimentSetup(Canvas canvas, Size size) {
    final centerY = size.height * 0.3;

    // Source in middle
    final sourceX = size.width / 2;
    canvas.drawCircle(
      Offset(sourceX, centerY),
      15,
      Paint()..color = const Color(0xFF805AD5),
    );
    canvas.drawCircle(
      Offset(sourceX, centerY),
      25,
      Paint()..color = const Color(0xFF805AD5).withValues(alpha: 0.3),
    );

    // Entangled pair emission
    final particleProgress = (time * 2) % 2;
    if (particleProgress < 1) {
      final distance = particleProgress * 100;

      // Particle to A
      canvas.drawCircle(
        Offset(sourceX - distance, centerY),
        6,
        Paint()..color = const Color(0xFF48BB78),
      );

      // Particle to B
      canvas.drawCircle(
        Offset(sourceX + distance, centerY),
        6,
        Paint()..color = const Color(0xFFFC8181),
      );

      // Entanglement line
      final wavePaint = Paint()
        ..color = const Color(0xFF805AD5).withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final wavePath = Path();
      wavePath.moveTo(sourceX - distance, centerY);
      for (double x = sourceX - distance; x <= sourceX + distance; x += 3) {
        final wave = 5 * math.sin((x - sourceX) * 0.2 + time * 5);
        wavePath.lineTo(x, centerY + wave);
      }
      canvas.drawPath(wavePath, wavePaint);
    }

    // Detector A
    final detectorAX = sourceX - 130;
    _drawDetector(canvas, detectorAX, centerY, angleA, 'A', const Color(0xFF48BB78));

    // Detector B
    final detectorBX = sourceX + 130;
    _drawDetector(canvas, detectorBX, centerY, angleB, 'B', const Color(0xFFFC8181));
  }

  void _drawDetector(Canvas canvas, double x, double y, double angle, String label, Color color) {
    final angleRad = angle * math.pi / 180;

    // Detector body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 40, height: 60),
        const Radius.circular(5),
      ),
      Paint()..color = color.withValues(alpha: 0.3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 40, height: 60),
        const Radius.circular(5),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Polarization angle indicator
    final arrowLength = 20.0;
    canvas.drawLine(
      Offset(x - arrowLength * math.cos(angleRad), y - arrowLength * math.sin(angleRad)),
      Offset(x + arrowLength * math.cos(angleRad), y + arrowLength * math.sin(angleRad)),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$label (${angle.toInt()}°)',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y + 40));
  }

  void _drawCorrelationGraph(Canvas canvas, Size size) {
    final graphLeft = size.width * 0.15;
    final graphRight = size.width * 0.85;
    final graphTop = size.height * 0.55;
    final graphBottom = size.height * 0.85;
    final graphWidth = graphRight - graphLeft;
    final graphHeight = graphBottom - graphTop;
    final graphCenterY = graphTop + graphHeight / 2;

    // Axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.6)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(graphLeft, graphCenterY),
      Offset(graphRight, graphCenterY),
      axisPaint,
    );
    canvas.drawLine(
      Offset(graphLeft, graphTop),
      Offset(graphLeft, graphBottom),
      axisPaint,
    );

    // Quantum prediction curve: E(θ) = -cos(θ)
    final quantumPath = Path();
    quantumPath.moveTo(graphLeft, graphCenterY + graphHeight / 2); // θ=0: E=-1

    for (double x = 0; x <= graphWidth; x += 2) {
      final theta = (x / graphWidth) * math.pi;
      final e = -math.cos(theta);
      final screenY = graphCenterY - e * graphHeight / 2;
      quantumPath.lineTo(graphLeft + x, screenY);
    }

    canvas.drawPath(
      quantumPath,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Classical limit (straight line from -1 to +1)
    final classicalPath = Path();
    classicalPath.moveTo(graphLeft, graphCenterY + graphHeight / 2);
    classicalPath.lineTo(graphRight, graphCenterY - graphHeight / 2);

    canvas.drawPath(
      classicalPath,
      Paint()
        ..color = const Color(0xFFED8936).withValues(alpha: 0.7)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Current angle marker
    final currentX = graphLeft + (angleB - angleA).abs() / 180 * graphWidth;
    canvas.drawLine(
      Offset(currentX, graphTop),
      Offset(currentX, graphBottom),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // Measured correlation point
    if (totalMeasurements > 0) {
      final measuredY = graphCenterY - correlation * graphHeight / 2;
      canvas.drawCircle(
        Offset(currentX, measuredY),
        6,
        Paint()..color = useQuantum ? AppColors.accent : const Color(0xFFED8936),
      );
    }

    // Legend
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: 'QM',
      style: TextStyle(color: AppColors.accent, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(graphRight - 30, graphTop - 15));

    textPainter.text = TextSpan(
      text: 'Classical',
      style: TextStyle(color: const Color(0xFFED8936), fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(graphRight - 50, graphTop));

    // Axis labels
    textPainter.text = TextSpan(
      text: 'θ (angle difference)',
      style: TextStyle(color: AppColors.muted, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(graphLeft + graphWidth / 2 - textPainter.width / 2, graphBottom + 5));

    textPainter.text = TextSpan(
      text: '+1',
      style: TextStyle(color: AppColors.muted, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(graphLeft - 20, graphTop - 5));

    textPainter.text = TextSpan(
      text: '-1',
      style: TextStyle(color: AppColors.muted, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(graphLeft - 20, graphBottom - 5));
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Source label
    textPainter.text = TextSpan(
      text: 'EPR Source',
      style: TextStyle(
        color: const Color(0xFF805AD5),
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.38));

    // Bell violation indicator
    final angleDiff = (angleB - angleA).abs() * math.pi / 180;
    final qmCorr = -math.cos(angleDiff);
    final classicalLimit = 1 - 2 * angleDiff / math.pi;
    final isViolation = qmCorr.abs() > classicalLimit.abs() && angleDiff > 0;

    if (isViolation) {
      textPainter.text = TextSpan(
        text: 'Bell Inequality Violated!',
        style: TextStyle(
          color: const Color(0xFF48BB78),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.02));
    }
  }

  @override
  bool shouldRepaint(covariant BellInequalityPainter oldDelegate) =>
      time != oldDelegate.time ||
      angleA != oldDelegate.angleA ||
      angleB != oldDelegate.angleB ||
      correlation != oldDelegate.correlation ||
      useQuantum != oldDelegate.useQuantum ||
      totalMeasurements != oldDelegate.totalMeasurements;
}
