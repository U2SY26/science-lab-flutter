import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Heisenberg Uncertainty Principle Simulation
/// 하이젠베르크 불확정성 원리 시뮬레이션 (Δx·Δp ≥ ℏ/2)
class HeisenbergScreen extends StatefulWidget {
  const HeisenbergScreen({super.key});

  @override
  State<HeisenbergScreen> createState() => _HeisenbergScreenState();
}

class _HeisenbergScreenState extends State<HeisenbergScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const double _defaultPositionUncertainty = 50.0;
  static const double _defaultMeasurePosition = 0.5;

  double positionUncertainty = _defaultPositionUncertainty;
  double measurePosition = _defaultMeasurePosition;
  bool isRunning = true;
  bool showMomentum = true;

  double time = 0;
  bool isKorean = true;
  final math.Random _random = math.Random();

  // Particles for visualization
  List<UncertainParticle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);
    _controller.repeat();
    _generateParticles();
  }

  void _generateParticles() {
    particles.clear();
    final momentumUncertainty = _calculateMomentumUncertainty();

    for (int i = 0; i < 100; i++) {
      final posOffset = (_random.nextDouble() - 0.5) * 2 * positionUncertainty;
      final momOffset = (_random.nextDouble() - 0.5) * 2 * momentumUncertainty;

      particles.add(UncertainParticle(
        x: measurePosition * 300 + posOffset,
        y: 150,
        px: momOffset * 0.5,
        py: (_random.nextDouble() - 0.5) * momOffset * 0.2,
      ));
    }
  }

  double _calculateMomentumUncertainty() {
    // Δp ≥ ℏ/(2Δx), simplified for visualization
    const hbar = 50.0; // Scaled Planck constant
    return hbar / (2 * positionUncertainty);
  }

  void _updatePhysics() {
    if (!isRunning) return;
    setState(() {
      time += 0.05;

      // Update particle positions based on their momenta
      for (final p in particles) {
        p.x += p.px * 0.1;
        p.y += p.py * 0.1;

        // Periodic boundary
        if (p.x < 0) p.x += 300;
        if (p.x > 300) p.x -= 300;
        if (p.y < 50) p.y = 50;
        if (p.y > 250) p.y = 250;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      positionUncertainty = _defaultPositionUncertainty;
      measurePosition = _defaultMeasurePosition;
      _generateParticles();
    });
  }

  void _measure() {
    HapticFeedback.heavyImpact();
    setState(() {
      _generateParticles();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final momentumUncertainty = _calculateMomentumUncertainty();
    final uncertaintyProduct = positionUncertainty * momentumUncertainty;

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
              isKorean ? '불확정성 원리' : 'Uncertainty Principle',
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
          title: isKorean ? '하이젠베르크 불확정성 원리' : 'Heisenberg Uncertainty',
          formula: 'Δx·Δp ≥ ℏ/2',
          formulaDescription: isKorean
              ? '위치(Δx)와 운동량(Δp)을 동시에 정확하게 측정하는 것은 불가능합니다. '
                  '위치를 더 정확하게 측정할수록 운동량의 불확정성이 커지고, 그 반대도 마찬가지입니다.'
              : 'It is impossible to simultaneously measure position (Δx) and momentum (Δp) with perfect accuracy. '
                  'The more precisely position is measured, the greater the uncertainty in momentum, and vice versa.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: HeisenbergPainter(
                time: time,
                positionUncertainty: positionUncertainty,
                momentumUncertainty: momentumUncertainty,
                measurePosition: measurePosition,
                particles: particles,
                showMomentum: showMomentum,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimSegment<bool>(
                label: isKorean ? '표시 모드' : 'Display Mode',
                options: {
                  true: isKorean ? '운동량 표시' : 'Show Momentum',
                  false: isKorean ? '위치만' : 'Position Only',
                },
                selected: showMomentum,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => showMomentum = v);
                },
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '위치 불확정성 (Δx)' : 'Position Uncertainty (Δx)',
                  value: positionUncertainty,
                  min: 10,
                  max: 100,
                  defaultValue: _defaultPositionUncertainty,
                  formatValue: (v) => '${v.toInt()}',
                  onChanged: (v) {
                    setState(() {
                      positionUncertainty = v;
                      _generateParticles();
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '측정 위치' : 'Measurement Position',
                    value: measurePosition,
                    min: 0.2,
                    max: 0.8,
                    defaultValue: _defaultMeasurePosition,
                    formatValue: (v) => '${(v * 100).toInt()}%',
                    onChanged: (v) {
                      setState(() {
                        measurePosition = v;
                        _generateParticles();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                positionUncertainty: positionUncertainty,
                momentumUncertainty: momentumUncertainty,
                product: uncertaintyProduct,
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

class UncertainParticle {
  double x;
  double y;
  double px; // momentum x
  double py; // momentum y

  UncertainParticle({
    required this.x,
    required this.y,
    required this.px,
    required this.py,
  });
}

class _PhysicsInfo extends StatelessWidget {
  final double positionUncertainty;
  final double momentumUncertainty;
  final double product;
  final bool isKorean;

  const _PhysicsInfo({
    required this.positionUncertainty,
    required this.momentumUncertainty,
    required this.product,
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
            label: 'Δx',
            value: positionUncertainty.toStringAsFixed(1),
          ),
          _InfoItem(
            label: 'Δp',
            value: momentumUncertainty.toStringAsFixed(1),
          ),
          _InfoItem(
            label: 'Δx·Δp',
            value: '≥ ${(product).toStringAsFixed(0)}',
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

class HeisenbergPainter extends CustomPainter {
  final double time;
  final double positionUncertainty;
  final double momentumUncertainty;
  final double measurePosition;
  final List<UncertainParticle> particles;
  final bool showMomentum;

  HeisenbergPainter({
    required this.time,
    required this.positionUncertainty,
    required this.momentumUncertainty,
    required this.measurePosition,
    required this.particles,
    required this.showMomentum,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawUncertaintyRegion(canvas, size);
    _drawParticles(canvas, size);
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

  void _drawUncertaintyRegion(Canvas canvas, Size size) {
    final centerX = 50 + measurePosition * (size.width - 100);
    final centerY = size.height * 0.45;

    // Position uncertainty region
    final positionPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: positionUncertainty * 2,
        height: 150,
      ),
      positionPaint,
    );

    // Position uncertainty border
    final borderPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: positionUncertainty * 2,
        height: 150,
      ),
      borderPaint,
    );

    // Momentum distribution (phase space)
    if (showMomentum) {
      final phaseY = size.height * 0.8;

      // Draw phase space diagram
      final phasePaint = Paint()
        ..color = const Color(0xFF38B2AC).withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(centerX, phaseY),
          width: positionUncertainty * 2,
          height: momentumUncertainty * 2,
        ),
        phasePaint,
      );

      // Phase space border
      final phaseBorderPaint = Paint()
        ..color = const Color(0xFF38B2AC).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(centerX, phaseY),
          width: positionUncertainty * 2,
          height: momentumUncertainty * 2,
        ),
        phaseBorderPaint,
      );

      // Minimum uncertainty ellipse
      final minEllipsePaint = Paint()
        ..color = const Color(0xFFED8936).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, phaseY),
          width: positionUncertainty * 2,
          height: momentumUncertainty * 2,
        ),
        minEllipsePaint,
      );
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    final scaleX = (size.width - 100) / 300;
    final scaleY = (size.height * 0.6) / 200;
    final offsetX = 50.0;
    final offsetY = size.height * 0.15;

    for (final p in particles) {
      final screenX = offsetX + p.x * scaleX;
      final screenY = offsetY + p.y * scaleY;

      // Particle
      final particlePaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(screenX, screenY),
        3,
        particlePaint,
      );

      // Momentum vector
      if (showMomentum) {
        final vectorPaint = Paint()
          ..color = const Color(0xFF38B2AC).withValues(alpha: 0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(screenX, screenY),
          Offset(screenX + p.px * 5, screenY + p.py * 5),
          vectorPaint,
        );
      }
    }
  }

  void _drawAxes(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;

    // X axis (position)
    canvas.drawLine(
      Offset(40, size.height * 0.45),
      Offset(size.width - 20, size.height * 0.45),
      axisPaint,
    );

    // Arrow
    final arrowPath = Path()
      ..moveTo(size.width - 20, size.height * 0.45)
      ..lineTo(size.width - 30, size.height * 0.45 - 5)
      ..lineTo(size.width - 30, size.height * 0.45 + 5)
      ..close();

    canvas.drawPath(arrowPath, Paint()..color = AppColors.muted.withValues(alpha: 0.6));

    if (showMomentum) {
      // P axis (momentum) for phase space
      canvas.drawLine(
        Offset(40, size.height * 0.65),
        Offset(40, size.height * 0.95),
        axisPaint,
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Position label
    textPainter.text = TextSpan(
      text: 'x (position)',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 80, size.height * 0.45 + 8));

    // Uncertainty label
    textPainter.text = TextSpan(
      text: 'Δx',
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    final centerX = 50 + measurePosition * (size.width - 100);
    textPainter.paint(canvas, Offset(centerX - 10, size.height * 0.12));

    if (showMomentum) {
      // Momentum label
      textPainter.text = TextSpan(
        text: 'Δp',
        style: TextStyle(
          color: const Color(0xFF38B2AC),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(20, size.height * 0.78));

      // Phase space label
      textPainter.text = TextSpan(
        text: 'Phase Space',
        style: TextStyle(
          color: AppColors.muted.withValues(alpha: 0.7),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - 80, size.height * 0.65));
    }
  }

  @override
  bool shouldRepaint(covariant HeisenbergPainter oldDelegate) =>
      time != oldDelegate.time ||
      positionUncertainty != oldDelegate.positionUncertainty ||
      showMomentum != oldDelegate.showMomentum;
}
