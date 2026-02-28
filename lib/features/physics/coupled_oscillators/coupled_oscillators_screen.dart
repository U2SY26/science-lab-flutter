import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CoupledOscillatorsScreen extends StatefulWidget {
  const CoupledOscillatorsScreen({super.key});
  @override
  State<CoupledOscillatorsScreen> createState() => _CoupledOscillatorsScreenState();
}

class _CoupledOscillatorsScreenState extends State<CoupledOscillatorsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _coupling = 2.0;
  double _k1 = 3.0;
  double _x1 = 0, _x2 = 0;

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
      final omPlus = math.sqrt((_k1 + 2 * _coupling) / 1.0);
      final omMinus = math.sqrt(_k1 / 1.0);
      _x1 = 60 * (math.cos(omPlus * _time) + math.cos(omMinus * _time)) / 2;
      _x2 = 60 * (-math.cos(omPlus * _time) + math.cos(omMinus * _time)) / 2;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _coupling = 2.0;
      _k1 = 3.0;
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
          const Text('결합 진동자', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '결합 진동자',
          formula: 'ω± = √((k₁+k₂)/m ± k₂/m)',
          formulaDescription: '두 질량이 용수철로 연결되어 정규 모드로 진동합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CoupledOscillatorsScreenPainter(
                time: _time,
                coupling: _coupling,
                k1: _k1,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '결합 강도 (k₂)',
                value: _coupling,
                min: 0.1,
                max: 5.0,
                step: 0.1,
                defaultValue: 2.0,
                formatValue: (v) => '${v.toStringAsFixed(1)}',
                onChanged: (v) => setState(() => _coupling = v),
              ),
              advancedControls: [
            SimSlider(
                label: '탄성계수 (k₁)',
                value: _k1,
                min: 0.5,
                max: 10.0,
                step: 0.1,
                defaultValue: 3.0,
                formatValue: (v) => '${v.toStringAsFixed(1)}',
                onChanged: (v) => setState(() => _k1 = v),
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
          _V('x₁', '${_x1.toStringAsFixed(1)}'),
          _V('x₂', '${_x2.toStringAsFixed(1)}'),
          _V('ω+', '${math.sqrt((_k1 + 2 * _coupling)).toStringAsFixed(2)}'),
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

class _CoupledOscillatorsScreenPainter extends CustomPainter {
  final double time;
  final double coupling;
  final double k1;

  _CoupledOscillatorsScreenPainter({
    required this.time,
    required this.coupling,
    required this.k1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Normal mode frequencies
    final omPlus = math.sqrt((k1 + 2 * coupling) / 1.0);
    final omMinus = math.sqrt(k1 / 1.0);

    // Positions: superposition of normal modes (initial: x1=1, x2=0)
    final x1 = 50.0 * (math.cos(omPlus * time) + math.cos(omMinus * time)) / 2;
    final x2 = 50.0 * (-math.cos(omPlus * time) + math.cos(omMinus * time)) / 2;

    // ── TOP: Spring-Mass System ──────────────────────────────
    final sysY = h * 0.28;
    final wallL = 8.0;
    final wallR = w - 8.0;
    final massR = 14.0;
    final springBase = sysY;

    // Equilibrium positions
    final eq1 = w * 0.32;
    final eq2 = w * 0.68;
    final m1x = eq1 + x1 * 0.5;
    final m2x = eq2 + x2 * 0.5;

    // Walls
    for (int s = 0; s < 5; s++) {
      canvas.drawLine(Offset(wallL, springBase - 12 + s * 5), Offset(wallL + 6, springBase - 12 + s * 5 - 4),
          Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..strokeWidth = 1);
      canvas.drawLine(Offset(wallR, springBase - 12 + s * 5), Offset(wallR - 6, springBase - 12 + s * 5 - 4),
          Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..strokeWidth = 1);
    }
    canvas.drawLine(Offset(wallL, springBase - 22), Offset(wallL, springBase + 6),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 2);
    canvas.drawLine(Offset(wallR, springBase - 22), Offset(wallR, springBase + 6),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 2);

    // Springs
    void drawSpring(double x1s, double x2s) {
      final path = Path();
      path.moveTo(x1s, springBase);
      final coils = 8;
      final cw = 8.0;
      for (int i = 0; i <= coils; i++) {
        final t = i / coils;
        final cx2 = x1s + t * (x2s - x1s) + (i % 2 == 0 ? -cw : cw);
        path.lineTo(cx2, springBase);
      }
      path.lineTo(x2s, springBase);
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFF5A8A9A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
    }

    drawSpring(wallL, m1x - massR);
    drawSpring(m1x + massR, m2x - massR);
    drawSpring(m2x + massR, wallR);

    // Masses
    canvas.drawCircle(Offset(m1x, springBase),
        massR, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.85));
    canvas.drawCircle(Offset(m2x, springBase),
        massR, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.85));
    _text(canvas, 'm₁', Offset(m1x - 6, springBase - 6),
        const TextStyle(color: Color(0xFF0D1A20), fontSize: 8, fontWeight: FontWeight.bold));
    _text(canvas, 'm₂', Offset(m2x - 6, springBase - 6),
        const TextStyle(color: Color(0xFF0D1A20), fontSize: 8, fontWeight: FontWeight.bold));

    _text(canvas, '결합 진동자  k₁=${k1.toStringAsFixed(1)}  k₂=${coupling.toStringAsFixed(1)}',
        Offset(w / 2 - 72, 4),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 9, fontWeight: FontWeight.bold));

    // ── MIDDLE: x₁(t) and x₂(t) time series ────────────────
    final graphY = h * 0.40;
    final graphH = h * 0.28;
    final padL = 30.0, padR = 8.0;
    final graphW = w - padL - padR;
    final mid1 = graphY + graphH * 0.25;
    final mid2 = graphY + graphH * 0.75;
    final amp = graphH * 0.2;

    canvas.drawLine(Offset(padL, mid1), Offset(padL + graphW, mid1),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.8);
    canvas.drawLine(Offset(padL, mid2), Offset(padL + graphW, mid2),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.8);
    _text(canvas, 'x₁(t)', Offset(2, mid1 - 6),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 8));
    _text(canvas, 'x₂(t)', Offset(2, mid2 - 6),
        const TextStyle(color: Color(0xFFFF6B35), fontSize: 8));

    final tWindow = 4 * math.pi / omMinus;
    final path1 = Path(), path2 = Path();
    bool f1 = true, f2 = true;
    for (int i = 0; i <= 100; i++) {
      final t2 = time - tWindow + i / 100 * tWindow;
      final p1 = 50.0 * (math.cos(omPlus * t2) + math.cos(omMinus * t2)) / 2;
      final p2 = 50.0 * (-math.cos(omPlus * t2) + math.cos(omMinus * t2)) / 2;
      final gx = padL + i / 100 * graphW;
      final gy1 = mid1 - p1 / 50.0 * amp;
      final gy2 = mid2 - p2 / 50.0 * amp;
      if (f1) { path1.moveTo(gx, gy1); f1 = false; } else { path1.lineTo(gx, gy1); }
      if (f2) { path2.moveTo(gx, gy2); f2 = false; } else { path2.lineTo(gx, gy2); }
    }
    canvas.drawPath(path1, Paint()..color = const Color(0xFF00D4FF)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawPath(path2, Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // ── BOTTOM: Normal mode labels and spectrum ──────────────
    final specY = graphY + graphH + 10;
    final specH = h - specY - 8;
    _text(canvas, '정규 모드', Offset(padL, specY - 2),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8, fontWeight: FontWeight.bold));

    // Two frequency bars
    final freqMax = math.max(omPlus, omMinus) * 1.2;
    final bar1W = (omMinus / freqMax * (graphW * 0.4)).clamp(0.0, graphW * 0.4);
    final bar2W = (omPlus / freqMax * (graphW * 0.4)).clamp(0.0, graphW * 0.4);
    final barH2 = (specH * 0.35).clamp(6.0, 18.0);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(padL, specY + 10, bar1W, barH2), const Radius.circular(2)),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7));
    _text(canvas, 'ω⁻=${omMinus.toStringAsFixed(2)}', Offset(padL + bar1W + 4, specY + 10),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 8));

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(padL, specY + 10 + barH2 + 4, bar2W, barH2), const Radius.circular(2)),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7));
    _text(canvas, 'ω⁺=${omPlus.toStringAsFixed(2)}', Offset(padL + bar2W + 4, specY + 10 + barH2 + 4),
        const TextStyle(color: Color(0xFFFF6B35), fontSize: 8));
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _CoupledOscillatorsScreenPainter oldDelegate) => true;
}
