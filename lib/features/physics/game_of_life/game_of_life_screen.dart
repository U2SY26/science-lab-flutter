import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 콘웨이의 생명 게임 시뮬레이션
class GameOfLifeScreen extends StatefulWidget {
  const GameOfLifeScreen({super.key});

  @override
  State<GameOfLifeScreen> createState() => _GameOfLifeScreenState();
}

class _GameOfLifeScreenState extends State<GameOfLifeScreen> {
  Timer? _timer;

  static const int gridSize = 50;
  late List<List<bool>> grid;
  late List<List<bool>> nextGrid;

  bool isRunning = false;
  int generation = 0;
  double speed = 100;
  int _birthCount = 0;
  int _deathCount = 0;

  // 프리셋
  String? _selectedPattern;

  @override
  void initState() {
    super.initState();
    _initGrid();
  }

  void _initGrid() {
    grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));
    nextGrid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));
  }

  void _randomize() {
    HapticFeedback.mediumImpact();
    final random = math.Random();
    setState(() {
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          grid[i][j] = random.nextDouble() > 0.7;
        }
      }
      generation = 0;
      _birthCount = 0;
      _deathCount = 0;
      _selectedPattern = null;
    });
  }

  void _clear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _initGrid();
      generation = 0;
      _birthCount = 0;
      _deathCount = 0;
      _selectedPattern = null;
    });
  }

  void _update() {
    if (!isRunning) return;

    setState(() {
      int births = 0;
      int deaths = 0;

      // 다음 세대 계산
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          int neighbors = _countNeighbors(i, j);
          if (grid[i][j]) {
            // 살아있는 세포: 2-3개 이웃이면 생존
            nextGrid[i][j] = neighbors == 2 || neighbors == 3;
            if (!nextGrid[i][j]) deaths++;
          } else {
            // 죽은 세포: 정확히 3개 이웃이면 탄생
            nextGrid[i][j] = neighbors == 3;
            if (nextGrid[i][j]) births++;
          }
        }
      }

      // 그리드 교환
      final temp = grid;
      grid = nextGrid;
      nextGrid = temp;
      generation++;
      _birthCount += births;
      _deathCount += deaths;
    });
  }

  int _countNeighbors(int x, int y) {
    int count = 0;
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        int nx = (x + i + gridSize) % gridSize;
        int ny = (y + j + gridSize) % gridSize;
        if (grid[nx][ny]) count++;
      }
    }
    return count;
  }

  void _toggleCell(int x, int y) {
    if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
      HapticFeedback.lightImpact();
      setState(() {
        grid[x][y] = !grid[x][y];
      });
    }
  }

  void _toggleRunning() {
    HapticFeedback.selectionClick();
    setState(() {
      isRunning = !isRunning;
      if (isRunning) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: speed.toInt()), (_) {
      _update();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _applyPattern(String pattern) {
    HapticFeedback.selectionClick();
    setState(() {
      _clear();
      _selectedPattern = pattern;
      final centerX = gridSize ~/ 2;
      final centerY = gridSize ~/ 2;

      List<List<int>> cells;

      switch (pattern) {
        case 'glider':
          cells = [
            [0, 1], [1, 2], [2, 0], [2, 1], [2, 2]
          ];
          break;
        case 'lwss': // Lightweight Spaceship
          cells = [
            [0, 1], [0, 4], [1, 0], [2, 0], [2, 4], [3, 0], [3, 1], [3, 2], [3, 3]
          ];
          break;
        case 'pulsar':
          cells = [];
          // Pulsar 패턴
          final offsets = [
            [-6, -4], [-6, -3], [-6, -2], [-6, 2], [-6, 3], [-6, 4],
            [-4, -6], [-3, -6], [-2, -6], [-4, -1], [-3, -1], [-2, -1],
            [-4, 1], [-3, 1], [-2, 1], [-4, 6], [-3, 6], [-2, 6],
            [-1, -4], [-1, -3], [-1, -2], [-1, 2], [-1, 3], [-1, 4],
            [1, -4], [1, -3], [1, -2], [1, 2], [1, 3], [1, 4],
            [2, -6], [3, -6], [4, -6], [2, -1], [3, -1], [4, -1],
            [2, 1], [3, 1], [4, 1], [2, 6], [3, 6], [4, 6],
            [6, -4], [6, -3], [6, -2], [6, 2], [6, 3], [6, 4],
          ];
          for (var o in offsets) {
            cells.add([o[0], o[1]]);
          }
          break;
        case 'gosper_gun':
          cells = [
            // Left square
            [0, 4], [0, 5], [1, 4], [1, 5],
            // Left part
            [10, 4], [10, 5], [10, 6], [11, 3], [11, 7], [12, 2], [12, 8],
            [13, 2], [13, 8], [14, 5], [15, 3], [15, 7], [16, 4], [16, 5], [16, 6],
            [17, 5],
            // Right part
            [20, 2], [20, 3], [20, 4], [21, 2], [21, 3], [21, 4], [22, 1], [22, 5],
            [24, 0], [24, 1], [24, 5], [24, 6],
            // Right square
            [34, 2], [34, 3], [35, 2], [35, 3],
          ];
          break;
        default:
          cells = [[0, 1], [1, 2], [2, 0], [2, 1], [2, 2]]; // Default glider
      }

      for (var cell in cells) {
        int x = (centerX + cell[0]) % gridSize;
        int y = (centerY + cell[1]) % gridSize;
        grid[x][y] = true;
      }
    });
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveCells = _countLiveCells();

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
              '셀룰러 오토마타',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '콘웨이의 생명 게임',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '셀룰러 오토마타',
          title: '콘웨이의 생명 게임',
          formula: '탄생: 3이웃 | 생존: 2-3이웃 | 사망: 그 외',
          formulaDescription: '간단한 규칙에서 복잡한 패턴이 창발하는 생명 시뮬레이션',
          simulation: GestureDetector(
            onTapDown: (details) {
              final cellSize = 350 / gridSize;
              final x = (details.localPosition.dy / cellSize).floor();
              final y = (details.localPosition.dx / cellSize).floor();
              _toggleCell(x, y);
            },
            child: SizedBox(
              height: 350,
              child: CustomPaint(
                painter: GameOfLifePainter(
                  grid: grid,
                  gridSize: gridSize,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 패턴 프리셋
              PresetGroup(
                label: '패턴 선택',
                presets: [
                  PresetButton(
                    label: '글라이더',
                    isSelected: _selectedPattern == 'glider',
                    onPressed: () => _applyPattern('glider'),
                  ),
                  PresetButton(
                    label: '우주선',
                    isSelected: _selectedPattern == 'lwss',
                    onPressed: () => _applyPattern('lwss'),
                  ),
                  PresetButton(
                    label: '펄서',
                    isSelected: _selectedPattern == 'pulsar',
                    onPressed: () => _applyPattern('pulsar'),
                  ),
                  PresetButton(
                    label: '글라이더 건',
                    isSelected: _selectedPattern == 'gosper_gun',
                    onPressed: () => _applyPattern('gosper_gun'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 통계
              _StatsDisplay(
                generation: generation,
                liveCells: liveCells,
                births: _birthCount,
                deaths: _deathCount,
              ),
              const SizedBox(height: 16),
              // 속도 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '시뮬레이션 속도',
                  value: speed,
                  min: 50,
                  max: 500,
                  defaultValue: 100,
                  formatValue: (v) => '${v.toInt()} ms',
                  onChanged: (v) {
                    setState(() => speed = v);
                    if (isRunning) {
                      _startTimer(); // Restart timer with new speed
                    }
                  },
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning ? '정지' : '시작',
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleRunning,
              ),
              SimButton(
                label: '랜덤',
                icon: Icons.shuffle,
                onPressed: _randomize,
              ),
              SimButton(
                label: '클리어',
                icon: Icons.delete_outline,
                onPressed: _clear,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _countLiveCells() {
    int count = 0;
    for (var row in grid) {
      for (var cell in row) {
        if (cell) count++;
      }
    }
    return count;
  }
}

/// 통계 표시 위젯
class _StatsDisplay extends StatelessWidget {
  final int generation;
  final int liveCells;
  final int births;
  final int deaths;

  const _StatsDisplay({
    required this.generation,
    required this.liveCells,
    required this.births,
    required this.deaths,
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
      child: Row(
        children: [
          _StatItem(label: '세대', value: '$generation', color: AppColors.accent),
          _StatItem(label: '생존', value: '$liveCells', color: AppColors.accent),
          _StatItem(label: '탄생', value: '$births', color: AppColors.accent2),
          _StatItem(label: '사망', value: '$deaths', color: AppColors.muted),
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
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class GameOfLifePainter extends CustomPainter {
  final List<List<bool>> grid;
  final int gridSize;

  GameOfLifePainter({required this.grid, required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / gridSize;

    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    // 그리드 라인
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= gridSize; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
    }

    // 살아있는 세포
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j]) {
          // 글로우 효과
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                j * cellSize,
                i * cellSize,
                cellSize,
                cellSize,
              ),
              const Radius.circular(2),
            ),
            Paint()..color = AppColors.accent.withValues(alpha: 0.3),
          );

          // 셀
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                j * cellSize + 1,
                i * cellSize + 1,
                cellSize - 2,
                cellSize - 2,
              ),
              const Radius.circular(2),
            ),
            Paint()..color = AppColors.accent,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant GameOfLifePainter oldDelegate) => true;
}
