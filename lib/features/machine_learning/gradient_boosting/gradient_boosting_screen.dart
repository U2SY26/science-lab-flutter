import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class GradientBoostingScreen extends StatefulWidget {
  const GradientBoostingScreen({super.key});
  @override
  State<GradientBoostingScreen> createState() => _GradientBoostingScreenState();
}

class _GradientBoostingScreenState extends State<GradientBoostingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _learningRate = 0.1;
  double _numRounds = 5.0;
  double _loss = 1.0;

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
      _loss = math.exp(-_learningRate * _numRounds * 1.5) + 0.05;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() { _time = 0; _learningRate = 0.1; _numRounds = 5.0; });
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
          const Text('그래디언트 부스팅', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '그래디언트 부스팅',
          formula: 'F_m = F_{m-1} + η·h_m',
          formulaDescription: '약한 학습기를 순차적으로 더하여 잔차를 줄여나갑니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _GradientBoostingPainter(
                time: _time,
                learningRate: _learningRate,
                numRounds: _numRounds,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: '학습률 (η)',
                  value: _learningRate,
                  min: 0.01,
                  max: 0.5,
                  step: 0.01,
                  defaultValue: 0.1,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _learningRate = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '부스팅 라운드',
                    value: _numRounds,
                    min: 1.0,
                    max: 10.0,
                    defaultValue: 5.0,
                    formatValue: (v) => '${v.toInt()}',
                    onChanged: (v) => setState(() => _numRounds = v),
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
                  _V('손실', _loss.toStringAsFixed(3)),
                  _V('라운드', '${_numRounds.toInt()}'),
                  _V('η', _learningRate.toStringAsFixed(2)),
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

class _GradientBoostingPainter extends CustomPainter {
  final double time;
  final double learningRate;
  final double numRounds;

  _GradientBoostingPainter({
    required this.time,
    required this.numRounds,
    required this.learningRate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final n = numRounds.toInt();

    // Animated round index: cycles through 0..n slowly
    final animRound = ((time * 0.8) % (n + 1.5)).clamp(0, n.toDouble());
    final currentRound = animRound.floor();

    // Top area: scatter plot (actual vs predicted residuals)
    final plotH = h * 0.58;
    final padL = 38.0, padR = 12.0, padT = 22.0, padB = 10.0;
    final plotW = w - padL - padR;

    // Grid
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final x = padL + plotW * i / 4;
      final y = padT + (plotH - padT - padB) * i / 4;
      canvas.drawLine(Offset(x, padT), Offset(x, plotH - padB), gridP);
      canvas.drawLine(Offset(padL, y), Offset(padL + plotW, y), gridP);
    }

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1;
    canvas.drawLine(Offset(padL, padT), Offset(padL, plotH - padB), axisPaint);
    canvas.drawLine(Offset(padL, plotH - padB), Offset(padL + plotW, plotH - padB), axisPaint);

    // Title
    _drawText(canvas, '잔차 감소 (Residual Reduction)',
        Offset(w / 2 - 70, 4),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold));

    // Data: 12 fixed points (x,y actual)
    final rng = math.Random(99);
    final dataX = List.generate(12, (i) => (i / 11.0) * 6 - 3);
    final dataY = List.generate(12, (i) => math.sin(dataX[i]) + (rng.nextDouble() - 0.5) * 0.5);

    // Initial prediction F0 = mean(y)
    final meanY = dataY.reduce((a, b) => a + b) / dataY.length;

    // Build boosted predictions up to currentRound
    var predictions = List.filled(12, meanY);
    for (int m = 0; m < currentRound && m < n; m++) {
      final residuals = List.generate(12, (i) => dataY[i] - predictions[i]);
      // Weak learner: fit a simple linear to residuals
      final avgR = residuals.reduce((a, b) => a + b) / residuals.length;
      for (int i = 0; i < 12; i++) {
        predictions[i] += learningRate * avgR * 0.8 +
            learningRate * residuals[i] * 0.4;
      }
    }

    final residuals = List.generate(12, (i) => dataY[i] - predictions[i]);
    final maxRes = residuals.map((r) => r.abs()).reduce(math.max).clamp(0.1, 5.0);

    double sx(double x) => padL + (x + 3) / 6 * plotW;
    double sy(double r) => plotH - padB - (r / maxRes * 0.9 + 0.9) / 1.8 * (plotH - padT - padB);

    // Zero line
    canvas.drawLine(Offset(padL, sy(0)), Offset(padL + plotW, sy(0)),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..strokeWidth = 1
          ..strokeCap = StrokeCap.round);

    // F0 initial prediction line
    final f0Y = sy(meanY - meanY); // residual = 0 at mean
    _drawText(canvas, 'F₀', Offset(padL + plotW + 2, f0Y - 6),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));

    // Residual points per round
    for (int i = 0; i < 12; i++) {
      final px = sx(dataX[i]);
      final py = sy(residuals[i]);
      canvas.drawCircle(Offset(px, py), 3.5,
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.9));
      // vertical line to zero
      canvas.drawLine(Offset(px, sy(0)), Offset(px, py),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.3)..strokeWidth = 1);
    }

    // Prediction curve (smooth)
    final path = Path();
    bool first = true;
    for (int i = 0; i <= 60; i++) {
      final xv = -3.0 + i * 6 / 60;
      final pv = predictions[((i / 60) * 11).round().clamp(0, 11)];
      final yv = sy(dataY[((i / 60) * 11).round().clamp(0, 11)] - pv);
      if (first) { path.moveTo(sx(xv), yv); first = false; } else { path.lineTo(sx(xv), yv); }
    }
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Axis labels
    _drawText(canvas, 'x', Offset(padL + plotW - 6, plotH - padB - 10),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 9));
    _drawText(canvas, 'r', Offset(padL - 10, padT),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 9));

    // Round label
    _drawText(canvas, '라운드 $currentRound / $n',
        Offset(padL + 4, padT + 4),
        TextStyle(color: const Color(0xFF00D4FF).withValues(alpha: 0.8), fontSize: 9));

    // Bottom: loss convergence chart
    final lossH = h - plotH - 10;
    final lossT = plotH + 8;
    final lossPadL = padL, lossPadB = 10.0;
    final lossW = w - lossPadL - padR;
    final lossAreaH = lossH - lossPadB - 16;

    _drawText(canvas, '손실 수렴 곡선',
        Offset(w / 2 - 30, lossT),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8, fontWeight: FontWeight.bold));

    // Loss curve
    final lossPath = Path();
    bool lFirst = true;
    for (int m = 0; m <= n; m++) {
      final loss = math.exp(-learningRate * m * 1.5) + 0.05;
      final lx = lossPadL + m / n * lossW;
      final ly = lossT + 14 + (1.0 - (loss - 0.05) / 0.95) * lossAreaH;
      if (lFirst) { lossPath.moveTo(lx, ly); lFirst = false; } else { lossPath.lineTo(lx, ly); }

      // Dot for each round
      final dotColor = m <= currentRound
          ? const Color(0xFF64FF8C)
          : const Color(0xFF5A8A9A).withValues(alpha: 0.4);
      canvas.drawCircle(Offset(lx, ly), m == currentRound ? 4.0 : 2.5,
          Paint()..color = dotColor);
    }
    canvas.drawPath(lossPath, Paint()
      ..color = const Color(0xFF64FF8C).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Animated current round vertical marker
    if (currentRound <= n) {
      final markerX = lossPadL + currentRound / n * lossW;
      canvas.drawLine(
        Offset(markerX, lossT + 14),
        Offset(markerX, lossT + 14 + lossAreaH),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.4)..strokeWidth = 1,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _GradientBoostingPainter oldDelegate) => true;
}
