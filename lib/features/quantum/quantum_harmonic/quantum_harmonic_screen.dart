import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Quantum Harmonic Oscillator Simulation
/// 양자 조화 진동자 시뮬레이션
class QuantumHarmonicScreen extends StatefulWidget {
  const QuantumHarmonicScreen({super.key});

  @override
  State<QuantumHarmonicScreen> createState() => _QuantumHarmonicScreenState();
}

class _QuantumHarmonicScreenState extends State<QuantumHarmonicScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const int _defaultQuantumN = 2;
  static const double _defaultOmega = 1.0;

  int quantumN = _defaultQuantumN;
  double omega = _defaultOmega;
  bool isRunning = true;
  bool showClassical = false;

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
      quantumN = _defaultQuantumN;
      omega = _defaultOmega;
    });
  }

  double get energyLevel {
    // En = ℏω(n + 1/2)
    return omega * (quantumN + 0.5);
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
              isKorean ? '양자 조화 진동자' : 'Quantum Harmonic Oscillator',
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
          title: isKorean ? '양자 조화 진동자' : 'Quantum Harmonic Oscillator',
          formula: 'Eₙ = ℏω(n + ½)',
          formulaDescription: isKorean
              ? '양자 조화 진동자의 에너지 준위는 등간격입니다. n=0일 때도 영점 에너지 ℏω/2가 존재합니다. '
                  '파동함수는 에르미트 다항식을 포함합니다.'
              : 'Energy levels of quantum harmonic oscillator are equally spaced. '
                  'Zero-point energy ℏω/2 exists even at n=0. Wave functions involve Hermite polynomials.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: QuantumHarmonicPainter(
                time: time,
                n: quantumN,
                omega: omega,
                showClassical: showClassical,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimSegment<bool>(
                label: isKorean ? '비교 표시' : 'Show Comparison',
                options: {
                  false: isKorean ? '양자만' : 'Quantum Only',
                  true: isKorean ? '고전 비교' : 'Classical',
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
                  label: isKorean ? '양자수 (n)' : 'Quantum Number (n)',
                  value: quantumN.toDouble(),
                  min: 0,
                  max: 6,
                  defaultValue: _defaultQuantumN.toDouble(),
                  formatValue: (v) => 'n=${v.toInt()}',
                  onChanged: (v) => setState(() => quantumN = v.toInt()),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '각진동수 (ω)' : 'Frequency (ω)',
                    value: omega,
                    min: 0.5,
                    max: 2.0,
                    defaultValue: _defaultOmega,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => omega = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                n: quantumN,
                energy: energyLevel,
                zeroPointEnergy: omega * 0.5,
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
  final double zeroPointEnergy;
  final bool isKorean;

  const _PhysicsInfo({
    required this.n,
    required this.energy,
    required this.zeroPointEnergy,
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
            label: 'Eₙ',
            value: '${energy.toStringAsFixed(1)}ℏω',
          ),
          _InfoItem(
            label: isKorean ? '영점 에너지' : 'Zero-point',
            value: '${zeroPointEnergy.toStringAsFixed(1)}ℏω',
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

class QuantumHarmonicPainter extends CustomPainter {
  final double time;
  final int n;
  final double omega;
  final bool showClassical;

  QuantumHarmonicPainter({
    required this.time,
    required this.n,
    required this.omega,
    required this.showClassical,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawPotential(canvas, size);
    _drawEnergyLevels(canvas, size);
    _drawWaveFunction(canvas, size);
    if (showClassical) {
      _drawClassicalTurningPoints(canvas, size);
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

  void _drawPotential(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final baseY = size.height * 0.85;
    final scale = 15.0 / omega;

    // Draw parabolic potential V = 1/2 mω²x²
    final potentialPath = Path();
    potentialPath.moveTo(centerX - 150, baseY);

    for (double x = -150; x <= 150; x += 3) {
      final v = 0.5 * omega * omega * (x / scale) * (x / scale);
      final screenY = baseY - v * 8;
      potentialPath.lineTo(centerX + x, screenY.clamp(size.height * 0.1, baseY));
    }

    potentialPath.lineTo(centerX + 150, baseY);
    potentialPath.close();

    // Fill potential
    canvas.drawPath(
      potentialPath,
      Paint()..color = const Color(0xFF805AD5).withValues(alpha: 0.15),
    );

    // Potential outline
    final outlinePath = Path();
    outlinePath.moveTo(centerX - 150, baseY);
    for (double x = -150; x <= 150; x += 3) {
      final v = 0.5 * omega * omega * (x / scale) * (x / scale);
      final screenY = baseY - v * 8;
      outlinePath.lineTo(centerX + x, screenY.clamp(size.height * 0.1, baseY));
    }

    canvas.drawPath(
      outlinePath,
      Paint()
        ..color = const Color(0xFF805AD5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawEnergyLevels(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final baseY = size.height * 0.85;
    final scale = 15.0 / omega;

    // Draw energy levels
    for (int level = 0; level <= 6; level++) {
      final energy = omega * (level + 0.5);
      final levelY = baseY - energy * 25;

      if (levelY < size.height * 0.1) continue;

      // Calculate classical turning points
      final turningPointX = math.sqrt(2 * energy / (omega * omega)) * scale;

      final isCurrentLevel = level == n;
      final levelPaint = Paint()
        ..color = isCurrentLevel
            ? AppColors.accent
            : AppColors.muted.withValues(alpha: 0.4)
        ..strokeWidth = isCurrentLevel ? 2.5 : 1;

      // Draw level line between turning points
      canvas.drawLine(
        Offset(centerX - turningPointX, levelY),
        Offset(centerX + turningPointX, levelY),
        levelPaint,
      );

      // Level label
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'n=$level',
          style: TextStyle(
            color: isCurrentLevel ? AppColors.accent : AppColors.muted.withValues(alpha: 0.6),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(centerX + turningPointX + 5, levelY - 5));
    }
  }

  void _drawWaveFunction(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final baseY = size.height * 0.85;
    final energy = omega * (n + 0.5);
    final levelY = baseY - energy * 25;
    final amplitude = 35.0;
    final scale = 15.0 / omega;

    // Wave function path
    final wavePath = Path();
    bool started = false;

    for (double x = -120; x <= 120; x += 2) {
      final xi = x / scale * math.sqrt(omega);
      final psi = _hermiteGaussian(n, xi);

      // Time-dependent phase
      final phase = omega * (n + 0.5) * time;
      final realPart = psi * math.cos(phase);

      final screenY = levelY - realPart * amplitude;

      if (!started) {
        wavePath.moveTo(centerX + x, screenY);
        started = true;
      } else {
        wavePath.lineTo(centerX + x, screenY);
      }
    }

    // Glow effect
    canvas.drawPath(
      wavePath,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke,
    );

    // Main wave
    canvas.drawPath(
      wavePath,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Probability density (smaller)
    final probPath = Path();
    probPath.moveTo(centerX - 120, levelY);
    for (double x = -120; x <= 120; x += 2) {
      final xi = x / scale * math.sqrt(omega);
      final psi = _hermiteGaussian(n, xi);
      final prob = psi * psi * 0.5;
      probPath.lineTo(centerX + x, levelY - prob * amplitude);
    }
    probPath.lineTo(centerX + 120, levelY);

    canvas.drawPath(
      probPath,
      Paint()..color = const Color(0xFF38B2AC).withValues(alpha: 0.3),
    );
  }

  double _hermiteGaussian(int n, double x) {
    final gaussian = math.exp(-x * x / 2);
    final hermite = _hermitePolynomial(n, x);
    // Normalization factor (approximate)
    final norm = 1.0 / math.sqrt(math.pow(2, n) * _factorial(n) * math.sqrt(math.pi));
    return norm * hermite * gaussian;
  }

  double _hermitePolynomial(int n, double x) {
    switch (n) {
      case 0:
        return 1;
      case 1:
        return 2 * x;
      case 2:
        return 4 * x * x - 2;
      case 3:
        return 8 * x * x * x - 12 * x;
      case 4:
        return 16 * x * x * x * x - 48 * x * x + 12;
      case 5:
        return 32 * x * x * x * x * x - 160 * x * x * x + 120 * x;
      case 6:
        return 64 * math.pow(x, 6) - 480 * math.pow(x, 4) + 720 * x * x - 120;
      default:
        return 1;
    }
  }

  int _factorial(int n) {
    if (n <= 1) return 1;
    return n * _factorial(n - 1);
  }

  void _drawClassicalTurningPoints(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final baseY = size.height * 0.85;
    final energy = omega * (n + 0.5);
    final levelY = baseY - energy * 25;
    final scale = 15.0 / omega;

    final turningPointX = math.sqrt(2 * energy / (omega * omega)) * scale;

    // Classical particle oscillating
    final classicalX = turningPointX * math.cos(omega * time * 2);
    final particleX = centerX + classicalX;

    // Turning point markers
    final markerPaint = Paint()
      ..color = const Color(0xFFED8936)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(centerX - turningPointX, levelY - 20),
      Offset(centerX - turningPointX, levelY + 20),
      markerPaint,
    );
    canvas.drawLine(
      Offset(centerX + turningPointX, levelY - 20),
      Offset(centerX + turningPointX, levelY + 20),
      markerPaint,
    );

    // Classical particle
    canvas.drawCircle(
      Offset(particleX, levelY),
      8,
      Paint()..color = const Color(0xFFED8936),
    );
    canvas.drawCircle(
      Offset(particleX, levelY),
      12,
      Paint()..color = const Color(0xFFED8936).withValues(alpha: 0.3),
    );
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Potential label
    textPainter.text = TextSpan(
      text: 'V(x) = ½mω²x²',
      style: TextStyle(
        color: const Color(0xFF805AD5),
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.65, size.height * 0.15));

    // Wave function label
    textPainter.text = TextSpan(
      text: 'ψₙ(x)',
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(30, size.height * 0.3));

    // Energy spacing label
    textPainter.text = TextSpan(
      text: 'ΔE = ℏω (equal spacing)',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.92));
  }

  @override
  bool shouldRepaint(covariant QuantumHarmonicPainter oldDelegate) =>
      time != oldDelegate.time ||
      n != oldDelegate.n ||
      omega != oldDelegate.omega ||
      showClassical != oldDelegate.showClassical;
}
