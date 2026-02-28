import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class LearningRateScreen extends StatefulWidget {
  const LearningRateScreen({super.key});
  @override
  State<LearningRateScreen> createState() => _LearningRateScreenState();
}

class _LearningRateScreenState extends State<LearningRateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _lr0 = 0.01;
  double _decayRate = 0.95;
  double _currentLr = 0.01, _loss = 1.0;

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
      final epoch = (_time * 10).toInt();
      _currentLr = _lr0 * math.pow(_decayRate, epoch.toDouble()).toDouble();
      _loss = math.exp(-_time * _lr0 * 100) + 0.01;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _lr0 = 0.01; _decayRate = 0.95;
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
          const Text('학습률 스케줄링', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '학습률 스케줄링',
          formula: 'η(t) = η₀ · decay(t)',
          formulaDescription: '다양한 학습률 스케줄링 전략을 비교합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _LearningRateScreenPainter(
                time: _time,
                lr0: _lr0,
                decayRate: _decayRate,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '초기 학습률',
                value: _lr0,
                min: 0.0001,
                max: 0.1,
                step: 0.0001,
                defaultValue: 0.01,
                formatValue: (v) => v.toStringAsFixed(4),
                onChanged: (v) => setState(() => _lr0 = v),
              ),
              advancedControls: [
            SimSlider(
                label: '감쇠율',
                value: _decayRate,
                min: 0.5,
                max: 0.999,
                step: 0.001,
                defaultValue: 0.95,
                formatValue: (v) => v.toStringAsFixed(3),
                onChanged: (v) => setState(() => _decayRate = v),
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
          _V('현재 LR', _currentLr.toStringAsFixed(6)),
          _V('Loss', _loss.toStringAsFixed(4)),
          _V('Epoch', (_time * 10).toInt().toString()),
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

class _LearningRateScreenPainter extends CustomPainter {
  final double time;
  final double lr0;
  final double decayRate;

  _LearningRateScreenPainter({
    required this.time,
    required this.lr0,
    required this.decayRate,
  });

  static const _cyan = Color(0xFF00D4FF);
  static const _yellow = Color(0xFFFFD700);
  static const _red = Color(0xFFFF4560);
  static const _simBg = Color(0xFF0D1A20);
  static const _ink = Color(0xFFE0F4FF);
  static const _muted = Color(0xFF5A8A9A);
  static const _grid = Color(0xFF1A3040);

  // Loss landscape: bowl-shaped with ridges
  double _loss(double x, double y) {
    return 0.4 * (x * x + 1.5 * y * y) +
        0.15 * math.sin(x * 3) * math.cos(y * 2) +
        0.08 * math.cos(x * 5 + 1) +
        0.05 * math.sin(y * 4 - 0.5);
  }

  // Gradient descent step
  Offset _gradStep(Offset pos, double lr) {
    const h = 0.001;
    final gx = (_loss(pos.dx + h, pos.dy) - _loss(pos.dx - h, pos.dy)) / (2 * h);
    final gy = (_loss(pos.dx, pos.dy + h) - _loss(pos.dx, pos.dy - h)) / (2 * h);
    return Offset(pos.dx - lr * gx, pos.dy - lr * gy);
  }

  void _drawLabel(Canvas canvas, String text, Offset offset,
      {Color color = _ink, double fontSize = 10}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = _simBg);

    // Layout: landscape on top 60%, loss curves on bottom 38%
    final double landscapeH = size.height * 0.58;
    final double curveH = size.height * 0.34;
    final double curveTop = landscapeH + size.height * 0.04;
    final double pad = 10.0;

    // --- HEATMAP landscape ---
    final int gridN = 40;
    final double cellW = size.width / gridN;
    final double cellH = landscapeH / gridN;
    final double domainMin = -2.0, domainMax = 2.0;

    // Precompute min/max loss for normalization
    double minL = double.infinity, maxL = double.negativeInfinity;
    for (int gy = 0; gy <= gridN; gy++) {
      for (int gx = 0; gx <= gridN; gx++) {
        final double wx = domainMin + (gx / gridN) * (domainMax - domainMin);
        final double wy = domainMin + (gy / gridN) * (domainMax - domainMin);
        final double l = _loss(wx, wy);
        if (l < minL) { minL = l; }
        if (l > maxL) { maxL = l; }
      }
    }

    for (int gy = 0; gy < gridN; gy++) {
      for (int gx = 0; gx < gridN; gx++) {
        final double wx = domainMin + ((gx + 0.5) / gridN) * (domainMax - domainMin);
        final double wy = domainMin + ((gy + 0.5) / gridN) * (domainMax - domainMin);
        final double l = (_loss(wx, wy) - minL) / (maxL - minL);
        // Blue (low) -> green -> red (high)
        final Color c = l < 0.5
            ? Color.lerp(const Color(0xFF0A2A4A), const Color(0xFF00C853), l * 2)!
            : Color.lerp(const Color(0xFF00C853), const Color(0xFFFF1744), (l - 0.5) * 2)!;
        canvas.drawRect(
          Rect.fromLTWH(gx * cellW, gy * cellH, cellW + 0.5, cellH + 0.5),
          Paint()..color = c,
        );
      }
    }

    // Helper: world -> canvas coords
    Offset worldToCanvas(double wx, double wy) {
      final double cx = ((wx - domainMin) / (domainMax - domainMin)) * size.width;
      final double cy = ((wy - domainMin) / (domainMax - domainMin)) * landscapeH;
      return Offset(cx, cy);
    }

    // Global minimum glow (near 0,0)
    final Offset minPos = worldToCanvas(0, 0);
    final double glowPulse = 0.6 + 0.4 * math.sin(time * 3);
    for (int g = 3; g >= 0; g--) {
      canvas.drawCircle(
        minPos,
        6.0 + g * 4.0,
        Paint()
          ..color = _cyan.withValues(alpha: 0.06 * glowPulse * (4 - g))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawCircle(minPos, 5, Paint()..color = _cyan.withValues(alpha: 0.9));
    // Star points
    for (int i = 0; i < 4; i++) {
      final double a = i * math.pi / 2;
      canvas.drawLine(
        Offset(minPos.dx + math.cos(a) * 3, minPos.dy + math.sin(a) * 3),
        Offset(minPos.dx + math.cos(a) * 8, minPos.dy + math.sin(a) * 8),
        Paint()..color = _cyan..strokeWidth = 1.2,
      );
    }

    // Gradient descent paths: 3 different LRs
    // Small LR
    final double lrSmall = lr0 * 0.05;
    // Just right LR
    final double lrRight = lr0;
    // Too large LR
    final double lrLarge = lr0 * 8.0;

    final configs = [
      (lrSmall, _yellow, '작은 LR'),
      (lrRight, _cyan, '적절한 LR'),
      (lrLarge, _red, '큰 LR'),
    ];

    // Simulate trajectories
    final int maxSteps = 60;
    final double animPhase = (time * 0.4) % 1.0;
    final int visibleSteps = (animPhase * maxSteps).toInt().clamp(1, maxSteps);

    for (final (lr, color, _) in configs) {
      Offset pos = const Offset(1.6, 1.4); // start top-right
      final path = Path();
      bool pathStarted = false;
      for (int step = 0; step < visibleSteps; step++) {
        pos = _gradStep(pos, lr);
        pos = Offset(pos.dx.clamp(domainMin, domainMax), pos.dy.clamp(domainMin, domainMax));
        final Offset cp = worldToCanvas(pos.dx, pos.dy);
        if (!pathStarted) {
          path.moveTo(cp.dx, cp.dy);
          pathStarted = true;
        } else {
          path.lineTo(cp.dx, cp.dy);
        }
      }
      // Trail glow
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.85)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      // Current dot
      if (pathStarted) {
        canvas.drawCircle(
          worldToCanvas(pos.dx, pos.dy),
          4.5,
          Paint()..color = color,
        );
        canvas.drawCircle(
          worldToCanvas(pos.dx, pos.dy),
          4.5,
          Paint()
            ..color = color.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }

    // Landscape border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, landscapeH),
      Paint()
        ..color = _muted.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // --- LOSS CURVES panel ---
    final Rect curveRect = Rect.fromLTWH(pad, curveTop, size.width - pad * 2, curveH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(curveRect, const Radius.circular(6)),
      Paint()..color = _grid.withValues(alpha: 0.55),
    );

    // Axis
    final axisPaint = Paint()..color = _muted.withValues(alpha: 0.4)..strokeWidth = 0.8;
    final double axisLeft = curveRect.left + 28;
    final double axisRight = curveRect.right - 8;
    final double axisBottom = curveRect.bottom - 14;
    final double axisTop = curveRect.top + 8;
    canvas.drawLine(Offset(axisLeft, axisTop), Offset(axisLeft, axisBottom), axisPaint);
    canvas.drawLine(Offset(axisLeft, axisBottom), Offset(axisRight, axisBottom), axisPaint);

    _drawLabel(canvas, 'Loss', Offset(curveRect.left + 2, axisTop - 2), color: _muted, fontSize: 8);
    _drawLabel(canvas, 'Step', Offset(axisRight - 18, axisBottom + 2), color: _muted, fontSize: 8);

    // Draw loss curves for each LR
    final curveDefs = [
      (lr0 * 0.05, _yellow),
      (lr0, _cyan),
      (lr0 * 8.0, _red),
    ];
    final double plotW = axisRight - axisLeft;
    final double plotH = axisBottom - axisTop;

    for (final (lr, color) in curveDefs) {
      final curvePath2 = Path();
      bool first = true;
      for (int step = 0; step <= 80; step++) {
        // Simulated loss decay
        final double t = step / 80.0;
        double lossVal;
        if (lr > lr0 * 4) {
          // Diverging oscillation
          lossVal = 0.1 + 0.8 * math.exp(-t * lr * 5) * (1 + 0.6 * math.sin(t * 20 * lr));
          lossVal = lossVal.clamp(0.0, 1.5);
        } else {
          lossVal = 0.02 + 0.9 * math.exp(-t * lr * 80);
        }
        final double px = axisLeft + t * plotW;
        final double py = axisBottom - (lossVal.clamp(0.0, 1.0)) * plotH;
        if (first) {
          curvePath2.moveTo(px, py);
          first = false;
        } else {
          curvePath2.lineTo(px, py);
        }
      }
      canvas.drawPath(curvePath2,
          Paint()..color = color.withValues(alpha: 0.85)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    }

    // Legend
    final legendItems = [(_yellow, '작은 LR'), (_cyan, '적절'), (_red, '큰 LR')];
    double legendX = axisLeft + 4;
    for (final (color, label) in legendItems) {
      canvas.drawRect(Rect.fromLTWH(legendX, axisTop + 2, 10, 5), Paint()..color = color);
      _drawLabel(canvas, label, Offset(legendX + 13, axisTop - 1), color: color, fontSize: 7.5);
      legendX += 52;
    }

    // Title
    _drawLabel(canvas, '손실 지형 & 학습 경로',
        Offset(size.width / 2 - 56, 4), color: _ink.withValues(alpha: 0.9), fontSize: 11);
  }

  @override
  bool shouldRepaint(covariant _LearningRateScreenPainter oldDelegate) => true;
}
