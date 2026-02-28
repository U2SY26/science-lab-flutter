import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ConfusionMatrixScreen extends StatefulWidget {
  const ConfusionMatrixScreen({super.key});
  @override
  State<ConfusionMatrixScreen> createState() => _ConfusionMatrixScreenState();
}

class _ConfusionMatrixScreenState extends State<ConfusionMatrixScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _threshold = 0.5;
  
  double _accuracy = 0.85, _precision = 0.8, _recall = 0.9;

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
      _accuracy = 0.5 + 0.4 * math.sin(_threshold * math.pi);
      _precision = 0.3 + 0.6 * _threshold;
      _recall = 0.95 - 0.5 * _threshold;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _threshold = 0.5;
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
          const Text('혼동 행렬과 ROC', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '혼동 행렬과 ROC',
          formula: 'Accuracy = (TP+TN)/(TP+TN+FP+FN)',
          formulaDescription: '분류 모델의 성능 지표를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ConfusionMatrixScreenPainter(
                time: _time,
                threshold: _threshold,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '임계값',
                value: _threshold,
                min: 0,
                max: 1,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _threshold = v),
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
          _V('정확도', (_accuracy * 100).toStringAsFixed(1) + '%'),
          _V('정밀도', (_precision * 100).toStringAsFixed(1) + '%'),
          _V('재현율', (_recall * 100).toStringAsFixed(1) + '%'),
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

class _ConfusionMatrixScreenPainter extends CustomPainter {
  final double time;
  final double threshold;

  _ConfusionMatrixScreenPainter({
    required this.time,
    required this.threshold,
  });

  static const _labels = ['Cat', 'Dog', 'Bird', 'Fish'];
  static const int _n = 4;

  // Generate animated confusion matrix values driven by time + threshold
  List<List<double>> _buildMatrix() {
    final rng = math.Random(42);
    // Base correct rates (diagonal) scale with threshold 0→1
    final correct = [0.55 + threshold * 0.35, 0.50 + threshold * 0.38,
                     0.48 + threshold * 0.40, 0.52 + threshold * 0.36];
    final matrix = List.generate(_n, (r) => List<double>.filled(_n, 0));
    for (int r = 0; r < _n; r++) {
      double diag = correct[r] + 0.04 * math.sin(time * 0.8 + r);
      diag = diag.clamp(0.1, 0.95);
      matrix[r][r] = diag;
      double remaining = 1.0 - diag;
      for (int c = 0; c < _n; c++) {
        if (c == r) continue;
        final raw = rng.nextDouble();
        matrix[r][c] = raw;
      }
      // Normalize off-diagonal to sum to remaining
      double offSum = 0;
      for (int c = 0; c < _n; c++) { if (c != r) offSum += matrix[r][c]; }
      for (int c = 0; c < _n; c++) {
        if (c != r) matrix[r][c] = matrix[r][c] / offSum * remaining;
      }
    }
    return matrix;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final matrix = _buildMatrix();

    // Layout: matrix in upper ~65%, metric bars below
    const labelW = 32.0;
    const topPad = 22.0;
    const matPad = 8.0;
    final matSize = math.min(size.width - labelW * 2 - matPad * 2,
                              size.height * 0.60 - labelW - topPad);
    final cellSize = matSize / _n;
    final matLeft = (size.width - matSize - labelW) / 2 + labelW;
    final matTop = topPad + labelW;

    // Column labels (predicted)
    final predLabelTp = TextPainter(
      text: const TextSpan(text: 'Predicted →',
          style: TextStyle(color: Color(0xFF5A8A9A), fontSize: 8.5)),
      textDirection: TextDirection.ltr)..layout();
    predLabelTp.paint(canvas, Offset(matLeft, topPad - 14));

    for (int c = 0; c < _n; c++) {
      final tp = TextPainter(
        text: TextSpan(text: _labels[c],
            style: const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8)),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(matLeft + c * cellSize + (cellSize - tp.width) / 2, topPad));
    }

