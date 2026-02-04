import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Multi-Armed Bandit Simulation
class MultiArmedBanditScreen extends ConsumerStatefulWidget {
  const MultiArmedBanditScreen({super.key});

  @override
  ConsumerState<MultiArmedBanditScreen> createState() =>
      _MultiArmedBanditScreenState();
}

class _MultiArmedBanditScreenState extends ConsumerState<MultiArmedBanditScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  // Bandit arms (slot machines)
  final int _numArms = 5;
  late List<double> _trueProbabilities; // Hidden true probabilities
  late List<int> _pulls; // Number of pulls for each arm
  late List<int> _rewards; // Total rewards for each arm
  late List<double> _estimatedProbabilities;

  // UCB specific
  late List<double> _ucbValues;

  // Strategy
  String _strategy = 'epsilon'; // 'epsilon', 'ucb', 'thompson'
  double _epsilon = 0.1;
  double _ucbC = 2.0; // UCB exploration parameter

  // Training state
  bool _isRunning = false;
  int _totalPulls = 0;
  int _totalRewards = 0;
  int _lastArm = -1;
  int _lastReward = 0;
  List<double> _rewardHistory = [];
  List<double> _regretHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeBandits();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(_step);
  }

  void _initializeBandits() {
    // Random true probabilities for each arm
    _trueProbabilities = List.generate(
      _numArms,
      (_) => _random.nextDouble() * 0.8 + 0.1, // 0.1 to 0.9
    );

    _pulls = List.filled(_numArms, 0);
    _rewards = List.filled(_numArms, 0);
    _estimatedProbabilities = List.filled(_numArms, 0.5);
    _ucbValues = List.filled(_numArms, double.infinity);

    _totalPulls = 0;
    _totalRewards = 0;
    _lastArm = -1;
    _lastReward = 0;
    _rewardHistory.clear();
    _regretHistory.clear();
  }

  int _selectArmEpsilonGreedy() {
    if (_random.nextDouble() < _epsilon) {
      // Explore: random arm
      return _random.nextInt(_numArms);
    } else {
      // Exploit: best estimated arm
      int bestArm = 0;
      for (int i = 1; i < _numArms; i++) {
        if (_estimatedProbabilities[i] > _estimatedProbabilities[bestArm]) {
          bestArm = i;
        }
      }
      return bestArm;
    }
  }

  int _selectArmUCB() {
    // First, try each arm once
    for (int i = 0; i < _numArms; i++) {
      if (_pulls[i] == 0) return i;
    }

    // UCB1: Q(a) + c * sqrt(ln(t) / N(a))
    for (int i = 0; i < _numArms; i++) {
      _ucbValues[i] = _estimatedProbabilities[i] +
          _ucbC * math.sqrt(math.log(_totalPulls) / _pulls[i]);
    }

    int bestArm = 0;
    for (int i = 1; i < _numArms; i++) {
      if (_ucbValues[i] > _ucbValues[bestArm]) {
        bestArm = i;
      }
    }
    return bestArm;
  }

  int _selectArmThompson() {
    // Thompson Sampling: sample from Beta distribution
    List<double> samples = List.generate(_numArms, (i) {
      final alpha = _rewards[i] + 1;
      final beta = _pulls[i] - _rewards[i] + 1;
      return _sampleBeta(alpha.toDouble(), beta.toDouble());
    });

    int bestArm = 0;
    for (int i = 1; i < _numArms; i++) {
      if (samples[i] > samples[bestArm]) {
        bestArm = i;
      }
    }
    return bestArm;
  }

  double _sampleBeta(double alpha, double beta) {
    // Approximate Beta sampling using gamma
    final x = _sampleGamma(alpha);
    final y = _sampleGamma(beta);
    return x / (x + y);
  }

  double _sampleGamma(double shape) {
    // Marsaglia and Tsang's method for gamma > 1
    if (shape < 1) {
      return _sampleGamma(shape + 1) * math.pow(_random.nextDouble(), 1 / shape);
    }

    final d = shape - 1 / 3;
    final c = 1 / math.sqrt(9 * d);

    while (true) {
      double x, v;
      do {
        x = _random.nextGaussian();
        v = 1 + c * x;
      } while (v <= 0);

      v = v * v * v;
      final u = _random.nextDouble();

      if (u < 1 - 0.0331 * x * x * x * x) return d * v;
      if (math.log(u) < 0.5 * x * x + d * (1 - v + math.log(v))) return d * v;
    }
  }

  int _selectArm() {
    switch (_strategy) {
      case 'epsilon':
        return _selectArmEpsilonGreedy();
      case 'ucb':
        return _selectArmUCB();
      case 'thompson':
        return _selectArmThompson();
      default:
        return _random.nextInt(_numArms);
    }
  }

  void _pullArm(int arm) {
    // Get reward based on true probability
    final reward = _random.nextDouble() < _trueProbabilities[arm] ? 1 : 0;

    // Update statistics
    _pulls[arm]++;
    _rewards[arm] += reward;
    _totalPulls++;
    _totalRewards += reward;

    // Update estimated probability
    _estimatedProbabilities[arm] = _rewards[arm] / _pulls[arm];

    _lastArm = arm;
    _lastReward = reward;

    // Track cumulative reward rate
    _rewardHistory.add(_totalRewards / _totalPulls);

    // Track regret (optimal - actual)
    final optimalProb = _trueProbabilities.reduce(math.max);
    final regret = optimalProb - _trueProbabilities[arm];
    final cumRegret = _regretHistory.isEmpty
        ? regret
        : _regretHistory.last + regret;
    _regretHistory.add(cumRegret);

    if (_rewardHistory.length > 200) {
      _rewardHistory.removeAt(0);
      _regretHistory.removeAt(0);
    }
  }

  void _step() {
    if (!_isRunning) return;

    setState(() {
      final arm = _selectArm();
      _pullArm(arm);
    });
  }

  void _toggleRunning() {
    HapticFeedback.selectionClick();
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _stepOnce() {
    HapticFeedback.lightImpact();
    if (!_isRunning) {
      final arm = _selectArm();
      _pullArm(arm);
      setState(() {});
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      _isRunning = false;
      _initializeBandits();
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
              isKorean ? '다중 슬롯머신 문제' : 'Multi-Armed Bandit',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '강화학습' : 'Reinforcement Learning',
          title: isKorean ? '다중 슬롯머신 문제' : 'Multi-Armed Bandit',
          formula: _strategy == 'ucb'
              ? 'UCB: Q(a) + c*sqrt(ln(t)/N(a))'
              : (_strategy == 'thompson'
                  ? 'Thompson: sample from Beta(alpha, beta)'
                  : 'Epsilon-Greedy: P(explore) = epsilon'),
          formulaDescription: isKorean
              ? '탐색(Exploration)과 활용(Exploitation)의 균형을 맞추는 문제'
              : 'Balance exploration and exploitation to maximize rewards',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BanditPainter(
                numArms: _numArms,
                trueProbabilities: _trueProbabilities,
                estimatedProbabilities: _estimatedProbabilities,
                pulls: _pulls,
                rewards: _rewards,
                ucbValues: _ucbValues,
                lastArm: _lastArm,
                lastReward: _lastReward,
                rewardHistory: _rewardHistory,
                strategy: _strategy,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Strategy selection
              SimSegment<String>(
                label: isKorean ? '전략' : 'Strategy',
                options: {
                  'epsilon': 'Epsilon-Greedy',
                  'ucb': 'UCB1',
                  'thompson': 'Thompson',
                },
                selected: _strategy,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _strategy = v);
                },
              ),
              const SizedBox(height: 16),

              // Stats display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: isKorean ? '총 시도' : 'Total Pulls',
                      value: '$_totalPulls',
                      color: Colors.blue,
                    ),
                    _StatItem(
                      label: isKorean ? '총 보상' : 'Total Rewards',
                      value: '$_totalRewards',
                      color: Colors.green,
                    ),
                    _StatItem(
                      label: isKorean ? '보상률' : 'Reward Rate',
                      value: _totalPulls > 0
                          ? '${(_totalRewards / _totalPulls * 100).toStringAsFixed(1)}%'
                          : '-',
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Strategy-specific parameters
              if (_strategy == 'epsilon')
                ControlGroup(
                  primaryControl: SimSlider(
                    label: isKorean ? '엡실론 (탐색 확률)' : 'Epsilon (Exploration)',
                    value: _epsilon,
                    min: 0.0,
                    max: 0.5,
                    defaultValue: 0.1,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _epsilon = v),
                  ),
                ),
              if (_strategy == 'ucb')
                ControlGroup(
                  primaryControl: SimSlider(
                    label: isKorean ? 'UCB 탐색 계수 (c)' : 'UCB Exploration (c)',
                    value: _ucbC,
                    min: 0.5,
                    max: 5.0,
                    defaultValue: 2.0,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _ucbC = v),
                  ),
                ),
              const SizedBox(height: 16),

              // Arm details
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isKorean ? '슬롯머신 상세' : 'Arm Details',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              color: Colors.green.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isKorean ? '실제' : 'True',
                              style: const TextStyle(color: AppColors.muted, fontSize: 9),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 10,
                              height: 10,
                              color: AppColors.accent.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isKorean ? '추정' : 'Est',
                              style: const TextStyle(color: AppColors.muted, fontSize: 9),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(_numArms, (i) {
                        final isLastArm = i == _lastArm;
                        final isBestArm = _trueProbabilities[i] ==
                            _trueProbabilities.reduce(math.max);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              children: [
                                Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: isLastArm
                                        ? AppColors.accent
                                        : AppColors.muted,
                                    fontSize: 10,
                                    fontWeight: isLastArm
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isLastArm
                                          ? AppColors.accent
                                          : (isBestArm
                                              ? Colors.green
                                              : AppColors.cardBorder),
                                      width: isLastArm || isBestArm ? 2 : 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      // True probability
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: FractionallySizedBox(
                                          heightFactor: _trueProbabilities[i],
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            color: Colors.green.withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),
                                      // Estimated probability
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: FractionallySizedBox(
                                          heightFactor: _estimatedProbabilities[i],
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            color: AppColors.accent.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_pulls[i]}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 9,
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
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning
                    ? (isKorean ? '정지' : 'Stop')
                    : (isKorean ? '실행' : 'Run'),
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleRunning,
              ),
              SimButton(
                label: isKorean ? '한 번' : 'Pull',
                icon: Icons.touch_app,
                onPressed: !_isRunning ? _stepOnce : null,
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

class _BanditPainter extends CustomPainter {
  final int numArms;
  final List<double> trueProbabilities;
  final List<double> estimatedProbabilities;
  final List<int> pulls;
  final List<int> rewards;
  final List<double> ucbValues;
  final int lastArm;
  final int lastReward;
  final List<double> rewardHistory;
  final String strategy;
  final bool isKorean;

  _BanditPainter({
    required this.numArms,
    required this.trueProbabilities,
    required this.estimatedProbabilities,
    required this.pulls,
    required this.rewards,
    required this.ucbValues,
    required this.lastArm,
    required this.lastReward,
    required this.rewardHistory,
    required this.strategy,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Draw slot machines
    _drawSlotMachines(canvas, Size(size.width, size.height * 0.6));

    // Draw reward history chart
    _drawRewardChart(
      canvas,
      Offset(20, size.height * 0.65),
      Size(size.width - 40, size.height * 0.3),
    );
  }

  void _drawSlotMachines(Canvas canvas, Size area) {
    final machineWidth = area.width / numArms * 0.8;
    final machineHeight = area.height * 0.7;
    final spacing = area.width / numArms;
    final startY = 30.0;

    for (int i = 0; i < numArms; i++) {
      final centerX = spacing * i + spacing / 2;
      final isSelected = i == lastArm;
      final isBest = trueProbabilities[i] == trueProbabilities.reduce(math.max);

      // Machine body
      final machineRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, startY + machineHeight / 2),
          width: machineWidth,
          height: machineHeight,
        ),
        const Radius.circular(8),
      );

      // Shadow
      canvas.drawRRect(
        machineRect.shift(const Offset(3, 3)),
        Paint()..color = Colors.black.withValues(alpha: 0.2),
      );

      // Body
      canvas.drawRRect(
        machineRect,
        Paint()
          ..color = isSelected
              ? AppColors.accent.withValues(alpha: 0.3)
              : AppColors.card,
      );

      // Border
      canvas.drawRRect(
        machineRect,
        Paint()
          ..color = isSelected
              ? AppColors.accent
              : (isBest ? Colors.green : AppColors.cardBorder)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 3 : 1,
      );

      // Display window
      final displayRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, startY + machineHeight * 0.35),
          width: machineWidth * 0.7,
          height: machineHeight * 0.3,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        displayRect,
        Paint()..color = Colors.black87,
      );

      // Show reward symbol if just pulled
      if (isSelected) {
        _drawText(
          canvas,
          lastReward == 1 ? 'WIN!' : 'X',
          Offset(centerX - 15, startY + machineHeight * 0.3),
          lastReward == 1 ? Colors.green : Colors.red,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        );
      }

      // Lever
      final leverX = centerX + machineWidth / 2 + 5;
      canvas.drawLine(
        Offset(leverX, startY + machineHeight * 0.3),
        Offset(leverX, startY + machineHeight * 0.6),
        Paint()
          ..color = Colors.grey.shade600
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(leverX, startY + machineHeight * 0.25),
        8,
        Paint()..color = Colors.red,
      );

      // Arm number
      _drawText(
        canvas,
        '${i + 1}',
        Offset(centerX - 5, startY + machineHeight + 5),
        isSelected ? AppColors.accent : AppColors.muted,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      );

      // Best arm star
      if (isBest) {
        _drawText(
          canvas,
          '*',
          Offset(centerX + machineWidth / 2 - 15, startY - 5),
          Colors.green,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        );
      }
    }
  }

  void _drawRewardChart(Canvas canvas, Offset origin, Size chartSize) {
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx, origin.dy, chartSize.width, chartSize.height),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.card,
    );

    _drawText(
      canvas,
      isKorean ? '누적 보상률' : 'Cumulative Reward Rate',
      Offset(origin.dx + 5, origin.dy + 5),
      AppColors.muted,
      fontSize: 9,
    );

    if (rewardHistory.isEmpty) return;

    final path = Path();
    final padding = 10.0;

    for (int i = 0; i < rewardHistory.length; i++) {
      final x = origin.dx +
          padding +
          (i / (rewardHistory.length - 1).clamp(1, double.infinity)) *
              (chartSize.width - padding * 2);
      final y = origin.dy +
          chartSize.height -
          padding -
          rewardHistory[i] * (chartSize.height - padding * 2 - 15);

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

    // Draw optimal line
    final optimalProb = trueProbabilities.reduce(math.max);
    final optimalY = origin.dy +
        chartSize.height -
        padding -
        optimalProb * (chartSize.height - padding * 2 - 15);
    canvas.drawLine(
      Offset(origin.dx + padding, optimalY),
      Offset(origin.dx + chartSize.width - padding, optimalY),
      Paint()
        ..color = Colors.green.withValues(alpha: 0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    _drawText(
      canvas,
      isKorean ? '최적' : 'Optimal',
      Offset(origin.dx + chartSize.width - 35, optimalY - 12),
      Colors.green,
      fontSize: 8,
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
  bool shouldRepaint(covariant _BanditPainter oldDelegate) => true;
}

// Extension for random gaussian
extension _RandomExtension on math.Random {
  double nextGaussian() {
    double u1 = nextDouble();
    double u2 = nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }
}
