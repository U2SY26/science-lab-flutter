import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Hydrogen Atom Simulation
/// 수소 원자 시뮬레이션 (En = -13.6eV/n²)
class HydrogenAtomScreen extends StatefulWidget {
  const HydrogenAtomScreen({super.key});

  @override
  State<HydrogenAtomScreen> createState() => _HydrogenAtomScreenState();
}

class _HydrogenAtomScreenState extends State<HydrogenAtomScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const int _defaultPrincipalN = 2;
  static const int _defaultAngularL = 1;
  static const int _defaultMagneticM = 0;

  int principalN = _defaultPrincipalN; // n = 1, 2, 3, ...
  int angularL = _defaultAngularL; // l = 0, 1, ..., n-1
  int magneticM = _defaultMagneticM; // m = -l, ..., l
  bool isRunning = true;
  int viewMode = 0; // 0: probability cloud, 1: energy levels, 2: radial

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
      principalN = _defaultPrincipalN;
      angularL = _defaultAngularL;
      magneticM = _defaultMagneticM;
    });
  }

  void _transition(int newN) {
    if (newN != principalN && newN >= 1 && newN <= 6) {
      HapticFeedback.heavyImpact();
      setState(() {
        principalN = newN;
        // Ensure l and m are valid for new n
        if (angularL >= newN) angularL = newN - 1;
        if (magneticM.abs() > angularL) magneticM = 0;
      });
    }
  }

  double get energyLevel {
    // En = -13.6 eV / n²
    return -13.6 / (principalN * principalN);
  }

  String get orbitalName {
    const orbitalLetters = ['s', 'p', 'd', 'f', 'g', 'h'];
    return '$principalN${orbitalLetters[angularL]}';
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
              isKorean ? '수소 원자' : 'Hydrogen Atom',
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
          title: isKorean ? '수소 원자' : 'Hydrogen Atom',
          formula: 'Eₙ = -13.6 eV / n²',
          formulaDescription: isKorean
              ? '수소 원자의 에너지 준위는 양자화되어 있습니다. n은 주양자수, l은 각운동량 양자수, '
                  'm은 자기 양자수입니다. 전자는 확률 분포(오비탈)로 존재합니다.'
              : 'The energy levels of hydrogen atom are quantized. n is principal quantum number, '
                  'l is angular momentum, m is magnetic quantum number. Electrons exist as probability distributions (orbitals).',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: HydrogenAtomPainter(
                time: time,
                n: principalN,
                l: angularL,
                m: magneticM,
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
                  0: isKorean ? '오비탈' : 'Orbital',
                  1: isKorean ? '에너지' : 'Energy',
                  2: isKorean ? '방사형' : 'Radial',
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
                  label: isKorean ? '주양자수 (n)' : 'Principal (n)',
                  value: principalN.toDouble(),
                  min: 1,
                  max: 6,
                  defaultValue: _defaultPrincipalN.toDouble(),
                  formatValue: (v) => 'n=${v.toInt()}',
                  onChanged: (v) {
                    final newN = v.toInt();
                    if (newN != principalN) {
                      setState(() {
                        principalN = newN;
                        if (angularL >= principalN) angularL = principalN - 1;
                        if (magneticM.abs() > angularL) magneticM = 0;
                      });
                    }
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '각운동량 (l)' : 'Angular (l)',
                    value: angularL.toDouble(),
                    min: 0,
                    max: (principalN - 1).toDouble(),
                    defaultValue: 0,
                    formatValue: (v) {
                      const letters = ['s', 'p', 'd', 'f', 'g', 'h'];
                      return 'l=${v.toInt()} (${letters[v.toInt()]})';
                    },
                    onChanged: (v) {
                      setState(() {
                        angularL = v.toInt();
                        if (magneticM.abs() > angularL) magneticM = 0;
                      });
                    },
                  ),
                  if (angularL > 0)
                    SimSlider(
                      label: isKorean ? '자기양자수 (m)' : 'Magnetic (m)',
                      value: magneticM.toDouble(),
                      min: -angularL.toDouble(),
                      max: angularL.toDouble(),
                      defaultValue: 0,
                      formatValue: (v) => 'm=${v.toInt()}',
                      onChanged: (v) => setState(() => magneticM = v.toInt()),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                orbitalName: orbitalName,
                energy: energyLevel,
                n: principalN,
                l: angularL,
                m: magneticM,
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
                label: isKorean ? '여기' : 'Excite',
                icon: Icons.arrow_upward,
                onPressed: () => _transition(principalN + 1),
              ),
              SimButton(
                label: isKorean ? '이완' : 'Relax',
                icon: Icons.arrow_downward,
                onPressed: () => _transition(principalN - 1),
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
  final String orbitalName;
  final double energy;
  final int n;
  final int l;
  final int m;
  final bool isKorean;

  const _PhysicsInfo({
    required this.orbitalName,
    required this.energy,
    required this.n,
    required this.l,
    required this.m,
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
            label: isKorean ? '오비탈' : 'Orbital',
            value: orbitalName,
          ),
          _InfoItem(
            label: isKorean ? '에너지' : 'Energy',
            value: '${energy.toStringAsFixed(2)} eV',
          ),
          _InfoItem(
            label: '(n,l,m)',
            value: '($n,$l,$m)',
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

class HydrogenAtomPainter extends CustomPainter {
  final double time;
  final int n;
  final int l;
  final int m;
  final int viewMode;

  HydrogenAtomPainter({
    required this.time,
    required this.n,
    required this.l,
    required this.m,
    required this.viewMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    switch (viewMode) {
      case 0:
        _drawOrbital(canvas, size);
        break;
      case 1:
        _drawEnergyLevels(canvas, size);
        break;
      case 2:
        _drawRadialProbability(canvas, size);
        break;
    }

    _drawNucleus(canvas, size);
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

  void _drawNucleus(Canvas canvas, Size size) {
    final centerX = viewMode == 1 ? size.width * 0.15 : size.width / 2;
    final centerY = size.height * 0.45;

    // Nucleus glow
    final glowGradient = RadialGradient(
      colors: [
        const Color(0xFFFC8181).withValues(alpha: 0.8),
        const Color(0xFFFC8181).withValues(alpha: 0.3),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: 20));

    canvas.drawCircle(
      Offset(centerX, centerY),
      20,
      Paint()..shader = glowGradient,
    );

    // Nucleus
    canvas.drawCircle(
      Offset(centerX, centerY),
      8,
      Paint()..color = const Color(0xFFFC8181),
    );

    // p+ label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'p⁺',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX - 6, centerY - 4));
  }

  void _drawOrbital(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.45;
    final maxRadius = math.min(size.width, size.height) * 0.35;

    // Draw probability density cloud
    final random = math.Random(42);

    for (int i = 0; i < 2000; i++) {
      // Generate random point in 3D and project
      final r = random.nextDouble() * maxRadius;
      final theta = random.nextDouble() * math.pi;
      final phi = random.nextDouble() * 2 * math.pi;

      // Calculate probability based on quantum numbers
      final prob = _radialProbability(r / maxRadius * n * 5, n, l) *
          _angularProbability(theta, phi, l, m);

      if (random.nextDouble() < prob * 3) {
        // 3D to 2D projection
        final x = r * math.sin(theta) * math.cos(phi + time * 0.5);
        final y = r * math.cos(theta);

        final screenX = centerX + x;
        final screenY = centerY + y;

        // Color based on phase
        final phase = (phi + time) % (2 * math.pi);
        final color = Color.lerp(
          AppColors.accent,
          const Color(0xFF805AD5),
          (math.sin(phase) + 1) / 2,
        )!;

        canvas.drawCircle(
          Offset(screenX, screenY),
          1.5,
          Paint()..color = color.withValues(alpha: prob * 0.8),
        );
      }
    }

    // Draw orbital shells as guides
    for (int shell = 1; shell <= n; shell++) {
      final shellRadius = maxRadius * shell / n;
      canvas.drawCircle(
        Offset(centerX, centerY),
        shellRadius,
        Paint()
          ..color = AppColors.muted.withValues(alpha: shell == n ? 0.3 : 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = shell == n ? 1.5 : 0.5,
      );
    }
  }

  double _radialProbability(double r, int n, int l) {
    // Simplified radial probability function
    final rho = 2 * r / n;
    final laguerre = _simplifiedLaguerre(rho, n, l);
    final exponential = math.exp(-rho / 2);
    final polynomial = math.pow(rho, l);
    return math.pow(exponential * polynomial * laguerre, 2).toDouble();
  }

  double _simplifiedLaguerre(double x, int n, int l) {
    // Very simplified associated Laguerre polynomial
    if (n == 1) return 1;
    if (n == 2 && l == 0) return 2 - x;
    if (n == 2 && l == 1) return 1;
    if (n == 3 && l == 0) return 6 - 6 * x + x * x;
    if (n == 3 && l == 1) return 4 - x;
    if (n == 3 && l == 2) return 1;
    return math.exp(-x * 0.1);
  }

  double _angularProbability(double theta, double phi, int l, int m) {
    // Simplified spherical harmonics magnitude squared
    if (l == 0) return 1 / (4 * math.pi);
    if (l == 1) {
      if (m == 0) return 3 / (4 * math.pi) * math.pow(math.cos(theta), 2);
      return 3 / (8 * math.pi) * math.pow(math.sin(theta), 2);
    }
    if (l == 2) {
      if (m == 0) {
        final ct = math.cos(theta);
        return 5 / (16 * math.pi) * math.pow(3 * ct * ct - 1, 2);
      }
      if (m.abs() == 1) {
        return 15 / (8 * math.pi) *
            math.pow(math.sin(theta) * math.cos(theta), 2);
      }
      return 15 / (32 * math.pi) * math.pow(math.sin(theta), 4);
    }
    return 0.1;
  }

  void _drawEnergyLevels(Canvas canvas, Size size) {
    final leftX = size.width * 0.25;
    final rightX = size.width * 0.85;
    final topY = size.height * 0.1;
    final bottomY = size.height * 0.85;

    // Draw energy scale
    final scalePaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(leftX, topY),
      Offset(leftX, bottomY),
      scalePaint,
    );

    // Draw energy levels n=1 to n=6
    for (int level = 1; level <= 6; level++) {
      final energy = -13.6 / (level * level);
      final normalizedY = bottomY - (energy + 13.6) / 13.6 * (bottomY - topY);

      final isCurrentLevel = level == n;
      final levelPaint = Paint()
        ..color = isCurrentLevel ? AppColors.accent : AppColors.muted
        ..strokeWidth = isCurrentLevel ? 3 : 1.5;

      canvas.drawLine(
        Offset(leftX, normalizedY),
        Offset(rightX, normalizedY),
        levelPaint,
      );

      // Level label
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'n=$level',
          style: TextStyle(
            color: isCurrentLevel ? AppColors.accent : AppColors.muted,
            fontSize: 11,
            fontWeight: isCurrentLevel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rightX + 5, normalizedY - 7));

      // Energy value
      textPainter.text = TextSpan(
        text: '${energy.toStringAsFixed(2)} eV',
        style: TextStyle(
          color: isCurrentLevel ? AppColors.accent : AppColors.muted.withValues(alpha: 0.7),
          fontSize: 9,
          fontFamily: 'monospace',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftX - textPainter.width - 5, normalizedY - 5));

      // Draw electron on current level
      if (isCurrentLevel) {
        final electronX = leftX + (rightX - leftX) * 0.5 + 20 * math.sin(time * 2);
        canvas.drawCircle(
          Offset(electronX, normalizedY),
          8,
          Paint()..color = const Color(0xFF63B3ED),
        );

        // Electron glow
        canvas.drawCircle(
          Offset(electronX, normalizedY),
          15,
          Paint()..color = const Color(0xFF63B3ED).withValues(alpha: 0.3),
        );
      }
    }

    // Draw ionization level
    canvas.drawLine(
      Offset(leftX, topY),
      Offset(rightX, topY),
      Paint()
        ..color = const Color(0xFFFC8181)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Ionization (0 eV)',
        style: TextStyle(
          color: const Color(0xFFFC8181),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(rightX + 5, topY - 5));
  }

  void _drawRadialProbability(Canvas canvas, Size size) {
    final graphLeft = size.width * 0.15;
    final graphRight = size.width - 30;
    final graphTop = size.height * 0.15;
    final graphBottom = size.height * 0.75;

    // Draw axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(graphLeft, graphBottom),
      Offset(graphRight, graphBottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(graphLeft, graphBottom),
      Offset(graphLeft, graphTop),
      axisPaint,
    );

    // Draw radial probability distribution
    final path = Path();
    bool started = false;

    for (double x = 0; x < graphRight - graphLeft; x += 2) {
      final r = x / (graphRight - graphLeft) * n * 10;
      final prob = _radialProbability(r, n, l) * r * r;
      final normalizedProb = prob / _maxRadialProb(n, l);
      final screenY = graphBottom - normalizedProb * (graphBottom - graphTop) * 0.9;

      if (!started) {
        path.moveTo(graphLeft + x, screenY);
        started = true;
      } else {
        path.lineTo(graphLeft + x, screenY);
      }
    }

    // Fill under curve
    final fillPath = Path.from(path);
    fillPath.lineTo(graphRight, graphBottom);
    fillPath.lineTo(graphLeft, graphBottom);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()..color = AppColors.accent.withValues(alpha: 0.2),
    );

    // Draw curve
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Axis labels
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'r (Bohr radii)',
        style: TextStyle(color: AppColors.muted, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset((graphLeft + graphRight) / 2 - textPainter.width / 2, graphBottom + 10));

    textPainter.text = TextSpan(
      text: 'r²|R(r)|²',
      style: TextStyle(color: AppColors.muted, fontSize: 11),
    );
    textPainter.layout();
    canvas.save();
    canvas.translate(graphLeft - 25, (graphTop + graphBottom) / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
    canvas.restore();
  }

  double _maxRadialProb(int n, int l) {
    // Approximate max value for normalization
    double maxProb = 0;
    for (double r = 0; r < n * 10; r += 0.1) {
      final prob = _radialProbability(r, n, l) * r * r;
      if (prob > maxProb) maxProb = prob;
    }
    return maxProb > 0 ? maxProb : 1;
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Orbital name
    const orbitalLetters = ['s', 'p', 'd', 'f', 'g', 'h'];
    textPainter.text = TextSpan(
      text: '$n${orbitalLetters[l]} orbital',
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.02));

    // Quantum numbers
    textPainter.text = TextSpan(
      text: '(n=$n, l=$l, m=$m)',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.92));
  }

  @override
  bool shouldRepaint(covariant HydrogenAtomPainter oldDelegate) =>
      time != oldDelegate.time ||
      n != oldDelegate.n ||
      l != oldDelegate.l ||
      m != oldDelegate.m ||
      viewMode != oldDelegate.viewMode;
}
