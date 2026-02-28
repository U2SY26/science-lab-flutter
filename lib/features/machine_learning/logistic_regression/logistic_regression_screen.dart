import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class LogisticRegressionScreen extends StatefulWidget {
  const LogisticRegressionScreen({super.key});
  @override
  State<LogisticRegressionScreen> createState() => _LogisticRegressionScreenState();
}

class _LogisticRegressionScreenState extends State<LogisticRegressionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _weight = 1.0;
  double _bias = 0.0;
  double _accuracy = 0;

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
      _accuracy = 0;
      int correct = 0, total = 20;
      final rng = math.Random(42);
      for (int i = 0; i < total; i++) {
        final x = (i - total / 2) * 0.5;
        final y = 1.0 / (1.0 + math.exp(-(_weight * x + _bias)));
        final predicted = y > 0.5 ? 1 : 0;
        final actual = x > 0 ? 1 : 0;
        if (predicted == actual) correct++;
      }
      _accuracy = correct / total;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _weight = 1.0;
      _bias = 0.0;
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
          const Text('로지스틱 회귀', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '로지스틱 회귀',
          formula: 'σ(z) = 1/(1+e⁻ᶻ)',
          formulaDescription: '시그모이드 함수를 이용한 이진 분류 경계를 학습합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _LogisticRegressionScreenPainter(
                time: _time,
                weight: _weight,
                bias: _bias,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '가중치 (w)',
                value: _weight,
                min: -5.0,
                max: 5.0,
                step: 0.1,
                defaultValue: 1.0,
                formatValue: (v) => '${v.toStringAsFixed(1)}',
                onChanged: (v) => setState(() => _weight = v),
              ),
              advancedControls: [
            SimSlider(
                label: '편향 (b)',
                value: _bias,
                min: -3.0,
                max: 3.0,
                step: 0.1,
                defaultValue: 0.0,
                formatValue: (v) => '${v.toStringAsFixed(1)}',
                onChanged: (v) => setState(() => _bias = v),
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
          _V('정확도', '${(_accuracy * 100).toStringAsFixed(0)}%'),
          _V('가중치', '${_weight.toStringAsFixed(1)}'),
          _V('편향', '${_bias.toStringAsFixed(1)}'),
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

class _LogisticRegressionScreenPainter extends CustomPainter {
  final double time;
  final double weight;
  final double bias;

  _LogisticRegressionScreenPainter({
    required this.time,
    required this.weight,
    required this.bias,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Layout: top 60% sigmoid curve, bottom 40% 2D boundary panel
    final sigH = h * 0.60;
    final padL = 36.0, padR = 12.0, padT = 20.0, padB = 10.0;
    final plotW = w - padL - padR;
    final plotAreaH = sigH - padT - padB;

    // Grid
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final gx = padL + plotW * i / 4;
      final gy = padT + plotAreaH * i / 4;
      canvas.drawLine(Offset(gx, padT), Offset(gx, sigH - padB), gridP);
      canvas.drawLine(Offset(padL, gy), Offset(padL + plotW, gy), gridP);
    }

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1;
    canvas.drawLine(Offset(padL, padT), Offset(padL, sigH - padB), axisPaint);
    canvas.drawLine(Offset(padL, sigH - padB), Offset(padL + plotW, sigH - padB), axisPaint);

    // P=0.5 horizontal guide
    final p05Y = padT + plotAreaH * 0.5;
    canvas.drawLine(Offset(padL, p05Y), Offset(padL + plotW, p05Y),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round);
    _text(canvas, 'P=0.5', Offset(padL + plotW + 2, p05Y - 5),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));

    // Title
    _text(canvas, '시그모이드 함수  σ(wx+b)', Offset(w / 2 - 60, 4),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold));

    // x range [-6, 6]
    double sx(double x) => padL + (x + 6) / 12 * plotW;
    double py(double p) => padT + (1.0 - p) * plotAreaH;

    // Sigmoid curve
    final sigPath = Path();
    bool first = true;
    for (int i = 0; i <= 120; i++) {
      final xv = -6.0 + i * 12 / 120;
      final z = weight * xv + bias;
      final pv = 1.0 / (1.0 + math.exp(-z));
      final px = sx(xv);
      final pyv = py(pv);
      if (first) { sigPath.moveTo(px, pyv); first = false; } else { sigPath.lineTo(px, pyv); }
    }
    canvas.drawPath(sigPath, Paint()
      ..color = const Color(0xFF00D4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0);

    // Decision boundary (x where wx+b=0 => x=-b/w)
    final boundX = (weight.abs() > 0.01) ? -bias / weight : 0.0;
    final bsx = sx(boundX.clamp(-5.5, 5.5));
    canvas.drawLine(Offset(bsx, padT), Offset(bsx, sigH - padB),
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
    _text(canvas, 'x*=${boundX.toStringAsFixed(1)}', Offset(bsx + 2, padT + 2),
        const TextStyle(color: Color(0xFF64FF8C), fontSize: 8));

    // Data points (class 0 left, class 1 right)
    final rng = math.Random(7);
    for (int i = 0; i < 20; i++) {
      final isC1 = i >= 10;
      final xv = (isC1 ? 1.5 : -1.5) + (rng.nextDouble() - 0.5) * 3;
      final z = weight * xv + bias;
      final pv = 1.0 / (1.0 + math.exp(-z));
      final ptX = sx(xv.clamp(-5.5, 5.5));
      final ptY = py(isC1 ? 1.0 : 0.0) + (rng.nextDouble() - 0.5) * 10;
      canvas.drawCircle(Offset(ptX, ptY.clamp(padT, sigH - padB)),
          3.0,
          Paint()..color = isC1
              ? const Color(0xFF00D4FF).withValues(alpha: 0.8)
              : const Color(0xFFFF6B35).withValues(alpha: 0.8));
      // prediction marker on curve
      canvas.drawLine(Offset(ptX, ptY.clamp(padT, sigH - padB)),
          Offset(ptX, py(pv).clamp(padT, sigH - padB)),
          Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.3)..strokeWidth = 0.8);
    }

    // Axis labels
    _text(canvas, 'x', Offset(padL + plotW - 6, sigH - padB - 10),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 9));
    _text(canvas, 'P(y=1)', Offset(2, padT),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));
    _text(canvas, '0', Offset(padL - 10, sigH - padB - 6),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));
    _text(canvas, '1', Offset(padL - 10, padT - 2),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));

    // Bottom panel: BCE loss display and 2D decision region
    final panelY = sigH + 6;
    final panelH = h - panelY - 6;
    final panelW = w;

    // Binary cross-entropy loss for current params
    double totalLoss = 0;
    final rng2 = math.Random(7);
    for (int i = 0; i < 20; i++) {
      final isC1 = i >= 10;
      final xv = (isC1 ? 1.5 : -1.5) + (rng2.nextDouble() - 0.5) * 3;
      final z = weight * xv + bias;
      final pv = 1.0 / (1.0 + math.exp(-z.clamp(-20, 20)));
      final y = isC1 ? 1.0 : 0.0;
      totalLoss += -(y * math.log(pv + 1e-9) + (1 - y) * math.log(1 - pv + 1e-9));
    }
    totalLoss /= 20;

    _text(canvas, 'BCE 손실: ${totalLoss.toStringAsFixed(3)}',
        Offset(padL, panelY + 2),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));

    // 2D decision region strip
    final stripW = panelW * 0.55;
    final stripX = w - stripW - 4;
    final stripH = panelH - 8;
    _text(canvas, '결정 영역', Offset(stripX, panelY),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));
    for (int xi = 0; xi < stripW.toInt(); xi += 2) {
      final xv = -6.0 + xi / stripW * 12;
      final z = weight * xv + bias;
      final pv = 1.0 / (1.0 + math.exp(-z));
      final col = Color.lerp(
        const Color(0xFFFF6B35).withValues(alpha: 0.5),
        const Color(0xFF00D4FF).withValues(alpha: 0.5),
        pv,
      )!;
      canvas.drawRect(
        Rect.fromLTWH(stripX + xi, panelY + 12, 2, stripH - 12),
        Paint()..color = col,
      );
    }
    // boundary marker on strip
    final bStrip = stripX + (boundX.clamp(-6.0, 6.0) + 6) / 12 * stripW;
    canvas.drawLine(Offset(bStrip, panelY + 12), Offset(bStrip, panelY + stripH),
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5);
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _LogisticRegressionScreenPainter oldDelegate) => true;
}
