import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Policy Gradient Simulation (Cart-Pole like environment)
class PolicyGradientScreen extends ConsumerStatefulWidget {
  const PolicyGradientScreen({super.key});

  @override
  ConsumerState<PolicyGradientScreen> createState() => _PolicyGradientScreenState();
}

class _PolicyGradientScreenState extends ConsumerState<PolicyGradientScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  // Cart-Pole state
  double _cartPosition = 0.0;
  double _cartVelocity = 0.0;
  double _poleAngle = 0.0;
  double _poleAngularVelocity = 0.0;

  // Policy network weights (simple linear policy)
  List<double> _policyWeights = [];

  // Training state
  bool _isTraining = false;
  int _episode = 0;
  int _stepCount = 0;
  int _maxStepsReached = 0;
  List<int> _episodeLengths = [];

  // Episode trajectory
  List<List<double>> _stateHistory = [];
  List<int> _actionHistory = [];
  List<double> _rewardHistory = [];

  // Parameters
  double _learningRate = 0.01;
  double _gravity = 9.8;
  double _cartMass = 1.0;
  double _poleMass = 0.1;
  double _poleLength = 0.5;
  double _forceMagnitude = 10.0;
  final double _dt = 0.02;

  @override
  void initState() {
    super.initState();
    _initializePolicy();
    _resetEnvironment();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20),
    )..addListener(_step);
  }

  void _initializePolicy() {
    // 4 state features -> 1 output (probability of going right)
    _policyWeights = List.generate(4, (_) => (_random.nextDouble() - 0.5) * 0.1);
  }

  void _resetEnvironment() {
    _cartPosition = 0.0;
    _cartVelocity = 0.0;
    _poleAngle = (_random.nextDouble() - 0.5) * 0.1; // Small random angle
    _poleAngularVelocity = 0.0;
    _stepCount = 0;
    _stateHistory.clear();
    _actionHistory.clear();
    _rewardHistory.clear();
  }

  List<double> _getState() {
    return [_cartPosition, _cartVelocity, _poleAngle, _poleAngularVelocity];
  }

  double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x.clamp(-500, 500)));

  double _policyForward(List<double> state) {
    double logit = 0;
    for (int i = 0; i < state.length; i++) {
      logit += state[i] * _policyWeights[i];
    }
    return _sigmoid(logit);
  }

  int _selectAction(List<double> state) {
    final prob = _policyForward(state);
    return _random.nextDouble() < prob ? 1 : 0; // 1 = right, 0 = left
  }

  void _physicsStep(int action) {
    final force = action == 1 ? _forceMagnitude : -_forceMagnitude;

    final cosTheta = math.cos(_poleAngle);
    final sinTheta = math.sin(_poleAngle);

    final totalMass = _cartMass + _poleMass;
    final poleMassLength = _poleMass * _poleLength;

    // Physics equations
    final temp = (force + poleMassLength * _poleAngularVelocity * _poleAngularVelocity * sinTheta) / totalMass;
    final thetaAcc = (_gravity * sinTheta - cosTheta * temp) /
        (_poleLength * (4.0 / 3.0 - _poleMass * cosTheta * cosTheta / totalMass));
    final xAcc = temp - poleMassLength * thetaAcc * cosTheta / totalMass;

    // Euler integration
    _cartPosition += _cartVelocity * _dt;
    _cartVelocity += xAcc * _dt;
    _poleAngle += _poleAngularVelocity * _dt;
    _poleAngularVelocity += thetaAcc * _dt;
  }

  bool _isDone() {
    return _cartPosition.abs() > 2.4 ||
        _poleAngle.abs() > math.pi / 6 || // 30 degrees
        _stepCount >= 500;
  }

  void _step() {
    if (!_isTraining) return;

    setState(() {
      final state = _getState();
      final action = _selectAction(state);

      // Store trajectory
      _stateHistory.add(state);
      _actionHistory.add(action);

      // Take action
      _physicsStep(action);
      _stepCount++;

      // Reward: +1 for each step survived
      _rewardHistory.add(1.0);

      // Check if episode is done
      if (_isDone()) {
        // Update policy with REINFORCE
        _updatePolicy();

        // Record episode
        _episodeLengths.add(_stepCount);
        if (_episodeLengths.length > 50) {
          _episodeLengths.removeAt(0);
        }
        if (_stepCount > _maxStepsReached) {
          _maxStepsReached = _stepCount;
        }

        _episode++;
        _resetEnvironment();
      }
    });
  }

  void _updatePolicy() {
    if (_stateHistory.isEmpty) return;

    // Compute returns (cumulative discounted rewards)
    final returns = List<double>.filled(_rewardHistory.length, 0.0);
    double cumulative = 0;
    for (int t = _rewardHistory.length - 1; t >= 0; t--) {
      cumulative = _rewardHistory[t] + 0.99 * cumulative;
      returns[t] = cumulative;
    }

    // Normalize returns
    final meanReturn = returns.reduce((a, b) => a + b) / returns.length;
    final stdReturn = math.sqrt(
        returns.map((r) => math.pow(r - meanReturn, 2)).reduce((a, b) => a + b) /
            returns.length);
    final normalizedReturns = returns
        .map((r) => stdReturn > 0 ? (r - meanReturn) / (stdReturn + 1e-8) : 0.0)
        .toList();

    // Policy gradient update
    for (int t = 0; t < _stateHistory.length; t++) {
      final state = _stateHistory[t];
      final action = _actionHistory[t];
      final advantage = normalizedReturns[t];

      final prob = _policyForward(state);
      final gradient = action == 1 ? (1 - prob) : -prob;

      // Update weights
      for (int i = 0; i < _policyWeights.length; i++) {
        _policyWeights[i] += _learningRate * gradient * state[i] * advantage;
      }
    }
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
      final state = _getState();
      final action = _selectAction(state);
      _physicsStep(action);
      _stepCount++;
      setState(() {});
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      _isTraining = false;
      _episode = 0;
      _maxStepsReached = 0;
      _episodeLengths.clear();
      _initializePolicy();
      _resetEnvironment();
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
              isKorean ? '정책 경사법' : 'Policy Gradient',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '강화학습' : 'Reinforcement Learning',
          title: isKorean ? '정책 경사법 (REINFORCE)' : 'Policy Gradient (REINFORCE)',
          formula: 'nabla J(theta) = E[nabla log pi(a|s) * R]',
          formulaDescription: isKorean
              ? '보상을 최대화하는 방향으로 정책을 직접 학습'
              : 'Directly optimize policy in the direction of higher rewards',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PolicyGradientPainter(
                cartPosition: _cartPosition,
                poleAngle: _poleAngle,
                policyWeights: _policyWeights,
                episodeLengths: _episodeLengths,
                stepCount: _stepCount,
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
                  color: _stepCount > 200
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _stepCount > 200 ? Colors.green : AppColors.cardBorder,
                  ),
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
                          label: isKorean ? '현재 스텝' : 'Current Steps',
                          value: '$_stepCount',
                          color: AppColors.accent,
                        ),
                        _StatItem(
                          label: isKorean ? '최고 기록' : 'Best',
                          value: '$_maxStepsReached',
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: isKorean ? '평균 지속' : 'Avg Length',
                          value: _episodeLengths.isEmpty
                              ? '-'
                              : (_episodeLengths.reduce((a, b) => a + b) /
                                      _episodeLengths.length)
                                  .toStringAsFixed(1),
                          color: Colors.purple,
                        ),
                        _StatItem(
                          label: isKorean ? '막대 각도' : 'Pole Angle',
                          value: '${(_poleAngle * 180 / math.pi).toStringAsFixed(1)}',
                          color: _poleAngle.abs() < 0.2 ? Colors.green : Colors.orange,
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
                  label: isKorean ? '학습률' : 'Learning Rate',
                  value: _learningRate,
                  min: 0.001,
                  max: 0.1,
                  defaultValue: 0.01,
                  formatValue: (v) => v.toStringAsFixed(3),
                  onChanged: (v) => setState(() => _learningRate = v),
                ),
              ),
              const SizedBox(height: 16),

              // Policy weights display
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
                      isKorean ? '정책 네트워크 가중치' : 'Policy Network Weights',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _WeightItem(
                          label: isKorean ? '위치' : 'Pos',
                          value: _policyWeights.isNotEmpty ? _policyWeights[0] : 0,
                        ),
                        _WeightItem(
                          label: isKorean ? '속도' : 'Vel',
                          value: _policyWeights.length > 1 ? _policyWeights[1] : 0,
                        ),
                        _WeightItem(
                          label: isKorean ? '각도' : 'Angle',
                          value: _policyWeights.length > 2 ? _policyWeights[2] : 0,
                        ),
                        _WeightItem(
                          label: isKorean ? '각속도' : 'AngVel',
                          value: _policyWeights.length > 3 ? _policyWeights[3] : 0,
                        ),
                      ],
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

