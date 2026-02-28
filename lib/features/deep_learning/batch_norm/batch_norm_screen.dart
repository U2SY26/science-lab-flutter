import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BatchNormScreen extends StatefulWidget {
  const BatchNormScreen({super.key});
  @override
  State<BatchNormScreen> createState() => _BatchNormScreenState();
}

class _BatchNormScreenState extends State<BatchNormScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _batchSize = 32;
  double _epsilon = 0.00001;
  double _mean = 0, _stdDev = 1;

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
      _mean = math.sin(_time) * 0.1;
      _stdDev = 1.0 / math.sqrt(_batchSize);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _batchSize = 32.0; _epsilon = 0.00001;
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
          const Text('배치 정규화', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '배치 정규화',
          formula: 'x̂ = (x-μ)/√(σ²+ε)',
          formulaDescription: '배치 정규화가 학습 안정성에 미치는 영향을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BatchNormScreenPainter(
                time: _time,
                batchSize: _batchSize,
                epsilon: _epsilon,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '배치 크기',
                value: _batchSize,
                min: 4,
                max: 256,
                step: 4,
                defaultValue: 32,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _batchSize = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'ε',
                value: _epsilon,
                min: 0.000001,
                max: 0.01,
                step: 0.000001,
                defaultValue: 0.00001,
                formatValue: (v) => v.toStringAsFixed(6),
                onChanged: (v) => setState(() => _epsilon = v),
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
          _V('μ', _mean.toStringAsFixed(4)),
          _V('σ', _stdDev.toStringAsFixed(4)),
          _V('batch', _batchSize.toInt().toString()),
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

class _BatchNormScreenPainter extends CustomPainter {
  final double time;
  final double batchSize;
  final double epsilon;

  _BatchNormScreenPainter({
    required this.time,
    required this.batchSize,
    required this.epsilon,
  });

  static const _cyan = Color(0xFF00D4FF);
  static const _orange = Color(0xFFFF6B35);
  static const _simBg = Color(0xFF0D1A20);
  static const _ink = Color(0xFFE0F4FF);
  static const _muted = Color(0xFF5A8A9A);
  static const _grid = Color(0xFF1A3040);

  void _drawLabel(Canvas canvas, String text, Offset offset, {Color color = _ink, double fontSize = 10}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  /// Gaussian bell curve value
  double _gauss(double x, double mean, double std) {
    final exponent = -0.5 * math.pow((x - mean) / std, 2);
    return (1 / (std * math.sqrt(2 * math.pi))) * math.exp(exponent);
  }

  void _drawHistogram(Canvas canvas, Rect rect, double mean, double std,
      Color barColor, Color glowColor, String label) {
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = _grid.withValues(alpha: 0.5),
    );

    final int bins = 20;
    final double xMin = mean - 4 * std;
    final double xMax = mean + 4 * std;
    final double binWidth = (xMax - xMin) / bins;
    final double maxDensity = _gauss(mean, mean, std);
    final double barAreaH = rect.height * 0.72;
    final double barBottom = rect.bottom - 22;
    final double barW = rect.width / (bins + 2);

    // Shaded std region
    final double stdLeft = ((mean - std - xMin) / (xMax - xMin)) * rect.width + rect.left;
    final double stdRight = ((mean + std - xMin) / (xMax - xMin)) * rect.width + rect.left;
    canvas.drawRect(
      Rect.fromLTRB(stdLeft.clamp(rect.left, rect.right),
          rect.top + 8, stdRight.clamp(rect.left, rect.right), barBottom),
      Paint()..color = barColor.withValues(alpha: 0.08),
    );

    // Draw bars with glow
    for (int i = 0; i < bins; i++) {
      final double bx = xMin + (i + 0.5) * binWidth;
      final double density = _gauss(bx, mean, std);
      final double barH = (density / maxDensity) * barAreaH;
      final double left = rect.left + (i / bins) * rect.width + 1;
      final double right = left + barW - 1;
      final double top = barBottom - barH;

      // Glow effect
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, barBottom),
        Paint()..color = glowColor.withValues(alpha: 0.18),
      );
      // Bar
      final grad = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [barColor, barColor.withValues(alpha: 0.5)],
      );
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, barBottom),
        Paint()..shader = grad.createShader(Rect.fromLTRB(left, top, right, barBottom)),
      );
    }

    // Mean dashed line (orange)
    final double meanX = ((mean - xMin) / (xMax - xMin)) * rect.width + rect.left;
    final dashPaint = Paint()..color = _orange.withValues(alpha: 0.85)..strokeWidth = 1.2;
    for (double dy = rect.top + 8; dy < barBottom; dy += 5) {
      canvas.drawLine(Offset(meanX, dy), Offset(meanX, math.min(dy + 3, barBottom)), dashPaint);
    }

    // Bell curve overlay
    final curvePath = Path();
    bool first = true;
    for (int px = 0; px <= rect.width.toInt(); px++) {
      final double bx = xMin + (px / rect.width) * (xMax - xMin);
      final double density = _gauss(bx, mean, std);
      final double cy2 = barBottom - (density / maxDensity) * barAreaH;
      final double cx2 = rect.left + px;
      if (first) {
        curvePath.moveTo(cx2, cy2);
        first = false;
      } else {
        curvePath.lineTo(cx2, cy2);
      }
    }
    canvas.drawPath(curvePath, Paint()
      ..color = barColor.withValues(alpha: 0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);

    // Labels
    _drawLabel(canvas, label, Offset(rect.left + 4, rect.top + 4), color: barColor, fontSize: 9);
    _drawLabel(canvas, 'μ=${mean.toStringAsFixed(2)}',
        Offset(rect.left + 4, barBottom + 4), color: _orange, fontSize: 8);
    _drawLabel(canvas, 'σ=${std.toStringAsFixed(2)}',
        Offset(rect.left + rect.width * 0.55, barBottom + 4), color: barColor, fontSize: 8);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = _simBg);

    // Subtle grid
    final gridPaint = Paint()..color = _grid.withValues(alpha: 0.25)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double pad = 12;
    final double panelW = (size.width - pad * 3) / 2;
    final double panelH = size.height - 52;
    final double panelTop = 38.0;

    // Animated: before BN mean drifts, std spreads
    final double beforeMean = math.sin(time * 0.7) * 1.5;
    final double beforeStd = 1.5 + math.sin(time * 0.4) * 0.6 + (batchSize < 32 ? 0.8 : 0);
    // After BN: always centered, std controlled by batchSize noise
    final double afterMean = math.sin(time * 0.9) * 0.04;
    final double afterStd = 1.0 + (1.0 / math.sqrt(batchSize)) * 0.3;

    final Rect leftPanel = Rect.fromLTWH(pad, panelTop, panelW, panelH);
    final Rect rightPanel = Rect.fromLTWH(pad * 2 + panelW, panelTop, panelW, panelH);

    // Before BN — red/muted tones
    _drawHistogram(canvas, leftPanel, beforeMean, beforeStd,
        const Color(0xFFFF4560), const Color(0xFFFF8080), 'Before BN');

    // After BN — cyan tones
    _drawHistogram(canvas, rightPanel, afterMean, afterStd,
        _cyan, const Color(0xFF80EEFF), 'After BN');

    // Arrow between panels
    final double arrowY = panelTop + panelH * 0.45;
    final double arrowX1 = pad + panelW + 2;
    final double arrowX2 = pad * 2 + panelW - 2;
    final arrowPaint = Paint()..color = _muted.withValues(alpha: 0.7)..strokeWidth = 1.5;
    final double pulse = math.sin(time * 2) * 0.5 + 0.5;
    canvas.drawLine(Offset(arrowX1, arrowY), Offset(arrowX2, arrowY),
        arrowPaint..color = _cyan.withValues(alpha: 0.4 + pulse * 0.4));
    // Arrowhead
    final arrowHead = Path()
      ..moveTo(arrowX2 - 1, arrowY)
      ..lineTo(arrowX2 - 6, arrowY - 4)
      ..lineTo(arrowX2 - 6, arrowY + 4)
      ..close();
    canvas.drawPath(arrowHead, Paint()..color = _cyan.withValues(alpha: 0.6 + pulse * 0.4));

    // γ/β label on arrow
    _drawLabel(canvas, 'γ,β', Offset(arrowX1 + (arrowX2 - arrowX1) / 2 - 8, arrowY - 14),
        color: _cyan.withValues(alpha: 0.85), fontSize: 9);

    // Title
    _drawLabel(canvas, '배치 정규화 효과',
        Offset(size.width / 2 - 42, 10), color: _ink, fontSize: 12);
  }

  @override
  bool shouldRepaint(covariant _BatchNormScreenPainter oldDelegate) => true;
}
