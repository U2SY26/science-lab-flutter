import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 소리 맥놀이 시뮬레이션
class BeatsScreen extends StatefulWidget {
  const BeatsScreen({super.key});

  @override
  State<BeatsScreen> createState() => _BeatsScreenState();
}

class _BeatsScreenState extends State<BeatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _freq1 = 440; // 주파수 1 (Hz)
  double _freq2 = 444; // 주파수 2 (Hz)
  bool _isRunning = true;

  double _time = 0;

  double get _beatFrequency => (_freq1 - _freq2).abs();
  double get _averageFrequency => (_freq1 + _freq2) / 2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!_isRunning) return;
    setState(() {
      _time += 0.016;
      if (_time > 10) _time = 0;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
    });
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
              '물리학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '소리 맥놀이',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '소리 맥놀이 (Beats)',
          formula: 'f_beat = |f₁ - f₂|',
          formulaDescription: '비슷한 두 진동수의 파동이 간섭하여 생기는 진폭 변화',
          simulation: SizedBox(
            height: 400,
            child: CustomPaint(
              painter: _BeatsPainter(
                freq1: _freq1,
                freq2: _freq2,
                time: _time,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 정보
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
                        _InfoItem(label: '주파수 1', value: '${_freq1.toInt()} Hz', color: Colors.blue),
                        _InfoItem(label: '주파수 2', value: '${_freq2.toInt()} Hz', color: Colors.red),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '맥놀이 진동수', value: '${_beatFrequency.toStringAsFixed(1)} Hz', color: AppColors.accent),
                        _InfoItem(label: '평균 진동수', value: '${_averageFrequency.toStringAsFixed(0)} Hz', color: Colors.green),
                      ],
                    ),
                  ],
                ),
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '맥놀이란?',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '비슷한 진동수의 두 음파가 중첩되면 보강/상쇄 간섭이 반복되어 음량이 규칙적으로 변합니다. 악기 조율에 활용됩니다.',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 프리셋
              PresetGroup(
                label: '예시',
                presets: [
                  PresetButton(
                    label: '느린 맥놀이',
                    isSelected: _beatFrequency < 3,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _freq1 = 440;
                        _freq2 = 442;
                      });
                    },
                  ),
                  PresetButton(
                    label: '보통',
                    isSelected: _beatFrequency >= 3 && _beatFrequency <= 8,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _freq1 = 440;
                        _freq2 = 445;
                      });
                    },
                  ),
                  PresetButton(
                    label: '빠른 맥놀이',
                    isSelected: _beatFrequency > 8,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _freq1 = 440;
                        _freq2 = 450;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '주파수 1 (Hz)',
                  value: _freq1,
                  min: 400,
                  max: 480,
                  defaultValue: 440,
                  formatValue: (v) => '${v.toInt()} Hz',
                  onChanged: (v) => setState(() => _freq1 = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '주파수 2 (Hz)',
                    value: _freq2,
                    min: 400,
                    max: 480,
                    defaultValue: 444,
                    formatValue: (v) => '${v.toInt()} Hz',
                    onChanged: (v) => setState(() => _freq2 = v),
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
                label: '동기화',
                icon: Icons.sync,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _freq2 = _freq1);
                },
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

class _BeatsPainter extends CustomPainter {
  final double freq1;
  final double freq2;
  final double time;

  _BeatsPainter({required this.freq1, required this.freq2, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 20.0;
    final graphWidth = size.width - padding * 2;
    final sectionHeight = (size.height - padding * 3) / 3;

    // 스케일 조정 (주파수를 시각화에 맞게)
    final displayFreq1 = freq1 / 50;
    final displayFreq2 = freq2 / 50;

    // 파동 1
    _drawSection(canvas, padding, padding, graphWidth, sectionHeight, displayFreq1, Colors.blue, '파동 1');

    // 파동 2
    _drawSection(canvas, padding, padding + sectionHeight + padding / 2, graphWidth, sectionHeight, displayFreq2, Colors.red, '파동 2');

    // 합성파 (맥놀이)
    _drawCombinedWave(canvas, padding, padding + (sectionHeight + padding / 2) * 2, graphWidth, sectionHeight, displayFreq1, displayFreq2);
  }

  void _drawSection(Canvas canvas, double x, double y, double width, double height, double freq, Color color, String label) {
    // 배경
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, height),
      Paint()..color = AppColors.card,
    );

    // 중심선
    canvas.drawLine(
      Offset(x, y + height / 2),
      Offset(x + width, y + height / 2),
      Paint()..color = AppColors.muted.withValues(alpha: 0.3),
    );

    // 파동
    final path = Path();
    final amplitude = height * 0.4;

    for (double px = 0; px < width; px += 2) {
      final t = time + px / 100;
      final value = math.sin(2 * math.pi * freq * t);
      final py = y + height / 2 - value * amplitude;

      if (px == 0) {
        path.moveTo(x + px, py);
      } else {
        path.lineTo(x + px, py);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 라벨
    _drawText(canvas, label, Offset(x + 5, y + 5), color);
  }

  void _drawCombinedWave(Canvas canvas, double x, double y, double width, double height, double freq1, double freq2) {
    // 배경
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, height),
      Paint()..color = AppColors.card,
    );

    // 중심선
    canvas.drawLine(
      Offset(x, y + height / 2),
      Offset(x + width, y + height / 2),
      Paint()..color = AppColors.muted.withValues(alpha: 0.3),
    );

    // 맥놀이 포락선
    final beatFreq = (freq1 - freq2).abs();
    final envelopePath = Path();
    final envelopePathNeg = Path();
    final amplitude = height * 0.4;

    for (double px = 0; px < width; px += 2) {
      final t = time + px / 100;
      final envelope = (math.cos(math.pi * beatFreq * t)).abs();
      final envY = envelope * amplitude;

      if (px == 0) {
        envelopePath.moveTo(x + px, y + height / 2 - envY);
        envelopePathNeg.moveTo(x + px, y + height / 2 + envY);
      } else {
        envelopePath.lineTo(x + px, y + height / 2 - envY);
        envelopePathNeg.lineTo(x + px, y + height / 2 + envY);
      }
    }

    canvas.drawPath(envelopePath, Paint()..color = Colors.green.withValues(alpha: 0.3)..strokeWidth = 1..style = PaintingStyle.stroke);
    canvas.drawPath(envelopePathNeg, Paint()..color = Colors.green.withValues(alpha: 0.3)..strokeWidth = 1..style = PaintingStyle.stroke);

    // 합성파
    final path = Path();
    for (double px = 0; px < width; px += 2) {
      final t = time + px / 100;
      final wave1 = math.sin(2 * math.pi * freq1 * t);
      final wave2 = math.sin(2 * math.pi * freq2 * t);
      final combined = (wave1 + wave2) / 2;
      final py = y + height / 2 - combined * amplitude;

      if (px == 0) {
        path.moveTo(x + px, py);
      } else {
        path.lineTo(x + px, py);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 라벨
    _drawText(canvas, '합성파 (맥놀이)', Offset(x + 5, y + 5), AppColors.accent);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _BeatsPainter oldDelegate) => true;
}