class _WeightItem extends StatelessWidget {
  final String label;
  final double value;

  const _WeightItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value > 0 ? Colors.green : (value < 0 ? Colors.red : AppColors.muted);
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 9)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value.toStringAsFixed(3),
            style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}

class _PolicyGradientPainter extends CustomPainter {
  final double cartPosition;
  final double poleAngle;
  final List<double> policyWeights;
  final List<int> episodeLengths;
  final int stepCount;
  final bool isKorean;

  _PolicyGradientPainter({
    required this.cartPosition,
    required this.poleAngle,
    required this.policyWeights,
    required this.episodeLengths,
    required this.stepCount,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Cart-Pole visualization area
    final cartPoleHeight = size.height * 0.55;
    final chartHeight = size.height - cartPoleHeight - 30;

    // Draw Cart-Pole
    _drawCartPole(canvas, Size(size.width, cartPoleHeight));

    // Draw episode length chart
    _drawChart(
      canvas,
      Offset(20, cartPoleHeight + 20),
      Size(size.width - 40, chartHeight),
    );
  }

  void _drawCartPole(Canvas canvas, Size area) {
    final groundY = area.height * 0.75;
    final centerX = area.width / 2;

    // Draw ground
    canvas.drawLine(
      Offset(0, groundY),
      Offset(area.width, groundY),
      Paint()
        ..color = AppColors.cardBorder
        ..strokeWidth = 2,
    );

    // Draw track markers
    for (int i = -3; i <= 3; i++) {
      final x = centerX + i * 50;
      canvas.drawLine(
        Offset(x, groundY),
        Offset(x, groundY + 10),
        Paint()
          ..color = AppColors.muted
          ..strokeWidth = 1,
      );
    }

    // Cart position on screen
    final cartX = centerX + cartPosition * 80; // Scale factor
    final cartWidth = 60.0;
    final cartHeight = 30.0;

    // Draw cart
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cartX, groundY - cartHeight / 2),
          width: cartWidth,
          height: cartHeight,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.blue.shade700,
    );

