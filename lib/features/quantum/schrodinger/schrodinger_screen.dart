import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Schrodinger Equation Simulation
/// 슈뢰딩거 방정식 시뮬레이션 (iℏ∂ψ/∂t = Hψ)
class SchrodingerScreen extends StatefulWidget {
  const SchrodingerScreen({super.key});

  @override
  State<SchrodingerScreen> createState() => _SchrodingerScreenState();
}

class _SchrodingerScreenState extends State<SchrodingerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const double _defaultEnergy = 3.0;
  static const double _defaultPotentialWidth = 100.0;
  static const double _defaultPotentialHeight = 50.0;

  double energy = _defaultEnergy;
  double potentialWidth = _defaultPotentialWidth;
  double potentialHeight = _defaultPotentialHeight;
  bool isRunning = true;
  int potentialType = 0; // 0: free, 1: infinite well, 2: finite well, 3: harmonic

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
      energy = _defaultEnergy;
      potentialWidth = _defaultPotentialWidth;
      potentialHeight = _defaultPotentialHeight;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _potentialName {
    switch (potentialType) {
      case 0:
        return isKorean ? '자유 입자' : 'Free Particle';
      case 1:
        return isKorean ? '무한 퍼텐셜 우물' : 'Infinite Well';
      case 2:
        return isKorean ? '유한 퍼텐셜 우물' : 'Finite Well';
      case 3:
        return isKorean ? '조화 진동자' : 'Harmonic';
      default:
        return '';
    }
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
              isKorean ? '슈뢰딩거 방정식' : 'Schrodinger Equation',
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
          title: isKorean ? '슈뢰딩거 방정식' : 'Schrodinger Equation',
          formula: 'iℏ∂ψ/∂t = Ĥψ',
          formulaDescription: isKorean
              ? '슈뢰딩거 방정식은 양자 시스템의 파동함수 ψ의 시간 변화를 기술합니다. '
                  'Ĥ는 해밀토니안 연산자로, 시스템의 총 에너지를 나타냅니다.'
              : 'The Schrodinger equation describes the time evolution of the wave function ψ. '
                  'Ĥ is the Hamiltonian operator representing the total energy of the system.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: SchrodingerPainter(
                time: time,
                energy: energy,
                potentialWidth: potentialWidth,
                potentialHeight: potentialHeight,
                potentialType: potentialType,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimSegment<int>(
                label: isKorean ? '퍼텐셜 유형' : 'Potential Type',
                options: {
                  0: isKorean ? '자유' : 'Free',
                  1: isKorean ? '무한우물' : 'Infinite',
                  2: isKorean ? '유한우물' : 'Finite',
                  3: isKorean ? '조화' : 'Harmonic',
                },
                selected: potentialType,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => potentialType = v);
                },
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '에너지 준위 (n)' : 'Energy Level (n)',
                  value: energy,
                  min: 1,
                  max: 6,
                  defaultValue: _defaultEnergy,
                  formatValue: (v) => 'n=${v.toInt()}',
                  onChanged: (v) => setState(() => energy = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '퍼텐셜 폭' : 'Potential Width',
                    value: potentialWidth,
                    min: 50,
                    max: 200,
                    defaultValue: _defaultPotentialWidth,
                    formatValue: (v) => '${v.toInt()} px',
                    onChanged: (v) => setState(() => potentialWidth = v),
                  ),
                  if (potentialType == 2 || potentialType == 3)
                    SimSlider(
                      label: isKorean ? '퍼텐셜 높이' : 'Potential Height',
                      value: potentialHeight,
                      min: 20,
                      max: 100,
                      defaultValue: _defaultPotentialHeight,
                      formatValue: (v) => '${v.toInt()}',
                      onChanged: (v) => setState(() => potentialHeight = v),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                energy: energy.toInt(),
                potentialName: _potentialName,
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
  final int energy;
  final String potentialName;
  final bool isKorean;

  const _PhysicsInfo({
    required this.energy,
    required this.potentialName,
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
            label: isKorean ? '에너지 준위' : 'Energy Level',
            value: 'n=$energy',
          ),
          _InfoItem(
            label: isKorean ? '퍼텐셜' : 'Potential',
            value: potentialName,
          ),
          _InfoItem(
            label: isKorean ? '에너지' : 'Energy',
            value: 'E∝n²',
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

class SchrodingerPainter extends CustomPainter {
  final double time;
  final double energy;
  final double potentialWidth;
  final double potentialHeight;
  final int potentialType;

  SchrodingerPainter({
    required this.time,
    required this.energy,
    required this.potentialWidth,
    required this.potentialHeight,
    required this.potentialType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawPotential(canvas, size);
    _drawWaveFunction(canvas, size);
    _drawProbabilityDensity(canvas, size);
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

    // Axis
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(50, size.height * 0.7),
      Offset(size.width - 20, size.height * 0.7),
      axisPaint,
    );
  }

  void _drawPotential(Canvas canvas, Size size) {
    final potentialPaint = Paint()
      ..color = const Color(0xFF805AD5).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final baseY = size.height * 0.7;
    final halfWidth = potentialWidth / 2;

    switch (potentialType) {
      case 1: // Infinite well
        // Left wall
        canvas.drawRect(
          Rect.fromLTRB(centerX - halfWidth - 10, 0, centerX - halfWidth, baseY),
          potentialPaint,
        );
        // Right wall
        canvas.drawRect(
          Rect.fromLTRB(centerX + halfWidth, 0, centerX + halfWidth + 10, baseY),
          potentialPaint,
        );
        break;

      case 2: // Finite well
        final wallHeight = potentialHeight * 2;
        // Left wall
        canvas.drawRect(
          Rect.fromLTRB(
            centerX - halfWidth - 30,
            baseY - wallHeight,
            centerX - halfWidth,
            baseY,
          ),
          potentialPaint,
        );
        // Right wall
        canvas.drawRect(
          Rect.fromLTRB(
            centerX + halfWidth,
            baseY - wallHeight,
            centerX + halfWidth + 30,
            baseY,
          ),
          potentialPaint,
        );
        break;

      case 3: // Harmonic oscillator
        final path = Path();
        path.moveTo(centerX - halfWidth - 50, baseY);
        for (double x = -halfWidth - 50; x <= halfWidth + 50; x += 2) {
          final potential = 0.01 * potentialHeight * x * x;
          path.lineTo(centerX + x, baseY - potential);
        }
        path.lineTo(centerX + halfWidth + 50, baseY);
        path.close();
        canvas.drawPath(path, potentialPaint);
        break;
    }
  }

  void _drawWaveFunction(Canvas canvas, Size size) {
    final n = energy.toInt();
    final centerX = size.width / 2;
    final baseY = size.height * 0.35;
    final halfWidth = potentialWidth / 2;
    final amplitude = 60.0;

    final realPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final imagPaint = Paint()
      ..color = const Color(0xFF38B2AC)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final realPath = Path();
    final imagPath = Path();
    bool started = false;

    final startX = potentialType == 0 ? 50.0 : centerX - halfWidth;
    final endX = potentialType == 0 ? size.width - 20 : centerX + halfWidth;

    for (double x = startX; x <= endX; x += 2) {
      double psi;

      if (potentialType == 0) {
        // Free particle - traveling wave
        final k = n * math.pi / potentialWidth;
        psi = math.sin(k * (x - centerX) - time * n);
      } else if (potentialType == 3) {
        // Harmonic oscillator
        final xi = (x - centerX) / (potentialWidth / 4);
        psi = _hermiteGaussian(n - 1, xi) * math.exp(-xi * xi / 2);
      } else {
        // Infinite/finite well - standing wave
        final relX = (x - startX) / (endX - startX);
        psi = math.sin(n * math.pi * relX);
      }

      final phase = time * n * 0.5;
      final realPart = psi * math.cos(phase);
      final imagPart = psi * math.sin(phase);

      final realY = baseY - realPart * amplitude;
      final imagY = baseY - imagPart * amplitude;

      if (!started) {
        realPath.moveTo(x, realY);
        imagPath.moveTo(x, imagY);
        started = true;
      } else {
        realPath.lineTo(x, realY);
        imagPath.lineTo(x, imagY);
      }
    }

    canvas.drawPath(realPath, realPaint);
    canvas.drawPath(imagPath, imagPaint);
  }

  double _hermiteGaussian(int n, double x) {
    // Hermite polynomials for quantum harmonic oscillator
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
      default:
        return math.sin(n * x);
    }
  }

  void _drawProbabilityDensity(Canvas canvas, Size size) {
    final n = energy.toInt();
    final centerX = size.width / 2;
    final baseY = size.height * 0.7;
    final halfWidth = potentialWidth / 2;
    final amplitude = 50.0;

    final probPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    final startX = potentialType == 0 ? 50.0 : centerX - halfWidth;
    final endX = potentialType == 0 ? size.width - 20 : centerX + halfWidth;

    path.moveTo(startX, baseY);

    for (double x = startX; x <= endX; x += 2) {
      double psi;

      if (potentialType == 0) {
        final k = n * math.pi / potentialWidth;
        psi = math.sin(k * (x - centerX) - time * n);
      } else if (potentialType == 3) {
        final xi = (x - centerX) / (potentialWidth / 4);
        psi = _hermiteGaussian(n - 1, xi) * math.exp(-xi * xi / 2);
      } else {
        final relX = (x - startX) / (endX - startX);
        psi = math.sin(n * math.pi * relX);
      }

      final prob = psi * psi;
      final y = baseY - prob * amplitude;
      path.lineTo(x, y);
    }

    path.lineTo(endX, baseY);
    path.close();
    canvas.drawPath(path, probPaint);

    // Draw probability outline
    final outlinePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final outlinePath = Path();
    outlinePath.moveTo(startX, baseY);

    for (double x = startX; x <= endX; x += 2) {
      double psi;

      if (potentialType == 0) {
        final k = n * math.pi / potentialWidth;
        psi = math.sin(k * (x - centerX) - time * n);
      } else if (potentialType == 3) {
        final xi = (x - centerX) / (potentialWidth / 4);
        psi = _hermiteGaussian(n - 1, xi) * math.exp(-xi * xi / 2);
      } else {
        final relX = (x - startX) / (endX - startX);
        psi = math.sin(n * math.pi * relX);
      }

      final prob = psi * psi;
      final y = baseY - prob * amplitude;
      outlinePath.lineTo(x, y);
    }

    canvas.drawPath(outlinePath, outlinePaint);
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Real part label
    textPainter.text = TextSpan(
      text: 'Re(ψ)',
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 50, size.height * 0.25));

    // Imaginary part label
    textPainter.text = TextSpan(
      text: 'Im(ψ)',
      style: TextStyle(
        color: const Color(0xFF38B2AC),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 50, size.height * 0.25 + 15));

    // Probability label
    textPainter.text = TextSpan(
      text: '|ψ|²',
      style: TextStyle(
        color: AppColors.accent.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 50, size.height * 0.6));
  }

  @override
  bool shouldRepaint(covariant SchrodingerPainter oldDelegate) =>
      time != oldDelegate.time ||
      energy != oldDelegate.energy ||
      potentialType != oldDelegate.potentialType;
}
