import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// P vs NP 문제 시각화
class PVsNpScreen extends StatefulWidget {
  const PVsNpScreen({super.key});

  @override
  State<PVsNpScreen> createState() => _PVsNpScreenState();
}

class _PVsNpScreenState extends State<PVsNpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  String _problem = 'sorting';
  int _inputSize = 10;
  bool _isRunning = false;
  List<int> _data = [];
  int _currentStep = 0;
  int _totalSteps = 0;
  int _comparisons = 0;

  // TSP 관련
  List<Offset> _cities = [];
  List<int> _currentPath = [];
  List<int> _bestPath = [];
  double _bestDistance = double.infinity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_update);
    _generateData();
  }

  void _generateData() {
    _data = List.generate(_inputSize, (i) => _random.nextInt(100));
    _cities = List.generate(_inputSize, (i) => Offset(
      _random.nextDouble(),
      _random.nextDouble(),
    ));
    _currentStep = 0;
    _totalSteps = 0;
    _comparisons = 0;
    _currentPath = [];
    _bestPath = [];
    _bestDistance = double.infinity;
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      if (_problem == 'sorting') {
        _sortingStep();
      } else if (_problem == 'tsp') {
        _tspStep();
      }
    });
  }

  void _sortingStep() {
    // 버블 정렬 (P 문제 - O(n²))
    bool swapped = false;
    for (int i = 0; i < _data.length - 1 - _currentStep; i++) {
      _comparisons++;
      if (_data[i] > _data[i + 1]) {
        final temp = _data[i];
        _data[i] = _data[i + 1];
        _data[i + 1] = temp;
        swapped = true;
      }
    }
    _currentStep++;
    _totalSteps++;

    if (!swapped || _currentStep >= _data.length - 1) {
      _isRunning = false;
      _controller.stop();
    }
  }

  void _tspStep() {
    // 브루트 포스 TSP (NP 문제 - O(n!))
    if (_currentPath.isEmpty) {
      _currentPath = List.generate(_inputSize, (i) => i);
    }

    // 다음 순열 생성
    if (!_nextPermutation(_currentPath)) {
      _isRunning = false;
      _controller.stop();
      return;
    }

    _totalSteps++;
    final distance = _calculatePathDistance(_currentPath);
    if (distance < _bestDistance) {
      _bestDistance = distance;
      _bestPath = List.from(_currentPath);
    }
  }

  bool _nextPermutation(List<int> arr) {
    int i = arr.length - 2;
    while (i >= 0 && arr[i] >= arr[i + 1]) i--;
    if (i < 0) return false;

    int j = arr.length - 1;
    while (arr[j] <= arr[i]) j--;

    final temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;

    // Reverse from i+1 to end
    int left = i + 1, right = arr.length - 1;
    while (left < right) {
      final t = arr[left];
      arr[left] = arr[right];
      arr[right] = t;
      left++;
      right--;
    }
    return true;
  }

  double _calculatePathDistance(List<int> path) {
    double total = 0;
    for (int i = 0; i < path.length; i++) {
      final from = _cities[path[i]];
      final to = _cities[path[(i + 1) % path.length]];
      total += math.sqrt(math.pow(from.dx - to.dx, 2) + math.pow(from.dy - to.dy, 2));
    }
    return total;
  }

  void _start() {
    HapticFeedback.mediumImpact();
    _generateData();
    _isRunning = true;
    _controller.repeat();
    setState(() {});
  }

  void _stop() {
    _isRunning = false;
    _controller.stop();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              '밀레니엄 난제',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              'P vs NP',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '밀레니엄 난제',
          title: 'P vs NP 문제',
          formula: 'P ⊆ NP, P = NP?',
          formulaDescription: '다항 시간에 검증 가능한 문제가 다항 시간에 풀리는가?',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _PvsNpPainter(
                problem: _problem,
                data: _data,
                cities: _cities,
                currentPath: _currentPath,
                bestPath: _bestPath,
                totalSteps: _totalSteps,
                inputSize: _inputSize,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 설명
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '상금: \$1,000,000',
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _problem == 'sorting'
                          ? 'P 문제: 정렬 - O(n²) 또는 O(n log n)에 해결 가능'
                          : 'NP 문제: TSP - O(n!)로 모든 경우를 확인해야 함',
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 통계
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
                    _InfoItem(label: '입력 크기', value: '$_inputSize', color: AppColors.ink),
                    _InfoItem(
                      label: '총 단계',
                      value: _problem == 'sorting'
                          ? '$_totalSteps / ${_inputSize * _inputSize}'
                          : '$_totalSteps / ${_factorial(_inputSize)}',
                      color: Colors.blue,
                    ),
                    _InfoItem(
                      label: '복잡도',
                      value: _problem == 'sorting' ? 'O(n²)' : 'O(n!)',
                      color: _problem == 'sorting' ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 문제 선택
              PresetGroup(
                label: '문제 유형',
                presets: [
                  PresetButton(
                    label: '정렬 (P)',
                    isSelected: _problem == 'sorting',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _problem = 'sorting';
                        _stop();
                        _generateData();
                      });
                    },
                  ),
                  PresetButton(
                    label: 'TSP (NP)',
                    isSelected: _problem == 'tsp',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _problem = 'tsp';
                        _stop();
                        _inputSize = math.min(_inputSize, 8); // TSP는 크기 제한
                        _generateData();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '입력 크기 (n)',
                  value: _inputSize.toDouble(),
                  min: _problem == 'tsp' ? 4 : 5,
                  max: _problem == 'tsp' ? 8 : 30,
                  defaultValue: 10,
                  formatValue: (v) => '${v.toInt()}개',
                  onChanged: (v) {
                    setState(() {
                      _inputSize = v.toInt();
                      _stop();
                      _generateData();
                    });
                  },
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning ? '정지' : '시작',
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _isRunning ? _stop : _start,
              ),
              SimButton(
                label: '리셋',
                icon: Icons.refresh,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _stop();
                  _generateData();
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _factorial(int n) {
    if (n <= 1) return '1';
    int result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    if (result > 9999999) return '${(result / 1000000).toStringAsFixed(1)}M';
    if (result > 9999) return '${(result / 1000).toStringAsFixed(1)}K';
    return result.toString();
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
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PvsNpPainter extends CustomPainter {
  final String problem;
  final List<int> data;
  final List<Offset> cities;
  final List<int> currentPath;
  final List<int> bestPath;
  final int totalSteps;
  final int inputSize;

  _PvsNpPainter({
    required this.problem,
    required this.data,
    required this.cities,
    required this.currentPath,
    required this.bestPath,
    required this.totalSteps,
    required this.inputSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (problem == 'sorting') {
      _drawSorting(canvas, size);
    } else {
      _drawTsp(canvas, size);
    }
  }

  void _drawSorting(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = 20.0;
    final barWidth = (size.width - padding * 2) / data.length;
    final maxVal = data.reduce(math.max).toDouble();

    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i] / maxVal) * (size.height - padding * 2);
      final x = padding + i * barWidth;
      final y = size.height - padding - barHeight;

      // 그라데이션 색상
      final color = Color.lerp(Colors.blue, Colors.green, data[i] / maxVal)!;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 1, y, barWidth - 2, barHeight),
          const Radius.circular(2),
        ),
        Paint()..color = color,
      );
    }

    // 복잡도 시각화
    _drawText(canvas, 'P 문제: 다항 시간에 해결 가능', Offset(10, 10), Colors.green);
  }

  void _drawTsp(Canvas canvas, Size size) {
    if (cities.isEmpty) return;

    final padding = 30.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 도시들
    for (int i = 0; i < cities.length; i++) {
      final pos = Offset(
        padding + cities[i].dx * graphWidth,
        padding + cities[i].dy * graphHeight,
      );
      canvas.drawCircle(pos, 8, Paint()..color = Colors.orange);
      _drawText(canvas, '$i', Offset(pos.dx - 3, pos.dy - 5), Colors.white, fontSize: 10);
    }

    // 현재 경로
    if (currentPath.length > 1) {
      final pathPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < currentPath.length; i++) {
        final pos = Offset(
          padding + cities[currentPath[i]].dx * graphWidth,
          padding + cities[currentPath[i]].dy * graphHeight,
        );
        if (i == 0) {
          path.moveTo(pos.dx, pos.dy);
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }
      path.close();
      canvas.drawPath(path, pathPaint);
    }

    // 최적 경로
    if (bestPath.length > 1) {
      final bestPaint = Paint()
        ..color = Colors.green
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < bestPath.length; i++) {
        final pos = Offset(
          padding + cities[bestPath[i]].dx * graphWidth,
          padding + cities[bestPath[i]].dy * graphHeight,
        );
        if (i == 0) {
          path.moveTo(pos.dx, pos.dy);
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }
      path.close();
      canvas.drawPath(path, bestPaint);
    }

    // 복잡도 시각화
    _drawText(canvas, 'NP 문제: 지수/팩토리얼 시간', Offset(10, 10), Colors.red);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 11}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _PvsNpPainter oldDelegate) => true;
}
