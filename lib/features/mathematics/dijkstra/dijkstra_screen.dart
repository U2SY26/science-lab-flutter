import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DijkstraScreen extends StatefulWidget {
  const DijkstraScreen({super.key});
  @override
  State<DijkstraScreen> createState() => _DijkstraScreenState();
}

class _DijkstraScreenState extends State<DijkstraScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _nodeCount = 8;
  
  double _shortestPath = 10, _visited = 0;

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
      _visited = (_time * 2).clamp(0, _nodeCount);
      _shortestPath = _nodeCount * 1.5 - _visited * 0.2;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _nodeCount = 8.0;
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
          const Text('다익스트라 알고리즘', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '다익스트라 알고리즘',
          formula: 'd[v] = min(d[v], d[u]+w(u,v))',
          formulaDescription: '다익스트라 최단 경로 알고리즘을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DijkstraScreenPainter(
                time: _time,
                nodeCount: _nodeCount,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '노드 수',
                value: _nodeCount,
                min: 3,
                max: 20,
                step: 1,
                defaultValue: 8,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _nodeCount = v),
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
          _V('최단경로', _shortestPath.toStringAsFixed(1)),
          _V('방문', _visited.toInt().toString() + '/' + _nodeCount.toInt().toString()),
          _V('노드', _nodeCount.toInt().toString()),
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

class _DijkstraScreenPainter extends CustomPainter {
  final double time;
  final double nodeCount;

  _DijkstraScreenPainter({required this.time, required this.nodeCount});

  static const int nodeTotal = 7;

  // Stable node positions seeded with Random(42)
  List<Offset> _nodePositions(Size size) {
    final rng = math.Random(42);
    const pad = 40.0;
    return List.generate(nodeTotal, (_) => Offset(
      pad + rng.nextDouble() * (size.width - pad * 2),
      pad + rng.nextDouble() * (size.height * 0.75 - pad * 2),
    ));
  }

  // Weighted edges: pairs of node indices + weight
  static const List<List<int>> _edges = [
    [0,1,4],[0,2,2],[1,2,5],[1,3,10],[2,4,3],[3,5,11],[4,3,4],[4,5,8],[4,6,2],[5,6,9],[2,6,6],[3,6,7],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 10 || size.height < 10) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final nodes = _nodePositions(size);
    // How many nodes "visited" based on time (cycles every 7 seconds)
    final cycle = (time % 7.0) / 7.0;
    final visitedCount = (cycle * nodeTotal).floor();
    // Dijkstra step order: 0→2→4→6→1→3→5
    const order = [0, 2, 4, 6, 1, 3, 5];
    final visitedSet = <int>{};
    for (int i = 0; i <= visitedCount && i < nodeTotal; i++) {
      visitedSet.add(order[i]);
    }

    // Simulated distances
    final dist = List.filled(nodeTotal, double.infinity);
    const fakeDist = [0.0, 14.0, 2.0, 16.0, 5.0, 13.0, 7.0];
    for (int i = 0; i < nodeTotal; i++) {
      if (visitedSet.contains(i)) dist[i] = fakeDist[i];
    }

    // Path highlight: 0→2→4→6 (indices in order)
    const pathNodes = [0, 2, 4, 6];
    final pathSet = <String>{};
    for (int i = 0; i < pathNodes.length - 1; i++) {
      pathSet.add('${pathNodes[i]}-${pathNodes[i+1]}');
      pathSet.add('${pathNodes[i+1]}-${pathNodes[i]}');
    }

    final edgePaint = Paint()..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final pathPaint = Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 3..style = PaintingStyle.stroke;

