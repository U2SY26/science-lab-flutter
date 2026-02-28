import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class MinimaxScreen extends StatefulWidget {
  const MinimaxScreen({super.key});
  @override
  State<MinimaxScreen> createState() => _MinimaxScreenState();
}

class _MinimaxScreenState extends State<MinimaxScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _treeDepth = 3;
  double _branchFactor = 2;
  double _nodesExplored = 0, _pruned = 0;

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
      _nodesExplored = math.pow(_branchFactor, _treeDepth).toDouble();
      _pruned = _nodesExplored * 0.4;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _treeDepth = 3; _branchFactor = 2;
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
          const Text('미니맥스 게임 트리', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '미니맥스 게임 트리',
          formula: 'v(s)=max/min v(children)',
          formulaDescription: '알파-베타 가지치기로 미니맥스 의사결정을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _MinimaxScreenPainter(
                time: _time,
                treeDepth: _treeDepth,
                branchFactor: _branchFactor,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '트리 깊이',
                value: _treeDepth,
                min: 2,
                max: 6,
                step: 1,
                defaultValue: 3,
                formatValue: (v) => '${v.toStringAsFixed(0)} 레벨',
                onChanged: (v) => setState(() => _treeDepth = v),
              ),
              advancedControls: [
            SimSlider(
                label: '분기 인자',
                value: _branchFactor,
                min: 2,
                max: 4,
                step: 1,
                defaultValue: 2,
                formatValue: (v) => v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _branchFactor = v),
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
          _V('탐색 노드', _nodesExplored.toStringAsFixed(0)),
          _V('가지치기', _pruned.toStringAsFixed(0)),
          _V('깊이', _treeDepth.toStringAsFixed(0)),
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

class _MinimaxScreenPainter extends CustomPainter {
  final double time;
  final double treeDepth;
  final double branchFactor;

  _MinimaxScreenPainter({
    required this.time,
    required this.treeDepth,
    required this.branchFactor,
  });

  // Terminal scores for leaf nodes (fixed layout, 3 branches, 3 sub-branches = 9 leaves + 1 center)
  static const List<int> _leafScores = [10, -10, 0, -10, 10, 0, 0, -10, 10];
  // Which leaves are pruned by alpha-beta (indices)
  static const Set<int> _prunedLeaves = {3, 7, 8};
  // Best path: root -> branch 0 -> sub 0 -> leaf 0 (score=10)
  static const List<int> _bestBranch = [0, 0]; // [lvl1 branch, lvl2 sub-branch]

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final depth = treeDepth.toInt().clamp(2, 4);
    final bf = branchFactor.toInt().clamp(2, 4);

    // Animation: evaluate left to right over 4 seconds, then loop
    final animCycle = 5.0;
    final animT = (time % animCycle) / animCycle; // 0..1
    // Total leaf nodes = bf^(depth-1), evaluate in order
    final totalLeaves = math.pow(bf, depth - 1).toInt();
    final revealedLeaves = (animT * (totalLeaves + 2)).floor();

    final pad = 14.0;
    final topY = pad + 22.0;
    final bottomY = size.height - pad - 10;

    // Draw up to 3 visible levels (cap for space)
    final visDepth = depth.clamp(2, 3);
    final visLevelH = (bottomY - topY) / (visDepth - 1);

    // Node radius
    final nr = (size.width / (bf * bf * 2.8)).clamp(8.0, 16.0);

    // Helper: draw glow circle
    void drawGlowCircle(Canvas c, Offset pos, double r, Color col, {double alpha = 1.0}) {
      for (int g = 3; g >= 1; g--) {
        c.drawCircle(pos, r + g * 2.5, Paint()..color = col.withValues(alpha: alpha * 0.07 * g));
      }
      c.drawCircle(pos, r, Paint()..color = col.withValues(alpha: alpha));
    }

    // Helper: draw text centered
    void drawCenteredText(Canvas c, String text, Offset center, Color col, double fs, {bool bold = false}) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
    }

    // Level 0: root (MAX, X)
    final rootPos = Offset(size.width / 2, topY);

    // Level 1 positions
    final l1Count = bf.clamp(2, 3);
    final l1Positions = List.generate(l1Count, (i) {
      final fraction = l1Count == 1 ? 0.5 : i / (l1Count - 1);
      return Offset(pad + fraction * (size.width - pad * 2), topY + visLevelH);
    });

    // Level 2 positions (leaves in vis depth==2, or mid-nodes in depth==3)
    final l2Count = l1Count * bf.clamp(2, 3);
    final l2Positions = List.generate(l2Count, (i) {
      final fraction = l2Count == 1 ? 0.5 : i / (l2Count - 1);
      return Offset(pad + fraction * (size.width - pad * 2), topY + visLevelH * (visDepth - 1));
    });

    // Determine which nodes are on the best path
    bool isBestL1(int i) => i == _bestBranch[0] % l1Count;
    bool isBestL2(int b1, int b2) => isBestL1(b1) && b2 == _bestBranch[1] % bf.clamp(2, 3);

    int leafIndex = 0;

    // Draw edges from root to L1
    for (int i = 0; i < l1Count; i++) {
      final onBest = isBestL1(i);
      canvas.drawLine(
        rootPos, l1Positions[i],
        Paint()
          ..color = onBest
              ? Colors.white.withValues(alpha: 0.85)
              : AppColors.muted.withValues(alpha: 0.35)
          ..strokeWidth = onBest ? 2.0 : 1.0,
      );
    }

    // Draw edges from L1 to L2
    final subBf = bf.clamp(2, 3);
    for (int i = 0; i < l1Count; i++) {
      for (int j = 0; j < subBf; j++) {
        final l2i = i * subBf + j;
        if (l2i >= l2Count) continue;
        final onBest = isBestL2(i, j);
        final pruned = _prunedLeaves.contains(leafIndex) && visDepth == 2;
        canvas.drawLine(
          l1Positions[i], l2Positions[l2i],
          Paint()
            ..color = pruned
                ? AppColors.muted.withValues(alpha: 0.15)
                : onBest
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.muted.withValues(alpha: 0.35)
            ..strokeWidth = onBest ? 2.0 : 0.9,
        );
        leafIndex++;
      }
    }

    // Draw L2 nodes (leaves or intermediate)
    leafIndex = 0;
    int revealCount = 0;
    for (int i = 0; i < l1Count; i++) {
      for (int j = 0; j < subBf; j++) {
        final l2i = i * subBf + j;
        if (l2i >= l2Count) { leafIndex++; continue; }
        final score = _leafScores[leafIndex % _leafScores.length];
        final pruned = _prunedLeaves.contains(leafIndex);
        final revealed = revealCount < revealedLeaves;
        final onBest = isBestL2(i, j);
        revealCount++;

        Color nodeColor;
        if (!revealed) {
          nodeColor = AppColors.simGrid;
        } else if (pruned) {
          nodeColor = AppColors.muted.withValues(alpha: 0.4);
        } else if (score > 0) {
          nodeColor = const Color(0xFF00FF88);
        } else if (score < 0) {
          nodeColor = const Color(0xFFFF4444);
        } else {
          nodeColor = AppColors.muted;
        }

        final pos = l2Positions[l2i];
        final glowAlpha = onBest && revealed ? 1.0 : 0.75;
        drawGlowCircle(canvas, pos, nr, nodeColor, alpha: glowAlpha);

        if (onBest && revealed) {
          canvas.drawCircle(pos, nr,
            Paint()..color = Colors.white.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5);
        }

        if (revealed) {
          if (pruned) {
            drawCenteredText(canvas, '✕', pos, AppColors.muted, nr * 0.9);
          } else {
            final scoreStr = score > 0 ? '+$score' : '$score';
            drawCenteredText(canvas, scoreStr, pos, Colors.white.withValues(alpha: 0.9), nr * 0.72, bold: true);
          }
        } else {
          drawCenteredText(canvas, '?', pos, AppColors.muted.withValues(alpha: 0.5), nr * 0.75);
        }

        leafIndex++;
      }
    }

    // Draw L1 nodes (MIN, O, orange)
    for (int i = 0; i < l1Count; i++) {
      final onBest = isBestL1(i);
      drawGlowCircle(canvas, l1Positions[i], nr, AppColors.accent2, alpha: onBest ? 1.0 : 0.75);
      if (onBest) {
        canvas.drawCircle(l1Positions[i], nr,
          Paint()..color = Colors.white.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
      drawCenteredText(canvas, 'O', l1Positions[i], Colors.white.withValues(alpha: 0.9), nr * 0.78, bold: true);
    }

    // Draw root (MAX, X, cyan) with pulse
    final pulse = 1.0 + math.sin(time * 2.5) * 0.08;
    drawGlowCircle(canvas, rootPos, nr * pulse, AppColors.accent);
    canvas.drawCircle(rootPos, nr * pulse,
      Paint()..color = Colors.white.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.8);
    drawCenteredText(canvas, 'X', rootPos, Colors.white, nr * 0.82, bold: true);

    // Level labels on right edge
    void drawLabel(String text, double y, Color col) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: col, fontSize: 8.5, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width - 2, y - tp.height / 2));
    }

    drawLabel('MAX', topY, AppColors.accent);
    drawLabel('MIN', topY + visLevelH, AppColors.accent2);
    if (visDepth > 2) drawLabel('LEAF', topY + visLevelH * 2, AppColors.muted);

    // Legend: pruned indicator
    final legendY = size.height - 8.0;
    canvas.drawCircle(Offset(8, legendY), 4, Paint()..color = AppColors.muted.withValues(alpha: 0.5));
    final ltp = TextPainter(
      text: TextSpan(text: ' 가지치기 (α-β)', style: TextStyle(color: AppColors.muted, fontSize: 8)),
      textDirection: TextDirection.ltr,
    )..layout();
    ltp.paint(canvas, Offset(13, legendY - ltp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MinimaxScreenPainter oldDelegate) => true;
}
