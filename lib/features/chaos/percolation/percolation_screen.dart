import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Percolation Simulation
class PercolationScreen extends ConsumerStatefulWidget {
  const PercolationScreen({super.key});

  @override
  ConsumerState<PercolationScreen> createState() => _PercolationScreenState();
}

class _PercolationScreenState extends ConsumerState<PercolationScreen> {
  final math.Random _random = math.Random();

  // Grid parameters
  static const int _gridSize = 50;
  late List<List<int>> _grid; // 0=blocked, 1=open, 2=filled

  // Parameters
  double _probability = 0.59; // Site percolation threshold ~0.593
  bool _percolates = false;
  int _openSites = 0;
  int _filledSites = 0;

  @override
  void initState() {
    super.initState();
    _generateGrid();
  }

  void _generateGrid() {
    // Initialize grid with random open/blocked sites
    _grid = List.generate(
      _gridSize,
      (_) => List.generate(
        _gridSize,
        (_) => _random.nextDouble() < _probability ? 1 : 0,
      ),
    );

    _openSites = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (cell > 0) _openSites++;
      }
    }

    _fillFromTop();
  }

  void _fillFromTop() {
    // Reset filled state
    for (int y = 0; y < _gridSize; y++) {
      for (int x = 0; x < _gridSize; x++) {
        if (_grid[y][x] == 2) _grid[y][x] = 1;
      }
    }

    // Fill from top row using flood fill
    for (int x = 0; x < _gridSize; x++) {
      if (_grid[0][x] == 1) {
        _floodFill(x, 0);
      }
    }

    // Count filled sites and check percolation
    _filledSites = 0;
    _percolates = false;
    for (int x = 0; x < _gridSize; x++) {
      for (int y = 0; y < _gridSize; y++) {
        if (_grid[y][x] == 2) {
          _filledSites++;
          if (y == _gridSize - 1) {
            _percolates = true;
          }
        }
      }
    }
  }

  void _floodFill(int x, int y) {
    if (x < 0 || x >= _gridSize || y < 0 || y >= _gridSize) return;
    if (_grid[y][x] != 1) return;

    _grid[y][x] = 2;

    // Fill neighbors (4-connectivity)
    _floodFill(x + 1, y);
    _floodFill(x - 1, y);
    _floodFill(x, y + 1);
    _floodFill(x, y - 1);
  }

  void _regenerate() {
    HapticFeedback.mediumImpact();
    setState(() {
      _generateGrid();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(languageProvider.notifier).isKorean;

    final openFraction = _openSites / (_gridSize * _gridSize);
    final filledFraction = _filledSites / (_gridSize * _gridSize);

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
              isKorean ? '퍼콜레이션' : 'Percolation',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '혼돈 이론' : 'Chaos Theory',
          title: isKorean ? '퍼콜레이션' : 'Percolation',
          formula: 'pc ~ 0.593 (2D site percolation)',
          formulaDescription: isKorean
              ? '임계 확률(pc) 이상에서 상단과 하단이 연결되는 경로가 나타납니다. 상전이의 예시입니다.'
              : 'Above critical probability (pc), a path connecting top to bottom appears. An example of phase transition.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PercolationPainter(
                grid: _grid,
                gridSize: _gridSize,
                percolates: _percolates,
                isKorean: isKorean,
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
                          label: isKorean ? '열린 사이트' : 'Open Sites',
                          value: '${(openFraction * 100).toStringAsFixed(1)}%',
                          color: Colors.white,
                        ),
                        _InfoItem(
                          label: isKorean ? '채워진 사이트' : 'Filled Sites',
                          value: '${(filledFraction * 100).toStringAsFixed(1)}%',
                          color: Colors.blue,
                        ),
                        _InfoItem(
                          label: isKorean ? '퍼콜레이션' : 'Percolates',
                          value: _percolates ? (isKorean ? '예' : 'Yes') : (isKorean ? '아니오' : 'No'),
                          color: _percolates ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Percolation indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _percolates
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _percolates
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _percolates ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: _percolates ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _percolates
                                ? (isKorean ? '상단에서 하단까지 연결됨!' : 'Connected from top to bottom!')
                                : (isKorean ? '연결 경로 없음' : 'No connecting path'),
                            style: TextStyle(
                              color: _percolates ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Presets near critical threshold
              PresetGroup(
                label: isKorean ? '확률 프리셋' : 'Probability Presets',
                presets: [
                  PresetButton(
                    label: 'p=0.5',
                    isSelected: (_probability - 0.5).abs() < 0.01,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _probability = 0.5);
                      _regenerate();
                    },
                  ),
                  PresetButton(
                    label: 'p=0.59 (pc)',
                    isSelected: (_probability - 0.59).abs() < 0.01,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _probability = 0.59);
                      _regenerate();
                    },
                  ),
                  PresetButton(
                    label: 'p=0.65',
                    isSelected: (_probability - 0.65).abs() < 0.01,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _probability = 0.65);
                      _regenerate();
                    },
                  ),
                  PresetButton(
                    label: 'p=0.75',
                    isSelected: (_probability - 0.75).abs() < 0.01,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _probability = 0.75);
                      _regenerate();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '열림 확률 (p)' : 'Open Probability (p)',
                  value: _probability,
                  min: 0.3,
                  max: 0.9,
                  defaultValue: 0.59,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() => _probability = v);
                  },
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '새로 생성' : 'Generate',
                icon: Icons.casino,
                isPrimary: true,
                onPressed: _regenerate,
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
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PercolationPainter extends CustomPainter {
  final List<List<int>> grid;
  final int gridSize;
  final bool percolates;
  final bool isKorean;

  _PercolationPainter({
    required this.grid,
    required this.gridSize,
    required this.percolates,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final cellSize = size.width / gridSize;

    final blockedPaint = Paint()..color = Colors.grey[800]!;
    final openPaint = Paint()..color = Colors.white;
    final filledPaint = Paint()..color = Colors.blue;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        Paint paint;
        switch (grid[y][x]) {
          case 0:
            paint = blockedPaint;
            break;
          case 1:
            paint = openPaint;
            break;
          case 2:
            paint = filledPaint;
            break;
          default:
            paint = blockedPaint;
        }

        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize - 0.5, cellSize - 0.5),
          paint,
        );
      }
    }

    // Draw top and bottom indicators
    canvas.drawRect(
      Rect.fromLTWH(0, -5, size.width, 3),
      Paint()..color = Colors.green,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height + 2, size.width, 3),
      Paint()..color = percolates ? Colors.green : Colors.red,
    );

    // Legend
    final legendY = size.height - 25;
    canvas.drawRect(Rect.fromLTWH(10, legendY, 12, 12), blockedPaint);
    _drawText(canvas, isKorean ? '막힘' : 'Blocked', Offset(25, legendY), AppColors.muted, 9);

    canvas.drawRect(Rect.fromLTWH(70, legendY, 12, 12), openPaint);
    _drawText(canvas, isKorean ? '열림' : 'Open', Offset(85, legendY), AppColors.muted, 9);

    canvas.drawRect(Rect.fromLTWH(125, legendY, 12, 12), filledPaint);
    _drawText(canvas, isKorean ? '채워짐' : 'Filled', Offset(140, legendY), AppColors.muted, 9);
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
  bool shouldRepaint(covariant _PercolationPainter oldDelegate) => true;
}
