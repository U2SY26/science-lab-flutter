import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Abelian Sandpile Simulation
class SandpileScreen extends ConsumerStatefulWidget {
  const SandpileScreen({super.key});

  @override
  ConsumerState<SandpileScreen> createState() => _SandpileScreenState();
}

class _SandpileScreenState extends ConsumerState<SandpileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Grid parameters
  static const int _gridSize = 51;
  late List<List<int>> _grid;

  // Parameters
  int _totalGrains = 0;
  int _avalanches = 0;
  bool _isRunning = false;
  int _grainsPerFrame = 1;
  String _dropMode = 'center';

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeGrid();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_update);
  }

  void _initializeGrid() {
    _grid = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));
    _totalGrains = 0;
    _avalanches = 0;
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      for (int i = 0; i < _grainsPerFrame; i++) {
        _dropGrain();
      }
    });
  }

  void _dropGrain() {
    int x, y;

    switch (_dropMode) {
      case 'center':
        x = _gridSize ~/ 2;
        y = _gridSize ~/ 2;
        break;
      case 'random':
        x = _random.nextInt(_gridSize);
        y = _random.nextInt(_gridSize);
        break;
      default:
        x = _gridSize ~/ 2;
        y = _gridSize ~/ 2;
    }

    _grid[y][x]++;
    _totalGrains++;

    // Topple until stable
    bool toppled = true;
    while (toppled) {
      toppled = false;
      for (int cy = 0; cy < _gridSize; cy++) {
        for (int cx = 0; cx < _gridSize; cx++) {
          if (_grid[cy][cx] >= 4) {
            _topple(cx, cy);
            toppled = true;
            _avalanches++;
          }
        }
      }
    }
  }

  void _topple(int x, int y) {
    _grid[y][x] -= 4;

    // Distribute to neighbors (grains fall off edges)
    if (x > 0) _grid[y][x - 1]++;
    if (x < _gridSize - 1) _grid[y][x + 1]++;
    if (y > 0) _grid[y - 1][x]++;
    if (y < _gridSize - 1) _grid[y + 1][x]++;
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

  void _dropSingle() {
    HapticFeedback.lightImpact();
    setState(() {
      _dropGrain();
    });
  }

  void _dropMany(int count) {
    HapticFeedback.mediumImpact();
    setState(() {
      for (int i = 0; i < count; i++) {
        _dropGrain();
      }
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

    // Calculate statistics
    int maxHeight = 0;
    int totalOnGrid = 0;
    for (final row in _grid) {
      for (final cell in row) {
        totalOnGrid += cell;
        if (cell > maxHeight) maxHeight = cell;
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
              isKorean ? '아벨리안 샌드파일' : 'Abelian Sandpile',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '혼돈 이론' : 'Chaos Theory',
          title: isKorean ? '아벨리안 샌드파일' : 'Abelian Sandpile',
          formula: isKorean ? '셀 >= 4 이면, 이웃 4개에 각각 1 분배' : 'If cell >= 4, distribute 1 to each of 4 neighbors',
          formulaDescription: isKorean
              ? '자기조직화 임계 현상의 예시. 모래알이 쌓이면 눈사태가 발생하여 프랙탈 패턴이 형성됩니다.'
              : 'An example of self-organized criticality. As sand accumulates, avalanches create fractal patterns.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SandpilePainter(
                grid: _grid,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoItem(
                      label: isKorean ? '총 모래알' : 'Total Grains',
                      value: _totalGrains.toString(),
                      color: AppColors.accent,
                    ),
                    _InfoItem(
                      label: isKorean ? '격자 위' : 'On Grid',
                      value: totalOnGrid.toString(),
                      color: Colors.orange,
                    ),
                    _InfoItem(
                      label: isKorean ? '최대 높이' : 'Max Height',
                      value: maxHeight.toString(),
                      color: Colors.red,
                    ),
                    _InfoItem(
                      label: isKorean ? '눈사태' : 'Avalanches',
                      value: _avalanches.toString(),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Drop mode
              PresetGroup(
                label: isKorean ? '드롭 모드' : 'Drop Mode',
                presets: [
                  PresetButton(
                    label: isKorean ? '중앙' : 'Center',
                    isSelected: _dropMode == 'center',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _dropMode = 'center');
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '무작위' : 'Random',
                    isSelected: _dropMode == 'random',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _dropMode = 'random');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick drop buttons
              PresetGroup(
                label: isKorean ? '빠른 드롭' : 'Quick Drop',
                presets: [
                  PresetButton(
                    label: '+100',
                    isSelected: false,
                    onPressed: () => _dropMany(100),
                  ),
                  PresetButton(
                    label: '+1000',
                    isSelected: false,
                    onPressed: () => _dropMany(1000),
                  ),
                  PresetButton(
                    label: '+10000',
                    isSelected: false,
                    onPressed: () => _dropMany(10000),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '프레임당 모래알' : 'Grains per Frame',
                  value: _grainsPerFrame.toDouble(),
                  min: 1,
                  max: 100,
                  defaultValue: 1,
                  formatValue: (v) => v.toInt().toString(),
                  onChanged: (v) => setState(() => _grainsPerFrame = v.toInt()),
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
                label: isKorean ? '+1' : '+1',
                icon: Icons.add,
                onPressed: _dropSingle,
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
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }
}

class _SandpilePainter extends CustomPainter {
  final List<List<int>> grid;
  final int gridSize;

  _SandpilePainter({
    required this.grid,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final cellSize = size.width / gridSize;

    // Color palette for different heights
    final colors = [
      Colors.black,           // 0
      Colors.blue[700]!,      // 1
      Colors.green[600]!,     // 2
      Colors.yellow[600]!,    // 3
      Colors.red,             // 4+ (unstable, but shown briefly)
    ];

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final height = grid[y][x];
        final color = colors[height.clamp(0, colors.length - 1)];

        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          Paint()..color = color,
        );
      }
    }

    // Grid lines for small grids
    if (gridSize <= 30) {
      final linePaint = Paint()
        ..color = AppColors.muted.withValues(alpha: 0.1)
        ..strokeWidth = 0.5;

      for (int i = 0; i <= gridSize; i++) {
        canvas.drawLine(
          Offset(i * cellSize, 0),
          Offset(i * cellSize, size.height),
          linePaint,
        );
        canvas.drawLine(
          Offset(0, i * cellSize),
          Offset(size.width, i * cellSize),
          linePaint,
        );
      }
    }

    // Legend
    final legendY = size.height - 20;
    for (int i = 0; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(10 + i * 35, legendY, 12, 12),
        Paint()..color = colors[i],
      );
      _drawText(canvas, '$i', Offset(25 + i * 35, legendY), Colors.white, 9);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _SandpilePainter oldDelegate) => true;
}
