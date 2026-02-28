import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BufferSolutionScreen extends StatefulWidget {
  const BufferSolutionScreen({super.key});
  @override
  State<BufferSolutionScreen> createState() => _BufferSolutionScreenState();
}

class _BufferSolutionScreenState extends State<BufferSolutionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _ratio = 1;
  double _pka = 4.76;
  double _ph = 4.76;

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
      _ph = _pka + (math.log(_ratio) / math.ln10);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _ratio = 1.0; _pka = 4.76;
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
          Text('화학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('완충 용액', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '완충 용액',
          formula: 'pH = pKa + log([A⁻]/[HA])',
          formulaDescription: '헨더슨-하셀바흐 방정식으로 완충 용액을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BufferSolutionScreenPainter(
                time: _time,
                ratio: _ratio,
                pka: _pka,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '[A⁻]/[HA] 비율',
                value: _ratio,
                min: 0.01,
                max: 100,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _ratio = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'pKa',
                value: _pka,
                min: 1,
                max: 14,
                step: 0.01,
                defaultValue: 4.76,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _pka = v),
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
          _V('pH', _ph.toStringAsFixed(2)),
          _V('pKa', _pka.toStringAsFixed(2)),
          _V('비율', _ratio.toStringAsFixed(2)),
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

class _BufferSolutionScreenPainter extends CustomPainter {
  final double time;
  final double ratio;
  final double pka;

  _BufferSolutionScreenPainter({
    required this.time,
    required this.ratio,
    required this.pka,
  });

  void _label(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 10, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    const padL = 42.0, padR = 12.0, padT = 32.0, padB = 38.0;
    final plotW = w - padL - padR;
    final plotH = h - padT - padB;

    // pH range displayed
    const phMin = 0.0;
    const phMax = 14.0;
    // X axis: volume of strong acid added, 0..20 mL
    const volMax = 20.0;

    // Henderson-Hasselbalch: pH = pKa + log([A-]/[HA])
    // Buffer: starts with [A-]/[HA] = ratio, capacity 10 mmol each
    // As we add acid (moles), HA increases and A- decreases
    final currentPH = pka + (math.log(ratio) / math.ln10);

    // Build curves
    // Buffer curve: pH changes slowly in buffer region
    // Pure water curve: pH drops sharply

    double bufferPH(double vol) {
      // Simplification: buffer capacity ~5 mL
      // At vol=0, pH=currentPH; at vol=10 (equiv pt), pH drops
      final capacity = 10.0;
      if (vol < capacity * 0.9) {
        // buffer region: HH equation
        final aMinusFrac = (capacity - vol) / capacity;
        final haFrac = vol / capacity;
        if (haFrac <= 0) return pka + 2;
        return pka + (math.log(aMinusFrac / haFrac) / math.ln10).clamp(-2.0, 2.0);
      } else {
        // past equivalence: drops steeply
        return pka - 1.5 - (vol - capacity * 0.9) * 0.5;
      }
    }

    double waterPH(double vol) {
      // Pure water: immediately acidic
      if (vol <= 0.01) return 7.0;
      return 7.0 - math.log(vol / 0.1) / math.ln10;
    }

    double xToCanvas(double vol) => padL + (vol / volMax) * plotW;
    double phToCanvas(double ph) => padT + (1 - (ph - phMin) / (phMax - phMin)) * plotH;

    // Buffer region highlight (pKa ± 1)
    final bufRegTop = phToCanvas((pka + 1).clamp(phMin, phMax));
    final bufRegBot = phToCanvas((pka - 1).clamp(phMin, phMax));
    canvas.drawRect(
      Rect.fromLTWH(padL, bufRegTop, plotW, bufRegBot - bufRegTop),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.06),
    );
    _label(canvas, '완충 영역\npKa±1', Offset(padL + plotW - 45, bufRegTop + 2), const Color(0xFF00D4FF).withValues(alpha: 0.7), fontSize: 8);

