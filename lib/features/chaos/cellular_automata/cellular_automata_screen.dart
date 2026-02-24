import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Cellular Automata (Rule 110) Simulation
class CellularAutomataScreen extends ConsumerStatefulWidget {
  const CellularAutomataScreen({super.key});

  @override
  ConsumerState<CellularAutomataScreen> createState() => _CellularAutomataScreenState();
}

class _CellularAutomataScreenState extends ConsumerState<CellularAutomataScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  int _rule = 110; // Rule 110 is Turing complete
  int _width = 101;
  double _speed = 1.0;
  String _initialCondition = 'single';

  // State
  List<List<bool>> _grid = [];
  int _currentRow = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _initializeGrid();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateAutomaton);
  }

  void _initializeGrid() {
    _grid = [];
    _currentRow = 0;

    // Initialize first row based on condition
    final firstRow = List.filled(_width, false);

    switch (_initialCondition) {
      case 'single':
        firstRow[_width ~/ 2] = true;
        break;
      case 'random':
        for (int i = 0; i < _width; i++) {
          firstRow[i] = DateTime.now().microsecondsSinceEpoch % (i + 2) == 0;
        }
        break;
      case 'alternating':
        for (int i = 0; i < _width; i++) {
          firstRow[i] = i % 2 == 0;
        }
        break;
    }

    _grid.add(firstRow);
  }

  void _updateAutomaton() {
    if (!_isRunning) return;

    setState(() {
      if (_grid.isEmpty) return;

      final prevRow = _grid.last;
      final newRow = List.filled(_width, false);

      for (int i = 0; i < _width; i++) {
        // Get neighborhood (with wrapping)
        final left = prevRow[(i - 1 + _width) % _width];
        final center = prevRow[i];
        final right = prevRow[(i + 1) % _width];

        // Convert to rule index (0-7)
        final index = (left ? 4 : 0) + (center ? 2 : 0) + (right ? 1 : 0);

        // Apply rule
        newRow[i] = (_rule >> index) & 1 == 1;
      }

      _grid.add(newRow);
      _currentRow++;

      // Limit grid size
      if (_grid.length > 200) {
        _grid.removeAt(0);
      }
    });
  }

  void _toggleRunning() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _controller.duration = Duration(milliseconds: (100 / _speed).round());
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _step() {
    HapticFeedback.lightImpact();
    if (_grid.isEmpty) return;

    final prevRow = _grid.last;
    final newRow = List.filled(_width, false);

    for (int i = 0; i < _width; i++) {
      final left = prevRow[(i - 1 + _width) % _width];
      final center = prevRow[i];
      final right = prevRow[(i + 1) % _width];
      final index = (left ? 4 : 0) + (center ? 2 : 0) + (right ? 1 : 0);
      newRow[i] = (_rule >> index) & 1 == 1;
    }

    setState(() {
      _grid.add(newRow);
      _currentRow++;
      if (_grid.length > 200) {
        _grid.removeAt(0);
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

  String _getRuleBinary() {
    return _rule.toRadixString(2).padLeft(8, '0');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);

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
              isKorean ? '셀룰러 오토마타' : 'Cellular Automata',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '혼돈 이론' : 'Chaos Theory',
          title: isKorean ? '셀룰러 오토마타' : 'Cellular Automata',
          formula: 'Rule $_rule = ${_getRuleBinary()}',
          formulaDescription: isKorean
              ? 'Wolfram의 1차원 셀룰러 오토마타. 각 셀의 다음 상태는 자신과 이웃 두 셀의 현재 상태로 결정됩니다.'
              : "Wolfram's 1D cellular automata. Each cell's next state is determined by itself and its two neighbors.",
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CellularAutomataPainter(
                grid: _grid,
                width: _width,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rule visualization
              Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rule $_rule',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isKorean ? '세대: $_currentRow' : 'Generation: $_currentRow',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Rule pattern display
                    _RulePatternDisplay(rule: _rule),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Famous rules
              PresetGroup(
                label: isKorean ? '유명한 규칙' : 'Famous Rules',
                presets: [
                  PresetButton(
                    label: 'Rule 30',
                    isSelected: _rule == 30,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _rule = 30;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: 'Rule 90',
                    isSelected: _rule == 90,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _rule = 90;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: 'Rule 110',
                    isSelected: _rule == 110,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _rule = 110;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: 'Rule 184',
                    isSelected: _rule == 184,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _rule = 184;
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Initial condition
              PresetGroup(
                label: isKorean ? '초기 조건' : 'Initial Condition',
                presets: [
                  PresetButton(
                    label: isKorean ? '단일 셀' : 'Single',
                    isSelected: _initialCondition == 'single',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _initialCondition = 'single';
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '무작위' : 'Random',
                    isSelected: _initialCondition == 'random',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _initialCondition = 'random';
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '교대' : 'Alternating',
                    isSelected: _initialCondition == 'alternating',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _initialCondition = 'alternating';
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '규칙 번호' : 'Rule Number',
                  value: _rule.toDouble(),
                  min: 0,
                  max: 255,
                  defaultValue: 110,
                  formatValue: (v) => v.toInt().toString(),
                  onChanged: (v) {
                    setState(() {
                      _rule = v.toInt();
                      _reset();
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '속도' : 'Speed',
                    value: _speed,
                    min: 0.2,
                    max: 5.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) {
                      setState(() {
                        _speed = v;
                        if (_isRunning) {
                          _controller.duration = Duration(milliseconds: (100 / _speed).round());
                        }
                      });
                    },
                  ),
                ],
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
                onPressed: _step,
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

class _RulePatternDisplay extends StatelessWidget {
  final int rule;

  const _RulePatternDisplay({required this.rule});

  @override
  Widget build(BuildContext context) {
    // Show all 8 possible input patterns and their outputs
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(8, (i) {
        final index = 7 - i; // Reverse order for display
        final left = (index >> 2) & 1 == 1;
        final center = (index >> 1) & 1 == 1;
        final right = index & 1 == 1;
        final output = (rule >> index) & 1 == 1;

        return Column(
          children: [
            Row(
              children: [
                _MiniCell(filled: left),
                _MiniCell(filled: center),
                _MiniCell(filled: right),
              ],
            ),
            const SizedBox(height: 2),
            _MiniCell(filled: output, isOutput: true),
          ],
        );
      }),
    );
  }
}

class _MiniCell extends StatelessWidget {
  final bool filled;
  final bool isOutput;

  const _MiniCell({required this.filled, this.isOutput = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: filled ? (isOutput ? AppColors.accent : AppColors.ink) : AppColors.bg,
        border: Border.all(color: AppColors.muted, width: 0.5),
      ),
    );
  }
}

class _CellularAutomataPainter extends CustomPainter {
  final List<List<bool>> grid;
  final int width;
  final bool isKorean;

  _CellularAutomataPainter({
    required this.grid,
    required this.width,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (grid.isEmpty) return;

    final cellWidth = size.width / width;
    final cellHeight = size.height / grid.length.clamp(1, 200);

    final filledPaint = Paint()..color = AppColors.ink;

    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < width; x++) {
        if (grid[y][x]) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight),
            filledPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CellularAutomataPainter oldDelegate) => true;
}
