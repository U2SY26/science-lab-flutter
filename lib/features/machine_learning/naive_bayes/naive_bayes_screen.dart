import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class NaiveBayesScreen extends StatefulWidget {
  const NaiveBayesScreen({super.key});
  @override
  State<NaiveBayesScreen> createState() => _NaiveBayesScreenState();
}

class _NaiveBayesScreenState extends State<NaiveBayesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _prior = 0.5;
  double _variance = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!_isRunning) return;
    setState(() { _time += 0.016; });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() { _time = 0; _prior = 0.5; _variance = 1.0; });
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
          const Text('나이브 베이즈', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '나이브 베이즈',
          formula: 'P(C|x) ∝ P(x|C)·P(C)',
          formulaDescription: '사전 확률과 조건부 확률을 이용하여 클래스를 분류합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _NaiveBayesPainter(
                time: _time,
                prior: _prior,
                variance: _variance,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: '사전 확률 P(C₁)',
                  value: _prior,
                  min: 0.1,
                  max: 0.9,
                  step: 0.01,
                  defaultValue: 0.5,
                  formatValue: (v) => '${(v * 100).toStringAsFixed(0)}%',

                  onChanged: (v) => setState(() => _prior = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '가우시안 분산',
                    value: _variance,
                    min: 0.3,
                    max: 3.0,
                    step: 0.1,
                    defaultValue: 1.0,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _variance = v),
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
                  _V('P(C₁)', '${(_prior * 100).toStringAsFixed(0)}%'),
                  _V('P(C₂)', '${((1 - _prior) * 100).toStringAsFixed(0)}%'),
                  _V('분산', _variance.toStringAsFixed(1)),
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

class _NaiveBayesPainter extends CustomPainter {
  final double time;
  final double prior;
  final double variance;

  _NaiveBayesPainter({
    required this.time,
    required this.prior,
    required this.variance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Layout: top 55% = scatter plot, bottom 45% = pie chart + legend
    final plotH = h * 0.58;
    final padL = 30.0, padR = 12.0, padT = 18.0, padB = 8.0;
    final plotW = w - padL - padR;

    // Axis
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1;
    canvas.drawLine(Offset(padL, padT), Offset(padL, plotH - padB), axisPaint);
    canvas.drawLine(Offset(padL, plotH - padB), Offset(padL + plotW, plotH - padB), axisPaint);

    // Title
    _drawText(canvas, '분류 특성 공간', Offset(w / 2 - 40, 2),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold));

    // Gaussian params: class1 center (-1.2, -0.8), class2 center (1.2, 0.8)
    const mu1x = -1.2, mu1y = -0.8;
    const mu2x = 1.2, mu2y = 0.8;
    final sigma = math.sqrt(variance);

    // Map data coords [-4,4] to screen
    double sx(double x) => padL + (x + 4) / 8 * plotW;
    double sy(double y) => plotH - padB - (y + 4) / 8 * (plotH - padT - padB);

    // Draw elliptical contours (3 rings each class)
    for (int ring = 1; ring <= 3; ring++) {
      final r = ring * sigma * 0.7;
      // Class 1 (cyan)
      final rect1 = Rect.fromCenter(
        center: Offset(sx(mu1x), sy(mu1y)),
        width: r * plotW / 8 * 2,
        height: r * (plotH - padT - padB) / 8 * 2 * 0.7,
      );
      canvas.drawOval(rect1, Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.12 + ring * 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0);
      // Class 2 (orange)
      final rect2 = Rect.fromCenter(
        center: Offset(sx(mu2x), sy(mu2y)),
        width: r * plotW / 8 * 2,
        height: r * (plotH - padT - padB) / 8 * 2 * 0.7,
      );
      canvas.drawOval(rect2, Paint()
        ..color = const Color(0xFFFF6B35).withValues(alpha: 0.12 + ring * 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0);
    }

    // Decision boundary: vertical line at x where P(C1|x)=P(C2|x)
    // Simplified: at the midpoint adjusted by prior
    final boundX = (mu1x + mu2x) / 2 + math.log(prior / (1 - prior)) * variance / (mu2x - mu1x);
    final bxScreen = sx(boundX.clamp(-3.5, 3.5));
    canvas.drawLine(Offset(bxScreen, padT), Offset(bxScreen, plotH - padB),
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
    _drawText(canvas, 'boundary', Offset(bxScreen + 2, padT + 2),
        const TextStyle(color: Color(0xFF64FF8C), fontSize: 8));

    // Data points
    final rng2 = math.Random(17);
    for (int i = 0; i < 70; i++) {
      final inClass1 = i < 70 * prior;
      final cx = (inClass1 ? mu1x : mu2x) + _gauss(rng2) * sigma;
      final cy = (inClass1 ? mu1y : mu2y) + _gauss(rng2) * sigma;
      if (cx < -4 || cx > 4 || cy < -4 || cy > 4) continue;
      canvas.drawCircle(
        Offset(sx(cx), sy(cy)),
        2.5,
        Paint()..color = inClass1
            ? const Color(0xFF00D4FF).withValues(alpha: 0.85)
            : const Color(0xFFFF6B35).withValues(alpha: 0.85),
      );
    }

    // Moving test point
    final testX = 2.0 * math.sin(time * 0.5);
    final testY = 1.5 * math.cos(time * 0.7);
    final testSX = sx(testX.clamp(-3.5, 3.5));
    final testSY = sy(testY.clamp(-3.5, 3.5));
    canvas.drawCircle(Offset(testSX, testSY), 5,
        Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(Offset(testSX, testSY), 2,
        Paint()..color = const Color(0xFFFFD700));
    final predicted = testX < boundX ? 'C₁' : 'C₂';
    _drawText(canvas, predicted, Offset(testSX + 6, testSY - 8),
        const TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold));

    // Axis labels
    _drawText(canvas, 'x₁', Offset(padL + plotW - 8, plotH - padB - 12),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 9));
    _drawText(canvas, 'x₂', Offset(padL + 2, padT),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 9));

    // Bottom panel: prior pie chart + legend
    final pieY = plotH + (h - plotH) * 0.3;
    final pieR = (h - plotH) * 0.32;
    final pieCenter = Offset(w * 0.22, pieY);

    // Pie chart
    final sweepC1 = prior * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: pieCenter, radius: pieR),
      -math.pi / 2,
      sweepC1,
      true,
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7),
    );
    canvas.drawArc(
      Rect.fromCircle(center: pieCenter, radius: pieR),
      -math.pi / 2 + sweepC1,
      2 * math.pi - sweepC1,
      true,
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7),
    );
    canvas.drawCircle(pieCenter, pieR,
        Paint()..color = const Color(0xFF5A8A9A)..style = PaintingStyle.stroke..strokeWidth = 1);
    _drawText(canvas, 'P(C)', Offset(pieCenter.dx - 10, pieY - pieR - 14),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));

    // Legend
    final legX = w * 0.45;
    final legY = plotH + 8.0;
    final legendItems = [
      ('클래스 1', const Color(0xFF00D4FF)),
      ('클래스 2', const Color(0xFFFF6B35)),
      ('경계선', const Color(0xFF64FF8C)),
      ('테스트', const Color(0xFFFFD700)),
    ];
    for (int i = 0; i < legendItems.length; i++) {
      final item = legendItems[i];
      final ly = legY + i * 14.0;
      canvas.drawCircle(Offset(legX + 5, ly + 5), 4, Paint()..color = item.$2.withValues(alpha: 0.8));
      _drawText(canvas, item.$1, Offset(legX + 13, ly),
          TextStyle(color: item.$2.withValues(alpha: 0.9), fontSize: 9));
    }
  }

  double _gauss(math.Random rng) {
    final u1 = rng.nextDouble();
    final u2 = rng.nextDouble();
    return math.sqrt(-2 * math.log(u1 + 1e-10)) * math.cos(2 * math.pi * u2);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _NaiveBayesPainter oldDelegate) => true;
}
