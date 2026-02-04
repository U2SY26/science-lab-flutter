import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Stern-Gerlach Experiment Simulation
/// 슈테른-게를라흐 실험 시뮬레이션
class SternGerlachScreen extends StatefulWidget {
  const SternGerlachScreen({super.key});

  @override
  State<SternGerlachScreen> createState() => _SternGerlachScreenState();
}

class _SternGerlachScreenState extends State<SternGerlachScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const double _defaultMagneticGradient = 50.0;
  static const double _defaultBeamSpeed = 50.0;

  double magneticGradient = _defaultMagneticGradient;
  double beamSpeed = _defaultBeamSpeed;
  bool isRunning = true;
  int experimentType = 0; // 0: single, 1: sequential, 2: three stages

  double time = 0;
  bool isKorean = true;
  final math.Random _random = math.Random();

  // Particles in beam
  List<SGParticle> particles = [];
  int upCount = 0;
  int downCount = 0;

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

      // Emit new particle
      if (_random.nextDouble() < 0.1) {
        _emitParticle();
      }

      // Update particles
      _updateParticles();
    });
  }

  void _emitParticle() {
    // Random initial spin orientation
    final spinAngle = _random.nextDouble() * 2 * math.pi;
    particles.add(SGParticle(
      x: 0,
      y: 0,
      vx: beamSpeed * 0.02,
      vy: 0,
      spinAngle: spinAngle,
      stage: 0,
      measured: false,
      spinUp: null,
    ));
  }

  void _updateParticles() {
    final toRemove = <SGParticle>[];

    for (final p in particles) {
      p.x += p.vx;

      // Stage 1: First SG apparatus
      if (p.x > 0.25 && p.x < 0.35 && !p.measured) {
        // Measurement! Collapse to spin up or down
        p.measured = true;
        final probUp = math.pow(math.cos(p.spinAngle / 2), 2);
        p.spinUp = _random.nextDouble() < probUp;
        p.stage = 1;
      }

      // After measurement, deflect
      if (p.measured && p.stage >= 1) {
        final deflection = p.spinUp! ? -1 : 1;
        p.vy = deflection * magneticGradient * 0.002;
      }

      p.y += p.vy;

      // Count at detector
      if (p.x > 0.9) {
        if (p.spinUp != null) {
          if (p.spinUp!) {
            upCount++;
          } else {
            downCount++;
          }
        }
        toRemove.add(p);
      }
    }

    particles.removeWhere((p) => toRemove.contains(p));
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      particles.clear();
      upCount = 0;
      downCount = 0;
      magneticGradient = _defaultMagneticGradient;
      beamSpeed = _defaultBeamSpeed;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = upCount + downCount;
    final upPercent = total > 0 ? (upCount / total * 100) : 50.0;
    final downPercent = total > 0 ? (downCount / total * 100) : 50.0;

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
              isKorean ? '슈테른-게를라흐 실험' : 'Stern-Gerlach',
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
          title: isKorean ? '슈테른-게를라흐 실험' : 'Stern-Gerlach Experiment',
          formula: 'F = μ·(∂B/∂z)',
          formulaDescription: isKorean
              ? '비균일 자기장을 통과하는 은 원자 빔이 두 갈래로 나뉩니다. '
                  '이는 스핀 양자수가 두 값(±ℏ/2)만 가질 수 있음을 보여주는 실험입니다.'
              : 'A beam of silver atoms passing through an inhomogeneous magnetic field splits into two. '
                  'This demonstrates that spin quantum number can only have two values (±ℏ/2).',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: SternGerlachPainter(
                time: time,
                magneticGradient: magneticGradient,
                particles: particles,
                experimentType: experimentType,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimSegment<int>(
                label: isKorean ? '실험 유형' : 'Experiment Type',
                options: {
                  0: isKorean ? '단일' : 'Single',
                  1: isKorean ? '연속' : 'Sequential',
                  2: isKorean ? '3단계' : 'Three Stage',
                },
                selected: experimentType,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    experimentType = v;
                    _reset();
                  });
                },
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '자기장 기울기' : 'Magnetic Gradient',
                  value: magneticGradient,
                  min: 20,
                  max: 100,
                  defaultValue: _defaultMagneticGradient,
                  formatValue: (v) => '${v.toInt()}',
                  onChanged: (v) => setState(() => magneticGradient = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '빔 속도' : 'Beam Speed',
                    value: beamSpeed,
                    min: 20,
                    max: 100,
                    defaultValue: _defaultBeamSpeed,
                    formatValue: (v) => '${v.toInt()}',
                    onChanged: (v) => setState(() => beamSpeed = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                upCount: upCount,
                downCount: downCount,
                upPercent: upPercent,
                downPercent: downPercent,
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

class SGParticle {
  double x; // normalized position (0 to 1)
  double y; // vertical deviation
  double vx;
  double vy;
  double spinAngle; // initial spin orientation
  int stage;
  bool measured;
  bool? spinUp;

  SGParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.spinAngle,
    required this.stage,
    required this.measured,
    required this.spinUp,
  });
}

