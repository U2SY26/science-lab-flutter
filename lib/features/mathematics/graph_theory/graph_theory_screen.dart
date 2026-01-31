import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 그래프 이론 시각화 화면
class GraphTheoryScreen extends StatefulWidget {
  const GraphTheoryScreen({super.key});

  @override
  State<GraphTheoryScreen> createState() => _GraphTheoryScreenState();
}

class _GraphTheoryScreenState extends State<GraphTheoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 그래프 데이터
  List<_Node> _nodes = [];
  List<_Edge> _edges = [];

  // BFS/DFS 상태
  List<int> _visitOrder = [];
  int _currentStep = 0;
  bool _isRunning = false;
  String _algorithm = 'bfs';

  // 프리셋
  String _selectedPreset = 'tree';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadPreset('tree');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadPreset(String preset) {
    _selectedPreset = preset;
    _nodes = [];
    _edges = [];
    _visitOrder = [];
    _currentStep = 0;
    _isRunning = false;

    switch (preset) {
      case 'tree':
        // 이진 트리
        _nodes = [
          _Node(x: 0.5, y: 0.15, label: '0'),
          _Node(x: 0.3, y: 0.35, label: '1'),
          _Node(x: 0.7, y: 0.35, label: '2'),
          _Node(x: 0.15, y: 0.55, label: '3'),
          _Node(x: 0.4, y: 0.55, label: '4'),
          _Node(x: 0.6, y: 0.55, label: '5'),
          _Node(x: 0.85, y: 0.55, label: '6'),
          _Node(x: 0.25, y: 0.75, label: '7'),
          _Node(x: 0.5, y: 0.75, label: '8'),
          _Node(x: 0.75, y: 0.75, label: '9'),
        ];
        _edges = [
          _Edge(from: 0, to: 1),
          _Edge(from: 0, to: 2),
          _Edge(from: 1, to: 3),
          _Edge(from: 1, to: 4),
          _Edge(from: 2, to: 5),
          _Edge(from: 2, to: 6),
          _Edge(from: 4, to: 7),
          _Edge(from: 4, to: 8),
          _Edge(from: 5, to: 9),
        ];
        break;
      case 'graph':
        // 일반 그래프
        _nodes = [
          _Node(x: 0.5, y: 0.2, label: '0'),
          _Node(x: 0.25, y: 0.4, label: '1'),
          _Node(x: 0.75, y: 0.4, label: '2'),
          _Node(x: 0.15, y: 0.65, label: '3'),
          _Node(x: 0.5, y: 0.55, label: '4'),
          _Node(x: 0.85, y: 0.65, label: '5'),
          _Node(x: 0.35, y: 0.8, label: '6'),
          _Node(x: 0.65, y: 0.8, label: '7'),
        ];
        _edges = [
          _Edge(from: 0, to: 1),
          _Edge(from: 0, to: 2),
          _Edge(from: 1, to: 3),
          _Edge(from: 1, to: 4),
          _Edge(from: 2, to: 4),
          _Edge(from: 2, to: 5),
          _Edge(from: 3, to: 6),
          _Edge(from: 4, to: 6),
          _Edge(from: 4, to: 7),
          _Edge(from: 5, to: 7),
        ];
        break;
      case 'cycle':
        // 순환 그래프
        const n = 8;
        for (int i = 0; i < n; i++) {
          final angle = -math.pi / 2 + i * 2 * math.pi / n;
          _nodes.add(_Node(
            x: 0.5 + 0.3 * math.cos(angle),
            y: 0.5 + 0.3 * math.sin(angle),
            label: '$i',
          ));
          _edges.add(_Edge(from: i, to: (i + 1) % n));
        }
        // 대각선 연결
        _edges.add(_Edge(from: 0, to: 4));
        _edges.add(_Edge(from: 2, to: 6));
        break;
      case 'complete':
        // 완전 그래프 K5
        const n = 5;
        for (int i = 0; i < n; i++) {
          final angle = -math.pi / 2 + i * 2 * math.pi / n;
          _nodes.add(_Node(
            x: 0.5 + 0.3 * math.cos(angle),
            y: 0.5 + 0.3 * math.sin(angle),
            label: '$i',
          ));
        }
        for (int i = 0; i < n; i++) {
          for (int j = i + 1; j < n; j++) {
            _edges.add(_Edge(from: i, to: j));
          }
        }
        break;
    }

    setState(() {});
  }

  void _runAlgorithm() {
    if (_isRunning) return;
    HapticFeedback.lightImpact();

    _visitOrder = [];
    _currentStep = 0;

    if (_algorithm == 'bfs') {
      _bfs();
    } else {
      _dfs();
    }

    setState(() {
      _isRunning = true;
    });

    _animateTraversal();
  }

  void _bfs() {
    final visited = List.filled(_nodes.length, false);
    final queue = <int>[0];
    visited[0] = true;

    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      _visitOrder.add(node);

      for (final edge in _edges) {
        int neighbor = -1;
        if (edge.from == node && !visited[edge.to]) {
          neighbor = edge.to;
        } else if (edge.to == node && !visited[edge.from]) {
          neighbor = edge.from;
        }

        if (neighbor != -1) {
          visited[neighbor] = true;
          queue.add(neighbor);
        }
      }
    }
  }

  void _dfs() {
    final visited = List.filled(_nodes.length, false);
    _dfsRecursive(0, visited);
  }

  void _dfsRecursive(int node, List<bool> visited) {
    visited[node] = true;
    _visitOrder.add(node);

    for (final edge in _edges) {
      int neighbor = -1;
      if (edge.from == node && !visited[edge.to]) {
        neighbor = edge.to;
      } else if (edge.to == node && !visited[edge.from]) {
        neighbor = edge.from;
      }

      if (neighbor != -1) {
        _dfsRecursive(neighbor, visited);
      }
    }
  }

  void _animateTraversal() async {
    for (int i = 0; i <= _visitOrder.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _currentStep = i;
      });
      HapticFeedback.selectionClick();
    }
    setState(() {
      _isRunning = false;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _visitOrder = [];
      _currentStep = 0;
      _isRunning = false;
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
              '수학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '그래프 탐색',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '그래프 탐색',
          formula: 'G = (V, E)',
          formulaDescription: 'BFS와 DFS로 그래프를 탐색하는 과정을 시각화합니다',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _GraphPainter(
                nodes: _nodes,
                edges: _edges,
                visitOrder: _visitOrder,
                currentStep: _currentStep,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 그래프 프리셋
              PresetGroup(
                label: '그래프 유형',
                presets: [
                  PresetButton(
                    label: '트리',
                    isSelected: _selectedPreset == 'tree',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _loadPreset('tree');
                    },
                  ),
                  PresetButton(
                    label: '일반',
                    isSelected: _selectedPreset == 'graph',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _loadPreset('graph');
                    },
                  ),
                  PresetButton(
                    label: '순환',
                    isSelected: _selectedPreset == 'cycle',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _loadPreset('cycle');
                    },
                  ),
                  PresetButton(
                    label: '완전 K5',
                    isSelected: _selectedPreset == 'complete',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _loadPreset('complete');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 알고리즘 선택
              PresetGroup(
                label: '탐색 알고리즘',
                presets: [
                  PresetButton(
                    label: 'BFS (너비)',
                    isSelected: _algorithm == 'bfs',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _algorithm = 'bfs');
                    },
                  ),
                  PresetButton(
                    label: 'DFS (깊이)',
                    isSelected: _algorithm == 'dfs',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _algorithm = 'dfs');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 탐색 순서
              _TraversalInfo(
                visitOrder: _visitOrder,
                currentStep: _currentStep,
                isRunning: _isRunning,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '탐색 시작',
                icon: Icons.play_arrow,
                isPrimary: true,
                onPressed: _isRunning ? null : _runAlgorithm,
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

class _Node {
  final double x, y;
  final String label;

  _Node({required this.x, required this.y, required this.label});
}

class _Edge {
  final int from, to;

  _Edge({required this.from, required this.to});
}

class _TraversalInfo extends StatelessWidget {
  final List<int> visitOrder;
  final int currentStep;
  final bool isRunning;

  const _TraversalInfo({
    required this.visitOrder,
    required this.currentStep,
    required this.isRunning,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRunning ? Icons.directions_run : Icons.route,
                size: 14,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                '탐색 순서',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (visitOrder.isNotEmpty)
                Text(
                  '$currentStep / ${visitOrder.length}',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (visitOrder.isEmpty)
            Text(
              '탐색 시작 버튼을 누르세요',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(visitOrder.length, (i) {
                final isVisited = i < currentStep;
                final isCurrent = i == currentStep - 1;

                return Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.accent
                        : isVisited
                            ? AppColors.accent.withValues(alpha: 0.3)
                            : AppColors.card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isVisited ? AppColors.accent : AppColors.cardBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${visitOrder[i]}',
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.black
                            : isVisited
                                ? AppColors.accent
                                : AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<_Node> nodes;
  final List<_Edge> edges;
  final List<int> visitOrder;
  final int currentStep;

  _GraphPainter({
    required this.nodes,
    required this.edges,
    required this.visitOrder,
    required this.currentStep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (nodes.isEmpty) return;

    final visitedSet = visitOrder.take(currentStep).toSet();

    // 간선 그리기
    for (final edge in edges) {
      final from = nodes[edge.from];
      final to = nodes[edge.to];

      final fromPos = Offset(from.x * size.width, from.y * size.height);
      final toPos = Offset(to.x * size.width, to.y * size.height);

      final isVisited = visitedSet.contains(edge.from) && visitedSet.contains(edge.to);

      canvas.drawLine(
        fromPos,
        toPos,
        Paint()
          ..color = isVisited
              ? AppColors.accent.withValues(alpha: 0.8)
              : AppColors.muted.withValues(alpha: 0.3)
          ..strokeWidth = isVisited ? 3 : 2,
      );
    }

    // 노드 그리기
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final pos = Offset(node.x * size.width, node.y * size.height);

      final visitIndex = visitOrder.indexOf(i);
      final isVisited = visitIndex >= 0 && visitIndex < currentStep;
      final isCurrent = visitIndex == currentStep - 1;

      // 글로우
      if (isCurrent) {
        canvas.drawCircle(
          pos,
          30,
          Paint()
            ..color = AppColors.accent.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }

      // 노드 본체
      canvas.drawCircle(
        pos,
        20,
        Paint()
          ..color = isCurrent
              ? AppColors.accent
              : isVisited
                  ? AppColors.accent.withValues(alpha: 0.7)
                  : AppColors.card,
      );

      // 테두리
      canvas.drawCircle(
        pos,
        20,
        Paint()
          ..color = isVisited ? AppColors.accent : AppColors.muted.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // 레이블
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.label,
          style: TextStyle(
            color: isCurrent
                ? Colors.black
                : isVisited
                    ? Colors.white
                    : AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) => true;
}
