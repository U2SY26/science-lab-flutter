import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 결정 트리 시각화 화면
class DecisionTreeScreen extends StatefulWidget {
  const DecisionTreeScreen({super.key});

  @override
  State<DecisionTreeScreen> createState() => _DecisionTreeScreenState();
}

class _DecisionTreeScreenState extends State<DecisionTreeScreen> {
  // 2D 데이터 포인트 (x, y, class)
  List<_DataPoint> _points = [];

  // 트리 구조
  _TreeNode? _root;
  int _maxDepth = 3;
  int _minSamples = 2;

  // 시각화 상태
  bool _showDecisionBoundary = true;

  @override
  void initState() {
    super.initState();
    _generateData('blobs');
  }

  void _generateData(String preset) {
    final rand = math.Random(42);
    _points = [];

    switch (preset) {
      case 'blobs':
        // 2개 클래스 군집
        for (int i = 0; i < 30; i++) {
          _points.add(_DataPoint(
            x: 0.2 + rand.nextDouble() * 0.3,
            y: 0.2 + rand.nextDouble() * 0.3,
            label: 0,
          ));
          _points.add(_DataPoint(
            x: 0.5 + rand.nextDouble() * 0.3,
            y: 0.5 + rand.nextDouble() * 0.3,
            label: 1,
          ));
        }
        break;
      case 'xor':
        // XOR 패턴
        for (int i = 0; i < 20; i++) {
          _points.add(_DataPoint(
            x: 0.1 + rand.nextDouble() * 0.3,
            y: 0.1 + rand.nextDouble() * 0.3,
            label: 0,
          ));
          _points.add(_DataPoint(
            x: 0.6 + rand.nextDouble() * 0.3,
            y: 0.6 + rand.nextDouble() * 0.3,
            label: 0,
          ));
          _points.add(_DataPoint(
            x: 0.1 + rand.nextDouble() * 0.3,
            y: 0.6 + rand.nextDouble() * 0.3,
            label: 1,
          ));
          _points.add(_DataPoint(
            x: 0.6 + rand.nextDouble() * 0.3,
            y: 0.1 + rand.nextDouble() * 0.3,
            label: 1,
          ));
        }
        break;
      case 'linear':
        // 선형 분리 가능
        for (int i = 0; i < 40; i++) {
          final x = rand.nextDouble();
          final y = rand.nextDouble();
          _points.add(_DataPoint(
            x: x,
            y: y,
            label: x + y > 1.0 ? 1 : 0,
          ));
        }
        break;
      case 'circles':
        // 동심원
        for (int i = 0; i < 40; i++) {
          final angle = rand.nextDouble() * 2 * math.pi;
          final r1 = 0.15 + rand.nextDouble() * 0.1;
          final r2 = 0.35 + rand.nextDouble() * 0.1;
          _points.add(_DataPoint(
            x: 0.5 + r1 * math.cos(angle),
            y: 0.5 + r1 * math.sin(angle),
            label: 0,
          ));
          _points.add(_DataPoint(
            x: 0.5 + r2 * math.cos(angle),
            y: 0.5 + r2 * math.sin(angle),
            label: 1,
          ));
        }
        break;
    }

    _buildTree();
  }

  void _buildTree() {
    HapticFeedback.lightImpact();
    setState(() {
      _root = _buildNode(_points, 0);
    });
  }

