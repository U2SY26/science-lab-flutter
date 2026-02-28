import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class NuclearFissionFusionScreen extends StatefulWidget {
  const NuclearFissionFusionScreen({super.key});
  @override
  State<NuclearFissionFusionScreen> createState() => _NuclearFissionFusionScreenState();
}

class _NuclearFissionFusionScreenState extends State<NuclearFissionFusionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _massNumber = 56;
  
  double _bindingE = 8.8; String _process = "안정";

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
      final a = _massNumber;
      _bindingE = 15.67 - 17.23 * math.pow(a, -1/3).toDouble() - 0.714 * (a/2) * ((a/2) - 1) / a;
      _bindingE = _bindingE.clamp(0, 9);
      _process = a > 56 ? "분열 유리" : a < 56 ? "융합 유리" : "안정";
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _massNumber = 56.0;
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
          const Text('핵분열과 핵융합', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '핵분열과 핵융합',
          formula: 'E = Δmc²',
          formulaDescription: '핵분열과 핵융합의 에너지 방출을 비교합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _NuclearFissionFusionScreenPainter(
                time: _time,
                massNumber: _massNumber,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '질량수 (A)',
                value: _massNumber,
                min: 2,
                max: 240,
                step: 1,
                defaultValue: 56,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _massNumber = v),
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
          _V('BE/A', _bindingE.toStringAsFixed(2) + ' MeV'),
          _V('과정', _process),
          _V('A', _massNumber.toInt().toString()),
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

class _NuclearFissionFusionScreenPainter extends CustomPainter {
  final double time;
  final double massNumber;

  _NuclearFissionFusionScreenPainter({
    required this.time,
    required this.massNumber,
  });

  void _label(Canvas canvas, String text, Offset pos, Color color,
      {double fontSize = 10, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color, {double width = 1.5}) {
    final paint = Paint()..color = color..strokeWidth = width..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, paint);
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final angle = math.atan2(dy, dx);
    const arrowSize = 7.0;
    canvas.drawLine(
      to,
      Offset(to.dx - arrowSize * math.cos(angle - 0.45), to.dy - arrowSize * math.sin(angle - 0.45)),
      paint,
    );
    canvas.drawLine(
      to,
      Offset(to.dx - arrowSize * math.cos(angle + 0.45), to.dy - arrowSize * math.sin(angle + 0.45)),
      paint,
    );
  }

