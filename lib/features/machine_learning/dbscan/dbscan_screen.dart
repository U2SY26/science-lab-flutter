import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DbscanScreen extends StatefulWidget {
  const DbscanScreen({super.key});
  @override
  State<DbscanScreen> createState() => _DbscanScreenState();
}

class _DbscanScreenState extends State<DbscanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _epsilon = 30;
  double _minPts = 3;
  int _clusters = 3, _noise = 5;

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
      _clusters = (100 / (_epsilon + 1)).round().clamp(1, 15);
      _noise = (_minPts * 2).round();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _epsilon = 30.0; _minPts = 3.0;
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
          const Text('DBSCAN 클러스터링', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: 'DBSCAN 클러스터링',
          formula: 'MinPts, ε-neighborhood',
          formulaDescription: '밀도 기반 클러스터링 알고리즘을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DbscanScreenPainter(
                time: _time,
                epsilon: _epsilon,
                minPts: _minPts,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'ε (반경)',
                value: _epsilon,
                min: 5,
                max: 100,
                step: 1,
                defaultValue: 30,
                formatValue: (v) => v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _epsilon = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'MinPts',
                value: _minPts,
                min: 1,
                max: 10,
                step: 1,
                defaultValue: 3,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _minPts = v),
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
          _V('클러스터', '$_clusters'),
          _V('노이즈', '$_noise'),
          _V('ε', _epsilon.toStringAsFixed(0)),
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

class _DbscanScreenPainter extends CustomPainter {
  final double time;
  final double epsilon;
  final double minPts;

  _DbscanScreenPainter({
    required this.time,
    required this.epsilon,
    required this.minPts,
  });

  static const _clusterColors = [
    Color(0xFF00D4FF), // cyan
    Color(0xFFFF6B35), // orange
    Color(0xFF64FF8C), // green
    Color(0xFFBB86FC), // purple
  ];