  _TreeNode _buildNode(List<_DataPoint> data, int depth) {
    // 종료 조건
    if (depth >= _maxDepth || data.length < _minSamples) {
      return _TreeNode.leaf(_majorityClass(data), data.length);
    }

    // 모든 점이 같은 클래스
    final classes = data.map((p) => p.label).toSet();
    if (classes.length == 1) {
      return _TreeNode.leaf(classes.first, data.length);
    }

    // 최적 분할 찾기
    double bestGini = double.infinity;
    double bestThreshold = 0;
    bool bestIsX = true;

    for (final isX in [true, false]) {
      final values = data.map((p) => isX ? p.x : p.y).toList()..sort();

      for (int i = 0; i < values.length - 1; i++) {
        final threshold = (values[i] + values[i + 1]) / 2;
        final left = data.where((p) => (isX ? p.x : p.y) <= threshold).toList();
        final right = data.where((p) => (isX ? p.x : p.y) > threshold).toList();

        if (left.isEmpty || right.isEmpty) continue;

        final gini = _weightedGini(left, right);
        if (gini < bestGini) {
          bestGini = gini;
          bestThreshold = threshold;
          bestIsX = isX;
        }
      }
    }

    if (bestGini == double.infinity) {
      return _TreeNode.leaf(_majorityClass(data), data.length);
    }

    final left = data.where((p) => (bestIsX ? p.x : p.y) <= bestThreshold).toList();
    final right = data.where((p) => (bestIsX ? p.x : p.y) > bestThreshold).toList();

    return _TreeNode(
      isX: bestIsX,
      threshold: bestThreshold,
      gini: bestGini,
      samples: data.length,
      left: _buildNode(left, depth + 1),
      right: _buildNode(right, depth + 1),
    );
  }

  int _majorityClass(List<_DataPoint> data) {
    if (data.isEmpty) return 0;
    final count0 = data.where((p) => p.label == 0).length;
    final count1 = data.length - count0;
    return count0 >= count1 ? 0 : 1;
  }

  double _giniImpurity(List<_DataPoint> data) {
    if (data.isEmpty) return 0;
    final p = data.where((p) => p.label == 0).length / data.length;
    return 1 - p * p - (1 - p) * (1 - p);
  }

