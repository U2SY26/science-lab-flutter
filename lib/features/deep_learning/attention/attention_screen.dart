import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Attention Mechanism Simulation
class AttentionScreen extends ConsumerStatefulWidget {
  const AttentionScreen({super.key});

  @override
  ConsumerState<AttentionScreen> createState() => _AttentionScreenState();
}

class _AttentionScreenState extends ConsumerState<AttentionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  // Attention type
  String _attentionType = 'dot'; // 'dot', 'additive', 'multiplicative'

  // Query, Key, Value vectors
  List<double> _query = [];
  List<List<double>> _keys = [];
  List<List<double>> _values = [];

  // Attention scores and weights
  List<double> _scores = [];
  List<double> _weights = [];
  List<double> _output = [];

  // Parameters
  final int _vectorDim = 4;
  final int _sequenceLength = 5;
  int _selectedQueryIndex = 0;
  double _temperature = 1.0;
  bool _isAnimating = false;
  double _animationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeVectors();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_animate);
  }

  void _initializeVectors() {
    // Initialize query
    _query = List.generate(_vectorDim, (_) => _random.nextDouble() * 2 - 1);

    // Initialize keys and values
    _keys = List.generate(
      _sequenceLength,
      (_) => List.generate(_vectorDim, (_) => _random.nextDouble() * 2 - 1),
    );
    _values = List.generate(
      _sequenceLength,
      (_) => List.generate(_vectorDim, (_) => _random.nextDouble() * 2 - 1),
    );

    _computeAttention();
  }

  void _computeAttention() {
    // Compute attention scores based on type
    _scores = List.generate(_sequenceLength, (i) {
      switch (_attentionType) {
        case 'dot':
          // Dot product attention: score = q . k
          double dot = 0;
          for (int j = 0; j < _vectorDim; j++) {
            dot += _query[j] * _keys[i][j];
          }
          return dot / math.sqrt(_vectorDim); // Scaled
        case 'additive':
          // Additive attention: score = v^T * tanh(W_q*q + W_k*k)
          double sum = 0;
          for (int j = 0; j < _vectorDim; j++) {
            sum += _tanh(_query[j] + _keys[i][j]);
          }
          return sum;
        case 'multiplicative':
          // Multiplicative attention: score = q^T * W * k
          double result = 0;
          for (int j = 0; j < _vectorDim; j++) {
            result += _query[j] * _keys[i][j] * 0.5; // Simplified W
          }
          return result;
        default:
          return 0;
      }
    });

    // Apply softmax with temperature
    _weights = _softmax(_scores.map((s) => s / _temperature).toList());

    // Compute weighted sum of values
    _output = List.filled(_vectorDim, 0.0);
    for (int i = 0; i < _sequenceLength; i++) {
      for (int j = 0; j < _vectorDim; j++) {
        _output[j] += _weights[i] * _values[i][j];
      }
    }
  }

  double _tanh(double x) {
    final ex = math.exp(x.clamp(-500, 500));
    final emx = math.exp(-x.clamp(-500, 500));
    return (ex - emx) / (ex + emx);
  }

  List<double> _softmax(List<double> x) {
    final maxVal = x.reduce(math.max);
    final exps = x.map((v) => math.exp(v - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  void _animate() {
    if (!_isAnimating) return;

    setState(() {
      _animationProgress += 0.02;
      if (_animationProgress >= 1.0) {
        _animationProgress = 0.0;
        _selectedQueryIndex = (_selectedQueryIndex + 1) % _sequenceLength;
        _query = _keys[_selectedQueryIndex].toList();
        _computeAttention();
      }
    });
  }

  void _startAnimation() {
    HapticFeedback.selectionClick();
    setState(() {
      _isAnimating = true;
    });
    _controller.repeat();
  }

  void _stopAnimation() {
    HapticFeedback.selectionClick();
    setState(() {
      _isAnimating = false;
    });
    _controller.stop();
  }

  void _randomizeVectors() {
    HapticFeedback.mediumImpact();
    setState(() {
      _initializeVectors();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      _isAnimating = false;
      _animationProgress = 0.0;
      _selectedQueryIndex = 0;
      _temperature = 1.0;
      _initializeVectors();
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
              isKorean ? '딥러닝' : 'DEEP LEARNING',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '어텐션 메커니즘' : 'Attention Mechanism',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '딥러닝' : 'Deep Learning',
          title: isKorean ? '어텐션 메커니즘' : 'Attention Mechanism',
          formula: _attentionType == 'dot'
              ? 'Attention(Q,K,V) = softmax(QK^T/sqrt(d))V'
              : (_attentionType == 'additive'
                  ? 'score = v^T tanh(W_q q + W_k k)'
                  : 'score = q^T W k'),
          formulaDescription: isKorean
              ? 'Query와 Key의 유사도를 계산하여 Value에 가중치를 부여'
              : 'Compute similarity between Query and Keys to weight Values',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _AttentionPainter(
                query: _query,
                keys: _keys,
                values: _values,
                scores: _scores,
                weights: _weights,
                output: _output,
                animationProgress: _animationProgress,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attention type selection
              SimSegment<String>(
                label: isKorean ? '어텐션 타입' : 'Attention Type',
                options: {
                  'dot': isKorean ? '닷 프로덕트' : 'Dot Product',
                  'additive': isKorean ? '가산' : 'Additive',
                  'multiplicative': isKorean ? '곱산' : 'Multiplicative',
                },
                selected: _attentionType,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _attentionType = v;
                    _computeAttention();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Temperature slider
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '온도 (Temperature)' : 'Temperature',
                  value: _temperature,
                  min: 0.1,
                  max: 3.0,
                  defaultValue: 1.0,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() {
                      _temperature = v;
                      _computeAttention();
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Attention weights display
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
                      isKorean ? '어텐션 가중치' : 'Attention Weights',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(_weights.length, (i) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              children: [
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(
                                        alpha: _weights[i].clamp(0.1, 1.0)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _weights[i].toStringAsFixed(2),
                                      style: TextStyle(
                                        color: _weights[i] > 0.3
                                            ? Colors.white
                                            : AppColors.muted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'K$i',
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
              const SizedBox(height: 16),

              // Output vector display
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
                      isKorean ? '출력 벡터' : 'Output Vector',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(_output.length, (i) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(
                                    alpha: ((_output[i] + 1) / 2).clamp(0.1, 1.0)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  _output[i].toStringAsFixed(2),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
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
                label: _isAnimating
                    ? (isKorean ? '정지' : 'Stop')
                    : (isKorean ? '애니메이션' : 'Animate'),
                icon: _isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _isAnimating ? _stopAnimation : _startAnimation,
              ),
              SimButton(
                label: isKorean ? '랜덤' : 'Random',
                icon: Icons.shuffle,
                onPressed: _randomizeVectors,
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

class _AttentionPainter extends CustomPainter {
  final List<double> query;
  final List<List<double>> keys;
  final List<List<double>> values;
  final List<double> scores;
  final List<double> weights;
  final List<double> output;
  final double animationProgress;
  final bool isKorean;

  _AttentionPainter({
    required this.query,
    required this.keys,
    required this.values,
    required this.scores,
    required this.weights,
    required this.output,
    required this.animationProgress,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 30.0;
    final queryY = 60.0;
    final keyValueY = 180.0;
    final outputY = size.height - 60;

    // Draw Query
    _drawVector(
      canvas,
      query,
      Offset(size.width / 2, queryY),
      40,
      30,
      'Query (Q)',
      AppColors.accent,
    );

    // Draw Keys and Values
    final kvSpacing = (size.width - padding * 2) / keys.length;
    for (int i = 0; i < keys.length; i++) {
      final x = padding + kvSpacing / 2 + i * kvSpacing;

      // Draw Key
      _drawVector(
        canvas,
        keys[i],
        Offset(x, keyValueY),
        30,
        25,
        'K$i',
        Colors.blue,
      );

      // Draw Value
      _drawVector(
        canvas,
        values[i],
        Offset(x, keyValueY + 70),
        30,
        25,
        'V$i',
        Colors.purple,
      );

      // Draw attention weight connection
      final weight = weights[i];
      canvas.drawLine(
        Offset(size.width / 2, queryY + 35),
        Offset(x, keyValueY - 15),
        Paint()
          ..color = AppColors.accent.withValues(alpha: weight.clamp(0.1, 1.0))
          ..strokeWidth = weight * 4 + 1,
      );

      // Draw weight label
      _drawText(
        canvas,
        weight.toStringAsFixed(2),
        Offset(x - 12, keyValueY - 35),
        AppColors.accent,
        fontSize: 9,
      );

      // Draw value to output connection
      canvas.drawLine(
        Offset(x, keyValueY + 95),
        Offset(size.width / 2, outputY - 20),
        Paint()
          ..color = Colors.green.withValues(alpha: weight.clamp(0.1, 0.6))
          ..strokeWidth = weight * 3 + 0.5,
      );
    }

    // Draw Output
    _drawVector(
      canvas,
      output,
      Offset(size.width / 2, outputY),
      40,
      30,
      isKorean ? '출력' : 'Output',
      Colors.green,
    );

    // Draw labels
    _drawText(canvas, isKorean ? '쿼리' : 'Query', Offset(padding, queryY - 10),
        AppColors.ink,
        fontSize: 11, fontWeight: FontWeight.bold);
    _drawText(canvas, isKorean ? '키 & 값' : 'Keys & Values',
        Offset(padding, keyValueY - 30), AppColors.ink,
        fontSize: 11, fontWeight: FontWeight.bold);

    // Draw softmax box
    final softmaxX = size.width - 100;
    final softmaxY = queryY + 50;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(softmaxX, softmaxY, 70, 30),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.orange.withValues(alpha: 0.3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(softmaxX, softmaxY, 70, 30),
        const Radius.circular(6),
      ),
      Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    _drawText(canvas, 'softmax', Offset(softmaxX + 10, softmaxY + 8),
        Colors.orange,
        fontSize: 10);
  }

  void _drawVector(
    Canvas canvas,
    List<double> vector,
    Offset center,
    double width,
    double height,
    String label,
    Color color,
  ) {
    final totalWidth = width * vector.length;
    final startX = center.dx - totalWidth / 2;

    for (int i = 0; i < vector.length; i++) {
      final x = startX + i * width;
      final rect = Rect.fromLTWH(x, center.dy - height / 2, width - 2, height);
      final normalizedValue = ((vector[i] + 1) / 2).clamp(0.0, 1.0);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = color.withValues(alpha: normalizedValue.clamp(0.2, 0.9)),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Draw label below
    _drawText(
      canvas,
      label,
      Offset(center.dx - label.length * 3, center.dy + height / 2 + 5),
      color,
      fontSize: 10,
    );
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color,
      {double fontSize = 12, FontWeight fontWeight = FontWeight.normal}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style:
            TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _AttentionPainter oldDelegate) => true;
}
