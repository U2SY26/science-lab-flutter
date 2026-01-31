import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 중심극한정리 시뮬레이션
class CentralLimitScreen extends StatefulWidget {
  const CentralLimitScreen({super.key});

  @override
  State<CentralLimitScreen> createState() => _CentralLimitScreenState();
}

class _CentralLimitScreenState extends State<CentralLimitScreen> {
  final _random = math.Random();
  List<double> _sampleMeans = [];
  int _sampleSize = 5;
  String _distribution = 'uniform';
  bool _isRunning = false;

  double get _mean {
    if (_sampleMeans.isEmpty) return 0;
    return _sampleMeans.reduce((a, b) => a + b) / _sampleMeans.length;
  }

  double get _stdDev {
    if (_sampleMeans.length < 2) return 0;
    final m = _mean;
    final variance = _sampleMeans.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / _sampleMeans.length;
    return math.sqrt(variance);
  }

  double _generateSample() {
    switch (_distribution) {
      case 'uniform':
        return _random.nextDouble();
      case 'exponential':
        return -math.log(1 - _random.nextDouble());
      case 'dice':
        return (_random.nextInt(6) + 1).toDouble();
      default:
        return _random.nextDouble();
    }
  }

  void _addSample() {
    double sum = 0;
    for (int i = 0; i < _sampleSize; i++) {
      sum += _generateSample();
    }
    _sampleMeans.add(sum / _sampleSize);

    if (_sampleMeans.length > 1000) {
      _sampleMeans.removeAt(0);
    }
  }

  void _start() {
    HapticFeedback.mediumImpact();
    _isRunning = true;
    _runSimulation();
  }

  void _runSimulation() async {
    while (_isRunning && mounted) {
      setState(() {
        for (int i = 0; i < 10; i++) {
          _addSample();
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _stop() {
    _isRunning = false;
    setState(() {});
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _isRunning = false;
    _sampleMeans = [];
    setState(() {});
  }

  @override
  void dispose() {
    _isRunning = false;
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
              '수학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '중심극한정리',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '중심극한정리 (CLT)',
          formula: 'X̄ ~ N(μ, σ²/n)',
          formulaDescription: '표본평균은 정규분포로 수렴',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _CentralLimitPainter(sampleMeans: _sampleMeans),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 통계량
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
                    _InfoItem(label: '표본 수', value: '${_sampleMeans.length}', color: AppColors.ink),
                    _InfoItem(label: '평균', value: _mean.toStringAsFixed(3), color: Colors.blue),
                    _InfoItem(label: '표준편차', value: _stdDev.toStringAsFixed(3), color: Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 분포 선택
              PresetGroup(
                label: '원래 분포',
                presets: [
                  PresetButton(
                    label: '균등분포',
                    isSelected: _distribution == 'uniform',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _distribution = 'uniform';
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '지수분포',
                    isSelected: _distribution == 'exponential',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _distribution = 'exponential';
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '주사위',
                    isSelected: _distribution == 'dice',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _distribution = 'dice';
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 설명
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Text(
                  '어떤 분포든 표본평균을 많이 모으면 정규분포(종 모양)가 됩니다. 표본 크기(n)가 클수록 더 빨리 수렴합니다.',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '표본 크기 (n)',
                  value: _sampleSize.toDouble(),
                  min: 2,
                  max: 30,
                  defaultValue: 5,
                  formatValue: (v) => '${v.toInt()}개',
                  onChanged: (v) {
                    setState(() {
                      _sampleSize = v.toInt();
                      _reset();
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
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }
}

class _CentralLimitPainter extends CustomPainter {
  final List<double> sampleMeans;

  _CentralLimitPainter({required this.sampleMeans});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (sampleMeans.isEmpty) {
      _drawText(canvas, '시작을 눌러 시뮬레이션', Offset(size.width / 2 - 80, size.height / 2), AppColors.muted);
      return;
    }

    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 히스토그램 생성
    final bins = 30;
    final minVal = sampleMeans.reduce(math.min);
    final maxVal = sampleMeans.reduce(math.max);
    final range = maxVal - minVal;
    final binWidth = range / bins;

    final histogram = List<int>.filled(bins, 0);
    for (var value in sampleMeans) {
      final binIndex = ((value - minVal) / binWidth).floor().clamp(0, bins - 1);
      histogram[binIndex]++;
    }

    final maxCount = histogram.reduce(math.max);

    // 축
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      Paint()..color = AppColors.muted,
    );
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      Paint()..color = AppColors.muted,
    );

    // 히스토그램 막대
    final barWidth = graphWidth / bins;
    for (int i = 0; i < bins; i++) {
      final barHeight = maxCount > 0 ? (histogram[i] / maxCount) * graphHeight : 0;
      final x = padding + i * barWidth;
      final y = size.height - padding - barHeight;

      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth - 1, barHeight.toDouble()),
        Paint()..color = Colors.blue.withValues(alpha: 0.7),
      );
    }

    // 정규분포 곡선 (비교용)
    if (sampleMeans.length > 10) {
      final mean = sampleMeans.reduce((a, b) => a + b) / sampleMeans.length;
      final variance = sampleMeans.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / sampleMeans.length;
      final stdDev = math.sqrt(variance);

      final normalPath = Path();
      for (double px = 0; px <= graphWidth; px += 2) {
        final x = minVal + (px / graphWidth) * range;
        final z = (x - mean) / stdDev;
        final pdf = math.exp(-0.5 * z * z) / (stdDev * math.sqrt(2 * math.pi));

        // 스케일 조정
        final scaledPdf = pdf * sampleMeans.length * binWidth;
        final y = size.height - padding - (scaledPdf / maxCount) * graphHeight;

        if (px == 0) {
          normalPath.moveTo(padding + px, y.clamp(padding, size.height - padding));
        } else {
          normalPath.lineTo(padding + px, y.clamp(padding, size.height - padding));
        }
      }

      canvas.drawPath(
        normalPath,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // 범례
    canvas.drawRect(Rect.fromLTWH(size.width - 80, 15, 15, 10), Paint()..color = Colors.blue);
    _drawText(canvas, '표본평균', Offset(size.width - 60, 12), Colors.blue, fontSize: 10);

    canvas.drawLine(Offset(size.width - 80, 35), Offset(size.width - 65, 35), Paint()..color = Colors.red..strokeWidth = 2);
    _drawText(canvas, '정규분포', Offset(size.width - 60, 29), Colors.red, fontSize: 10);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _CentralLimitPainter oldDelegate) => true;
}
