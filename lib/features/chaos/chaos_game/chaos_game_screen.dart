import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ChaosGameScreen extends StatefulWidget {
  const ChaosGameScreen({super.key});
  @override
  State<ChaosGameScreen> createState() => _ChaosGameScreenState();
}

class _ChaosGameScreenState extends State<ChaosGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _vertices = 3;
  double _ratio = 0.5;
  int _points = 0;

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
      _points = (_time * 100).toInt();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _vertices = 3.0; _ratio = 0.5;
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
          const Text('카오스 게임', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스 시뮬레이션',
          title: '카오스 게임',
          formula: 'Jump ratio = 1/2',
          formulaDescription: '카오스 게임으로 프랙탈을 생성합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ChaosGameScreenPainter(
                time: _time,
                vertices: _vertices,
                ratio: _ratio,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '꼭짓점 수',
                value: _vertices,
                min: 3,
                max: 8,
                step: 1,
                defaultValue: 3,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _vertices = v),
              ),
              advancedControls: [
            SimSlider(
                label: '점프 비율',
                value: _ratio,
                min: 0.1,
                max: 0.9,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _ratio = v),
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
          _V('점', '$_points'),
          _V('비율', _ratio.toStringAsFixed(2)),
          _V('꼭짓점', _vertices.toInt().toString()),
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

class _ChaosGameScreenPainter extends CustomPainter {
  final double time;
  final double vertices;
  final double ratio;

  _ChaosGameScreenPainter({
    required this.time,
    required this.vertices,
    required this.ratio,
  });

  // Color per transform index
  Color _transformColor(int idx, int total) {
    const colors = [AppColors.accent, AppColors.accent2, Color(0xFF64FF8C),
      Color(0xFFFFD700), Color(0xFFFF69B4), Color(0xFF9B59B6), Color(0xFF00BFFF), Color(0xFFFF4500)];
    return colors[idx % colors.length];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 1 || size.height < 1) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final n = vertices.toInt().clamp(3, 8);
    final cx = size.width / 2;
    const topPad = 18.0;
    final radius = (math.min(size.width, size.height) - topPad * 2) * 0.44;
    final cy = topPad + radius + 4;

    // Compute polygon vertices
    final verts = List.generate(n, (i) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      return Offset(cx + radius * math.cos(angle), cy + radius * math.sin(angle));
    });

    // Draw polygon outline (muted)
    final polyPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final polyPath = Path()..moveTo(verts[0].dx, verts[0].dy);
    for (int i = 1; i < n; i++) { polyPath.lineTo(verts[i].dx, verts[i].dy); }
    polyPath.close();
    canvas.drawPath(polyPath, polyPaint);

    // Run chaos game: accumulate points per frame in deterministic seed
    final totalPts = ((time * 120) % 50000).toInt() + 200;
    final rng = math.Random(7);
    double px = cx, py = cy;
    // Warm up
    for (int i = 0; i < 20; i++) {
      final idx = rng.nextInt(n);
      px = px + ratio * (verts[idx].dx - px);
      py = py + ratio * (verts[idx].dy - py);
    }
    // Draw points in batches, coloring by last chosen vertex
    const int batchSize = 600;
    final rng2 = math.Random(13 + (time * 5).toInt());
    double qx = cx + rng2.nextDouble() * 10 - 5;
    double qy = cy + rng2.nextDouble() * 10 - 5;
    final List<List<Offset>> buckets = List.generate(n, (_) => []);
    final iterCount = math.min(totalPts, batchSize * 80);
    for (int i = 0; i < iterCount; i++) {
      final idx = rng.nextInt(n);
      qx = qx + ratio * (verts[idx].dx - qx);
      qy = qy + ratio * (verts[idx].dy - qy);
      if (i > 20) { buckets[idx].add(Offset(qx, qy)); }
    }
    for (int v = 0; v < n; v++) {
      final col = _transformColor(v, n).withValues(alpha: 0.75);
      final ptPaint = Paint()..color = col..strokeWidth = 0.8..style = PaintingStyle.fill;
      for (final pt in buckets[v]) {
        canvas.drawCircle(pt, 0.7, ptPaint);
      }
    }

    // Draw vertex circles with highlight of last chosen
    final lastIdx = (rng.nextInt(n));
    for (int i = 0; i < n; i++) {
      final isLast = i == lastIdx;
      canvas.drawCircle(verts[i], isLast ? 7 : 5,
          Paint()..color = _transformColor(i, n).withValues(alpha: isLast ? 1.0 : 0.6));
      canvas.drawCircle(verts[i], isLast ? 7 : 5,
          Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1);
    }

    // Point count label
    final tp = TextPainter(
      text: TextSpan(
        text: '점: ${math.min(totalPts, iterCount)}  꼭짓점: $n  비율: ${ratio.toStringAsFixed(2)}',
        style: const TextStyle(color: AppColors.muted, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 8);
    tp.paint(canvas, Offset(4, size.height - 16));
  }

  @override
  bool shouldRepaint(covariant _ChaosGameScreenPainter oldDelegate) => true;
}
