import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 공명 시뮬레이션
class ResonanceScreen extends StatefulWidget {
  const ResonanceScreen({super.key});

  @override
  State<ResonanceScreen> createState() => _ResonanceScreenState();
}

class _ResonanceScreenState extends State<ResonanceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _naturalFrequency = 2.0; // 고유 진동수 (Hz)
  double _drivingFrequency = 2.0; // 외력 진동수 (Hz)
  double _damping = 0.1; // 감쇠 계수
  bool _isRunning = true;

  double _time = 0;

  double get _frequencyRatio => _drivingFrequency / _naturalFrequency;
  double get _amplitude {
    final r = _frequencyRatio;
    final z = _damping;
    return 1 / math.sqrt(math.pow(1 - r * r, 2) + math.pow(2 * z * r, 2));
  }

  double get _phase {
    final r = _frequencyRatio;
    final z = _damping;
    return math.atan2(2 * z * r, 1 - r * r);
  }

  bool get _isResonance => (_frequencyRatio - 1).abs() < 0.1;

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
              '공명',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '공명 (Resonance)',
          formula: 'A = 1/√[(1-r²)² + (2ζr)²]',
          formulaDescription: '외력의 진동수가 고유 진동수와 같을 때 진폭이 최대',
          simulation: SizedBox(
            height: 350,
            child: Column(
              children: [
                // 진동자 시각화
                Expanded(
                  flex: 2,
                  child: CustomPaint(
                    painter: _OscillatorPainter(
                      displacement: _amplitude * 50 * math.sin(2 * math.pi * _drivingFrequency * _time - _phase),
                      isResonance: _isResonance,
                    ),
                    size: Size.infinite,
                  ),
                ),
                // 주파수 응답 곡선
                Expanded(
                  flex: 3,
                  child: CustomPaint(
                    painter: _FrequencyResponsePainter(
                      frequencyRatio: _frequencyRatio,
                      damping: _damping,
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
              // 상태 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isResonance ? Colors.red.withValues(alpha: 0.1) : AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isResonance ? Colors.red : AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isResonance ? '🔴 공명 상태!' : '일반 진동',
                          style: TextStyle(
                            color: _isResonance ? Colors.red : AppColors.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'r = ${_frequencyRatio.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.muted, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '고유 진동수', value: '${_naturalFrequency.toStringAsFixed(1)} Hz', color: Colors.blue),
                        _InfoItem(label: '외력 진동수', value: '${_drivingFrequency.toStringAsFixed(1)} Hz', color: Colors.orange),
                        _InfoItem(label: '증폭 비율', value: '${_amplitude.toStringAsFixed(1)}x', color: AppColors.accent),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '외력 진동수 f (Hz)',
                  value: _drivingFrequency,
                  min: 0.5,
                  max: 4.0,
                  defaultValue: 2.0,
                  formatValue: (v) => '${v.toStringAsFixed(2)} Hz',
                  onChanged: (v) => setState(() => _drivingFrequency = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '고유 진동수 f₀ (Hz)',
                    value: _naturalFrequency,
                    min: 1.0,
                    max: 3.0,
                    defaultValue: 2.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)} Hz',
                    onChanged: (v) => setState(() => _naturalFrequency = v),
                  ),
                  SimSlider(
                    label: '감쇠 계수 ζ',
                    value: _damping,
                    min: 0.01,
                    max: 0.5,
                    defaultValue: 0.1,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _damping = v),
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
                label: '공명 맞추기',
                icon: Icons.tune,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _drivingFrequency = _naturalFrequency);
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

class _OscillatorPainter extends CustomPainter {
  final double displacement;
  final bool isResonance;

  _OscillatorPainter({required this.displacement, required this.isResonance});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 평형선
    canvas.drawLine(
      Offset(20, centerY),
      Offset(size.width - 20, centerY),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // 외력 표시 (사인파 화살표)
    final forceArrow = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(30, centerY),
      Offset(30, centerY - displacement * 0.5),
      forceArrow,
    );

    // 물체
    final objectY = centerY + displacement;
    canvas.drawCircle(
      Offset(centerX, objectY),
      20,
      Paint()..color = isResonance ? Colors.red : AppColors.accent,
    );

    // 공명 시 글로우
    if (isResonance) {
      canvas.drawCircle(
        Offset(centerX, objectY),
        30,
        Paint()..color = Colors.red.withValues(alpha: 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OscillatorPainter oldDelegate) {
    return oldDelegate.displacement != displacement;
  }
}

class _FrequencyResponsePainter extends CustomPainter {
  final double frequencyRatio;
  final double damping;

  _FrequencyResponsePainter({required this.frequencyRatio, required this.damping});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.card);

    final padding = 30.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 축
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );

    // 주파수 응답 곡선
    final path = Path();
    final maxAmplitude = 10.0;

    for (double x = 0; x < graphWidth; x += 2) {
      final r = x / graphWidth * 3; // 0 ~ 3
      final z = damping;
      final amp = 1 / math.sqrt(math.pow(1 - r * r, 2) + math.pow(2 * z * r, 2));
      final normalizedAmp = (amp / maxAmplitude).clamp(0.0, 1.0);
      final y = size.height - padding - normalizedAmp * graphHeight;

      if (x == 0) {
        path.moveTo(padding + x, y);
      } else {
        path.lineTo(padding + x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 현재 위치 마커
    final markerX = padding + (frequencyRatio / 3) * graphWidth;
    final r = frequencyRatio;
    final amp = 1 / math.sqrt(math.pow(1 - r * r, 2) + math.pow(2 * damping * r, 2));
    final normalizedAmp = (amp / maxAmplitude).clamp(0.0, 1.0);
    final markerY = size.height - padding - normalizedAmp * graphHeight;

    canvas.drawCircle(
      Offset(markerX, markerY),
      6,
      Paint()..color = Colors.red,
    );

    // r=1 (공명) 라인
    final resonanceX = padding + graphWidth / 3;
    canvas.drawLine(
      Offset(resonanceX, padding),
      Offset(resonanceX, size.height - padding),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    // 라벨
    _drawText(canvas, 'A', Offset(padding - 15, padding), AppColors.muted, fontSize: 10);
    _drawText(canvas, 'r = f/f₀', Offset(size.width - padding - 30, size.height - padding + 5), AppColors.muted, fontSize: 10);
    _drawText(canvas, '1', Offset(resonanceX - 3, size.height - padding + 5), Colors.red, fontSize: 10);
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
  bool shouldRepaint(covariant _FrequencyResponsePainter oldDelegate) {
    return oldDelegate.frequencyRatio != frequencyRatio || oldDelegate.damping != damping;
  }
}
