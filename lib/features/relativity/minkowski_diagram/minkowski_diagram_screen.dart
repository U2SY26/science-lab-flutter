import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Minkowski Spacetime Diagram Simulation
class MinkowskiDiagramScreen extends StatefulWidget {
  const MinkowskiDiagramScreen({super.key});

  @override
  State<MinkowskiDiagramScreen> createState() => _MinkowskiDiagramScreenState();
}

class _MinkowskiDiagramScreenState extends State<MinkowskiDiagramScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _velocity = 0.5; // v/c
  double _time = 0.0;
  bool _isAnimating = false;
  bool _showLightCones = true;
  bool _showWorldlines = true;
  bool _showSimultaneity = true;
  bool _isKorean = true;

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
      _time += 0.02;
      if (_time >= 2) _time = -2;
    });
  }

  double get _gamma => 1 / math.sqrt(1 - _velocity * _velocity);

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _velocity = 0.5;
      _time = 0;
      _isAnimating = false;
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
              _isKorean ? '민코프스키 시공간' : 'Minkowski Spacetime',
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
          title: _isKorean ? '민코프스키 시공간' : 'Minkowski Spacetime',
          formula: 'ds² = c²dt² - dx² - dy² - dz²',
          formulaDescription: _isKorean
              ? '민코프스키 시공간에서 시간과 공간은 하나의 4차원 연속체를 형성합니다. 빛 원뿔은 인과관계를 결정하고, 동시성은 관측자에 따라 상대적입니다.'
              : 'In Minkowski spacetime, time and space form a unified 4D continuum. Light cones determine causality, and simultaneity is relative to the observer.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: MinkowskiDiagramPainter(
                velocity: _velocity,
                gamma: _gamma,
                time: _time,
                showLightCones: _showLightCones,
                showWorldlines: _showWorldlines,
                showSimultaneity: _showSimultaneity,
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
                  label: _isKorean ? '관측자 속도 (v/c)' : 'Observer Velocity (v/c)',
                  value: _velocity,
                  min: 0,
                  max: 0.9,
                  defaultValue: 0.5,
                  formatValue: (v) => '${(v * 100).toStringAsFixed(0)}% c',
                  onChanged: (v) => setState(() => _velocity = v),
                ),
                advancedControls: [
                  SimToggle(
                    label: _isKorean ? '빛 원뿔' : 'Light Cones',
                    value: _showLightCones,
                    onChanged: (v) => setState(() => _showLightCones = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '세계선' : 'Worldlines',
                    value: _showWorldlines,
                    onChanged: (v) => setState(() => _showWorldlines = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '동시성' : 'Simultaneity',
                    value: _showSimultaneity,
                    onChanged: (v) => setState(() => _showSimultaneity = v),
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
          Text(
            isKorean ? '시공간 영역:' : 'Spacetime Regions:',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 12, height: 12, color: Colors.yellow.withValues(alpha: 0.3)),
              const SizedBox(width: 8),
              Text(
                isKorean ? '빛처럼 영역 (미래/과거)' : 'Timelike (Future/Past)',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 12, height: 12, color: Colors.grey.withValues(alpha: 0.3)),
              const SizedBox(width: 8),
              Text(
                isKorean ? '공간처럼 영역 (인과적 무관)' : 'Spacelike (Causally Disconnected)',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MinkowskiDiagramPainter extends CustomPainter {
  final double velocity;
  final double gamma;
  final double time;
  final bool showLightCones;
  final bool showWorldlines;
  final bool showSimultaneity;
  final bool isKorean;

  MinkowskiDiagramPainter({
    required this.velocity,
    required this.gamma,
    required this.time,
    required this.showLightCones,
    required this.showWorldlines,
    required this.showSimultaneity,
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

    // Draw light cones
    if (showLightCones) {
      _drawLightCones(canvas, centerX, centerY, scale);
    }

    // Draw rest frame axes
    _drawRestFrameAxes(canvas, centerX, centerY, scale);

    // Draw moving frame axes
    _drawMovingFrameAxes(canvas, centerX, centerY, scale);

    // Draw simultaneity lines
    if (showSimultaneity) {
      _drawSimultaneityLines(canvas, centerX, centerY, scale);
    }

    // Draw worldlines
    if (showWorldlines) {
      _drawWorldlines(canvas, centerX, centerY, scale);
    }

    // Draw events
    _drawEvents(canvas, centerX, centerY, scale);

    // Labels
    _drawLabels(canvas, size, centerX, centerY, scale);
  }

  void _drawLightCones(Canvas canvas, double cx, double cy, double scale) {
    // Light cone fill (future)
    final futurePath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + scale, cy - scale)
      ..lineTo(cx - scale, cy - scale)
      ..close();
    canvas.drawPath(
      futurePath,
      Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.1),
    );

    // Light cone fill (past)
    final pastPath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + scale, cy + scale)
      ..lineTo(cx - scale, cy + scale)
      ..close();
    canvas.drawPath(
      pastPath,
      Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.1),
    );

    // Light cone edges
    final lightPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 2;

    // Future light cone
    canvas.drawLine(Offset(cx, cy), Offset(cx + scale, cy - scale), lightPaint);
    canvas.drawLine(Offset(cx, cy), Offset(cx - scale, cy - scale), lightPaint);

    // Past light cone
    canvas.drawLine(Offset(cx, cy), Offset(cx + scale, cy + scale), lightPaint);
    canvas.drawLine(Offset(cx, cy), Offset(cx - scale, cy + scale), lightPaint);
  }

  void _drawRestFrameAxes(Canvas canvas, double cx, double cy, double scale) {
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;

    // Time axis (vertical)
    canvas.drawLine(Offset(cx, cy + scale), Offset(cx, cy - scale), axisPaint);

    // Space axis (horizontal)
    canvas.drawLine(Offset(cx - scale, cy), Offset(cx + scale, cy), axisPaint);

    // Arrow heads
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Time arrow
    final timeArrow = Path()
      ..moveTo(cx, cy - scale)
      ..lineTo(cx - 5, cy - scale + 10)
      ..lineTo(cx + 5, cy - scale + 10)
      ..close();
    canvas.drawPath(timeArrow, arrowPaint);

    // Space arrow
    final spaceArrow = Path()
      ..moveTo(cx + scale, cy)
      ..lineTo(cx + scale - 10, cy - 5)
      ..lineTo(cx + scale - 10, cy + 5)
      ..close();
    canvas.drawPath(spaceArrow, arrowPaint);

    // Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    for (double i = -0.75; i <= 0.75; i += 0.25) {
      if (i == 0) continue;
      canvas.drawLine(
        Offset(cx + i * scale, cy - scale),
        Offset(cx + i * scale, cy + scale),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cx - scale, cy + i * scale),
        Offset(cx + scale, cy + i * scale),
        gridPaint,
      );
    }
  }

  void _drawMovingFrameAxes(Canvas canvas, double cx, double cy, double scale) {
    final angle = math.atan(velocity);
    final boostedPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2;

    // Time' axis (tilted toward light cone)
    final t1x = cx - scale * math.sin(angle);
    final t1y = cy + scale * math.cos(angle);
    final t2x = cx + scale * math.sin(angle);
    final t2y = cy - scale * math.cos(angle);
    canvas.drawLine(Offset(t1x, t1y), Offset(t2x, t2y), boostedPaint);

    // Space' axis (tilted toward light cone)
    final x1x = cx - scale * math.cos(angle);
    final x1y = cy + scale * math.sin(angle);
    final x2x = cx + scale * math.cos(angle);
    final x2y = cy - scale * math.sin(angle);
    canvas.drawLine(Offset(x1x, x1y), Offset(x2x, x2y), boostedPaint);

    // Grid for moving frame
    final boostedGridPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    for (double i = -0.5; i <= 0.5; i += 0.25) {
      if (i == 0) continue;
      // Lines of constant t'
      final startX = cx + i * scale * math.sin(angle) - scale * math.cos(angle);
      final startY = cy - i * scale * math.cos(angle) + scale * math.sin(angle);
      final endX = cx + i * scale * math.sin(angle) + scale * math.cos(angle);
      final endY = cy - i * scale * math.cos(angle) - scale * math.sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), boostedGridPaint);
    }
  }

  void _drawSimultaneityLines(Canvas canvas, double cx, double cy, double scale) {
    // Lines of constant time in rest frame
    final restSimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final restT = time * 0.5;
    canvas.drawLine(
      Offset(cx - scale, cy - restT * scale),
      Offset(cx + scale, cy - restT * scale),
      restSimPaint,
    );

    // Lines of constant time' in moving frame
    final angle = math.atan(velocity);
    final movingSimPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final movingT = time * 0.5;
    final startX = cx + movingT * scale * math.sin(angle) - scale * math.cos(angle);
    final startY = cy - movingT * scale * math.cos(angle) + scale * math.sin(angle);
    final endX = cx + movingT * scale * math.sin(angle) + scale * math.cos(angle);
    final endY = cy - movingT * scale * math.cos(angle) - scale * math.sin(angle);
    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), movingSimPaint);
  }

  void _drawWorldlines(Canvas canvas, double cx, double cy, double scale) {
    // Stationary observer worldline (along time axis)
    canvas.drawLine(
      Offset(cx, cy + scale * 0.8),
      Offset(cx, cy - scale * 0.8),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3,
    );

    // Moving observer worldline
    final angle = math.atan(velocity);
    canvas.drawLine(
      Offset(cx - scale * 0.8 * math.sin(angle), cy + scale * 0.8 * math.cos(angle)),
      Offset(cx + scale * 0.8 * math.sin(angle), cy - scale * 0.8 * math.cos(angle)),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 3,
    );

    // Light ray worldline
    canvas.drawLine(
      Offset(cx - scale * 0.6, cy + scale * 0.6),
      Offset(cx + scale * 0.6, cy - scale * 0.6),
      Paint()
        ..color = const Color(0xFFFFD700)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawEvents(Canvas canvas, double cx, double cy, double scale) {
    // Event at origin
    canvas.drawCircle(
      Offset(cx, cy),
      6,
      Paint()..color = Colors.white,
    );

    // Event A (in future light cone)
    canvas.drawCircle(
      Offset(cx + scale * 0.2, cy - scale * 0.4),
      5,
      Paint()..color = Colors.green,
    );

    // Event B (in past light cone)
    canvas.drawCircle(
      Offset(cx - scale * 0.1, cy + scale * 0.3),
      5,
      Paint()..color = Colors.red,
    );

    // Event C (spacelike separated)
    canvas.drawCircle(
      Offset(cx + scale * 0.5, cy - scale * 0.1),
      5,
      Paint()..color = Colors.grey,
    );
  }

  void _drawLabels(Canvas canvas, Size size, double cx, double cy, double scale) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Time axis label
    textPainter.text = const TextSpan(
      text: 'ct',
      style: TextStyle(color: Colors.white70, fontSize: 14),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + 8, cy - scale - 15));

    // Space axis label
    textPainter.text = const TextSpan(
      text: 'x',
      style: TextStyle(color: Colors.white70, fontSize: 14),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + scale + 5, cy - 8));

    // Time' axis label
    final angle = math.atan(velocity);
    textPainter.text = TextSpan(
      text: "ct'",
      style: TextStyle(color: AppColors.accent, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + scale * 0.8 * math.sin(angle) + 5, cy - scale * 0.8 * math.cos(angle) - 15));

    // Space' axis label
    textPainter.text = TextSpan(
      text: "x'",
      style: TextStyle(color: AppColors.accent, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + scale * 0.8 * math.cos(angle) + 5, cy - scale * 0.8 * math.sin(angle) + 5));

    // Event labels
    textPainter.text = const TextSpan(
      text: 'A',
      style: TextStyle(color: Colors.green, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + scale * 0.2 + 8, cy - scale * 0.4 - 5));

    textPainter.text = const TextSpan(
      text: 'B',
      style: TextStyle(color: Colors.red, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - scale * 0.1 + 8, cy + scale * 0.3 - 5));

    textPainter.text = const TextSpan(
      text: 'C',
      style: TextStyle(color: Colors.grey, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + scale * 0.5 + 8, cy - scale * 0.1 - 5));

    // Legend
    textPainter.text = TextSpan(
      text: isKorean ? '흰색: 정지 좌표계 | 파랑: 운동 좌표계' : 'White: Rest frame | Blue: Moving frame',
      style: const TextStyle(color: Colors.white54, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height - 20));
  }

  @override
  bool shouldRepaint(covariant MinkowskiDiagramPainter oldDelegate) {
    return velocity != oldDelegate.velocity ||
        time != oldDelegate.time ||
        showLightCones != oldDelegate.showLightCones ||
        showWorldlines != oldDelegate.showWorldlines ||
        showSimultaneity != oldDelegate.showSimultaneity;
  }
}
