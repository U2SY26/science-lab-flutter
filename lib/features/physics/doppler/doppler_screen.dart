import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 도플러 효과 시뮬레이션
class DopplerScreen extends StatefulWidget {
  const DopplerScreen({super.key});

  @override
  State<DopplerScreen> createState() => _DopplerScreenState();
}

class _DopplerScreenState extends State<DopplerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _sourceSpeed = 50; // m/s
  double _sourceFrequency = 440; // Hz (A4 note)
  static const double _soundSpeed = 343; // m/s at 20°C

  double _sourcePosition = 0;
  bool _isRunning = true;

  double get _approachingFrequency {
    if (_sourceSpeed >= _soundSpeed) return double.infinity;
    return _sourceFrequency * _soundSpeed / (_soundSpeed - _sourceSpeed);
  }

  double get _recedingFrequency {
    return _sourceFrequency * _soundSpeed / (_soundSpeed + _sourceSpeed);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!_isRunning) return;
    setState(() {
      _sourcePosition = (_controller.value * 2 - 1); // -1 to 1
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
              '도플러 효과',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '도플러 효과',
          formula: "f' = f × v/(v ± vₛ)",
          formulaDescription: '음원이 움직일 때 관측되는 주파수 변화',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DopplerPainter(
                sourcePosition: _sourcePosition,
                sourceSpeed: _sourceSpeed,
                soundSpeed: _soundSpeed,
                time: _controller.value,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 주파수 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _FreqBox(
                        label: '접근 시',
                        frequency: _approachingFrequency,
                        color: Colors.red,
                        icon: Icons.arrow_back,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          const Text(
                            '원래 주파수',
                            style: TextStyle(color: AppColors.muted, fontSize: 10),
                          ),
                          Text(
                            '${_sourceFrequency.toInt()} Hz',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _FreqBox(
                        label: '멀어질 시',
                        frequency: _recedingFrequency,
                        color: Colors.blue,
                        icon: Icons.arrow_forward,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '음원 속도 (m/s)',
                  value: _sourceSpeed,
                  min: 0,
                  max: 300,
                  defaultValue: 50,
                  formatValue: (v) => '${v.toInt()} m/s (${(v / _soundSpeed * 100).toStringAsFixed(0)}% 음속)',
                  onChanged: (v) => setState(() => _sourceSpeed = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '음원 주파수 (Hz)',
                    value: _sourceFrequency,
                    min: 100,
                    max: 1000,
                    defaultValue: 440,
                    formatValue: (v) => '${v.toInt()} Hz',
                    onChanged: (v) => setState(() => _sourceFrequency = v),
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
                label: '저속',
                icon: Icons.directions_walk,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sourceSpeed = 30);
                },
              ),
              SimButton(
                label: '고속',
                icon: Icons.directions_car,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sourceSpeed = 150);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreqBox extends StatelessWidget {
  final String label;
  final double frequency;
  final Color color;
  final IconData icon;

  const _FreqBox({
    required this.label,
    required this.frequency,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            frequency.isFinite ? '${frequency.toInt()} Hz' : '∞',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DopplerPainter extends CustomPainter {
  final double sourcePosition;
  final double sourceSpeed;
  final double soundSpeed;
  final double time;

  _DopplerPainter({
    required this.sourcePosition,
    required this.sourceSpeed,
    required this.soundSpeed,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    final centerY = size.height / 2;
    final sourceX = size.width / 2 + sourcePosition * (size.width / 2 - 60);

    // 파동 (동심원)
    final waveCount = 8;
    for (int i = 0; i < waveCount; i++) {
      final waveTime = (time + i / waveCount) % 1.0;
      final baseRadius = waveTime * size.width * 0.6;

      // 음원 이동에 따른 파동 중심 이동
      final emitPosition = sourceX - (waveTime * sourceSpeed / soundSpeed * size.width * 0.3);

      if (baseRadius > 5) {
        final wavePaint = Paint()
          ..color = AppColors.accent.withValues(alpha: 0.3 * (1 - waveTime))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(
          Offset(emitPosition, centerY),
          baseRadius,
          wavePaint,
        );
      }
    }

    // 음원 (차량/사이렌)
    canvas.drawCircle(
      Offset(sourceX, centerY),
      20,
      Paint()..color = Colors.red,
    );

    // 스피커 아이콘
    final speakerPath = Path()
      ..moveTo(sourceX - 8, centerY - 5)
      ..lineTo(sourceX - 4, centerY - 5)
      ..lineTo(sourceX + 4, centerY - 10)
      ..lineTo(sourceX + 4, centerY + 10)
      ..lineTo(sourceX - 4, centerY + 5)
      ..lineTo(sourceX - 8, centerY + 5)
      ..close();

    canvas.drawPath(speakerPath, Paint()..color = Colors.white);

    // 이동 방향 화살표
    _drawArrow(
      canvas,
      Offset(sourceX + 30, centerY),
      Offset(sourceX + 60, centerY),
      Colors.red,
    );

    // 관찰자 (좌우)
    _drawObserver(canvas, Offset(40, centerY), '접근', Colors.red);
    _drawObserver(canvas, Offset(size.width - 40, centerY), '멀어짐', Colors.blue);

    // 파장 표시
    _drawText(
      canvas,
      '짧은 파장 (높은 음)',
      Offset(20, size.height - 40),
      Colors.red,
      fontSize: 11,
    );
    _drawText(
      canvas,
      '긴 파장 (낮은 음)',
      Offset(size.width - 110, size.height - 40),
      Colors.blue,
      fontSize: 11,
    );
  }

  void _drawObserver(Canvas canvas, Offset pos, String label, Color color) {
    // 사람 아이콘
    canvas.drawCircle(pos, 8, Paint()..color = color);
    canvas.drawLine(
      Offset(pos.dx, pos.dy + 10),
      Offset(pos.dx, pos.dy + 25),
      Paint()
        ..color = color
        ..strokeWidth = 3,
    );

    _drawText(canvas, label, Offset(pos.dx - 15, pos.dy + 30), color, fontSize: 10);
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    canvas.drawLine(start, end, paint);

    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowSize = 8.0;

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle - math.pi / 6),
        end.dy - arrowSize * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        end.dx - arrowSize * math.cos(angle + math.pi / 6),
        end.dy - arrowSize * math.sin(angle + math.pi / 6),
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _DopplerPainter oldDelegate) {
    return oldDelegate.sourcePosition != sourcePosition || oldDelegate.time != time;
  }
}
