import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ColligativePropertiesScreen extends StatefulWidget {
  const ColligativePropertiesScreen({super.key});
  @override
  State<ColligativePropertiesScreen> createState() => _ColligativePropertiesScreenState();
}

class _ColligativePropertiesScreenState extends State<ColligativePropertiesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _molality = 1.0;
  double _vantHoff = 1.0;
  double _deltaTb = 0, _deltaTf = 0;

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
      _deltaTb = 0.512 * _molality * _vantHoff;
      _deltaTf = 1.86 * _molality * _vantHoff;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _molality = 1.0;
      _vantHoff = 1.0;
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
          const Text('총괄성', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '총괄성',
          formula: 'ΔT = K·m·i',
          formulaDescription: '끓는점 오름과 어는점 내림 효과를 관찰합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ColligativePropertiesScreenPainter(
                time: _time,
                molality: _molality,
                vantHoff: _vantHoff,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '몰랄 농도 (m)',
                value: _molality,
                min: 0.1,
                max: 5.0,
                step: 0.1,
                defaultValue: 1.0,
                formatValue: (v) => '${v.toStringAsFixed(1)} m',
                onChanged: (v) => setState(() => _molality = v),
              ),
              advancedControls: [
            SimSlider(
                label: '반트호프 인자 (i)',
                value: _vantHoff,
                min: 1.0,
                max: 3.0,
                defaultValue: 1.0,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => _vantHoff = v),
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
          _V('ΔTb', '${_deltaTb.toStringAsFixed(2)} °C'),
          _V('ΔTf', '${_deltaTf.toStringAsFixed(2)} °C'),
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

class _ColligativePropertiesScreenPainter extends CustomPainter {
  final double time;
  final double molality;
  final double vantHoff;

  _ColligativePropertiesScreenPainter({
    required this.time,
    required this.molality,
    required this.vantHoff,
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
    final m = molality.clamp(0.1, 5.0);
    final i = vantHoff.clamp(1.0, 3.0);

    final deltaTb = 0.512 * m * i;  // boiling point elevation (water Kb=0.512)
    final deltaTf = 1.86 * m * i;   // freezing point depression (water Kf=1.86)
    final osmosis = i * m * 0.0831 * 298; // Π = iMRT (bar, M≈m for dilute)
    final xSolute = (m / (m + 55.5)).clamp(0.0, 1.0); // mole fraction solute
    final pStar = 23.8; // mmHg at 25°C
    final deltaP = xSolute * pStar;

    _lbl(canvas, '총괄성 (Colligative Properties)', Offset(w / 2, 12),
        const Color(0xFF00D4FF), 11, fw: FontWeight.bold);

    // Layout: 2x2 grid of panels
    final padL = 6.0, padT = 24.0, padR = 6.0;
    final panW = (w - padL - padR - 8) / 2;
    final panH = (h - padT - 4) / 2 - 4;
    final positions = [
      Offset(padL, padT),
      Offset(padL + panW + 8, padT),
      Offset(padL, padT + panH + 8),
      Offset(padL + panW + 8, padT + panH + 8),
    ];
    final panTitles = ['끓는점 오름 ΔTb', '어는점 내림 ΔTf', '삼투압 Π', '증기압 내림 ΔP'];
    final panColors = [
      const Color(0xFFFF6B35),
      const Color(0xFF00D4FF),
      const Color(0xFF64FF8C),
      const Color(0xFFFFD700),
    ];
    final panValues = [deltaTb, deltaTf, osmosis, deltaP];
    final panMaxes = [5.0, 18.0, 40.0, 5.0];
    final panUnits = ['°C', '°C', 'bar', 'mmHg'];
    final panFormulas = [
      'Kb·m·i',
      'Kf·m·i',
      'iMRT',
      'xsolute·P*',
    ];

    for (int pi = 0; pi < 4; pi++) {
      final ox = positions[pi].dx;
      final oy = positions[pi].dy;
      final color = panColors[pi];
      final val = panValues[pi];
      final maxVal = panMaxes[pi];

      // Panel background
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(ox, oy, panW, panH), const Radius.circular(6)),
          Paint()..color = const Color(0xFF0A1520));
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(ox, oy, panW, panH), const Radius.circular(6)),
          Paint()..color = color.withValues(alpha: 0.3)..strokeWidth = 1..style = PaintingStyle.stroke);

      // Title
      _lbl(canvas, panTitles[pi], Offset(ox + panW / 2, oy + 9), color, 8, fw: FontWeight.bold);

      // Bar (vertical)
      final barL = ox + panW * 0.15;
      final barT2 = oy + 20;
      final barBotY = oy + panH - 24;
      final barH2 = barBotY - barT2;
      final barW4 = panW * 0.22;

      // Background bar
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(barL, barT2, barW4, barH2), const Radius.circular(3)),
          Paint()..color = const Color(0xFF1A3040));

      // Filled bar
      final fillRatio = (val / maxVal).clamp(0.0, 1.0);
      final fillH2 = fillRatio * barH2;
      if (fillH2 > 0) {
        // Animate slight pulse
        final pulse = 0.9 + 0.1 * math.sin(time * 2 + pi * 0.8);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(barL, barBotY - fillH2, barW4, fillH2),
                const Radius.circular(3)),
            Paint()..color = color.withValues(alpha: 0.8 * pulse));
      }

      // Arrow indicating direction
      final arrowX = barL + barW4 + 6;
      if (pi == 0 || pi == 2 || pi == 3) {
        // Up arrows (increase)
        canvas.drawLine(Offset(arrowX, barBotY), Offset(arrowX, barT2 + 4),
            Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke);
        canvas.drawLine(Offset(arrowX - 4, barT2 + 10), Offset(arrowX, barT2 + 4),
            Paint()..color = color..strokeWidth = 1.5);
        canvas.drawLine(Offset(arrowX + 4, barT2 + 10), Offset(arrowX, barT2 + 4),
            Paint()..color = color..strokeWidth = 1.5);
      } else {
        // Down arrow (freezing point decreases)
        canvas.drawLine(Offset(arrowX, barT2), Offset(arrowX, barBotY - 4),
            Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke);
        canvas.drawLine(Offset(arrowX - 4, barBotY - 10), Offset(arrowX, barBotY - 4),
            Paint()..color = color..strokeWidth = 1.5);
        canvas.drawLine(Offset(arrowX + 4, barBotY - 10), Offset(arrowX, barBotY - 4),
            Paint()..color = color..strokeWidth = 1.5);
      }

      // Molecule visualization (right half of panel)
      final molAreaL = ox + panW * 0.52;
      final molAreaT = oy + 18;
      final molAreaW = panW * 0.44;
      final molAreaH = panH - 30;
      final rng = math.Random(pi * 7 + 3);
      final numSolvent = 10;
      final numSolute = (m * 3).round().clamp(1, 12);

      // Solvent (blue circles)
      for (int si = 0; si < numSolvent; si++) {
        final seed = si * 2.1 + pi;
        final mx = molAreaL + 4 + ((rng.nextDouble() * (molAreaW - 8) +
                math.sin(time * 0.5 + seed) * (molAreaW * 0.06)).abs() % (molAreaW - 8));
        final my = molAreaT + 4 + ((rng.nextDouble() * (molAreaH - 8) +
                math.cos(time * 0.4 + seed * 1.3) * (molAreaH * 0.06)).abs() % (molAreaH - 8));
        canvas.drawCircle(Offset(mx, my), 3.5,
            Paint()..color = const Color(0xFF3A6080).withValues(alpha: 0.7));
      }
      // Solute (orange circles)
      for (int si = 0; si < numSolute; si++) {
        final seed = si * 3.3 + pi * 5;
        final mx = molAreaL + 4 + ((rng.nextDouble() * (molAreaW - 8) +
                math.sin(time * 0.6 + seed + 1) * (molAreaW * 0.07)).abs() % (molAreaW - 8));
        final my = molAreaT + 4 + ((rng.nextDouble() * (molAreaH - 8) +
                math.cos(time * 0.5 + seed * 1.1) * (molAreaH * 0.07)).abs() % (molAreaH - 8));
        canvas.drawCircle(Offset(mx, my), 4.0,
            Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.85));
      }

      // Value label
      _lbl(canvas, '${val.toStringAsFixed(2)} ${panUnits[pi]}',
          Offset(ox + panW / 2, oy + panH - 15), color, 9, fw: FontWeight.bold);
      _lbl(canvas, '= ${panFormulas[pi]}', Offset(ox + panW / 2, oy + panH - 6),
          const Color(0xFF5A8A9A), 7);
    }

    // Legend row
    _lbl(canvas, '● 용매  ● 용질  m=${m.toStringAsFixed(1)} mol/kg  i=${i.toInt()}',
        Offset(w / 2, h - 3),
        const Color(0xFF5A8A9A), 8);
  }

  @override
  bool shouldRepaint(covariant _ColligativePropertiesScreenPainter oldDelegate) => true;
}
