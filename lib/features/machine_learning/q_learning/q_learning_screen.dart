import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Q-Learning Simulation
class QLearningScreen extends ConsumerStatefulWidget {
  const QLearningScreen({super.key});

  @override
  ConsumerState<QLearningScreen> createState() => _QLearningScreenState();
}

class _QLearningScreenState extends ConsumerState<QLearningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  // Grid world
  static const int _gridSize = 5;
  late List<List<double>> _rewards;
  late List<List<List<double>>> _qTable; // [row][col][action]

  // Agent state
  int _agentRow = 0;
  int _agentCol = 0;
  int _goalRow = 4;
  int _goalCol = 4;

  // Obstacles
  List<List<int>> _obstacles = [];

  // Parameters
  double _learningRate = 0.1;
  double _discountFactor = 0.9;
  double _epsilon = 0.3;

  // Training state
  bool _isTraining = false;
  int _episode = 0;
  int _stepCount = 0;
  int _totalReward = 0;
  List<int> _episodeRewards = [];

  // Actions: 0=up, 1=right, 2=down, 3=left
  static const List<List<int>> _actionDeltas = [
    [-1, 0], // up
    [0, 1], // right
    [1, 0], // down
    [0, -1], // left
  ];

  @override
  void initState() {
    super.initState();
    _initializeEnvironment();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(_step);
  }

  void _initializeEnvironment() {
    // Initialize rewards
    _rewards = List.generate(
      _gridSize,
      (i) => List.generate(_gridSize, (j) => -1.0), // Small negative reward for each step
    );
    _rewards[_goalRow][_goalCol] = 100.0; // Goal reward

    // Initialize Q-table
    _qTable = List.generate(
      _gridSize,
      (i) => List.generate(
        _gridSize,
        (j) => List.generate(4, (_) => 0.0),
      ),
    );

    // Set obstacles
    _obstacles = [
      [1, 1],
      [1, 3],
      [2, 1],
      [3, 3],
    ];

    // Set obstacle rewards
    for (final obs in _obstacles) {
      _rewards[obs[0]][obs[1]] = -50.0;
    }

    _resetAgent();
  }

  void _resetAgent() {
    _agentRow = 0;
    _agentCol = 0;
    _stepCount = 0;
    _totalReward = 0;
  }

  bool _isValidState(int row, int col) {
    return row >= 0 && row < _gridSize && col >= 0 && col < _gridSize;
  }

  int _selectAction() {
    // Epsilon-greedy policy
    if (_random.nextDouble() < _epsilon) {
      return _random.nextInt(4);
    } else {
      // Select best action
      final qValues = _qTable[_agentRow][_agentCol];
      int bestAction = 0;
      double bestValue = qValues[0];
      for (int a = 1; a < 4; a++) {
        if (qValues[a] > bestValue) {
          bestValue = qValues[a];
          bestAction = a;
        }
      }
      return bestAction;
    }
  }

  void _step() {
    if (!_isTraining) return;

    setState(() {
      // Select action
      final action = _selectAction();

      // Calculate next state
      int nextRow = _agentRow + _actionDeltas[action][0];
      int nextCol = _agentCol + _actionDeltas[action][1];

      // Check bounds
      if (!_isValidState(nextRow, nextCol)) {
        nextRow = _agentRow;
        nextCol = _agentCol;
      }

      // Get reward
      final reward = _rewards[nextRow][nextCol];
      _totalReward += reward.toInt();

      // Q-learning update
      final currentQ = _qTable[_agentRow][_agentCol][action];
      final maxNextQ = _qTable[nextRow][nextCol].reduce(math.max);
      final newQ = currentQ +
          _learningRate * (reward + _discountFactor * maxNextQ - currentQ);
      _qTable[_agentRow][_agentCol][action] = newQ;

      // Move agent
      _agentRow = nextRow;
      _agentCol = nextCol;
      _stepCount++;

      // Check if reached goal or max steps
      if ((_agentRow == _goalRow && _agentCol == _goalCol) ||
          _stepCount >= 100) {
        _episodeRewards.add(_totalReward);
        if (_episodeRewards.length > 50) {
          _episodeRewards.removeAt(0);
        }
        _episode++;
        _resetAgent();

        // Decay epsilon
        _epsilon = math.max(0.01, _epsilon * 0.995);
      }
    });
  }

  void _toggleTraining() {
    HapticFeedback.selectionClick();
    setState(() {
      _isTraining = !_isTraining;
      if (_isTraining) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _stepOnce() {
    HapticFeedback.lightImpact();
    if (!_isTraining) {
      _step();
      setState(() {});
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      _isTraining = false;
      _episode = 0;
      _epsilon = 0.3;
      _episodeRewards.clear();
      _initializeEnvironment();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);

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
              isKorean ? '머신러닝' : 'MACHINE LEARNING',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? 'Q-러닝' : 'Q-Learning',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '강화학습' : 'Reinforcement Learning',
          title: isKorean ? 'Q-러닝' : 'Q-Learning',
          formula: 'Q(s,a) <- Q(s,a) + alpha[r + gamma*max Q(s\',a\') - Q(s,a)]',
          formulaDescription: isKorean
              ? '에이전트가 환경과 상호작용하며 최적의 행동 정책을 학습'
              : 'Agent learns optimal policy by interacting with environment',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _QLearningPainter(
                gridSize: _gridSize,
                qTable: _qTable,
                rewards: _rewards,
                agentRow: _agentRow,
                agentCol: _agentCol,
                goalRow: _goalRow,
                goalCol: _goalCol,
                obstacles: _obstacles,
                episodeRewards: _episodeRewards,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: isKorean ? '에피소드' : 'Episode',
                          value: '$_episode',
                          color: Colors.blue,
                        ),
                        _StatItem(
                          label: isKorean ? '스텝' : 'Steps',
                          value: '$_stepCount',
                          color: AppColors.accent,
                        ),
                        _StatItem(
                          label: isKorean ? '탐험율' : 'Epsilon',
                          value: _epsilon.toStringAsFixed(3),
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: isKorean ? '현재 보상' : 'Current Reward',
                          value: '$_totalReward',
                          color: _totalReward >= 0 ? Colors.green : Colors.red,
                        ),
                        _StatItem(
                          label: isKorean ? '평균 보상' : 'Avg Reward',
                          value: _episodeRewards.isEmpty
                              ? '-'
                              : (_episodeRewards.reduce((a, b) => a + b) /
                                      _episodeRewards.length)
                                  .toStringAsFixed(1),
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Learning rate slider
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '학습률 (alpha)' : 'Learning Rate (alpha)',
                  value: _learningRate,
                  min: 0.01,
                  max: 0.5,
                  defaultValue: 0.1,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _learningRate = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '할인 계수 (gamma)' : 'Discount Factor (gamma)',
                    value: _discountFactor,
                    min: 0.5,
                    max: 0.99,
                    defaultValue: 0.9,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _discountFactor = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Q-value display for current state
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
                      isKorean
                          ? '현재 상태 Q-값 ($_agentRow, $_agentCol)'
                          : 'Q-Values at ($_agentRow, $_agentCol)',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(4, (i) {
                        final qValue = _qTable[_agentRow][_agentCol][i];
                        final isMax = qValue ==
                            _qTable[_agentRow][_agentCol].reduce(math.max);
                        return Column(
                          children: [
                            Icon(
                              [
                                Icons.arrow_upward,
                                Icons.arrow_forward,
                                Icons.arrow_downward,
                                Icons.arrow_back,
                              ][i],
                              size: 16,
                              color: isMax ? AppColors.accent : AppColors.muted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              qValue.toStringAsFixed(1),
                              style: TextStyle(
                                color: isMax ? AppColors.accent : AppColors.muted,
                                fontSize: 11,
                                fontWeight:
                                    isMax ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      }),
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
                label: _isTraining
                    ? (isKorean ? '정지' : 'Stop')
                    : (isKorean ? '학습' : 'Train'),
                icon: _isTraining ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleTraining,
              ),
              SimButton(
                label: isKorean ? '한 스텝' : 'Step',
                icon: Icons.skip_next,
                onPressed: !_isTraining ? _stepOnce : null,
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _QLearningPainter extends CustomPainter {
  final int gridSize;
  final List<List<List<double>>> qTable;
  final List<List<double>> rewards;
  final int agentRow;
  final int agentCol;
  final int goalRow;
  final int goalCol;
  final List<List<int>> obstacles;
  final List<int> episodeRewards;
  final bool isKorean;

  _QLearningPainter({
    required this.gridSize,
    required this.qTable,
    required this.rewards,
    required this.agentRow,
    required this.agentCol,
    required this.goalRow,
    required this.goalCol,
    required this.obstacles,
    required this.episodeRewards,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final gridWidth = size.width * 0.55;
    final cellSize = gridWidth / gridSize;
    final gridLeft = 20.0;
    final gridTop = 30.0;

    // Draw grid
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final x = gridLeft + col * cellSize;
        final y = gridTop + row * cellSize;
        final rect = Rect.fromLTWH(x, y, cellSize - 2, cellSize - 2);

        // Background color based on Q-value
        final maxQ = qTable[row][col].reduce(math.max);
        final minQ = qTable[row][col].reduce(math.min);
        final avgQ = (maxQ + minQ) / 2;
        final normalizedQ = (avgQ + 100) / 200; // Normalize roughly

        Color cellColor;
        if (obstacles.any((obs) => obs[0] == row && obs[1] == col)) {
          cellColor = Colors.red.shade800;
        } else if (row == goalRow && col == goalCol) {
          cellColor = Colors.green;
        } else {
          cellColor = Color.lerp(
            AppColors.card,
            Colors.blue.shade300,
            normalizedQ.clamp(0, 1),
          )!;
        }

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = cellColor,
        );

        // Draw policy arrows (best action)
        if (!obstacles.any((obs) => obs[0] == row && obs[1] == col) &&
            !(row == goalRow && col == goalCol)) {
          final qValues = qTable[row][col];
          int bestAction = 0;
          for (int a = 1; a < 4; a++) {
            if (qValues[a] > qValues[bestAction]) {
              bestAction = a;
            }
          }

          _drawArrow(
            canvas,
            Offset(x + cellSize / 2, y + cellSize / 2),
            bestAction,
            cellSize * 0.3,
            Colors.white.withValues(alpha: 0.7),
          );
        }

        // Draw agent
        if (row == agentRow && col == agentCol) {
          canvas.drawCircle(
            Offset(x + cellSize / 2, y + cellSize / 2),
            cellSize * 0.3,
            Paint()..color = Colors.yellow,
          );
          canvas.drawCircle(
            Offset(x + cellSize / 2, y + cellSize / 2),
            cellSize * 0.3,
            Paint()
              ..color = Colors.orange
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }

        // Draw goal
        if (row == goalRow && col == goalCol) {
          _drawText(
            canvas,
            'GOAL',
            Offset(x + cellSize / 2 - 14, y + cellSize / 2 - 6),
            Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          );
        }
      }
    }

    // Draw reward chart
    final chartLeft = gridLeft + gridWidth + 30;
    final chartWidth = size.width - chartLeft - 20;
    final chartTop = gridTop;
    final chartHeight = gridSize * cellSize;

    // Chart background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(chartLeft, chartTop, chartWidth, chartHeight),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.card,
    );

    // Chart title
    _drawText(
      canvas,
      isKorean ? '에피소드 보상' : 'Episode Rewards',
      Offset(chartLeft, chartTop - 18),
      AppColors.ink,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    // Draw reward line
    if (episodeRewards.isNotEmpty) {
      final maxReward = episodeRewards.reduce(math.max).toDouble();
      final minReward = episodeRewards.reduce(math.min).toDouble();
      final range = (maxReward - minReward).abs();
      final effectiveRange = range > 0 ? range : 1.0;

      final path = Path();
      for (int i = 0; i < episodeRewards.length; i++) {
        final x = chartLeft + (i / (episodeRewards.length - 1).clamp(1, double.infinity)) * chartWidth;
        final normalizedY = (episodeRewards[i] - minReward) / effectiveRange;
        final y = chartTop + chartHeight - normalizedY * chartHeight * 0.9 - 10;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.accent
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // Legend
    _drawText(canvas, isKorean ? '에이전트' : 'Agent',
        Offset(gridLeft, gridTop + gridWidth + 15), Colors.yellow,
        fontSize: 9);
    _drawText(canvas, isKorean ? '목표' : 'Goal',
        Offset(gridLeft + 60, gridTop + gridWidth + 15), Colors.green,
        fontSize: 9);
    _drawText(canvas, isKorean ? '장애물' : 'Obstacle',
        Offset(gridLeft + 100, gridTop + gridWidth + 15), Colors.red,
        fontSize: 9);
  }

  void _drawArrow(
      Canvas canvas, Offset center, int direction, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset end;
    switch (direction) {
      case 0: // up
        end = Offset(center.dx, center.dy - size);
        break;
      case 1: // right
        end = Offset(center.dx + size, center.dy);
        break;
      case 2: // down
        end = Offset(center.dx, center.dy + size);
        break;
      case 3: // left
        end = Offset(center.dx - size, center.dy);
        break;
      default:
        end = center;
    }

    canvas.drawLine(center, end, paint);

    // Arrow head
    final angle = (end - center).direction;
    final headSize = size * 0.4;
    canvas.drawLine(
      end,
      Offset(
        end.dx - headSize * math.cos(angle - 0.5),
        end.dy - headSize * math.sin(angle - 0.5),
      ),
      paint,
    );
    canvas.drawLine(
      end,
      Offset(
        end.dx - headSize * math.cos(angle + 0.5),
        end.dy - headSize * math.sin(angle + 0.5),
      ),
      paint,
    );
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color,
      {double fontSize = 12, FontWeight fontWeight = FontWeight.normal}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _QLearningPainter oldDelegate) => true;
}
