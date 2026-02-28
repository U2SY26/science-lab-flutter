import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class HeartConductionScreen extends StatefulWidget {
  const HeartConductionScreen({super.key});
  @override
  State<HeartConductionScreen> createState() => _HeartConductionScreenState();
}

class _HeartConductionScreenState extends State<HeartConductionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _heartRate = 72;
  
  double _prInterval = 0.16, _qrs = 0.08, _qt = 0.4;

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
      _prInterval = 0.12 + 40 / _heartRate;
      _qrs = 0.08;
      _qt = 0.35 + 20 / _heartRate;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _heartRate = 72.0;
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
          Text('생물학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('심장 전기 전도', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '심장 전기 전도',
          formula: 'SA → AV → Bundle → Purkinje',
          formulaDescription: '심장 전기 전도 시스템을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _HeartConductionScreenPainter(
                time: _time,
                heartRate: _heartRate,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '심박수 (bpm)',
                value: _heartRate,
                min: 40,
                max: 200,
                step: 1,
                defaultValue: 72,
                formatValue: (v) => v.toStringAsFixed(0) + ' bpm',
                onChanged: (v) => setState(() => _heartRate = v),
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
          _V('PR', (_prInterval * 1000).toStringAsFixed(0) + ' ms'),
          _V('QRS', (_qrs * 1000).toStringAsFixed(0) + ' ms'),
          _V('QT', (_qt * 1000).toStringAsFixed(0) + ' ms'),
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

class _HeartConductionScreenPainter extends CustomPainter {
  final double time;
  final double heartRate;

  _HeartConductionScreenPainter({
    required this.time,
    required this.heartRate,
  });

  void _lbl(Canvas canvas, String text, Offset pos, Color color, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Beat period
    final beatPeriod = 60.0 / heartRate;
    final beatPhase = (time % beatPeriod) / beatPeriod; // 0..1

    // ── Upper 55%: Heart cross-section ─────────────────────────────────
    final heartTop = 22.0;
    final heartH = h * 0.52;
    final heartCx = cx;
    final heartCy = heartTop + heartH * 0.50;
    final heartW = math.min(w * 0.62, heartH * 1.1);

    // Conduction progress: SA→AV (0..0.15), AV→Bundle (0.15..0.30), Bundle→Purkinje (0.30..0.70)
    final saActive   = beatPhase < 0.15;
    final avActive   = beatPhase >= 0.15 && beatPhase < 0.30;
    final bundleActive = beatPhase >= 0.30 && beatPhase < 0.55;
    final purActive  = beatPhase >= 0.55 && beatPhase < 0.85;

    // Chamber contraction timing
    final raContract = saActive;
    final laContract = saActive;
    final rvContract = bundleActive || purActive;
    final lvContract = bundleActive || purActive;

    Color chamberColor(bool contracting, Color base) =>
        contracting ? base.withValues(alpha: 0.55) : base.withValues(alpha: 0.18);

    // Draw 4 chambers as rounded rects
    // RA (Right Atrium) - top right
    final raRect = Rect.fromCenter(center: Offset(heartCx + heartW * 0.28, heartCy - heartH * 0.28), width: heartW * 0.38, height: heartH * 0.32);
    // LA (Left Atrium) - top left
    final laRect = Rect.fromCenter(center: Offset(heartCx - heartW * 0.28, heartCy - heartH * 0.28), width: heartW * 0.38, height: heartH * 0.32);
    // RV (Right Ventricle) - bottom right
    final rvRect = Rect.fromCenter(center: Offset(heartCx + heartW * 0.24, heartCy + heartH * 0.20), width: heartW * 0.40, height: heartH * 0.40);
    // LV (Left Ventricle) - bottom left
    final lvRect = Rect.fromCenter(center: Offset(heartCx - heartW * 0.24, heartCy + heartH * 0.20), width: heartW * 0.40, height: heartH * 0.40);

    final rr = const Radius.circular(10);
    // Fill
    canvas.drawRRect(RRect.fromRectAndRadius(raRect, rr), Paint()..color = chamberColor(raContract, const Color(0xFF4488FF)));
    canvas.drawRRect(RRect.fromRectAndRadius(laRect, rr), Paint()..color = chamberColor(laContract, const Color(0xFFFF4444)));
    canvas.drawRRect(RRect.fromRectAndRadius(rvRect, rr), Paint()..color = chamberColor(rvContract, const Color(0xFF4488FF)));
    canvas.drawRRect(RRect.fromRectAndRadius(lvRect, rr), Paint()..color = chamberColor(lvContract, const Color(0xFFFF4444)));
    // Stroke
    final strokePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = const Color(0xFF5A8A9A);
    canvas.drawRRect(RRect.fromRectAndRadius(raRect, rr), strokePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(laRect, rr), strokePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rvRect, rr), strokePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(lvRect, rr), strokePaint);

    // Chamber labels
    _lbl(canvas, 'RA', Offset(raRect.center.dx, raRect.center.dy), const Color(0xFF9EB8FF), 9);
    _lbl(canvas, 'LA', Offset(laRect.center.dx, laRect.center.dy), const Color(0xFFFF8888), 9);
    _lbl(canvas, 'RV', Offset(rvRect.center.dx, rvRect.center.dy), const Color(0xFF9EB8FF), 9);
    _lbl(canvas, 'LV', Offset(lvRect.center.dx, lvRect.center.dy), const Color(0xFFFF8888), 9);

    // SA node (top-right of RA)
    final saPos = Offset(raRect.right - 8, raRect.top + 8);
    final saColor = saActive ? const Color(0xFFFFD700) : const Color(0xFF5A8A9A);
    canvas.drawCircle(saPos, 6, Paint()..color = saColor.withValues(alpha: 0.25));
    canvas.drawCircle(saPos, 6, Paint()..color = saColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _lbl(canvas, 'SA', Offset(saPos.dx + 14, saPos.dy), saColor, 7);

    // AV node (between atria and ventricles, center)
    final avPos = Offset(heartCx + heartW * 0.04, heartCy - heartH * 0.04);
    final avColor = avActive ? const Color(0xFFFFD700) : const Color(0xFF5A8A9A);
    canvas.drawCircle(avPos, 5, Paint()..color = avColor.withValues(alpha: 0.25));
    canvas.drawCircle(avPos, 5, Paint()..color = avColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _lbl(canvas, 'AV', Offset(avPos.dx + 12, avPos.dy), avColor, 7);

    // His bundle line (AV → apex)
    final hisEnd = Offset(heartCx, heartCy + heartH * 0.42);
    final bundleColor = bundleActive ? const Color(0xFF00D4FF) : const Color(0xFF1A3040);
    canvas.drawLine(avPos, hisEnd, Paint()..color = bundleColor..strokeWidth = 1.5);
    _lbl(canvas, '히스 다발', Offset(heartCx - heartW * 0.18, heartCy + heartH * 0.22), bundleColor, 7);

    // Purkinje fibers (branching from apex)
    final purkColor = purActive ? const Color(0xFF64FF8C) : const Color(0xFF1A3040);
    // Left branch
    canvas.drawLine(hisEnd, Offset(lvRect.center.dx, lvRect.bottom - 4), Paint()..color = purkColor..strokeWidth = 1.2);
    // Right branch
    canvas.drawLine(hisEnd, Offset(rvRect.center.dx, rvRect.bottom - 4), Paint()..color = purkColor..strokeWidth = 1.2);
    _lbl(canvas, '퍼킨지', Offset(heartCx, hisEnd.dy + 10), purkColor, 7);

    // Ripple wave on contracting chambers
    if (raContract || laContract) {
      final rippleR = heartH * 0.06 + beatPhase * heartH * 0.18;
      canvas.drawCircle(Offset(heartCx, heartCy - heartH * 0.28), rippleR,
          Paint()..color = const Color(0xFFFFD700).withValues(alpha: (0.15 - beatPhase).clamp(0, 0.15))
            ..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
    if (rvContract || lvContract) {
      final prog = ((beatPhase - 0.30) / 0.55).clamp(0.0, 1.0);
      final rippleR2 = heartH * 0.06 + prog * heartH * 0.22;
      canvas.drawCircle(Offset(heartCx, heartCy + heartH * 0.20), rippleR2,
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: (0.20 - prog * 0.20).clamp(0, 0.20))
            ..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    // BPM label
    _lbl(canvas, '${heartRate.toStringAsFixed(0)} BPM', Offset(cx, heartTop + heartH + 10), const Color(0xFF00D4FF), 9);

    // Divider
    final divY = heartTop + heartH + 22.0;
    canvas.drawLine(Offset(0, divY), Offset(w, divY),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    // ── Lower: ECG waveform ─────────────────────────────────────────────
    final ecgTop = divY + 4;
    final ecgBottom = h - 16.0;
    final ecgLeft = 28.0;
    final ecgRight = w - 8.0;
    final ecgH = ecgBottom - ecgTop;
    final ecgW = ecgRight - ecgLeft;
    final ecgMidY = ecgTop + ecgH / 2;

    // Grid
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5;
    canvas.drawLine(Offset(ecgLeft, ecgTop), Offset(ecgLeft, ecgBottom), gridP);
    canvas.drawLine(Offset(ecgLeft, ecgBottom), Offset(ecgRight, ecgBottom), gridP);
    canvas.drawLine(Offset(ecgLeft, ecgMidY), Offset(ecgRight, ecgMidY), gridP);

    // ECG shape function
    double ecgY(double phase) {
      // P wave
      if (phase < 0.10) { return math.exp(-math.pow((phase - 0.05) / 0.025, 2)) * 0.25; }
      // PR segment
      if (phase < 0.20) { return 0; }
      // Q
      if (phase < 0.22) { return -(phase - 0.20) / 0.02 * 0.15; }
      // R peak
      if (phase < 0.26) { return -0.15 + (phase - 0.22) / 0.04 * 1.15; }
      // S
      if (phase < 0.30) { return 1.0 - (phase - 0.26) / 0.04 * 1.25; }
      // ST segment
      if (phase < 0.40) { return (phase - 0.30) / 0.10 * 0.05; }
      // T wave
      if (phase < 0.60) { return 0.05 + math.exp(-math.pow((phase - 0.50) / 0.06, 2)) * 0.30; }
      return 0;
    }

    final scrollSpeed = heartRate / 60.0;
    final ecgPath = Path();
    final pts = 160;
    for (int i = 0; i <= pts; i++) {
      final tx = i / pts.toDouble();
      final x = ecgLeft + tx * ecgW;
      final phase = (time * scrollSpeed * 0.8 + tx * 1.5) % 1.0;
      final v = ecgY(phase);
      final y = ecgMidY - v * ecgH * 0.48;
      if (i == 0) { ecgPath.moveTo(x, y); } else { ecgPath.lineTo(x, y); }
    }
    canvas.drawPath(ecgPath, Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.8..style = PaintingStyle.stroke);

    // Wave labels
    _lbl(canvas, 'P', Offset(ecgLeft + ecgW * 0.05, ecgMidY - ecgH * 0.22), const Color(0xFF5A8A9A), 7.5);
    _lbl(canvas, 'QRS', Offset(ecgLeft + ecgW * 0.22, ecgMidY - ecgH * 0.50), const Color(0xFF5A8A9A), 7.5);
    _lbl(canvas, 'T', Offset(ecgLeft + ecgW * 0.46, ecgMidY - ecgH * 0.22), const Color(0xFF5A8A9A), 7.5);

    // Title
    _lbl(canvas, '심장 전기 전도 (Cardiac Conduction)', Offset(w / 2, 11), const Color(0xFF00D4FF), 10);
  }

  @override
  bool shouldRepaint(covariant _HeartConductionScreenPainter oldDelegate) => true;
}
