import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class MendelianGeneticsScreen extends StatefulWidget {
  const MendelianGeneticsScreen({super.key});
  @override
  State<MendelianGeneticsScreen> createState() => _MendelianGeneticsScreenState();
}

class _MendelianGeneticsScreenState extends State<MendelianGeneticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _parent1 = 1.0;
  double _parent2 = 1.0;
  double _ratioAA = 0.25, _ratioAa = 0.5, _ratioaa = 0.25;

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
      final a1 = _parent1.toInt(), a2 = _parent2.toInt();
      final p1A = a1 == 0 ? 1.0 : a1 == 1 ? 0.5 : 0.0;
      final p2A = a2 == 0 ? 1.0 : a2 == 1 ? 0.5 : 0.0;
      _ratioAA = p1A * p2A;
      _ratioAa = p1A * (1 - p2A) + (1 - p1A) * p2A;
      _ratioaa = (1 - p1A) * (1 - p2A);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _parent1 = 1.0;
      _parent2 = 1.0;
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
          Text('생물 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('멘델 유전학', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물 시뮬레이션',
          title: '멘델 유전학',
          formula: 'AA:Aa:aa = 1:2:1',
          formulaDescription: '우성과 열성 대립유전자의 유전 법칙을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _MendelianGeneticsScreenPainter(
                time: _time,
                parent1: _parent1,
                parent2: _parent2,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '부모 1 (0=AA,1=Aa,2=aa)',
                value: _parent1,
                min: 0.0,
                max: 2.0,
                defaultValue: 1.0,
                formatValue: (v) => '${["AA","Aa","aa"][v.toInt()]}',
                onChanged: (v) => setState(() => _parent1 = v),
              ),
              advancedControls: [
            SimSlider(
                label: '부모 2 (0=AA,1=Aa,2=aa)',
                value: _parent2,
                min: 0.0,
                max: 2.0,
                defaultValue: 1.0,
                formatValue: (v) => '${["AA","Aa","aa"][v.toInt()]}',
                onChanged: (v) => setState(() => _parent2 = v),
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
          _V('AA', '${(_ratioAA * 100).toStringAsFixed(0)}%'),
          _V('Aa', '${(_ratioAa * 100).toStringAsFixed(0)}%'),
          _V('aa', '${(_ratioaa * 100).toStringAsFixed(0)}%'),
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

class _MendelianGeneticsScreenPainter extends CustomPainter {
  final double time;
  final double parent1;
  final double parent2;

  _MendelianGeneticsScreenPainter({
    required this.time,
    required this.parent1,
    required this.parent2,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, {double fontSize = 11, Color? color}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color ?? AppColors.muted, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final p1 = parent1.toInt(); // 0=AA, 1=Aa, 2=aa
    final p2 = parent2.toInt();
    final p1A = p1 == 0 ? 1.0 : p1 == 1 ? 0.5 : 0.0;
    final p2A = p2 == 0 ? 1.0 : p2 == 1 ? 0.5 : 0.0;
    final ratioAA = p1A * p2A;
    final ratioAa = p1A * (1 - p2A) + (1 - p1A) * p2A;
    final ratioaa = (1 - p1A) * (1 - p2A);

    final labels = ['AA', 'Aa', 'aa'];
    final p1Label = labels[p1];
    final p2Label = labels[p2];

    // Colors
    const cyanColor = Color(0xFF00D4FF);
    const orangeColor = Color(0xFFFF6B35);
    const greenColor = Color(0xFF64FF8C);
    const mutedColor = Color(0xFF5A8A9A);
    const inkColor = Color(0xFFE0F4FF);

    Color genoColor(int g) {
      if (g == 0) return cyanColor;
      if (g == 1) return greenColor;
      return orangeColor;
    }

    final w = size.width;
    final h = size.height;

    // --- Title ---
    final titleTp = TextPainter(
      text: const TextSpan(text: '멘델 유전학 (P → F2 세대)', style: TextStyle(color: cyanColor, fontSize: 13, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, Offset((w - titleTp.width) / 2, 6));

    // Layout: 3 rows: P, F1, F2
    final rowY = [h * 0.22, h * 0.50, h * 0.78];
    final rowLabels = ['P 세대', 'F1 세대', 'F2 세대'];

    // Draw row labels on left
    for (int r = 0; r < 3; r++) {
      final ltp = TextPainter(
        text: TextSpan(text: rowLabels[r], style: const TextStyle(color: mutedColor, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      ltp.paint(canvas, Offset(6, rowY[r] - ltp.height / 2));
    }

    // --- P generation: 2 parent circles ---
    final pPositions = [Offset(w * 0.30, rowY[0]), Offset(w * 0.70, rowY[0])];
    final pColors = [genoColor(p1), genoColor(p2)];
    final pLabels = [p1Label, p2Label];
    final pR = 22.0;
    for (int i = 0; i < 2; i++) {
      canvas.drawCircle(pPositions[i], pR, Paint()..color = pColors[i].withValues(alpha: 0.25));
      canvas.drawCircle(pPositions[i], pR, Paint()..color = pColors[i]..style = PaintingStyle.stroke..strokeWidth = 2);
      _drawLabel(canvas, pLabels[i], pPositions[i], fontSize: 13, color: pColors[i]);
      // dominance label below
      final domText = i == 0 ? (p1 == 0 ? '우성' : p1 == 1 ? '이형' : '열성') : (p2 == 0 ? '우성' : p2 == 1 ? '이형' : '열성');
      _drawLabel(canvas, domText, pPositions[i] + const Offset(0, 32), fontSize: 9, color: mutedColor);
    }

    // Cross symbol between parents
    _drawLabel(canvas, '×', Offset(w / 2, rowY[0]), fontSize: 16, color: mutedColor);

    // Arrows P → F1
    final arrowPaint = Paint()..color = mutedColor.withValues(alpha: 0.5)..strokeWidth = 1.0;
    canvas.drawLine(Offset(w / 2, rowY[0] + pR + 4), Offset(w / 2, rowY[1] - 26), arrowPaint);

    // --- F1 generation: all Aa (if Aa cross) or appropriate ---
    // F1 genotype is always Aa when P is AA x aa; adjust for other crosses
    final f1Geno = (p1 == 0 && p2 == 2) || (p1 == 2 && p2 == 0)
        ? 1 // Aa
        : (p1 == 0 && p2 == 0) || (p1 == 2 && p2 == 2)
            ? p1
            : 1;
    final f1Color = genoColor(f1Geno);
    final f1Label = labels[f1Geno];
    canvas.drawCircle(Offset(w / 2, rowY[1]), pR, Paint()..color = f1Color.withValues(alpha: 0.25));
    canvas.drawCircle(Offset(w / 2, rowY[1]), pR, Paint()..color = f1Color..style = PaintingStyle.stroke..strokeWidth = 2);
    _drawLabel(canvas, f1Label, Offset(w / 2, rowY[1]), fontSize: 13, color: f1Color);
    _drawLabel(canvas, 'F1 자손', Offset(w / 2, rowY[1] + 32), fontSize: 9, color: mutedColor);

    // Arrow F1 → F2
    canvas.drawLine(Offset(w / 2, rowY[1] + pR + 4), Offset(w / 2, rowY[2] - 10), arrowPaint);

    // --- F2 generation: 4 circles with ratio ---
    final f2Labels = ['AA', 'Aa', 'aa'];
    final f2Colors = [cyanColor, greenColor, orangeColor];
    // Show 4 circles: 1 AA, 2 Aa, 1 aa proportionally spaced
    final f2Positions = [
      Offset(w * 0.18, rowY[2]),
      Offset(w * 0.38, rowY[2]),
      Offset(w * 0.62, rowY[2]),
      Offset(w * 0.82, rowY[2]),
    ];
    final f2GenoSeq = [0, 1, 1, 2]; // 1:2:1 pattern
    final f2SmR = 17.0;
    for (int i = 0; i < 4; i++) {
      final g = f2GenoSeq[i];
      final c = f2Colors[g];
      canvas.drawCircle(f2Positions[i], f2SmR, Paint()..color = c.withValues(alpha: 0.20));
      canvas.drawCircle(f2Positions[i], f2SmR, Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = 1.5);
      _drawLabel(canvas, f2Labels[g], f2Positions[i], fontSize: 11, color: c);
    }

    // Ratio bar chart at bottom
    final barTop = h * 0.88;
    final barH = h * 0.09;
    final barLeft = w * 0.12;
    final barRight = w * 0.88;
    final barW = barRight - barLeft;

    final ratios = [ratioAA, ratioAa, ratioaa];
    final barColors = [cyanColor, greenColor, orangeColor];
    double bx = barLeft;
    for (int i = 0; i < 3; i++) {
      final bw = barW * ratios[i];
      if (bw > 1) {
        canvas.drawRect(
          Rect.fromLTWH(bx, barTop, bw, barH),
          Paint()..color = barColors[i].withValues(alpha: 0.7),
        );
        if (bw > 24) {
          _drawLabel(canvas, '${(ratios[i] * 100).round()}%', Offset(bx + bw / 2, barTop + barH / 2), fontSize: 9, color: inkColor);
        }
      }
      bx += bw;
    }
    // Bar border
    canvas.drawRect(
      Rect.fromLTWH(barLeft, barTop, barW, barH),
      Paint()..color = mutedColor.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 0.8,
    );

    // Legend
    final legendItems = [('AA 우성', cyanColor), ('Aa 이형', greenColor), ('aa 열성', orangeColor)];
    for (int i = 0; i < 3; i++) {
      final lx = barLeft + barW * (i / 3.0) + barW / 6;
      canvas.drawCircle(Offset(lx - 14, barTop - 10), 4, Paint()..color = legendItems[i].$2);
      _drawLabel(canvas, legendItems[i].$1, Offset(lx, barTop - 10), fontSize: 9, color: mutedColor);
    }
  }

  @override
  bool shouldRepaint(covariant _MendelianGeneticsScreenPainter oldDelegate) => true;
}
