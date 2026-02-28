import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class TentMapScreen extends StatefulWidget {
  const TentMapScreen({super.key});
  @override
  State<TentMapScreen> createState() => _TentMapScreenState();
}

class _TentMapScreenState extends State<TentMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _mu = 1.5;
  
  double _xVal = 0.4;

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
      double x = 0.4;
      for (int i = 0; i < 50; i++) {
        x = _mu * (x < 0.5 ? x : 1 - x);
      }
      _xVal = x;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _mu = 1.5;
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
          Text('카오스 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('텐트 사상', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스 시뮬레이션',
          title: '텐트 사상',
          formula: 'x_{n+1} = μ·min(x, 1-x)',
          formulaDescription: '텐트 사상의 궤도와 카오스를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _TentMapScreenPainter(
                time: _time,
                mu: _mu,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'μ (매개변수)',
                value: _mu,
                min: 0,
                max: 2,
                step: 0.01,
                defaultValue: 1.5,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _mu = v),
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
          _V('x*', _xVal.toStringAsFixed(4)),
          _V('μ', _mu.toStringAsFixed(2)),
          _V('상태', _mu > 1 ? '카오스' : '수렴'),
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

class _TentMapScreenPainter extends CustomPainter {
  final double time;
  final double mu;

  _TentMapScreenPainter({
    required this.time,
    required this.mu,
  });

  // Tent map function
  double _tent(double x) => mu * (x < 0.5 ? x : 1 - x);

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fs, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 1 || size.height < 1) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Layout: main plot (top 75%), histogram (bottom 20%), gap 5%
    final plotH = size.height * 0.72;
    final histTop = size.height * 0.78;
    final histH = size.height * 0.18;
    final pad = 28.0;
    final plotW = size.width - pad * 2;

    // Helper: map unit [0,1] to canvas coords in plot area
    Offset toCanvas(double x, double y) => Offset(
      pad + x * plotW,
      plotH - y * (plotH - pad) - pad * 0.5,
    );

    // Draw axes
    final axisPaint = Paint()..color = AppColors.simGrid..strokeWidth = 0.8;
    canvas.drawLine(Offset(pad, plotH - pad * 0.5), Offset(pad + plotW, plotH - pad * 0.5), axisPaint);
    canvas.drawLine(Offset(pad, pad * 0.5), Offset(pad, plotH - pad * 0.5), axisPaint);

    // Draw diagonal y=x (dashed, muted)
    final dashPaint = Paint()..color = AppColors.muted.withValues(alpha: 0.5)..strokeWidth = 1;
    for (int i = 0; i < 20; i++) {
      final t0 = i / 20.0;
      final t1 = (i + 0.5) / 20.0;
      canvas.drawLine(toCanvas(t0, t0), toCanvas(t1, t1), dashPaint);
    }

    // Draw tent map function (cyan)
    final mapPaint = Paint()..color = AppColors.accent..strokeWidth = 2..style = PaintingStyle.stroke;
    final mapPath = Path()..moveTo(toCanvas(0, 0).dx, toCanvas(0, 0).dy);
    mapPath.lineTo(toCanvas(0.5, mu * 0.5).dx, toCanvas(0.5, mu * 0.5).dy);
    mapPath.lineTo(toCanvas(1.0, 0).dx, toCanvas(1.0, 0).dy);
    canvas.drawPath(mapPath, mapPaint);

    // Cobweb iteration
    const int totalSteps = 60;
    final revealSteps = ((time * 8) % (totalSteps + 10)).toInt();
    double x = 0.3 + 0.1 * math.sin(time * 0.3);
    final List<Offset> cobPts = [toCanvas(x, 0)];
    for (int i = 0; i < math.min(revealSteps, totalSteps); i++) {
      final fx = _tent(x);
      cobPts.add(toCanvas(x, fx));   // vertical: x stays, y goes to f(x)
      cobPts.add(toCanvas(fx, fx));  // horizontal: go to diagonal
      x = fx;
    }

    // Draw cobweb with color gradient blue→red
    if (cobPts.length >= 2) {
      for (int i = 0; i < cobPts.length - 1; i++) {
        final t = i / cobPts.length.toDouble();
        final col = Color.lerp(AppColors.accent.withValues(alpha: 0.6),
            AppColors.accent2.withValues(alpha: 0.9), t)!;
        canvas.drawLine(cobPts[i], cobPts[i + 1],
            Paint()..color = col..strokeWidth = 1.2..style = PaintingStyle.stroke);
      }
      // Current point
      canvas.drawCircle(cobPts.last, 4,
          Paint()..color = Colors.white..style = PaintingStyle.fill);
    }

    // Axis labels
    _drawLabel(canvas, 'x', Offset(pad + plotW + 2, plotH - pad * 0.5 - 6), AppColors.muted, 10);
    _drawLabel(canvas, 'f(x)', Offset(pad + 2, pad * 0.5 - 2), AppColors.muted, 10);
    _drawLabel(canvas, 'μ=${mu.toStringAsFixed(2)}', Offset(pad + plotW * 0.35, pad * 0.5),
        mu > 1 ? AppColors.accent2 : AppColors.accent, 11);

    // Mini histogram of iterates
    const int histBins = 40;
    const int iterCount = 500;
    final bins = List<int>.filled(histBins, 0);
    double hx = 0.4;
    for (int i = 0; i < 200; i++) { hx = _tent(hx); }
    for (int i = 0; i < iterCount; i++) {
      hx = _tent(hx);
      final bin = (hx * histBins).clamp(0, histBins - 1).toInt();
      bins[bin]++;
    }
    final maxBin = bins.reduce(math.max);
    final binW = size.width / histBins;
    final histPaint = Paint()..color = AppColors.accent.withValues(alpha: 0.55);
    for (int b = 0; b < histBins; b++) {
      if (maxBin > 0) {
        final bh = histH * bins[b] / maxBin;
        canvas.drawRect(
          Rect.fromLTWH(b * binW, histTop + histH - bh, binW - 0.5, bh),
          histPaint,
        );
      }
    }
    _drawLabel(canvas, '분포', Offset(2, histTop - 2), AppColors.muted, 9);
  }

  @override
  bool shouldRepaint(covariant _TentMapScreenPainter oldDelegate) => true;
}