  // Generate stable cluster points with seeded random
  List<Offset> _generatePoints(Size size) {
    final rng = math.Random(42);
    final pad = 30.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final pts = <Offset>[];
    // 3 main clusters
    final centers = [
      Offset(pad + w * 0.25, pad + h * 0.30),
      Offset(pad + w * 0.70, pad + h * 0.25),
      Offset(pad + w * 0.50, pad + h * 0.72),
    ];
    final spread = [32.0, 28.0, 35.0];
    final counts = [40, 38, 42];
    for (int c = 0; c < centers.length; c++) {
      for (int i = 0; i < counts[c]; i++) {
        final angle = rng.nextDouble() * math.pi * 2;
        final r = rng.nextDouble() * spread[c];
        pts.add(Offset(centers[c].dx + r * math.cos(angle), centers[c].dy + r * math.sin(angle)));
      }
    }
    // noise points
    for (int i = 0; i < 16; i++) {
      pts.add(Offset(pad + rng.nextDouble() * w, pad + rng.nextDouble() * h));
    }
    return pts;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // Subtle grid
    final gridPaint = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.5)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint); }
    for (double y = 0; y < size.height; y += 28) { canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint); }

    final pts = _generatePoints(size);
    final eps = epsilon.clamp(5.0, 100.0);
    final minP = minPts.clamp(1.0, 10.0).toInt();

    // Animate query point sweeping across dataset in a figure-8 path
    final t = time * 0.4;
    final cx = size.width / 2 + size.width * 0.35 * math.sin(t);
    final cy = size.height / 2 + size.height * 0.30 * math.sin(t * 2);
    final queryPt = Offset(cx, cy);

    // Scale epsilon to canvas (epsilon param 5-100 → pixels 15-80)
    final epsPixels = 15.0 + (eps - 5) / 95 * 65;

    // Classify each point relative to ALL neighbors (simplified DBSCAN color logic)
    // Count neighbors within eps for each point
    final neighborCounts = List<int>.filled(pts.length, 0);
    for (int i = 0; i < pts.length; i++) {
      for (int j = 0; j < pts.length; j++) {
        if (i == j) continue;
        if ((pts[i] - pts[j]).distance <= epsPixels) neighborCounts[i]++;
      }
    }

    // Assign cluster IDs (greedy BFS)
    final clusterIds = List<int>.filled(pts.length, -1); // -1=noise
    int nextCluster = 0;
    for (int i = 0; i < pts.length; i++) {
      if (clusterIds[i] != -1 || neighborCounts[i] < minP) continue;
      final queue = <int>[i];
      clusterIds[i] = nextCluster;
      while (queue.isNotEmpty) {
        final cur = queue.removeAt(0);
        for (int j = 0; j < pts.length; j++) {
          if (clusterIds[j] != -1) continue;
          if ((pts[cur] - pts[j]).distance <= epsPixels) {
            clusterIds[j] = nextCluster;
            if (neighborCounts[j] >= minP) queue.add(j);
          }
        }
      }
      nextCluster++;
    }

    // Draw epsilon circle glow (pulsing)
    final pulse = 0.6 + 0.4 * math.sin(time * 3.5);
    final circlePaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.08 * pulse)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(queryPt, epsPixels, circlePaint);

    // Dashed epsilon ring
    _drawDashedCircle(canvas, queryPt, epsPixels, const Color(0xFF00D4FF).withValues(alpha: 0.7 * pulse), 1.5);

    // Draw all points
    for (int i = 0; i < pts.length; i++) {
      final inRange = (pts[i] - queryPt).distance <= epsPixels;
      final cid = clusterIds[i];
      final isCore = neighborCounts[i] >= minP;
      final isNoise = cid == -1;

      Color ptColor;
      double ptRadius;
      if (isNoise) {
        ptColor = const Color(0xFFFF4466);
        ptRadius = 3.5;
      } else {
        ptColor = _clusterColors[cid % _clusterColors.length];
        ptRadius = isCore ? 5.5 : 3.5;
      }

      // Glow for in-range points
      if (inRange && !isNoise) {
        canvas.drawCircle(pts[i], ptRadius + 5, Paint()..color = ptColor.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      }

      // Fill
      canvas.drawCircle(pts[i], ptRadius, Paint()..color = ptColor.withValues(alpha: isNoise ? 0.55 : 0.9));

      // Core point ring
      if (isCore) {
        canvas.drawCircle(pts[i], ptRadius + 2, Paint()..color = ptColor.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.2);
      }

      // Noise X mark
      if (isNoise) {
        final xp = Paint()..color = const Color(0xFFFF4466).withValues(alpha: 0.7)..strokeWidth = 1.5;
        canvas.drawLine(pts[i].translate(-4, -4), pts[i].translate(4, 4), xp);
        canvas.drawLine(pts[i].translate(4, -4), pts[i].translate(-4, 4), xp);
      }
    }

    // Query point marker
    final qGlow = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(queryPt, 10, qGlow);
    canvas.drawCircle(queryPt, 5, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(queryPt, 5, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Legend
    _drawLegend(canvas, size);
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Color color, double strokeWidth) {
    final paint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke;
    const dashCount = 28;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 1) continue;
      final a1 = i / dashCount * math.pi * 2;
      final a2 = (i + 0.7) / dashCount * math.pi * 2;
      final path = Path()..moveTo(center.dx + radius * math.cos(a1), center.dy + radius * math.sin(a1))..arcTo(Rect.fromCircle(center: center, radius: radius), a1, a2 - a1, false);
      canvas.drawPath(path, paint);
    }
  }

  void _drawLegend(Canvas canvas, Size size) {
    final items = [
      ('Core', const Color(0xFF00D4FF)),
      ('Border', const Color(0xFF64FF8C)),
      ('Noise', const Color(0xFFFF4466)),
    ];
    double lx = 10;
    for (final (label, color) in items) {
      canvas.drawCircle(Offset(lx + 5, size.height - 12), 4, Paint()..color = color.withValues(alpha: 0.9));
      final tp = TextPainter(text: TextSpan(text: label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(lx + 12, size.height - 17));
      lx += tp.width + 22;
    }
  }

  @override
  bool shouldRepaint(covariant _DbscanScreenPainter oldDelegate) => true;
}
