import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class EscapeVelocityScreen extends StatefulWidget {
  const EscapeVelocityScreen({super.key});
  @override
  State<EscapeVelocityScreen> createState() => _EscapeVelocityScreenState();
}

class _EscapeVelocityScreenState extends State<EscapeVelocityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _bodyMass = 1;
  double _bodyRadius = 1;
  double _vEscape = 11.2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!_isRunning) return;
    setState(() {
      _time += 0.016;
      _vEscape = 11.2 * math.sqrt(_bodyMass / _bodyRadius);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _bodyMass = 1.0; _bodyRadius = 1.0;
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('천문학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('탈출 속도', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '탈출 속도',
          formula: 'v_e = √(2GM/r)',
          formulaDescription: '천체의 탈출 속도를 계산하고 비교합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _EscapeVelocityScreenPainter(
                time: _time,
                bodyMass: _bodyMass,
                bodyRadius: _bodyRadius,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '천체 질량 (M⊕)',
                value: _bodyMass,
                min: 0.01,
                max: 1000,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(2) + ' M⊕',
                onChanged: (v) => setState(() => _bodyMass = v),
              ),
              advancedControls: [
            SimSlider(
                label: '반지름 (R⊕)',
                value: _bodyRadius,
                min: 0.1,
                max: 100,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' R⊕',
                onChanged: (v) => setState(() => _bodyRadius = v),
              ),
              ],
            ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(children: [
          _V('v_e', _vEscape.toStringAsFixed(2) + ' km/s'),
          _V('M', _bodyMass.toStringAsFixed(2) + ' M⊕'),
          _V('R', _bodyRadius.toStringAsFixed(1) + ' R⊕'),
                ]),
              ),
            ],
          ),
          buttons: SimButtonGroup(expanded: true, buttons: [
            SimButton(
              label: _isRunning ? '정지' : '재생',
              icon: _isRunning ? Icons.pause : Icons.play_arrow,
              isPrimary: true,
              onPressed: () { HapticFeedback.selectionClick(); setState(() => _isRunning = !_isRunning); },
            ),
            SimButton(label: '리셋', icon: Icons.refresh, onPressed: _reset),
          ]),
        ),
      ),
    );
  }
}

class _V extends StatelessWidget {
  final String label, value;
  const _V(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
  ]));
}

class _EscapeVelocityScreenPainter extends CustomPainter {
  final double time;
  final double bodyMass;
  final double bodyRadius;

  _EscapeVelocityScreenPainter({
    required this.time,
    required this.bodyMass,
    required this.bodyRadius,
  });

