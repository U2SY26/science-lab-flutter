import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class HookeSpringScreen extends StatefulWidget {
  const HookeSpringScreen({super.key});
  @override
  State<HookeSpringScreen> createState() => _HookeSpringScreenState();
}

class _HookeSpringScreenState extends State<HookeSpringScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _k1 = 10;
  double _k2 = 10;
  double _kSeries = 5.0, _kParallel = 20.0;

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
      _kSeries = (_k1 * _k2) / (_k1 + _k2);
      _kParallel = _k1 + _k2;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _k1 = 10.0; _k2 = 10.0;
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
          const Text('직렬/병렬 용수철', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '직렬/병렬 용수철',
          formula: '1/k_s=1/k₁+1/k₂',
          formulaDescription: '직렬과 병렬 용수철의 동작을 비교합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _HookeSpringScreenPainter(
                time: _time,
                k1: _k1,
                k2: _k2,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '탄성계수 k₁ (N/m)',
                value: _k1,
                min: 1,
                max: 50,
                step: 1,
                defaultValue: 10,
                formatValue: (v) => v.toStringAsFixed(0) + ' N/m',
                onChanged: (v) => setState(() => _k1 = v),
              ),
              advancedControls: [
            SimSlider(
                label: '탄성계수 k₂ (N/m)',
                value: _k2,
                min: 1,
                max: 50,
                step: 1,
                defaultValue: 10,
                formatValue: (v) => v.toStringAsFixed(0) + ' N/m',
                onChanged: (v) => setState(() => _k2 = v),
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
          _V('k₁', _k1.toStringAsFixed(1) + ' N/m'),
          _V('직렬', _kSeries.toStringAsFixed(1) + ' N/m'),
          _V('병렬', _kParallel.toStringAsFixed(1) + ' N/m'),
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

class _HookeSpringScreenPainter extends CustomPainter {
  final double time;
  final double k1;
  final double k2;

  _HookeSpringScreenPainter({
    required this.time,
    required this.k1,
    required this.k2,
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

  // Draw a coil spring from (x, y1) to (x, y2) with given coils
  void _drawSpring(Canvas canvas, double x, double y1, double y2, Color color,
      double coilW, int coils) {
    final length = y2 - y1;
    final segH = length / (coils * 2 + 2);
    final path = Path();
    path.moveTo(x, y1);
    path.lineTo(x, y1 + segH);
    for (int i = 0; i < coils; i++) {
      path.lineTo(x + coilW, y1 + segH + (i * 2 + 1) * segH);
      path.lineTo(x - coilW, y1 + segH + (i * 2 + 2) * segH);
    }
    path.lineTo(x, y2 - segH);
    path.lineTo(x, y2);
    canvas.drawPath(path,
        Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  void _arrow(Canvas canvas, Offset from, Offset to, Color color, double sw) {
    final p = Paint()..color = color..strokeWidth = sw..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, p);
    final dx = to.dx - from.dx, dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 2) return;
    final nx = dx / len, ny = dy / len;
    const hs = 5.0;
    canvas.drawLine(to, Offset(to.dx - nx * hs - ny * hs * 0.5, to.dy - ny * hs + nx * hs * 0.5), p);
    canvas.drawLine(to, Offset(to.dx - nx * hs + ny * hs * 0.5, to.dy - ny * hs - nx * hs * 0.5), p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;

    // Spring constants
    final kSeries = (k1 * k2) / (k1 + k2);
    final kParallel = k1 + k2;

    // Animated force oscillation
    final forcePhase = time * 1.2;
    final forceMag = 0.5 + 0.5 * math.sin(forcePhase); // 0..1
    const maxForce = 30.0; // N
    final force = forceMag * maxForce;

    // Extensions: F = k*x  → x = F/k, capped for display
    const maxExtDisplay = 28.0; // px
    final extSeries = (force / kSeries).clamp(0.0, maxExtDisplay);
    final extParallel = (force / kParallel).clamp(0.0, maxExtDisplay / 2);

    // ---- Layout ----
    const wallY = 18.0;
    final seriesX = w * 0.26;
    final parallelX = w * 0.72;
    final springTop = wallY + 6;

    // ===  SERIES SIDE (left) ===
    // Wall
    canvas.drawRect(Rect.fromLTWH(seriesX - 20, wallY - 4, 40, 5),
        Paint()..color = const Color(0xFF1A3040));
    canvas.drawLine(Offset(seriesX - 20, wallY - 4), Offset(seriesX + 20, wallY - 4),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 2);
    _label(canvas, '직렬', Offset(seriesX - 10, 2), const Color(0xFF00D4FF), 9, bold: true);

    // Spring 1 (top half of total length)
    final seriesMidY = springTop + h * 0.19 + extSeries * 0.5;
    final seriesEndY = seriesMidY + h * 0.19 + extSeries * 0.5;

    _drawSpring(canvas, seriesX, springTop, seriesMidY, const Color(0xFF00D4FF), 10, 5);
    _label(canvas, 'k₁=${k1.toStringAsFixed(0)}', Offset(seriesX + 13, (springTop + seriesMidY) / 2 - 5),
        const Color(0xFF00D4FF), 8);

    // Connector dot between springs
    canvas.drawCircle(Offset(seriesX, seriesMidY), 3,
        Paint()..color = const Color(0xFF5A8A9A));

    _drawSpring(canvas, seriesX, seriesMidY, seriesEndY, const Color(0xFF00D4FF), 10, 5);
    _label(canvas, 'k₂=${k2.toStringAsFixed(0)}', Offset(seriesX + 13, (seriesMidY + seriesEndY) / 2 - 5),
        const Color(0xFF00D4FF), 8);

    // Mass block
    canvas.drawRect(Rect.fromLTWH(seriesX - 12, seriesEndY, 24, 16),
        Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.fill);
    canvas.drawRect(Rect.fromLTWH(seriesX - 12, seriesEndY, 24, 16),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1..style = PaintingStyle.stroke);

    // Force arrow
    _arrow(canvas, Offset(seriesX, seriesEndY + 16),
        Offset(seriesX, seriesEndY + 16 + force * 0.4), const Color(0xFFFF6B35), 1.5);
    _label(canvas, 'F', Offset(seriesX + 4, seriesEndY + 22), const Color(0xFFFF6B35), 8);

    // Formula
    _label(canvas, '1/k_s=1/k₁+1/k₂', Offset(seriesX - 34, seriesEndY + 38),
        const Color(0xFF5A8A9A), 8);
    _label(canvas, 'k_s=${kSeries.toStringAsFixed(1)} N/m', Offset(seriesX - 20, seriesEndY + 50),
        const Color(0xFFE0F4FF), 8, bold: true);

    // === PARALLEL SIDE (right) ===
    canvas.drawRect(Rect.fromLTWH(parallelX - 30, wallY - 4, 60, 5),
        Paint()..color = const Color(0xFF1A3040));
    canvas.drawLine(Offset(parallelX - 30, wallY - 4), Offset(parallelX + 30, wallY - 4),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 2);
    _label(canvas, '병렬', Offset(parallelX - 10, 2), const Color(0xFFFF6B35), 9, bold: true);

    final parEndY = springTop + h * 0.34 + extParallel;
    final sp1X = parallelX - 15.0, sp2X = parallelX + 15.0;

    // Horizontal connector at top
    canvas.drawLine(Offset(sp1X, springTop), Offset(sp2X, springTop),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.5);

    _drawSpring(canvas, sp1X, springTop, parEndY, const Color(0xFFFF6B35), 8, 5);
    _label(canvas, 'k₁', Offset(sp1X - 18, (springTop + parEndY) / 2 - 5),
        const Color(0xFFFF6B35), 8);

    _drawSpring(canvas, sp2X, springTop, parEndY, const Color(0xFFFF6B35), 8, 5);
    _label(canvas, 'k₂', Offset(sp2X + 5, (springTop + parEndY) / 2 - 5),
        const Color(0xFFFF6B35), 8);

    // Horizontal connector at bottom + mass
    canvas.drawLine(Offset(sp1X, parEndY), Offset(sp2X, parEndY),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.5);
    canvas.drawRect(Rect.fromLTWH(parallelX - 14, parEndY, 28, 16),
        Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.fill);
    canvas.drawRect(Rect.fromLTWH(parallelX - 14, parEndY, 28, 16),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1..style = PaintingStyle.stroke);

    _arrow(canvas, Offset(parallelX, parEndY + 16),
        Offset(parallelX, parEndY + 16 + force * 0.4), const Color(0xFFFF6B35), 1.5);
    _label(canvas, 'F', Offset(parallelX + 4, parEndY + 22), const Color(0xFFFF6B35), 8);

    _label(canvas, 'k_p=k₁+k₂', Offset(parallelX - 26, parEndY + 38),
        const Color(0xFF5A8A9A), 8);
    _label(canvas, 'k_p=${kParallel.toStringAsFixed(1)} N/m', Offset(parallelX - 22, parEndY + 50),
        const Color(0xFFE0F4FF), 8, bold: true);

    // Center divider
    canvas.drawLine(Offset(w / 2, 14), Offset(w / 2, h - 6),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    // Force value display
    _label(canvas, 'F=${force.toStringAsFixed(1)} N', Offset(w / 2 - 22, h - 14),
        const Color(0xFF5A8A9A), 9);
  }

  @override
  bool shouldRepaint(covariant _HookeSpringScreenPainter oldDelegate) => true;
}