    // Draw wheels
    canvas.drawCircle(
      Offset(cartX - cartWidth / 3, groundY),
      8,
      Paint()..color = Colors.grey.shade800,
    );
    canvas.drawCircle(
      Offset(cartX + cartWidth / 3, groundY),
      8,
      Paint()..color = Colors.grey.shade800,
    );

    // Draw pole
    final poleLength = 100.0;
    final poleEndX = cartX + poleLength * math.sin(poleAngle);
    final poleEndY = groundY - cartHeight - poleLength * math.cos(poleAngle);

    canvas.drawLine(
      Offset(cartX, groundY - cartHeight),
      Offset(poleEndX, poleEndY),
      Paint()
        ..color = Colors.orange
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Draw pole pivot
    canvas.drawCircle(
      Offset(cartX, groundY - cartHeight),
      6,
      Paint()..color = Colors.grey.shade700,
    );

    // Draw angle indicator
    if (poleAngle.abs() > 0.01) {
      final arcRect = Rect.fromCenter(
        center: Offset(cartX, groundY - cartHeight),
        width: 40,
        height: 40,
      );
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        poleAngle,
        false,
        Paint()
          ..color = poleAngle.abs() < 0.2 ? Colors.green : Colors.red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // Draw boundaries
    final boundaryX1 = centerX - 2.4 * 80;
    final boundaryX2 = centerX + 2.4 * 80;
    canvas.drawLine(
      Offset(boundaryX1, groundY - 150),
      Offset(boundaryX1, groundY),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      Offset(boundaryX2, groundY - 150),
      Offset(boundaryX2, groundY),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Labels
    _drawText(
      canvas,
      isKorean ? '스텝: $stepCount' : 'Step: $stepCount',
      Offset(10, 10),
      AppColors.ink,
      fontSize: 12,
    );
  }

  void _drawChart(Canvas canvas, Offset origin, Size chartSize) {
    // Chart background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx, origin.dy, chartSize.width, chartSize.height),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.card,
    );

    _drawText(
      canvas,
      isKorean ? '에피소드 지속 시간' : 'Episode Length',
      Offset(origin.dx + 5, origin.dy + 5),
      AppColors.muted,
      fontSize: 9,
    );

    if (episodeLengths.isEmpty) return;

    final maxLength = episodeLengths.reduce(math.max).toDouble();
    final effectiveMax = maxLength > 0 ? maxLength : 1.0;

    final path = Path();
    final padding = 10.0;

    for (int i = 0; i < episodeLengths.length; i++) {
      final x = origin.dx +
          padding +
          (i / (episodeLengths.length - 1).clamp(1, double.infinity)) *
              (chartSize.width - padding * 2);
      final y = origin.dy +
          chartSize.height -
          padding -
          (episodeLengths[i] / effectiveMax) * (chartSize.height - padding * 2 - 15);

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

  void _drawText(Canvas canvas, String text, Offset position, Color color,
      {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _PolicyGradientPainter oldDelegate) => true;
}
