import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BinomialDistributionScreen extends StatefulWidget {
  const BinomialDistributionScreen({super.key});
  @override
  State<BinomialDistributionScreen> createState() => _BinomialDistributionScreenState();
}

class _BinomialDistributionScreenState extends State<BinomialDistributionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _trials = 10;
  double _probability = 0.5;
  double _mean = 0, _variance = 0;

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
      _mean = _trials * _probability;
      _variance = _trials * _probability * (1 - _probability);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _trials = 10; _probability = 0.5;
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
          const Text('이항 분포', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '이항 분포',
          formula: 'P(k)=C(n,k)p^k(1-p)^{n-k}',
          formulaDescription: '이항 확률 분포를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BinomialDistributionScreenPainter(
                time: _time,
                trials: _trials,
                probability: _probability,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '시행 횟수 n',
                value: _trials,
                min: 1,
                max: 50,
                step: 1,
                defaultValue: 10,
                formatValue: (v) => v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _trials = v),
              ),
              advancedControls: [
            SimSlider(
                label: '성공 확률 p',
                value: _probability,
                min: 0.01,
                max: 0.99,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _probability = v),
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
          _V('평균', _mean.toStringAsFixed(2)),
          _V('분산', _variance.toStringAsFixed(2)),
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

class _BinomialDistributionScreenPainter extends CustomPainter {
  final double time;
  final double trials;
  final double probability;

  _BinomialDistributionScreenPainter({required this.time, required this.trials, required this.probability});

  // log-gamma for large factorials
  double _logGamma(int n) {
    if (n <= 1) return 0;
    double s = 0;
    for (int i = 2; i <= n; i++) s += math.log(i);
    return s;
  }

  double _binomialPmf(int k, int n, double p) {
    if (p <= 0) return k == 0 ? 1.0 : 0.0;
    if (p >= 1) return k == n ? 1.0 : 0.0;
    final logP = _logGamma(n) - _logGamma(k) - _logGamma(n - k)
        + k * math.log(p) + (n - k) * math.log(1 - p);
    return math.exp(logP);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 10 || size.height < 10) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final n = trials.round().clamp(1, 50);
    final p = probability.clamp(0.01, 0.99);
    final mean = n * p;
    final sigma = math.sqrt(n * p * (1 - p));

    // Compute PMF values
    final probs = List.generate(n + 1, (k) => _binomialPmf(k, n, p));
    final maxP = probs.reduce(math.max);

    // Chart area
    const padL = 28.0, padR = 8.0, padT = 24.0, padB = 28.0;
    final chartW = size.width - padL - padR;
    final chartH = size.height - padT - padB;
    final barW = chartW / (n + 1);

    // Animate bars growing from bottom (grow-in during first 1.5s)
    final growFrac = (time / 1.5).clamp(0.0, 1.0);

    // ±1σ shaded region
    final sigmaL = (mean - sigma).clamp(0, n.toDouble());
    final sigmaR = (mean + sigma).clamp(0, n.toDouble());
    final shadeX1 = padL + sigmaL * barW;
    final shadeX2 = padL + (sigmaR + 1) * barW;
    canvas.drawRect(
      Rect.fromLTWH(shadeX1, padT, shadeX2 - shadeX1, chartH),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.07),
    );

    // Bars
    for (int k = 0; k <= n; k++) {
      final prob = probs[k];
      final barH = maxP > 0 ? (prob / maxP) * chartH * growFrac : 0.0;
      final distFromMean = (k - mean).abs() / (sigma + 0.01);
      final t = (distFromMean / 3).clamp(0.0, 1.0);
      final col = Color.lerp(const Color(0xFF00D4FF), const Color(0xFF1A3040), t)!;
      final x = padL + k * barW;
      final y = padT + chartH - barH;
      canvas.drawRect(Rect.fromLTWH(x + 1, y, barW - 2, barH),
        Paint()..color = col.withValues(alpha: 0.85)..style = PaintingStyle.fill);
      canvas.drawRect(Rect.fromLTWH(x + 1, y, barW - 2, barH),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.3)..strokeWidth = 0.5..style = PaintingStyle.stroke);
    }

    // Mean dashed vertical line
    final meanX = padL + mean * barW + barW / 2;
    const dashH = 6.0;
    for (double y = padT; y < padT + chartH; y += dashH * 2) {
      canvas.drawLine(
        Offset(meanX, y), Offset(meanX, y + dashH),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.8)..strokeWidth = 1.2,
      );
    }

    // Normal approximation curve (when n > 10)
    if (n > 10) {
      final normPath = Path();
      bool normStarted = false;
      for (int px = 0; px <= chartW.toInt(); px++) {
        final kVal = px / barW;
        final z = (kVal - mean) / (sigma + 0.01);
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

    // Cumulative distribution (orange step function, right axis)
    double cumP = 0;
    final cumPath = Path();
    bool cumStarted = false;
    for (int k = 0; k <= n; k++) {
      cumP += probs[k];
      final x = padL + k * barW;
      final y = padT + chartH * (1 - cumP.clamp(0, 1));
      if (!cumStarted) { cumPath.moveTo(x, y); cumStarted = true; }
      else { cumPath.lineTo(x, y); }
      cumPath.lineTo(x + barW, y);
    }
    canvas.drawPath(cumPath, Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke);

    // Y-axis ticks
    final axPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.8;
    canvas.drawLine(Offset(padL, padT), Offset(padL, padT + chartH), axPaint);
    canvas.drawLine(Offset(padL, padT + chartH), Offset(padL + chartW, padT + chartH), axPaint);
    for (int t = 0; t <= 4; t++) {
      final y = padT + chartH * (1 - t / 4);
      final lbl = (maxP * t / 4).toStringAsFixed(2);
      final tp = TextPainter(
        text: TextSpan(text: lbl, style: const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Labels
    final mtp = TextPainter(
      text: TextSpan(text: 'μ=${mean.toStringAsFixed(1)}  σ=${sigma.toStringAsFixed(1)}',
        style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    mtp.paint(canvas, Offset(padL + 4, 6));
  }

  @override
  bool shouldRepaint(covariant _BinomialDistributionScreenPainter oldDelegate) => true;
}