  // Bethe-Weizsäcker semi-empirical binding energy per nucleon (MeV)
  double _bindingEnergyPerNucleon(double a) {
    if (a < 2) return 0;
    final z = a / 2.0; // approximate Z = A/2
    final av = 15.67;
    final as_ = 17.23;
    final ac = 0.714;
    final aa = 23.29;
    final be = av * a - as_ * math.pow(a, 2 / 3) - ac * z * (z - 1) / math.pow(a, 1 / 3) - aa * (a - 2 * z) * (a - 2 * z) / a;
    return (be / a).clamp(0.0, 9.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    const padL = 46.0, padR = 12.0, padT = 28.0, padB = 50.0;
    final plotW = w - padL - padR;
    final plotH = h - padT - padB;

    const aMin = 1.0, aMax = 240.0;
    const beMin = 0.0, beMax = 10.0;

    double aToX(double a) => padL + ((a - aMin) / (aMax - aMin)) * plotW;
    double beToY(double be) => padT + (1 - (be - beMin) / (beMax - beMin)) * plotH;

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0;
    canvas.drawLine(Offset(padL, padT), Offset(padL, padT + plotH), axisPaint);
    canvas.drawLine(Offset(padL, padT + plotH), Offset(padL + plotW, padT + plotH), axisPaint);

    // Y axis labels (MeV/nucleon)
    for (int be = 0; be <= 9; be += 3) {
      final yp = beToY(be.toDouble());
      _label(canvas, '$be', Offset(2, yp - 5), const Color(0xFF5A8A9A), fontSize: 8);
      canvas.drawLine(Offset(padL - 3, yp), Offset(padL, yp), axisPaint);
    }
    _label(canvas, 'MeV/핵자', Offset(2, padT - 10), const Color(0xFF5A8A9A), fontSize: 8);

    // X axis labels
    for (int a = 0; a <= 240; a += 40) {
      final xp = aToX(a.toDouble());
      _label(canvas, '$a', Offset(xp - 6, padT + plotH + 6), const Color(0xFF5A8A9A), fontSize: 8);
      canvas.drawLine(Offset(xp, padT + plotH), Offset(xp, padT + plotH + 3), axisPaint);
    }
    _label(canvas, '질량수 A →', Offset(padL + plotW / 2 - 22, padT + plotH + 18), const Color(0xFF5A8A9A), fontSize: 8);

    // Binding energy curve
    final curvePath = Path();
    bool firstPt = true;
    for (double a = 2; a <= 240; a += 1) {
      final be = _bindingEnergyPerNucleon(a);
      final px = aToX(a);
      final py = beToY(be);
      if (firstPt) {
        curvePath.moveTo(px, py);
        firstPt = false;
      } else {
        curvePath.lineTo(px, py);
      }
    }
    canvas.drawPath(
      curvePath,
      Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2.5..style = PaintingStyle.stroke,
    );

    // Fe-56 peak marker
    const aFe = 56.0;
    final beFe = _bindingEnergyPerNucleon(aFe);
    final xFe = aToX(aFe);
    final yFe = beToY(beFe);
    canvas.drawCircle(Offset(xFe, yFe), 5, Paint()..color = const Color(0xFFFFD700));
    _label(canvas, 'Fe-56\n${beFe.toStringAsFixed(1)}MeV', Offset(xFe + 4, yFe - 18), const Color(0xFFFFD700), fontSize: 8, bold: true);

    // Current mass number dot
    final curBE = _bindingEnergyPerNucleon(massNumber);
    final xCur = aToX(massNumber);
    final yCur = beToY(curBE);
    canvas.drawCircle(Offset(xCur, yCur), 6, Paint()..color = const Color(0xFFFF6B35));
    _label(canvas, 'A=${massNumber.toInt()}', Offset(xCur + 6, yCur - 6), const Color(0xFFFF6B35), fontSize: 9);

    // Fission arrow: U-235 → Fe region (right to center)
    const aU = 235.0, aBa = 141.0;
    final xU = aToX(aU);
    final yU = beToY(_bindingEnergyPerNucleon(aU));
    final xBa = aToX(aBa);
    final yBa = beToY(_bindingEnergyPerNucleon(aBa));
    _drawArrow(canvas, Offset(xU, yU), Offset(xBa, yBa), const Color(0xFFFF6B35), width: 1.5);
    _label(canvas, 'U-235→분열', Offset(xU - 40, yU + 4), const Color(0xFFFF6B35), fontSize: 8);

    // Fusion arrow: H-2 + H-3 → He-4 (left to center-left)
    const aH2 = 2.0, aHe = 4.0;
    final xH2 = aToX(aH2);
    final yH2 = beToY(_bindingEnergyPerNucleon(aH2));
    final xHe = aToX(aHe);
    final yHe = beToY(_bindingEnergyPerNucleon(aHe));
    _drawArrow(canvas, Offset(xH2, yH2), Offset(xHe, yHe), const Color(0xFF64FF8C), width: 1.5);
    _label(canvas, 'H+H→융합', Offset(xH2, yH2 + 4), const Color(0xFF64FF8C), fontSize: 8);

    // Animated neutron particle for fission chain
    final isFission = massNumber > 60;
    if (isFission) {
      // Animate neutrons flying outward from current position
      for (int i = 0; i < 3; i++) {
        final angle = time * 2 + i * (2 * math.pi / 3);
        final dist = (time * 20) % 40.0;
        final nx = xCur + dist * math.cos(angle);
        final ny = yCur + dist * math.sin(angle);
        if (nx > padL && nx < padL + plotW && ny > padT && ny < padT + plotH) {
          canvas.drawCircle(Offset(nx, ny), 3, Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.8));
        }
      }
    } else if (massNumber < 40) {
      // Fusion glow
      final glowR = 8 + 4 * math.sin(time * 3);
      canvas.drawCircle(Offset(xCur, yCur), glowR, Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.15));
    }

    // Energy release annotation
    final energyLabel = massNumber > 60
        ? '핵분열: ~200 MeV/반응'
        : massNumber < 20
            ? '핵융합: ~17.6 MeV/반응'
            : '안정 영역';
    final energyColor = massNumber > 60
        ? const Color(0xFFFF6B35)
        : massNumber < 20
            ? const Color(0xFF64FF8C)
            : const Color(0xFFFFD700);
    _label(canvas, energyLabel, Offset(padL + 4, padT + plotH + 30), energyColor, fontSize: 10, bold: true);
    _label(canvas, 'BE/A = ${curBE.toStringAsFixed(2)} MeV', Offset(w - 120, padT + plotH + 30), const Color(0xFF00D4FF), fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _NuclearFissionFusionScreenPainter oldDelegate) => true;
}
