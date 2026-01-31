import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 퍼셉트론 시뮬레이션
class PerceptronScreen extends StatefulWidget {
  const PerceptronScreen({super.key});

  @override
  State<PerceptronScreen> createState() => _PerceptronScreenState();
}

class _PerceptronScreenState extends State<PerceptronScreen> {
  final _random = math.Random();
  List<_DataPoint> _points = [];
  double _w1 = 0;
  double _w2 = 0;
  double _bias = 0;
  double _learningRate = 0.1;
  int _epoch = 0;
  int _errors = 0;
  bool _isTraining = false;

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  void _generateData() {
    _points = [];

    // 선형 분리 가능한 데이터 생성
    for (int i = 0; i < 20; i++) {
      final x = _random.nextDouble();
      final y = _random.nextDouble();
      // y > x + 0.1 이면 클래스 1, 아니면 클래스 0
      final label = y > x + 0.1 ? 1 : 0;
      _points.add(_DataPoint(x: x, y: y, label: label));
    }

    _w1 = (_random.nextDouble() - 0.5) * 2;
    _w2 = (_random.nextDouble() - 0.5) * 2;
    _bias = (_random.nextDouble() - 0.5) * 2;
    _epoch = 0;
    _calculateErrors();
    setState(() {});
  }

  int _predict(double x, double y) {
    final z = _w1 * x + _w2 * y + _bias;
    return z >= 0 ? 1 : 0;
  }

  void _calculateErrors() {
    _errors = 0;
    for (var p in _points) {
      if (_predict(p.x, p.y) != p.label) {
        _errors++;
      }
    }
  }

  void _trainEpoch() {
    for (var p in _points) {
      final prediction = _predict(p.x, p.y);
      final error = p.label - prediction;

      if (error != 0) {
        _w1 += _learningRate * error * p.x;
        _w2 += _learningRate * error * p.y;
        _bias += _learningRate * error;
      }
    }
    _epoch++;
    _calculateErrors();
  }

  void _startTraining() async {
    _isTraining = true;
    for (int i = 0; i < 50 && _isTraining && _errors > 0; i++) {
      _trainEpoch();
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _isTraining = false;
    setState(() {});
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _isTraining = false;
    _generateData();
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
              'AI/ML',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '퍼셉트론',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML',
          title: '퍼셉트론 (Perceptron)',
          formula: 'y = step(w₁x₁ + w₂x₂ + b)',
          formulaDescription: '가장 간단한 인공 신경망의 기본 단위',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _PerceptronPainter(
                points: _points,
                w1: _w1,
                w2: _w2,
                bias: _bias,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _errors == 0 ? Colors.green.withValues(alpha: 0.1) : AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _errors == 0 ? Colors.green : AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    if (_errors == 0)
                      const Text(
                        '✓ 완벽히 분류됨!',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: 'w₁', value: _w1.toStringAsFixed(2), color: AppColors.accent),
                        _InfoItem(label: 'w₂', value: _w2.toStringAsFixed(2), color: AppColors.accent),
                        _InfoItem(label: 'bias', value: _bias.toStringAsFixed(2), color: Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '에폭', value: '$_epoch', color: Colors.blue),
                        _InfoItem(label: '오류', value: '$_errors / ${_points.length}', color: _errors > 0 ? Colors.red : Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 퍼셉트론 구조 시각화
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        _NeuronCircle(label: 'x₁'),
                        const SizedBox(height: 8),
                        _NeuronCircle(label: 'x₂'),
                        const SizedBox(height: 8),
                        _NeuronCircle(label: '1', isBias: true),
                      ],
                    ),
                    Column(
                      children: [
                        Text('w₁=${_w1.toStringAsFixed(1)}', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                        const Icon(Icons.arrow_forward, color: AppColors.muted, size: 16),
                        Text('w₂=${_w2.toStringAsFixed(1)}', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                        const Icon(Icons.arrow_forward, color: AppColors.muted, size: 16),
                        Text('b=${_bias.toStringAsFixed(1)}', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                      ],
                    ),
                    _NeuronCircle(label: 'Σ', isOutput: true),
                    const Icon(Icons.arrow_forward, color: AppColors.accent),
                    Column(
                      children: const [
                        Text('step', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                        Text('함수', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, color: AppColors.accent),
                    _NeuronCircle(label: 'y', isOutput: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '학습률',
                  value: _learningRate,
                  min: 0.01,
                  max: 0.5,
                  defaultValue: 0.1,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _learningRate = v),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isTraining ? '학습 중...' : '학습 시작',
                icon: Icons.play_arrow,
                isPrimary: true,
                onPressed: _isTraining ? null : () {
                  HapticFeedback.selectionClick();
                  _startTraining();
                },
              ),
              SimButton(
                label: '1 에폭',
                icon: Icons.skip_next,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _trainEpoch();
                  setState(() {});
                },
              ),
              SimButton(
                label: '새 데이터',
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

class _NeuronCircle extends StatelessWidget {
  final String label;
  final bool isBias;
  final bool isOutput;

  const _NeuronCircle({required this.label, this.isBias = false, this.isOutput = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isOutput ? AppColors.accent : (isBias ? Colors.orange : AppColors.card),
        shape: BoxShape.circle,
        border: Border.all(color: isOutput ? AppColors.accent : AppColors.muted),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isOutput ? Colors.white : AppColors.ink,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }
}

class _DataPoint {
  final double x, y;
  final int label;

  _DataPoint({required this.x, required this.y, required this.label});
}

class _PerceptronPainter extends CustomPainter {
  final List<_DataPoint> points;
  final double w1, w2, bias;

  _PerceptronPainter({required this.points, required this.w1, required this.w2, required this.bias});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 30.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 결정 경계 영역 (배경색)
    for (double x = 0; x <= 1; x += 0.02) {
      for (double y = 0; y <= 1; y += 0.02) {
        final z = w1 * x + w2 * y + bias;
        final px = padding + x * graphWidth;
        final py = size.height - padding - y * graphHeight;
        canvas.drawRect(
          Rect.fromCenter(center: Offset(px, py), width: graphWidth * 0.025, height: graphHeight * 0.025),
          Paint()..color = (z >= 0 ? Colors.blue : Colors.red).withValues(alpha: 0.1),
        );
      }
    }

    // 결정 경계선: w1*x + w2*y + bias = 0 → y = -(w1*x + bias) / w2
    if (w2.abs() > 0.01) {
      final y0 = -bias / w2;
      final y1 = -(w1 + bias) / w2;

      final startY = (1 - y0) * graphHeight + padding;
      final endY = (1 - y1) * graphHeight + padding;

      canvas.drawLine(
        Offset(padding, startY.clamp(padding, size.height - padding)),
        Offset(size.width - padding, endY.clamp(padding, size.height - padding)),
        Paint()
          ..color = AppColors.accent
          ..strokeWidth = 2,
      );
    }

    // 데이터 포인트
    for (var p in points) {
      final px = padding + p.x * graphWidth;
      final py = size.height - padding - p.y * graphHeight;
      final color = p.label == 1 ? Colors.blue : Colors.red;

      canvas.drawCircle(Offset(px, py), 8, Paint()..color = color);
      canvas.drawCircle(
        Offset(px, py),
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PerceptronPainter oldDelegate) => true;
}
