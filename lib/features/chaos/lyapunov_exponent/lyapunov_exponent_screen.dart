import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class LyapunovExponentScreen extends StatefulWidget {
  const LyapunovExponentScreen({super.key});
  @override
  State<LyapunovExponentScreen> createState() => _LyapunovExponentScreenState();
}

class _LyapunovExponentScreenState extends State<LyapunovExponentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _rParam = 3.7;
  
  double _lyapunov = 0; bool _chaotic = true;

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
      double x = 0.5;
      double sum = 0;
      for (int i = 0; i < 200; i++) {
        x = _rParam * x * (1 - x);
        final deriv = (_rParam * (1 - 2 * x)).abs();
        if (deriv > 0) sum += math.log(deriv);
      }
      _lyapunov = sum / 200;
      _chaotic = _lyapunov > 0;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _rParam = 3.7;
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
          const Text('리아푸노프 지수', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스 시뮬레이션',
          title: '리아푸노프 지수',
          formula: "λ = lim (1/n)Σ ln|f\'(x_i)|",
          formulaDescription: '리아푸노프 지수로 카오스 정도를 측정합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _LyapunovExponentScreenPainter(
                time: _time,
                rParam: _rParam,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'r (매개변수)',
                value: _rParam,
                min: 2.5,
                max: 4,
                step: 0.01,
                defaultValue: 3.7,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _rParam = v),
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
          _V('λ', _lyapunov.toStringAsFixed(4)),
          _V('상태', _chaotic ? '카오스' : '주기적'),
          _V('r', _rParam.toStringAsFixed(2)),
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

class _LyapunovExponentScreenPainter extends CustomPainter {
  final double time;
  final double rParam;

  _LyapunovExponentScreenPainter({
    required this.time,
    required this.rParam,
  });

  // Compute Lyapunov exponent for logistic map at parameter r
  double _lyapunovAt(double r) {
    double x = 0.5;
    double sum = 0;
    const warmup = 100;
    const iters = 200;
    for (int i = 0; i < warmup; i++) x = r * x * (1 - x);
    for (int i = 0; i < iters; i++) {
      x = r * x * (1 - x);
      final d = (r * (1 - 2 * x)).abs();
      if (d > 1e-10) sum += math.log(d);
    }
    return sum / iters;
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 1 || size.height < 1) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    const double rMin = 2.5, rMax = 4.0;
    const int cols = 200;
    const double mapAreaTop = 20.0;
    const double mapAreaBottom = 0.85; // fraction of height for color map
    const double lambdaRange = 2.0; // from -2 to +1

    final mapH = size.height * mapAreaBottom - mapAreaTop;
    final colW = size.width / cols;

    // Compute columns up to animated column
    final revealCols = ((time * 25) % (cols + 1)).toInt();

    for (int c = 0; c < math.min(revealCols, cols); c++) {
      final r = rMin + (rMax - rMin) * c / cols;
      final lam = _lyapunovAt(r);
      // Map lambda: -2..0 = stable (cyan), 0..1 = chaotic (orange/red)
      Color col;
      if (lam <= 0) {
        final t = ((lam + lambdaRange) / lambdaRange).clamp(0.0, 1.0);
        col = Color.lerp(const Color(0xFF001A20), AppColors.accent, t)!;
      } else {
        final t = (lam / 1.5).clamp(0.0, 1.0);
        col = Color.lerp(AppColors.accent2, const Color(0xFFFF2222), t)!;
      }
      final rect = Rect.fromLTWH(c * colW, mapAreaTop, colW + 0.5, mapH);
      canvas.drawRect(rect, Paint()..color = col);
    }

    // Current rParam vertical line
    final curX = (rParam - rMin) / (rMax - rMin) * size.width;
    canvas.drawLine(
      Offset(curX, mapAreaTop),
      Offset(curX, mapAreaTop + mapH),
      Paint()..color = Colors.white.withValues(alpha: 0.85)..strokeWidth = 1.5,
    );

    // Zero lambda horizontal dashed line
    final zeroY = mapAreaTop + mapH * (lambdaRange / (lambdaRange + 1));
    final dashPaint = Paint()..color = AppColors.muted.withValues(alpha: 0.7)..strokeWidth = 1;
    for (double dx = 0; dx < size.width; dx += 8) {
      if (dx + 4 < size.width) {
        canvas.drawLine(Offset(dx, zeroY), Offset(dx + 4, zeroY), dashPaint);
      }
    }

    // Labels
    _drawLabel(canvas, '안정 영역', Offset(8, zeroY + 4), AppColors.accent, 10);
    _drawLabel(canvas, '카오스 영역', Offset(8, mapAreaTop + 4), AppColors.accent2, 10);

    // X axis labels
    _drawLabel(canvas, 'r=2.5', const Offset(2, 0), AppColors.muted, 9);
    _drawLabel(canvas, 'r=4.0', Offset(size.width - 30, 0), AppColors.muted, 9);

    // Current lambda value
    final lam = _lyapunovAt(rParam);
    _drawLabel(canvas, 'λ=${lam.toStringAsFixed(3)}', Offset(curX + 3, zeroY - 14),
        lam > 0 ? AppColors.accent2 : AppColors.accent, 10);

    // Bottom: bifurcation dots (faint overlay)
    final dotPaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.12)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.fill;
    final rng = math.Random(42);
    for (int c = 0; c < cols; c += 2) {
      final r = rMin + (rMax - rMin) * c / cols;
      double x = 0.5 + rng.nextDouble() * 0.01;
      for (int i = 0; i < 300; i++) x = r * x * (1 - x);
      for (int i = 0; i < 40; i++) {
        x = r * x * (1 - x);
        final px = c * colW;
        final py = mapAreaTop + mapH * (1 - x);
        canvas.drawCircle(Offset(px, py.clamp(mapAreaTop, mapAreaTop + mapH)), 0.7, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LyapunovExponentScreenPainter oldDelegate) => true;
}
