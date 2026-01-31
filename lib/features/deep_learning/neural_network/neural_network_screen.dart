import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 활성화 함수 열거형
enum ActivationFunction {
  sigmoid('시그모이드', 'σ(x) = 1/(1+e⁻ˣ)'),
  relu('ReLU', 'f(x) = max(0, x)'),
  tanh('Tanh', 'f(x) = tanh(x)');

  final String label;
  final String formula;
  const ActivationFunction(this.label, this.formula);
}

/// 신경망 플레이그라운드
class NeuralNetworkScreen extends StatefulWidget {
  const NeuralNetworkScreen({super.key});

  @override
  State<NeuralNetworkScreen> createState() => _NeuralNetworkScreenState();
}

class _NeuralNetworkScreenState extends State<NeuralNetworkScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 네트워크 구조
  List<int> layers = [2, 4, 4, 1];
  late List<List<double>> neurons;
  late List<List<List<double>>> weights;

  bool isTraining = false;
  int epoch = 0;
  double loss = 1.0;
  double learningRate = 0.1;
  ActivationFunction _activation = ActivationFunction.sigmoid;

  // 프리셋
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _initNetwork();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_train);
  }

  void _initNetwork() {
    final random = math.Random();

    // 뉴런 초기화
    neurons = layers.map((size) {
      return List.generate(size, (_) => random.nextDouble());
    }).toList();

    // 가중치 초기화 (Xavier 초기화)
    weights = [];
    for (int i = 0; i < layers.length - 1; i++) {
      final scale = math.sqrt(2.0 / (layers[i] + layers[i + 1]));
      weights.add(List.generate(
        layers[i],
        (_) => List.generate(
          layers[i + 1],
          (_) => (random.nextDouble() - 0.5) * 2 * scale,
        ),
      ));
    }

    epoch = 0;
    loss = 1.0;
  }

  double _activate(double x) {
    switch (_activation) {
      case ActivationFunction.sigmoid:
        return 1 / (1 + math.exp(-x.clamp(-500, 500)));
      case ActivationFunction.relu:
        return math.max(0, x);
      case ActivationFunction.tanh:
        return (math.exp(x) - math.exp(-x)) / (math.exp(x) + math.exp(-x));
    }
  }

  void _forward() {
    for (int l = 1; l < layers.length; l++) {
      for (int j = 0; j < layers[l]; j++) {
        double sum = 0;
        for (int i = 0; i < layers[l - 1]; i++) {
          sum += neurons[l - 1][i] * weights[l - 1][i][j];
        }
        neurons[l][j] = _activate(sum);
      }
    }
  }

  void _train() {
    if (!isTraining) return;

    setState(() {
      final random = math.Random();

      // 랜덤 입력 생성 (XOR 패턴)
      final input1 = random.nextBool() ? 1.0 : 0.0;
      final input2 = random.nextBool() ? 1.0 : 0.0;
      final target = (input1 != input2) ? 1.0 : 0.0;

      neurons[0][0] = input1;
      neurons[0][1] = input2;

      // 순전파
      _forward();

      // 오차 계산
      final output = neurons.last[0];
      final error = target - output;
      loss = loss * 0.99 + error.abs() * 0.01;

      // 간단한 가중치 업데이트
      for (int l = weights.length - 1; l >= 0; l--) {
        for (int i = 0; i < weights[l].length; i++) {
          for (int j = 0; j < weights[l][i].length; j++) {
            weights[l][i][j] += learningRate * error * neurons[l][i] * 0.1;
          }
        }
      }

      epoch++;
    });
  }

  void _toggleTraining() {
    HapticFeedback.selectionClick();
    setState(() {
      isTraining = !isTraining;
      if (isTraining) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;
      isTraining = false;
      _controller.stop();

      switch (preset) {
        case 'simple':
          layers = [2, 3, 1];
          break;
        case 'deep':
          layers = [2, 4, 4, 4, 1];
          break;
        case 'wide':
          layers = [2, 8, 8, 1];
          break;
        case 'xor':
          layers = [2, 4, 4, 1];
          break;
      }

      _initNetwork();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      isTraining = false;
      _initNetwork();
      _selectedPreset = null;
    });
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
              '딥러닝',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '신경망 플레이그라운드',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '딥러닝',
          title: '신경망 플레이그라운드',
          formula: _activation.formula,
          formulaDescription: 'XOR 문제를 해결하는 다층 퍼셉트론',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: NeuralNetworkPainter(
                layers: layers,
                neurons: neurons,
                weights: weights,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 네트워크 구조 프리셋
              PresetGroup(
                label: '네트워크 구조',
                presets: [
                  PresetButton(
                    label: '단순',
                    isSelected: _selectedPreset == 'simple',
                    onPressed: () => _applyPreset('simple'),
                  ),
                  PresetButton(
                    label: 'XOR',
                    isSelected: _selectedPreset == 'xor',
                    onPressed: () => _applyPreset('xor'),
                  ),
                  PresetButton(
                    label: '깊게',
                    isSelected: _selectedPreset == 'deep',
                    onPressed: () => _applyPreset('deep'),
                  ),
                  PresetButton(
                    label: '넓게',
                    isSelected: _selectedPreset == 'wide',
                    onPressed: () => _applyPreset('wide'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 통계
              _TrainingStats(
                epoch: epoch,
                loss: loss,
                isTraining: isTraining,
                layers: layers,
              ),
              const SizedBox(height: 16),
              // 활성화 함수 선택
              PresetGroup(
                label: '활성화 함수',
                presets: ActivationFunction.values.map((a) => PresetButton(
                  label: a.label,
                  isSelected: _activation == a,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _activation = a;
                      _initNetwork();
                    });
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),
              // 학습률 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '학습률 (Learning Rate)',
                  value: learningRate,
                  min: 0.01,
                  max: 0.5,
                  defaultValue: 0.1,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => learningRate = v),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isTraining ? '정지' : '학습 시작',
                icon: isTraining ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleTraining,
              ),
              SimButton(
                label: '순전파',
                icon: Icons.arrow_forward,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    final random = math.Random();
                    neurons[0][0] = random.nextDouble();
                    neurons[0][1] = random.nextDouble();
                    _forward();
                  });
                },
              ),
              SimButton(
                label: '리셋',
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

/// 학습 통계 위젯
class _TrainingStats extends StatelessWidget {
  final int epoch;
  final double loss;
  final bool isTraining;
  final List<int> layers;

  const _TrainingStats({
    required this.epoch,
    required this.loss,
    required this.isTraining,
    required this.layers,
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Epoch', value: '$epoch', color: AppColors.accent),
              _StatItem(
                label: 'Loss',
                value: loss.toStringAsFixed(4),
                color: loss < 0.1 ? AppColors.accent2 : AppColors.accent,
              ),
              _StatItem(
                label: '상태',
                value: isTraining ? '학습 중' : '정지',
                color: isTraining ? AppColors.accent2 : AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '구조: ${layers.join(" → ")}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class NeuralNetworkPainter extends CustomPainter {
  final List<int> layers;
  final List<List<double>> neurons;
  final List<List<List<double>>> weights;

  NeuralNetworkPainter({
    required this.layers,
    required this.neurons,
    required this.weights,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    final layerSpacing = size.width / (layers.length + 1);
    final nodeRadius = 18.0;

    // 노드 위치 계산
    List<List<Offset>> positions = [];
    for (int l = 0; l < layers.length; l++) {
      final x = layerSpacing * (l + 1);
      final nodeCount = layers[l];
      final totalHeight = nodeCount * (nodeRadius * 2 + 20);
      final startY = (size.height - totalHeight) / 2 + nodeRadius;

      List<Offset> layerPositions = [];
      for (int n = 0; n < nodeCount; n++) {
        final y = startY + n * (nodeRadius * 2 + 20);
        layerPositions.add(Offset(x, y));
      }
      positions.add(layerPositions);
    }

    // 연결선 그리기
    for (int l = 0; l < layers.length - 1; l++) {
      for (int i = 0; i < layers[l]; i++) {
        for (int j = 0; j < layers[l + 1]; j++) {
          final weight = weights[l][i][j];
          final color = weight > 0
              ? AppColors.accent.withValues(alpha: weight.abs().clamp(0.1, 0.8))
              : AppColors.accent2.withValues(alpha: weight.abs().clamp(0.1, 0.8));

          canvas.drawLine(
            positions[l][i],
            positions[l + 1][j],
            Paint()
              ..color = color
              ..strokeWidth = (weight.abs() * 2).clamp(0.5, 3),
          );
        }
      }
    }

    // 노드 그리기
    for (int l = 0; l < layers.length; l++) {
      for (int n = 0; n < layers[l]; n++) {
        final pos = positions[l][n];
        final activation = neurons[l][n];

        // 활성화에 따른 색상
        final color = Color.lerp(
          AppColors.simBg,
          AppColors.accent,
          activation.clamp(0, 1),
        )!;

        // 글로우 효과
        canvas.drawCircle(
          pos,
          nodeRadius + 4,
          Paint()..color = AppColors.accent.withValues(alpha: activation.clamp(0, 1) * 0.3),
        );

        // 노드 배경
        canvas.drawCircle(
          pos,
          nodeRadius,
          Paint()..color = color,
        );

        // 노드 테두리
        canvas.drawCircle(
          pos,
          nodeRadius,
          Paint()
            ..color = AppColors.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );

        // 활성화 값
        final textPainter = TextPainter(
          text: TextSpan(
            text: activation.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
        );
      }
    }

    // 레이어 라벨
    final labelNames = ['입력', ...List.generate(layers.length - 2, (i) => '은닉${i + 1}'), '출력'];
    for (int l = 0; l < layers.length && l < labelNames.length; l++) {
      final x = layerSpacing * (l + 1);
      _drawText(canvas, labelNames[l], Offset(x - 15, size.height - 20));
    }
  }

  void _drawText(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant NeuralNetworkPainter oldDelegate) => true;
}