    // pH=7 reference line
    final y7 = phToCanvas(7.0);
    canvas.drawLine(
      Offset(padL, y7), Offset(padL + plotW, y7),
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)..strokeWidth = 0.8,
    );
    _label(canvas, 'pH 7', Offset(padL + plotW + 2, y7 - 5), const Color(0xFF5A8A9A), fontSize: 8);

    // pKa line
    final ypKa = phToCanvas(pka);
    canvas.drawLine(
      Offset(padL, ypKa), Offset(padL + plotW, ypKa),
      Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.5)..strokeWidth = 0.8,
    );
    _label(canvas, 'pKa', Offset(2, ypKa - 5), const Color(0xFFFFD700), fontSize: 8);

    // Draw buffer curve
    final bufPath = Path();
    bool first = true;
    for (double vol = 0; vol <= volMax; vol += 0.2) {
      final ph = bufferPH(vol).clamp(phMin, phMax);
      final px = xToCanvas(vol);
      final py = phToCanvas(ph);
      if (first) {
        bufPath.moveTo(px, py);
        first = false;
      } else {
        bufPath.lineTo(px, py);
      }
    }
    canvas.drawPath(bufPath, Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2.5..style = PaintingStyle.stroke);

    // Draw pure water curve
    final waterPath = Path();
    first = true;
    for (double vol = 0; vol <= volMax; vol += 0.2) {
      final ph = waterPH(vol).clamp(phMin, phMax);
      final px = xToCanvas(vol);
      final py = phToCanvas(ph);
      if (first) {
        waterPath.moveTo(px, py);
        first = false;
      } else {
        waterPath.lineTo(px, py);
      }
    }
    canvas.drawPath(waterPath, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Current pH dot (animated along buffer curve)
    final animVol = (math.sin(time * 0.5) * 0.5 + 0.5) * 12.0;
    final animPH = bufferPH(animVol).clamp(phMin, phMax);
    canvas.drawCircle(
      Offset(xToCanvas(animVol), phToCanvas(animPH)),
      5,
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0;
    canvas.drawLine(Offset(padL, padT), Offset(padL, padT + plotH), axisPaint);
    canvas.drawLine(Offset(padL, padT + plotH), Offset(padL + plotW, padT + plotH), axisPaint);

    // Y axis labels (pH)
    for (int ph = 0; ph <= 14; ph += 2) {
      final yp = phToCanvas(ph.toDouble());
      _label(canvas, '$ph', Offset(2, yp - 5), const Color(0xFF5A8A9A), fontSize: 8);
      canvas.drawLine(Offset(padL - 3, yp), Offset(padL, yp), axisPaint);
    }
    _label(canvas, 'pH', Offset(2, padT - 10), const Color(0xFF5A8A9A), fontSize: 9);

    // X axis labels
    for (int v = 0; v <= 20; v += 5) {
      final xp = xToCanvas(v.toDouble());
      _label(canvas, '$v', Offset(xp - 5, padT + plotH + 6), const Color(0xFF5A8A9A), fontSize: 8);
    }
    _label(canvas, '산 첨가량 (mL)', Offset(padL + plotW / 2 - 30, padT + plotH + 18), const Color(0xFF5A8A9A), fontSize: 9);

    // Legend
    _label(canvas, '━ 완충 용액', Offset(padL + 4, padT + 4), const Color(0xFF00D4FF), fontSize: 9);
    _label(canvas, '━ 순수 물', Offset(padL + 4, padT + 15), const Color(0xFFFF6B35), fontSize: 9);
    _label(canvas, 'pH=${currentPH.toStringAsFixed(2)}  pKa=${pka.toStringAsFixed(2)}', Offset(w - 120, padT + 4), const Color(0xFFFFD700), fontSize: 9, bold: true);
  }

  @override
  bool shouldRepaint(covariant _BufferSolutionScreenPainter oldDelegate) => true;
}
