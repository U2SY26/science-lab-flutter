import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// A* 경로 탐색 시뮬레이션
class AstarScreen extends StatefulWidget {
  const AstarScreen({super.key});

  @override
  State<AstarScreen> createState() => _AstarScreenState();
}

class _AstarScreenState extends State<AstarScreen> {
  static const int gridSize = 15;
  late List<List<int>> _grid; // 0: 빈칸, 1: 벽, 2: 시작, 3: 목표, 4: 방문, 5: 경로
  Point _start = const Point(1, 1);
  Point _goal = const Point(13, 13);
  bool _isSearching = false;
  List<Point> _path = [];
  Set<Point> _visited = {};
  Set<Point> _frontier = {};
  int _nodesExplored = 0;

  @override
  void initState() {
    super.initState();
    _initGrid();
  }

  void _initGrid() {
    _grid = List.generate(gridSize, (y) => List.generate(gridSize, (x) => 0));

    // 랜덤 벽 생성
    final random = math.Random();
    for (int i = 0; i < gridSize * gridSize ~/ 4; i++) {
      final x = random.nextInt(gridSize);
      final y = random.nextInt(gridSize);
      if ((x != _start.x || y != _start.y) && (x != _goal.x || y != _goal.y)) {
        _grid[y][x] = 1;
      }
    }

    _path = [];
    _visited = {};
    _frontier = {};
    _nodesExplored = 0;
  }

  double _heuristic(Point a, Point b) {
    // 맨해튼 거리
    return (a.x - b.x).abs() + (a.y - b.y).abs().toDouble();
  }

  List<Point> _getNeighbors(Point p) {
    final neighbors = <Point>[];
    final dirs = [const Point(0, -1), const Point(1, 0), const Point(0, 1), const Point(-1, 0)];

    for (var d in dirs) {
      final nx = p.x + d.x;
      final ny = p.y + d.y;
      if (nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize && _grid[ny][nx] != 1) {
        neighbors.add(Point(nx, ny));
      }
    }
    return neighbors;
  }

  void _startSearch() async {
    _isSearching = true;
    _path = [];
    _visited = {};
    _frontier = {};
    _nodesExplored = 0;
    setState(() {});

    // A* 알고리즘
    final openSet = <_Node>[];
    final cameFrom = <Point, Point>{};
    final gScore = <Point, double>{};
    final fScore = <Point, double>{};

    gScore[_start] = 0;
    fScore[_start] = _heuristic(_start, _goal);
    openSet.add(_Node(_start, fScore[_start]!));
    _frontier.add(_start);

    while (openSet.isNotEmpty && _isSearching) {
      openSet.sort((a, b) => a.f.compareTo(b.f));
      final current = openSet.removeAt(0);
      _frontier.remove(current.point);
      _visited.add(current.point);
      _nodesExplored++;

      if (current.point == _goal) {
        // 경로 재구성
        _path = [_goal];
        var curr = _goal;
        while (cameFrom.containsKey(curr)) {
          curr = cameFrom[curr]!;
          _path.insert(0, curr);
        }
        break;
      }

      for (var neighbor in _getNeighbors(current.point)) {
        final tentativeG = (gScore[current.point] ?? double.infinity) + 1;

        if (tentativeG < (gScore[neighbor] ?? double.infinity)) {
          cameFrom[neighbor] = current.point;
          gScore[neighbor] = tentativeG;
          fScore[neighbor] = tentativeG + _heuristic(neighbor, _goal);

          if (!_visited.contains(neighbor)) {
            openSet.add(_Node(neighbor, fScore[neighbor]!));
            _frontier.add(neighbor);
          }
        }
      }

      setState(() {});
      await Future.delayed(const Duration(milliseconds: 30));
    }

    _isSearching = false;
    setState(() {});
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _isSearching = false;
    _initGrid();
    setState(() {});
  }

  void _toggleCell(int x, int y) {
    if ((x == _start.x && y == _start.y) || (x == _goal.x && y == _goal.y)) return;
    if (_isSearching) return;

    setState(() {
      _grid[y][x] = _grid[y][x] == 1 ? 0 : 1;
      _path = [];
      _visited = {};
      _frontier = {};
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
              'AI/ML',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              'A* 경로 탐색',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML',
          title: 'A* 경로 탐색',
          formula: 'f(n) = g(n) + h(n)',
          formulaDescription: '휴리스틱을 사용한 최적 경로 탐색 알고리즘',
          simulation: SizedBox(
            height: 320,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellSize = constraints.maxWidth / gridSize;
                    return GestureDetector(
                      onTapUp: (details) {
                        final x = (details.localPosition.dx / cellSize).floor();
                        final y = (details.localPosition.dy / cellSize).floor();
                        if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
                          _toggleCell(x, y);
                        }
                      },
                      child: CustomPaint(
                        painter: _AstarPainter(
                          grid: _grid,
                          start: _start,
                          goal: _goal,
                          path: _path,
                          visited: _visited,
                          frontier: _frontier,
                        ),
                        size: Size(constraints.maxWidth, constraints.maxWidth),
                      ),
                    );
                  },
                ),
              ),
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
                        _InfoItem(label: '탐색 노드', value: '$_nodesExplored', color: Colors.orange),
                        _InfoItem(label: '경로 길이', value: _path.isEmpty ? '-' : '${_path.length}', color: AppColors.accent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '벽을 터치하여 추가/제거',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 범례
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _LegendItem(color: Colors.green, label: '시작'),
                  _LegendItem(color: Colors.red, label: '목표'),
                  _LegendItem(color: Colors.grey.shade700, label: '벽'),
                  _LegendItem(color: Colors.blue.withValues(alpha: 0.3), label: '방문'),
                  _LegendItem(color: Colors.yellow, label: '경로'),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isSearching ? '탐색 중...' : '경로 찾기',
                icon: Icons.search,
                isPrimary: true,
                onPressed: _isSearching ? null : () {
                  HapticFeedback.selectionClick();
                  _startSearch();
                },
              ),
              SimButton(
                label: '새 미로',
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

class Point {
  final int x, y;
  const Point(this.x, this.y);

  @override
  bool operator ==(Object other) => other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class _Node {
  final Point point;
  final double f;
  _Node(this.point, this.f);
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
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
      ],
    );
  }
}

class _AstarPainter extends CustomPainter {
  final List<List<int>> grid;
  final Point start;
  final Point goal;
  final List<Point> path;
  final Set<Point> visited;
  final Set<Point> frontier;

  _AstarPainter({
    required this.grid,
    required this.start,
    required this.goal,
    required this.path,
    required this.visited,
    required this.frontier,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / grid.length;

    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < grid[y].length; x++) {
        final rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);
        Color color = AppColors.card;

        if (grid[y][x] == 1) {
          color = Colors.grey.shade700;
        } else if (Point(x, y) == start) {
          color = Colors.green;
        } else if (Point(x, y) == goal) {
          color = Colors.red;
        } else if (path.contains(Point(x, y))) {
          color = Colors.yellow;
        } else if (frontier.contains(Point(x, y))) {
          color = Colors.green.withValues(alpha: 0.3);
        } else if (visited.contains(Point(x, y))) {
          color = Colors.blue.withValues(alpha: 0.3);
        }

        canvas.drawRect(rect, Paint()..color = color);
        canvas.drawRect(
          rect,
          Paint()
            ..color = AppColors.cardBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AstarPainter oldDelegate) => true;
}
