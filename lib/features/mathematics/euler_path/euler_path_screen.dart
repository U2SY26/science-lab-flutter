import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class EulerPathScreen extends StatefulWidget {
  const EulerPathScreen({super.key});
  @override
  State<EulerPathScreen> createState() => _EulerPathScreenState();
}

class _EulerPathScreenState extends State<EulerPathScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _nodes = 6;
  double _edges = 8;
  bool _hasEuler = true; int _oddDeg = 0;

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
      _oddDeg = (_edges.toInt() * 2 % _nodes.toInt()).clamp(0, _nodes.toInt());
      _hasEuler = _oddDeg == 0 || _oddDeg == 2;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _nodes = 6.0; _edges = 8.0;
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
          const Text('오일러 경로', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '오일러 경로',
          formula: 'deg(v) conditions',
          formulaDescription: '오일러 경로와 해밀턴 경로의 존재 조건을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _EulerPathScreenPainter(
                time: _time,
                nodes: _nodes,
                edges: _edges,
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
                value: _nodes,
                min: 3,
                max: 12,
                step: 1,
                defaultValue: 6,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _nodes = v),
              ),
              advancedControls: [
            SimSlider(
                label: '간선 수',
                value: _edges,
                min: 3,
                max: 30,
                step: 1,
                defaultValue: 8,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _edges = v),
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
          _V('오일러', _hasEuler ? '존재' : '불가'),
          _V('홀수차', '$_oddDeg'),
          _V('V/E', '${_nodes.toInt()}/${_edges.toInt()}'),
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

class _EulerPathScreenPainter extends CustomPainter {
  final double time;
  final double nodes;
  final double edges;

  _EulerPathScreenPainter({
    required this.time,
    required this.nodes,
    required this.edges,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 9}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Background grid
    final gridP = Paint()..color = AppColors.simGrid.withValues(alpha: 0.18)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 32) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridP); }
    for (double y = 0; y < size.height; y += 32) { canvas.drawLine(Offset(0, y), Offset(size.width, y), gridP); }

    final nodeCount = nodes.toInt().clamp(3, 12);
    final rng = math.Random(42);

    // Generate stable node positions
    final pad = 36.0;
    final nodePos = List.generate(nodeCount, (i) {
      final x = pad + rng.nextDouble() * (size.width - pad * 2);
      final y = pad + rng.nextDouble() * (size.height - pad * 2 - 20);
      return Offset(x, y);
    });

    // Generate edges: deterministic from seed, ensure connected
    final edgeSet = <String>{};
    final edgeList = <(int, int)>[];
    // First: chain to ensure connectivity
    for (int i = 0; i < nodeCount - 1; i++) {
      final key = '${i}_${i+1}';
      if (edgeSet.add(key)) edgeList.add((i, i + 1));
    }
    // Extra edges
    final rng2 = math.Random(42);
    final extraCount = (edges.toInt() - (nodeCount - 1)).clamp(0, nodeCount * 2);
    for (int attempt = 0; attempt < extraCount * 4 && edgeList.length < edges.toInt(); attempt++) {
      final a = rng2.nextInt(nodeCount);
      final b = rng2.nextInt(nodeCount);
      if (a == b) continue;
      final lo = a < b ? a : b;
      final hi = a < b ? b : a;
      final key = '${lo}_$hi';
      if (edgeSet.add(key)) edgeList.add((lo, hi));
    }

    // Compute degree per node
    final degree = List.filled(nodeCount, 0);
    for (final e in edgeList) { degree[e.$1]++; degree[e.$2]++; }
    final oddNodes = degree.where((d) => d % 2 == 1).length;
    final hasEuler = oddNodes == 0 || oddNodes == 2;

    // Animate traversal: cycle through edges
    final totalEdges = edgeList.length;
    final traversalStep = totalEdges > 0
        ? ((time * 0.7) % (totalEdges + 2.0)).floor()
        : 0;
    final visitedEdges = traversalStep.clamp(0, totalEdges);
    final isComplete = visitedEdges >= totalEdges;

    // Draw edges
    for (int i = 0; i < edgeList.length; i++) {
      final (a, b) = edgeList[i];
      final from = nodePos[a];
      final to   = nodePos[b];
      Color edgeColor;
      double strokeW;
      if (i < visitedEdges - 1) {
        edgeColor = AppColors.accent.withValues(alpha: 0.85);
        strokeW = 2.0;
      } else if (i == visitedEdges - 1) {
        // Current edge: orange glow
        edgeColor = AppColors.accent2;
        strokeW = 3.0;
        for (int g = 3; g >= 1; g--) {
          canvas.drawLine(from, to,
            Paint()..color = AppColors.accent2.withValues(alpha: 0.08 * g)
                   ..strokeWidth = strokeW + g * 3..strokeCap = StrokeCap.round);
        }
      } else {
        edgeColor = AppColors.muted.withValues(alpha: 0.3);
        strokeW = 1.2;
      }
      canvas.drawLine(from, to,
        Paint()..color = edgeColor..strokeWidth = strokeW..strokeCap = StrokeCap.round);
    }

    // Draw nodes
    for (int i = 0; i < nodeCount; i++) {
      final p = nodePos[i];
      final isOdd = degree[i] % 2 == 1;
      final nodeColor = isOdd ? AppColors.accent2 : AppColors.accent;
      // Glow
      for (int g = 3; g >= 1; g--) {
        canvas.drawCircle(p, 10.0 + g * 2.5,
          Paint()..color = nodeColor.withValues(alpha: 0.05 * g));
      }
      canvas.drawCircle(p, 10, Paint()..color = AppColors.simBg);
      canvas.drawCircle(p, 10,
        Paint()..color = nodeColor..style = PaintingStyle.stroke..strokeWidth = 2.0);
      // Degree number
      final degTp = TextPainter(
        text: TextSpan(text: '${degree[i]}',
          style: TextStyle(color: nodeColor, fontSize: 9, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      degTp.paint(canvas, Offset(p.dx - degTp.width / 2, p.dy - degTp.height / 2));
    }

    // Status label
    if (isComplete) {
      _drawLabel(canvas, '오일러 경로 발견!',
        Offset(size.width / 2 - 40, size.height - 18),
        hasEuler ? AppColors.accent : AppColors.accent2, fontSize: 11);
    }

    // Info
    _drawLabel(canvas, '홀수차 노드: $oddNodes   ${hasEuler ? "오일러 경로 존재" : "오일러 경로 불가"}',
      Offset(8, 6), hasEuler ? AppColors.accent : AppColors.accent2, fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _EulerPathScreenPainter oldDelegate) => true;
}
