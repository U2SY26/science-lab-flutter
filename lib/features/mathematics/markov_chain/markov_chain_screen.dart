import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Markov Chain Visualization
/// 마르코프 체인 시각화
class MarkovChainScreen extends StatefulWidget {
  const MarkovChainScreen({super.key});

  @override
  State<MarkovChainScreen> createState() => _MarkovChainScreenState();
}

class _MarkovChainScreenState extends State<MarkovChainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  // 3-state Markov chain: Sunny (0), Cloudy (1), Rainy (2)
  // Transition matrix P[i][j] = P(next = j | current = i)
  List<List<double>> transitionMatrix = [
    [0.7, 0.2, 0.1], // From Sunny
    [0.3, 0.4, 0.3], // From Cloudy
    [0.2, 0.3, 0.5], // From Rainy
  ];

  int currentState = 0;
  List<int> history = [0];
  List<double> stationaryDist = [0.0, 0.0, 0.0];
  bool isRunning = false;
  int stepCount = 0;
  bool isKorean = true;

  final List<String> stateNames = ['Sunny', 'Cloudy', 'Rainy'];
  final List<String> stateNamesKo = ['맑음', '흐림', '비'];
  final List<Color> stateColors = [Colors.orange, Colors.grey, Colors.blue];
  final List<IconData> stateIcons = [Icons.wb_sunny, Icons.cloud, Icons.water_drop];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && isRunning) {
          _step();
          _controller.reset();
          _controller.forward();
        }
      });
    _calculateStationaryDistribution();
  }

  void _calculateStationaryDistribution() {
    // Power iteration to find stationary distribution
    List<double> pi = [1.0 / 3, 1.0 / 3, 1.0 / 3];

    for (int iter = 0; iter < 100; iter++) {
      List<double> newPi = [0, 0, 0];
      for (int j = 0; j < 3; j++) {
        for (int i = 0; i < 3; i++) {
          newPi[j] += pi[i] * transitionMatrix[i][j];
        }
      }
      pi = newPi;
    }

    setState(() => stationaryDist = pi);
  }

  void _step() {
    final r = _random.nextDouble();
    double cumulative = 0;
    int nextState = currentState;

    for (int j = 0; j < 3; j++) {
      cumulative += transitionMatrix[currentState][j];
      if (r < cumulative) {
        nextState = j;
        break;
      }
    }

    setState(() {
      currentState = nextState;
      history.add(nextState);
      if (history.length > 50) history.removeAt(0);
      stepCount++;
    });
  }

  void _toggleRun() {
    HapticFeedback.selectionClick();
    setState(() => isRunning = !isRunning);
    if (isRunning) {
      _controller.forward();
    } else {
      _controller.stop();
    }
  }

  void _singleStep() {
    HapticFeedback.lightImpact();
    _step();
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      currentState = 0;
      history = [0];
      stepCount = 0;
      isRunning = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate empirical distribution from history
    final counts = [0, 0, 0];
    for (final state in history) {
      counts[state]++;
    }
    final empirical = counts.map((c) => c / history.length).toList();

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
              isKorean ? '확률론' : 'PROBABILITY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '마르코프 체인' : 'Markov Chain',
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
          category: isKorean ? '확률론' : 'PROBABILITY',
          title: isKorean ? '마르코프 체인' : 'Markov Chain',
          formula: 'P(Xₙ₊₁|Xₙ,...,X₁) = P(Xₙ₊₁|Xₙ)',
          formulaDescription: isKorean
              ? '마르코프 체인은 다음 상태가 오직 현재 상태에만 의존하는 확률 과정입니다 (무기억성).'
              : 'A Markov chain is a stochastic process where the next state depends only on the current state (memoryless property).',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: MarkovChainPainter(
                transitionMatrix: transitionMatrix,
                currentState: currentState,
                history: history,
                stateColors: stateColors,
                animationProgress: _controller.value,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current state display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: stateColors[currentState].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stateColors[currentState]),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(stateIcons[currentState], color: stateColors[currentState], size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKorean ? '현재 상태' : 'Current State',
                          style: const TextStyle(color: AppColors.muted, fontSize: 10),
                        ),
                        Text(
                          isKorean ? stateNamesKo[currentState] : stateNames[currentState],
                          style: TextStyle(
                            color: stateColors[currentState],
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKorean ? '단계' : 'Steps',
                          style: const TextStyle(color: AppColors.muted, fontSize: 10),
                        ),
                        Text(
                          '$stepCount',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Distribution comparison
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKorean ? '분포 비교' : 'Distribution Comparison',
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 60),
                        for (int i = 0; i < 3; i++)
                          Expanded(
                            child: Center(
                              child: Icon(stateIcons[i], color: stateColors[i], size: 16),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _DistributionRow(
                      label: isKorean ? '경험적' : 'Empirical',
                      values: empirical,
                      colors: stateColors,
                    ),
                    const SizedBox(height: 4),
                    _DistributionRow(
                      label: isKorean ? '정상분포' : 'Stationary',
                      values: stationaryDist,
                      colors: stateColors,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Transition probabilities (simplified)
              Text(
                isKorean ? '전이 확률 (현재 상태에서)' : 'Transition Probabilities (from current)',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(3, (j) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Icon(stateIcons[j], color: stateColors[j], size: 20),
                          const SizedBox(height: 4),
                          Text(
                            '${(transitionMatrix[currentState][j] * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: stateColors[j],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning
                    ? (isKorean ? '정지' : 'Stop')
                    : (isKorean ? '자동 실행' : 'Auto Run'),
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleRun,
              ),
              SimButton(
                label: isKorean ? '한 단계' : 'Step',
                icon: Icons.skip_next,
                onPressed: isRunning ? null : _singleStep,
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

class _DistributionRow extends StatelessWidget {
  final String label;
  final List<double> values;
  final List<Color> colors;

  const _DistributionRow({
    required this.label,
    required this.values,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        ),
        for (int i = 0; i < values.length; i++)
          Expanded(
            child: Center(
              child: Text(
                '${(values[i] * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: colors[i],
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MarkovChainPainter extends CustomPainter {
  final List<List<double>> transitionMatrix;
  final int currentState;
  final List<int> history;
  final List<Color> stateColors;
  final double animationProgress;

  MarkovChainPainter({
    required this.transitionMatrix,
    required this.currentState,
    required this.history,
    required this.stateColors,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Draw state diagram
    final centerY = size.height * 0.4;
    final radius = 30.0;
    final spacing = size.width / 4;

    final statePositions = [
      Offset(spacing, centerY),
      Offset(spacing * 2, centerY - 40),
      Offset(spacing * 3, centerY),
    ];

    // Draw transitions (arrows)
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (transitionMatrix[i][j] > 0.05) {
          _drawTransition(
            canvas,
            statePositions[i],
            statePositions[j],
            transitionMatrix[i][j],
            i == j,
            radius,
            i == currentState,
          );
        }
      }
    }

    // Draw states
    for (int i = 0; i < 3; i++) {
      final isActive = i == currentState;
      final pos = statePositions[i];

      // Glow effect for current state
      if (isActive) {
        canvas.drawCircle(
          pos,
          radius + 8,
          Paint()..color = stateColors[i].withValues(alpha: 0.3),
        );
      }

      // State circle
      canvas.drawCircle(
        pos,
        radius,
        Paint()..color = isActive ? stateColors[i] : stateColors[i].withValues(alpha: 0.3),
      );
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = stateColors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 3 : 1,
      );

      // State label
      _drawText(
        canvas,
        ['S', 'C', 'R'][i],
        pos,
        isActive ? Colors.white : stateColors[i],
        fontSize: 16,
      );
    }

    // Draw history timeline
    final timelineY = size.height * 0.8;
    final timelineStart = 30.0;
    final timelineWidth = size.width - 60;
    final dotSpacing = timelineWidth / math.max(history.length - 1, 1);

    // Timeline line
    canvas.drawLine(
      Offset(timelineStart, timelineY),
      Offset(size.width - 30, timelineY),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..strokeWidth = 2,
    );

    // History dots
    for (int i = 0; i < history.length; i++) {
      final x = timelineStart + i * dotSpacing;
      final state = history[i];
      final isLast = i == history.length - 1;

      canvas.drawCircle(
        Offset(x, timelineY),
        isLast ? 6 : 4,
        Paint()..color = stateColors[state],
      );
    }

    // Timeline label
    _drawText(
      canvas,
      'History',
      Offset(size.width / 2, timelineY + 15),
      AppColors.muted,
      fontSize: 10,
    );
  }

  void _drawTransition(Canvas canvas, Offset from, Offset to, double prob,
      bool isSelfLoop, double radius, bool isActive) {
    final paint = Paint()
      ..color = isActive
          ? AppColors.accent.withValues(alpha: 0.8)
          : AppColors.muted.withValues(alpha: 0.3)
      ..strokeWidth = isActive ? 2 : 1
      ..style = PaintingStyle.stroke;

    if (isSelfLoop) {
      // Self-loop
      final loopRadius = radius * 0.6;
      canvas.drawArc(
        Rect.fromCircle(center: from - Offset(0, radius + loopRadius), radius: loopRadius),
        0.5,
        5,
        false,
        paint,
      );
    } else {
      // Arrow between states
      final direction = (to - from);
      final distance = direction.distance;
      final unit = direction / distance;

      final start = from + unit * radius;
      final end = to - unit * radius;

      // Curved path
      final mid = (start + end) / 2;
      final normal = Offset(-unit.dy, unit.dx);
      final control = mid + normal * 20;

      final path = Path();
      path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);

      // Arrowhead
      final arrowDirection = (end - control).normalize();
      final arrowSize = 8.0;
      final arrowLeft = end - arrowDirection * arrowSize + Offset(-arrowDirection.dy, arrowDirection.dx) * arrowSize / 2;
      final arrowRight = end - arrowDirection * arrowSize - Offset(-arrowDirection.dy, arrowDirection.dx) * arrowSize / 2;

      final arrowPath = Path();
      arrowPath.moveTo(end.dx, end.dy);
      arrowPath.lineTo(arrowLeft.dx, arrowLeft.dy);
      arrowPath.lineTo(arrowRight.dx, arrowRight.dy);
      arrowPath.close();

      canvas.drawPath(arrowPath, Paint()..color = paint.color);
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant MarkovChainPainter oldDelegate) =>
      currentState != oldDelegate.currentState ||
      history.length != oldDelegate.history.length ||
      animationProgress != oldDelegate.animationProgress;
}

extension on Offset {
  Offset normalize() {
    final d = distance;
    return d > 0 ? this / d : this;
  }
}
