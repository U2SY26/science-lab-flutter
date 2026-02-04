import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Particle in a Box Simulation
/// 상자 속 입자 시뮬레이션
class ParticleInBoxScreen extends StatefulWidget {
  const ParticleInBoxScreen({super.key});

  @override
  State<ParticleInBoxScreen> createState() => _ParticleInBoxScreenState();
}

class _ParticleInBoxScreenState extends State<ParticleInBoxScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const int _defaultQuantumN = 2;
  static const double _defaultBoxWidth = 200.0;

  int quantumN = _defaultQuantumN;
  double boxWidth = _defaultBoxWidth;
  bool isRunning = true;
  int viewMode = 0; // 0: wave function, 1: probability, 2: both

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
      time += 0.03;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      quantumN = _defaultQuantumN;
      boxWidth = _defaultBoxWidth;
    });
  }

  double get energyLevel {
    // En = n²π²ℏ²/(2mL²) - simplified
    return (quantumN * quantumN).toDouble();
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
              isKorean ? '상자 속 입자' : 'Particle in a Box',
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
          title: isKorean ? '상자 속 입자' : 'Particle in a Box',
          formula: 'Eₙ = n²π²ℏ²/(2mL²)',
          formulaDescription: isKorean
              ? '무한 퍼텐셜 우물에 갇힌 입자의 에너지는 양자화됩니다. '
                  '파동함수는 ψ(x) = √(2/L)sin(nπx/L)이고, 벽에서 0이어야 합니다.'
              : 'Energy of a particle in an infinite potential well is quantized. '
                  'Wave function is ψ(x) = √(2/L)sin(nπx/L), must be zero at walls.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: ParticleInBoxPainter(
                time: time,
                n: quantumN,
                boxWidth: boxWidth,
                viewMode: viewMode,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimSegment<int>(
                label: isKorean ? '표시 모드' : 'View Mode',
                options: {
                  0: 'ψ(x)',
                  1: '|ψ|²',
                  2: isKorean ? '둘 다' : 'Both',
                },
                selected: viewMode,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => viewMode = v);
                },
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '양자수 (n)' : 'Quantum Number (n)',
                  value: quantumN.toDouble(),
                  min: 1,
                  max: 8,
                  defaultValue: _defaultQuantumN.toDouble(),
                  formatValue: (v) => 'n=${v.toInt()}',
                  onChanged: (v) => setState(() => quantumN = v.toInt()),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '상자 폭 (L)' : 'Box Width (L)',
                    value: boxWidth,
                    min: 100,
                    max: 300,
                    defaultValue: _defaultBoxWidth,
                    formatValue: (v) => '${v.toInt()} px',
                    onChanged: (v) => setState(() => boxWidth = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                n: quantumN,
                energy: energyLevel,
                nodes: quantumN - 1,
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
  final int n;
  final double energy;
  final int nodes;
  final bool isKorean;

  const _PhysicsInfo({
    required this.n,
    required this.energy,
    required this.nodes,
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
            label: isKorean ? '양자수' : 'Quantum n',
            value: 'n=$n',
          ),
          _InfoItem(
            label: isKorean ? '에너지' : 'Energy',
            value: 'E=${energy.toInt()}E₁',
          ),
          _InfoItem(
            label: isKorean ? '노드 수' : 'Nodes',
            value: '$nodes',
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

class ParticleInBoxPainter extends CustomPainter {
  final double time;
  final int n;
  final double boxWidth;
  final int viewMode;

  ParticleInBoxPainter({
    required this.time,
    required this.n,
    required this.boxWidth,
    required this.viewMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawBox(canvas, size);
    _drawEnergyLevels(canvas, size);

    if (viewMode == 0 || viewMode == 2) {
      _drawWaveFunction(canvas, size);
    }
    if (viewMode == 1 || viewMode == 2) {
      _drawProbabilityDensity(canvas, size);
    }

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

  void _drawBox(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final halfWidth = boxWidth / 2;

    // Infinite walls
    final wallPaint = Paint()
      ..color = const Color(0xFF805AD5)
      ..style = PaintingStyle.fill;

    // Left wall
    canvas.drawRect(
      Rect.fromLTWH(centerX - halfWidth - 15, size.height * 0.15, 15, size.height * 0.7),
      wallPaint,
    );

    // Right wall
    canvas.drawRect(
      Rect.fromLTWH(centerX + halfWidth, size.height * 0.15, 15, size.height * 0.7),
      wallPaint,
    );

    // Potential labels
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'V=∞',
        style: TextStyle(
          color: const Color(0xFF805AD5),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX - halfWidth - 13, size.height * 0.1));
    textPainter.paint(canvas, Offset(centerX + halfWidth + 2, size.height * 0.1));

    // Inside potential (V=0)
    textPainter.text = TextSpan(
      text: 'V=0',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX - 10, size.height * 0.88));

    // Box floor
    canvas.drawLine(
      Offset(centerX - halfWidth, size.height * 0.85),
      Offset(centerX + halfWidth, size.height * 0.85),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
  }

  void _drawEnergyLevels(Canvas canvas, Size size) {
    final rightX = size.width * 0.85;
    final graphTop = size.height * 0.15;
    final graphBottom = size.height * 0.85;
    final graphHeight = graphBottom - graphTop;

    // Draw energy level diagram on the right
    final maxEnergy = 64.0; // n=8 squared

    for (int level = 1; level <= 8; level++) {
      final energy = level * level.toDouble();
      final normalizedY = graphBottom - (energy / maxEnergy) * graphHeight * 0.9;

      final isCurrentLevel = level == n;
      final levelColor = isCurrentLevel ? AppColors.accent : AppColors.muted.withValues(alpha: 0.5);

      canvas.drawLine(
        Offset(rightX - 30, normalizedY),
        Offset(rightX + 10, normalizedY),
        Paint()
          ..color = levelColor
          ..strokeWidth = isCurrentLevel ? 2.5 : 1,
      );

      if (level <= 5 || isCurrentLevel) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'n=$level',
            style: TextStyle(
              color: levelColor,
              fontSize: 9,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(rightX + 15, normalizedY - 5));
      }
    }

    // Axis label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'E',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(rightX - 10, graphTop - 15));
  }

  void _drawWaveFunction(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final centerY = size.height * 0.5;
    final halfWidth = boxWidth / 2;
    final amplitude = 60.0;

    final path = Path();
    bool started = false;

    for (double x = centerX - halfWidth; x <= centerX + halfWidth; x += 2) {
      final normalizedX = (x - (centerX - halfWidth)) / boxWidth;
      final psi = math.sin(n * math.pi * normalizedX);

      // Time-dependent phase
      final phase = time * n * 0.5;
      final realPart = psi * math.cos(phase);

      final screenY = centerY - realPart * amplitude;

      if (!started) {
        path.moveTo(x, screenY);
        started = true;
      } else {
        path.lineTo(x, screenY);
      }
    }

    // Draw wave function
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Mark nodes
    for (int node = 1; node < n; node++) {
      final nodeX = centerX - halfWidth + boxWidth * node / n;
      canvas.drawCircle(
        Offset(nodeX, centerY),
        5,
        Paint()..color = const Color(0xFFFC8181),
      );
    }
  }

  void _drawProbabilityDensity(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final baseY = size.height * 0.85;
    final halfWidth = boxWidth / 2;
    final amplitude = 100.0;

    final path = Path();
    path.moveTo(centerX - halfWidth, baseY);
    // Drawing probability density |psi|^2

    for (double x = centerX - halfWidth; x <= centerX + halfWidth; x += 2) {
      final normalizedX = (x - (centerX - halfWidth)) / boxWidth;
      final psi = math.sin(n * math.pi * normalizedX);
      final prob = psi * psi;

      final screenY = baseY - prob * amplitude;
      path.lineTo(x, screenY);
    }

    path.lineTo(centerX + halfWidth, baseY);
    path.close();

    // Fill probability density
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF38B2AC).withValues(alpha: 0.3),
    );

    // Outline
    final outlinePath = Path();
    outlinePath.moveTo(centerX - halfWidth, baseY);
    for (double x = centerX - halfWidth; x <= centerX + halfWidth; x += 2) {
      final normalizedX = (x - (centerX - halfWidth)) / boxWidth;
      final psi = math.sin(n * math.pi * normalizedX);
      final prob = psi * psi;
      final screenY = baseY - prob * amplitude;
      outlinePath.lineTo(x, screenY);
    }

    canvas.drawPath(
      outlinePath,
      Paint()
        ..color = const Color(0xFF38B2AC)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Wave function label
    if (viewMode == 0 || viewMode == 2) {
      textPainter.text = TextSpan(
        text: 'ψ(x)',
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(30, size.height * 0.35));
    }

    // Probability density label
    if (viewMode == 1 || viewMode == 2) {
      textPainter.text = TextSpan(
        text: '|ψ(x)|²',
        style: TextStyle(
          color: const Color(0xFF38B2AC),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(30, size.height * 0.65));
    }

    // Formula
    textPainter.text = TextSpan(
      text: 'ψₙ(x) = √(2/L)·sin(nπx/L)',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 10,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.05));
  }

  @override
  bool shouldRepaint(covariant ParticleInBoxPainter oldDelegate) =>
      time != oldDelegate.time ||
      n != oldDelegate.n ||
      boxWidth != oldDelegate.boxWidth ||
      viewMode != oldDelegate.viewMode;
}
