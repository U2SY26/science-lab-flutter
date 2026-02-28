import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ActivationEnergyScreen extends StatefulWidget {
  const ActivationEnergyScreen({super.key});
  @override
  State<ActivationEnergyScreen> createState() => _ActivationEnergyScreenState();
}

class _ActivationEnergyScreenState extends State<ActivationEnergyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _activationE = 75;
  double _catalystEffect = 30;
  double _rateConst = 0, _catalyzedEa = 0;

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
      _catalyzedEa = _activationE * (1 - _catalystEffect / 100);
      _rateConst = math.exp(-_activationE * 1000 / (8.314 * 298));
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _activationE = 75; _catalystEffect = 30;
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
          const Text('활성화 에너지와 촉매', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '활성화 에너지와 촉매',
          formula: 'k = Ae^{-Ea/RT}',
          formulaDescription: '촉매가 활성화 에너지를 낮추는 방법을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ActivationEnergyScreenPainter(
                time: _time,
                activationE: _activationE,
                catalystEffect: _catalystEffect,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '활성화 에너지 (kJ/mol)',
                value: _activationE,
                min: 10,
                max: 200,
                step: 5,
                defaultValue: 75,
                formatValue: (v) => '${v.toStringAsFixed(0)} kJ/mol',
                onChanged: (v) => setState(() => _activationE = v),
              ),
              advancedControls: [
            SimSlider(
                label: '촉매 효과 (%)',
                value: _catalystEffect,
                min: 0,
                max: 80,
                step: 5,
                defaultValue: 30,
                formatValue: (v) => '${v.toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _catalystEffect = v),
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
          _V('촉매 후 Ea', '${_catalyzedEa.toStringAsFixed(0)} kJ/mol'),
          _V('속도 상수', _rateConst.toStringAsExponential(2)),
          _V('감소율', '${_catalystEffect.toStringAsFixed(0)}%'),
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

class _ActivationEnergyScreenPainter extends CustomPainter {
  final double time;
  final double activationE;
  final double catalystEffect;

  _ActivationEnergyScreenPainter({
    required this.time,
    required this.activationE,
    required this.catalystEffect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;

    // Layout: energy profile (left 55%) | Arrhenius plot (right 45%)
    final profW = w * 0.54;
    final plotX = profW + 8;
    final plotW = w - plotX - 6;

    final catalyzedEa = activationE * (1 - catalystEffect / 100);

    // ── Energy Profile ────────────────────────────────────────────────────
    final left = 32.0, right = profW - 8;
    final top = 22.0, bottom = h - 32.0;
    final pH = bottom - top;
    final pW = right - left;

    // Energy levels (normalised)
    const reactantE = 0.15;  // reactants at 15% height
    const productE  = 0.05;  // products at 5% height
    final eaFrac    = (activationE / 200.0).clamp(0.1, 0.92);
    final eaCatFrac = (catalyzedEa / 200.0).clamp(0.05, eaFrac - 0.04);

    // Convert energy fraction → y coordinate (higher E = lower y)
    double eY(double frac) => bottom - frac * pH;

    // Faint grid
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.4;
    for (int gi = 1; gi <= 4; gi++) {
      canvas.drawLine(Offset(left, top + pH * gi / 4), Offset(right, top + pH * gi / 4), gridP);
    }

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0;
    canvas.drawLine(Offset(left, top), Offset(left, bottom), axisPaint);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), axisPaint);

    void profLabel(String t, double x, double y, Color c, {double fs = 8}) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: TextStyle(color: c, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
    profLabel('에너지 프로파일', left + pW / 2, top - 8, const Color(0xFF5A8A9A), fs: 9);
    profLabel('에너지', left - 14, top + pH / 2, const Color(0xFF5A8A9A));
    profLabel('반응 좌표 →', left + pW / 2, bottom + 14, const Color(0xFF5A8A9A));

    // Build smooth energy profile via cubic bezier approximation with polyline
    Path buildProfile(double eaF, Color color, {bool dashed = false}) {
      final path = Path();
      // Reactant plateau: 0..0.2
      // Rise to peak: 0.2..0.5
      // Fall to product: 0.5..0.8
      // Product plateau: 0.8..1.0
      const steps = 200;
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        double e;
        if (t < 0.2) {
          e = reactantE;
        } else if (t < 0.5) {
          final s = (t - 0.2) / 0.3;
          // smooth bell rise using sine
          e = reactantE + (eaF - reactantE) * math.sin(s * math.pi / 2);
        } else if (t < 0.8) {
          final s = (t - 0.5) / 0.3;
          e = eaF - (eaF - productE) * math.sin(s * math.pi / 2);
        } else {
          e = productE;
        }
        final px = left + t * pW;
        final py = eY(e);
        if (i == 0) { path.moveTo(px, py); } else { path.lineTo(px, py); }
      }
      return path;
    }

    // Uncatalysed profile (cyan)
    final uncatPath = buildProfile(eaFrac, const Color(0xFF00D4FF));
    canvas.drawPath(uncatPath,
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2.0..style = PaintingStyle.stroke);

    // Catalysed profile (orange, lower peak)
    if (catalystEffect > 0) {
      final catPath = buildProfile(eaCatFrac, const Color(0xFFFF6B35));
      canvas.drawPath(catPath,
          Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.8
            ..style = PaintingStyle.stroke);
    }

    // Reactant & product horizontal markers
    canvas.drawLine(Offset(left, eY(reactantE)), Offset(left + pW * 0.22, eY(reactantE)),
        Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.6)..strokeWidth = 1.0);
    canvas.drawLine(Offset(left + pW * 0.78, eY(productE)), Offset(right, eY(productE)),
        Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.6)..strokeWidth = 1.0);

    // Ea arrows
    final peakX = left + pW * 0.5;
    final arrowPaint = Paint()..strokeWidth = 1.0..style = PaintingStyle.stroke;
    // Uncatalysed Ea arrow
    canvas.drawLine(Offset(peakX + 8, eY(reactantE)), Offset(peakX + 8, eY(eaFrac)),
        arrowPaint..color = const Color(0xFF00D4FF).withValues(alpha: 0.7));
    profLabel('Ea=${activationE.toStringAsFixed(0)}', peakX + 22, (eY(reactantE) + eY(eaFrac)) / 2,
        const Color(0xFF00D4FF), fs: 7);

    // Catalysed Ea arrow
    if (catalystEffect > 0) {
      canvas.drawLine(Offset(peakX - 16, eY(reactantE)), Offset(peakX - 16, eY(eaCatFrac)),
          arrowPaint..color = const Color(0xFFFF6B35).withValues(alpha: 0.7));
      profLabel('Ea\'=${catalyzedEa.toStringAsFixed(0)}', peakX - 34,
          (eY(reactantE) + eY(eaCatFrac)) / 2, const Color(0xFFFF6B35), fs: 7);
    }

    // Animated particle traversing the profile
    final particleT = ((time * 0.18) % 1.0);
    double particleE;
    if (particleT < 0.2) {
      particleE = reactantE;
    } else if (particleT < 0.5) {
      final s = (particleT - 0.2) / 0.3;
      particleE = reactantE + (eaFrac - reactantE) * math.sin(s * math.pi / 2);
    } else if (particleT < 0.8) {
      final s = (particleT - 0.5) / 0.3;
      particleE = eaFrac - (eaFrac - productE) * math.sin(s * math.pi / 2);
    } else {
      particleE = productE;
    }
    final pPx = left + particleT * pW;
    final pPy = eY(particleE);
    canvas.drawCircle(Offset(pPx, pPy), 5,
        Paint()..color = const Color(0xFF64FF8C)..style = PaintingStyle.fill);

    // Legend
    profLabel('─ 비촉매', left + 4, top + 2, const Color(0xFF00D4FF), fs: 7.5);
    if (catalystEffect > 0) {
      profLabel('─ 촉매', left + 4, top + 12, const Color(0xFFFF6B35), fs: 7.5);
    }

    // ── Arrhenius Plot: ln(k) vs 1/T ─────────────────────────────────────
    final gLeft = plotX, gRight = plotX + plotW - 4;
    final gTop = 22.0, gBottom = h - 32.0;
    final gH = gBottom - gTop;
    final gW = gRight - gLeft;

    canvas.drawLine(Offset(gLeft, gTop), Offset(gLeft, gBottom), axisPaint);
    canvas.drawLine(Offset(gLeft, gBottom), Offset(gRight, gBottom), axisPaint);

    // Faint grid
    for (int gi = 1; gi <= 3; gi++) {
      canvas.drawLine(Offset(gLeft, gTop + gH * gi / 3), Offset(gRight, gTop + gH * gi / 3), gridP);
      canvas.drawLine(Offset(gLeft + gW * gi / 3, gTop), Offset(gLeft + gW * gi / 3, gBottom), gridP);
    }

    void gLabel(String t, double x, double y, Color c, {double fs = 7.5}) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: TextStyle(color: c, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
    gLabel('아레니우스 플롯', gLeft + gW / 2, gTop - 8, const Color(0xFF5A8A9A), fs: 8);
    gLabel('1/T (K⁻¹)', gLeft + gW / 2, gBottom + 14, const Color(0xFF5A8A9A));
    gLabel('ln(k)', gLeft - 10, gTop + gH / 2, const Color(0xFF5A8A9A));

    // Temperature range: 200K..600K → 1/T: 0.00167..0.005
    const tMin = 200.0, tMax = 600.0;
    final invTMin = 1 / tMax; // smaller value = right side
    final invTMax = 1 / tMin; // larger value = left side
    final R = 8.314;
    final eaJ = activationE * 1000; // J/mol

    // ln(k) = ln(A) - Ea/(R*T); use ln(A)=15 as baseline
    const lnA = 15.0;
    double lnK(double temp) => lnA - eaJ / (R * temp);

    final lnKatTMin = lnK(tMin);
    final lnKatTMax = lnK(tMax);

    // Map to canvas coords
    Offset arrhCoord(double temp) {
      final invT = 1.0 / temp;
      final xFrac = (invT - invTMin) / (invTMax - invTMin);
      final yFrac = (lnK(temp) - lnKatTMax) / (lnKatTMin - lnKatTMax);
      return Offset(gLeft + (1 - xFrac) * gW, gTop + yFrac.clamp(0.0, 1.0) * gH);
    }

    // Uncatalysed line (cyan)
    final aPath = Path()..moveTo(arrhCoord(tMax).dx, arrhCoord(tMax).dy);
    for (double temp = tMax; temp >= tMin; temp -= 5) {
      final pt = arrhCoord(temp);
      aPath.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(aPath,
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.8..style = PaintingStyle.stroke);

    // Catalysed line (orange, lower Ea = shallower slope)
    if (catalystEffect > 0) {
      final eaCatJ = catalyzedEa * 1000;
      double lnKcat(double temp) => lnA - eaCatJ / (R * temp);
      final lnKcatMin = lnKcat(tMin);
      final lnKcatMax = lnKcat(tMax);

      Offset catCoord(double temp) {
        final invT = 1.0 / temp;
        final xFrac = (invT - invTMin) / (invTMax - invTMin);
        final yFrac = (lnKcat(temp) - lnKcatMax) / (lnKcatMin - lnKcatMax);
        return Offset(gLeft + (1 - xFrac) * gW, gTop + yFrac.clamp(0.0, 1.0) * gH);
      }

      final catPath = Path()..moveTo(catCoord(tMax).dx, catCoord(tMax).dy);
      for (double temp = tMax; temp >= tMin; temp -= 5) {
        final pt = catCoord(temp);
        catPath.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(catPath,
          Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.8..style = PaintingStyle.stroke);
    }

    // Slope annotation: slope = -Ea/R
    gLabel('기울기 = -Ea/R', gLeft + gW * 0.55, gTop + gH * 0.2,
        const Color(0xFF00D4FF), fs: 7);

    // Axis tick labels
    gLabel('1/600', gRight, gBottom + 10, const Color(0xFF5A8A9A), fs: 6.5);
    gLabel('1/200', gLeft, gBottom + 10, const Color(0xFF5A8A9A), fs: 6.5);

    // Current T marker (T=298K)
    final markerPt = arrhCoord(298);
    canvas.drawCircle(markerPt, 5,
        Paint()..color = const Color(0xFF64FF8C)..style = PaintingStyle.fill);
    gLabel('298K', markerPt.dx, markerPt.dy - 10, const Color(0xFF64FF8C), fs: 7);

    // Legend
    gLabel('─ 비촉매', gLeft + 2, gTop + 2, const Color(0xFF00D4FF), fs: 7);
    if (catalystEffect > 0) {
      gLabel('─ 촉매', gLeft + 2, gTop + 11, const Color(0xFFFF6B35), fs: 7);
    }
  }

  @override
  bool shouldRepaint(covariant _ActivationEnergyScreenPainter oldDelegate) => true;
}
