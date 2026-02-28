import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class MinimumSpanningTreeScreen extends StatefulWidget {
  const MinimumSpanningTreeScreen({super.key});
  @override
  State<MinimumSpanningTreeScreen> createState() => _MinimumSpanningTreeScreenState();
}

class _MinimumSpanningTreeScreenState extends State<MinimumSpanningTreeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _nodeCount = 8;
  
  double _totalWeight = 0; int _mstEdges = 7;

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
      _mstEdges = _nodeCount.toInt() - 1;
      _totalWeight = _mstEdges * 5.0 + 10 * math.sin(_time);
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
          const Text('최소 신장 트리', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '최소 신장 트리',
          formula: '|E(MST)| = |V| - 1',
          formulaDescription: '크루스칼/프림 알고리즘으로 최소 신장 트리를 구성합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _MinimumSpanningTreeScreenPainter(
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
          _V('MST 간선', '$_mstEdges'),
          _V('총 가중치', _totalWeight.toStringAsFixed(1)),
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

class _MinimumSpanningTreeScreenPainter extends CustomPainter {
  final double time;
  final double nodeCount;

  _MinimumSpanningTreeScreenPainter({
    required this.time,
    required this.nodeCount,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 9}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  // Union-Find for Kruskal's
  int _find(List<int> parent, int x) {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
  }

  bool _union(List<int> parent, List<int> rank, int a, int b) {
    final ra = _find(parent, a), rb = _find(parent, b);
    if (ra == rb) return false;
    if (rank[ra] < rank[rb]) { parent[ra] = rb; }
    else if (rank[ra] > rank[rb]) { parent[rb] = ra; }
    else { parent[rb] = ra; rank[ra]++; }
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Background grid
    final gridP = Paint()..color = AppColors.simGrid.withValues(alpha: 0.18)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 32) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridP); }
    for (double y = 0; y < size.height; y += 32) { canvas.drawLine(Offset(0, y), Offset(size.width, y), gridP); }

    final n = nodeCount.toInt().clamp(3, 20);
    final rng = math.Random(42);
    final pad = 36.0;

    // Stable node positions
    final nodePos = List.generate(n, (_) =>
      Offset(pad + rng.nextDouble() * (size.width - pad * 2),
             pad + rng.nextDouble() * (size.height - pad * 2 - 18)));

    // Generate all edges with integer weights
    final allEdges = <(int, int, int)>[];
    final rng2 = math.Random(42);
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        // Only add edge with ~50% probability to keep graph sparse
        if (rng2.nextDouble() < 0.45 || j == i + 1) {
          final w = 1 + rng2.nextInt(19);
          allEdges.add((i, j, w));
        }
      }
    }
    // Sort by weight (Kruskal's)
    allEdges.sort((a, b) => a.$3.compareTo(b.$3));

    // Run Kruskal's to find MST edges
    final parent = List.generate(n, (i) => i);
    final rank = List.filled(n, 0);
    final mstEdgeIndices = <int>{};
    double totalCost = 0;
    for (int i = 0; i < allEdges.length; i++) {
      final (a, b, w) = allEdges[i];
      if (_union(parent, rank, a, b)) {
        mstEdgeIndices.add(i);
        totalCost += w;
        if (mstEdgeIndices.length == n - 1) break;
      }
    }

    // Animate: reveal MST edges one by one
    final mstList = mstEdgeIndices.toList()..sort();
    final stepDuration = 1.5; // seconds per edge
    final totalTime = mstList.length * stepDuration + 2.0;
    final animTime = time % totalTime;
    final edgesRevealed = (animTime / stepDuration).floor().clamp(0, mstList.length);

    // Draw non-MST edges (dim)
    for (int i = 0; i < allEdges.length; i++) {
      if (mstEdgeIndices.contains(i)) continue;
      final (a, b, w) = allEdges[i];
      final from = nodePos[a], to = nodePos[b];
      canvas.drawLine(from, to,
        Paint()..color = AppColors.muted.withValues(alpha: 0.18)..strokeWidth = 1.0);
      // Weight label
      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      _drawLabel(canvas, '$w', Offset(mid.dx - 4, mid.dy - 5),
        AppColors.muted.withValues(alpha: 0.35), fontSize: 8);
    }

    // Draw MST edges with animation
    double shownCost = 0;
    for (int idx = 0; idx < mstList.length; idx++) {
      final edgeIdx = mstList[idx];
      final (a, b, w) = allEdges[edgeIdx];
      final from = nodePos[a], to = nodePos[b];
      final isRevealed = idx < edgesRevealed;
      final isCurrent = idx == edgesRevealed - 1;

      if (isRevealed) {
        shownCost += w;
        // Glow
        if (isCurrent) {
          for (int g = 3; g >= 1; g--) {
            canvas.drawLine(from, to,
              Paint()..color = AppColors.accent.withValues(alpha: 0.06 * g)
                     ..strokeWidth = 4.0 + g * 2..strokeCap = StrokeCap.round);
          }
        }
        canvas.drawLine(from, to,
          Paint()..color = AppColors.accent.withValues(alpha: 0.9)..strokeWidth = 2.5..strokeCap = StrokeCap.round);
        // Weight label
        final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
        _drawLabel(canvas, '$w', Offset(mid.dx - 4, mid.dy - 6), AppColors.accent, fontSize: 9);
      } else {
        // Rejected edges: briefly flash orange then stay dim red
        final rejectPhase = (animTime - idx * stepDuration).clamp(0.0, stepDuration);
        if (rejectPhase > 0 && rejectPhase < 0.4 && idx < edgesRevealed + 1) {
          canvas.drawLine(from, to,
            Paint()..color = AppColors.accent2.withValues(alpha: 0.6)..strokeWidth = 2.0);
        }
      }
    }

    // Draw nodes
    for (int i = 0; i < n; i++) {
      final p = nodePos[i];
      for (int g = 2; g >= 1; g--) {
        canvas.drawCircle(p, 10.0 + g * 2,
          Paint()..color = AppColors.accent.withValues(alpha: 0.04 * g));
      }
      canvas.drawCircle(p, 10, Paint()..color = AppColors.simBg);
      canvas.drawCircle(p, 10,
        Paint()..color = AppColors.accent..style = PaintingStyle.stroke..strokeWidth = 1.8);
      final idTp = TextPainter(
        text: TextSpan(text: '$i',
          style: const TextStyle(color: AppColors.accent, fontSize: 8, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      idTp.paint(canvas, Offset(p.dx - idTp.width / 2, p.dy - idTp.height / 2));
    }

    // Total MST cost display
    _drawLabel(canvas,
      'MST 총 가중치: ${shownCost.toStringAsFixed(0)} / ${totalCost.toStringAsFixed(0)}  (간선 $edgesRevealed/${mstList.length})',
      Offset(8, 6), AppColors.ink, fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _MinimumSpanningTreeScreenPainter oldDelegate) => true;
}
