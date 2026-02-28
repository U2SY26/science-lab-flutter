import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DaltonLawScreen extends StatefulWidget {
  const DaltonLawScreen({super.key});
  @override
  State<DaltonLawScreen> createState() => _DaltonLawScreenState();
}

class _DaltonLawScreenState extends State<DaltonLawScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _n1 = 1.0;
  double _n2 = 0.5;
  double _n3 = 0.2;
  double _p1 = 0, _p2 = 0, _p3 = 0, _totalP = 0;

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
      final total = _n1 + _n2 + _n3;
      _p1 = _n1 / total; _p2 = _n2 / total; _p3 = _n3 / total;
      _totalP = total * 0.0821 * 300 / 24.0;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _n1 = 1.0;
      _n2 = 0.5;
      _n3 = 0.2;
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
          Text('화학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('달턴 분압 법칙', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '달턴 분압 법칙',
          formula: 'P_total = P₁ + P₂ + P₃',
          formulaDescription: '혼합 기체에서 각 기체의 분압이 전체 압력을 구성합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DaltonLawScreenPainter(
                time: _time,
                n1: _n1,
                n2: _n2,
                n3: _n3,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'N₂ (mol)',
                value: _n1,
                min: 0.1,
                max: 3.0,
                step: 0.1,
                defaultValue: 1.0,
                formatValue: (v) => '${v.toStringAsFixed(1)}',
                onChanged: (v) => setState(() => _n1 = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'O₂ (mol)',
                value: _n2,
                min: 0.1,
                max: 3.0,
                step: 0.1,
                defaultValue: 0.5,
                formatValue: (v) => '${v.toStringAsFixed(1)}',
                onChanged: (v) => setState(() => _n2 = v),
              ),
            SimSlider(
                label: 'CO₂ (mol)',
                value: _n3,
                min: 0.0,
                max: 2.0,
                step: 0.1,
                defaultValue: 0.2,
                formatValue: (v) => '${v.toStringAsFixed(1)}',
                onChanged: (v) => setState(() => _n3 = v),
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
          _V('P(N₂)', '${(_p1 * _totalP).toStringAsFixed(2)} atm'),
          _V('P(O₂)', '${(_p2 * _totalP).toStringAsFixed(2)} atm'),
          _V('P 전체', '${_totalP.toStringAsFixed(2)} atm'),
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

class _DaltonLawScreenPainter extends CustomPainter {
  final double time;
  final double n1;
  final double n2;
  final double n3;

  _DaltonLawScreenPainter({
    required this.time,
    required this.n1,
    required this.n2,
    required this.n3,
  });

  void _lbl(Canvas canvas, String text, Offset center, Color color, double sz,
      {FontWeight fw = FontWeight.normal}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: sz, fontFamily: 'monospace', fontWeight: fw)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    final total = n1 + n2 + n3;
    final x1 = n1 / total;
    final x2 = n2 / total;
    final x3 = n3 / total;
    final pTotal = total * 0.0821 * 300 / 24.0;
    final p1 = x1 * pTotal;
    final p2 = x2 * pTotal;
    final p3 = x3 * pTotal;

    _lbl(canvas, '달턴 분압 법칙  P_total = P₁ + P₂ + P₃', Offset(w / 2, 12),
        const Color(0xFF00D4FF), 11, fw: FontWeight.bold);

    final gasColors = [
      const Color(0xFF00D4FF),
      const Color(0xFF64FF8C),
      const Color(0xFFFF6B35),
    ];
    final gasNames = ['N₂', 'O₂', 'CO₂'];
    final gasN = [n1, n2, n3];
    final gasP = [p1, p2, p3];
    final gasX = [x1, x2, x3];

    // ===== LEFT: Mixed gas container (45% width) =====
    final boxL = 10.0, boxT = 24.0;
    final boxW = w * 0.42, boxH = h * 0.58;
    final boxB = boxT + boxH;

    canvas.drawRect(Rect.fromLTWH(boxL, boxT, boxW, boxH),
        Paint()..color = const Color(0xFF0A1520));
    canvas.drawRect(Rect.fromLTWH(boxL, boxT, boxW, boxH),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Molecules inside the box
    final rng = math.Random(13);
    final counts = [
      (n1 * 8).round().clamp(1, 14),
      (n2 * 8).round().clamp(1, 14),
      (n3 * 8).round().clamp(1, 14),
    ];
    int molIdx = 0;
    for (int gi = 0; gi < 3; gi++) {
      for (int mi = 0; mi < counts[gi]; mi++) {
        final seed = molIdx * 1.91 + gi * 3.7;
        molIdx++;
        final mx = boxL + 8 + ((rng.nextDouble() * (boxW - 16) +
                math.sin(time * 0.7 + seed) * (boxW * 0.12)).abs() % (boxW - 16));
        final my = boxT + 8 + ((rng.nextDouble() * (boxH - 16) +
                math.cos(time * 0.6 + seed * 1.3) * (boxH * 0.12)).abs() % (boxH - 16));
        canvas.drawCircle(Offset(mx, my), 5.5,
            Paint()..color = gasColors[gi].withValues(alpha: 0.75));
        _lbl(canvas, gasNames[gi], Offset(mx, my), const Color(0xFF0D1A20), 5);
      }
    }

    // Box label
    _lbl(canvas, 'P_total=${pTotal.toStringAsFixed(2)} atm', Offset(boxL + boxW / 2, boxB + 10),
        const Color(0xFFE0F4FF), 9);

    // ===== RIGHT: Partial pressure bar chart =====
    final chartL = w * 0.48, chartT = 28.0, chartR = w - 8.0;
    final chartW2 = chartR - chartL;
    final chartBot = h * 0.68;
    final chartH = chartBot - chartT - 18;

    _lbl(canvas, '분압 (atm)', Offset(chartL + chartW2 / 2, chartT + 5),
        const Color(0xFFE0F4FF), 9);

    final axisP2 = Paint()..color = const Color(0xFF2A4050)..strokeWidth = 1..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(chartL, chartT + 14), Offset(chartL, chartBot), axisP2);
    canvas.drawLine(Offset(chartL, chartBot), Offset(chartR, chartBot), axisP2);

    final maxP = pTotal.clamp(0.1, 10.0);
    final barGap = 8.0;
    final barW3 = (chartW2 - barGap * 4) / 3;

    for (int gi = 0; gi < 3; gi++) {
      final bx = chartL + barGap + gi * (barW3 + barGap);
      final bH2 = (gasP[gi] / maxP) * (chartH - 4);
      final by = chartBot - bH2;

      // Animated fill
      final pulse = (math.sin(time * 2 + gi * 1.2) * 0.1 + 0.9);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, barW3, bH2), const Radius.circular(3)),
          Paint()..color = gasColors[gi].withValues(alpha: 0.8 * pulse));
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, barW3, bH2), const Radius.circular(3)),
          Paint()..color = gasColors[gi]..strokeWidth = 1..style = PaintingStyle.stroke);

      _lbl(canvas, gasNames[gi], Offset(bx + barW3 / 2, chartBot + 8),
          gasColors[gi], 9, fw: FontWeight.bold);
      _lbl(canvas, '${gasP[gi].toStringAsFixed(2)}', Offset(bx + barW3 / 2, by - 7),
          gasColors[gi], 8);
    }

    // Total bar (stacked visualization)
    final totalBarX = chartR - barW3 - barGap;
    double stackY = chartBot;
    for (int gi = 0; gi < 3; gi++) {
      final segH = (gasP[gi] / maxP) * (chartH - 4);
      stackY -= segH;
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(totalBarX, stackY, barW3, segH), const Radius.circular(2)),
          Paint()..color = gasColors[gi].withValues(alpha: 0.65));
    }
    canvas.drawRect(Rect.fromLTWH(totalBarX, stackY, barW3, chartBot - stackY),
        Paint()..color = const Color(0xFFE0F4FF)..strokeWidth = 1..style = PaintingStyle.stroke);
    _lbl(canvas, 'Total', Offset(totalBarX + barW3 / 2, chartBot + 8),
        const Color(0xFFE0F4FF), 8);
    _lbl(canvas, '${pTotal.toStringAsFixed(2)}', Offset(totalBarX + barW3 / 2, stackY - 7),
        const Color(0xFFE0F4FF), 8);

    // ===== BOTTOM: Mole fraction table =====
    final tableTop = chartBot + 22;
    _lbl(canvas, '몰 분율  xᵢ = nᵢ / n_total', Offset(w * 0.7, tableTop + 6),
        const Color(0xFF5A8A9A), 9);

    final tableL = w * 0.46;
    final colW = (w - tableL - 8) / 4;
    final headers = ['기체', 'n (mol)', 'xᵢ', 'Pᵢ (atm)'];
    for (int ci = 0; ci < 4; ci++) {
      _lbl(canvas, headers[ci], Offset(tableL + (ci + 0.5) * colW, tableTop + 18),
          const Color(0xFF5A8A9A), 8, fw: FontWeight.bold);
    }
    for (int gi = 0; gi < 3; gi++) {
      final rowY = tableTop + 30 + gi * 14.0;
      final rowData = [
        gasNames[gi],
        gasN[gi].toStringAsFixed(1),
        gasX[gi].toStringAsFixed(3),
        gasP[gi].toStringAsFixed(3),
      ];
      for (int ci = 0; ci < 4; ci++) {
        final cx2 = tableL + (ci + 0.5) * colW;
        final col = ci == 0 ? gasColors[gi] : const Color(0xFFE0F4FF);
        _lbl(canvas, rowData[ci], Offset(cx2, rowY), col, 8);
      }
    }

    // Divider
    canvas.drawLine(Offset(w * 0.44, 24), Offset(w * 0.44, h - 6),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _DaltonLawScreenPainter oldDelegate) => true;
}
