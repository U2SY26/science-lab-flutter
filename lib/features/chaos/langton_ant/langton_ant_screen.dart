import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Langton's Ant Simulation
class LangtonAntScreen extends ConsumerStatefulWidget {
  const LangtonAntScreen({super.key});

  @override
  ConsumerState<LangtonAntScreen> createState() => _LangtonAntScreenState();
}

class _LangtonAntScreenState extends ConsumerState<LangtonAntScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Grid parameters
  static const int _gridSize = 101;
  late List<List<bool>> _grid;

  // Ant state
  int _antX = _gridSize ~/ 2;
  int _antY = _gridSize ~/ 2;
  int _direction = 0; // 0=up, 1=right, 2=down, 3=left

  // Simulation state
  int _step = 0;
  bool _isRunning = false;
  int _stepsPerFrame = 1;

  // Directions: up, right, down, left
  static const List<List<int>> _directions = [
    [0, -1], // up
    [1, 0],  // right
    [0, 1],  // down
    [-1, 0], // left
  ];

  @override
  void initState() {
    super.initState();
    _initializeGrid();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateAnt);
  }

  void _initializeGrid() {
    _grid = List.generate(_gridSize, (_) => List.filled(_gridSize, false));
    _antX = _gridSize ~/ 2;
    _antY = _gridSize ~/ 2;
    _direction = 0;
    _step = 0;
  }

  void _updateAnt() {
    if (!_isRunning) return;

    setState(() {
      for (int i = 0; i < _stepsPerFrame; i++) {
        _performStep();
      }
    });
  }

  void _performStep() {
    // Check bounds
    if (_antX < 0 || _antX >= _gridSize || _antY < 0 || _antY >= _gridSize) {
      _antX = _gridSize ~/ 2;
      _antY = _gridSize ~/ 2;
      return;
    }

    // Get current cell color
    final currentColor = _grid[_antY][_antX];

    // Turn based on color
    if (currentColor) {
      // White cell: turn left (counterclockwise)
      _direction = (_direction + 3) % 4;
    } else {
      // Black cell: turn right (clockwise)
      _direction = (_direction + 1) % 4;
    }

    // Flip the color
    _grid[_antY][_antX] = !currentColor;

    // Move forward
    _antX += _directions[_direction][0];
    _antY += _directions[_direction][1];

    // Wrap around
    _antX = (_antX + _gridSize) % _gridSize;
    _antY = (_antY + _gridSize) % _gridSize;

    _step++;
  }

  void _toggleRunning() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _singleStep() {
    HapticFeedback.lightImpact();
    setState(() {
      _performStep();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = false;
      _controller.stop();
      _initializeGrid();
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

    // Count white cells
    int whiteCells = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (cell) whiteCells++;
      }
    }

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
              isKorean ? '혼돈 이론' : 'CHAOS THEORY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '랭턴의 개미' : "Langton's Ant",
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '혼돈 이론' : 'Chaos Theory',
          title: isKorean ? '랭턴의 개미' : "Langton's Ant",
          formula: isKorean ? '흰색: 우회전, 반전, 전진 / 검은색: 좌회전, 반전, 전진' : 'White: turn right, flip, forward / Black: turn left, flip, forward',
          formulaDescription: isKorean
              ? '단순한 규칙에서 복잡한 패턴이 나타납니다. 약 10,000단계 후 "고속도로"가 형성됩니다.'
              : 'Complex patterns emerge from simple rules. A "highway" forms after about 10,000 steps.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _LangtonAntPainter(
                grid: _grid,
                antX: _antX,
                antY: _antY,
                direction: _direction,
                gridSize: _gridSize,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status info
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
                        _InfoItem(
                          label: isKorean ? '단계' : 'Steps',
                          value: _step.toString(),
                          color: AppColors.accent,
                        ),
                        _InfoItem(
                          label: isKorean ? '흰 셀' : 'White Cells',
                          value: whiteCells.toString(),
                          color: Colors.white,
                        ),
                        _InfoItem(
                          label: isKorean ? '위치' : 'Position',
                          value: '($_antX, $_antY)',
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Phase indicator
                    _buildPhaseIndicator(isKorean),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Speed presets
              PresetGroup(
                label: isKorean ? '속도 프리셋' : 'Speed Presets',
                presets: [
                  PresetButton(
                    label: '1x',
                    isSelected: _stepsPerFrame == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _stepsPerFrame = 1);
                    },
                  ),
                  PresetButton(
                    label: '10x',
                    isSelected: _stepsPerFrame == 10,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _stepsPerFrame = 10);
                    },
                  ),
                  PresetButton(
                    label: '50x',
                    isSelected: _stepsPerFrame == 50,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _stepsPerFrame = 50);
                    },
                  ),
                  PresetButton(
                    label: '100x',
                    isSelected: _stepsPerFrame == 100,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _stepsPerFrame = 100);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '프레임당 단계' : 'Steps per Frame',
                  value: _stepsPerFrame.toDouble(),
                  min: 1,
                  max: 200,
                  defaultValue: 1,
                  formatValue: (v) => v.toInt().toString(),
                  onChanged: (v) => setState(() => _stepsPerFrame = v.toInt()),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning
                    ? (isKorean ? '일시정지' : 'Pause')
                    : (isKorean ? '시작' : 'Start'),
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleRunning,
              ),
              SimButton(
                label: isKorean ? '한 단계' : 'Step',
                icon: Icons.skip_next,
                onPressed: _singleStep,
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

  Widget _buildPhaseIndicator(bool isKorean) {
    String phase;
    Color color;

    if (_step < 500) {
      phase = isKorean ? '초기 단계 (무질서)' : 'Initial Phase (Chaotic)';
      color = Colors.red;
    } else if (_step < 10000) {
      phase = isKorean ? '과도기 단계' : 'Transition Phase';
      color = Colors.orange;
    } else {
      phase = isKorean ? '고속도로 형성!' : 'Highway Formed!';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _step >= 10000 ? Icons.check_circle : Icons.info,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(phase, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
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
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }
}

class _LangtonAntPainter extends CustomPainter {
  final List<List<bool>> grid;
  final int antX;
  final int antY;
  final int direction;
  final int gridSize;

  _LangtonAntPainter({
    required this.grid,
    required this.antX,
    required this.antY,
    required this.direction,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final cellSize = size.width / gridSize;
    final whitePaint = Paint()..color = Colors.white;
    final antPaint = Paint()..color = Colors.red;

    // Draw grid
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (grid[y][x]) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
            whitePaint,
          );
        }
      }
    }

    // Draw ant
    final antCenterX = antX * cellSize + cellSize / 2;
    final antCenterY = antY * cellSize + cellSize / 2;
    final antSize = cellSize * 1.5;

    // Ant body
    canvas.drawCircle(Offset(antCenterX, antCenterY), antSize / 2, antPaint);

    // Direction indicator (triangle showing direction)
    final path = Path();
    final tipX = antCenterX + antSize * 0.8 * _directionDx(direction);
    final tipY = antCenterY + antSize * 0.8 * _directionDy(direction);

    path.moveTo(tipX, tipY);
    path.lineTo(
      antCenterX + antSize * 0.3 * _directionDx((direction + 1) % 4),
      antCenterY + antSize * 0.3 * _directionDy((direction + 1) % 4),
    );
    path.lineTo(
      antCenterX + antSize * 0.3 * _directionDx((direction + 3) % 4),
      antCenterY + antSize * 0.3 * _directionDy((direction + 3) % 4),
    );
    path.close();

    canvas.drawPath(path, Paint()..color = Colors.yellow);
  }

  double _directionDx(int dir) {
    switch (dir) {
      case 1: return 1;
      case 3: return -1;
      default: return 0;
    }
  }

  double _directionDy(int dir) {
    switch (dir) {
      case 0: return -1;
      case 2: return 1;
      default: return 0;
    }
  }

  @override
  bool shouldRepaint(covariant _LangtonAntPainter oldDelegate) => true;
}