  double _weightedGini(List<_DataPoint> left, List<_DataPoint> right) {
    final total = left.length + right.length;
    return (left.length / total) * _giniImpurity(left) +
           (right.length / total) * _giniImpurity(right);
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _root = null;
    });
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
              '결정 트리',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '머신러닝',
          title: '결정 트리',
          formula: 'Gini = 1 - Σpᵢ²',
          formulaDescription: '지니 불순도를 최소화하며 데이터를 분할하는 분류 알고리즘',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _DecisionTreePainter(
                points: _points,
                root: _root,
                showBoundary: _showDecisionBoundary,
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
                    label: '군집',
                    isSelected: true,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _generateData('blobs'));
                    },
                  ),
                  PresetButton(
                    label: 'XOR',
                    isSelected: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _generateData('xor'));
                    },
                  ),
                  PresetButton(
                    label: '선형',
                    isSelected: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _generateData('linear'));
                    },
                  ),
                  PresetButton(
                    label: '원형',
                    isSelected: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _generateData('circles'));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 트리 정보
              if (_root != null) _TreeInfo(root: _root!),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: '최대 깊이',
                  value: _maxDepth.toDouble(),
                  min: 1,
                  max: 6,
                  defaultValue: 3,
                  formatValue: (v) => v.toInt().toString(),
                  onChanged: (v) {
                    setState(() {
                      _maxDepth = v.toInt();
                      _buildTree();
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              // 결정 경계 토글
              Row(
                children: [
                  Switch(
                    value: _showDecisionBoundary,
                    onChanged: (v) => setState(() => _showDecisionBoundary = v),
                    activeColor: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '결정 경계 표시',
                    style: TextStyle(color: AppColors.ink, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '트리 학습',
                icon: Icons.account_tree,
                isPrimary: true,
                onPressed: _buildTree,
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
  final int label;

  _DataPoint({required this.x, required this.y, required this.label});
}

class _TreeNode {
  final bool isLeaf;
  final bool isX;
  final double threshold;
  final double gini;
  final int samples;
  final int? predictedClass;
  final _TreeNode? left;
  final _TreeNode? right;

  _TreeNode({
    this.isLeaf = false,
    required this.isX,
    required this.threshold,
    required this.gini,
    required this.samples,
    this.predictedClass,
    this.left,
    this.right,
  });

  factory _TreeNode.leaf(int predictedClass, int samples) {
    return _TreeNode(
      isLeaf: true,
      isX: true,
      threshold: 0,
      gini: 0,
      samples: samples,
      predictedClass: predictedClass,
    );
  }

  int predict(double x, double y) {
    if (isLeaf) return predictedClass ?? 0;
    final value = isX ? x : y;
    if (value <= threshold) {
      return left?.predict(x, y) ?? 0;
    } else {
      return right?.predict(x, y) ?? 0;
    }
  }

  int get depth {
    if (isLeaf) return 0;
    final leftDepth = left?.depth ?? 0;
    final rightDepth = right?.depth ?? 0;
    return 1 + math.max(leftDepth, rightDepth);
  }

  int get nodeCount {
    if (isLeaf) return 1;
    return 1 + (left?.nodeCount ?? 0) + (right?.nodeCount ?? 0);
  }
}

class _TreeInfo extends StatelessWidget {
  final _TreeNode root;

  const _TreeInfo({required this.root});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _InfoChip(
            label: '깊이',
            value: '${root.depth}',
            icon: Icons.height,
            color: AppColors.accent,
          ),
          _InfoChip(
            label: '노드 수',
            value: '${root.nodeCount}',
            icon: Icons.account_tree,
            color: AppColors.accent2,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionTreePainter extends CustomPainter {
  final List<_DataPoint> points;
  final _TreeNode? root;
  final bool showBoundary;

  _DecisionTreePainter({
    required this.points,
    this.root,
    this.showBoundary = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 20.0;
    final plotWidth = size.width - padding * 2;
    final plotHeight = size.height - padding * 2;

    // 결정 경계 그리기
    if (showBoundary && root != null) {
      const resolution = 50;
      final cellWidth = plotWidth / resolution;
      final cellHeight = plotHeight / resolution;

      for (int i = 0; i < resolution; i++) {
        for (int j = 0; j < resolution; j++) {
          final x = i / resolution;
          final y = j / resolution;
          final prediction = root!.predict(x, y);

          final rect = Rect.fromLTWH(
            padding + i * cellWidth,
            padding + (resolution - 1 - j) * cellHeight,
            cellWidth + 1,
            cellHeight + 1,
          );

          canvas.drawRect(
            rect,
            Paint()
              ..color = prediction == 0
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.accent2.withValues(alpha: 0.15),
          );
        }
      }
    }

    // 분할선 그리기
    if (root != null) {
      _drawSplits(canvas, root!, padding, padding, plotWidth, plotHeight);
    }

    // 데이터 포인트 그리기
    for (final point in points) {
      final px = padding + point.x * plotWidth;
      final py = padding + (1 - point.y) * plotHeight;

      final color = point.label == 0 ? AppColors.accent : AppColors.accent2;

      canvas.drawCircle(
        Offset(px, py),
        6,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(px, py),
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawSplits(Canvas canvas, _TreeNode node, double left, double top,
      double width, double height) {
    if (node.isLeaf) return;

    final paint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (node.isX) {
      final x = left + node.threshold * width;
      canvas.drawLine(Offset(x, top), Offset(x, top + height), paint);

      if (node.left != null) {
        _drawSplits(canvas, node.left!, left, top, node.threshold * width, height);
      }
      if (node.right != null) {
        _drawSplits(canvas, node.right!, x, top, (1 - node.threshold) * width, height);
      }
    } else {
      final y = top + (1 - node.threshold) * height;
      canvas.drawLine(Offset(left, y), Offset(left + width, y), paint);

      if (node.left != null) {
        _drawSplits(canvas, node.left!, left, y, width, node.threshold * height);
      }
      if (node.right != null) {
        _drawSplits(canvas, node.right!, left, top, width, (1 - node.threshold) * height);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DecisionTreePainter oldDelegate) => true;
}
