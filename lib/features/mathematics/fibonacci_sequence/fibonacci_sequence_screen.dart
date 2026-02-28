import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class FibonacciSequenceScreen extends StatefulWidget {
  const FibonacciSequenceScreen({super.key});
  @override
  State<FibonacciSequenceScreen> createState() => _FibonacciSequenceScreenState();
}

class _FibonacciSequenceScreenState extends State<FibonacciSequenceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _nTerms = 10;
  
  double _ratio = 1.618, _fibN = 55;

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
      double a = 0, b = 1;
      for (int i = 2; i <= _nTerms.toInt(); i++) { final c = a + b; a = b; b = c; }
      _fibN = b;
      _ratio = b / (a > 0 ? a : 1);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _nTerms = 10.0;
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
          const Text('피보나치 수열', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '피보나치 수열',
          formula: 'F(n) = F(n-1) + F(n-2)',
          formulaDescription: '피보나치 수열과 황금 나선을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _FibonacciSequenceScreenPainter(
                time: _time,
                nTerms: _nTerms,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '항 수 (n)',
                value: _nTerms,
                min: 2,
                max: 30,
                step: 1,
                defaultValue: 10,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _nTerms = v),
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
          _V('F(n)', _fibN.toStringAsFixed(0)),
          _V('비율', _ratio.toStringAsFixed(6)),
          _V('φ', '1.618034'),
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

class _FibonacciSequenceScreenPainter extends CustomPainter {
  final double time;
  final double nTerms;

  _FibonacciSequenceScreenPainter({
    required this.time,
    required this.nTerms,
  });

  // Build Fibonacci list up to n terms
  List<int> _fibs(int n) {
    final list = <int>[1, 1];
    for (int i = 2; i < n; i++) { list.add(list[i - 1] + list[i - 2]); }
    return list.take(n).toList();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final n = nTerms.toInt().clamp(2, 10);

    // Split canvas: top 60% spiral, bottom 40% phyllotaxis
    final spiralH = size.height * 0.60;
    final phylloH = size.height * 0.38;
    final phylloTop = spiralH + size.height * 0.02;

    // ---- FIBONACCI SPIRAL (tiled rectangles) ----
    // Lay out squares from the center outward
    // Use the first 7 fibs to keep squares visible
    const maxSquares = 7;
    final dispN = n.clamp(2, maxSquares);
    final dispFibs = _fibs(dispN);
    final maxFib = dispFibs.last.toDouble();
    final scale = math.min(size.width, spiralH) / (maxFib * 2.2);

    final colors = [AppColors.accent, AppColors.accent2, AppColors.muted,
                    AppColors.accent, AppColors.accent2, AppColors.muted, AppColors.accent];

    // Build rects by tiling: start at center
    double ox = size.width / 2 - scale * dispFibs.last / 2;
    double oy = spiralH / 2 - scale * dispFibs.last / 3;
    // direction: right, up, left, down
    final dirs = [[1,0],[0,-1],[-1,0],[0,1]];
    double curX = ox, curY = oy;
    final rects = <Rect>[];

    for (int i = 0; i < dispFibs.length; i++) {
      final s = dispFibs[i] * scale;
      final dir = dirs[i % 4];
      // Place square
      double rx = curX, ry = curY;
      if (dir[0] == 1)  { rx = curX; ry = curY - s; }
      if (dir[0] == -1) { rx = curX - s; ry = curY; }
      if (dir[1] == -1) { rx = curX; ry = curY - s; }
      if (dir[1] == 1)  { rx = curX - s; ry = curY; }
      rx = curX; ry = curY;
      rects.add(Rect.fromLTWH(rx, ry, s, s));
      curX += dir[0] * s;
      curY += dir[1] * s;
    }

    for (int i = 0; i < rects.length; i++) {
      final r = rects[i];
      final c = colors[i % colors.length];
      canvas.drawRect(r, Paint()..color = c.withValues(alpha: 0.10));
      canvas.drawRect(r, Paint()..color = c.withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      // Number label
      final label = TextPainter(
        text: TextSpan(text: '${dispFibs[i]}',
          style: TextStyle(color: c.withValues(alpha: 0.8), fontSize: (r.width * 0.28).clamp(7.0, 14.0))),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(r.center.dx - label.width / 2, r.center.dy - label.height / 2));
    }

    // Animate golden spiral arc drawing progressively
    final spiralProgress = (time * 0.3) % 1.0;
    final totalArcSteps = dispFibs.length;
    final stepsToShow = (spiralProgress * totalArcSteps).floor() + 1;
    final spiralPath = Path();
    bool spiralFirst = true;

    for (int i = 0; i < stepsToShow.clamp(0, rects.length); i++) {
      final r = rects[i];
      // Quarter arc from one corner to another
      final startAngle = (i % 4) * math.pi / 2;
      final sweepAngle = math.pi / 2;
      final center = Offset(
        i % 4 == 0 ? r.left : (i % 4 == 1 ? r.right : (i % 4 == 2 ? r.right : r.left)),
        i % 4 == 0 ? r.bottom : (i % 4 == 1 ? r.bottom : (i % 4 == 2 ? r.top : r.top)),
      );
      final arcR = rects[i].width;
      if (spiralFirst) {
        spiralPath.addArc(Rect.fromCircle(center: center, radius: arcR), startAngle, sweepAngle);
        spiralFirst = false;
      } else {
        spiralPath.addArc(Rect.fromCircle(center: center, radius: arcR), startAngle, sweepAngle);
      }
    }
    canvas.drawPath(spiralPath,
      Paint()..color = AppColors.accent.withValues(alpha: 0.9)..strokeWidth = 2.2..style = PaintingStyle.stroke);

    // ---- PHYLLOTAXIS (sunflower seeds) ----
    final phyCx = size.width / 2;
    final phyCy = phylloTop + phylloH / 2;
    final phyR  = math.min(size.width, phylloH) * 0.43;
    const goldenAngle = 2.39996; // radians
    const seedCount = 89;
    final seedProgress = ((time * 0.4) % 1.0);
    final seedsToShow = (seedProgress * seedCount).floor() + 1;

    for (int k = 0; k < seedsToShow; k++) {
      final r = phyR * math.sqrt(k / seedCount.toDouble());
      final theta = k * goldenAngle;
      final sx = phyCx + r * math.cos(theta);
      final sy = phyCy + r * math.sin(theta);
      final frac = k / seedCount.toDouble();
      final c = Color.lerp(AppColors.accent, AppColors.accent2, frac)!;
      canvas.drawCircle(Offset(sx, sy), 2.2, Paint()..color = c.withValues(alpha: 0.85));
    }

    final phylloLabel = TextPainter(
      text: const TextSpan(text: '황금각 φ 엽서배열',
        style: TextStyle(color: AppColors.muted, fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    phylloLabel.paint(canvas, Offset(phyCx - phylloLabel.width / 2, phylloTop + 2));
  }

  @override
  bool shouldRepaint(covariant _FibonacciSequenceScreenPainter oldDelegate) => true;
}
