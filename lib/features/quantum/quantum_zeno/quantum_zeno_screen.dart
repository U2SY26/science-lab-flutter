import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class QuantumZenoScreen extends StatefulWidget {
  const QuantumZenoScreen({super.key});
  @override
  State<QuantumZenoScreen> createState() => _QuantumZenoScreenState();
}

class _QuantumZenoScreenState extends State<QuantumZenoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _measurements = 5;
  
  double _survivalProb = 0.9, _decayProb = 0.1;

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
      final n = _measurements.toInt();
      final angle = math.pi * _time / (2 * n * 1.0);
      _survivalProb = math.pow(math.cos(angle), 2 * n).toDouble().clamp(0.0, 1.0);
      _decayProb = 1 - _survivalProb;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _measurements = 5.0;
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
          Text('양자역학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('양자 제논 효과', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '양자 제논 효과',
          formula: 'P(survive) = cos²ⁿ(πt/2nT)',
          formulaDescription: '빈번한 측정이 양자 상태 변화를 억제하는 효과를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _QuantumZenoScreenPainter(
                time: _time,
                measurements: _measurements,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '측정 횟수 (n)',
                value: _measurements,
                min: 1,
                max: 50,
                step: 1,
                defaultValue: 5,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _measurements = v),
              ),
              
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
          _V('생존', '${(_survivalProb * 100).toStringAsFixed(1)}%'),
          _V('붕괴', '${(_decayProb * 100).toStringAsFixed(1)}%'),
          _V('n', _measurements.toInt().toString()),
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

class _QuantumZenoScreenPainter extends CustomPainter {
  final double time;
  final double measurements;

  _QuantumZenoScreenPainter({
    required this.time,
    required this.measurements,
  });

