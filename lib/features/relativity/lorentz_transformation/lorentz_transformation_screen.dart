import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Lorentz Transformation Simulation
class LorentzTransformationScreen extends StatefulWidget {
  const LorentzTransformationScreen({super.key});

  @override
  State<LorentzTransformationScreen> createState() => _LorentzTransformationScreenState();
}

class _LorentzTransformationScreenState extends State<LorentzTransformationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _velocity = 0.5; // v/c (fraction of speed of light)
  double _time = 0.0;
  bool _isAnimating = true;
  double _animationSpeed = 1.0;
  bool _showGrid = true;
  bool _showEvents = true;
  bool _isKorean = true;

  // Sample events in spacetime
  final List<Map<String, double>> _events = [
    {'x': 0.0, 't': 0.0},
    {'x': 0.5, 't': 0.3},
    {'x': -0.3, 't': 0.6},
    {'x': 0.2, 't': -0.4},
    {'x': -0.6, 't': 0.2},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _updateAnimation() {
    if (!_isAnimating) return;
    setState(() {
      _time += 0.01 * _animationSpeed;
      if (_time >= 2 * math.pi) _time -= 2 * math.pi;
    });
  }

  // Lorentz factor
  double get _gamma => 1 / math.sqrt(1 - _velocity * _velocity);

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _velocity = 0.5;
      _time = 0;
      _isAnimating = true;
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
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKorean ? '상대성이론 시뮬레이션' : 'RELATIVITY SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '로렌츠 변환' : 'Lorentz Transformation',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => _isKorean = !_isKorean),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: _isKorean ? '상대성이론 시뮬레이션' : 'RELATIVITY SIMULATION',
          title: _isKorean ? '로렌츠 변환' : 'Lorentz Transformation',
          formula: "x' = γ(x - vt), t' = γ(t - vx/c²)",
          formulaDescription: _isKorean
              ? '로렌츠 변환은 서로 다른 관성 좌표계 사이의 시공간 좌표를 변환합니다. 빛의 속도에 가까워질수록 시간 지연과 길이 수축이 발생합니다.'
              : 'Lorentz transformation converts spacetime coordinates between inertial reference frames. Near light speed, time dilation and length contraction occur.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: LorentzTransformationPainter(
                velocity: _velocity,
                gamma: _gamma,
                time: _time,
                events: _events,
                showGrid: _showGrid,
                showEvents: _showEvents,
                isKorean: _isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: _isKorean ? '속도 (v/c)' : 'Velocity (v/c)',
                  value: _velocity,
                  min: 0,
                  max: 0.99,
                  defaultValue: 0.5,
                  formatValue: (v) => '${(v * 100).toStringAsFixed(0)}% c',
                  onChanged: (v) => setState(() => _velocity = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '애니메이션 속도' : 'Animation Speed',
                    value: _animationSpeed,
                    min: 0.5,
                    max: 2.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() => _animationSpeed = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '격자 표시' : 'Show Grid',
                    value: _showGrid,
                    onChanged: (v) => setState(() => _showGrid = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '사건 표시' : 'Show Events',
                    value: _showEvents,
                    onChanged: (v) => setState(() => _showEvents = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                velocity: _velocity,
                gamma: _gamma,
                isKorean: _isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isAnimating
                    ? (_isKorean ? '정지' : 'Pause')
                    : (_isKorean ? '재생' : 'Play'),
                icon: _isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isAnimating = !_isAnimating);
                },
              ),
              SimButton(
                label: _isKorean ? '리셋' : 'Reset',
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

class _InfoCard extends StatelessWidget {
  final double velocity;
  final double gamma;
  final bool isKorean;

  const _InfoCard({
    required this.velocity,
    required this.gamma,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    final timeDilation = gamma;
    final lengthContraction = 1 / gamma;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                isKorean ? '로렌츠 인자 γ' : 'Lorentz Factor γ',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                gamma.toStringAsFixed(3),
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer, size: 14, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                isKorean ? '시간 지연' : 'Time Dilation',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${timeDilation.toStringAsFixed(2)}x',
                style: const TextStyle(color: Colors.orange, fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.straighten, size: 14, color: Colors.cyan),
              const SizedBox(width: 8),
              Text(
                isKorean ? '길이 수축' : 'Length Contraction',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${(lengthContraction * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.cyan, fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LorentzTransformationPainter extends CustomPainter {
  final double velocity;
  final double gamma;
  final double time;
  final List<Map<String, double>> events;
  final bool showGrid;
  final bool showEvents;
  final bool isKorean;

  LorentzTransformationPainter({
    required this.velocity,
    required this.gamma,
    required this.time,
    required this.events,
    required this.showGrid,
    required this.showEvents,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = math.min(size.width, size.height) * 0.35;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0A0A1A),
    );

    // Draw rest frame grid
    if (showGrid) {
      _drawRestFrameGrid(canvas, centerX, centerY, scale);
    }

    // Draw moving frame (boosted) grid
    _drawBoostedGrid(canvas, centerX, centerY, scale);

    // Draw light cones
    _drawLightCones(canvas, centerX, centerY, scale);

    // Draw worldlines
    _drawWorldlines(canvas, centerX, centerY, scale);

    // Draw events
    if (showEvents) {
      _drawEvents(canvas, centerX, centerY, scale);
    }

    // Draw axes labels
    _drawAxesLabels(canvas, size, centerX, centerY, scale);
  }

  void _drawRestFrameGrid(Canvas canvas, double cx, double cy, double scale) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    // Vertical lines (constant x)
    for (double x = -1; x <= 1; x += 0.25) {
      canvas.drawLine(
        Offset(cx + x * scale, cy - scale),
        Offset(cx + x * scale, cy + scale),
        gridPaint,
      );
    }

    // Horizontal lines (constant t)
    for (double t = -1; t <= 1; t += 0.25) {
      canvas.drawLine(
        Offset(cx - scale, cy - t * scale),
        Offset(cx + scale, cy - t * scale),
        gridPaint,
      );
    }
  }

  void _drawBoostedGrid(Canvas canvas, double cx, double cy, double scale) {
    final boostedPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    // The boost angle (rapidity)
    final tanhV = velocity;
    final angle = math.atan(tanhV);

    // Draw boosted x' axis (tilted toward light cone)
    canvas.drawLine(
      Offset(cx - scale * math.cos(angle), cy + scale * math.sin(angle)),
      Offset(cx + scale * math.cos(angle), cy - scale * math.sin(angle)),
      boostedPaint,
    );

    // Draw boosted t' axis (tilted toward light cone)
    canvas.drawLine(
      Offset(cx - scale * math.sin(angle), cy + scale * math.cos(angle)),
      Offset(cx + scale * math.sin(angle), cy - scale * math.cos(angle)),
      boostedPaint,
    );

    // Draw boosted grid lines
    final boostedGridPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    for (double i = -0.75; i <= 0.75; i += 0.25) {
      if (i == 0) continue;

      // Lines of constant x'
      final startX = cx + i * scale * math.cos(angle) - scale * math.sin(angle);
      final startY = cy - i * scale * math.sin(angle) - scale * math.cos(angle);
      final endX = cx + i * scale * math.cos(angle) + scale * math.sin(angle);
      final endY = cy - i * scale * math.sin(angle) + scale * math.cos(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), boostedGridPaint);

      // Lines of constant t'
      final startX2 = cx + i * scale * math.sin(angle) - scale * math.cos(angle);
      final startY2 = cy - i * scale * math.cos(angle) + scale * math.sin(angle);
      final endX2 = cx + i * scale * math.sin(angle) + scale * math.cos(angle);
      final endY2 = cy - i * scale * math.cos(angle) - scale * math.sin(angle);
      canvas.drawLine(Offset(startX2, startY2), Offset(endX2, endY2), boostedGridPaint);
    }
  }

  void _drawLightCones(Canvas canvas, double cx, double cy, double scale) {
    final lightPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.5)
      ..strokeWidth = 2;

    // Future light cone (45 degree lines)
    canvas.drawLine(Offset(cx, cy), Offset(cx + scale, cy - scale), lightPaint);
    canvas.drawLine(Offset(cx, cy), Offset(cx - scale, cy - scale), lightPaint);

    // Past light cone
    canvas.drawLine(Offset(cx, cy), Offset(cx + scale, cy + scale), lightPaint);
    canvas.drawLine(Offset(cx, cy), Offset(cx - scale, cy + scale), lightPaint);
  }

  void _drawWorldlines(Canvas canvas, double cx, double cy, double scale) {
    // Rest observer worldline (vertical)
    canvas.drawLine(
      Offset(cx, cy - scale),
      Offset(cx, cy + scale),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 2,
    );

    // Moving observer worldline
    final angle = math.atan(velocity);
    canvas.drawLine(
      Offset(cx - scale * math.sin(angle), cy + scale * math.cos(angle)),
      Offset(cx + scale * math.sin(angle), cy - scale * math.cos(angle)),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2,
    );
  }

  void _drawEvents(Canvas canvas, double cx, double cy, double scale) {
    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final x = event['x']!;
      final t = event['t']!;

      // Position in rest frame
      final screenX = cx + x * scale;
      final screenY = cy - t * scale;

      // Draw event in rest frame
      canvas.drawCircle(
        Offset(screenX, screenY),
        6,
        Paint()..color = Colors.white,
      );

      // Calculate transformed coordinates
      final xPrime = gamma * (x - velocity * t);
      final tPrime = gamma * (t - velocity * x);

      // Draw transformed event (connected by line)
      final screenXPrime = cx + xPrime * scale;
      final screenYPrime = cy - tPrime * scale;

      // Connection line
      canvas.drawLine(
        Offset(screenX, screenY),
        Offset(screenXPrime, screenYPrime),
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );

      // Transformed event
      canvas.drawCircle(
        Offset(screenXPrime, screenYPrime),
        6,
        Paint()..color = AppColors.accent,
      );
    }
  }

  void _drawAxesLabels(Canvas canvas, Size size, double cx, double cy, double scale) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // X axis label
    textPainter.text = TextSpan(
      text: 'x',
      style: const TextStyle(color: Colors.white70, fontSize: 14),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + scale + 10, cy - 8));

    // T axis label
    textPainter.text = TextSpan(
      text: 'ct',
      style: const TextStyle(color: Colors.white70, fontSize: 14),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + 5, cy - scale - 20));

    // X' axis label
    textPainter.text = TextSpan(
      text: "x'",
      style: TextStyle(color: AppColors.accent, fontSize: 12),
    );
    textPainter.layout();
    final angle = math.atan(velocity);
    textPainter.paint(
      canvas,
      Offset(cx + scale * math.cos(angle) + 5, cy - scale * math.sin(angle) - 15),
    );

    // T' axis label
    textPainter.text = TextSpan(
      text: "ct'",
      style: TextStyle(color: AppColors.accent, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(cx + scale * math.sin(angle) + 5, cy - scale * math.cos(angle) - 15),
    );

    // Light cone label
    textPainter.text = TextSpan(
      text: isKorean ? '빛 원뿔' : 'Light Cone',
      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + scale * 0.7, cy - scale * 0.7 - 15));

    // Legend
    textPainter.text = TextSpan(
      text: isKorean ? '흰색: 정지 좌표계, 파랑: 운동 좌표계' : 'White: Rest frame, Blue: Moving frame',
      style: const TextStyle(color: Colors.white54, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height - 20));
  }

  @override
  bool shouldRepaint(covariant LorentzTransformationPainter oldDelegate) {
    return velocity != oldDelegate.velocity ||
        time != oldDelegate.time ||
        showGrid != oldDelegate.showGrid ||
        showEvents != oldDelegate.showEvents;
  }
}
