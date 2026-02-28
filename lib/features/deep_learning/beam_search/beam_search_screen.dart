import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BeamSearchScreen extends StatefulWidget {
  const BeamSearchScreen({super.key});
  @override
  State<BeamSearchScreen> createState() => _BeamSearchScreenState();
}

class _BeamSearchScreenState extends State<BeamSearchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _beamWidth = 3;
  
  double _quality = 0.8, _candidates = 3;

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
      _candidates = _beamWidth;
      _quality = 1 - 1 / (_beamWidth + 1);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _beamWidth = 3.0;
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
          const Text('빔 서치 디코딩', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '빔 서치 디코딩',
          formula: 'Top-k beams at each step',
          formulaDescription: '빔 서치 디코딩 알고리즘을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BeamSearchScreenPainter(
                time: _time,
                beamWidth: _beamWidth,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '빔 너비 (k)',
                value: _beamWidth,
                min: 1,
                max: 10,
                step: 1,
                defaultValue: 3,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _beamWidth = v),
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
          _V('품질', '${(_quality * 100).toStringAsFixed(1)}%'),
          _V('후보', _candidates.toInt().toString()),
          _V('k', _beamWidth.toInt().toString()),
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

class _BeamSearchScreenPainter extends CustomPainter {
  final double time;
  final double beamWidth;

  _BeamSearchScreenPainter({
    required this.time,
    required this.beamWidth,
  });

  static const _cyan = Color(0xFF00D4FF);
  static const _orange = Color(0xFFFF6B35);
  static const _simBg = Color(0xFF0D1A20);
  static const _ink = Color(0xFFE0F4FF);
  static const _muted = Color(0xFF5A8A9A);
  static const _grid = Color(0xFF1A3040);

  // Deterministic pseudo-random score seeded by position
  double _score(int level, int idx) {
    final int seed = level * 31 + idx * 17;
    return 0.25 + 0.70 * ((math.sin(seed * 2.7182 + 1.4) + 1) / 2);
  }

  void _drawLabel(Canvas canvas, String text, Offset offset,
      {Color color = _ink, double fontSize = 10, FontWeight weight = FontWeight.w600}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = _simBg);

    // Subtle grid
    final gridPaint = Paint()..color = _grid.withValues(alpha: 0.3)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final int k = beamWidth.toInt().clamp(1, 10);
    // Tree layout: 4 levels (root + 3 expansion levels)
    const int levels = 4;
    final double topPad = 32.0;
    final double bottomPad = 42.0;
    final double levelH = (size.height - topPad - bottomPad) / (levels - 1);
    final double nodeR = math.min(14.0, (size.width / (k * 2.5)).clamp(8.0, 14.0));

    // Animate: tree expands level by level
    final double animCycle = (time * 0.35) % 1.0;
    final double revealedLevels = 1.0 + animCycle * (levels - 1);

    // Build node positions and scores level by level.
    // Level 0: root (1 node)
    // Level l: k^l nodes but we only keep top-k beams at each level
    // For simplicity, show k nodes per level (already-pruned beams)
    final List<List<Offset>> levelPositions = [];
    final List<List<double>> levelScores = [];
    final List<List<double>> levelCumScores = [];

    // Root
    levelPositions.add([Offset(size.width / 2, topPad)]);
    levelScores.add([1.0]);
    levelCumScores.add([1.0]);

    // Expand k beams per level
    // At level 1: k children from root, keep top k
    // At level l: k children from each of k parents → k*k candidates → keep top k
    for (int lvl = 1; lvl < levels; lvl++) {
      final double y = topPad + lvl * levelH;
      final List<Offset> positions = [];
      final List<double> scores = [];
      final List<double> cumScores = [];
      final double spacing = size.width / (k + 1);
      for (int i = 0; i < k; i++) {
        final double x = spacing * (i + 1);
        positions.add(Offset(x, y));
        final double s = _score(lvl, i);
        scores.add(s);
        // Cumulative: multiply with parent (simplified: divide by level to show decay)
        final double parentCum = lvl == 1
            ? levelCumScores[0][0]
            : levelCumScores[lvl - 1][i % levelCumScores[lvl - 1].length];
        cumScores.add(parentCum * s);
      }
      levelPositions.add(positions);
      levelScores.add(scores);
      levelCumScores.add(cumScores);
    }

    // Find best beam (highest cumulative score at last visible level)
    int bestLeafIdx = 0;
    double bestCum = 0;
    final int lastVisibleLevel = (revealedLevels - 1).toInt().clamp(0, levels - 1);
    for (int i = 0; i < levelCumScores[lastVisibleLevel].length; i++) {
      if (levelCumScores[lastVisibleLevel][i] > bestCum) {
        bestCum = levelCumScores[lastVisibleLevel][i];
        bestLeafIdx = i;
      }
    }

