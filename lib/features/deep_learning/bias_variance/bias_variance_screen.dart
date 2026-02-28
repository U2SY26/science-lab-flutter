import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BiasVarianceScreen extends StatefulWidget {
  const BiasVarianceScreen({super.key});
  @override
  State<BiasVarianceScreen> createState() => _BiasVarianceScreenState();
}

class _BiasVarianceScreenState extends State<BiasVarianceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _complexity = 3;
  
  double _bias = 0.5, _variance = 0.1, _totalError = 0.7;

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
      _bias = 1.0 / _complexity;
      _variance = 0.05 * _complexity;
      _totalError = _bias * _bias + _variance + 0.1;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _complexity = 3.0;
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
          Text('AI/ML 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('편향-분산 트레이드오프', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '편향-분산 트레이드오프',
          formula: 'Error = Bias² + Variance + Noise',
          formulaDescription: '모델 복잡도에 따른 편향-분산 관계를 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BiasVarianceScreenPainter(
                time: _time,
                complexity: _complexity,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '모델 복잡도',
                value: _complexity,
                min: 1,
                max: 10,
                step: 0.1,
                defaultValue: 3,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _complexity = v),
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
          _V('Bias²', (_bias * _bias).toStringAsFixed(3)),
          _V('Var', _variance.toStringAsFixed(3)),
          _V('Total', _totalError.toStringAsFixed(3)),
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

class _BiasVarianceScreenPainter extends CustomPainter {
  final double time;
  final double complexity;

  _BiasVarianceScreenPainter({
    required this.time,
    required this.complexity,
  });

  // Bias², Variance, Noise, Total at normalised complexity t ∈ [0,1]
  static const double _noise = 0.08;
  double _bias2(double t)    => 0.82 * math.pow(1 - t, 2.2).toDouble();
  double _variance(double t) => 0.06 + 0.86 * math.pow(t, 2.0).toDouble();
  double _total(double t)    => _bias2(t) + _variance(t) + _noise;

  // Optimal complexity: where total error is minimum (approx by sampling)
  double _optimalT() {
    double bestT = 0, bestErr = double.infinity;
    for (int i = 0; i <= 100; i++) {
      final t = i / 100.0;
      final e = _total(t);
      if (e < bestErr) { bestErr = e; bestT = t; }
    }
    return bestT;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // Layout constants
    const lPad = 38.0; // left axis space
    const rPad = 12.0;
    const tPad = 18.0;
    const bPad = 34.0; // bottom axis space
    final w = size.width - lPad - rPad;
    final h = size.height - tPad - bPad;

    // Complexity t ∈ [0,1] from slider (complexity 1→10 maps to 0→1)
    final curT = ((complexity - 1.0) / 9.0).clamp(0.0, 1.0);
    final optT = _optimalT();

    // ── Zone fills (underfitting / overfitting) ──
    final underRect = Rect.fromLTWH(lPad, tPad, optT * w, h);
    final overRect  = Rect.fromLTWH(lPad + optT * w, tPad, (1 - optT) * w, h);
    canvas.drawRect(underRect, Paint()..color = const Color(0xFFFF4466).withValues(alpha: 0.04));
    canvas.drawRect(overRect,  Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.04));

    // Zone labels
    _label(canvas, 'Underfitting', Offset(lPad + optT * w * 0.38, tPad + 6),
        const Color(0xFFFF4466), 8.5);
    _label(canvas, 'Overfitting', Offset(lPad + optT * w + (1 - optT) * w * 0.45, tPad + 6),
        const Color(0xFFFF6B35), 8.5);

