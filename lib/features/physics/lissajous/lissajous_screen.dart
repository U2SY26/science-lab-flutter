import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class LissajousScreen extends StatefulWidget {
  const LissajousScreen({super.key});
  @override
  State<LissajousScreen> createState() => _LissajousScreenState();
}

class _LissajousScreenState extends State<LissajousScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _freqRatio = 2;
  double _phaseDelta = 0;


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
      
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _freqRatio = 2; _phaseDelta = 0.0;
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
          const Text('리사주 도형', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '리사주 도형',
          formula: 'x=sin(at+δ), y=sin(bt)',
          formulaDescription: '수직 진동에서 리사주 도형을 생성합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _LissajousScreenPainter(
                time: _time,
                freqRatio: _freqRatio,
                phaseDelta: _phaseDelta,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '주파수 비 a/b',
                value: _freqRatio,
                min: 1,
                max: 5,
                step: 1,
                defaultValue: 2,
                formatValue: (v) => v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _freqRatio = v),
              ),
              advancedControls: [
            SimSlider(
                label: '위상차 δ',
                value: _phaseDelta,
                min: 0,
                max: 3.14,
                step: 0.05,
                defaultValue: 0,
                formatValue: (v) => '${v.toStringAsFixed(2)} rad',
                onChanged: (v) => setState(() => _phaseDelta = v),
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
          _V('a/b', _freqRatio.toStringAsFixed(0)),
          _V('δ', '${_phaseDelta.toStringAsFixed(2)} rad'),
          _V('시간', _time.toStringAsFixed(1)),
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

class _LissajousScreenPainter extends CustomPainter {
  final double time;
  final double freqRatio;
  final double phaseDelta;

  _LissajousScreenPainter({
    required this.time,
    required this.freqRatio,
    required this.phaseDelta,
  });

  void _label(Canvas canvas, String text, Offset pos, Color color, double sz) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: sz, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;
    // Layout: margin top/bottom for sin wave traces, center square for figure
    final marginH = h * 0.18; // top/bottom margin for y-wave trace
    final marginW = w * 0.18; // left/right margin for x-wave trace
    final figLeft = marginW;
    final figTop = marginH;
    final figW = w - marginW * 2;
    final figH = h - marginH * 2;
    final cx = figLeft + figW / 2;
    final cy = figTop + figH / 2;
    final radius = math.min(figW, figH) * 0.42;

    // Background grid for figure area
    final gridP = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.4)..strokeWidth = 0.5;
    canvas.drawRect(Rect.fromLTWH(figLeft, figTop, figW, figH),
        Paint()..color = const Color(0xFF0A0A0F));
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(Offset(figLeft + figW * i / 4, figTop),
          Offset(figLeft + figW * i / 4, figTop + figH), gridP);
      canvas.drawLine(Offset(figLeft, figTop + figH * i / 4),
          Offset(figLeft + figW, figTop + figH * i / 4), gridP);
    }
    // Axes
    final axisP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1;
    canvas.drawLine(Offset(cx, figTop), Offset(cx, figTop + figH), axisP);
    canvas.drawLine(Offset(figLeft, cy), Offset(figLeft + figW, cy), axisP);

    final a = freqRatio; // x freq
    const b = 1.0;       // y freq
    final delta = phaseDelta;

    // Number of steps — full period
    const steps = 500;
    final tPeriod = 2 * math.pi;

    // Current drawing position (animated — show pen drawing)
    final drawFraction = ((time * 0.4) % 1.0);
    final drawSteps = (drawFraction * steps).toInt().clamp(1, steps);

    // Draw full faded trail
    for (int i = 1; i < steps; i++) {
      final t0 = (i - 1) / steps * tPeriod;
      final t1 = i / steps * tPeriod;
      final x0 = cx + radius * math.sin(a * t0 + delta);
      final y0 = cy - radius * math.sin(b * t0);
      final x1 = cx + radius * math.sin(a * t1 + delta);
      final y1 = cy - radius * math.sin(b * t1);
      // Color: dark cyan gradient
      final frac = i / steps;
      final alpha = (0.15 + frac * 0.2).clamp(0.0, 1.0);
      canvas.drawLine(Offset(x0, y0), Offset(x1, y1),
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: alpha)..strokeWidth = 1);
    }

    // Draw bright animated trail up to drawSteps
    for (int i = 1; i < drawSteps; i++) {
      final t0 = (i - 1) / steps * tPeriod;
      final t1 = i / steps * tPeriod;
      final x0 = cx + radius * math.sin(a * t0 + delta);
      final y0 = cy - radius * math.sin(b * t0);
      final x1 = cx + radius * math.sin(a * t1 + delta);
      final y1 = cy - radius * math.sin(b * t1);
      final frac = i / drawSteps;
      final alpha = (0.3 + frac * 0.7).clamp(0.0, 1.0);
      canvas.drawLine(Offset(x0, y0), Offset(x1, y1),
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: alpha)..strokeWidth = 1.8);
    }

    // Current pen dot
    final tCur = drawFraction * tPeriod;
    final penX = cx + radius * math.sin(a * tCur + delta);
    final penY = cy - radius * math.sin(b * tCur);
    canvas.drawCircle(Offset(penX, penY), 5,
        Paint()..color = const Color(0xFF00D4FF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(Offset(penX, penY), 3, Paint()..color = const Color(0xFFE0F4FF));

    // -- Top margin: x oscillation sin(a*t+δ) --
    final topCy = marginH * 0.5;
    final topAmp = marginH * 0.35;
    final xWavePath = Path();
    for (int i = 0; i <= steps; i++) {
      final t = i / steps * tPeriod;
      final xNorm = math.sin(a * t + delta);
      final px = figLeft + (i / steps) * figW;
      final py = topCy - xNorm * topAmp;
      if (i == 0) { xWavePath.moveTo(px, py); } else { xWavePath.lineTo(px, py); }
    }
    canvas.drawPath(xWavePath, Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke);
    // vertical guide line from pen to top
    canvas.drawLine(Offset(penX, topCy), Offset(penX, figTop),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.3)..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round);

    // -- Left margin: y oscillation sin(b*t) --
    final leftCx = marginW * 0.5;
    final leftAmp = marginW * 0.35;
    final yWavePath = Path();
    for (int i = 0; i <= steps; i++) {
      final t = i / steps * tPeriod;
      final yNorm = math.sin(b * t);
      final py = figTop + (i / steps) * figH;
      final px = leftCx + yNorm * leftAmp;
      if (i == 0) { yWavePath.moveTo(px, py); } else { yWavePath.lineTo(px, py); }
    }
    canvas.drawPath(yWavePath, Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(leftCx, penY), Offset(figLeft, penY),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.3)..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round);

    // Labels
    _label(canvas, 'x=sin(${a.toInt()}t+δ)', Offset(figLeft, 2), const Color(0xFF00D4FF), 9);
    _label(canvas, 'y=sin(t)', Offset(2, figTop + 2), const Color(0xFFFF6B35), 9);
    _label(canvas, 'a/b=${a.toInt()}  δ=${phaseDelta.toStringAsFixed(2)}rad',
        Offset(cx - 40, figTop + figH + 3), const Color(0xFF5A8A9A), 9);
  }

  @override
  bool shouldRepaint(covariant _LissajousScreenPainter oldDelegate) => true;
}
