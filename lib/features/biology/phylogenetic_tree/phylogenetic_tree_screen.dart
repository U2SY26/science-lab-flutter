import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class PhylogeneticTreeScreen extends StatefulWidget {
  const PhylogeneticTreeScreen({super.key});
  @override
  State<PhylogeneticTreeScreen> createState() => _PhylogeneticTreeScreenState();
}

class _PhylogeneticTreeScreenState extends State<PhylogeneticTreeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _mutRate = 0.01;
  
  double _branches = 4, _treeDepth = 3.0;

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
      _branches = 4 + (_mutRate * 100).round().toDouble();
      _treeDepth = math.log(_branches) / math.ln2;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _mutRate = 0.01;
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
          Text('생물학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('계통수', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '계통수',
          formula: 'UPGMA / NJ',
          formulaDescription: '분자 데이터를 이용한 계통수 구성을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PhylogeneticTreeScreenPainter(
                time: _time,
                mutRate: _mutRate,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '돌연변이율',
                value: _mutRate,
                min: 0.001,
                max: 0.1,
                step: 0.001,
                defaultValue: 0.01,
                formatValue: (v) => v.toStringAsFixed(3),
                onChanged: (v) => setState(() => _mutRate = v),
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
          _V('분기점', _branches.toInt().toString()),
          _V('깊이', _treeDepth.toStringAsFixed(1)),
          _V('돌연변이율', _mutRate.toStringAsFixed(3)),
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

class _PhylogeneticTreeScreenPainter extends CustomPainter {
  final double time;
  final double mutRate;

  _PhylogeneticTreeScreenPainter({
    required this.time,
    required this.mutRate,
  });

  void _drawLabel(Canvas canvas, String text, Offset center,
      {double fontSize = 10, Color? color, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color ?? const Color(0xFF5A8A9A),
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    const cyanColor = Color(0xFF00D4FF);
    const orangeColor = Color(0xFFFF6B35);
    const greenColor = Color(0xFF64FF8C);
    const mutedColor = Color(0xFF5A8A9A);
    const inkColor = Color(0xFFE0F4FF);

    final w = size.width;
    final h = size.height;

    // Title
    final titleTp = TextPainter(
      text: const TextSpan(
          text: '계통수 (Phylogenetic Tree)',
          style: TextStyle(color: cyanColor, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, Offset((w - titleTp.width) / 2, 5));

    // Tree layout: root at bottom, leaves at top
    // 8 taxa with a bifurcating tree shape
    final treeBottom = h * 0.88;
    final treeTop = h * 0.10;
    final treeLeft = w * 0.08;
    final treeRight = w * 0.92;

    // Branch lengths influenced by mutRate (larger = longer branches)
    final branchScale = 0.5 + mutRate * 8.0;

    // Define the fixed cladogram structure:
    // 8 leaves: ((((A,B),(C,D)),((E,F),G)),H)
    // Leaf x positions (evenly spaced)
    const taxaNames = ['어류', '양서류', '파충류', '공룡', '조류', '포유류', '고래류', '인류'];
    final taxaColors = [
      cyanColor, cyanColor,
      greenColor, greenColor, greenColor,
      orangeColor, orangeColor, orangeColor,
    ];
    final leafCount = taxaNames.length;
    final leafSpacing = (treeRight - treeLeft) / (leafCount - 1);
    final leafY = treeTop + 14.0;

    // Leaf x positions
    final leafX = List.generate(leafCount, (i) => treeLeft + leafSpacing * i);

    // Node y levels (5 levels: leaves=0, then 4 internal)
    // Level depths scaled by branchScale
    final levelDepths = [0.0, 0.18, 0.36, 0.56, 0.78];

    final l0 = treeBottom - (treeBottom - treeTop - 14) * (levelDepths[1] * branchScale.clamp(0.5, 1.0));
    final l1 = treeBottom - (treeBottom - treeTop - 14) * (levelDepths[2] * branchScale.clamp(0.5, 1.0));
    final l2 = treeBottom - (treeBottom - treeTop - 14) * (levelDepths[3] * branchScale.clamp(0.5, 1.0));
    final l3 = treeBottom - (treeBottom - treeTop - 14) * (levelDepths[4] * branchScale.clamp(0.5, 1.0));

    final branchPaint = Paint()
      ..color = mutedColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Helper: draw L-shaped branch from child to parent node
    void drawBranch(double childX, double childY, double parentX, double parentY, {Color? color}) {
      final p = branchPaint;
      if (color != null) {
        canvas.drawLine(Offset(childX, childY), Offset(childX, parentY),
            Paint()..color = color.withValues(alpha: 0.7)..strokeWidth = 1.8..style = PaintingStyle.stroke);
        canvas.drawLine(Offset(childX, parentY), Offset(parentX, parentY),
            Paint()..color = color.withValues(alpha: 0.7)..strokeWidth = 1.8..style = PaintingStyle.stroke);
      } else {
        canvas.drawLine(Offset(childX, childY), Offset(childX, parentY), p);
        canvas.drawLine(Offset(childX, parentY), Offset(parentX, parentY), p);
      }
    }

    // Internal node positions (x = midpoint of children)
    // Level 1 nodes (pairs of leaves)
    final n00x = (leafX[0] + leafX[1]) / 2; // (A,B)
    final n01x = (leafX[2] + leafX[3]) / 2; // (C,D)
    final n02x = (leafX[4] + leafX[5]) / 2; // (E,F)
    final n03x = leafX[6];                    // G alone
    final n04x = leafX[7];                    // H alone

    // Level 2 nodes
    final n10x = (n00x + n01x) / 2; // ((A,B),(C,D))
    final n11x = (n02x + n03x) / 2; // ((E,F),G)

    // Level 3 node
    final n20x = (n10x + n11x) / 2; // (((A,B),(C,D)),((E,F),G))

    // Level 4 (root)
    final rootX = (n20x + n04x) / 2;
    final rootY = treeBottom;

    // Draw branches: leaves → level 1
    for (int i = 0; i < 2; i++) { drawBranch(leafX[i], leafY, n00x, l0, color: cyanColor); }
    for (int i = 2; i < 4; i++) { drawBranch(leafX[i], leafY, n01x, l0, color: greenColor); }
    for (int i = 4; i < 6; i++) { drawBranch(leafX[i], leafY, n02x, l0, color: orangeColor); }
    drawBranch(leafX[6], leafY, n03x, l0, color: orangeColor);
    drawBranch(leafX[7], leafY, n04x, l1);

    // Level 1 → level 2
    drawBranch(n00x, l0, n10x, l1);
    drawBranch(n01x, l0, n10x, l1);
    drawBranch(n02x, l0, n11x, l1);
    drawBranch(n03x, l0, n11x, l1);

    // Level 2 → level 3
    drawBranch(n10x, l1, n20x, l2);
    drawBranch(n11x, l1, n20x, l2);

    // Level 3 → root
    drawBranch(n20x, l2, rootX, l3);
    drawBranch(n04x, l1, rootX, l3);

    // Root vertical stub
    canvas.drawLine(Offset(rootX, l3), Offset(rootX, rootY), branchPaint);

    // Internal node circles with bootstrap values (seeded)
    final internalNodes = [
      (n00x, l0, '98'), (n01x, l0, '95'), (n02x, l0, '87'),
      (n10x, l1, '92'), (n11x, l1, '83'), (n20x, l2, '76'), (rootX, l3, ''),
    ];
    for (final node in internalNodes) {
      canvas.drawCircle(Offset(node.$1, node.$2), 4,
          Paint()..color = const Color(0xFF1A3040));
      canvas.drawCircle(Offset(node.$1, node.$2), 4,
          Paint()..color = mutedColor.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      if (node.$3.isNotEmpty) {
        _drawLabel(canvas, node.$3, Offset(node.$1 + 8, node.$2 - 7), fontSize: 7, color: greenColor);
      }
    }

    // Root marker
    canvas.drawCircle(Offset(rootX, rootY - 4), 5, Paint()..color = inkColor.withValues(alpha: 0.3));
    canvas.drawCircle(Offset(rootX, rootY - 4), 5,
        Paint()..color = inkColor..style = PaintingStyle.stroke..strokeWidth = 1.0);
    _drawLabel(canvas, '공통\n조상', Offset(rootX, rootY + 10), fontSize: 8, color: inkColor);

    // Leaf labels and dots
    for (int i = 0; i < leafCount; i++) {
      canvas.drawCircle(Offset(leafX[i], leafY), 5,
          Paint()..color = taxaColors[i].withValues(alpha: 0.4));
      canvas.drawCircle(Offset(leafX[i], leafY), 5,
          Paint()..color = taxaColors[i]..style = PaintingStyle.stroke..strokeWidth = 1.2);
      _drawLabel(canvas, taxaNames[i], Offset(leafX[i], leafY - 14), fontSize: 8, color: taxaColors[i]);
    }

    // Synapomorphy dots on branches (shared derived characters)
    final synNodes = [(n10x - 10, l1 + 8), (n11x + 8, l1 - 4)];
    for (final sn in synNodes) {
      canvas.drawCircle(Offset(sn.$1, sn.$2), 3.5, Paint()..color = const Color(0xFFFFCC00).withValues(alpha: 0.8));
    }
    _drawLabel(canvas, '공유파생형질', Offset(n10x - 24, l1 + 20), fontSize: 7, color: const Color(0xFFFFCC00));

    // Time scale bar at bottom
    final scaleY = h - 12.0;
    final scaleLeft = treeLeft;
    final scaleRight = treeLeft + (treeRight - treeLeft) * 0.4;
    canvas.drawLine(Offset(scaleLeft, scaleY), Offset(scaleRight, scaleY),
        Paint()..color = mutedColor..strokeWidth = 1.5);
    canvas.drawLine(Offset(scaleLeft, scaleY - 4), Offset(scaleLeft, scaleY + 4),
        Paint()..color = mutedColor..strokeWidth = 1.5);
    canvas.drawLine(Offset(scaleRight, scaleY - 4), Offset(scaleRight, scaleY + 4),
        Paint()..color = mutedColor..strokeWidth = 1.5);
    _drawLabel(canvas, '${(0.1 / mutRate).toStringAsFixed(0)} 백만년', Offset((scaleLeft + scaleRight) / 2, scaleY - 8), fontSize: 8, color: mutedColor);
  }

  @override
  bool shouldRepaint(covariant _PhylogeneticTreeScreenPainter oldDelegate) => true;
}