    // Row labels (actual)
    for (int r = 0; r < _n; r++) {
      final tp = TextPainter(
        text: TextSpan(text: _labels[r],
            style: const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8)),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(matLeft - tp.width - 4,
          matTop + r * cellSize + (cellSize - tp.height) / 2));
    }

    // Draw cells
    for (int r = 0; r < _n; r++) {
      for (int c = 0; c < _n; c++) {
        final val = matrix[r][c];
        final rect = Rect.fromLTWH(
            matLeft + c * cellSize, matTop + r * cellSize, cellSize - 2, cellSize - 2);

        Color cellColor;
        if (r == c) {
          // Diagonal: dark blue → bright cyan
          final t = val.clamp(0.0, 1.0);
          cellColor = Color.lerp(const Color(0xFF0A2030), const Color(0xFF00D4FF), t)!;
        } else {
          // Off-diagonal: near-black → orange/red heat
          final t = (val * 3.5).clamp(0.0, 1.0);
          cellColor = Color.lerp(const Color(0xFF0D1A20), const Color(0xFFFF6B35), t)!;
        }
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)),
            Paint()..color = cellColor);

        // Diagonal glow
        if (r == c && val > 0.5) {
          final glowAlpha = ((val - 0.5) * 0.4).clamp(0.0, 0.35);
          canvas.drawRRect(
              RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(4)),
              Paint()
                ..color = const Color(0xFF00D4FF).withValues(alpha: glowAlpha)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        }

        // Value text
        final pct = (val * 100).round();
        final textColor = r == c
            ? (val > 0.4 ? const Color(0xFF001822) : const Color(0xFF00D4FF))
            : (val > 0.15 ? const Color(0xFF001822) : const Color(0xFF5A8A9A));
        final vtp = TextPainter(
          text: TextSpan(text: '$pct%',
              style: TextStyle(color: textColor, fontSize: 8.5, fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr)..layout();
        vtp.paint(canvas, Offset(rect.left + (rect.width - vtp.width) / 2,
            rect.top + (rect.height - vtp.height) / 2));
      }
    }

    // Metric bars: Precision, Recall, F1
    final barTop = matTop + matSize + 18.0;
    final barAreaH = size.height - barTop - 12;
    if (barAreaH < 20) return;

    // Compute metrics from matrix (macro average)
    double precSum = 0, recSum = 0, f1Sum = 0;
    for (int c = 0; c < _n; c++) {
      double colSum = 0, rowSum = 0;
      for (int r = 0; r < _n; r++) { colSum += matrix[r][c]; rowSum += matrix[c][r]; }
      final prec = colSum > 0 ? matrix[c][c] / colSum : 0.0;
      final rec  = rowSum > 0 ? matrix[c][c] / rowSum : 0.0;
      final f1   = (prec + rec) > 0 ? 2 * prec * rec / (prec + rec) : 0.0;
      precSum += prec; recSum += rec; f1Sum += f1;
    }
    final metrics = [
      ('Precision', precSum / _n, const Color(0xFF00D4FF)),
      ('Recall',    recSum / _n,  const Color(0xFF64FF8C)),
      ('F1-Score',  f1Sum / _n,   const Color(0xFFFF6B35)),
    ];

    final barW = (size.width - 32) / metrics.length - 8;
    for (int i = 0; i < metrics.length; i++) {
      final (label, val, color) = metrics[i];
      final bx = 16 + i * (barW + 8);
      final maxBarH = barAreaH - 16;
      final filledH = (val.clamp(0.0, 1.0) * maxBarH);

      // Track background
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx, barTop, barW, maxBarH), const Radius.circular(3)),
          Paint()..color = const Color(0xFF1A3040));

      // Filled bar with gradient
      if (filledH > 0) {
        final barRect = Rect.fromLTWH(bx, barTop + maxBarH - filledH, barW, filledH);
        canvas.drawRRect(
            RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
            Paint()..shader = LinearGradient(
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [color.withValues(alpha: 0.4), color],
            ).createShader(barRect));
      }

      // Label
      final ltp = TextPainter(
        text: TextSpan(text: label,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 8)),
        textDirection: TextDirection.ltr)..layout();
      ltp.paint(canvas, Offset(bx + (barW - ltp.width) / 2, barTop + maxBarH + 2));

      // Value
      final vtp = TextPainter(
        text: TextSpan(text: '${(val * 100).toStringAsFixed(0)}%',
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)..layout();
      vtp.paint(canvas, Offset(bx + (barW - vtp.width) / 2,
          barTop + maxBarH - filledH - 12));
    }
  }

  @override
  bool shouldRepaint(covariant _ConfusionMatrixScreenPainter oldDelegate) => true;
}