    // Draw edges first (behind nodes)
    for (int lvl = 1; lvl < levels; lvl++) {
      if (lvl > revealedLevels) { break; }
      final double levelAlpha = ((revealedLevels - lvl + 1)).clamp(0.0, 1.0);

      final List<Offset> parents = levelPositions[lvl - 1];
      final List<Offset> children = levelPositions[lvl];

      for (int ci = 0; ci < children.length; ci++) {
        final Offset child = children[ci];
        // Connect to nearest parent
        final int pi = (ci * parents.length / children.length).toInt().clamp(0, parents.length - 1);
        final Offset parent = parents[pi];

        // Is this edge on the best beam path?
        final bool isBest = (lvl == lastVisibleLevel && ci == bestLeafIdx) ||
            (lvl < lastVisibleLevel && ci == bestLeafIdx % parents.length);

        // Is pruned (low score)?
        final bool isPruned = levelScores[lvl][ci] < 0.4;

        Color edgeColor;
        double edgeWidth;
        if (isBest) {
          edgeColor = _orange.withValues(alpha: 0.9 * levelAlpha);
          edgeWidth = 2.0;
        } else if (isPruned) {
          edgeColor = _muted.withValues(alpha: 0.2 * levelAlpha);
          edgeWidth = 0.8;
        } else {
          edgeColor = _cyan.withValues(alpha: 0.3 * levelAlpha);
          edgeWidth = 1.2;
        }

        // Edge glow for best path
        if (isBest) {
          canvas.drawLine(parent, child,
              Paint()
                ..color = _orange.withValues(alpha: 0.15 * levelAlpha)
                ..strokeWidth = 6
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        }
        canvas.drawLine(parent, child,
            Paint()..color = edgeColor..strokeWidth = edgeWidth..strokeCap = StrokeCap.round);

        // Score label on edge
        if (!isPruned && lvl <= lastVisibleLevel) {
          final Offset mid = Offset((parent.dx + child.dx) / 2, (parent.dy + child.dy) / 2);
          _drawLabel(canvas, levelScores[lvl][ci].toStringAsFixed(2),
              Offset(mid.dx + 2, mid.dy - 8),
              color: (isBest ? _orange : _muted).withValues(alpha: 0.75 * levelAlpha),
              fontSize: 7.5);
        }
      }
    }

    // Draw nodes
    for (int lvl = 0; lvl < levels; lvl++) {
      if (lvl > revealedLevels) { break; }
      final double levelAlpha = ((revealedLevels - lvl + 1)).clamp(0.0, 1.0);
      final List<Offset> positions = levelPositions[lvl];

      for (int i = 0; i < positions.length; i++) {
        final Offset pos = positions[i];
        final double score = lvl == 0 ? 1.0 : levelScores[lvl][i];
        final bool isBest = lvl > 0 && lvl == lastVisibleLevel && i == bestLeafIdx;
        final bool isPruned = lvl > 0 && score < 0.4;

        // Node color by probability
        Color nodeColor;
        if (isPruned) {
          nodeColor = const Color(0xFF3A3A4A);
        } else {
          nodeColor = Color.lerp(
              _muted.withValues(alpha: 0.5),
              _cyan,
              score,
          )!;
        }

        // Glow for best node
        if (isBest) {
          final double pulse = 0.6 + 0.4 * math.sin(time * 3);
          canvas.drawCircle(pos, nodeR + 6,
              Paint()
                ..color = _orange.withValues(alpha: 0.3 * pulse * levelAlpha)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
          canvas.drawCircle(pos, nodeR + 2,
              Paint()..color = _orange.withValues(alpha: 0.5 * levelAlpha));
        }

        // Node fill
        canvas.drawCircle(pos, nodeR,
            Paint()..color = nodeColor.withValues(alpha: 0.85 * levelAlpha));
        // Node border
        canvas.drawCircle(pos, nodeR,
            Paint()
              ..color = (isBest ? _orange : isPruned ? _muted.withValues(alpha: 0.3) : _cyan)
                  .withValues(alpha: 0.8 * levelAlpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = isBest ? 2.0 : 1.0);

        // Score text inside node
        if (nodeR >= 10) {
          _drawLabel(canvas, score.toStringAsFixed(1),
              Offset(pos.dx - nodeR * 0.55, pos.dy - 5),
              color: (isPruned ? _muted : _simBg).withValues(alpha: levelAlpha),
              fontSize: 8.5, weight: FontWeight.bold);
        }

        // Pruned mark
        if (isPruned && lvl > 0 && lvl <= lastVisibleLevel) {
          final crossPaint = Paint()
            ..color = const Color(0xFFFF4560).withValues(alpha: 0.7 * levelAlpha)
            ..strokeWidth = 1.5;
          canvas.drawLine(
            Offset(pos.dx - nodeR * 0.5, pos.dy - nodeR * 0.5),
            Offset(pos.dx + nodeR * 0.5, pos.dy + nodeR * 0.5),
            crossPaint,
          );
          canvas.drawLine(
            Offset(pos.dx + nodeR * 0.5, pos.dy - nodeR * 0.5),
            Offset(pos.dx - nodeR * 0.5, pos.dy + nodeR * 0.5),
            crossPaint,
          );
        }
      }
    }

    // Root label
    _drawLabel(canvas, 'START',
        Offset(levelPositions[0][0].dx - 16, levelPositions[0][0].dy - nodeR - 14),
        color: _muted, fontSize: 8);

    // Best hypothesis bar at bottom
    final double barY = size.height - bottomPad + 6;
    _drawLabel(canvas, '최적 경로  cum.score: ${bestCum.toStringAsFixed(3)}',
        Offset(size.width / 2 - 80, barY),
        color: _orange.withValues(alpha: 0.9), fontSize: 9.5);

    // Level labels on left
    for (int lvl = 0; lvl < levels; lvl++) {
      if (lvl > revealedLevels) { break; }
      _drawLabel(canvas, 't$lvl',
          Offset(3, topPad + lvl * levelH - 6),
          color: _muted.withValues(alpha: 0.5), fontSize: 8);
    }

    // Title
    _drawLabel(canvas, '빔 서치  k=$k',
        Offset(size.width / 2 - 30, 8), color: _ink.withValues(alpha: 0.9), fontSize: 11);
  }

  @override
  bool shouldRepaint(covariant _BeamSearchScreenPainter oldDelegate) => true;
}
