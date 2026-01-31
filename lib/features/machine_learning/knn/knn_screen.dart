import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// K-최근접 이웃 시뮬레이션
class KnnScreen extends StatefulWidget {
  const KnnScreen({super.key});

  @override
  State<KnnScreen> createState() => _KnnScreenState();
}

class _KnnScreenState extends State<KnnScreen> {
  final _random = math.Random();
  List<_DataPoint> _points = [];
  Offset? _queryPoint;
  int _k = 3;
  int? _predictedClass;
  List<int> _nearestIndices = [];

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  void _generateData() {
    _points = [];

    // 클래스 0 (빨강)
    for (int i = 0; i < 15; i++) {
      _points.add(_DataPoint(
        x: 0.2 + _random.nextDouble() * 0.3,
        y: 0.2 + _random.nextDouble() * 0.3,
        classLabel: 0,
      ));
    }

    // 클래스 1 (파랑)
    for (int i = 0; i < 15; i++) {
      _points.add(_DataPoint(
        x: 0.5 + _random.nextDouble() * 0.3,
        y: 0.5 + _random.nextDouble() * 0.3,
        classLabel: 1,
      ));
    }

    _queryPoint = null;
    _predictedClass = null;
    _nearestIndices = [];
    setState(() {});
  }

  void _setQueryPoint(Offset localPosition, Size size) {
    final padding = 30.0;
    final x = (localPosition.dx - padding) / (size.width - padding * 2);
    final y = 1 - (localPosition.dy - padding) / (size.height - padding * 2);

    if (x >= 0 && x <= 1 && y >= 0 && y <= 1) {
      _queryPoint = Offset(x, y);
      _classify();
      setState(() {});
    }
  }

  void _classify() {
    if (_queryPoint == null) return;

    // 거리 계산
    List<MapEntry<int, double>> distances = [];
    for (int i = 0; i < _points.length; i++) {
      final dx = _points[i].x - _queryPoint!.dx;
      final dy = _points[i].y - _queryPoint!.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      distances.add(MapEntry(i, dist));
    }

    // 정렬
    distances.sort((a, b) => a.value.compareTo(b.value));

    // K개의 최근접 이웃
    _nearestIndices = distances.take(_k).map((e) => e.key).toList();

    // 다수결 투표
    int class0Count = 0;
    int class1Count = 0;
    for (var idx in _nearestIndices) {
      if (_points[idx].classLabel == 0) {
        class0Count++;
      } else {
        class1Count++;
      }
    }

    _predictedClass = class0Count > class1Count ? 0 : 1;
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
              'K-최근접 이웃',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML',
          title: 'K-최근접 이웃 (KNN)',
          formula: 'y = mode(y_i) for i ∈ k-nearest',
          formulaDescription: '가장 가까운 K개의 이웃으로 분류하는 알고리즘',
          simulation: SizedBox(
            height: 300,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    HapticFeedback.lightImpact();
                    _setQueryPoint(details.localPosition, constraints.biggest);
                  },
                  onPanUpdate: (details) {
                    _setQueryPoint(details.localPosition, constraints.biggest);
                  },
                  child: CustomPaint(
                    painter: _KnnPainter(
                      points: _points,
                      queryPoint: _queryPoint,
                      k: _k,
                      predictedClass: _predictedClass,
                      nearestIndices: _nearestIndices,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
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
                    const Text(
                      '화면을 터치하여 분류할 점 선택',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    if (_predictedClass != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('예측: ', style: TextStyle(color: AppColors.ink)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _predictedClass == 0 ? Colors.red : Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '클래스 ${_predictedClass == 0 ? "A" : "B"}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // K 값 선택
              PresetGroup(
                label: 'K 값',
                presets: [1, 3, 5, 7].map((k) {
                  return PresetButton(
                    label: 'K=$k',
                    isSelected: _k == k,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _k = k;
                        if (_queryPoint != null) _classify();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 범례
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('클래스 A', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  const SizedBox(width: 16),
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('클래스 B', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '새 데이터',
                icon: Icons.refresh,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _generateData();
                },
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
  final int classLabel;

  _DataPoint({required this.x, required this.y, required this.classLabel});
}

class _KnnPainter extends CustomPainter {
  final List<_DataPoint> points;
  final Offset? queryPoint;
  final int k;
  final int? predictedClass;
  final List<int> nearestIndices;

  _KnnPainter({
    required this.points,
    required this.queryPoint,
    required this.k,
    required this.predictedClass,
    required this.nearestIndices,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 30.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 그리드
    for (int i = 0; i <= 10; i++) {
      final x = padding + i * graphWidth / 10;
      final y = padding + i * graphHeight / 10;
      canvas.drawLine(
        Offset(x, padding),
        Offset(x, size.height - padding),
        Paint()..color = AppColors.muted.withValues(alpha: 0.1),
      );
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        Paint()..color = AppColors.muted.withValues(alpha: 0.1),
      );
    }

    // 쿼리 포인트와 최근접 이웃 연결선
    if (queryPoint != null) {
      final qx = padding + queryPoint!.dx * graphWidth;
      final qy = size.height - padding - queryPoint!.dy * graphHeight;

      for (var idx in nearestIndices) {
        final px = padding + points[idx].x * graphWidth;
        final py = size.height - padding - points[idx].y * graphHeight;

        canvas.drawLine(
          Offset(qx, qy),
          Offset(px, py),
          Paint()
            ..color = Colors.green.withValues(alpha: 0.5)
            ..strokeWidth = 2,
        );
      }
    }

    // 데이터 포인트
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final px = padding + p.x * graphWidth;
      final py = size.height - padding - p.y * graphHeight;

      final isNearest = nearestIndices.contains(i);
      final color = p.classLabel == 0 ? Colors.red : Colors.blue;

      if (isNearest) {
        canvas.drawCircle(Offset(px, py), 12, Paint()..color = Colors.green.withValues(alpha: 0.3));
      }

      canvas.drawCircle(Offset(px, py), 8, Paint()..color = color);
      canvas.drawCircle(
        Offset(px, py),
        8,
        Paint()
          ..color = isNearest ? Colors.green : Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // 쿼리 포인트
    if (queryPoint != null) {
      final qx = padding + queryPoint!.dx * graphWidth;
      final qy = size.height - padding - queryPoint!.dy * graphHeight;

      canvas.drawCircle(Offset(qx, qy), 12, Paint()..color = AppColors.accent.withValues(alpha: 0.3));
      canvas.drawCircle(Offset(qx, qy), 8, Paint()..color = AppColors.accent);
      canvas.drawCircle(
        Offset(qx, qy),
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // ? 표시
      _drawText(canvas, '?', Offset(qx - 4, qy - 6), Colors.white, fontSize: 12);
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 10}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _KnnPainter oldDelegate) => true;
}
