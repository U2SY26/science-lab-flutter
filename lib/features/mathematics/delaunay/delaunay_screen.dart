import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DelaunayScreen extends StatefulWidget {
  const DelaunayScreen({super.key});
  @override
  State<DelaunayScreen> createState() => _DelaunayScreenState();
}

class _DelaunayScreenState extends State<DelaunayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _numPoints = 10;
  
  int _triangles = 0;

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
      _triangles = (2 * _numPoints - 5).toInt().clamp(1, 999);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _numPoints = 10.0;
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
          const Text('들로네 삼각분할', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '들로네 삼각분할',
          formula: 'Empty circumcircle',
          formulaDescription: '들로네 삼각분할과 외접원 조건을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DelaunayScreenPainter(
                time: _time,
                numPoints: _numPoints,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '점 수',
                value: _numPoints,
                min: 3,
                max: 50,
                step: 1,
                defaultValue: 10,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _numPoints = v),
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
          _V('삼각형', '$_triangles'),
          _V('점', _numPoints.toInt().toString()),
          _V('변', '${3 * _triangles ~/ 2}'),
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

class _DelaunayScreenPainter extends CustomPainter {
  final double time;
  final double numPoints;

  _DelaunayScreenPainter({required this.time, required this.numPoints});

  static const int kPts = 15;

  List<Offset> _basePoints(Size size) {
    final rng = math.Random(42);
    const pad = 36.0;
    return List.generate(kPts, (_) => Offset(
      pad + rng.nextDouble() * (size.width - pad * 2),
      pad + rng.nextDouble() * (size.height * 0.80 - pad),
    ));
  }

  List<Offset> _animatedPoints(Size size) {
    final base = _basePoints(size);
    return List.generate(kPts, (i) => Offset(
      base[i].dx + 6 * math.sin(time * 0.5 + i * 1.1),
      base[i].dy + 6 * math.cos(time * 0.4 + i * 0.8),
    ));
  }

  // Simple Bowyer-Watson-style triangulation: connect every point to its
  // two closest neighbours to approximate Delaunay triangles.
  List<List<int>> _triangulate(List<Offset> pts) {
    final tris = <List<int>>[];
    final n = pts.length;
    for (int i = 0; i < n; i++) {
      // Find two nearest neighbours
      final dists = List.generate(n, (j) {
        if (j == i) return <double>[double.infinity, j.toDouble()];
        final dx = pts[i].dx - pts[j].dx, dy = pts[i].dy - pts[j].dy;
        return <double>[dx * dx + dy * dy, j.toDouble()];
      });
      dists.sort((a, b) => a[0].compareTo(b[0]));
      final a = dists[0][1].toInt();
      final b = dists[1][1].toInt();
      if (i < a && i < b) tris.add([i, a, b]);
    }
    return tris;
  }

  // Circumcircle center & radius for triangle
  (Offset, double) _circumcircle(Offset a, Offset b, Offset c) {
    final ax = a.dx, ay = a.dy, bx = b.dx, by = b.dy, cx = c.dx, cy = c.dy;
    final d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));
    if (d.abs() < 1e-6) return (Offset.zero, 0);
    final ux = ((ax*ax + ay*ay) * (by - cy) + (bx*bx + by*by) * (cy - ay) + (cx*cx + cy*cy) * (ay - by)) / d;
    final uy = ((ax*ax + ay*ay) * (cx - bx) + (bx*bx + by*by) * (ax - cx) + (cx*cx + cy*cy) * (bx - ax)) / d;
    final center = Offset(ux, uy);
    final r = (a - center).distance;
    return (center, r);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 10 || size.height < 10) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final pts = _animatedPoints(size);
    final tris = _triangulate(pts);

    // Highlighted triangle index (cycles)
    final int hiIdx = tris.isEmpty ? 0 : (time * 0.8).floor() % tris.length;

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int t = 0; t < tris.length; t++) {
      final tri = tris[t];
      final a = pts[tri[0]], b = pts[tri[1]], c = pts[tri[2]];
      final path = Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy)..lineTo(c.dx, c.dy)..close();
      fillPaint.color = t == hiIdx
          ? const Color(0xFF00D4FF).withValues(alpha: 0.15)
          : const Color(0xFF1A3040).withValues(alpha: 0.5);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    }

    // Circumscribed circle for highlighted triangle
    if (hiIdx < tris.length) {
      final tri = tris[hiIdx];
      final (center, r) = _circumcircle(pts[tri[0]], pts[tri[1]], pts[tri[2]]);
      if (r > 0 && r < size.width) {
        final dashPaint = Paint()
          ..color = const Color(0xFFFF6B35).withValues(alpha: 0.8)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        // Dashed circle via path segments
        final path = Path();
        const segs = 40;
        for (int s = 0; s < segs; s++) {
          if (s % 2 == 0) {
            final a1 = s * 2 * math.pi / segs, a2 = (s + 0.6) * 2 * math.pi / segs;
            path.moveTo(center.dx + r * math.cos(a1), center.dy + r * math.sin(a1));
            path.lineTo(center.dx + r * math.cos(a2), center.dy + r * math.sin(a2));
          }
        }
        canvas.drawPath(path, dashPaint);
        canvas.drawCircle(center, 3, Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.fill);
      }

      // Dual Voronoi dashed lines to circumcenter from each vertex
      if (r > 0 && r < size.width) {
        final (center, _) = _circumcircle(pts[tri[0]], pts[tri[1]], pts[tri[2]]);
        final dualPaint = Paint()
          ..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        for (final vi in tri) {
          canvas.drawLine(pts[vi], center, dualPaint);
        }
      }
    }

    // Draw points
    for (int i = 0; i < kPts; i++) {
      canvas.drawCircle(pts[i], 5, Paint()..color = const Color(0xFF0D1A20)..style = PaintingStyle.fill);
      canvas.drawCircle(pts[i], 5, Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    }

    // Label
    final ltp = TextPainter(
      text: const TextSpan(text: '들로네 속성: 외접원 내부에 점 없음', style: TextStyle(color: Color(0xFFFF6B35), fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    ltp.paint(canvas, Offset((size.width - ltp.width) / 2, size.height - 18));
  }

  @override
  bool shouldRepaint(covariant _DelaunayScreenPainter oldDelegate) => true;
}
