import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 선형 회귀 시뮬레이션
class LinearRegressionScreen extends StatefulWidget {
  const LinearRegressionScreen({super.key});

  @override
  State<LinearRegressionScreen> createState() => _LinearRegressionScreenState();
}

class _LinearRegressionScreenState extends State<LinearRegressionScreen> {
  final _random = math.Random();
  List<Offset> _points = [];
  double _slope = 0;
  double _intercept = 0;
  double _learningRate = 0.01;
  int _iterations = 0;
  double _mse = 0;
  bool _isTraining = false;

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  void _generateData() {
    // 노이즈가 있는 선형 데이터 생성
    final trueSlope = 0.5 + _random.nextDouble() * 0.5;
    final trueIntercept = 0.1 + _random.nextDouble() * 0.3;

    _points = List.generate(30, (i) {
      final x = _random.nextDouble();
      final noise = (_random.nextDouble() - 0.5) * 0.15;
      final y = (trueSlope * x + trueIntercept + noise).clamp(0.0, 1.0);
      return Offset(x, y);
    });

    _slope = 0;
    _intercept = 0.5;
    _iterations = 0;
    _calculateMSE();
    setState(() {});
  }

  void _calculateMSE() {
    if (_points.isEmpty) return;
    double sum = 0;
    for (var p in _points) {
      final predicted = _slope * p.dx + _intercept;
      sum += math.pow(p.dy - predicted, 2);
    }
    _mse = sum / _points.length;
  }

  void _trainStep() {
    if (_points.isEmpty) return;

    // 경사 하강법
    double slopeGrad = 0;
    double interceptGrad = 0;

    for (var p in _points) {
      final predicted = _slope * p.dx + _intercept;
      final error = predicted - p.dy;
      slopeGrad += error * p.dx;
      interceptGrad += error;
    }

    slopeGrad = (slopeGrad * 2) / _points.length;
    interceptGrad = (interceptGrad * 2) / _points.length;

    _slope -= _learningRate * slopeGrad;
    _intercept -= _learningRate * interceptGrad;
    _iterations++;
    _calculateMSE();
  }

  void _startTraining() async {
    _isTraining = true;
    for (int i = 0; i < 100 && _isTraining; i++) {
      _trainStep();
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _isTraining = false;
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
              '선형 회귀',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML',
          title: '선형 회귀',
          formula: 'y = wx + b',
          formulaDescription: '데이터에 가장 잘 맞는 직선을 찾는 지도 학습',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _LinearRegressionPainter(
                points: _points,
                slope: _slope,
                intercept: _intercept,
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
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '기울기 w', value: _slope.toStringAsFixed(3), color: AppColors.accent),
                        _InfoItem(label: '절편 b', value: _intercept.toStringAsFixed(3), color: Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: 'MSE', value: _mse.toStringAsFixed(4), color: Colors.red),
                        _InfoItem(label: '반복', value: '$_iterations', color: Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '학습률',
                  value: _learningRate,
                  min: 0.001,
                  max: 0.1,
                  defaultValue: 0.01,
                  formatValue: (v) => v.toStringAsFixed(3),
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
                label: '1 스텝',
                icon: Icons.skip_next,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _trainStep();
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

class _LinearRegressionPainter extends CustomPainter {
  final List<Offset> points;
  final double slope;
  final double intercept;

  _LinearRegressionPainter({required this.points, required this.slope, required this.intercept});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 30.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 축
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );

    // 회귀선
    final y0 = intercept;
    final y1 = slope + intercept;
    canvas.drawLine(
      Offset(padding, size.height - padding - y0 * graphHeight),
      Offset(size.width - padding, size.height - padding - y1 * graphHeight),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2,
    );

    // 데이터 포인트
    for (var p in points) {
      final px = padding + p.dx * graphWidth;
      final py = size.height - padding - p.dy * graphHeight;

      // 오차선
      final predictedY = slope * p.dx + intercept;
      final predPy = size.height - padding - predictedY * graphHeight;
      canvas.drawLine(
        Offset(px, py),
        Offset(px, predPy),
        Paint()
          ..color = Colors.red.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );

      // 포인트
      canvas.drawCircle(Offset(px, py), 5, Paint()..color = Colors.blue);
    }
  }

  @override
  bool shouldRepaint(covariant _LinearRegressionPainter oldDelegate) => true;
}
