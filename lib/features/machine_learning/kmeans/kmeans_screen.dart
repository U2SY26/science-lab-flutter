import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// K-Means 클러스터링 화면
class KMeansScreen extends StatefulWidget {
  const KMeansScreen({super.key});

  @override
  State<KMeansScreen> createState() => _KMeansScreenState();
}

class _KMeansScreenState extends State<KMeansScreen> {
  // 데이터 포인트
  List<Offset> _points = [];
  List<int> _assignments = [];

  // 중심점
  List<Offset> _centroids = [];
  int _k = 3;
  int _iteration = 0;
  bool _isConverged = false;

  // 클러스터 색상
  final List<Color> _clusterColors = [
    AppColors.accent,
    AppColors.accent2,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
  ];

  // 프리셋
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _generateData('blobs');
  }

  void _generateData(String preset) {
    final rand = math.Random();
    _points = [];
    _selectedPreset = preset;

    switch (preset) {
      case 'blobs':
        // 3개의 명확한 군집
        for (int c = 0; c < 3; c++) {
          final cx = 80 + c * 100.0;
          final cy = 100 + (c % 2) * 80.0;
          for (int i = 0; i < 20; i++) {
            _points.add(Offset(
              cx + (rand.nextDouble() - 0.5) * 60,
              cy + (rand.nextDouble() - 0.5) * 60,
            ));
          }
        }
        break;
      case 'random':
        for (int i = 0; i < 60; i++) {
          _points.add(Offset(
            30 + rand.nextDouble() * 290,
            30 + rand.nextDouble() * 220,
          ));
        }
        break;
      case 'circles':
        // 동심원 형태
        for (int i = 0; i < 30; i++) {
          final angle = rand.nextDouble() * 2 * math.pi;
          final r = 30 + rand.nextDouble() * 20;
          _points.add(Offset(
            175 + r * math.cos(angle),
            140 + r * math.sin(angle),
          ));
        }
        for (int i = 0; i < 30; i++) {
          final angle = rand.nextDouble() * 2 * math.pi;
          final r = 80 + rand.nextDouble() * 20;
          _points.add(Offset(
            175 + r * math.cos(angle),
            140 + r * math.sin(angle),
          ));
        }
        break;
      case 'moons':
        // 초승달 형태
        for (int i = 0; i < 30; i++) {
          final angle = rand.nextDouble() * math.pi;
          _points.add(Offset(
            100 + 60 * math.cos(angle) + rand.nextDouble() * 15,
            120 + 60 * math.sin(angle) + rand.nextDouble() * 15,
          ));
        }
        for (int i = 0; i < 30; i++) {
          final angle = rand.nextDouble() * math.pi;
          _points.add(Offset(
            160 + 60 * math.cos(angle + math.pi) + rand.nextDouble() * 15,
            160 + 60 * math.sin(angle + math.pi) + rand.nextDouble() * 15,
          ));
        }
        break;
    }

    _initCentroids();
  }

  void _initCentroids() {
    final rand = math.Random();
    _centroids = [];
    _assignments = List.filled(_points.length, -1);
    _iteration = 0;
    _isConverged = false;

    // 랜덤 초기 중심점
    final indices = List.generate(_points.length, (i) => i)..shuffle(rand);
    for (int i = 0; i < _k && i < _points.length; i++) {
      _centroids.add(_points[indices[i]]);
    }
  }

  void _step() {
    if (_isConverged) return;
    HapticFeedback.lightImpact();

    setState(() {
      // 1. 할당 단계: 각 점을 가장 가까운 중심점에 할당
      final newAssignments = <int>[];
      for (final point in _points) {
        double minDist = double.infinity;
        int closest = 0;
        for (int i = 0; i < _centroids.length; i++) {
          final dist = _distance(point, _centroids[i]);
          if (dist < minDist) {
            minDist = dist;
            closest = i;
          }
        }
        newAssignments.add(closest);
      }

      // 수렴 체크
      if (_listEquals(newAssignments, _assignments)) {
        _isConverged = true;
        HapticFeedback.heavyImpact();
        return;
      }

      _assignments = newAssignments;

      // 2. 업데이트 단계: 중심점 재계산
      for (int i = 0; i < _k; i++) {
        double sumX = 0, sumY = 0;
        int count = 0;
        for (int j = 0; j < _points.length; j++) {
          if (_assignments[j] == i) {
            sumX += _points[j].dx;
            sumY += _points[j].dy;
            count++;
          }
        }
        if (count > 0) {
          _centroids[i] = Offset(sumX / count, sumY / count);
        }
      }

      _iteration++;
    });
  }

  void _runToConvergence() {
    if (_isConverged) return;

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || _isConverged) return false;
      _step();
      return !_isConverged;
    });
  }

  double _distance(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _initCentroids();
    });
  }

  // 총 내부 분산 (Inertia) 계산
  double get _inertia {
    double sum = 0;
    for (int i = 0; i < _points.length; i++) {
      if (_assignments[i] >= 0 && _assignments[i] < _centroids.length) {
        final dist = _distance(_points[i], _centroids[_assignments[i]]);
        sum += dist * dist;
      }
    }
    return sum;
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
              'K-Means 클러스터링',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '머신러닝',
          title: 'K-Means 클러스터링',
          formula: 'argmin Σ||xᵢ - μₖ||²',
          formulaDescription: '비지도 학습으로 데이터를 K개 군집으로 분류',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: KMeansPainter(
                points: _points,
                centroids: _centroids,
                assignments: _assignments,
                colors: _clusterColors,
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
                    isSelected: _selectedPreset == 'blobs',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _generateData('blobs'));
                    },
                  ),
                  PresetButton(
                    label: '랜덤',
                    isSelected: _selectedPreset == 'random',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _generateData('random'));
                    },
                  ),
                  PresetButton(
                    label: '원형',
                    isSelected: _selectedPreset == 'circles',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _generateData('circles'));
                    },
                  ),
                  PresetButton(
                    label: '초승달',
                    isSelected: _selectedPreset == 'moons',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _generateData('moons'));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 상태 정보
              _ClusterInfo(
                iteration: _iteration,
                k: _k,
                inertia: _inertia,
                isConverged: _isConverged,
                pointCount: _points.length,
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: 'K (클러스터 수)',
                  value: _k.toDouble(),
                  min: 2,
                  max: 6,
                  defaultValue: 3,
                  formatValue: (v) => v.toInt().toString(),
                  onChanged: (v) {
                    setState(() {
                      _k = v.toInt();
                      _initCentroids();
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
                label: '1단계',
                icon: Icons.skip_next,
                isPrimary: true,
                onPressed: _isConverged ? null : _step,
              ),
              SimButton(
                label: '자동 실행',
                icon: Icons.fast_forward,
                onPressed: _isConverged ? null : _runToConvergence,
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

/// 클러스터 정보 위젯
class _ClusterInfo extends StatelessWidget {
  final int iteration;
  final int k;
  final double inertia;
  final bool isConverged;
  final int pointCount;

  const _ClusterInfo({
    required this.iteration,
    required this.k,
    required this.inertia,
    required this.isConverged,
    required this.pointCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConverged ? Colors.green.withValues(alpha: 0.5) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          if (isConverged)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    '수렴 완료!',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: '반복',
                  value: iteration.toString(),
                  icon: Icons.loop,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: 'K',
                  value: k.toString(),
                  icon: Icons.hub,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: 'Inertia',
                  value: inertia.toStringAsFixed(0),
                  icon: Icons.compress,
                  color: AppColors.accent2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: '데이터',
                  value: pointCount.toString(),
                  icon: Icons.scatter_plot,
                ),
              ),
            ],
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
  final Color? color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.muted;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, size: 12, color: chipColor),
          Text(
            label,
            style: TextStyle(
              color: chipColor.withValues(alpha: 0.7),
              fontSize: 9,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// K-Means 시각화 페인터
class KMeansPainter extends CustomPainter {
  final List<Offset> points;
  final List<Offset> centroids;
  final List<int> assignments;
  final List<Color> colors;

  KMeansPainter({
    required this.points,
    required this.centroids,
    required this.assignments,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // 데이터 포인트
    for (int i = 0; i < points.length; i++) {
      final color = assignments[i] >= 0 && assignments[i] < colors.length
          ? colors[assignments[i]]
          : AppColors.muted;

      canvas.drawCircle(
        points[i],
        6,
        Paint()..color = color.withValues(alpha: 0.7),
      );
    }

    // 중심점
    for (int i = 0; i < centroids.length; i++) {
      final color = i < colors.length ? colors[i] : AppColors.muted;

      // 글로우
      canvas.drawCircle(
        centroids[i],
        20,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // X 마커
      final cx = centroids[i].dx;
      final cy = centroids[i].dy;
      final markerPaint = Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(cx - 8, cy - 8), Offset(cx + 8, cy + 8), markerPaint);
      canvas.drawLine(Offset(cx + 8, cy - 8), Offset(cx - 8, cy + 8), markerPaint);

      // 테두리
      canvas.drawCircle(
        centroids[i],
        12,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant KMeansPainter oldDelegate) => true;
}
