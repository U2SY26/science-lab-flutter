import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BandStructureScreen extends StatefulWidget {
  const BandStructureScreen({super.key});
  @override
  State<BandStructureScreen> createState() => _BandStructureScreenState();
}

class _BandStructureScreenState extends State<BandStructureScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _bandGap = 1.1;
  
  String _material = "반도체";

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
      _material = _bandGap < 0.01 ? "도체" : _bandGap < 3.5 ? "반도체" : "부도체";
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _bandGap = 1.1;
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
          Text('양자역학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('에너지 띠 구조', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '에너지 띠 구조',
          formula: 'E(k) = ħ²k²/2m*',
          formulaDescription: '고체의 에너지 띠 구조와 밴드갭을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BandStructureScreenPainter(
                time: _time,
                bandGap: _bandGap,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '밴드갭 (eV)',
                value: _bandGap,
                min: 0,
                max: 5,
                step: 0.1,
                defaultValue: 1.1,
                formatValue: (v) => v.toStringAsFixed(1) + ' eV',
                onChanged: (v) => setState(() => _bandGap = v),
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
          _V('E_g', _bandGap.toStringAsFixed(1) + ' eV'),
          _V('유형', _material),
          _V('λ', (_bandGap > 0 ? (1240 / _bandGap).toStringAsFixed(0) + ' nm' : '∞')),
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

class _BandStructureScreenPainter extends CustomPainter {
  final double time;
  final double bandGap;

  _BandStructureScreenPainter({
    required this.time,
    required this.bandGap,
  });

  void _label(Canvas canvas, String text, Offset offset,
      {double fontSize = 9, Color color = const Color(0xFF5A8A9A)}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Layout: left 45% = atomic levels evolution, right 55% = E-k dispersion
    final splitX = w * 0.42;

    // ---- LEFT: Atom → Solid energy level broadening ----
    final leftPad = 12.0;
    final leftW = splitX - leftPad * 2;
    final topY = h * 0.12;
    final botY = h * 0.88;
    final midY = (topY + botY) / 2;

    // Define 4 stages: 1 atom, 2 atoms, 4 atoms, solid band
    final stages = 4;
    final stageW = leftW / stages;

    // Conduction band top y, valence band bottom y
    final cbTop = topY + (botY - topY) * 0.05;
    final cbBot = topY + (botY - topY) * 0.35;
    final vbTop = topY + (botY - topY) * 0.65;
    final vbBot = topY + (botY - topY) * 0.95;

    // Band gap fraction in the energy axis
    final gapFrac = (bandGap / 6.0).clamp(0.0, 0.25);

    for (int s = 0; s < stages; s++) {
      final stX = leftPad + s * stageW;
      final cx = stX + stageW * 0.5;

      if (s < 3) {
        // Discrete levels for atoms
        final nLevels = [1, 2, 4][s];
        final spread = stageW * (0.08 + s * 0.1);
        // Conduction band levels
        for (int i = 0; i < nLevels; i++) {
          final y = cbBot - (cbBot - cbTop) * (i + 0.5) / nLevels;
          final lx = cx - spread / 2;
          final rx = cx + spread / 2;
          canvas.drawLine(Offset(lx, y), Offset(rx, y),
              Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)..strokeWidth = 1.2);
        }
        // Valence band levels
        for (int i = 0; i < nLevels; i++) {
          final y = vbTop + (vbBot - vbTop) * (i + 0.5) / nLevels;
          final lx = cx - spread / 2;
          final rx = cx + spread / 2;
          canvas.drawLine(Offset(lx, y), Offset(rx, y),
              Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.7)..strokeWidth = 1.2);
        }
        final stageLabels = ['1원자', '2원자', '4원자'];
        _label(canvas, stageLabels[s], Offset(cx - 12, botY + 4),
            color: const Color(0xFF5A8A9A), fontSize: 8);
      } else {
        // Solid: filled bands
        // Valence band (filled, green)
        final vbRect = Rect.fromLTRB(stX + 4, vbTop, stX + stageW - 4, vbBot);
        canvas.drawRect(vbRect,
            Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.25));
        canvas.drawRect(vbRect,
            Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1);

        // Band gap region
        final gapTop = vbTop - gapFrac * (botY - topY);
        if (bandGap > 0.05) {
          final gapRect = Rect.fromLTRB(stX + 4, gapTop, stX + stageW - 4, vbTop);
          canvas.drawRect(gapRect,
              Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.7));
          _label(canvas, 'Eg\n${bandGap.toStringAsFixed(1)}eV',
              Offset(stX + 6, gapTop + (vbTop - gapTop) / 2 - 8),
              color: const Color(0xFFFF6B35), fontSize: 7);
        }

        // Conduction band
        final cbActualBot = gapTop;
        final cbActualTop = cbTop;
        final cbRect = Rect.fromLTRB(stX + 4, cbActualTop, stX + stageW - 4, cbActualBot);
        canvas.drawRect(cbRect,
            Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.15));
        canvas.drawRect(cbRect,
            Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 1);

        _label(canvas, '고체', Offset(cx - 8, botY + 4), color: const Color(0xFF5A8A9A), fontSize: 8);
        _label(canvas, '전도대', Offset(stX + 5, cbActualTop + 2), color: const Color(0xFF00D4FF), fontSize: 7);
        _label(canvas, '가전자대', Offset(stX + 5, vbTop + 2), color: const Color(0xFF64FF8C), fontSize: 7);

        // Fermi level dashed line
        if (bandGap < 0.05) {
          // Metal: fermi in middle of band
          canvas.drawLine(Offset(stX + 4, midY), Offset(stX + stageW - 4, midY),
              Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)..strokeWidth = 1.2
                ..shader = null);
          _label(canvas, 'E_F', Offset(stX + stageW - 18, midY - 10),
              color: const Color(0xFFFF6B35), fontSize: 7);
        } else {
          // Semiconductor/insulator: Fermi in gap
          final fY = gapTop + (vbTop - gapTop) / 2;
          final dashLen = 4.0;
          for (double dx = stX + 4; dx < stX + stageW - 4; dx += dashLen * 2) {
            canvas.drawLine(Offset(dx, fY), Offset(dx + dashLen, fY),
                Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)..strokeWidth = 1);
          }
          _label(canvas, 'E_F', Offset(stX + stageW - 18, fY - 10),
              color: const Color(0xFFFF6B35), fontSize: 7);
        }
      }
    }

    // Divider
    canvas.drawLine(Offset(splitX, 0), Offset(splitX, h),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    // ---- RIGHT: E-k dispersion ----
    final rPad = 12.0;
    final rLeft = splitX + rPad;
    final rRight = w - rPad;
    final rW = rRight - rLeft;
    final rTop = h * 0.10;
    final rBot = h * 0.90;
    final rH = rBot - rTop;

    // k axis: -π/a to +π/a (Brillouin zone)
    // E axis: 0 to Emax
    final eMax = bandGap + 3.0; // eV above valence band
    double eToY(double e) => rBot - e / eMax * rH;
    double kToX(double kFrac) => rLeft + (kFrac + 1) / 2 * rW; // kFrac: -1..+1

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1;
    canvas.drawLine(Offset(rLeft, rBot), Offset(rRight, rBot), axisPaint);
    canvas.drawLine(Offset(kToX(0), rTop), Offset(kToX(0), rBot), axisPaint);

    _label(canvas, 'k', Offset(rRight - 8, rBot + 2), color: const Color(0xFF5A8A9A));
    _label(canvas, 'E', Offset(rLeft - 12, rTop), color: const Color(0xFF5A8A9A));
    _label(canvas, '-π/a', Offset(rLeft - 8, rBot + 2), color: const Color(0xFF5A8A9A), fontSize: 8);
    _label(canvas, '+π/a', Offset(rRight - 14, rBot + 2), color: const Color(0xFF5A8A9A), fontSize: 8);

    // Valence band: E_v(k) = Ev_top - Δv*(k/π)²  (parabolic, top at k=0)
    final evTop = (eMax * 0.45).clamp(0.0, eMax);
    final evBot = (eMax * 0.08).clamp(0.0, eMax);

    final vbPath = Path();
    bool vbFirst = true;
    for (int i = 0; i <= 100; i++) {
      final kFrac = -1.0 + i * 2.0 / 100;
      final e = evTop - (evTop - evBot) * kFrac * kFrac;
      final x = kToX(kFrac);
      final y = eToY(e);
      if (vbFirst) {
        vbPath.moveTo(x, y);
        vbFirst = false;
      } else {
        vbPath.lineTo(x, y);
      }
    }
    canvas.drawPath(vbPath, Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 2..style = PaintingStyle.stroke);

    // Fill valence band (below curve to axis)
    final vbFill = Path();
    vbFill.moveTo(rLeft, rBot);
    for (int i = 0; i <= 100; i++) {
      final kFrac = -1.0 + i * 2.0 / 100;
      final e = evTop - (evTop - evBot) * kFrac * kFrac;
      vbFill.lineTo(kToX(kFrac), eToY(e));
    }
    vbFill.lineTo(rRight, rBot);
    vbFill.close();
    canvas.drawPath(vbFill, Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.15));

    // Band gap region
    final gapBotE = evTop;
    final gapTopE = gapBotE + bandGap;
    if (bandGap > 0.05) {
      final gapRect = Rect.fromLTRB(rLeft, eToY(gapTopE), rRight, eToY(gapBotE));
      canvas.drawRect(gapRect, Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.5));
      // Gap label
      _label(canvas, 'Eg=${bandGap.toStringAsFixed(1)}eV',
          Offset(kToX(0.0) + 4, eToY(gapBotE + bandGap / 2) - 4),
          color: const Color(0xFFFF6B35), fontSize: 8);
    }

    // Conduction band: E_c(k) = Ec_bot + Δc*(k/π)²
    final ecBot = gapTopE;
    final ecTop = ecBot + eMax * 0.35;

    final cbPath = Path();
    bool cbFirst = true;
    for (int i = 0; i <= 100; i++) {
      final kFrac = -1.0 + i * 2.0 / 100;
      final e = ecBot + (ecTop - ecBot) * kFrac * kFrac;
      if (e > eMax) continue;
      final x = kToX(kFrac);
      final y = eToY(e);
      if (cbFirst) {
        cbPath.moveTo(x, y);
        cbFirst = false;
      } else {
        cbPath.lineTo(x, y);
      }
    }
    canvas.drawPath(cbPath, Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2..style = PaintingStyle.stroke);

    // Fermi level (dashed)
    double fermiE;
    if (bandGap < 0.05) {
      fermiE = evTop * 0.85; // metal: in valence band
    } else {
      fermiE = gapBotE + bandGap / 2; // in gap
    }
    if (fermiE < eMax) {
      final fy = eToY(fermiE);
      for (double dx = rLeft; dx < rRight; dx += 8) {
        canvas.drawLine(Offset(dx, fy), Offset(dx + 4, fy),
            Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.8)..strokeWidth = 1);
      }
      _label(canvas, 'E_F', Offset(rRight - 20, fy - 11),
          color: const Color(0xFFFF6B35), fontSize: 8);
    }

    // Band labels
    _label(canvas, '전도대', Offset(rLeft + 2, eToY(ecBot + (ecTop - ecBot) * 0.25)),
        color: const Color(0xFF00D4FF), fontSize: 8);
    _label(canvas, '가전자대', Offset(rLeft + 2, eToY(evTop * 0.6)),
        color: const Color(0xFF64FF8C), fontSize: 8);

    // Material type
    final matType = bandGap < 0.05 ? '도체' : bandGap < 3.5 ? '반도체' : '부도체';
    final matColor = bandGap < 0.05
        ? const Color(0xFF64FF8C)
        : bandGap < 3.5
            ? const Color(0xFF00D4FF)
            : const Color(0xFFFF6B35);
    _label(canvas, matType, Offset(rLeft + rW / 2 - 10, rTop),
        color: matColor, fontSize: 11);
  }

  @override
  bool shouldRepaint(covariant _BandStructureScreenPainter oldDelegate) => true;
}
