import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// SVM (Support Vector Machine) 시각화 화면
class SvmScreen extends StatefulWidget {
  const SvmScreen({super.key});

  @override
  State<SvmScreen> createState() => _SvmScreenState();
}

class _SvmScreenState extends State<SvmScreen> {
  // 데이터 포인트
  List<_DataPoint> _points = [];

  // SVM 파라미터
  double _w1 = 1.0;
  double _w2 = 1.0;
  double _b = 0.0;
  double _margin = 0.3;

  // 서포트 벡터 인덱스
  List<int> _supportVectors = [];

  // 학습 상태
  bool _isTrained = false;
  int _iterations = 0;

  @override
  void initState() {
    super.initState();
    _generateData('linear');
  }

  void _generateData(String preset) {
    final rand = math.Random(42);
    _points = [];
    _isTrained = false;
    _iterations = 0;
    _supportVectors = [];

    switch (preset) {
      case 'linear':
        // 선형 분리 가능한 데이터
        for (int i = 0; i < 20; i++) {
          _points.add(_DataPoint(
            x: 0.1 + rand.nextDouble() * 0.35,
            y: 0.1 + rand.nextDouble() * 0.35,
            label: -1,
          ));
          _points.add(_DataPoint(
            x: 0.55 + rand.nextDouble() * 0.35,
            y: 0.55 + rand.nextDouble() * 0.35,
            label: 1,
          ));
        }
        break;
      case 'overlap':
        // 일부 겹치는 데이터
        for (int i = 0; i < 20; i++) {
          _points.add(_DataPoint(
            x: 0.15 + rand.nextDouble() * 0.4,
            y: 0.15 + rand.nextDouble() * 0.4,
            label: -1,
          ));
          _points.add(_DataPoint(
            x: 0.45 + rand.nextDouble() * 0.4,
            y: 0.45 + rand.nextDouble() * 0.4,
            label: 1,
          ));
        }
        break;
      case 'vertical':
        // 수직 분리
        for (int i = 0; i < 20; i++) {
          _points.add(_DataPoint(
            x: 0.1 + rand.nextDouble() * 0.3,
            y: rand.nextDouble(),
            label: -1,
          ));
          _points.add(_DataPoint(
            x: 0.6 + rand.nextDouble() * 0.3,
            y: rand.nextDouble(),
            label: 1,
          ));
        }
        break;
    }

    // 초기 결정 경계
    _w1 = 1.0;
    _w2 = 1.0;
    _b = -1.0;
    _normalizeWeights();

    setState(() {});
  }

  void _normalizeWeights() {
    final norm = math.sqrt(_w1 * _w1 + _w2 * _w2);
    if (norm > 0) {
      _w1 /= norm;
      _w2 /= norm;
    }
  }

  void _train() {
    HapticFeedback.lightImpact();

    // 간단한 퍼셉트론 기반 SVM 학습
    const learningRate = 0.1;
    const epochs = 100;

    for (int epoch = 0; epoch < epochs; epoch++) {
      bool updated = false;

      for (final point in _points) {
        final prediction = _w1 * point.x + _w2 * point.y + _b;
        final margin = point.label * prediction;

        if (margin < 1) {
          // 마진 위반 - 가중치 업데이트
          _w1 += learningRate * (point.label * point.x);
          _w2 += learningRate * (point.label * point.y);
          _b += learningRate * point.label * 0.1;
          updated = true;
        }
      }

      _iterations++;

      if (!updated) break;
    }

    _normalizeWeights();
    _findSupportVectors();

    setState(() {
      _isTrained = true;
    });

    HapticFeedback.heavyImpact();
  }

