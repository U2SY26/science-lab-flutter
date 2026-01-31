import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 정렬 알고리즘 시각화 화면
class SortingScreen extends StatefulWidget {
  const SortingScreen({super.key});

  @override
  State<SortingScreen> createState() => _SortingScreenState();
}

enum SortAlgorithm {
  bubble('버블 정렬', 'O(n²)', 'O(1)', '인접 요소를 비교하여 교환'),
  selection('선택 정렬', 'O(n²)', 'O(1)', '최솟값을 찾아 맨 앞으로'),
  insertion('삽입 정렬', 'O(n²)', 'O(1)', '정렬된 부분에 삽입'),
  quick('퀵 정렬', 'O(n log n)', 'O(log n)', '피벗 기준 분할 정복'),
  merge('병합 정렬', 'O(n log n)', 'O(n)', '분할 후 병합');

  final String label;
  final String timeComplexity;
  final String spaceComplexity;
  final String description;

  const SortAlgorithm(this.label, this.timeComplexity, this.spaceComplexity, this.description);
}

class _SortingScreenState extends State<SortingScreen> {
  List<int> _array = [];
  int _comparing1 = -1;
  int _comparing2 = -1;
  Set<int> _sortedIndices = {};
  bool _isSorting = false;
  SortAlgorithm _algorithm = SortAlgorithm.bubble;
  double _speed = 50;
  int _comparisons = 0;
  int _swaps = 0;
  int _arraySize = 30;

  @override
  void initState() {
    super.initState();
    _generateArray();
  }

  void _generateArray() {
    final random = math.Random();
    setState(() {
      _array = List.generate(_arraySize, (_) => random.nextInt(100) + 10);
      _comparing1 = -1;
      _comparing2 = -1;
      _sortedIndices = {};
      _comparisons = 0;
      _swaps = 0;
    });
  }

  void _generateReversed() {
    setState(() {
      _array = List.generate(_arraySize, (i) => 110 - (i * 100 ~/ _arraySize));
      _comparing1 = -1;
      _comparing2 = -1;
      _sortedIndices = {};
      _comparisons = 0;
      _swaps = 0;
    });
  }

