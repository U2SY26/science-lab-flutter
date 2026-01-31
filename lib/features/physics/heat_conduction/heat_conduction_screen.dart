import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 열전도 시뮬레이션
class HeatConductionScreen extends StatefulWidget {
  const HeatConductionScreen({super.key});

  @override
  State<HeatConductionScreen> createState() => _HeatConductionScreenState();
}

class _HeatConductionScreenState extends State<HeatConductionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _leftTemp = 100; // 왼쪽 온도 (°C)
  double _rightTemp = 20; // 오른쪽 온도 (°C)
  double _conductivity = 0.5; // 열전도도 (상대값)
  String _material = '구리';
  bool _isRunning = true;

  List<double> _temperatures = [];
  static const int _segments = 20;

  final Map<String, double> _materials = {
    '구리': 1.0,
    '알루미늄': 0.6,
    '철': 0.2,
    '유리': 0.003,
    '나무': 0.0004,
  };

  @override
  void initState() {
    super.initState();
    _initTemperatures();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update);
    _controller.repeat();
  }

  void _initTemperatures() {
    _temperatures = List.generate(_segments, (i) {
      if (i == 0) return _leftTemp;
      if (i == _segments - 1) return _rightTemp;
      return (_leftTemp + _rightTemp) / 2;
    });
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      // 열전도 시뮬레이션 (유한 차분법)
      final newTemps = List<double>.from(_temperatures);
      final k = _conductivity * _materials[_material]!;

      for (int i = 1; i < _segments - 1; i++) {
        final diffusion = k * (_temperatures[i - 1] - 2 * _temperatures[i] + _temperatures[i + 1]);
        newTemps[i] = _temperatures[i] + diffusion * 0.5;
      }

      // 경계 조건 유지
      newTemps[0] = _leftTemp;
      newTemps[_segments - 1] = _rightTemp;

      _temperatures = newTemps;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _initTemperatures();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getTemperatureColor(double temp) {
    final normalized = ((temp - 0) / 120).clamp(0.0, 1.0);
    return Color.lerp(Colors.blue, Colors.red, normalized)!;
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
              '물리학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '열전도',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '열전도 (Heat Conduction)',
          formula: 'q = -k∇T',
          formulaDescription: '푸리에 법칙: 열은 온도가 높은 곳에서 낮은 곳으로 전달',
          simulation: SizedBox(
            height: 300,
            child: Column(
              children: [
                // 온도 막대
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: List.generate(_segments, (i) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: _getTemperatureColor(_temperatures[i]),
                              borderRadius: i == 0
                                  ? const BorderRadius.horizontal(left: Radius.circular(8))
                                  : i == _segments - 1
                                      ? const BorderRadius.horizontal(right: Radius.circular(8))
                                      : null,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                // 온도 그래프
                Expanded(
                  flex: 3,
                  child: CustomPaint(
                    painter: _TemperatureGraphPainter(
                      temperatures: _temperatures,
                      leftTemp: _leftTemp,
                      rightTemp: _rightTemp,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 재질 선택
              PresetGroup(
                label: '재질',
                presets: _materials.keys.map((mat) {
                  return PresetButton(
                    label: mat,
                    isSelected: _material == mat,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _material = mat;
                        _reset();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 열전도도 표시
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
                    _InfoItem(label: '왼쪽 온도', value: '${_leftTemp.toInt()}°C', color: Colors.red),
                    _InfoItem(label: '열전도도', value: '${(_materials[_material]! * 100).toStringAsFixed(1)}%', color: AppColors.accent),
                    _InfoItem(label: '오른쪽 온도', value: '${_rightTemp.toInt()}°C', color: Colors.blue),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '왼쪽 온도 (°C)',
                  value: _leftTemp,
                  min: 0,
                  max: 120,
                  defaultValue: 100,
                  formatValue: (v) => '${v.toInt()}°C',
                  onChanged: (v) {
                    setState(() {
                      _leftTemp = v;
                      _temperatures[0] = v;
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '오른쪽 온도 (°C)',
                    value: _rightTemp,
                    min: 0,
                    max: 120,
                    defaultValue: 20,
                    formatValue: (v) => '${v.toInt()}°C',
                    onChanged: (v) {
                      setState(() {
                        _rightTemp = v;
                        _temperatures[_segments - 1] = v;
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
                label: _isRunning ? '정지' : '재생',
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isRunning = !_isRunning);
                },
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
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TemperatureGraphPainter extends CustomPainter {
  final List<double> temperatures;
  final double leftTemp;
  final double rightTemp;

  _TemperatureGraphPainter({
    required this.temperatures,
    required this.leftTemp,
    required this.rightTemp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.card);

    final padding = 30.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 축
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );

    // 온도 곡선
    final path = Path();
    final maxTemp = math.max(leftTemp, rightTemp) + 10;

    for (int i = 0; i < temperatures.length; i++) {
      final x = padding + (i / (temperatures.length - 1)) * graphWidth;
      final y = size.height - padding - (temperatures[i] / maxTemp) * graphHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.red, Colors.blue],
        ).createShader(Rect.fromLTWH(padding, 0, graphWidth, 1))
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    // 라벨
    _drawText(canvas, 'T(°C)', Offset(padding - 25, padding - 10), AppColors.muted, fontSize: 10);
    _drawText(canvas, 'x', Offset(size.width - padding + 5, size.height - padding + 5), AppColors.muted, fontSize: 10);
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
  bool shouldRepaint(covariant _TemperatureGraphPainter oldDelegate) => true;
}