  void _findSupportVectors() {
    _supportVectors = [];
    const threshold = 0.3;

    for (int i = 0; i < _points.length; i++) {
      final point = _points[i];
      final dist = (_w1 * point.x + _w2 * point.y + _b).abs() /
          math.sqrt(_w1 * _w1 + _w2 * _w2);

      if (dist < threshold) {
        _supportVectors.add(i);
      }
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _w1 = 1.0;
      _w2 = 1.0;
      _b = -1.0;
      _normalizeWeights();
      _isTrained = false;
      _iterations = 0;
      _supportVectors = [];
    });
  }

  double get _accuracy {
    if (_points.isEmpty) return 0;
    int correct = 0;
    for (final point in _points) {
      final prediction = _w1 * point.x + _w2 * point.y + _b;
      if ((prediction > 0 && point.label == 1) ||
          (prediction <= 0 && point.label == -1)) {
        correct++;
      }
    }
    return correct / _points.length * 100;
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
              '머신러닝',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              'SVM 분류기',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '머신러닝',
          title: 'SVM 분류기',
          formula: 'max margin: 2/||w||',
          formulaDescription: '최대 마진을 갖는 결정 경계를 찾는 분류 알고리즘',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _SvmPainter(
                points: _points,
                w1: _w1,
                w2: _w2,
                b: _b,
                supportVectors: _supportVectors,
                isTrained: _isTrained,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 데이터 프리셋
              PresetGroup(
                label: '데이터 분포',
                presets: [
                  PresetButton(
                    label: '선형',
                    isSelected: true,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _generateData('linear'));
                    },
                  ),
                  PresetButton(
                    label: '겹침',
                    isSelected: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _generateData('overlap'));
                    },
                  ),
                  PresetButton(
                    label: '수직',
                    isSelected: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _generateData('vertical'));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 학습 정보
              _TrainingInfo(
                isTrained: _isTrained,
                iterations: _iterations,
                accuracy: _accuracy,
                supportVectorCount: _supportVectors.length,
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: '마진 표시 너비',
                  value: _margin,
                  min: 0.1,
                  max: 0.5,
                  defaultValue: 0.3,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _margin = v),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '학습',
                icon: Icons.school,
                isPrimary: true,
                onPressed: _train,
              ),
              SimButton(
                label: '초기화',
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

class _DataPoint {
  final double x, y;
  final int label; // -1 or 1

  _DataPoint({required this.x, required this.y, required this.label});
}

class _TrainingInfo extends StatelessWidget {
  final bool isTrained;
  final int iterations;
  final double accuracy;
  final int supportVectorCount;

  const _TrainingInfo({
    required this.isTrained,
    required this.iterations,
    required this.accuracy,
    required this.supportVectorCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTrained ? Colors.green.withValues(alpha: 0.5) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          if (isTrained)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    '학습 완료!',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoChip(
                label: '반복',
                value: '$iterations',
                icon: Icons.loop,
                color: AppColors.muted,
              ),
              _InfoChip(
                label: '정확도',
                value: '${accuracy.toStringAsFixed(1)}%',
                icon: Icons.check,
                color: AppColors.accent,
              ),
              _InfoChip(
                label: 'SV 개수',
                value: '$supportVectorCount',
                icon: Icons.star,
                color: AppColors.accent2,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _SvmPainter extends CustomPainter {
  final List<_DataPoint> points;
  final double w1, w2, b;
  final List<int> supportVectors;
  final bool isTrained;

  _SvmPainter({
    required this.points,
    required this.w1,
    required this.w2,
    required this.b,
    required this.supportVectors,
    required this.isTrained,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 20.0;
    final plotWidth = size.width - padding * 2;
    final plotHeight = size.height - padding * 2;

    // 결정 경계 영역 그리기
    if (isTrained) {
      const resolution = 50;
      final cellWidth = plotWidth / resolution;
      final cellHeight = plotHeight / resolution;

      for (int i = 0; i < resolution; i++) {
        for (int j = 0; j < resolution; j++) {
          final x = i / resolution;
          final y = j / resolution;
          final prediction = w1 * x + w2 * y + b;

          final rect = Rect.fromLTWH(
            padding + i * cellWidth,
            padding + (resolution - 1 - j) * cellHeight,
            cellWidth + 1,
            cellHeight + 1,
          );

          Color color;
          if (prediction > 0) {
            color = AppColors.accent.withValues(alpha: 0.1);
          } else {
            color = AppColors.accent2.withValues(alpha: 0.1);
          }

          canvas.drawRect(rect, Paint()..color = color);
        }
      }
    }

    // 결정 경계선 그리기
    final norm = math.sqrt(w1 * w1 + w2 * w2);
    if (norm > 0) {
      // 메인 결정 경계
      _drawLine(canvas, padding, plotWidth, plotHeight, 0, Colors.white);

      // 마진 경계
      if (isTrained) {
        _drawLine(canvas, padding, plotWidth, plotHeight, 1, AppColors.accent.withValues(alpha: 0.5));
        _drawLine(canvas, padding, plotWidth, plotHeight, -1, AppColors.accent2.withValues(alpha: 0.5));
      }
    }

    // 데이터 포인트 그리기
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final px = padding + point.x * plotWidth;
      final py = padding + (1 - point.y) * plotHeight;

      final isSV = supportVectors.contains(i);
      final color = point.label == 1 ? AppColors.accent : AppColors.accent2;

      // 서포트 벡터 하이라이트
      if (isSV) {
        canvas.drawCircle(
          Offset(px, py),
          12,
          Paint()
            ..color = color.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      // 포인트
      canvas.drawCircle(Offset(px, py), isSV ? 8 : 6, Paint()..color = color);
      canvas.drawCircle(
        Offset(px, py),
        isSV ? 8 : 6,
        Paint()
          ..color = isSV ? Colors.white : Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSV ? 2 : 1,
      );
    }
  }

  void _drawLine(Canvas canvas, double padding, double plotWidth,
      double plotHeight, double offset, Color color) {
    // w1*x + w2*y + b = offset
    // y = (-w1*x - b + offset) / w2

    final points = <Offset>[];

    for (double x = 0; x <= 1; x += 0.01) {
      if (w2.abs() > 0.001) {
        final y = (-w1 * x - b + offset) / w2;
        if (y >= 0 && y <= 1) {
          points.add(Offset(
            padding + x * plotWidth,
            padding + (1 - y) * plotHeight,
          ));
        }
      }
    }

    if (points.length >= 2) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final pt in points.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = offset == 0 ? 2 : 1
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SvmPainter oldDelegate) => true;
}
