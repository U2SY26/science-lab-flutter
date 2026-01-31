import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 감쇠 진동자 시뮬레이션
class DampedOscillatorScreen extends StatefulWidget {
  const DampedOscillatorScreen({super.key});

  @override
  State<DampedOscillatorScreen> createState() => _DampedOscillatorScreenState();
}

class _DampedOscillatorScreenState extends State<DampedOscillatorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _dampingRatio = 0.1; // 감쇠비 (ζ)
  double _naturalFrequency = 2.0; // 고유진동수 (ω₀)
  double _initialAmplitude = 100;
  bool _isRunning = true;

  double _time = 0;
  List<Offset> _trajectory = [];

  // 감쇠 유형
  String get _dampingType {
    if (_dampingRatio < 1) return '과소감쇠 (Underdamped)';
    if (_dampingRatio == 1) return '임계감쇠 (Critical)';
    return '과대감쇠 (Overdamped)';
  }

  double get _dampedFrequency {
    if (_dampingRatio >= 1) return 0;
    return _naturalFrequency * math.sqrt(1 - _dampingRatio * _dampingRatio);
  }

  double _getDisplacement(double t) {
    if (_dampingRatio < 1) {
      // 과소감쇠
      return _initialAmplitude *
          math.exp(-_dampingRatio * _naturalFrequency * t) *
          math.cos(_dampedFrequency * t);
    } else if (_dampingRatio == 1) {
      // 임계감쇠
      return _initialAmplitude * (1 + _naturalFrequency * t) * math.exp(-_naturalFrequency * t);
    } else {
      // 과대감쇠
      final r1 = -_naturalFrequency * (_dampingRatio + math.sqrt(_dampingRatio * _dampingRatio - 1));
      final r2 = -_naturalFrequency * (_dampingRatio - math.sqrt(_dampingRatio * _dampingRatio - 1));
      return _initialAmplitude * 0.5 * (math.exp(r1 * t) + math.exp(r2 * t));
    }
  }

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
      final displacement = _getDisplacement(_time);
      _trajectory.add(Offset(_time * 30, displacement));

      if (_trajectory.length > 500) {
        _trajectory.removeAt(0);
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _trajectory.clear();
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
              '감쇠 진동자',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '감쇠 진동자',
          formula: "x(t) = A₀e^(-ζω₀t)cos(ω_d t)",
          formulaDescription: '마찰이나 저항에 의해 진폭이 감소하는 진동',
          simulation: SizedBox(
            height: 350,
            child: Column(
              children: [
                // 진동자 시각화
                Expanded(
                  flex: 2,
                  child: CustomPaint(
                    painter: _OscillatorPainter(
                      displacement: _getDisplacement(_time),
                      maxAmplitude: _initialAmplitude,
                    ),
                    size: Size.infinite,
                  ),
                ),
                // 그래프
                Expanded(
                  flex: 3,
                  child: CustomPaint(
                    painter: _GraphPainter(
                      trajectory: _trajectory,
                      maxAmplitude: _initialAmplitude,
                      dampingRatio: _dampingRatio,
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
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dampingType,
                          style: TextStyle(
                            color: _dampingRatio < 1
                                ? Colors.blue
                                : _dampingRatio == 1
                                    ? Colors.green
                                    : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          't = ${_time.toStringAsFixed(2)} s',
                          style: const TextStyle(color: AppColors.muted, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '감쇠비 ζ', value: _dampingRatio.toStringAsFixed(2), color: AppColors.accent),
                        _InfoItem(label: 'ω₀', value: '${_naturalFrequency.toStringAsFixed(1)} rad/s', color: Colors.orange),
                        if (_dampingRatio < 1)
                          _InfoItem(label: 'ω_d', value: '${_dampedFrequency.toStringAsFixed(2)} rad/s', color: Colors.cyan),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 프리셋
              PresetGroup(
                label: '감쇠 유형',
                presets: [
                  PresetButton(
                    label: '과소감쇠',
                    isSelected: _dampingRatio < 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _dampingRatio = 0.1;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '임계감쇠',
                    isSelected: _dampingRatio == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _dampingRatio = 1.0;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '과대감쇠',
                    isSelected: _dampingRatio > 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _dampingRatio = 2.0;
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '감쇠비 (ζ)',
                  value: _dampingRatio,
                  min: 0.01,
                  max: 3.0,
                  defaultValue: 0.1,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() {
                      _dampingRatio = v;
                      _reset();
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '고유진동수 ω₀ (rad/s)',
                    value: _naturalFrequency,
                    min: 0.5,
                    max: 5.0,
                    defaultValue: 2.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)} rad/s',
                    onChanged: (v) {
                      setState(() {
                        _naturalFrequency = v;
                        _reset();
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

class _OscillatorPainter extends CustomPainter {
  final double displacement;
  final double maxAmplitude;

  _OscillatorPainter({required this.displacement, required this.maxAmplitude});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 평형 위치 표시
    canvas.drawLine(
      Offset(centerX, 10),
      Offset(centerX, size.height - 10),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // 스프링
    final springTop = 10.0;
    final objectY = centerY + displacement * 0.5;
    _drawSpring(canvas, Offset(centerX, springTop), Offset(centerX, objectY - 20));

    // 물체
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, objectY), width: 40, height: 40),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.accent,
    );

    // 변위 라벨
    if (displacement.abs() > 5) {
      _drawText(canvas, 'x', Offset(centerX + 30, objectY - 5), AppColors.muted);
    }
  }

  void _drawSpring(Canvas canvas, Offset start, Offset end) {
    final path = Path();
    final coils = 10;
    final amplitude = 15.0;
    final length = end.dy - start.dy;
    final coilHeight = length / coils;

    path.moveTo(start.dx, start.dy);

    for (int i = 0; i < coils; i++) {
      final y1 = start.dy + i * coilHeight + coilHeight * 0.25;
      final y2 = start.dy + i * coilHeight + coilHeight * 0.75;

      path.lineTo(start.dx + amplitude, y1);
      path.lineTo(start.dx - amplitude, y2);
    }

    path.lineTo(end.dx, end.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 12)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _OscillatorPainter oldDelegate) {
    return oldDelegate.displacement != displacement;
  }
}

class _GraphPainter extends CustomPainter {
  final List<Offset> trajectory;
  final double maxAmplitude;
  final double dampingRatio;

  _GraphPainter({required this.trajectory, required this.maxAmplitude, required this.dampingRatio});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.card);

    final padding = 30.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;
    final centerY = padding + graphHeight / 2;

    // 축
    canvas.drawLine(
      Offset(padding, centerY),
      Offset(size.width - padding, centerY),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );

    // 포락선 (감쇠 곡선)
    if (dampingRatio < 1) {
      final envelopePath = Path();
      final envelopePathNeg = Path();

      for (double x = 0; x < graphWidth; x += 2) {
        final t = x / 30;
        final envelope = maxAmplitude * math.exp(-dampingRatio * 2.0 * t);
        final y = envelope * graphHeight / (maxAmplitude * 2.5);

        if (x == 0) {
          envelopePath.moveTo(padding + x, centerY - y);
          envelopePathNeg.moveTo(padding + x, centerY + y);
        } else {
          envelopePath.lineTo(padding + x, centerY - y);
          envelopePathNeg.lineTo(padding + x, centerY + y);
        }
      }

      canvas.drawPath(envelopePath, Paint()..color = Colors.red.withValues(alpha: 0.3)..strokeWidth = 1..style = PaintingStyle.stroke);
      canvas.drawPath(envelopePathNeg, Paint()..color = Colors.red.withValues(alpha: 0.3)..strokeWidth = 1..style = PaintingStyle.stroke);
    }

    // 궤적
    if (trajectory.length > 1) {
      final path = Path();
      final startX = trajectory.first.dx;

      for (int i = 0; i < trajectory.length; i++) {
        final x = padding + (trajectory[i].dx - startX);
        final y = centerY - trajectory[i].dy * graphHeight / (maxAmplitude * 2.5);

        if (x > padding && x < size.width - padding) {
          if (i == 0 || (padding + (trajectory[i - 1].dx - startX)) < padding) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.accent
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // 라벨
    _drawText(canvas, 'x(t)', Offset(padding - 25, centerY - 10), AppColors.muted, fontSize: 10);
    _drawText(canvas, 't', Offset(size.width - padding + 5, centerY - 5), AppColors.muted, fontSize: 10);
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
  bool shouldRepaint(covariant _GraphPainter oldDelegate) => true;
}
