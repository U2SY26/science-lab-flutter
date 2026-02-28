import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class PunnettSquareScreen extends StatefulWidget {
  const PunnettSquareScreen({super.key});
  @override
  State<PunnettSquareScreen> createState() => _PunnettSquareScreenState();
}

class _PunnettSquareScreenState extends State<PunnettSquareScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _numTraits = 1.0;
  

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
      
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _numTraits = 1.0;
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
          const Text('펀넷 사각형', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물 시뮬레이션',
          title: '펀넷 사각형',
          formulaDescription: '인터랙티브 펀넷 사각형으로 유전자형 비율을 예측합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PunnettSquareScreenPainter(
                time: _time,
                numTraits: _numTraits,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '형질 수',
                value: _numTraits,
                min: 1.0,
                max: 2.0,
                defaultValue: 1.0,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => _numTraits = v),
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
          _V('형질', '${_numTraits.toInt()}'),
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

class _PunnettSquareScreenPainter extends CustomPainter {
  final double time;
  final double numTraits;

  _PunnettSquareScreenPainter({
    required this.time,
    required this.numTraits,
  });

  void _drawText(Canvas canvas, String text, Offset center, {double fontSize = 11, Color? color, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color ?? const Color(0xFF5A8A9A),
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  Color _genoColor(String geno) {
    final allLower = geno == geno.toLowerCase();
    if (allLower) return const Color(0xFFFF6B35); // recessive aa
    final uniqueAlleles = geno.split('').toSet();
    if (uniqueAlleles.length == 1) return const Color(0xFF00D4FF); // homozygous dominant AA
    return const Color(0xFF64FF8C); // heterozygous Aa
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    const cyanColor = Color(0xFF00D4FF);
    const mutedColor = Color(0xFF5A8A9A);
    const inkColor = Color(0xFFE0F4FF);
    const gridColor = Color(0xFF1A3040);

    final w = size.width;
    final h = size.height;
    final isMono = numTraits < 1.5;

    // Title
    final titleTp = TextPainter(
      text: TextSpan(
        text: isMono ? '펀넷 사각형 — 단성잡종 (Aa × Aa)' : '펀넷 사각형 — 양성잡종 (AaBb × AaBb)',
        style: const TextStyle(color: cyanColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, Offset((w - titleTp.width) / 2, 6));

    if (isMono) {
      // 2x2 grid: Aa x Aa
      // Gametes: A, a for both parents
      final rowGametes = ['A', 'a'];
      final colGametes = ['A', 'a'];
      final results = [
        ['AA', 'Aa'],
        ['Aa', 'aa'],
      ];

      const n = 2;
      final gridLeft = w * 0.18;
      final gridTop = h * 0.18;
      final cellW = (w * 0.62) / n;
      final cellH = (h * 0.60) / n;
      final headerSize = 28.0;

      // Column headers (parent 1 gametes - top)
      for (int c = 0; c < n; c++) {
        _drawText(canvas, colGametes[c],
            Offset(gridLeft + headerSize + cellW * c + cellW / 2, gridTop + headerSize / 2),
            fontSize: 13, color: cyanColor, bold: true);
      }
      // Row headers (parent 2 gametes - left)
      for (int r = 0; r < n; r++) {
        _drawText(canvas, rowGametes[r],
            Offset(gridLeft + headerSize / 2, gridTop + headerSize + cellH * r + cellH / 2),
            fontSize: 13, color: cyanColor, bold: true);
      }

      // Parent labels
      _drawText(canvas, '♂ 부', Offset(gridLeft + headerSize + cellW * n / 2, gridTop - 10), fontSize: 10, color: mutedColor);
      _drawText(canvas, '♀ 모', Offset(gridLeft - 10, gridTop + headerSize + cellH * n / 2), fontSize: 10, color: mutedColor);

      // Cells
      for (int r = 0; r < n; r++) {
        for (int c = 0; c < n; c++) {
          final geno = results[r][c];
          final cellRect = Rect.fromLTWH(
            gridLeft + headerSize + cellW * c,
            gridTop + headerSize + cellH * r,
            cellW, cellH,
          );
          final cellColor = _genoColor(geno);
          canvas.drawRect(cellRect, Paint()..color = cellColor.withValues(alpha: 0.18));
          canvas.drawRect(cellRect, Paint()..color = gridColor..style = PaintingStyle.stroke..strokeWidth = 1.0);
          _drawText(canvas, geno, cellRect.center, fontSize: 14, color: cellColor, bold: true);
        }
      }

      // Ratio display (right side)
      final ratioX = gridLeft + headerSize + cellW * n + 16;
      final ratioData = [('AA', '25%', const Color(0xFF00D4FF)), ('Aa', '50%', const Color(0xFF64FF8C)), ('aa', '25%', const Color(0xFFFF6B35))];
      _drawText(canvas, '비율', Offset(ratioX + 28, gridTop + headerSize), fontSize: 10, color: mutedColor);
      for (int i = 0; i < 3; i++) {
        final ry = gridTop + headerSize + 18.0 + i * 26;
        canvas.drawCircle(Offset(ratioX + 8, ry), 7, Paint()..color = ratioData[i].$3.withValues(alpha: 0.4));
        canvas.drawCircle(Offset(ratioX + 8, ry), 7, Paint()..color = ratioData[i].$3..style = PaintingStyle.stroke..strokeWidth = 1.5);
        _drawText(canvas, ratioData[i].$1, Offset(ratioX + 8, ry), fontSize: 9, color: ratioData[i].$3);
        _drawText(canvas, ratioData[i].$2, Offset(ratioX + 34, ry), fontSize: 10, color: inkColor);
      }

      // Phenotype bar below
      final barTop = gridTop + headerSize + cellH * n + 14;
      final barLeft2 = gridLeft + headerSize;
      final barW2 = cellW * n;
      final barH2 = 16.0;
      // dominant : recessive = 3:1
      canvas.drawRect(Rect.fromLTWH(barLeft2, barTop, barW2 * 0.75, barH2),
          Paint()..color = cyanColor.withValues(alpha: 0.65));
      canvas.drawRect(Rect.fromLTWH(barLeft2 + barW2 * 0.75, barTop, barW2 * 0.25, barH2),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.65));
      canvas.drawRect(Rect.fromLTWH(barLeft2, barTop, barW2, barH2),
          Paint()..color = mutedColor.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 0.8);
      _drawText(canvas, '우성 표현형 75%', Offset(barLeft2 + barW2 * 0.375, barTop + barH2 / 2), fontSize: 9, color: inkColor);
      _drawText(canvas, '열성 25%', Offset(barLeft2 + barW2 * 0.875, barTop + barH2 / 2), fontSize: 9, color: inkColor);

    } else {
      // 4x4 grid: AaBb x AaBb
      final gametes = ['AB', 'Ab', 'aB', 'ab'];
      const n = 4;
      final gridLeft = w * 0.04;
      final gridTop = h * 0.14;
      final cellW = (w * 0.80) / n;
      final cellH = (h * 0.62) / n;
      final headerSize = 22.0;

      // Column & row headers
      for (int c = 0; c < n; c++) {
        _drawText(canvas, gametes[c],
            Offset(gridLeft + headerSize + cellW * c + cellW / 2, gridTop + headerSize / 2),
            fontSize: 9, color: cyanColor, bold: true);
      }
      for (int r = 0; r < n; r++) {
        _drawText(canvas, gametes[r],
            Offset(gridLeft + headerSize / 2, gridTop + headerSize + cellH * r + cellH / 2),
            fontSize: 9, color: cyanColor, bold: true);
      }

      // Determine phenotype for 9:3:3:1
      Color phenoColor(int r, int c) {
        final g1 = gametes[r];
        final g2 = gametes[c];
        final alleles = g1 + g2;
        final hasA = alleles.contains('A');
        final hasB = alleles.contains('B');
        if (hasA && hasB) return const Color(0xFF00D4FF);       // A_B_ 9
        if (hasA && !hasB) return const Color(0xFF64FF8C);      // A_bb 3
        if (!hasA && hasB) return const Color(0xFFFF6B35);      // aaB_ 3
        return const Color(0xFF8844AA);                          // aabb 1
      }

      for (int r = 0; r < n; r++) {
        for (int c = 0; c < n; c++) {
          final g1 = gametes[r];
          final g2 = gametes[c];
          final geno = '${g1[0]}${g2[0]}${g1[1]}${g2[1]}';
          final cellRect = Rect.fromLTWH(
            gridLeft + headerSize + cellW * c,
            gridTop + headerSize + cellH * r,
            cellW, cellH,
          );
          final pc = phenoColor(r, c);
          canvas.drawRect(cellRect, Paint()..color = pc.withValues(alpha: 0.18));
          canvas.drawRect(cellRect, Paint()..color = gridColor..style = PaintingStyle.stroke..strokeWidth = 0.6);
          _drawText(canvas, geno, cellRect.center, fontSize: 7, color: pc);
        }
      }

      // 9:3:3:1 ratio right side
      final ratioX = gridLeft + headerSize + cellW * n + 6;
      final ratioData = [
        ('A_B_', '9', const Color(0xFF00D4FF)),
        ('A_bb', '3', const Color(0xFF64FF8C)),
        ('aaB_', '3', const Color(0xFFFF6B35)),
        ('aabb', '1', const Color(0xFF8844AA)),
      ];
      _drawText(canvas, '9:3:3:1', Offset(ratioX + 22, gridTop + headerSize - 8), fontSize: 10, color: mutedColor);
      for (int i = 0; i < 4; i++) {
        final ry = gridTop + headerSize + 14.0 + i * 24;
        canvas.drawRect(Rect.fromLTWH(ratioX, ry - 7, 12, 14),
            Paint()..color = ratioData[i].$3.withValues(alpha: 0.4));
        _drawText(canvas, ratioData[i].$1, Offset(ratioX + 26, ry), fontSize: 8, color: ratioData[i].$3);
        _drawText(canvas, ratioData[i].$2, Offset(ratioX + 42, ry), fontSize: 10, color: inkColor);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PunnettSquareScreenPainter oldDelegate) => true;
}
