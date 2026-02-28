import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class NeuralStyleScreen extends StatefulWidget {
  const NeuralStyleScreen({super.key});
  @override
  State<NeuralStyleScreen> createState() => _NeuralStyleScreenState();
}

class _NeuralStyleScreenState extends State<NeuralStyleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _styleWeight = 5;
  double _contentWeight = 1;
  double _totalLoss = 0;

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
      _totalLoss = _contentWeight * (5.0 / (1 + _time)) + _styleWeight * (3.0 / (1 + _time));
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _styleWeight = 5; _contentWeight = 1.0;
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
          const Text('신경 스타일 전이', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '신경 스타일 전이',
          formula: 'L = αL_content + βL_style',
          formulaDescription: 'CNN에서 콘텐츠와 스타일 분리를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _NeuralStyleScreenPainter(
                time: _time,
                styleWeight: _styleWeight,
                contentWeight: _contentWeight,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '스타일 가중치 β',
                value: _styleWeight,
                min: 0,
                max: 10,
                step: 0.5,
                defaultValue: 5,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _styleWeight = v),
              ),
              advancedControls: [
            SimSlider(
                label: '콘텐츠 가중치 α',
                value: _contentWeight,
                min: 0,
                max: 10,
                step: 0.5,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _contentWeight = v),
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
          _V('총 손실', _totalLoss.toStringAsFixed(2)),
          _V('α', _contentWeight.toStringAsFixed(1)),
          _V('β', _styleWeight.toStringAsFixed(1)),
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

class _NeuralStyleScreenPainter extends CustomPainter {
  final double time;
  final double styleWeight;
  final double contentWeight;

  _NeuralStyleScreenPainter({
    required this.time,
    required this.styleWeight,
    required this.contentWeight,
  });

  // 5 conv layers: relative widths and heights
  static const _layerScales = [1.0, 0.78, 0.56, 0.36, 0.18];
  static const _layerLabels = ['Conv1\nEdges', 'Conv2\nTexture', 'Conv3\nBlobs', 'Conv4\nAbstract', 'FC\nVector'];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Layout: top section = CNN layers, bottom strip = loss curves
    const lossH = 58.0;
    const pad = 10.0;
    final layersH = size.height - lossH - pad;

    _drawCNNLayers(canvas, size, pad, layersH);
    _drawLossCurves(canvas, size, layersH + pad, lossH);
  }

  void _drawCNNLayers(Canvas canvas, Size size, double pad, double areaH) {
    // Total width weight: sum of layerScales for spacing
    final totalW = size.width - pad * 2;
    // Each layer block gets proportional width + small gap
    const gap = 6.0;
    const n = 5;
    final blockW = (totalW - gap * (n - 1)) / n;

    // Blend ratio: style vs content driven by weights (normalized)
    final totalW2 = styleWeight + contentWeight + 0.001;
    final styleRatio = styleWeight / totalW2;

    for (int l = 0; l < n; l++) {
      final left = pad + l * (blockW + gap);
      final scale = _layerScales[l];
      final blockH = areaH * scale;
      final top = pad + (areaH - blockH) / 2; // vertically centered
      final rect = Rect.fromLTWH(left, top, blockW, blockH);

      _drawLayerBlock(canvas, rect, l, scale, styleRatio);
      _drawLayerLabel(canvas, rect, l);
    }

    // Animated blend arrows between Conv3 and Conv4 (style+content merge)
    _drawBlendArrows(canvas, pad, areaH, blockW, gap, styleRatio);
  }

  void _drawLayerBlock(Canvas canvas, Rect rect, int layerIdx, double scale, double styleRatio) {
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)));

    // Background
    canvas.drawRect(rect, Paint()..color = AppColors.simGrid.withValues(alpha: 0.55));

    switch (layerIdx) {
      case 0:
        _drawEdgePattern(canvas, rect);
        break;
      case 1:
        _drawCrossHatchPattern(canvas, rect);
        break;
      case 2:
        _drawBlobPattern(canvas, rect);
        break;
      case 3:
        _drawAbstractPattern(canvas, rect, styleRatio);
        break;
      case 4:
        _drawFeatureVector(canvas, rect, styleRatio);
        break;
    }

    // Style (orange) / Content (cyan) tint blend
    final styleTint = AppColors.accent2.withValues(alpha: styleRatio * 0.22);
    final contentTint = AppColors.accent.withValues(alpha: (1 - styleRatio) * 0.18);
    canvas.drawRect(rect, Paint()..color = styleTint);
    canvas.drawRect(rect, Paint()..color = contentTint);

    canvas.restore();

    // Border glow: more orange = more style
    final borderColor = Color.lerp(AppColors.accent, AppColors.accent2, styleRatio)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..color = borderColor.withValues(alpha: 0.35 + scale * 0.3)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
  }

  // Conv1: edge-detection sine wave grid
  void _drawEdgePattern(Canvas canvas, Rect r) {
    final p = Paint()..color = AppColors.accent.withValues(alpha: 0.55)..strokeWidth = 0.8..style = PaintingStyle.stroke;
    const lines = 6;
    for (int i = 0; i < lines; i++) {
      final y0 = r.top + (i + 0.5) * r.height / lines;
      final path = Path();
      const pts = 20;
      for (int j = 0; j <= pts; j++) {
        final t = j / pts;
        final x = r.left + t * r.width;
        final y = y0 + math.sin(t * math.pi * 2 + time * 1.2 + i * 0.5) * r.height * 0.06;
        j == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, p);
    }
  }

  // Conv2: cross-hatch texture
  void _drawCrossHatchPattern(Canvas canvas, Rect r) {
    final p = Paint()..color = AppColors.accent.withValues(alpha: 0.4)..strokeWidth = 0.6;
    final spacing = r.width / 6;
    final phase = math.sin(time * 0.8) * 3;
    for (double x = r.left; x <= r.right; x += spacing) {
      canvas.drawLine(Offset(x + phase, r.top), Offset(x - phase, r.bottom), p);
    }
    for (double y = r.top; y <= r.bottom; y += spacing) {
      canvas.drawLine(Offset(r.left, y + phase), Offset(r.right, y - phase), p);
    }
  }

  // Conv3: color blobs
  void _drawBlobPattern(Canvas canvas, Rect r) {
    const blobs = 5;
    for (int i = 0; i < blobs; i++) {
      final bx = r.left + r.width * (0.2 + i * 0.15 + math.sin(time * 0.5 + i) * 0.06);
      final by = r.top + r.height * (0.3 + math.cos(time * 0.4 + i * 1.2) * 0.25);
      final br = r.width * 0.12 + math.sin(time + i) * r.width * 0.03;
      final col = i.isEven ? AppColors.accent : AppColors.accent2;
      canvas.drawCircle(Offset(bx, by), br, Paint()..color = col.withValues(alpha: 0.3));
      canvas.drawCircle(Offset(bx, by), br * 0.5, Paint()..color = col.withValues(alpha: 0.55));
    }
  }

  // Conv4: abstract swirl of both content+style
  void _drawAbstractPattern(Canvas canvas, Rect r, double styleRatio) {
    final cx = r.left + r.width / 2, cy = r.top + r.height / 2;
    const spirals = 4;
    for (int s = 0; s < spirals; s++) {
      final path = Path();
      const pts = 24;
      for (int i = 0; i <= pts; i++) {
        final ang = i / pts * math.pi * 1.5 + s * math.pi / 2 + time * 0.6;
        final rad = i / pts * math.min(r.width, r.height) * 0.38;
        final x = cx + math.cos(ang) * rad;
        final y = cy + math.sin(ang) * rad;
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      final col = Color.lerp(AppColors.accent, AppColors.accent2, styleRatio)!;
      canvas.drawPath(path, Paint()..color = col.withValues(alpha: 0.55)..strokeWidth = 1.0..style = PaintingStyle.stroke);
    }
  }

  // FC layer: vertical feature bar chart
  void _drawFeatureVector(Canvas canvas, Rect r, double styleRatio) {
    const bars = 8;
    final barW = r.width * 0.55;
    final barLeft = r.left + (r.width - barW) / 2;
    final barSpacing = r.height / (bars + 1);

    for (int i = 0; i < bars; i++) {
      final y = r.top + barSpacing * (i + 1);
      final val = (math.sin(time * 0.9 + i * 0.8) + 1) / 2;
      final colT = (i / bars + styleRatio) % 1.0;
      final col = Color.lerp(AppColors.accent, AppColors.accent2, colT)!;
      final w = barW * val;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barLeft, y - 1.5, w, 3), const Radius.circular(2)),
        Paint()..color = col.withValues(alpha: 0.75),
      );
    }
  }

  void _drawBlendArrows(Canvas canvas, double pad, double areaH, double blockW, double gap, double styleRatio) {
    // Arrow between layer 2 and 3 showing style+content merge
    const l = 2;
    final x1 = pad + l * (blockW + gap) + blockW;
    final x2 = pad + (l + 1) * (blockW + gap);
    final midY = pad + areaH / 2;

    // Style arrow (from top, orange)
    final arrowPhase = (time * 0.7) % 1.0;
    final arrowX = x1 + arrowPhase * (x2 - x1);

    canvas.drawLine(
      Offset(x1 + 2, midY),
      Offset(x2 - 2, midY),
      Paint()
        ..color = Color.lerp(AppColors.accent, AppColors.accent2, styleRatio)!
            .withValues(alpha: 0.45)
        ..strokeWidth = 1.2,
    );

    // Moving particle
    canvas.drawCircle(
      Offset(arrowX, midY),
      3.5,
      Paint()..color = Color.lerp(AppColors.accent, AppColors.accent2, styleRatio)!.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      Offset(arrowX, midY),
      7,
      Paint()..color = Color.lerp(AppColors.accent, AppColors.accent2, styleRatio)!.withValues(alpha: 0.18),
    );
  }

  void _drawLayerLabel(Canvas canvas, Rect rect, int layerIdx) {
    final parts = _layerLabels[layerIdx].split('\n');
    _drawText(canvas, parts[0], Offset(rect.left + 2, rect.bottom + 2), 8, AppColors.muted.withValues(alpha: 0.8));
    if (parts.length > 1) {
      _drawText(canvas, parts[1], Offset(rect.left + 2, rect.bottom + 11), 7, AppColors.muted.withValues(alpha: 0.55));
    }
  }

  void _drawLossCurves(Canvas canvas, Size size, double top, double h) {
    const pad = 10.0;
    final left = pad, right = size.width - pad;
    final w = right - left;
    final graphTop = top + 14;
    final graphH = h - 20;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h - 4), const Radius.circular(5)),
      Paint()..color = AppColors.simGrid.withValues(alpha: 0.35),
    );

    // Axes
    final axisPaint = Paint()..color = AppColors.muted.withValues(alpha: 0.3)..strokeWidth = 0.5;
    canvas.drawLine(Offset(left + 14, graphTop), Offset(left + 14, graphTop + graphH), axisPaint);
    canvas.drawLine(Offset(left + 14, graphTop + graphH), Offset(right - 4, graphTop + graphH), axisPaint);

    // Content loss curve (cyan): decays with contentWeight influence
    _drawLossCurve(canvas, left + 14, graphTop, w - 18, graphH,
        AppColors.accent, contentWeight * 0.6, 0.3, 'L_content');

    // Style loss curve (orange): decays with styleWeight influence
    _drawLossCurve(canvas, left + 14, graphTop, w - 18, graphH,
        AppColors.accent2, styleWeight * 0.25, 0.5, 'L_style');

    _drawText(canvas, 'Loss Curves', Offset(left + 16, top + 2), 8, AppColors.muted.withValues(alpha: 0.7));
  }

  void _drawLossCurve(Canvas canvas, double left, double top, double w, double h,
      Color color, double decayRate, double offset, String label) {
    final curvePaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final path = Path();
    const steps = 60;
    for (int i = 0; i <= steps; i++) {
      final tNorm = i / steps;
      final tAgo = tNorm * math.min(time, 10.0);
      final loss = math.exp(-(decayRate + 0.15) * tAgo) * (0.9 + 0.08 * math.sin(tAgo * 2.5 + offset));
      final x = left + tNorm * w;
      final y = top + h * (1 - loss.clamp(0.0, 1.0));
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, curvePaint);

    // Current value dot
    final curT = math.min(time, 10.0);
    final curLoss = math.exp(-(decayRate + 0.15) * curT) * (0.9 + 0.08 * math.sin(curT * 2.5 + offset));
    final dotX = left + w;
    final dotY = top + h * (1 - curLoss.clamp(0.0, 1.0));
    canvas.drawCircle(Offset(dotX, dotY), 2.8, Paint()..color = color);
    canvas.drawCircle(Offset(dotX, dotY), 5.5, Paint()..color = color.withValues(alpha: 0.22));

    _drawText(canvas, label, Offset(left + 2, top + h * (1 - math.exp(0.0)) - 10), 7, color.withValues(alpha: 0.7));
  }

  void _drawText(Canvas canvas, String text, Offset pos, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _NeuralStyleScreenPainter oldDelegate) => true;
}