  void _label(Canvas canvas, String text, Offset pos, Color col, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // Escape velocity (km/s): v_e = 11.2 * sqrt(M/R)
    final vEscape = 11.2 * math.sqrt(bodyMass / bodyRadius);
    // Schwarzschild radius ratio: r_s / R = 2GM/Rc² — scaled for display
    // r_s (Earth units) = 2 * bodyMass * 6.674e-11 * 5.97e24 / (6.37e6 * (3e8)^2) * (1/bodyRadius)
    //  ≈ 8.87e-10 * bodyMass / bodyRadius (dimensionless, in R_Earth)
    final rsRatio = 8.87e-4 * bodyMass / bodyRadius; // just for labelling
    final isBlackHole = rsRatio >= 1.0;

    // Layout: left 60% = trajectory panel, right 40% = potential curve
    final panelSplit = size.width * 0.58;

    // ── LEFT: Trajectory panel ──
    final bodyPx = math.min(panelSplit * 0.18, size.height * 0.15);
    final bodyCx = panelSplit * 0.28;
    final bodyCy = size.height * 0.72;

    // Body glow
    final bodyColor = isBlackHole
        ? const Color(0xFF220022)
        : bodyMass > 300
            ? const Color(0xFFFFCC44)
            : const Color(0xFF3A6EA5);
    canvas.drawCircle(
        Offset(bodyCx, bodyCy),
        bodyPx * 1.5,
        Paint()
          ..color = bodyColor.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(
        Offset(bodyCx, bodyCy), bodyPx, Paint()..color = bodyColor);
    canvas.drawCircle(
        Offset(bodyCx, bodyCy),
        bodyPx,
        Paint()
          ..color = bodyColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Black hole Schwarzschild ring
    if (isBlackHole) {
      canvas.drawCircle(
          Offset(bodyCx, bodyCy),
          bodyPx * 1.2,
          Paint()
            ..color = const Color(0xFFFF6B35).withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
      _label(canvas, 'r_s', Offset(bodyCx + bodyPx * 1.25, bodyCy - 6),
          const Color(0xFFFF6B35), 8);
    }

    _label(canvas, isBlackHole ? '블랙홀' : (bodyMass > 300 ? '별' : '행성'),
        Offset(bodyCx - 10, bodyCy + bodyPx + 5),
        const Color(0xFF5A8A9A), 9);

    // Draw 4 projectile trajectories at different launch speeds
    // Escape velocity reference
    final vRef = vEscape; // km/s
    final launchSpeeds = [vRef * 0.5, vRef * 0.8, vRef, vRef * 1.5];
    final colors = [
      const Color(0xFFFF6B35),
      const Color(0xFFFFAA55),
      const Color(0xFF00D4FF),
      const Color(0xFF64FF8C),
    ];

    for (int i = 0; i < launchSpeeds.length; i++) {
      final v = launchSpeeds[i];
      final isEscape = v >= vRef;
      final col = colors[i];

      final path = Path();
      final animOffset = (time * 0.4 + i * 0.25) % 1.0;

      if (!isEscape) {
        // Sub-escape: parabola that returns
        final maxH = (v / vRef) * (size.height * 0.55);
        final startX = bodyCx + bodyPx + 2;
        for (double t = 0; t <= 1.0; t += 0.02) {
          final h = maxH * 4 * t * (1 - t);
          final x = startX + t * 40;
          final y = bodyCy - h;
          if (t == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(
            path,
            Paint()
              ..color = col.withValues(alpha: 0.55)
              ..strokeWidth = 1.2
              ..style = PaintingStyle.stroke);
        // Animated dot
        final dotT = animOffset < 0.5
            ? animOffset * 2
            : (1 - animOffset) * 2; // bounce
        final dotH = maxH * 4 * dotT * (1 - dotT);
        final dotX = startX + dotT * 40;
        final dotY = bodyCy - dotH;
        canvas.drawCircle(Offset(dotX, dotY), 3, Paint()..color = col);
      } else {
        // Super-escape: diagonal upward
        final angle = -math.pi / 3 + i * 0.15;
        final startX = bodyCx + bodyPx * math.cos(-angle);
        final startY = bodyCy + bodyPx * math.sin(-angle);
        final len = math.min(panelSplit - startX - 10, size.height * 0.6);
        path.moveTo(startX, startY);
        path.lineTo(startX + len * math.cos(angle), startY + len * math.sin(angle));
        canvas.drawPath(
            path,
            Paint()
              ..color = col.withValues(alpha: 0.6)
              ..strokeWidth = 1.2
              ..style = PaintingStyle.stroke);
        // Animated dot along escape path
        final dotT = animOffset;
        final dotX = startX + len * dotT * math.cos(angle);
        final dotY = startY + len * dotT * math.sin(angle);
        canvas.drawCircle(Offset(dotX, dotY), 3, Paint()..color = col);
      }
    }

    // Legend
    final legY = size.height * 0.07;
    for (int i = 0; i < 4; i++) {
      final v = launchSpeeds[i];
      final col = colors[i];
      final fraction = (v / vRef);
      canvas.drawLine(
          Offset(4, legY + i * 14),
          Offset(18, legY + i * 14),
          Paint()
            ..color = col
            ..strokeWidth = 2);
      _label(
          canvas,
          '${fraction.toStringAsFixed(1)}v_e ${i >= 2 ? "(탈출)" : "(귀환)"}',
          Offset(22, legY + i * 14 - 5),
          col,
          8);
    }

    // v_escape display
    _label(
        canvas,
        'v_e = ${vEscape.toStringAsFixed(1)} km/s',
        Offset(4, legY + 60),
        const Color(0xFF00D4FF),
        10);

    // ── RIGHT: Potential energy curve ──
    final graphLeft = panelSplit + 6;
    final graphRight = size.width - 6.0;
    final graphTop = size.height * 0.08;
    final graphBottom = size.height * 0.92;
    final graphW = graphRight - graphLeft;
    final graphH = graphBottom - graphTop;

    canvas.drawRect(
      Rect.fromLTWH(graphLeft, graphTop, graphW, graphH),
      Paint()..color = const Color(0xFF0A1520),
    );
    canvas.drawRect(
      Rect.fromLTWH(graphLeft, graphTop, graphW, graphH),
      Paint()
        ..color = const Color(0xFF1A3040)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Axes
    final axisPaint = Paint()
      ..color = const Color(0xFF5A8A9A)
      ..strokeWidth = 0.8;
    // x-axis at bottom (U=0 asymptote)
    final zeroY = graphTop + graphH * 0.08;
    canvas.drawLine(
        Offset(graphLeft, zeroY), Offset(graphRight, zeroY), axisPaint);
    // y-axis
    canvas.drawLine(
        Offset(graphLeft + 2, graphTop), Offset(graphLeft + 2, graphBottom), axisPaint);

    _label(canvas, 'U(r)', Offset(graphLeft + 3, graphTop + 2),
        const Color(0xFF5A8A9A), 8);
    _label(canvas, 'r →', Offset(graphRight - 16, zeroY + 3),
        const Color(0xFF5A8A9A), 8);
    _label(canvas, '0', Offset(graphLeft + 4, zeroY - 10),
        const Color(0xFF5A8A9A), 7);

    // U(r) = -GMm/r curve (scaled)
    final potPath = Path();
    bool potStarted = false;
    final rMin = 1.0;
    final rMax = 8.0;
    for (double r = rMin; r <= rMax; r += 0.05) {
      final u = -1.0 / r; // normalised
      final x = graphLeft + 2 + (r - rMin) / (rMax - rMin) * (graphW - 4);
      final y = zeroY - u * graphH * 0.85;
      final yClamp = y.clamp(graphTop + 2, graphBottom - 2);
      if (!potStarted) {
        potPath.moveTo(x, yClamp);
        potStarted = true;
      } else {
        potPath.lineTo(x, yClamp);
      }
    }
    canvas.drawPath(
        potPath,
        Paint()
          ..color = const Color(0xFF5A8A9A).withValues(alpha: 0.7)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke);

    // Total energy lines for escape (E=0) and sub-escape (E<0)
    canvas.drawLine(Offset(graphLeft + 2, zeroY), Offset(graphRight - 2, zeroY),
        Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: 0.5)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke);
    _label(canvas, 'E=0 (탈출)', Offset(graphLeft + 4, zeroY - 18),
        const Color(0xFF00D4FF), 7);

    // Bound orbit line
    final boundY = zeroY + graphH * 0.25;
    canvas.drawLine(
        Offset(graphLeft + 2, boundY),
        Offset(graphRight - 2, boundY),
        Paint()
          ..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke);
    _label(canvas, 'E<0 (속박)', Offset(graphLeft + 4, boundY + 3),
        const Color(0xFFFF6B35), 7);

    _label(canvas, 'U(r)=-GMm/r', Offset(graphLeft + 4, graphBottom - 14),
        const Color(0xFF5A8A9A), 7);
  }

  @override
  bool shouldRepaint(covariant _EscapeVelocityScreenPainter oldDelegate) =>
      true;
}