    // ── Grid lines ──
    final gridP = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.6)..strokeWidth = 0.5;
    for (int i = 1; i <= 4; i++) {
      final y = tPad + h * i / 4;
      canvas.drawLine(Offset(lPad, y), Offset(lPad + w, y), gridP);
    }

    // ── Y-axis labels ──
    for (int i = 0; i <= 4; i++) {
      final val = i / 4.0;
      final py = tPad + h * (1 - val / 1.2);
      final ytp = TextPainter(
        text: TextSpan(text: val.toStringAsFixed(2),
            style: const TextStyle(color: Color(0xFF3A6070), fontSize: 7.5)),
        textDirection: TextDirection.ltr)..layout();
      ytp.paint(canvas, Offset(lPad - ytp.width - 3, py - ytp.height / 2));
    }

    // Y-axis title
    canvas.save();
    canvas.translate(10, tPad + h / 2);
    canvas.rotate(-math.pi / 2);
    final yAxisTp = TextPainter(
      text: const TextSpan(text: 'Error',
          style: TextStyle(color: Color(0xFF5A8A9A), fontSize: 9)),
      textDirection: TextDirection.ltr)..layout();
    yAxisTp.paint(canvas, Offset(-yAxisTp.width / 2, -yAxisTp.height / 2));
    canvas.restore();

    // X-axis
    canvas.drawLine(Offset(lPad, tPad + h), Offset(lPad + w, tPad + h),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);
    canvas.drawLine(Offset(lPad, tPad), Offset(lPad, tPad + h),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    final xLabels = ['Simple', '', '', '', '', 'Complex'];
    for (int i = 0; i < xLabels.length; i++) {
      if (xLabels[i].isEmpty) continue;
      final px = lPad + i / (xLabels.length - 1) * w;
      final xtp = TextPainter(
        text: TextSpan(text: xLabels[i],
            style: const TextStyle(color: Color(0xFF3A6070), fontSize: 8)),
        textDirection: TextDirection.ltr)..layout();
      xtp.paint(canvas, Offset(px - xtp.width / 2, tPad + h + 4));
    }
    _label(canvas, 'Model Complexity →', Offset(lPad + w / 2 - 45, tPad + h + 20),
        const Color(0xFF3A6070), 8);

    // ── Helper: map (t, errorVal) → canvas Offset ──
    Offset toCanvas(double t, double err) {
      final px = lPad + t * w;
      final py = tPad + h * (1 - (err / 1.2).clamp(0.0, 1.0));
      return Offset(px, py);
    }

    const steps = 80;

    // ── Bias² area fill ──
    final biasAreaPath = Path();
    biasAreaPath.moveTo(lPad, tPad + h);
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final p = toCanvas(t, _bias2(t));
      biasAreaPath.lineTo(p.dx, p.dy);
    }
    biasAreaPath.lineTo(lPad + w, tPad + h);
    biasAreaPath.close();
    canvas.drawPath(biasAreaPath,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.07));

    // ── Variance area fill ──
    final varAreaPath = Path();
    varAreaPath.moveTo(lPad, tPad + h);
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final p = toCanvas(t, _variance(t));
      varAreaPath.lineTo(p.dx, p.dy);
    }
    varAreaPath.lineTo(lPad + w, tPad + h);
    varAreaPath.close();
    canvas.drawPath(varAreaPath,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.06));

    // ── Total error area fill (noise floor) ──
    final noiseY = toCanvas(0.5, _noise).dy;
    canvas.drawRect(Rect.fromLTWH(lPad, noiseY, w, tPad + h - noiseY),
        Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.03));

    // ── Draw curves ──
    _drawCurve(canvas, steps, (t) => toCanvas(t, _bias2(t)),
        const Color(0xFFFF6B35), 2.0);
    _drawCurve(canvas, steps, (t) => toCanvas(t, _variance(t)),
        const Color(0xFF00D4FF), 2.0);
    _drawCurve(canvas, steps, (t) => toCanvas(t, _total(t)),
        const Color(0xFFE0F4FF), 2.5);

    // Noise floor dashed line
    _drawDashedHLine(canvas, lPad, lPad + w,
        toCanvas(0.5, _noise).dy, const Color(0xFFE0F4FF).withValues(alpha: 0.3));

    // ── Optimal complexity dashed vertical ──
    final optX = lPad + optT * w;
    _drawDashedVLine(canvas, optX, tPad, tPad + h,
        const Color(0xFF64FF8C).withValues(alpha: 0.7));

    // Star at optimal total error
    final optPt = toCanvas(optT, _total(optT));
    _drawStar(canvas, optPt, 7.0, const Color(0xFF64FF8C));

    // "Optimal" label
    final optTp = TextPainter(
      text: const TextSpan(text: 'Optimal',
          style: TextStyle(color: Color(0xFF64FF8C), fontSize: 8.5, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr)..layout();
    canvas.drawRect(
        Rect.fromLTWH(optX - optTp.width / 2 - 3, tPad - 1, optTp.width + 6, optTp.height + 2),
        Paint()..color = const Color(0xFF0D1A20).withValues(alpha: 0.8));
    optTp.paint(canvas, Offset(optX - optTp.width / 2, tPad));

    // ── Animated dot on total-error curve ──
    // Pulse gently at current complexity position
    final dotPt = toCanvas(curT, _total(curT));
    final dotGlow = 0.5 + 0.5 * math.sin(time * 3.0);
    canvas.drawCircle(dotPt, 10,
        Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.12 * dotGlow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(dotPt, 5,
        Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.9));
    canvas.drawCircle(dotPt, 5,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Error value callout
    final curErr = _total(curT);
    final callTp = TextPainter(
      text: TextSpan(text: curErr.toStringAsFixed(3),
          style: const TextStyle(color: Color(0xFFE0F4FF), fontSize: 8.5, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr)..layout();
    final callX = (dotPt.dx + 8 + callTp.width > lPad + w)
        ? dotPt.dx - callTp.width - 8 : dotPt.dx + 8;
    canvas.drawRect(
        Rect.fromLTWH(callX - 2, dotPt.dy - callTp.height / 2 - 1, callTp.width + 4, callTp.height + 2),
        Paint()..color = const Color(0xFF0D1A20).withValues(alpha: 0.85));
    callTp.paint(canvas, Offset(callX, dotPt.dy - callTp.height / 2));

    // ── Legend ──
    final legends = [
      ('Bias²',    const Color(0xFFFF6B35)),
      ('Variance', const Color(0xFF00D4FF)),
      ('Total',    const Color(0xFFE0F4FF)),
    ];
    double lx = lPad;
    for (final (name, col) in legends) {
      canvas.drawLine(Offset(lx, size.height - 8), Offset(lx + 14, size.height - 8),
          Paint()..color = col..strokeWidth = 2.0..strokeCap = StrokeCap.round);
      final ltp = TextPainter(
        text: TextSpan(text: name, style: TextStyle(color: col.withValues(alpha: 0.8), fontSize: 8.5)),
        textDirection: TextDirection.ltr)..layout();
      ltp.paint(canvas, Offset(lx + 18, size.height - 8 - ltp.height / 2));
      lx += ltp.width + 30;
    }
  }

  void _drawCurve(Canvas canvas, int steps, Offset Function(double) mapper,
      Color color, double sw) {
    final path = Path();
    for (int i = 0; i <= steps; i++) {
      final p = mapper(i / steps);
      if (i == 0) { path.moveTo(p.dx, p.dy); } else { path.lineTo(p.dx, p.dy); }
    }
    canvas.drawPath(path, Paint()
      ..color = color
      ..strokeWidth = sw
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  void _drawDashedHLine(Canvas canvas, double x1, double x2, double y, Color color) {
    const dash = 6.0, gap = 4.0;
    final p = Paint()..color = color..strokeWidth = 1.0;
    double x = x1;
    while (x < x2) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(x1, x2), y), p);
      x += dash + gap;
    }
  }

  void _drawDashedVLine(Canvas canvas, double x, double y1, double y2, Color color) {
    const dash = 6.0, gap = 4.0;
    final p = Paint()..color = color..strokeWidth = 1.2;
    double y = y1;
    while (y < y2) {
      canvas.drawLine(Offset(x, y), Offset(x, (y + dash).clamp(y1, y2)), p);
      y += dash + gap;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerA = -math.pi / 2 + i * math.pi * 2 / 5;
      final innerA = outerA + math.pi / 5;
      final op = Offset(center.dx + r * math.cos(outerA), center.dy + r * math.sin(outerA));
      final ip = Offset(center.dx + r * 0.4 * math.cos(innerA), center.dy + r * 0.4 * math.sin(innerA));
      if (i == 0) { path.moveTo(op.dx, op.dy); } else { path.lineTo(op.dx, op.dy); }
      path.lineTo(ip.dx, ip.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawPath(path, Paint()..color = color);
  }

  void _label(Canvas canvas, String text, Offset pos, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _BiasVarianceScreenPainter oldDelegate) => true;
}
