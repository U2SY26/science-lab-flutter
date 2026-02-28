import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class QuantumDecoherenceScreen extends StatefulWidget {
  const QuantumDecoherenceScreen({super.key});
  @override
  State<QuantumDecoherenceScreen> createState() => _QuantumDecoherenceScreenState();
}

class _QuantumDecoherenceScreenState extends State<QuantumDecoherenceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _t2 = 5;
  
  double _coherence = 1.0, _purityVal = 1.0;

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
      _coherence = math.exp(-_time / _t2);
      _purityVal = 0.5 + 0.5 * _coherence * _coherence;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _t2 = 5.0;
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
          const Text('양자 결어긋남', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '양자 결어긋남',
          formula: 'ρ(t) = ρ(0)e^(-t/T₂)',
          formulaDescription: '양자 결어긋남 과정에서 간섭성 손실을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _QuantumDecoherenceScreenPainter(
                time: _time,
                t2: _t2,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'T₂ (결어긋남 시간)',
                value: _t2,
                min: 0.5,
                max: 20,
                step: 0.5,
                defaultValue: 5,
                formatValue: (v) => '${v.toStringAsFixed(1)} μs',
                onChanged: (v) => setState(() => _t2 = v),
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
          _V('간섭성', _coherence.toStringAsFixed(3)),
          _V('순도', _purityVal.toStringAsFixed(3)),
          _V('t/T₂', (_time / _t2).toStringAsFixed(2)),
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

class _QuantumDecoherenceScreenPainter extends CustomPainter {
  final double time;
  final double t2;

  _QuantumDecoherenceScreenPainter({
    required this.time,
    required this.t2,
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

    // Coherence at current time
    final coherence = math.exp(-time / t2).clamp(0.0, 1.0);

    // --- Layout: top=interference pattern, bottom=coherence decay curve ---
    final patternTop = 24.0;
    final patternH = h * 0.42;
    final curveTop = patternTop + patternH + 22;
    final curveH = h - curveTop - 36;
    final leftMargin = 30.0;
    final rightMargin = 8.0;
    final plotW = w - leftMargin - rightMargin;

    // ===== Top: Double-slit interference pattern =====
    _drawText(canvas, '이중 슬릿 간섭 패턴 (결어긋남 진행)', Offset(w / 2, 8),
        fontSize: 9, color: const Color(0xFF00D4FF), align: TextAlign.center);

    // Draw intensity as vertical bars across width
    const nBars = 60;
    final barW = plotW / nBars;
    final patternBottom = patternTop + patternH;

    for (int i = 0; i < nBars; i++) {
      final x = -1.0 + 2.0 * i / (nBars - 1); // -1..1
      // Double slit interference: I = |ψ₁+ψ₂|²
      // With decoherence: I = I₁ + I₂ + 2√(I₁I₂)·γ·cos(kdx)
      // Single-slit envelope × interference
      const slitSep = 4.0;
      const sigma = 0.4;
      final envelope = math.exp(-x * x / (2 * sigma * sigma));
      final fringes = math.cos(slitSep * math.pi * x);
      // Mix: coherent (interference) vs incoherent (two separate Gaussians)
      final twoGaussian = (math.exp(-(x + 0.2) * (x + 0.2) / (2 * 0.1)) +
          math.exp(-(x - 0.2) * (x - 0.2) / (2 * 0.1))) * 0.4;
      final coherentI = envelope * (1 + fringes) / 2;
      final incoherentI = (coherentI + twoGaussian) / 2;
      final intensity = (coherence * coherentI + (1 - coherence) * incoherentI).clamp(0.0, 1.0);

      final bh = intensity * patternH * 0.88;
      final bx = leftMargin + i * barW;
      final col = Color.lerp(
        const Color(0xFF1A3040),
        const Color(0xFF00D4FF),
        intensity,
      )!;
      canvas.drawRect(
        Rect.fromLTWH(bx, patternBottom - bh, barW - 0.5, bh),
        Paint()..color = col.withValues(alpha: 0.85),
      );
    }

    // Pattern axis
    canvas.drawLine(Offset(leftMargin, patternBottom), Offset(w - rightMargin, patternBottom),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)..strokeWidth = 1);
    _drawText(canvas, '간섭성 γ=${coherence.toStringAsFixed(2)}', Offset(w / 2, patternTop + 4),
        fontSize: 8, color: coherence > 0.5 ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35),
        align: TextAlign.center);

    // Environment qubit orbits (small circles representing entanglement)
    final envCx = w - 40.0;
    final envCy = patternTop + patternH * 0.4;
    final envR = 18.0;
    const nEnv = 6;
    for (int i = 0; i < nEnv; i++) {
      final angle = time * 1.2 + i * 2 * math.pi / nEnv;
      final entangled = (1 - coherence);
      final ex = envCx + envR * math.cos(angle);
      final ey = envCy + envR * math.sin(angle);
      canvas.drawCircle(Offset(ex, ey), 3.5,
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: (0.3 + entangled * 0.6).clamp(0.0, 1.0)));
      // Line to center (entanglement)
      canvas.drawLine(Offset(envCx, envCy), Offset(ex, ey),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: entangled * 0.4)..strokeWidth = 0.8);
    }
    canvas.drawCircle(Offset(envCx, envCy), 7,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6));
    _drawText(canvas, 'sys', Offset(envCx, envCy - 4),
        fontSize: 7, color: const Color(0xFF0D1A20), align: TextAlign.center);
    _drawText(canvas, '환경', Offset(envCx, envCy + envR + 4),
        fontSize: 7, color: const Color(0xFFFF6B35), align: TextAlign.center);

    // ===== Bottom: Coherence decay curve =====
    final curveBottom = curveTop + curveH;
    _drawText(canvas, 'γ(t) = e^(-t/T₂)', Offset(w / 2, curveTop - 14),
        fontSize: 9, color: const Color(0xFF5A8A9A), align: TextAlign.center);

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..strokeWidth = 1;
    canvas.drawLine(Offset(leftMargin, curveTop), Offset(leftMargin, curveBottom), axisPaint);
    canvas.drawLine(Offset(leftMargin, curveBottom), Offset(w - rightMargin, curveBottom), axisPaint);
    _drawText(canvas, 'γ', Offset(2, curveTop + curveH / 2 - 5), fontSize: 8, color: const Color(0xFF5A8A9A));
    _drawText(canvas, 't', Offset(w - rightMargin, curveBottom + 2), fontSize: 8, color: const Color(0xFF5A8A9A));

    // Y-axis ticks
    for (final yv in [0.0, 0.5, 1.0]) {
      final py = curveBottom - yv * curveH;
      canvas.drawLine(Offset(leftMargin - 4, py), Offset(leftMargin, py),
          Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..strokeWidth = 1);
      _drawText(canvas, yv.toStringAsFixed(1), Offset(2, py - 5), fontSize: 7, color: const Color(0xFF5A8A9A));
    }

    // Draw decay curve
    const nCurvePts = 80;
    final maxT = t2 * 3;
    final curvePath = Path();
    for (int i = 0; i <= nCurvePts; i++) {
      final t = maxT * i / nCurvePts;
      final g = math.exp(-t / t2);
      final px = leftMargin + (t / maxT) * plotW;
      final py = curveBottom - g * curveH;
      if (i == 0) { curvePath.moveTo(px, py); } else { curvePath.lineTo(px, py); }
    }
    canvas.drawPath(curvePath, Paint()..color = const Color(0xFF00D4FF)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Current time indicator
    final currentT = time.clamp(0.0, maxT);
    final indicatorX = leftMargin + (currentT / maxT) * plotW;
    final indicatorY = curveBottom - coherence * curveH;
    canvas.drawLine(Offset(indicatorX, curveBottom), Offset(indicatorX, curveTop),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.4)..strokeWidth = 1);
    canvas.drawCircle(Offset(indicatorX, indicatorY), 5,
        Paint()..color = const Color(0xFFFF6B35));
    _drawText(canvas, 'γ=${coherence.toStringAsFixed(2)}', Offset(indicatorX + 6, indicatorY - 8),
        fontSize: 8, color: const Color(0xFFFF6B35));

    // T2 marker
    if (t2 <= maxT) {
      final t2X = leftMargin + (t2 / maxT) * plotW;
      canvas.drawLine(Offset(t2X, curveBottom + 3), Offset(t2X, curveTop),
          Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)..strokeWidth = 1
            ..strokeCap = StrokeCap.round);
      _drawText(canvas, 'T₂', Offset(t2X, curveBottom + 4), fontSize: 7, color: const Color(0xFF5A8A9A), align: TextAlign.center);
    }

    // Status
    final statusColor = coherence > 0.5
        ? const Color(0xFF64FF8C)
        : (coherence > 0.1 ? const Color(0xFFFF6B35) : const Color(0xFFFF4444));
    final statusText = coherence > 0.5 ? '양자 결맞음' : (coherence > 0.1 ? '부분 결어긋남' : '고전 혼합 상태');
    _drawText(canvas, statusText, Offset(w - rightMargin, curveTop - 14),
        fontSize: 8, color: statusColor, align: TextAlign.right);
  }

  @override
  bool shouldRepaint(covariant _QuantumDecoherenceScreenPainter oldDelegate) => true;
}
