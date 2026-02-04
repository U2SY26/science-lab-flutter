import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Schwarzschild Metric Simulation
class SchwarzschildScreen extends StatefulWidget {
  const SchwarzschildScreen({super.key});

  @override
  State<SchwarzschildScreen> createState() => _SchwarzschildScreenState();
}

class _SchwarzschildScreenState extends State<SchwarzschildScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _mass = 1.0; // Solar masses
  double _radialPosition = 5.0; // In Schwarzschild radii
  double _time = 0.0;
  bool _isAnimating = true;
  bool _showPotential = true;
  bool _showClocks = true;
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
    });
  }

  // Proper time ratio at position r
  double get _properTimeRatio => math.sqrt(1 - 1 / _radialPosition);

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _mass = 1.0;
      _radialPosition = 5.0;
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
              _isKorean ? '슈바르츠실트 계량' : 'Schwarzschild Metric',
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
          title: _isKorean ? '슈바르츠실트 계량' : 'Schwarzschild Metric',
          formula: 'ds² = -(1-rs/r)c²dt² + (1-rs/r)⁻¹dr² + r²dΩ²',
          formulaDescription: _isKorean
              ? '슈바르츠실트 계량은 구대칭 정적 질량 분포 주변의 시공간을 기술합니다. rs = 2GM/c²는 슈바르츠실트 반경(사건의 지평선)입니다.'
              : 'The Schwarzschild metric describes spacetime around a spherically symmetric static mass. rs = 2GM/c² is the Schwarzschild radius (event horizon).',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: SchwarzschildPainter(
                mass: _mass,
                radialPosition: _radialPosition,
                time: _time,
                properTimeRatio: _properTimeRatio,
                showPotential: _showPotential,
                showClocks: _showClocks,
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
                  label: _isKorean ? '반경 위치 (r/rs)' : 'Radial Position (r/rs)',
                  value: _radialPosition,
                  min: 1.1,
                  max: 10.0,
                  defaultValue: 5.0,
                  formatValue: (v) => '${v.toStringAsFixed(1)} rs',
                  onChanged: (v) => setState(() => _radialPosition = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '질량' : 'Mass',
                    value: _mass,
                    min: 0.5,
                    max: 5.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)} M☉',
                    onChanged: (v) => setState(() => _mass = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '유효 퍼텐셜' : 'Effective Potential',
                    value: _showPotential,
                    onChanged: (v) => setState(() => _showPotential = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '시간 비교' : 'Show Clocks',
                    value: _showClocks,
                    onChanged: (v) => setState(() => _showClocks = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                radialPosition: _radialPosition,
                properTimeRatio: _properTimeRatio,
                mass: _mass,
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
  final double radialPosition;
  final double properTimeRatio;
  final double mass;
  final bool isKorean;

  const _InfoCard({
    required this.radialPosition,
    required this.properTimeRatio,
    required this.mass,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    final schwarzschildRadius = 2.95 * mass; // km

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
              Icon(Icons.radio_button_checked, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                isKorean ? '슈바르츠실트 반경' : 'Schwarzschild Radius',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'rs = ${schwarzschildRadius.toStringAsFixed(1)} km',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
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
                isKorean ? '고유시간 비율 (dτ/dt)' : 'Proper Time Ratio (dτ/dt)',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const Spacer(),
              Text(
                properTimeRatio.toStringAsFixed(4),
                style: const TextStyle(color: Colors.orange, fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? 'r = rs에서 시간이 정지하고, r < rs에서는 시공간 좌표가 뒤바뀜'
                : 'Time stops at r = rs, spacetime coordinates swap for r < rs',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class SchwarzschildPainter extends CustomPainter {
  final double mass;
  final double radialPosition;
  final double time;
  final double properTimeRatio;
  final bool showPotential;
  final bool showClocks;
  final bool isKorean;

  SchwarzschildPainter({
    required this.mass,
    required this.radialPosition,
    required this.time,
    required this.properTimeRatio,
    required this.showPotential,
    required this.showClocks,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.35;
    final centerY = size.height / 2;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0A0A1A),
    );

    // Draw effective potential on the right
    if (showPotential) {
      _drawEffectivePotential(canvas, size);
    }

    // Draw black hole and metric visualization
    _drawBlackHole(canvas, centerX, centerY);

    // Draw radial position indicator
    _drawRadialPosition(canvas, centerX, centerY);

    // Draw clocks comparison
    if (showClocks) {
      _drawClocks(canvas, size, centerX, centerY);
    }

    // Labels
    _drawLabels(canvas, size, centerX, centerY);
  }

  void _drawBlackHole(Canvas canvas, double cx, double cy) {
    final rs = 25 * math.sqrt(mass);

    // Event horizon
    canvas.drawCircle(
      Offset(cx, cy),
      rs,
      Paint()..color = Colors.black,
    );

    // Photon sphere
    canvas.drawCircle(
      Offset(cx, cy),
      rs * 1.5,
      Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ISCO (Innermost Stable Circular Orbit)
    canvas.drawCircle(
      Offset(cx, cy),
      rs * 3,
      Paint()
        ..color = Colors.green.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Event horizon edge
    canvas.drawCircle(
      Offset(cx, cy),
      rs,
      Paint()
        ..color = Colors.red.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Concentric circles showing metric
    for (double r = 2; r <= 10; r += 1) {
      final radius = rs * r;
      if (radius > 150) break;

      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }
  }

  void _drawRadialPosition(Canvas canvas, double cx, double cy) {
    final rs = 25 * math.sqrt(mass);
    final posRadius = rs * radialPosition;

    // Position circle
    canvas.drawCircle(
      Offset(cx, cy),
      posRadius,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Observer marker
    final observerAngle = time * 0.5;
    final observerX = cx + posRadius * math.cos(observerAngle);
    final observerY = cy + posRadius * math.sin(observerAngle);

    canvas.drawCircle(
      Offset(observerX, observerY),
      8,
      Paint()..color = AppColors.accent,
    );

    // Line from center to observer
    canvas.drawLine(
      Offset(cx, cy),
      Offset(observerX, observerY),
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
  }

  void _drawEffectivePotential(Canvas canvas, Size size) {
    final graphLeft = size.width * 0.55;
    final graphRight = size.width - 20;
    final graphTop = 40.0;
    final graphBottom = size.height - 40;
    final graphWidth = graphRight - graphLeft;
    final graphHeight = graphBottom - graphTop;

    // Background
    canvas.drawRect(
      Rect.fromLTRB(graphLeft, graphTop, graphRight, graphBottom),
      Paint()..color = const Color(0xFF1A1A2E),
    );

    // Axes
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(graphLeft, graphBottom), Offset(graphRight, graphBottom), axisPaint);
    canvas.drawLine(Offset(graphLeft, graphTop), Offset(graphLeft, graphBottom), axisPaint);

    // Effective potential curve
    final potentialPath = Path();
    bool first = true;

    for (double r = 1.5; r <= 10; r += 0.1) {
      final x = graphLeft + (r - 1) / 9 * graphWidth;
      // Simplified effective potential: V_eff = -1/r + L^2/(2r^2) - L^2/(r^3)
      final L = 4.0; // Angular momentum
      final vEff = -1 / r + L * L / (2 * r * r) - L * L / (r * r * r);
      final normalizedV = (vEff + 0.15) / 0.3; // Normalize to 0-1
      final y = graphBottom - normalizedV.clamp(0.0, 1.0) * graphHeight;

      if (first) {
        potentialPath.moveTo(x, y);
        first = false;
      } else {
        potentialPath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      potentialPath,
      Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Current position marker
    final posX = graphLeft + (radialPosition - 1) / 9 * graphWidth;
    final L = 4.0;
    final vEffPos = -1 / radialPosition + L * L / (2 * radialPosition * radialPosition) - L * L / (radialPosition * radialPosition * radialPosition);
    final normalizedVPos = (vEffPos + 0.15) / 0.3;
    final posY = graphBottom - normalizedVPos.clamp(0.0, 1.0) * graphHeight;

    canvas.drawCircle(
      Offset(posX, posY),
      5,
      Paint()..color = AppColors.accent,
    );

    // Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: isKorean ? '유효 퍼텐셜' : 'Effective Potential',
      style: const TextStyle(color: Colors.cyan, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(graphLeft + 5, graphTop + 5));

    textPainter.text = const TextSpan(
      text: 'r/rs',
      style: TextStyle(color: Colors.white54, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(graphRight - 20, graphBottom + 5));
  }

  void _drawClocks(Canvas canvas, Size size, double cx, double cy) {
    // Far away clock (reference)
    _drawClock(canvas, size.width - 80, 80, 25, time, 1.0, isKorean ? '원거리' : 'Far');

    // Clock at current position
    _drawClock(canvas, size.width - 80, 180, 25, time * properTimeRatio, properTimeRatio, '${radialPosition.toStringAsFixed(1)}rs');
  }

  void _drawClock(Canvas canvas, double x, double y, double radius, double clockTime, double rate, String label) {
    // Clock face
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()..color = const Color(0xFF2A2A4A),
    );
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Hour marks
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 - math.pi / 2;
      final inner = radius * 0.8;
      final outer = radius * 0.95;
      canvas.drawLine(
        Offset(x + inner * math.cos(angle), y + inner * math.sin(angle)),
        Offset(x + outer * math.cos(angle), y + outer * math.sin(angle)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }

    // Clock hand
    final handAngle = clockTime - math.pi / 2;
    canvas.drawLine(
      Offset(x, y),
      Offset(x + radius * 0.7 * math.cos(handAngle), y + radius * 0.7 * math.sin(handAngle)),
      Paint()
        ..color = rate < 1 ? Colors.orange : Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Center dot
    canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.white);

    // Label
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: label,
      style: const TextStyle(color: Colors.white70, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y + radius + 5));
  }

  void _drawLabels(Canvas canvas, Size size, double cx, double cy) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final rs = 25 * math.sqrt(mass);

    // Event horizon label
    textPainter.text = TextSpan(
      text: 'rs',
      style: const TextStyle(color: Colors.red, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + rs + 5, cy - 5));

    // Photon sphere
    textPainter.text = const TextSpan(
      text: '1.5rs',
      style: TextStyle(color: Color(0xFFFFD700), fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + rs * 1.5 + 5, cy - 5));

    // ISCO
    textPainter.text = TextSpan(
      text: isKorean ? '3rs (ISCO)' : '3rs (ISCO)',
      style: const TextStyle(color: Colors.green, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + rs * 3 + 5, cy - 5));

    // Current position
    textPainter.text = TextSpan(
      text: '${radialPosition.toStringAsFixed(1)}rs',
      style: TextStyle(color: AppColors.accent, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + rs * radialPosition + 5, cy + 15));
  }

  @override
  bool shouldRepaint(covariant SchwarzschildPainter oldDelegate) {
    return mass != oldDelegate.mass ||
        radialPosition != oldDelegate.radialPosition ||
        time != oldDelegate.time ||
        showPotential != oldDelegate.showPotential ||
        showClocks != oldDelegate.showClocks;
  }
}