  Future<void> _sort() async {
    if (_isSorting) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isSorting = true;
      _comparisons = 0;
      _swaps = 0;
      _sortedIndices = {};
    });

    switch (_algorithm) {
      case SortAlgorithm.bubble:
        await _bubbleSort();
        break;
      case SortAlgorithm.selection:
        await _selectionSort();
        break;
      case SortAlgorithm.insertion:
        await _insertionSort();
        break;
      case SortAlgorithm.quick:
        await _quickSort(0, _array.length - 1);
        break;
      case SortAlgorithm.merge:
        await _mergeSort(0, _array.length - 1);
        break;
    }

    if (_isSorting) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isSorting = false;
        _comparing1 = -1;
        _comparing2 = -1;
        _sortedIndices = Set.from(List.generate(_array.length, (i) => i));
      });
    }
  }

  Future<void> _bubbleSort() async {
    for (int i = 0; i < _array.length - 1; i++) {
      bool swapped = false;
      for (int j = 0; j < _array.length - i - 1; j++) {
        if (!_isSorting) return;
        setState(() {
          _comparing1 = j;
          _comparing2 = j + 1;
          _comparisons++;
        });
        await Future.delayed(Duration(milliseconds: _speed.toInt()));

        if (_array[j] > _array[j + 1]) {
          setState(() {
            final temp = _array[j];
            _array[j] = _array[j + 1];
            _array[j + 1] = temp;
            _swaps++;
          });
          swapped = true;
          await Future.delayed(Duration(milliseconds: _speed.toInt()));
        }
      }
      setState(() => _sortedIndices.add(_array.length - i - 1));
      if (!swapped) break;
    }
  }

  Future<void> _selectionSort() async {
    for (int i = 0; i < _array.length - 1; i++) {
      int minIdx = i;
      for (int j = i + 1; j < _array.length; j++) {
        if (!_isSorting) return;
        setState(() {
          _comparing1 = minIdx;
          _comparing2 = j;
          _comparisons++;
        });
        await Future.delayed(Duration(milliseconds: _speed.toInt()));

        if (_array[j] < _array[minIdx]) {
          minIdx = j;
        }
      }
      if (minIdx != i) {
        setState(() {
          final temp = _array[i];
          _array[i] = _array[minIdx];
          _array[minIdx] = temp;
          _swaps++;
        });
        await Future.delayed(Duration(milliseconds: _speed.toInt()));
      }
      setState(() => _sortedIndices.add(i));
    }
  }

  Future<void> _insertionSort() async {
    setState(() => _sortedIndices.add(0));
    for (int i = 1; i < _array.length; i++) {
      int key = _array[i];
      int j = i - 1;

      while (j >= 0 && _array[j] > key) {
        if (!_isSorting) return;
        setState(() {
          _comparing1 = j;
          _comparing2 = j + 1;
          _comparisons++;
          _array[j + 1] = _array[j];
          _swaps++;
        });
        await Future.delayed(Duration(milliseconds: _speed.toInt()));
        j--;
      }
      setState(() {
        _array[j + 1] = key;
        _sortedIndices.add(i);
      });
      await Future.delayed(Duration(milliseconds: _speed.toInt()));
    }
  }

  Future<void> _quickSort(int low, int high) async {
    if (low < high && _isSorting) {
      int pi = await _partition(low, high);
      setState(() => _sortedIndices.add(pi));
      await _quickSort(low, pi - 1);
      await _quickSort(pi + 1, high);
    }
  }

  Future<int> _partition(int low, int high) async {
    int pivot = _array[high];
    int i = low - 1;

    for (int j = low; j < high; j++) {
      if (!_isSorting) return low;
      setState(() {
        _comparing1 = j;
        _comparing2 = high;
        _comparisons++;
      });
      await Future.delayed(Duration(milliseconds: _speed.toInt()));

      if (_array[j] < pivot) {
        i++;
        setState(() {
          final temp = _array[i];
          _array[i] = _array[j];
          _array[j] = temp;
          _swaps++;
        });
        await Future.delayed(Duration(milliseconds: _speed.toInt()));
      }
    }

    setState(() {
      final temp = _array[i + 1];
      _array[i + 1] = _array[high];
      _array[high] = temp;
      _swaps++;
    });
    await Future.delayed(Duration(milliseconds: _speed.toInt()));

    return i + 1;
  }

  Future<void> _mergeSort(int left, int right) async {
    if (left < right && _isSorting) {
      int mid = (left + right) ~/ 2;
      await _mergeSort(left, mid);
      await _mergeSort(mid + 1, right);
      await _merge(left, mid, right);
    }
  }

  Future<void> _merge(int left, int mid, int right) async {
    List<int> leftArr = _array.sublist(left, mid + 1);
    List<int> rightArr = _array.sublist(mid + 1, right + 1);

    int i = 0, j = 0, k = left;

    while (i < leftArr.length && j < rightArr.length && _isSorting) {
      setState(() {
        _comparing1 = left + i;
        _comparing2 = mid + 1 + j;
        _comparisons++;
      });
      await Future.delayed(Duration(milliseconds: _speed.toInt()));

      if (leftArr[i] <= rightArr[j]) {
        setState(() {
          _array[k] = leftArr[i];
          _sortedIndices.add(k);
        });
        i++;
      } else {
        setState(() {
          _array[k] = rightArr[j];
          _sortedIndices.add(k);
          _swaps++;
        });
        j++;
      }
      k++;
      await Future.delayed(Duration(milliseconds: _speed.toInt()));
    }

    while (i < leftArr.length && _isSorting) {
      setState(() {
        _array[k] = leftArr[i];
        _sortedIndices.add(k);
      });
      i++;
      k++;
      await Future.delayed(Duration(milliseconds: _speed.toInt()));
    }

    while (j < rightArr.length && _isSorting) {
      setState(() {
        _array[k] = rightArr[j];
        _sortedIndices.add(k);
      });
      j++;
      k++;
      await Future.delayed(Duration(milliseconds: _speed.toInt()));
    }
  }

  void _stop() {
    HapticFeedback.lightImpact();
    setState(() => _isSorting = false);
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
              '알고리즘',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '정렬 알고리즘',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '알고리즘',
          title: '정렬 알고리즘',
          formula: '시간: ${_algorithm.timeComplexity}  공간: ${_algorithm.spaceComplexity}',
          formulaDescription: _algorithm.description,
          simulation: SizedBox(
            height: 280,
            child: CustomPaint(
              painter: SortingPainter(
                array: _array,
                comparing1: _comparing1,
                comparing2: _comparing2,
                sortedIndices: _sortedIndices,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 알고리즘 선택
              PresetGroup(
                label: '알고리즘',
                presets: SortAlgorithm.values.map((algo) => PresetButton(
                  label: algo.label,
                  isSelected: _algorithm == algo,
                  onPressed: _isSorting ? () {} : () => setState(() => _algorithm = algo),
                )).toList(),
              ),
              const SizedBox(height: 16),
              // 통계
              _StatsDisplay(
                comparisons: _comparisons,
                swaps: _swaps,
                arraySize: _array.length,
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '속도 (딜레이)',
                  value: _speed,
                  min: 5,
                  max: 200,
                  defaultValue: 50,
                  formatValue: (v) => '${v.toInt()} ms',
                  onChanged: (v) => setState(() => _speed = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '배열 크기',
                    value: _arraySize.toDouble(),
                    min: 10,
                    max: 60,
                    defaultValue: 30,
                    formatValue: (v) => '${v.toInt()}',
                    onChanged: (v) {
                      if (_isSorting) return;
                      setState(() => _arraySize = v.toInt());
                      _generateArray();
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
                label: _isSorting ? '중지' : '정렬 시작',
                icon: _isSorting ? Icons.stop : Icons.play_arrow,
                isPrimary: true,
                isLoading: _isSorting,
                onPressed: _isSorting ? _stop : _sort,
              ),
              SimButton(
                label: '랜덤',
                icon: Icons.shuffle,
                onPressed: _isSorting ? null : _generateArray,
              ),
              SimButton(
                label: '역순',
                icon: Icons.swap_vert,
                onPressed: _isSorting ? null : _generateReversed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 통계 표시 위젯
class _StatsDisplay extends StatelessWidget {
  final int comparisons;
  final int swaps;
  final int arraySize;

  const _StatsDisplay({
    required this.comparisons,
    required this.swaps,
    required this.arraySize,
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
          _StatItem(label: '비교 횟수', value: comparisons.toString(), color: AppColors.accent),
          _StatItem(label: '교환 횟수', value: swaps.toString(), color: AppColors.accent2),
          _StatItem(label: '배열 크기', value: arraySize.toString(), color: AppColors.muted),
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
              fontSize: 16,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 정렬 시각화 페인터
class SortingPainter extends CustomPainter {
  final List<int> array;
  final int comparing1;
  final int comparing2;
  final Set<int> sortedIndices;

  SortingPainter({
    required this.array,
    required this.comparing1,
    required this.comparing2,
    required this.sortedIndices,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    if (array.isEmpty) return;

    final barWidth = (size.width - 40) / array.length - 2;
    final maxVal = array.reduce(math.max);
    final heightScale = (size.height - 50) / maxVal;

    for (int i = 0; i < array.length; i++) {
      final barHeight = array[i] * heightScale;
      final x = 20 + i * (barWidth + 2);
      final y = size.height - 20 - barHeight;

      Color color;
      if (i == comparing1 || i == comparing2) {
        color = AppColors.accent2; // 비교 중
      } else if (sortedIndices.contains(i)) {
        color = const Color(0xFF4CAF50); // 정렬 완료
      } else {
        color = AppColors.accent; // 기본
      }

      // 그림자
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 1, y + 2, barWidth, barHeight),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.2),
      );

      // 바
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          color.withValues(alpha: 0.7),
        ],
      ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(2),
        ),
        Paint()..shader = gradient,
      );

      // 비교 중인 바에 글로우 효과
      if (i == comparing1 || i == comparing2) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 2, y - 2, barWidth + 4, barHeight + 4),
            const Radius.circular(4),
          ),
          Paint()
            ..color = AppColors.accent2.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // 범례
    _drawLegend(canvas, size);
  }

  void _drawLegend(Canvas canvas, Size size) {
    const legendY = 8.0;
    var legendX = 20.0;

    final legends = [
      (AppColors.accent, '미정렬'),
      (AppColors.accent2, '비교 중'),
      (const Color(0xFF4CAF50), '완료'),
    ];

    for (final (color, label) in legends) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(legendX, legendY, 10, 10),
          const Radius.circular(2),
        ),
        Paint()..color = color,
      );
      _drawText(canvas, label, Offset(legendX + 14, legendY - 1));
      legendX += 60;
    }
  }

  void _drawText(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant SortingPainter oldDelegate) => true;
}
