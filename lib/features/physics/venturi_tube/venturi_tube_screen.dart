import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class VenturiTubeScreen extends StatefulWidget {
  const VenturiTubeScreen({super.key});
  @override
  State<VenturiTubeScreen> createState() => _VenturiTubeScreenState();
}

class _VenturiTubeScreenState extends State<VenturiTubeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _flowSpeed = 5;
  double _tubeRatio = 2;
  double _pressure1 = 101325, _pressure2 = 101325, _speed2 = 5.0;

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
      final v1 = _flowSpeed;
      final ratio = _tubeRatio;
      _speed2 = v1 * ratio * ratio;
      final rho = 1000.0;
      _pressure1 = 101325.0;
      _pressure2 = _pressure1 + 0.5 * rho * (v1 * v1 - _speed2 * _speed2);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _flowSpeed = 5.0; _tubeRatio = 2.0;
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
          const Text('벤투리 효과', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '벤투리 효과',
          formula: 'P₁+½ρv₁²=P₂+½ρv₂²',
          formulaDescription: '좁은 관에서의 압력 변화를 관찰합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _VenturiTubeScreenPainter(
                time: _time,
                flowSpeed: _flowSpeed,
                tubeRatio: _tubeRatio,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '유속 (m/s)',
                value: _flowSpeed,
                min: 1,
                max: 20,
                step: 0.5,
                defaultValue: 5,
                formatValue: (v) => v.toStringAsFixed(1) + ' m/s',
                onChanged: (v) => setState(() => _flowSpeed = v),
              ),
              advancedControls: [
            SimSlider(
                label: '관 직경 비',
                value: _tubeRatio,
                min: 1.1,
                max: 5,
                step: 0.1,
                defaultValue: 2,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _tubeRatio = v),
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
          _V('P₁', (_pressure1 / 1000).toStringAsFixed(1) + ' kPa'),
          _V('P₂', (_pressure2 / 1000).toStringAsFixed(1) + ' kPa'),
          _V('v₂', _speed2.toStringAsFixed(1) + ' m/s'),
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

class _VenturiTubeScreenPainter extends CustomPainter {
  final double time;
  final double flowSpeed;
  final double tubeRatio;

  _VenturiTubeScreenPainter({
    required this.time,
    required this.flowSpeed,
    required this.tubeRatio,
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

    // Physics
    final v1 = flowSpeed;
    final ratio = tubeRatio.clamp(1.1, 5.0);
    final v2 = v1 * ratio * ratio;
    const rho = 1000.0;
    const p1 = 101325.0;
    final p2 = p1 + 0.5 * rho * (v1 * v1 - v2 * v2);

    // --- Tube geometry ---
    // Tube centered vertically
    final tubeCy = h * 0.42;
    final wideHalf = h * 0.13; // half-height of wide section
    final narrowHalf = wideHalf / ratio.clamp(1.1, 3.5);

    // x positions
    final x0 = w * 0.04;   // start
    final x1 = w * 0.28;   // start of taper
    final x2 = w * 0.42;   // narrow start
    final x3 = w * 0.58;   // narrow end
    final x4 = w * 0.72;   // end of taper
    final x5 = w * 0.96;   // end

    // Build tube outline path
    final tubePath = Path();
    // Top wall
    tubePath.moveTo(x0, tubeCy - wideHalf);
    tubePath.lineTo(x1, tubeCy - wideHalf);
    tubePath.lineTo(x2, tubeCy - narrowHalf);
    tubePath.lineTo(x3, tubeCy - narrowHalf);
    tubePath.lineTo(x4, tubeCy - wideHalf);
    tubePath.lineTo(x5, tubeCy - wideHalf);
    // Bottom wall (reverse)
    tubePath.lineTo(x5, tubeCy + wideHalf);
    tubePath.lineTo(x4, tubeCy + wideHalf);
    tubePath.lineTo(x3, tubeCy + narrowHalf);
    tubePath.lineTo(x2, tubeCy + narrowHalf);
    tubePath.lineTo(x1, tubeCy + wideHalf);
    tubePath.lineTo(x0, tubeCy + wideHalf);
    tubePath.close();

    // Fill tube with water color
    canvas.drawPath(tubePath,
        Paint()..color = const Color(0xFF003060).withValues(alpha: 0.7));
    // Tube border
    canvas.drawPath(tubePath,
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Flow particles
    const numParticles = 14;
    for (int i = 0; i < numParticles; i++) {
      final offset = (i / numParticles);
      // Speed-based: faster in narrow section
      double tNorm = ((offset + time * v1 * 0.04) % 1.0);
      // Map tNorm to x and compute y-center and speed
      double px, particleV;
      if (tNorm < 0.28) {
        px = x0 + tNorm / 0.28 * (x1 - x0);
        particleV = v1;
      } else if (tNorm < 0.42) {
        px = x1 + (tNorm - 0.28) / 0.14 * (x2 - x1);
        particleV = v1 + (v2 - v1) * ((tNorm - 0.28) / 0.14);
      } else if (tNorm < 0.58) {
        px = x2 + (tNorm - 0.42) / 0.16 * (x3 - x2);
        particleV = v2;
      } else if (tNorm < 0.72) {
        px = x3 + (tNorm - 0.58) / 0.14 * (x4 - x3);
        particleV = v2 - (v2 - v1) * ((tNorm - 0.58) / 0.14);
      } else {
        px = x4 + (tNorm - 0.72) / 0.28 * (x5 - x4);
        particleV = v1;
      }
      final speedFrac = (particleV / (v2 + 0.01)).clamp(0.0, 1.0);
      final dotColor = Color.lerp(
          const Color(0xFF004080), const Color(0xFF00D4FF), speedFrac)!;
      canvas.drawCircle(Offset(px, tubeCy), 3.5, Paint()..color = dotColor);
    }

    // Speed arrows at wide and narrow sections
    final arrowY = tubeCy;
    // Wide: short arrow
    _drawArrow(canvas, Offset(x0 + 6, arrowY), Offset(x0 + 6 + v1 * 2.2, arrowY),
        const Color(0xFF00D4FF), 1.5);
    _label(canvas, 'v₁=${v1.toStringAsFixed(1)}', Offset(x0 + 4, arrowY - wideHalf - 13),
        const Color(0xFF00D4FF), 8);

    // Narrow: long arrow
    final narX = (x2 + x3) / 2;
    _drawArrow(canvas, Offset(narX - v2 * 0.8, arrowY), Offset(narX + v2 * 0.8, arrowY),
        const Color(0xFFFF6B35), 1.5);
    _label(canvas, 'v₂=${v2.toStringAsFixed(1)}', Offset(narX - 12, arrowY - narrowHalf - 13),
        const Color(0xFFFF6B35), 8);

    // --- Pressure gauges (vertical tubes above) ---
    // P1 gauge above wide left section
    final g1X = x0 + (x1 - x0) * 0.5;
    final p1MaxH = h * 0.22;
    final p1H = p1MaxH * (p1 / 101325.0).clamp(0.0, 1.2);
    final g1TopY = tubeCy - wideHalf - 4;
    canvas.drawRect(Rect.fromLTWH(g1X - 6, g1TopY - p1MaxH, 12, p1MaxH),
        Paint()..color = const Color(0xFF001830).withValues(alpha: 0.7));
    canvas.drawRect(Rect.fromLTWH(g1X - 5, g1TopY - p1H, 10, p1H),
        Paint()..color = const Color(0xFF0060C0).withValues(alpha: 0.85));
    canvas.drawRect(Rect.fromLTWH(g1X - 6, g1TopY - p1MaxH, 12, p1MaxH),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1..style = PaintingStyle.stroke);
    _label(canvas, 'P₁', Offset(g1X - 5, g1TopY - p1MaxH - 12), const Color(0xFF00D4FF), 9);
    _label(canvas, (p1 / 1000).toStringAsFixed(1), Offset(g1X - 10, g1TopY - p1H - 11),
        const Color(0xFFE0F4FF), 7);

    // P2 gauge above narrow section
    final g2X = (x2 + x3) / 2;
    final p2Clamped = p2.clamp(0.0, 200000.0);
    final p2H = p1MaxH * (p2Clamped / 101325.0).clamp(0.0, 1.2);
    final g2TopY = tubeCy - narrowHalf - 4;
    canvas.drawRect(Rect.fromLTWH(g2X - 6, g2TopY - p1MaxH, 12, p1MaxH),
        Paint()..color = const Color(0xFF001830).withValues(alpha: 0.7));
    final p2HClamped = p2H.clamp(0.0, p1MaxH);
    canvas.drawRect(Rect.fromLTWH(g2X - 5, g2TopY - p2HClamped, 10, p2HClamped),
        Paint()..color = const Color(0xFF0060C0).withValues(alpha: 0.85));
    canvas.drawRect(Rect.fromLTWH(g2X - 6, g2TopY - p1MaxH, 12, p1MaxH),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1..style = PaintingStyle.stroke);
    _label(canvas, 'P₂', Offset(g2X - 5, g2TopY - p1MaxH - 12), const Color(0xFFFF6B35), 9);
    _label(canvas, (p2 / 1000).toStringAsFixed(1), Offset(g2X - 10, g2TopY - p2HClamped - 11),
        const Color(0xFFE0F4FF), 7);

    // Bernoulli equation label bottom
    final eqY = h * 0.84;
    _label(canvas, 'P₁+½ρv₁² = P₂+½ρv₂²  (Bernoulli)',
        Offset(w / 2 - 70, eqY), const Color(0xFF5A8A9A), 8, bold: true);
    _label(canvas, 'P₁=${(p1 / 1000).toStringAsFixed(1)}kPa  P₂=${(p2 / 1000).toStringAsFixed(1)}kPa  v₂=${v2.toStringAsFixed(1)}m/s',
        Offset(w / 2 - 65, eqY + 12), const Color(0xFFE0F4FF), 8);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color, double sw) {
    canvas.drawLine(from, to, Paint()..color = color..strokeWidth = sw..strokeCap = StrokeCap.round);
    final dx = to.dx - from.dx, dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 2) return;
    final nx = dx / len, ny = dy / len;
    const hs = 5.0;
    canvas.drawLine(to, Offset(to.dx - nx * hs - ny * hs * 0.5, to.dy - ny * hs + nx * hs * 0.5),
        Paint()..color = color..strokeWidth = sw);
    canvas.drawLine(to, Offset(to.dx - nx * hs + ny * hs * 0.5, to.dy - ny * hs - nx * hs * 0.5),
        Paint()..color = color..strokeWidth = sw);
  }

  @override
  bool shouldRepaint(covariant _VenturiTubeScreenPainter oldDelegate) => true;
}
