import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Wave Equation Visualization (PDE)
/// 파동 방정식 시각화 (편미분방정식)
class WaveEquationScreen extends StatefulWidget {
  const WaveEquationScreen({super.key});

  @override
  State<WaveEquationScreen> createState() => _WaveEquationScreenState();
}

class _WaveEquationScreenState extends State<WaveEquationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Wave speed
  double c = 1.0;
  // Grid size
  final int gridSize = 100;
  // Time step
  double dt = 0.02;
  // Simulation time
  double time = 0;

  bool isRunning = false;
  bool isKorean = true;

  // Wave displacement (current and previous time steps)
  List<double> u = [];
  List<double> uPrev = [];

  // Initial condition type
  int initialCondition = 0; // 0: gaussian, 1: pluck, 2: traveling wave

  // Boundary condition type
  int boundaryCondition = 0; // 0: fixed, 1: free

  @override
  void initState() {
    super.initState();
    _initializeWave();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_simulate);
  }

  void _initializeWave() {
    final dx = 1.0 / (gridSize - 1);

    u = List.generate(gridSize, (i) {
      final x = i * dx;
      switch (initialCondition) {
        case 0: // Gaussian pulse
          return math.exp(-100 * math.pow(x - 0.5, 2));
        case 1: // Pluck (triangular)
          if (x < 0.3) return x / 0.3;
          if (x < 0.7) return 1 - (x - 0.3) / 0.4;
          return 0.0;
        case 2: // Traveling sine wave (initial position)
          return math.sin(4 * math.pi * x);
        default:
          return 0.0;
      }
    });

    // For traveling wave, initialize with velocity
    if (initialCondition == 2) {
      // u(x, -dt) = u(x, 0) + c * dt * du/dx
      uPrev = List.generate(gridSize, (i) {
        final x = i * dx;
        // Shift back in time
        return math.sin(4 * math.pi * (x + c * dt));
      });
    } else {
      // Initially at rest
      uPrev = List<double>.from(u);
    }

    time = 0;
  }

  void _simulate() {
    if (!isRunning) return;

    setState(() {
      // Explicit finite difference for wave equation
      // d2u/dt2 = c^2 * d2u/dx2
      final dx = 1.0 / (gridSize - 1);
      final r = c * dt / dx;
      final r2 = r * r;

      final uNew = List<double>.filled(gridSize, 0);

      for (int i = 1; i < gridSize - 1; i++) {
        uNew[i] = 2 * u[i] -
            uPrev[i] +
            r2 * (u[i + 1] - 2 * u[i] + u[i - 1]);
      }

      // Boundary conditions
      if (boundaryCondition == 0) {
        // Fixed ends
        uNew[0] = 0;
        uNew[gridSize - 1] = 0;
      } else {
        // Free ends (Neumann)
        uNew[0] = uNew[1];
        uNew[gridSize - 1] = uNew[gridSize - 2];
      }

      uPrev = u;
      u = uNew;
      time += dt;
    });

    if (isRunning) {
      _controller.forward(from: 0);
    }
  }

  void _toggleSimulation() {
    HapticFeedback.mediumImpact();
    setState(() {
      isRunning = !isRunning;
      if (isRunning) {
        _controller.forward(from: 0);
      } else {
        _controller.stop();
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      isRunning = false;
      _initializeWave();
    });
  }

  double get _maxDisplacement => u.map((v) => v.abs()).reduce(math.max);
  double get _energy {
    // Total energy (kinetic + potential)
    final dx = 1.0 / (gridSize - 1);
    double ke = 0;
    double pe = 0;

    for (int i = 0; i < gridSize; i++) {
      // Kinetic energy: (du/dt)^2
      final dudt = (u[i] - uPrev[i]) / dt;
      ke += dudt * dudt * dx;

      // Potential energy: (du/dx)^2
      if (i < gridSize - 1) {
        final dudx = (u[i + 1] - u[i]) / dx;
        pe += c * c * dudx * dudx * dx;
      }
    }

    return 0.5 * (ke + pe);
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
              isKorean ? '편미분방정식' : 'PDEs',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '파동 방정식' : 'Wave Equation',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
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
          category: isKorean ? '편미분방정식' : 'PDEs',
          title: isKorean ? '파동 방정식' : 'Wave Equation',
          formula: '∂²u/∂t² = c² ∂²u/∂x²',
          formulaDescription: isKorean
              ? '파동 방정식은 현의 진동, 소리, 빛 등 파동의 전파를 설명합니다. c는 파동의 속도입니다.'
              : 'The wave equation describes propagation of waves in strings, sound, light, etc. c is the wave speed.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: WaveEquationPainter(
                u: u,
                uPrev: uPrev,
                time: time,
                c: c,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _InfoItem(
                      label: isKorean ? '시간' : 'Time',
                      value: 't = ${time.toStringAsFixed(2)}',
                      color: AppColors.accent,
                    ),
                    _InfoItem(
                      label: isKorean ? '최대 진폭' : 'Max Amp',
                      value: _maxDisplacement.toStringAsFixed(3),
                    ),
                    _InfoItem(
                      label: isKorean ? '에너지' : 'Energy',
                      value: _energy.toStringAsFixed(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Initial condition
              PresetGroup(
                label: isKorean ? '초기 조건' : 'Initial Condition',
                presets: [
                  PresetButton(
                    label: isKorean ? '가우시안' : 'Gaussian',
                    isSelected: initialCondition == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        initialCondition = 0;
                        _initializeWave();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '뜯기' : 'Pluck',
                    isSelected: initialCondition == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        initialCondition = 1;
                        _initializeWave();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '진행파' : 'Traveling',
                    isSelected: initialCondition == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        initialCondition = 2;
                        _initializeWave();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Boundary condition
              PresetGroup(
                label: isKorean ? '경계 조건' : 'Boundary Condition',
                presets: [
                  PresetButton(
                    label: isKorean ? '고정단' : 'Fixed',
                    isSelected: boundaryCondition == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        boundaryCondition = 0;
                        _initializeWave();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '자유단' : 'Free',
                    isSelected: boundaryCondition == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        boundaryCondition = 1;
                        _initializeWave();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SimSlider(
                label: 'c (${isKorean ? '파동 속도' : 'wave speed'})',
                value: c,
                min: 0.5,
                max: 2.0,
                defaultValue: 1.0,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => c = v),
              ),
              const SizedBox(height: 12),

              // Explanation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKorean ? '유한 차분법:' : 'Finite Difference:',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'u(x,t+dt) = 2u(x,t) - u(x,t-dt) + r²[u(x+dx) - 2u(x) + u(x-dx)]',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      isKorean ? 'r = c·dt/dx (쿠란트 수)' : 'r = c·dt/dx (Courant number)',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning
                    ? (isKorean ? '일시정지' : 'Pause')
                    : (isKorean ? '시작' : 'Start'),
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

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class WaveEquationPainter extends CustomPainter {
  final List<double> u;
  final List<double> uPrev;
  final double time;
  final double c;
  final bool isKorean;

  WaveEquationPainter({
    required this.u,
    required this.uPrev,
    required this.time,
    required this.c,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (u.isEmpty) return;

    final padding = 40.0;
    final graphWidth = size.width - 2 * padding;
    final graphHeight = size.height - 2 * padding;
    final graphTop = padding;
    final centerY = graphTop + graphHeight / 2;

    // Draw grid
    final gridPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = graphTop + graphHeight * i / 4;
      canvas.drawLine(
        Offset(padding, y),
        Offset(padding + graphWidth, y),
        gridPaint,
      );
    }

    // Draw center line (equilibrium)
    canvas.drawLine(
      Offset(padding, centerY),
      Offset(padding + graphWidth, centerY),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 1,
    );

    // Draw string support points
    canvas.drawCircle(
      Offset(padding, centerY),
      6,
      Paint()..color = AppColors.cardBorder,
    );
    canvas.drawCircle(
      Offset(padding + graphWidth, centerY),
      6,
      Paint()..color = AppColors.cardBorder,
    );

    // Draw wave
    final wavePath = Path();
    final maxU = 1.5; // Fixed scale

    for (int i = 0; i < u.length; i++) {
      final x = padding + graphWidth * i / (u.length - 1);
      final y = centerY - (u[i] / maxU) * (graphHeight / 2 - 10);

      if (i == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }

    // Draw wave shadow (previous position)
    final shadowPath = Path();
    for (int i = 0; i < uPrev.length; i++) {
      final x = padding + graphWidth * i / (uPrev.length - 1);
      final y = centerY - (uPrev[i] / maxU) * (graphHeight / 2 - 10);

      if (i == 0) {
        shadowPath.moveTo(x, y);
      } else {
        shadowPath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw current wave
    canvas.drawPath(
      wavePath,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Draw velocity arrows at selected points
    for (int i = 10; i < u.length - 10; i += 15) {
      final x = padding + graphWidth * i / (u.length - 1);
      final y = centerY - (u[i] / maxU) * (graphHeight / 2 - 10);
      final vy = (u[i] - uPrev[i]) / 0.02 * 10; // Scale velocity for visibility

      if (vy.abs() > 0.1) {
        _drawArrow(
          canvas,
          Offset(x, y),
          Offset(x, y - vy),
          Colors.red.withValues(alpha: 0.7),
        );
      }
    }

    // Labels
    _drawText(
      canvas,
      isKorean ? '파동 변위 u(x,t)' : 'Wave Displacement u(x,t)',
      Offset(size.width / 2, 15),
      AppColors.muted,
      fontSize: 11,
    );

    _drawText(
      canvas,
      'x = 0',
      Offset(padding, size.height - 15),
      AppColors.muted,
      fontSize: 10,
    );

    _drawText(
      canvas,
      'x = L',
      Offset(padding + graphWidth, size.height - 15),
      AppColors.muted,
      fontSize: 10,
    );

    // Legend
    _drawText(
      canvas,
      isKorean ? '빨간 화살표: 속도' : 'Red arrows: velocity',
      Offset(size.width / 2, size.height - 15),
      Colors.red.withValues(alpha: 0.7),
      fontSize: 9,
    );
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, paint);

    // Arrow head
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final arrowSize = 5.0;

    final path = Path();
    path.moveTo(to.dx, to.dy);
    path.lineTo(
      to.dx - arrowSize * math.cos(angle - 0.5),
      to.dy - arrowSize * math.sin(angle - 0.5),
    );
    path.moveTo(to.dx, to.dy);
    path.lineTo(
      to.dx - arrowSize * math.cos(angle + 0.5),
      to.dy - arrowSize * math.sin(angle + 0.5),
    );

    canvas.drawPath(path, paint);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color,
      {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant WaveEquationPainter oldDelegate) =>
      u != oldDelegate.u || time != oldDelegate.time;
}
