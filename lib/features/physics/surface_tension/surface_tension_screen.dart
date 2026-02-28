import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class SurfaceTensionScreen extends StatefulWidget {
  const SurfaceTensionScreen({super.key});
  @override
  State<SurfaceTensionScreen> createState() => _SurfaceTensionScreenState();
}

class _SurfaceTensionScreenState extends State<SurfaceTensionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _gamma = 0.072;
  double _wireLength = 5;
  double _force = 0.0072;

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
      _force = 2 * _gamma * _wireLength * 0.01;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _gamma = 0.072; _wireLength = 5.0;
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
          Text('물리 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('표면 장력', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '표면 장력',
          formula: 'F = γL',
          formulaDescription: '표면 장력이 액체 표면에 미치는 영향을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SurfaceTensionScreenPainter(
                time: _time,
                gamma: _gamma,
                wireLength: _wireLength,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '표면 장력 계수 (N/m)',
                value: _gamma,
                min: 0.01,
                max: 0.5,
                step: 0.001,
                defaultValue: 0.072,
                formatValue: (v) => v.toStringAsFixed(3) + ' N/m',
                onChanged: (v) => setState(() => _gamma = v),
              ),
              advancedControls: [
            SimSlider(
                label: '와이어 길이 (cm)',
                value: _wireLength,
                min: 1,
                max: 20,
                step: 0.5,
                defaultValue: 5,
                formatValue: (v) => v.toStringAsFixed(1) + ' cm',
                onChanged: (v) => setState(() => _wireLength = v),
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
          _V('γ', _gamma.toStringAsFixed(3) + ' N/m'),
          _V('L', _wireLength.toStringAsFixed(1) + ' cm'),
          _V('F', (_force * 1000).toStringAsFixed(2) + ' mN'),
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

class _SurfaceTensionScreenPainter extends CustomPainter {
  final double time;
  final double gamma;
  final double wireLength;

  _SurfaceTensionScreenPainter({
    required this.time,
    required this.gamma,
    required this.wireLength,
  });

  void _label(Canvas canvas, String text, Offset pos, Color color, double sz,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: sz,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;

    // ---- Layout ----
    // Top 55%: main surface tension scene (water surface + object)
    // Bottom 40%: capillary action + molecule diagram
    final mainH = h * 0.55;
    final capY = mainH + 8;
    final capH = h - capY - 6;

    // === MAIN SCENE: water surface with object ===
    final waterTop = mainH * 0.48;
    final waterBottom = mainH * 0.85;

    // Water body fill
    canvas.drawRect(Rect.fromLTWH(0, waterTop + 10, w, waterBottom - waterTop),
        Paint()..color = const Color(0xFF003060).withValues(alpha: 0.6));

    // Ripple animation: concentric arcs from center
    final cx = w * 0.5;
    final rippleAmp = 6.0 * gamma / 0.072; // more surface tension = bigger ripple
    for (int i = 0; i < 4; i++) {
      final phase = (time * 1.2 + i * 0.4) % 1.0;
      final rippleR = phase * w * 0.45;
      final alpha = (1.0 - phase) * 0.3;
      if (alpha > 0.02) {
        canvas.drawArc(
            Rect.fromCenter(center: Offset(cx, waterTop + 8), width: rippleR * 2, height: rippleR * 0.5),
            math.pi, math.pi, false,
            Paint()
              ..color = const Color(0xFF00D4FF).withValues(alpha: alpha)
              ..strokeWidth = 1.0
              ..style = PaintingStyle.stroke);
      }
    }

    // Surface curve: depressed at center (object sits there)
    final surfaceDepression = rippleAmp * (1 + 0.15 * math.sin(time * 3));
    final surfacePath = Path();
    for (int px = 0; px <= w.toInt(); px++) {
      final xNorm = (px - cx) / (w * 0.3);
      final depression = surfaceDepression * math.exp(-xNorm * xNorm);
      final sy = waterTop + depression;
      if (px == 0) { surfacePath.moveTo(0, sy); } else { surfacePath.lineTo(px.toDouble(), sy); }
    }
    canvas.drawPath(surfacePath, Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke);

    // Object (small oval — like a water strider foot / needle)
    final objY = waterTop + surfaceDepression * 0.7;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, objY - 3), width: 22, height: 8),
        Paint()..color = const Color(0xFF5A8A9A)..style = PaintingStyle.fill);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, objY - 3), width: 22, height: 8),
        Paint()..color = const Color(0xFFE0F4FF)..strokeWidth = 1..style = PaintingStyle.stroke);
    _label(canvas, '물체', Offset(cx + 12, objY - 10), const Color(0xFFE0F4FF), 8);

    // Surface tension force arrows (pointing inward along surface at contact point)
    final arrowLen = 18.0 + gamma * 60;
    final leftAx = cx - 11.0, rightAx = cx + 11.0;
    final arrowY = objY;
    // Left arrow (pointing left-down along surface)
    canvas.drawLine(Offset(leftAx, arrowY), Offset(leftAx - arrowLen, arrowY + 4),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    // Right arrow
    canvas.drawLine(Offset(rightAx, arrowY), Offset(rightAx + arrowLen, arrowY + 4),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    _label(canvas, 'γ', Offset(cx - 4, arrowY + 6), const Color(0xFFFF6B35), 9);

    // Molecule visualization: surface vs bulk
    final molY = waterBottom - 8;
    // Surface molecules (top layer) — uneven force (net downward)
    for (int i = 0; i < 7; i++) {
      final mx = w * 0.1 + i * (w * 0.12);
      canvas.drawCircle(Offset(mx, molY - 6), 4,
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7));
      // Force arrow pointing down (net surface force)
      canvas.drawLine(Offset(mx, molY - 2), Offset(mx, molY + 7),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)..strokeWidth = 1);
    }
    // Bulk molecules (below surface) — symmetric forces
    for (int i = 0; i < 5; i++) {
      final mx = w * 0.15 + i * (w * 0.15);
      canvas.drawCircle(Offset(mx, molY + 15), 3.5,
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.35));
    }
    _label(canvas, '표면 분자: 비대칭 인력 → 표면 장력',
        Offset(8, molY + 22), const Color(0xFF5A8A9A), 8);

    // === CAPILLARY ACTION PANEL ===
    canvas.drawRect(Rect.fromLTWH(0, capY, w, capH),
        Paint()..color = const Color(0xFF0A0A0F));
    canvas.drawLine(Offset(0, capY), Offset(w, capY),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    _label(canvas, '모세관 현상 (γ=${gamma.toStringAsFixed(3)} N/m)',
        Offset(6, capY + 3), const Color(0xFF5A8A9A), 8, bold: true);

    // Draw 3 capillary tubes with different radii
    final tubeRadii = [8.0, 5.0, 3.0];
    final tubeLabels = ['r=넓', 'r=중', 'r=좁'];
    final tubeBaseY = capY + capH - 8;
    final rhoG = 1000.0 * 9.8;
    for (int ti = 0; ti < 3; ti++) {
      final tx = w * (0.22 + ti * 0.25);
      final r = tubeRadii[ti];
      // Rise height: h = 2γcosθ / (ρgr)  — scaled for display
      final riseH = (2 * gamma * 0.95 / (rhoG * r * 0.001)).clamp(0.0, capH * 0.7);
      final waterTopCapY = tubeBaseY - riseH;

      // Tube outline
      canvas.drawRect(Rect.fromLTWH(tx - r, capY + 14, r * 2, capH - 22),
          Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1..style = PaintingStyle.stroke);
      // Water in tube
      if (riseH > 1) {
        canvas.drawRect(Rect.fromLTWH(tx - r + 1, waterTopCapY, r * 2 - 2, riseH),
            Paint()..color = const Color(0xFF0060C0).withValues(alpha: 0.75));
        // Meniscus arc (concave)
        canvas.drawArc(
            Rect.fromLTWH(tx - r + 1, waterTopCapY - r * 0.5, r * 2 - 2, r),
            0, math.pi, false,
            Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.2..style = PaintingStyle.stroke);
      }
      _label(canvas, tubeLabels[ti], Offset(tx - 6, tubeBaseY + 2), const Color(0xFF5A8A9A), 7);
    }
    _label(canvas, 'h=2γcosθ/ρgr', Offset(w * 0.68, capY + capH * 0.3),
        const Color(0xFFFF6B35), 9);
  }

  @override
  bool shouldRepaint(covariant _SurfaceTensionScreenPainter oldDelegate) => true;
}
