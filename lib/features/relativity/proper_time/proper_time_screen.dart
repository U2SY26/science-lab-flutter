import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ProperTimeScreen extends StatefulWidget {
  const ProperTimeScreen({super.key});
  @override
  State<ProperTimeScreen> createState() => _ProperTimeScreenState();
}

class _ProperTimeScreenState extends State<ProperTimeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _beta = 0.5;
  double _gamma = 1, _properTime = 0;

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
      _gamma = 1.0 / math.sqrt(1.0 - _beta * _beta);
      _properTime = _time / _gamma;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _beta = 0.5;
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
          const Text('고유 시간과 세계선', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '고유 시간과 세계선',
          formula: 'dτ² = dt² - dx²/c²',
          formulaDescription: '민코프스키 시공간에서 세계선과 고유 시간을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ProperTimeScreenPainter(
                time: _time,
                beta: _beta,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '속도 β (v/c)',
                value: _beta,
                min: 0.0,
                max: 0.99,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => '${v.toStringAsFixed(2)} c',
                onChanged: (v) => setState(() => _beta = v),
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
          _V('γ', '${_gamma.toStringAsFixed(3)}'),
          _V('좌표시간', '${_time.toStringAsFixed(2)} s'),
          _V('고유시간', '${_properTime.toStringAsFixed(2)} s'),
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

class _ProperTimeScreenPainter extends CustomPainter {
  final double time;
  final double beta;

  _ProperTimeScreenPainter({
    required this.time,
    required this.beta,
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

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final v = beta.clamp(0.0, 0.99);
    final gamma = 1.0 / math.sqrt(1.0 - v * v);

    _lbl(canvas, '민코프스키 시공간 & 쌍둥이 역설', Offset(w / 2, 12),
        const Color(0xFF00D4FF), 11, fw: FontWeight.bold);

    // ======= LEFT: Minkowski spacetime diagram =======
    final dL = 10.0, dT = 24.0, dR = w * 0.56, dB = h * 0.80;
    final dW = dR - dL;
    final dH = dB - dT;
    // Origin at bottom-center
    final ox = dL + dW / 2;
    final oy = dB;

    // Grid
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5..style = PaintingStyle.stroke;
    for (double gy = dT; gy <= dB; gy += dH / 5) {
      canvas.drawLine(Offset(dL, gy), Offset(dR, gy), gridP);
    }
    for (double gx = dL; gx <= dR; gx += dW / 6) {
      canvas.drawLine(Offset(gx, dT), Offset(gx, dB), gridP);
    }

    // Axes
    final axisP = Paint()..color = const Color(0xFF2A4050)..strokeWidth = 1..style = PaintingStyle.stroke;
    // ct axis (upward)
    canvas.drawLine(Offset(ox, oy), Offset(ox, dT + 4), axisP);
    canvas.drawLine(Offset(ox - 4, dT + 10), Offset(ox, dT + 4), axisP);
    canvas.drawLine(Offset(ox + 4, dT + 10), Offset(ox, dT + 4), axisP);
    _lbl(canvas, 'ct', Offset(ox + 8, dT + 8), const Color(0xFF5A8A9A), 9);
    // x axis (rightward)
    canvas.drawLine(Offset(dL, oy), Offset(dR - 4, oy), axisP);
    canvas.drawLine(Offset(dR - 10, oy - 4), Offset(dR - 4, oy), axisP);
    canvas.drawLine(Offset(dR - 10, oy + 4), Offset(dR - 4, oy), axisP);
    _lbl(canvas, 'x', Offset(dR - 2, oy - 8), const Color(0xFF5A8A9A), 9);

    // Light cone (45° lines)
    final lcP = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(ox, oy), Offset(dR, dT + (dB - dT) * (1 - (dW / 2) / dH)), lcP);
    canvas.drawLine(Offset(ox, oy), Offset(dL, dT + (dB - dT) * (1 - (dW / 2) / dH)), lcP);
    _lbl(canvas, 'light cone', Offset(dR - 20, dT + 8), const Color(0xFFFFD700).withValues(alpha: 0.5), 7);

    // Time height of diagram
    final tMax = dH - 6;

    // Worldline A: stationary (vertical line at x=0)
    final wlAPath = Path();
    wlAPath.moveTo(ox, oy);
    wlAPath.lineTo(ox, dT + 6);
    canvas.drawPath(wlAPath,
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2.5..style = PaintingStyle.stroke);
    _lbl(canvas, 'A (정지)', Offset(ox - 22, dT + 18), const Color(0xFF00D4FF), 8);

    // Worldline B: travels at v then returns (V-shape, tilted)
    final travelAngle = math.asin(v.clamp(0, 0.99));  // angle from ct axis
    final xShift = (dW * 0.28) * math.sin(travelAngle);
    final ctShift = (tMax * 0.5) * math.cos(travelAngle);
    final midX = ox + xShift;
    final midY = oy - ctShift;

    final wlBPath = Path();
    wlBPath.moveTo(ox, oy);
    wlBPath.lineTo(midX, midY);
    wlBPath.lineTo(ox, dT + 6);
    canvas.drawPath(wlBPath,
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2..style = PaintingStyle.stroke);
    _lbl(canvas, 'B (v=${v.toStringAsFixed(2)}c)', Offset(midX + 14, midY), const Color(0xFFFF6B35), 8);

    // Proper time segments on B worldline
    final properTimeB = 2 * ctShift / gamma;
    final coordTimeA = tMax;
    // Tick marks on A
    final tickCount = 5;
    for (int ti = 1; ti <= tickCount; ti++) {
      final ty = oy - (ti / tickCount) * tMax;
      canvas.drawLine(Offset(ox - 5, ty), Offset(ox + 5, ty),
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..strokeWidth = 1);
    }
    // Tick marks on B (fewer = younger)
    final bTickCount = (tickCount / gamma).round().clamp(1, tickCount);
    for (int ti = 1; ti <= bTickCount; ti++) {
      // First leg
      final leg1T = ti / (bTickCount * 2.0);
      final tx = ox + xShift * (leg1T * 2);
      final ty = oy - ctShift * (leg1T * 2);
      if (tx >= dL && ty >= dT) {
        canvas.drawLine(Offset(tx - 4, ty + 4), Offset(tx + 4, ty - 4),
            Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)..strokeWidth = 1);
      }
    }

    // Age labels at top
    _lbl(canvas, 'A 나이: ${(coordTimeA / 20).toStringAsFixed(1)} yr',
        Offset(ox - 18, dT - 2), const Color(0xFF00D4FF), 8);
    _lbl(canvas, 'B 나이: ${(properTimeB / 20).toStringAsFixed(1)} yr',
        Offset(ox + 50, dT - 2), const Color(0xFFFF6B35), 8);

    // ======= RIGHT: Time dilation info panel =======
    final iL = w * 0.59, iT = 24.0, iR = w - 6.0;
    final iW = iR - iL;

    // γ gauge
    final gageT = iT + 4;
    _lbl(canvas, 'γ = ${gamma.toStringAsFixed(3)}', Offset(iL + iW / 2, gageT + 8),
        const Color(0xFF64FF8C), 11, fw: FontWeight.bold);
    _lbl(canvas, '1/√(1-β²)', Offset(iL + iW / 2, gageT + 20),
        const Color(0xFF5A8A9A), 8);

    // Bar: coord time vs proper time
    final barT2 = gageT + 32;
    final barBotY2 = h * 0.78;
    final barH3 = barBotY2 - barT2;
    final barW5 = iW * 0.35;
    final bar1X = iL + iW * 0.18;
    final bar2X = iL + iW * 0.60;

    // Coord time bar (A)
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(bar1X, barT2, barW5, barH3), const Radius.circular(4)),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7));
    _lbl(canvas, '좌표시간', Offset(bar1X + barW5 / 2, barT2 - 7), const Color(0xFF00D4FF), 8);
    _lbl(canvas, 'Δt', Offset(bar1X + barW5 / 2, barT2 + barH3 / 2), const Color(0xFFE0F4FF), 9);

    // Proper time bar (B — shorter by γ)
    final propH = (barH3 / gamma).clamp(4.0, barH3);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(bar2X, barBotY2 - propH, barW5, propH),
            const Radius.circular(4)),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7));
    _lbl(canvas, '고유시간', Offset(bar2X + barW5 / 2, barT2 - 7), const Color(0xFFFF6B35), 8);
    _lbl(canvas, 'Δτ', Offset(bar2X + barW5 / 2, barBotY2 - propH / 2), const Color(0xFFE0F4FF), 9);

    // Brace connecting the tops
    canvas.drawLine(Offset(bar1X + barW5, barBotY2 - propH),
        Offset(bar2X, barBotY2 - propH),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 0.8..style = PaintingStyle.stroke);
    _lbl(canvas, '÷γ', Offset(iL + iW / 2, barBotY2 - propH - 6), const Color(0xFF5A8A9A), 8);

    // Bar labels at bottom
    _lbl(canvas, 'A (지구)', Offset(bar1X + barW5 / 2, barBotY2 + 8), const Color(0xFF00D4FF), 8);
    _lbl(canvas, 'B (로켓)', Offset(bar2X + barW5 / 2, barBotY2 + 8), const Color(0xFFFF6B35), 8);

    // Formula
    _lbl(canvas, 'Δτ = Δt / γ', Offset(iL + iW / 2, h * 0.86),
        const Color(0xFF64FF8C), 10, fw: FontWeight.bold);
    _lbl(canvas, 'β=${v.toStringAsFixed(2)}  γ=${gamma.toStringAsFixed(3)}',
        Offset(iL + iW / 2, h * 0.93), const Color(0xFF5A8A9A), 8);
  }

  @override
  bool shouldRepaint(covariant _ProperTimeScreenPainter oldDelegate) => true;
}
