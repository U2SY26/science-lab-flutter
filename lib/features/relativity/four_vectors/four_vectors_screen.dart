import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class FourVectorsScreen extends StatefulWidget {
  const FourVectorsScreen({super.key});
  @override
  State<FourVectorsScreen> createState() => _FourVectorsScreenState();
}

class _FourVectorsScreenState extends State<FourVectorsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _velocity = 0.5;
  double _restMass = 1.0;
  double _gamma = 1, _energy = 1, _momentum = 0;

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
      _gamma = 1.0 / math.sqrt(1.0 - _velocity * _velocity);
      _energy = _gamma * _restMass;
      _momentum = _gamma * _restMass * _velocity;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _velocity = 0.5;
      _restMass = 1.0;
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
          Text('상대성이론 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('4-벡터', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '4-벡터',
          formula: 'p^μ = (E/c, px, py, pz)',
          formulaDescription: '민코프스키 시공간에서 4-운동량을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _FourVectorsScreenPainter(
                time: _time,
                velocity: _velocity,
                restMass: _restMass,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '속도 (v/c)',
                value: _velocity,
                min: 0.0,
                max: 0.99,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => '${v.toStringAsFixed(2)} c',
                onChanged: (v) => setState(() => _velocity = v),
              ),
              advancedControls: [
            SimSlider(
                label: '정지 질량 (m₀)',
                value: _restMass,
                min: 0.1,
                max: 5.0,
                step: 0.1,
                defaultValue: 1.0,
                formatValue: (v) => '${v.toStringAsFixed(1)}',
                onChanged: (v) => setState(() => _restMass = v),
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
          _V('E', '${_energy.toStringAsFixed(3)}'),
          _V('p', '${_momentum.toStringAsFixed(3)}'),
          _V('γ', '${_gamma.toStringAsFixed(3)}'),
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

class _FourVectorsScreenPainter extends CustomPainter {
  final double time;
  final double velocity;
  final double restMass;

  _FourVectorsScreenPainter({
    required this.time,
    required this.velocity,
    required this.restMass,
  });

  void _lbl(Canvas canvas, String text, Offset center, Color color, double sz,
      {FontWeight fw = FontWeight.normal}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: sz, fontFamily: 'monospace', fontWeight: fw)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _arrow(Canvas canvas, Offset from, Offset to, Color color, double strokeW) {
    canvas.drawLine(from, to, Paint()..color = color..strokeWidth = strokeW..style = PaintingStyle.stroke);
    final dir = (to - from);
    final len = dir.distance;
    if (len < 1) return;
    final unit = dir / len;
    final perp = Offset(-unit.dy, unit.dx);
    const headLen = 8.0, headW = 4.0;
    final head1 = to - unit * headLen + perp * headW;
    final head2 = to - unit * headLen - perp * headW;
    canvas.drawLine(to, head1, Paint()..color = color..strokeWidth = strokeW);
    canvas.drawLine(to, head2, Paint()..color = color..strokeWidth = strokeW);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final v = velocity.clamp(0.0, 0.99);
    final m0 = restMass.clamp(0.1, 5.0);
    final gamma = 1.0 / math.sqrt(1.0 - v * v);
    final E = gamma * m0;       // energy (in units c=1)
    final p = gamma * m0 * v;   // momentum
    final invMass = m0 * m0;    // E²-p² = m0² (invariant)

    _lbl(canvas, '4-운동량 벡터  p^μ = (E/c, px, py, pz)', Offset(w / 2, 12),
        const Color(0xFF00D4FF), 10, fw: FontWeight.bold);

    final axisP = Paint()..color = const Color(0xFF2A4050)..strokeWidth = 1..style = PaintingStyle.stroke;

    // ======= LEFT: Energy-momentum diagram =======
    final dL = 14.0, dT = 26.0, dR = w * 0.48, dB = h * 0.82;
    final dW = dR - dL;
    final dH = dB - dT;
    // Origin at bottom-left
    final ox = dL + 10;
    final oy = dB - 10;

    // Grid
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5..style = PaintingStyle.stroke;
    for (int gi = 0; gi <= 4; gi++) {
      final gy = oy - gi * (dH * 0.22);
      final gx2 = ox + gi * (dW * 0.22);
      if (gy >= dT) canvas.drawLine(Offset(ox, gy), Offset(dR, gy), gridP);
      if (gx2 <= dR) canvas.drawLine(Offset(gx2, dT), Offset(gx2, oy), gridP);
    }

    // Axes
    canvas.drawLine(Offset(ox, oy), Offset(dR, oy), axisP);
    canvas.drawLine(Offset(ox, oy), Offset(ox, dT), axisP);
    _lbl(canvas, 'px', Offset(dR - 5, oy - 8), const Color(0xFF5A8A9A), 8);
    _lbl(canvas, 'E', Offset(ox + 8, dT + 8), const Color(0xFF5A8A9A), 8);

    // Scale factor: map values to pixels
    const maxVal = 8.0;
    final scaleX = (dW - 20) / maxVal;
    final scaleY = (dH - 20) / maxVal;

    // Mass-shell hyperbola: E² - px² = m0²
    final hyperPath = Path();
    bool hyperFirst = true;
    for (double px2 = 0; px2 <= maxVal; px2 += 0.1) {
      final e2 = math.sqrt(invMass + px2 * px2);
      if (e2 > maxVal) break;
      final hx = ox + px2 * scaleX;
      final hy = oy - e2 * scaleY;
      if (hy < dT) break;
      if (hyperFirst) { hyperPath.moveTo(hx, hy); hyperFirst = false; }
      else { hyperPath.lineTo(hx, hy); }
    }
    canvas.drawPath(hyperPath,
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..strokeWidth = 1.2..style = PaintingStyle.stroke);
    _lbl(canvas, 'E²-p²=m₀²', Offset(ox + 40, oy - m0 * scaleY - 10),
        const Color(0xFF5A8A9A), 7);

    // 4-momentum vector
    final tipX = ox + p * scaleX;
    final tipY = oy - E * scaleY;
    if (tipX <= dR && tipY >= dT) {
      // Classify interval
      final invariant = E * E - p * p;
      final vecColor = invariant > 0.01
          ? const Color(0xFF00D4FF)  // timelike
          : const Color(0xFFFF6B35); // lightlike
      _arrow(canvas, Offset(ox, oy), Offset(tipX, tipY), vecColor, 2.0);
      canvas.drawCircle(Offset(tipX, tipY), 5, Paint()..color = vecColor);

      // Components
      canvas.drawLine(Offset(ox, oy), Offset(tipX, oy),
          Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.6)..strokeWidth = 1..style = PaintingStyle.stroke);
      canvas.drawLine(Offset(tipX, oy), Offset(tipX, tipY),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..strokeWidth = 1..style = PaintingStyle.stroke);

      _lbl(canvas, 'px=${p.toStringAsFixed(2)}', Offset((ox + tipX) / 2, oy + 8),
          const Color(0xFF64FF8C), 7);
      _lbl(canvas, 'E=${E.toStringAsFixed(2)}', Offset(tipX + 16, (oy + tipY) / 2),
          const Color(0xFFFF6B35), 7);

      // Interval type label
      final typeStr = invariant > 0.01 ? '시간적(timelike)' : '광적(lightlike)';
      _lbl(canvas, typeStr, Offset(ox + dW * 0.5, dT + 8), vecColor, 8, fw: FontWeight.bold);
    }

    // Light cone lines (45°)
    canvas.drawLine(Offset(ox, oy), Offset(ox + math.min(dW - 20, dH - 20), oy - math.min(dW - 20, dH - 20)),
        Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.25)..strokeWidth = 1..style = PaintingStyle.stroke);
    _lbl(canvas, 'E=p (광)', Offset(ox + 36, oy - 30), const Color(0xFFFFD700).withValues(alpha: 0.5), 7);

    // ======= RIGHT: Component table + invariant =======
    final iL = w * 0.52, iT = 26.0;
    final iW = w - iL - 6;

    _lbl(canvas, '4-운동량 성분', Offset(iL + iW / 2, iT + 8),
        const Color(0xFFE0F4FF), 9, fw: FontWeight.bold);

    // Component bars
    final compData = <(String, double, Color)>[
      ('E/c', E, const Color(0xFFFF6B35)),
      ('px', p, const Color(0xFF64FF8C)),
      ('py', 0.0, const Color(0xFF5A8A9A)),
      ('pz', 0.0, const Color(0xFF5A8A9A)),
    ];
    final barMaxE = (E + 0.1).clamp(1.0, maxVal);
    final barTop2 = iT + 20;
    final barBotY3 = h * 0.60;
    final barH4 = barBotY3 - barTop2;
    final barW6 = iW * 0.18;
    final barGap = (iW - compData.length * barW6) / (compData.length + 1);

    for (int ci = 0; ci < compData.length; ci++) {
      final bx = iL + barGap + ci * (barW6 + barGap);
      final val2 = compData[ci].$2.abs();
      final fillH3 = (val2 / barMaxE).clamp(0.0, 1.0) * (barH4 - 4);
      final color2 = compData[ci].$3;

      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx, barTop2, barW6, barH4), const Radius.circular(3)),
          Paint()..color = const Color(0xFF1A3040));
      if (fillH3 > 0) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(bx, barBotY3 - fillH3, barW6, fillH3),
                const Radius.circular(3)),
            Paint()..color = color2.withValues(alpha: 0.8));
      }
      _lbl(canvas, compData[ci].$1, Offset(bx + barW6 / 2, barBotY3 + 7), color2, 8);
      _lbl(canvas, compData[ci].$2.toStringAsFixed(2),
          Offset(bx + barW6 / 2, barBotY3 - fillH3 - 7), color2, 7);
    }

    // Invariant display
    final invY = barBotY3 + 22;
    _lbl(canvas, '불변량 (Lorentz scalar)', Offset(iL + iW / 2, invY), const Color(0xFFE0F4FF), 8, fw: FontWeight.bold);
    _lbl(canvas, 's² = E²-p² = m₀²', Offset(iL + iW / 2, invY + 13), const Color(0xFF5A8A9A), 8);
    _lbl(canvas, '= ${invMass.toStringAsFixed(3)}', Offset(iL + iW / 2, invY + 25),
        const Color(0xFF64FF8C), 10, fw: FontWeight.bold);

    // Lorentz transform display
    final ltY = invY + 42;
    _lbl(canvas, 'v=${v.toStringAsFixed(2)}c  γ=${gamma.toStringAsFixed(3)}', Offset(iL + iW / 2, ltY),
        const Color(0xFF00D4FF), 9);
    _lbl(canvas, 'E=γm₀=${E.toStringAsFixed(3)}', Offset(iL + iW / 2, ltY + 13),
        const Color(0xFFFF6B35), 9);
    _lbl(canvas, 'p=γm₀v=${p.toStringAsFixed(3)}', Offset(iL + iW / 2, ltY + 26),
        const Color(0xFF64FF8C), 9);

    // Spacetime interval types legend
    final legY = h - 14.0;
    _lbl(canvas, '■ 시간적 s²<0', Offset(w * 0.2, legY), const Color(0xFF00D4FF), 8);
    _lbl(canvas, '■ 광적 s²=0', Offset(w * 0.5, legY), const Color(0xFFFFD700), 8);
    _lbl(canvas, '■ 공간적 s²>0', Offset(w * 0.8, legY), const Color(0xFFFF6B35), 8);

    // Vertical divider
    canvas.drawLine(Offset(w * 0.50, 24), Offset(w * 0.50, h - 18),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _FourVectorsScreenPainter oldDelegate) => true;
}