class _PhysicsInfo extends StatelessWidget {
  final int upCount;
  final int downCount;
  final double upPercent;
  final double downPercent;
  final bool isKorean;

  const _PhysicsInfo({
    required this.upCount,
    required this.downCount,
    required this.upPercent,
    required this.downPercent,
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
            label: isKorean ? '스핀 업 (↑)' : 'Spin Up (↑)',
            value: '$upCount (${upPercent.toStringAsFixed(1)}%)',
          ),
          _InfoItem(
            label: isKorean ? '스핀 다운 (↓)' : 'Spin Down (↓)',
            value: '$downCount (${downPercent.toStringAsFixed(1)}%)',
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

class SternGerlachPainter extends CustomPainter {
  final double time;
  final double magneticGradient;
  final List<SGParticle> particles;
  final int experimentType;

  SternGerlachPainter({
    required this.time,
    required this.magneticGradient,
    required this.particles,
    required this.experimentType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawApparatus(canvas, size);
    _drawMagneticField(canvas, size);
    _drawParticles(canvas, size);
    _drawDetectors(canvas, size);
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

  void _drawApparatus(Canvas canvas, Size size) {
    final centerY = size.height * 0.45;

    // Source (oven)
    final ovenRect = Rect.fromLTWH(20, centerY - 25, 40, 50);
    canvas.drawRRect(
      RRect.fromRectAndRadius(ovenRect, const Radius.circular(5)),
      Paint()..color = const Color(0xFF4A5568),
    );

    // Heat glow
    final heatGradient = RadialGradient(
      colors: [
        const Color(0xFFFF6B6B).withValues(alpha: 0.5 + 0.2 * math.sin(time * 3)),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: ovenRect.center, radius: 30));
    canvas.drawCircle(ovenRect.center, 30, Paint()..shader = heatGradient);

    // Collimator
    final collimatorX = size.width * 0.15;
    canvas.drawRect(
      Rect.fromLTWH(collimatorX, centerY - 40, 10, 30),
      Paint()..color = const Color(0xFF4A5568),
    );
    canvas.drawRect(
      Rect.fromLTWH(collimatorX, centerY + 10, 10, 30),
      Paint()..color = const Color(0xFF4A5568),
    );

    // SG Magnet housing
    final magnetX = size.width * 0.25;
    final magnetWidth = size.width * 0.15;
    final magnetHeight = 80.0;

    // North pole (pointed)
    final northPath = Path()
      ..moveTo(magnetX, centerY - magnetHeight)
      ..lineTo(magnetX + magnetWidth, centerY - magnetHeight)
      ..lineTo(magnetX + magnetWidth, centerY - 20)
      ..lineTo(magnetX + magnetWidth / 2, centerY - 5)
      ..lineTo(magnetX, centerY - 20)
      ..close();

    canvas.drawPath(northPath, Paint()..color = const Color(0xFFFC8181));

    // South pole (flat)
    final southPath = Path()
      ..moveTo(magnetX, centerY + magnetHeight)
      ..lineTo(magnetX + magnetWidth, centerY + magnetHeight)
      ..lineTo(magnetX + magnetWidth, centerY + 20)
      ..lineTo(magnetX, centerY + 20)
      ..close();

    canvas.drawPath(southPath, Paint()..color = const Color(0xFF63B3ED));

    // N and S labels
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(magnetX + magnetWidth / 2 - 5, centerY - magnetHeight + 10));

    textPainter.text = TextSpan(
      text: 'S',
      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(magnetX + magnetWidth / 2 - 5, centerY + magnetHeight - 25));
  }

  void _drawMagneticField(Canvas canvas, Size size) {
    final centerY = size.height * 0.45;
    final magnetX = size.width * 0.25;
    final magnetWidth = size.width * 0.15;

    // Draw field lines (non-uniform)
    final fieldPaint = Paint()
      ..color = const Color(0xFF805AD5).withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      final yOffset = (i - 2) * 15.0;
      final path = Path();
      path.moveTo(magnetX + 10, centerY + yOffset - 50);

      // Non-uniform field - stronger gradient near pointed pole
      for (double y = centerY + yOffset - 50; y < centerY + yOffset + 50; y += 5) {
        final curvature = (y - centerY) * 0.01;
        path.lineTo(magnetX + magnetWidth / 2 + curvature * 30, y);
      }

      canvas.drawPath(path, fieldPaint);
    }

    // Gradient indicator arrow
    canvas.drawLine(
      Offset(magnetX + magnetWidth + 20, centerY),
      Offset(magnetX + magnetWidth + 20, centerY - 40),
      Paint()
        ..color = const Color(0xFF805AD5)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(magnetX + magnetWidth + 20, centerY - 40),
      Offset(magnetX + magnetWidth + 15, centerY - 30),
      Paint()
        ..color = const Color(0xFF805AD5)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(magnetX + magnetWidth + 20, centerY - 40),
      Offset(magnetX + magnetWidth + 25, centerY - 30),
      Paint()
        ..color = const Color(0xFF805AD5)
        ..strokeWidth = 2,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '∂B/∂z',
        style: TextStyle(
          color: const Color(0xFF805AD5),
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(magnetX + magnetWidth + 10, centerY - 55));
  }

  void _drawParticles(Canvas canvas, Size size) {
    final centerY = size.height * 0.45;
    final maxDeflection = magneticGradient * 0.8;

    for (final p in particles) {
      final screenX = 80 + p.x * (size.width - 120);
      final screenY = centerY + p.y * maxDeflection;

      // Particle color based on spin state
      Color particleColor;
      if (!p.measured) {
        // Superposition - purple
        particleColor = const Color(0xFF805AD5);
      } else if (p.spinUp!) {
        particleColor = const Color(0xFF48BB78);
      } else {
        particleColor = const Color(0xFFFC8181);
      }

      // Particle glow
      canvas.drawCircle(
        Offset(screenX, screenY),
        8,
        Paint()..color = particleColor.withValues(alpha: 0.3),
      );

      // Particle
      canvas.drawCircle(
        Offset(screenX, screenY),
        4,
        Paint()..color = particleColor,
      );

      // Spin arrow
      if (p.measured && p.spinUp != null) {
        final arrowDir = p.spinUp! ? -1 : 1;
        canvas.drawLine(
          Offset(screenX, screenY + arrowDir * 8),
          Offset(screenX, screenY - arrowDir * 8),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _drawDetectors(Canvas canvas, Size size) {
    final centerY = size.height * 0.45;
    final detectorX = size.width - 50;
    final maxDeflection = magneticGradient * 0.8;

    // Upper detector (spin up)
    final upperY = centerY - maxDeflection;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(detectorX, upperY - 20, 30, 40),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF48BB78).withValues(alpha: 0.3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(detectorX, upperY - 20, 30, 40),
        const Radius.circular(5),
      ),
      Paint()
        ..color = const Color(0xFF48BB78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Lower detector (spin down)
    final lowerY = centerY + maxDeflection;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(detectorX, lowerY - 20, 30, 40),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFFC8181).withValues(alpha: 0.3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(detectorX, lowerY - 20, 30, 40),
        const Radius.circular(5),
      ),
      Paint()
        ..color = const Color(0xFFFC8181)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: '↑',
      style: TextStyle(color: const Color(0xFF48BB78), fontSize: 18, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(detectorX + 10, upperY - 8));

    textPainter.text = TextSpan(
      text: '↓',
      style: TextStyle(color: const Color(0xFFFC8181), fontSize: 18, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(detectorX + 10, lowerY - 8));
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Source label
    textPainter.text = TextSpan(
      text: 'Ag atoms',
      style: TextStyle(color: AppColors.muted, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(20, size.height * 0.7));

    // Magnet label
    textPainter.text = TextSpan(
      text: 'SG Magnet',
      style: TextStyle(color: AppColors.muted, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.27, size.height * 0.85));

    // Result explanation
    textPainter.text = TextSpan(
      text: 'Quantized spin: ms = ±½',
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.92));
  }

  @override
  bool shouldRepaint(covariant SternGerlachPainter oldDelegate) =>
      time != oldDelegate.time ||
      magneticGradient != oldDelegate.magneticGradient ||
      particles.length != oldDelegate.particles.length;
}
