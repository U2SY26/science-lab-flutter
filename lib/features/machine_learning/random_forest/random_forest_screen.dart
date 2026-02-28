import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class RandomForestScreen extends StatefulWidget {
  const RandomForestScreen({super.key});
  @override
  State<RandomForestScreen> createState() => _RandomForestScreenState();
}

class _RandomForestScreenState extends State<RandomForestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _numTrees = 5.0;
  double _maxDepth = 3.0;
  double _accuracy = 0;

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
      _accuracy = 0.65 + 0.03 * _numTrees.clamp(1, 10) + 0.02 * _maxDepth;
      if (_accuracy > 0.98) _accuracy = 0.98;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _numTrees = 5.0;
      _maxDepth = 3.0;
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
          const Text('랜덤 포레스트', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '랜덤 포레스트',
          formula: 'ŷ = mode(h₁(x), h₂(x), ..., hₙ(x))',
          formulaDescription: '여러 결정 트리의 다수결로 분류합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _RandomForestScreenPainter(
                time: _time,
                numTrees: _numTrees,
                maxDepth: _maxDepth,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '트리 수',
                value: _numTrees,
                min: 1.0,
                max: 15.0,
                defaultValue: 5.0,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => _numTrees = v),
              ),
              advancedControls: [
            SimSlider(
                label: '최대 깊이',
                value: _maxDepth,
                min: 1.0,
                max: 6.0,
                defaultValue: 3.0,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => _maxDepth = v),
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
          _V('정확도', '${(_accuracy * 100).toStringAsFixed(1)}%'),
          _V('트리', '${_numTrees.toInt()}'),
          _V('깊이', '${_maxDepth.toInt()}'),
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

class _RandomForestScreenPainter extends CustomPainter {
  final double time;
  final double numTrees;
  final double maxDepth;

  _RandomForestScreenPainter({
    required this.time,
    required this.numTrees,
    required this.maxDepth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final n = numTrees.toInt().clamp(1, 15);
    final depth = maxDepth.toInt().clamp(1, 6);

    // Layout: top row = mini trees, bottom = feature importance + ensemble result
    final treeAreaH = h * 0.52;
    final barAreaH = h * 0.33;
    final barAreaY = treeAreaH + h * 0.06;

    // Title
    _text(canvas, '랜덤 포레스트 앙상블', Offset(w / 2 - 52, 4),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold));

    // Draw mini decision trees
    final treeW = (w - 16) / n.clamp(1, 7);
    final visibleTrees = n.clamp(1, 7);
    final rng = math.Random(42);

    // Each tree votes class 0 or class 1
    final votes = List.generate(n, (i) => rng.nextBool() ? 0 : 1);
    // Animate current tree being "active"
    final activeTree = (time * 1.2).toInt() % n;

    for (int t = 0; t < visibleTrees; t++) {
      final tx = 8.0 + t * treeW + treeW / 2;
      final ty = 22.0;
      final isActive = (t == activeTree % visibleTrees);
      _drawMiniTree(canvas, Offset(tx, ty), treeW * 0.9, treeAreaH - 36, depth,
          votes[t], isActive, rng);
    }

    // Votes summary bar
    final votes1 = votes.where((v) => v == 1).length;
    final votes0 = n - votes1;
    final voteX = w / 2;
    final voteY = treeAreaH + 4;
    _text(canvas, '투표: C₁=$votes1  C₂=$votes0  →  ${votes1 > votes0 ? "C₁" : "C₂"} 선택',
        Offset(voteX - 70, voteY),
        TextStyle(
          color: votes1 > votes0 ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ));

    // Feature importance bars (3 features)
    final featNames = ['특성 A', '특성 B', '특성 C'];
    final featImportance = [0.50 + depth * 0.03, 0.30 - depth * 0.01, 0.20 - depth * 0.01];
    final total = featImportance.reduce((a, b) => a + b);
    final norm = featImportance.map((f) => f / total).toList();

    final barX = 40.0;
    final barMaxW = w - barX - 12;
    const barColors = [Color(0xFF00D4FF), Color(0xFFFF6B35), Color(0xFF64FF8C)];

    _text(canvas, '특성 중요도', Offset(barX, barAreaY - 2),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8, fontWeight: FontWeight.bold));

    for (int i = 0; i < 3; i++) {
      final by = barAreaY + 12 + i * (barAreaH / 3.5);
      final bw = norm[i] * barMaxW;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barX, by, bw, 12), const Radius.circular(2)),
        Paint()..color = barColors[i].withValues(alpha: 0.75),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barX, by, barMaxW, 12), const Radius.circular(2)),
        Paint()..color = barColors[i].withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 0.5,
      );
      _text(canvas, '${featNames[i]}  ${(norm[i] * 100).toStringAsFixed(0)}%',
          Offset(barX + bw + 4, by + 1),
          TextStyle(color: barColors[i].withValues(alpha: 0.9), fontSize: 8));
    }

    // Single tree vs ensemble error display
    final singleErr = 0.35 - depth * 0.02;
    final ensErr = singleErr / math.sqrt(n.toDouble());
    final errY = barAreaY + barAreaH + 8;
    _text(canvas, '단일 트리 오류: ${(singleErr * 100).toStringAsFixed(0)}%   앙상블 오류: ${(ensErr * 100).toStringAsFixed(0)}%',
        Offset(w / 2 - 85, errY),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));
  }

  void _drawMiniTree(Canvas canvas, Offset center, double treeW, double treeH,
      int depth, int vote, bool active, math.Random rng) {
    final nodeR = (treeW / (depth * 2.2)).clamp(3.0, 7.0);
    final linePaint = Paint()
      ..color = active
          ? const Color(0xFF00D4FF).withValues(alpha: 0.7)
          : const Color(0xFF5A8A9A).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    void drawNode(Offset pos, int d, double spread) {
      if (d > depth) return;
      final isLeaf = d == depth;
      final nodeColor = isLeaf
          ? (vote == 1 ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35))
          : (active ? const Color(0xFF5A8A9A) : const Color(0xFF1A3040));
      canvas.drawCircle(pos, nodeR * (isLeaf ? 0.9 : 1.0),
          Paint()..color = nodeColor.withValues(alpha: 0.8));
      canvas.drawCircle(pos, nodeR * (isLeaf ? 0.9 : 1.0),
          Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke..strokeWidth = 0.5);
      if (!isLeaf) {
        final nextY = pos.dy + treeH / depth;
        final lPos = Offset(pos.dx - spread / 2, nextY);
        final rPos = Offset(pos.dx + spread / 2, nextY);
        canvas.drawLine(pos, lPos, linePaint);
        canvas.drawLine(pos, rPos, linePaint);
        drawNode(lPos, d + 1, spread / 2);
        drawNode(rPos, d + 1, spread / 2);
      }
    }

    drawNode(center, 1, treeW * 0.5);
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _RandomForestScreenPainter oldDelegate) => true;
}
