import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 도르래 시스템 시뮬레이션
class PulleyScreen extends StatefulWidget {
  const PulleyScreen({super.key});

  @override
  State<PulleyScreen> createState() => _PulleyScreenState();
}

class _PulleyScreenState extends State<PulleyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int _pulleyCount = 2; // 도르래 개수
  double _load = 100; // 하중 (N)
  double _effort = 0; // 힘 (계산됨)
  bool _isRunning = false;

  double _position = 0; // 로프 당김 위치

  // 이상적 기계적 이점 = 도르래 개수
  double get _mechanicalAdvantage => _pulleyCount.toDouble();
  double get _requiredEffort => _load / _mechanicalAdvantage;
  double get _ropeDistance => _position * _mechanicalAdvantage;

  @override
  void initState() {
    super.initState();
    _effort = _requiredEffort;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update);
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      if (_effort >= _requiredEffort && _position < 1.0) {
        _position += 0.005;
      }
      if (_position >= 1.0) {
        _position = 1.0;
        _isRunning = false;
        _controller.stop();
      }
    });
  }

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = true;
      _controller.repeat();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = false;
      _position = 0;
      _controller.stop();
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
              '도르래 시스템',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '도르래 시스템',
          formula: 'MA = Load / Effort',
          formulaDescription: '도르래를 사용하면 필요한 힘은 줄지만 당기는 거리는 늘어남',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PulleyPainter(
                pulleyCount: _pulleyCount,
                position: _position,
                load: _load,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 정보
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '기계적 이점 MA = ',
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                        Text(
                          '$_pulleyCount',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '하중', value: '${_load.toInt()} N', color: Colors.red),
                        _InfoItem(label: '필요한 힘', value: '${_requiredEffort.toStringAsFixed(1)} N', color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '물체 이동', value: '${(_position * 100).toStringAsFixed(0)}%', color: Colors.blue),
                        _InfoItem(label: '로프 당김', value: '${(_ropeDistance * 100).toStringAsFixed(0)}%', color: Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 도르래 개수 선택
              PresetGroup(
                label: '도르래 개수',
                presets: [
                  PresetButton(
                    label: '1개',
                    isSelected: _pulleyCount == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _pulleyCount = 1;
                        _effort = _requiredEffort;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '2개',
                    isSelected: _pulleyCount == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _pulleyCount = 2;
                        _effort = _requiredEffort;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '3개',
                    isSelected: _pulleyCount == 3,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _pulleyCount = 3;
                        _effort = _requiredEffort;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '4개',
                    isSelected: _pulleyCount == 4,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _pulleyCount = 4;
                        _effort = _requiredEffort;
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '하중 (N)',
                  value: _load,
                  min: 50,
                  max: 200,
                  defaultValue: 100,
                  formatValue: (v) => '${v.toInt()} N',
                  onChanged: (v) {
                    setState(() {
                      _load = v;
                      _effort = _requiredEffort;
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
                label: _isRunning ? '정지' : '당기기',
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _isRunning ? _reset : _start,
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

class _PulleyPainter extends CustomPainter {
  final int pulleyCount;
  final double position;
  final double load;

  _PulleyPainter({required this.pulleyCount, required this.position, required this.load});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final pulleyRadius = 20.0;
    final topY = 40.0;
    final bottomY = size.height - 80;
    final loadDrop = position * (bottomY - topY - 100);

    // 천장
    canvas.drawLine(
      Offset(50, topY - 20),
      Offset(size.width - 50, topY - 20),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 4,
    );

    // 도르래들 배치
    if (pulleyCount == 1) {
      _drawSinglePulley(canvas, centerX, topY, pulleyRadius, loadDrop, bottomY);
    } else {
      _drawMultiplePulleys(canvas, centerX, topY, pulleyRadius, loadDrop, bottomY, size);
    }
  }

  void _drawSinglePulley(Canvas canvas, double centerX, double topY, double radius, double loadDrop, double bottomY) {
    // 고정 도르래
    _drawPulleyWheel(canvas, centerX, topY, radius);

    // 지지대
    canvas.drawLine(
      Offset(centerX, topY - 20),
      Offset(centerX, topY - radius),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 3,
    );

    // 로프 - 왼쪽 (하중)
    canvas.drawLine(
      Offset(centerX - radius, topY),
      Offset(centerX - radius, bottomY - loadDrop),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2,
    );

    // 로프 - 오른쪽 (당김)
    canvas.drawLine(
      Offset(centerX + radius, topY),
      Offset(centerX + radius, bottomY - 50 + loadDrop),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2,
    );

    // 하중
    _drawLoad(canvas, centerX - radius, bottomY - loadDrop);

    // 당김 표시
    _drawEffortArrow(canvas, centerX + radius, bottomY - 30);
  }

  void _drawMultiplePulleys(Canvas canvas, double centerX, double topY, double radius, double loadDrop, double bottomY, Size size) {
    final spacing = 60.0;
    final startX = centerX - spacing;
    final movableY = topY + 80 + loadDrop * 0.5;

    // 고정 도르래들 (상단)
    for (int i = 0; i < (pulleyCount / 2).ceil(); i++) {
      final x = startX + i * spacing;
      _drawPulleyWheel(canvas, x, topY, radius);
      canvas.drawLine(
        Offset(x, topY - 20),
        Offset(x, topY - radius),
        Paint()
          ..color = AppColors.muted
          ..strokeWidth = 3,
      );
    }

    // 움직이는 도르래들 (하단)
    for (int i = 0; i < (pulleyCount / 2).floor(); i++) {
      final x = startX + i * spacing + spacing / 2;
      _drawPulleyWheel(canvas, x, movableY, radius);
    }

    // 로프 (간략화)
    final ropeColor = AppColors.accent;
    final ropePaint = Paint()
      ..color = ropeColor
      ..strokeWidth = 2;

    // 지그재그 로프
    double lastX = startX - radius;
    double lastY = topY;
    for (int i = 0; i < pulleyCount; i++) {
      double nextX, nextY;
      if (i % 2 == 0) {
        nextX = startX + (i ~/ 2) * spacing;
        nextY = topY;
      } else {
        nextX = startX + (i ~/ 2) * spacing + spacing / 2;
        nextY = movableY;
      }
      canvas.drawLine(Offset(lastX, lastY), Offset(nextX - radius, nextY), ropePaint);
      lastX = nextX + radius;
      lastY = nextY;
    }

    // 하중
    _drawLoad(canvas, startX + spacing / 2 - 15, movableY + radius + 30);
  }

  void _drawPulleyWheel(Canvas canvas, double x, double y, double radius) {
    // 외곽
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()
        ..color = AppColors.muted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // 중심
    canvas.drawCircle(
      Offset(x, y),
      5,
      Paint()..color = AppColors.accent,
    );
  }

  void _drawLoad(Canvas canvas, double x, double y) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y + 20), width: 50, height: 40),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.red,
    );
    _drawText(canvas, '${load.toInt()}N', Offset(x - 15, y + 15), Colors.white);
  }

  void _drawEffortArrow(Canvas canvas, double x, double y) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3;

    canvas.drawLine(Offset(x, y), Offset(x, y + 40), paint);

    final path = Path()
      ..moveTo(x, y + 40)
      ..lineTo(x - 8, y + 30)
      ..lineTo(x + 8, y + 30)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.green);

    _drawText(canvas, 'F', Offset(x + 10, y + 20), Colors.green);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _PulleyPainter oldDelegate) {
    return oldDelegate.position != position || oldDelegate.pulleyCount != pulleyCount;
  }
}
