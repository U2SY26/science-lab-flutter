import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// ODE Solver Visualization
/// 상미분방정식 풀이 시각화
class OdeSolverScreen extends StatefulWidget {
  const OdeSolverScreen({super.key});

  @override
  State<OdeSolverScreen> createState() => _OdeSolverScreenState();
}

class _OdeSolverScreenState extends State<OdeSolverScreen> {
  int equationType = 0; // 0: dy/dx = y, 1: dy/dx = -y, 2: dy/dx = x, 3: dy/dx = sin(x)
  int solverMethod = 0; // 0: Euler, 1: RK4
  double stepSize = 0.2;
  double initialY = 1.0;
  double xMin = 0.0;
  double xMax = 5.0;
  bool showExact = true;
  bool showSlope = true;
  bool isKorean = true;

  // Differential equation dy/dx = f(x, y)
  double _f(double x, double y) {
    switch (equationType) {
      case 0:
        return y; // dy/dx = y -> y = Ce^x
      case 1:
        return -y; // dy/dx = -y -> y = Ce^(-x)
      case 2:
        return x; // dy/dx = x -> y = x²/2 + C
      case 3:
        return math.sin(x); // dy/dx = sin(x) -> y = -cos(x) + C
      default:
        return y;
    }
  }

  // Exact solution (for comparison)
  double _exact(double x) {
    switch (equationType) {
      case 0:
        return initialY * math.exp(x);
      case 1:
        return initialY * math.exp(-x);
      case 2:
        return x * x / 2 + initialY;
      case 3:
        return -math.cos(x) + math.cos(0) + initialY;
      default:
        return initialY;
    }
  }

  // Euler method
  List<Offset> _eulerSolve() {
    final points = <Offset>[];
    double x = xMin;
    double y = initialY;
    points.add(Offset(x, y));

    while (x < xMax) {
      y = y + stepSize * _f(x, y);
      x += stepSize;
      points.add(Offset(x, y));
    }

    return points;
  }

  // Runge-Kutta 4th order
  List<Offset> _rk4Solve() {
    final points = <Offset>[];
    double x = xMin;
    double y = initialY;
    points.add(Offset(x, y));

    final h = stepSize;
    while (x < xMax) {
      final k1 = _f(x, y);
      final k2 = _f(x + h / 2, y + h * k1 / 2);
      final k3 = _f(x + h / 2, y + h * k2 / 2);
      final k4 = _f(x + h, y + h * k3);

      y = y + h * (k1 + 2 * k2 + 2 * k3 + k4) / 6;
      x += h;
      points.add(Offset(x, y));
    }

    return points;
  }

  List<Offset> get _solution => solverMethod == 0 ? _eulerSolve() : _rk4Solve();

