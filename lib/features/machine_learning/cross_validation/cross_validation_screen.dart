import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CrossValidationScreen extends StatefulWidget {
  const CrossValidationScreen({super.key});
  @override
  State<CrossValidationScreen> createState() => _CrossValidationScreenState();
}

class _CrossValidationScreenState extends State<CrossValidationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _kFolds = 5;
  
  double _avgScore = 0.85, _std = 0.03;

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
      final k = _kFolds.toInt();
      _avgScore = 0.8 + 0.05 * math.sin(_time + k.toDouble());
      _std = 0.1 / math.sqrt(k.toDouble());
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _kFolds = 5.0;
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
          const Text('교차 검증', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '교차 검증',
          formula: 'CV = (1/k)Σ score_i',
          formulaDescription: 'K-Fold 교차 검증의 과정을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CrossValidationScreenPainter(
                time: _time,
                kFolds: _kFolds,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'K (폴드 수)',
                value: _kFolds,
                min: 2,
                max: 10,
                step: 1,
                defaultValue: 5,
                formatValue: (v) => v.toInt().toString() + '-fold',
                onChanged: (v) => setState(() => _kFolds = v),
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
          _V('평균', (_avgScore * 100).toStringAsFixed(1) + '%'),
          _V('표준편차', (_std * 100).toStringAsFixed(2) + '%'),
          _V('K', _kFolds.toInt().toString()),
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

class _CrossValidationScreenPainter extends CustomPainter {
  final double time;
  final double kFolds;

  _CrossValidationScreenPainter({
    required this.time,
    required this.kFolds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final k = kFolds.toInt().clamp(2, 10);
    // Which fold is currently highlighted (cycles with time)
    final cycleLen = k * 1.8;
    final activeFold = ((time % cycleLen) / cycleLen * k).floor().clamp(0, k - 1);
    // Score for each fold: stable seeded + small time wobble
    final rng = math.Random(42);
    final baseScores = List.generate(k, (i) => 0.72 + rng.nextDouble() * 0.20);
    final scores = List.generate(k,
        (i) => (baseScores[i] + 0.03 * math.sin(time * 0.6 + i)).clamp(0.55, 0.99));

    // ── Section 1: Fold strip (top ~28%) ──
    const stripTop = 18.0;
    const stripH = 32.0;
    const stripPadX = 14.0;
    final stripW = size.width - stripPadX * 2;
    final blockW = stripW / k;

    // "Dataset" label
    final dstp = TextPainter(
      text: const TextSpan(text: 'Dataset',
          style: TextStyle(color: Color(0xFF5A8A9A), fontSize: 9)),
      textDirection: TextDirection.ltr)..layout();
    dstp.paint(canvas, Offset(stripPadX, stripTop - 13));

    for (int i = 0; i < k; i++) {
      final bx = stripPadX + i * blockW;
      final isVal = i == activeFold;
      final rect = Rect.fromLTWH(bx + 1, stripTop, blockW - 2, stripH);

      if (isVal) {
        // Validation block — orange glow
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(5)),
            Paint()
              ..color = const Color(0xFFFF6B35).withValues(alpha: 0.25)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.85));
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            Paint()
              ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      } else {
        // Train block — cyan
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.25));
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            Paint()
              ..color = const Color(0xFF00D4FF).withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0);
      }

      // Fold index label
      final ltp = TextPainter(
        text: TextSpan(text: '${i + 1}',
            style: TextStyle(
                color: isVal ? const Color(0xFF001822) : const Color(0xFF00D4FF).withValues(alpha: 0.8),
                fontSize: 9, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)..layout();
      ltp.paint(canvas, Offset(bx + (blockW - ltp.width) / 2, stripTop + (stripH - ltp.height) / 2));
    }

    // Legend chips
    _drawChip(canvas, Offset(stripPadX, stripTop + stripH + 6), 'Train', const Color(0xFF00D4FF));
    _drawChip(canvas, Offset(stripPadX + 58, stripTop + stripH + 6), 'Val', const Color(0xFFFF6B35));

    // ── Section 2: Score bar chart (middle ~38%) ──
    const barAreaTop = 98.0;
    const barAreaH = 110.0;
    final barMaxH = barAreaH - 24.0;
    final barW = (stripW / k - 4).clamp(4.0, 40.0);

    // Axis line
    canvas.drawLine(
        Offset(stripPadX, barAreaTop + barMaxH),
        Offset(stripPadX + stripW, barAreaTop + barMaxH),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    // Y-axis labels
    for (final yv in [0.6, 0.8, 1.0]) {
      final py = barAreaTop + barMaxH - (yv - 0.5) / 0.5 * barMaxH;
      final ytp = TextPainter(
        text: TextSpan(text: '${(yv * 100).toInt()}%',
            style: const TextStyle(color: Color(0xFF3A6070), fontSize: 7.5)),
        textDirection: TextDirection.ltr)..layout();
      ytp.paint(canvas, Offset(0, py - 5));
      canvas.drawLine(Offset(stripPadX, py), Offset(stripPadX + stripW, py),
          Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.5)..strokeWidth = 0.5);
    }

    for (int i = 0; i < k; i++) {
      final score = scores[i];
      final isCur = i == activeFold;
      final bx = stripPadX + i * (stripW / k) + (stripW / k - barW) / 2;
      final filledH = ((score - 0.5) / 0.5 * barMaxH).clamp(0.0, barMaxH);
      final barRect = Rect.fromLTWH(bx, barAreaTop + barMaxH - filledH, barW, filledH);
      final color = isCur ? const Color(0xFFFF6B35) : const Color(0xFF00D4FF);

      canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
          Paint()..shader = LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [color.withValues(alpha: 0.35), color.withValues(alpha: isCur ? 1.0 : 0.75)],
          ).createShader(barRect));

      if (isCur) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(barRect.inflate(2), const Radius.circular(4)),
            Paint()
              ..color = const Color(0xFFFF6B35).withValues(alpha: 0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      }

      // Score text
      final stp = TextPainter(
        text: TextSpan(text: '${(score * 100).toStringAsFixed(0)}%',
            style: TextStyle(color: color, fontSize: 7.5, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)..layout();
      stp.paint(canvas, Offset(bx + (barW - stp.width) / 2, barAreaTop + barMaxH - filledH - 12));
    }

    // "Fold Scores" label
    final fstp = TextPainter(
      text: const TextSpan(text: 'Fold Scores',
          style: TextStyle(color: Color(0xFF5A8A9A), fontSize: 9)),
      textDirection: TextDirection.ltr)..layout();
    fstp.paint(canvas, Offset(stripPadX + stripW - fstp.width, barAreaTop - 12));

    // ── Section 3: Mean ± std band (bottom ~28%) ──
    const chartTop = 228.0;
    final chartH = size.height - chartTop - 18;
    if (chartH < 30) return;
    final chartW = stripW;

    // Axes
    final axPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1;
    canvas.drawLine(Offset(stripPadX, chartTop), Offset(stripPadX, chartTop + chartH), axPaint);
    canvas.drawLine(Offset(stripPadX, chartTop + chartH),
        Offset(stripPadX + chartW, chartTop + chartH), axPaint);

    final meanScore = scores.reduce((a, b) => a + b) / k;
    final std = math.sqrt(scores.map((s) => math.pow(s - meanScore, 2)).reduce((a, b) => a + b) / k);

    // Training score (approaches 1 as k increases) & val score = mean
    final trainScores = List.generate(k, (i) => (0.92 - 0.01 * i + 0.01 * math.sin(time * 0.5 + i)).clamp(0.7, 0.99));
    final valScores = scores;

    // Variance band around val mean
    final bandPath = Path();
    final bandPathBottom = Path();
    for (int i = 0; i < k; i++) {
      final xf = stripPadX + i / (k - 1).clamp(1, 100) * chartW;
      final yTop = chartTop + chartH - (((meanScore + std) - 0.5) / 0.5 * chartH).clamp(0.0, chartH);
      final yBot = chartTop + chartH - (((meanScore - std) - 0.5) / 0.5 * chartH).clamp(0.0, chartH);
      if (i == 0) { bandPath.moveTo(xf, yTop); bandPathBottom.moveTo(xf, yBot); }
      else { bandPath.lineTo(xf, yTop); bandPathBottom.lineTo(xf, yBot); }
    }
    for (int i = k - 1; i >= 0; i--) {
      final xf = stripPadX + i / (k - 1).clamp(1, 100) * chartW;
      final yBot = chartTop + chartH - (((meanScore - std) - 0.5) / 0.5 * chartH).clamp(0.0, chartH);
      bandPath.lineTo(xf, yBot);
    }
    bandPath.close();
    canvas.drawPath(bandPath, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.1));

    // Val score curve
    _drawLineCurve(canvas, List.generate(k, (i) {
      final xf = stripPadX + i / (k - 1).clamp(1, 100) * chartW;
      final yf = chartTop + chartH - ((valScores[i] - 0.5) / 0.5 * chartH).clamp(0.0, chartH);
      return Offset(xf, yf);
    }), const Color(0xFF00D4FF), 2.0);

    // Train score curve
    _drawLineCurve(canvas, List.generate(k, (i) {
      final xf = stripPadX + i / (k - 1).clamp(1, 100) * chartW;
      final yf = chartTop + chartH - ((trainScores[i] - 0.5) / 0.5 * chartH).clamp(0.0, chartH);
      return Offset(xf, yf);
    }), const Color(0xFF64FF8C), 1.5);

    // Legend
    _drawChip(canvas, Offset(stripPadX, chartTop - 14), 'Train Acc', const Color(0xFF64FF8C));
    _drawChip(canvas, Offset(stripPadX + 72, chartTop - 14), 'Val Acc', const Color(0xFF00D4FF));

    // x-axis fold labels
    for (int i = 0; i < k; i++) {
      final xf = stripPadX + i / (k - 1).clamp(1, 100) * chartW;
      final xtp = TextPainter(
        text: TextSpan(text: '${i + 1}',
            style: const TextStyle(color: Color(0xFF3A6070), fontSize: 7.5)),
        textDirection: TextDirection.ltr)..layout();
      xtp.paint(canvas, Offset(xf - xtp.width / 2, chartTop + chartH + 3));
    }
  }

  void _drawLineCurve(Canvas canvas, List<Offset> pts, Color color, double sw) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) { path.lineTo(pts[i].dx, pts[i].dy); }
    canvas.drawPath(path, Paint()..color = color..strokeWidth = sw..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    for (final p in pts) {
      canvas.drawCircle(p, 3, Paint()..color = color.withValues(alpha: 0.9));
    }
  }

  void _drawChip(Canvas canvas, Offset pos, String label, Color color) {
    canvas.drawCircle(Offset(pos.dx + 4, pos.dy + 5), 3.5, Paint()..color = color.withValues(alpha: 0.85));
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(color: color.withValues(alpha: 0.75), fontSize: 8)),
      textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(pos.dx + 11, pos.dy));
  }

  @override
  bool shouldRepaint(covariant _CrossValidationScreenPainter oldDelegate) => true;
}