    // Draw edges
    for (final e in _edges) {
      final a = nodes[e[0]], b = nodes[e[1]];
      final key1 = '${e[0]}-${e[1]}', key2 = '${e[1]}-${e[0]}';
      final isPath = pathSet.contains(key1) || pathSet.contains(key2);
      if (isPath && visitedSet.contains(e[0]) && visitedSet.contains(e[1])) {
        canvas.drawLine(a, b, pathPaint);
      } else {
        edgePaint.color = const Color(0xFF5A8A9A).withValues(alpha: 0.4);
        canvas.drawLine(a, b, edgePaint);
      }
      // Weight label
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final wtp = TextPainter(
        text: TextSpan(text: '${e[2]}', style: const TextStyle(color: Color(0xFF5A8A9A), fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      wtp.paint(canvas, mid - Offset(wtp.width / 2, wtp.height / 2));
    }

    // Draw nodes
    for (int i = 0; i < nodeTotal; i++) {
      final pos = nodes[i];
      final isSource = i == 0;
      final isDest = i == 6;
      final isVisited = visitedSet.contains(i);
      final isCurrent = visitedSet.isNotEmpty && order[visitedCount.clamp(0, nodeTotal - 1)] == i;

      Color fillColor;
      Color borderColor;
      double glowR = 0;
      Color glowColor = const Color(0xFF00D4FF);

      if (isSource) {
        fillColor = const Color(0xFF1A4030);
        borderColor = const Color(0xFF64FF8C);
        glowR = 20; glowColor = const Color(0xFF64FF8C);
      } else if (isDest) {
        fillColor = const Color(0xFF3A1A10);
        borderColor = const Color(0xFFFF6B35);
        glowR = 20; glowColor = const Color(0xFFFF6B35);
      } else if (isVisited) {
        fillColor = const Color(0xFF003040);
        borderColor = const Color(0xFF00D4FF);
      } else {
        fillColor = const Color(0xFF1A2A30);
        borderColor = const Color(0xFF5A8A9A);
      }

      if (isCurrent && !isSource && !isDest) {
        glowR = 18; glowColor = const Color(0xFF00D4FF);
      }

      if (glowR > 0) {
        canvas.drawCircle(pos, glowR, Paint()
          ..color = glowColor.withValues(alpha: 0.2 + 0.1 * math.sin(time * 4))
          ..style = PaintingStyle.fill);
      }

      canvas.drawCircle(pos, 14, Paint()..color = fillColor..style = PaintingStyle.fill);
      canvas.drawCircle(pos, 14, Paint()..color = borderColor..strokeWidth = 2..style = PaintingStyle.stroke);

      // Node label
      final label = String.fromCharCode(65 + i); // A-G
      final ntp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: borderColor, fontSize: 11, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      ntp.paint(canvas, pos - Offset(ntp.width / 2, ntp.height / 2));

      // Distance label above node
      final distStr = dist[i].isInfinite ? '∞' : dist[i].toInt().toString();
      final dtp = TextPainter(
        text: TextSpan(text: distStr, style: const TextStyle(color: Color(0xFFE0F4FF), fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      dtp.paint(canvas, Offset(pos.dx - dtp.width / 2, pos.dy - 28));
    }

    // Priority queue panel on right
    final pqX = size.width - 90;
    final pqPaint = Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pqX - 4, 4, 88, 16.0 + visitedSet.length * 16), const Radius.circular(4)), pqPaint);
    final htp = TextPainter(
      text: const TextSpan(text: 'PQ', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 9, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    htp.paint(canvas, Offset(pqX, 7));
    int row = 0;
    for (final idx in order) {
      if (!visitedSet.contains(idx)) break;
      final label = '${String.fromCharCode(65+idx)}: ${fakeDist[idx].toInt()}';
      final rtp = TextPainter(
        text: TextSpan(text: label, style: const TextStyle(color: Color(0xFFE0F4FF), fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      rtp.paint(canvas, Offset(pqX, 20 + row * 16.0));
      row++;
    }

    // Bottom label
    final btp = TextPainter(
      text: TextSpan(
        text: '최단경로: A→C→E→G  (거리: 7)',
        style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    btp.paint(canvas, Offset((size.width - btp.width) / 2, size.height - 20));
  }

  @override
  bool shouldRepaint(covariant _DijkstraScreenPainter oldDelegate) => true;
}