  String get _equationString {
    switch (equationType) {
      case 0:
        return "dy/dx = y";
      case 1:
        return "dy/dx = -y";
      case 2:
        return "dy/dx = x";
      case 3:
        return "dy/dx = sin(x)";
      default:
        return "";
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      stepSize = 0.2;
      initialY = 1.0;
      equationType = 0;
      solverMethod = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final solution = _solution;
    final error = solution.isNotEmpty
        ? (solution.last.dy - _exact(solution.last.dx)).abs()
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
              isKorean ? '미분방정식' : 'DIFFERENTIAL EQ.',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? 'ODE 솔버' : 'ODE Solver',
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
          category: isKorean ? '미분방정식' : 'DIFFERENTIAL EQ.',
          title: isKorean ? 'ODE 솔버' : 'ODE Solver',
          formula: _equationString,
          formulaDescription: isKorean
              ? '오일러 방법과 룽게-쿠타 방법으로 미분방정식의 수치해를 구합니다.'
              : 'Numerically solve ODEs using Euler and Runge-Kutta methods.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: OdeSolverPainter(
                solution: solution,
                exactSolution: _exact,
                xMin: xMin,
                xMax: xMax,
                showExact: showExact,
                showSlope: showSlope,
                f: _f,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: error < 0.1
                      ? Colors.green.withValues(alpha: 0.1)
                      : error < 0.5
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: error < 0.1
                        ? Colors.green
                        : error < 0.5
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    _InfoItem(
                      label: isKorean ? '방법' : 'Method',
                      value: solverMethod == 0 ? 'Euler' : 'RK4',
                    ),
                    _InfoItem(
                      label: isKorean ? '스텝 크기' : 'Step Size',
                      value: 'h=${stepSize.toStringAsFixed(2)}',
                    ),
                    _InfoItem(
                      label: isKorean ? '최종 오차' : 'Final Error',
                      value: error.toStringAsFixed(4),
                      color: error < 0.1
                          ? Colors.green
                          : error < 0.5
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Equation selection
              PresetGroup(
                label: isKorean ? '미분방정식' : 'Differential Equation',
                presets: [
                  PresetButton(
                    label: "y' = y",
                    isSelected: equationType == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => equationType = 0);
                    },
                  ),
                  PresetButton(
                    label: "y' = -y",
                    isSelected: equationType == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => equationType = 1);
                    },
                  ),
                  PresetButton(
                    label: "y' = x",
                    isSelected: equationType == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => equationType = 2);
                    },
                  ),
                  PresetButton(
                    label: "y' = sin(x)",
                    isSelected: equationType == 3,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => equationType = 3);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Solver method
              PresetGroup(
                label: isKorean ? '풀이 방법' : 'Solver Method',
                presets: [
                  PresetButton(
                    label: isKorean ? '오일러' : 'Euler',
                    isSelected: solverMethod == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => solverMethod = 0);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '룽게-쿠타 (RK4)' : 'Runge-Kutta (RK4)',
                    isSelected: solverMethod == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => solverMethod = 1);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '스텝 크기 (h)' : 'Step Size (h)',
                  value: stepSize,
                  min: 0.05,
                  max: 1.0,
                  defaultValue: 0.2,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => stepSize = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '초기값 y(0)' : 'Initial Value y(0)',
                    value: initialY,
                    min: 0.1,
                    max: 3.0,
                    defaultValue: 1.0,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => initialY = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '정확해 표시' : 'Show Exact',
                      value: showExact,
                      onChanged: (v) => setState(() => showExact = v),
                    ),
                  ),
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '기울기장 표시' : 'Show Slope Field',
                      value: showSlope,
                      onChanged: (v) => setState(() => showSlope = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                isPrimary: true,
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
              color: color ?? AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class OdeSolverPainter extends CustomPainter {
  final List<Offset> solution;
  final double Function(double) exactSolution;
  final double xMin, xMax;
  final bool showExact;
  final bool showSlope;
  final double Function(double, double) f;

  OdeSolverPainter({
    required this.solution,
    required this.exactSolution,
    required this.xMin,
    required this.xMax,
    required this.showExact,
    required this.showSlope,
    required this.f,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // Find y range
    double yMin = 0, yMax = 0;
    for (final p in solution) {
      yMin = math.min(yMin, p.dy);
      yMax = math.max(yMax, p.dy);
    }
    for (double x = xMin; x <= xMax; x += 0.1) {
      final y = exactSolution(x);
      if (y.isFinite) {
        yMin = math.min(yMin, y);
        yMax = math.max(yMax, y);
      }
    }
    yMin -= 0.5;
    yMax += 0.5;

    final xScale = graphWidth / (xMax - xMin);
    final yScale = graphHeight / (yMax - yMin);

    double toScreenX(double x) => padding + (x - xMin) * xScale;
    double toScreenY(double y) => padding + graphHeight - (y - yMin) * yScale;

    // Draw grid
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (double x = xMin.ceilToDouble(); x <= xMax; x += 1) {
      canvas.drawLine(Offset(toScreenX(x), padding), Offset(toScreenX(x), size.height - padding), gridPaint);
    }
    for (double y = yMin.ceilToDouble(); y <= yMax; y += 1) {
      canvas.drawLine(Offset(padding, toScreenY(y)), Offset(size.width - padding, toScreenY(y)), gridPaint);
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;

    if (yMin <= 0 && yMax >= 0) {
      canvas.drawLine(Offset(padding, toScreenY(0)), Offset(size.width - padding, toScreenY(0)), axisPaint);
    }
    if (xMin <= 0 && xMax >= 0) {
      canvas.drawLine(Offset(toScreenX(0), padding), Offset(toScreenX(0), size.height - padding), axisPaint);
    }

    // Draw slope field
    if (showSlope) {
      final slopePaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.3)
        ..strokeWidth = 1;

      for (double x = xMin; x <= xMax; x += 0.5) {
        for (double y = yMin; y <= yMax; y += 0.5) {
          final slope = f(x, y);
          if (slope.isFinite && slope.abs() < 10) {
            final angle = math.atan(slope);
            final length = 10.0;
            final cx = toScreenX(x);
            final cy = toScreenY(y);
            canvas.drawLine(
              Offset(cx - length * math.cos(angle) / 2, cy + length * math.sin(angle) / 2),
              Offset(cx + length * math.cos(angle) / 2, cy - length * math.sin(angle) / 2),
              slopePaint,
            );
          }
        }
      }
    }

    // Draw exact solution
    if (showExact) {
      final exactPath = Path();
      bool started = false;
      for (double x = xMin; x <= xMax; x += 0.02) {
        final y = exactSolution(x);
        if (y.isFinite && y >= yMin && y <= yMax) {
          if (!started) {
            exactPath.moveTo(toScreenX(x), toScreenY(y));
            started = true;
          } else {
            exactPath.lineTo(toScreenX(x), toScreenY(y));
          }
        }
      }
      canvas.drawPath(
        exactPath,
        Paint()
          ..color = Colors.green.withValues(alpha: 0.5)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // Draw numerical solution
    if (solution.length > 1) {
      final solutionPath = Path();
      solutionPath.moveTo(toScreenX(solution[0].dx), toScreenY(solution[0].dy));
      for (int i = 1; i < solution.length; i++) {
        solutionPath.lineTo(toScreenX(solution[i].dx), toScreenY(solution[i].dy));
      }
      canvas.drawPath(
        solutionPath,
        Paint()
          ..color = AppColors.accent
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );

      // Draw solution points
      for (final p in solution) {
        canvas.drawCircle(Offset(toScreenX(p.dx), toScreenY(p.dy)), 4, Paint()..color = AppColors.accent);
      }
    }

    // Legend
    _drawText(canvas, 'Numerical', Offset(size.width - 60, 20), AppColors.accent, fontSize: 10);
    canvas.drawLine(Offset(size.width - 90, 20), Offset(size.width - 65, 20), Paint()..color = AppColors.accent..strokeWidth = 2);

    if (showExact) {
      _drawText(canvas, 'Exact', Offset(size.width - 60, 35), Colors.green, fontSize: 10);
      canvas.drawLine(Offset(size.width - 90, 35), Offset(size.width - 65, 35), Paint()..color = Colors.green..strokeWidth = 2);
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant OdeSolverPainter oldDelegate) =>
      solution != oldDelegate.solution ||
      showExact != oldDelegate.showExact ||
      showSlope != oldDelegate.showSlope;
}