  void _drawText(Canvas canvas, String text, Offset offset,
      {double fontSize = 10, Color color = const Color(0xFFE0F4FF), bool bold = false, TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    double dx = offset.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final n = measurements.toInt().clamp(1, 50);

    // --- Layout: top = probability curves, bottom = survival vs n bar ---
    final leftMargin = 32.0;
    final rightMargin = 8.0;
    final topMargin = 26.0;
    final midGap = 20.0;
    final curvesH = h * 0.50;
    final barsTop = topMargin + curvesH + midGap;
    final barsH = h - barsTop - 20;
    final plotW = w - leftMargin - rightMargin;

    _drawText(canvas, '양자 제논 효과 (n=$n 측정)', Offset(w / 2, 6),
        fontSize: 9, color: const Color(0xFF00D4FF), align: TextAlign.center);

    // === Top: P(t) curves ===
    final curvesBottom = topMargin + curvesH;

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..strokeWidth = 1;
    canvas.drawLine(Offset(leftMargin, topMargin), Offset(leftMargin, curvesBottom), axisPaint);
    canvas.drawLine(Offset(leftMargin, curvesBottom), Offset(w - rightMargin, curvesBottom), axisPaint);
    _drawText(canvas, 'P', Offset(2, topMargin + curvesH / 2 - 5), fontSize: 8, color: const Color(0xFF5A8A9A));
    _drawText(canvas, 't', Offset(w - rightMargin + 2, curvesBottom - 5), fontSize: 8, color: const Color(0xFF5A8A9A));

    // Y-axis ticks
    for (final yv in [0.0, 0.5, 1.0]) {
      final py = curvesBottom - yv * curvesH;
      canvas.drawLine(Offset(leftMargin - 4, py), Offset(leftMargin, py), axisPaint);
      _drawText(canvas, yv.toStringAsFixed(1), Offset(2, py - 5), fontSize: 7, color: const Color(0xFF5A8A9A));
    }

    const nPts = 80;
    const totalTime = math.pi; // one full Rabi oscillation period

    // Natural decay: P(t) = sin²(Ωt/2) = (1 - cos(Ωt))/2  (decay from |0⟩ to |1⟩)
    // Survival: P_survive = cos²(Ωt/2)
    final naturalPath = Path();
    for (int i = 0; i <= nPts; i++) {
      final t = totalTime * i / nPts;
      final p = math.pow(math.cos(t / 2), 2).toDouble();
      final px = leftMargin + (t / totalTime) * plotW;
      final py = curvesBottom - p * curvesH;
      if (i == 0) { naturalPath.moveTo(px, py); } else { naturalPath.lineTo(px, py); }
    }
    canvas.drawPath(naturalPath,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Zeno: Piecewise with n measurements in [0, π]
    // Each segment: P_step = cos²(Ωτ/2)^2 where τ=π/n
    // Between measurements the system evolves freely then collapses
    if (n >= 1) {
      final zenoPath = Path();
      final tau = totalTime / n;
      bool started = false;
      double pSurvive = 1.0;
      for (int seg = 0; seg < n; seg++) {
        final tStart = seg * tau;
        final tEnd = tStart + tau;
        // Draw free evolution segment
        const segsPerInterval = 10;
        for (int j = 0; j <= segsPerInterval; j++) {
          final t = tStart + tau * j / segsPerInterval;
          final localP = pSurvive * math.pow(math.cos((t - tStart) / 2), 2).toDouble();
          final px = leftMargin + (t / totalTime) * plotW;
          final py = curvesBottom - localP.clamp(0.0, 1.0) * curvesH;
          if (!started) { zenoPath.moveTo(px, py); started = true; } else { zenoPath.lineTo(px, py); }
        }
        // Measurement collapse: probability drops by factor cos²(τ/2)
        pSurvive *= math.pow(math.cos(tau / 2), 2).toDouble();
        // Vertical drop at measurement point
        final mx = leftMargin + (tEnd / totalTime) * plotW;
        final dropFrom = curvesBottom - pSurvive / math.pow(math.cos(tau / 2), 2).toDouble() * curvesH;
        final dropTo = curvesBottom - pSurvive * curvesH;
        canvas.drawLine(Offset(mx, dropFrom), Offset(mx, dropTo),
            Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.4)..strokeWidth = 1);
        // Measurement tick mark
        canvas.drawLine(Offset(mx, curvesBottom - 4), Offset(mx, curvesBottom + 4),
            Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..strokeWidth = 1);
      }
      canvas.drawPath(zenoPath,
          Paint()..color = const Color(0xFF00D4FF)..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    // Legend
    canvas.drawLine(Offset(leftMargin + 4, topMargin + 8), Offset(leftMargin + 20, topMargin + 8),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2);
    _drawText(canvas, '제논(n=$n 측정)', Offset(leftMargin + 24, topMargin + 3),
        fontSize: 8, color: const Color(0xFF00D4FF));
    canvas.drawLine(Offset(leftMargin + 4, topMargin + 18), Offset(leftMargin + 20, topMargin + 18),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.8)..strokeWidth = 2);
    _drawText(canvas, '자연 붕괴', Offset(leftMargin + 24, topMargin + 13),
        fontSize: 8, color: const Color(0xFFFF6B35));

    // === Bottom: Final survival probability vs n ===
    if (barsH > 16) {
      _drawText(canvas, '측정 횟수 n별 생존확률 P_survival(T=π)',
          Offset(w / 2, barsTop - 12), fontSize: 8, color: const Color(0xFF5A8A9A), align: TextAlign.center);
      canvas.drawLine(Offset(leftMargin, barsTop), Offset(leftMargin, barsTop + barsH), axisPaint);
      canvas.drawLine(Offset(leftMargin, barsTop + barsH), Offset(w - rightMargin, barsTop + barsH), axisPaint);

      const nShow = 10;
      final barW2 = plotW / (nShow + 1);
      for (int ni = 1; ni <= nShow; ni++) {
        final tau2 = totalTime / ni;
        final pSurv = math.pow(math.cos(tau2 / 2), 2 * ni).toDouble().clamp(0.0, 1.0);
        final bh = pSurv * barsH * 0.9;
        final bx = leftMargin + ni * barW2;
        final isCurrentN = ni == n.clamp(1, nShow);
        canvas.drawRect(
          Rect.fromLTWH(bx - barW2 * 0.35, barsTop + barsH - bh, barW2 * 0.7, bh),
          Paint()..color = isCurrentN
              ? const Color(0xFF00D4FF)
              : const Color(0xFF00D4FF).withValues(alpha: 0.35),
        );
        _drawText(canvas, '$ni', Offset(bx, barsTop + barsH + 2),
            fontSize: 7, color: const Color(0xFF5A8A9A), align: TextAlign.center);
      }
      _drawText(canvas, 'n', Offset(w - rightMargin + 2, barsTop + barsH - 5), fontSize: 8, color: const Color(0xFF5A8A9A));
    }
  }

  @override
  bool shouldRepaint(covariant _QuantumZenoScreenPainter oldDelegate) => true;
}
