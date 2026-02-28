import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class PoissonDistributionScreen extends StatefulWidget {
  const PoissonDistributionScreen({super.key});
  @override
  State<PoissonDistributionScreen> createState() => _PoissonDistributionScreenState();
}

class _PoissonDistributionScreenState extends State<PoissonDistributionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _lambda = 3;
  double _variance = 0;

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
      _variance = _lambda;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _lambda = 3;
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
          Text('수학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('포아송 분포', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '포아송 분포',
          formula: 'P(k)=λ^k·e^{-λ}/k!',
          formulaDescription: '포아송 분포로 드문 사건을 모델링합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PoissonDistributionScreenPainter(
                time: _time,
                lambda: _lambda,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '평균 λ',
                value: _lambda,
                min: 0.1,
                max: 20,
                step: 0.5,
                defaultValue: 3,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _lambda = v),
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
          _V('평균 λ', _lambda.toStringAsFixed(1)),
          _V('분산', _variance.toStringAsFixed(1)),
          _V('표준편차', math.sqrt(_variance).toStringAsFixed(2)),
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

class _PoissonDistributionScreenPainter extends CustomPainter {
  final double time;
  final double lambda;

  _PoissonDistributionScreenPainter({required this.time, required this.lambda});

  double _poissonPmf(int k, double lam) {
    if (k < 0 || lam <= 0) return 0;
    // Use log to avoid overflow: log P = k*log(λ) - λ - logGamma(k+1)
    double logFact = 0;
    for (int i = 2; i <= k; i++) {
      logFact += math.log(i);
    }
    return math.exp(k * math.log(lam) - lam - logFact);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 10 || size.height < 10) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final lam = lambda.clamp(0.1, 20.0);
    final sigma = math.sqrt(lam);
    final kMax = (lam + 4 * sigma + 4).ceil().clamp(5, 30);

    // Compute PMF
    final probs = List.generate(kMax + 1, (k) => _poissonPmf(k, lam));
    final maxP = probs.reduce(math.max);

    // Chart layout: top part = PMF histogram, bottom strip = process timeline
    const padL = 28.0, padR = 8.0, padT = 24.0;
    final chartH = size.height * 0.58;
    final chartW = size.width - padL - padR;
    final padB = size.height - padT - chartH;
    final barW = chartW / (kMax + 1);

    // Draw bars (cyan gradient)
    for (int k = 0; k <= kMax; k++) {
      final prob = probs[k];
      final barH = maxP > 0 ? (prob / maxP) * chartH : 0.0;
      final darkness = 1.0 - (prob / (maxP + 0.001));
      final col = Color.lerp(const Color(0xFF00D4FF), const Color(0xFF003040), darkness * 0.7)!;
      final x = padL + k * barW;
      final y = padT + chartH - barH;
      canvas.drawRect(
        Rect.fromLTWH(x + 1, y, barW - 2, barH),
        Paint()..color = col.withValues(alpha: 0.9)..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + 1, y, barW - 2, barH),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.25)..strokeWidth = 0.5..style = PaintingStyle.stroke,
      );
    }

    // Mean vertical line (λ)
    final meanX = padL + lam * barW + barW / 2;
    const dashH = 5.0;
    for (double y = padT; y < padT + chartH; y += dashH * 2) {
      canvas.drawLine(
        Offset(meanX, y), Offset(meanX, y + dashH),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.8)..strokeWidth = 1.2,
      );
    }

    // Normal approximation curve (for large λ)
    if (lam >= 5) {
      final normPath = Path();
      bool normStarted = false;
      for (int px = 0; px <= chartW.toInt(); px++) {
        final kVal = px / barW;
        final z = (kVal - lam) / (sigma + 0.001);
        final normP = math.exp(-0.5 * z * z) / (sigma * math.sqrt(2 * math.pi));
        final normH = maxP > 0 ? (normP / maxP) * chartH : 0.0;
        final x = padL + px.toDouble();
        final y = padT + chartH - normH;
        if (!normStarted) { normPath.moveTo(x, y); normStarted = true; }
        else { normPath.lineTo(x, y); }
      }
      canvas.drawPath(normPath, Paint()
        ..color = const Color(0xFFFF6B35).withValues(alpha: 0.9)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke);
    }

    // Axes
    final axPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.8;
    canvas.drawLine(Offset(padL, padT), Offset(padL, padT + chartH), axPaint);
    canvas.drawLine(Offset(padL, padT + chartH), Offset(padL + chartW, padT + chartH), axPaint);

    // X-axis labels (every 5 or every 2)
    final step = kMax > 20 ? 5 : (kMax > 10 ? 2 : 1);
    for (int k = 0; k <= kMax; k += step) {
      final x = padL + k * barW + barW / 2;
      final tp = TextPainter(
        text: TextSpan(text: '$k', style: const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, padT + chartH + 3));
    }

    // Y-axis ticks
    for (int t = 0; t <= 3; t++) {
      final y = padT + chartH * (1 - t / 3);
      final lbl = (maxP * t / 3).toStringAsFixed(2);
      final tp = TextPainter(
        text: TextSpan(text: lbl, style: const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Poisson process timeline (bottom strip)
    final timelineY = padT + chartH + padB * 0.3;
    final timelineW = chartW;
    canvas.drawLine(Offset(padL, timelineY), Offset(padL + timelineW, timelineY),
      Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1.2);

    // Simulate events with exponential inter-arrival using seeded RNG
    // Seed changes slowly with time so events animate in
    final rng = math.Random(42);
    double t = 0;
    const timeWindow = 10.0;
    while (t < timeWindow) {
      final inter = -math.log(1 - rng.nextDouble()) / lam;
      t += inter;
      if (t >= timeWindow) break;
      // Animate: events appear as time progresses
      final eventX = padL + (t / timeWindow) * timelineW;
      final alpha = (1.0 - (time * 0.3 - (t / timeWindow * 4)).abs().clamp(0, 1)).clamp(0.2, 1.0);
      canvas.drawCircle(Offset(eventX, timelineY), 4,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: alpha.toDouble())..style = PaintingStyle.fill);
    }

    // Key property label: mean = variance = λ
    final propTp = TextPainter(
      text: TextSpan(text: 'E[X] = Var[X] = λ = ${lam.toStringAsFixed(1)}',
        style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    propTp.paint(canvas, Offset(padL + 4, 6));

    // σ label
    final sigTp = TextPainter(
      text: TextSpan(text: 'σ = ${sigma.toStringAsFixed(2)}',
        style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    sigTp.paint(canvas, Offset(padL + chartW - sigTp.width, 6));
  }

  @override
  bool shouldRepaint(covariant _PoissonDistributionScreenPainter oldDelegate) => true;
}
