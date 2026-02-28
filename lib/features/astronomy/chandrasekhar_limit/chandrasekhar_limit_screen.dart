import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ChandrasekharLimitScreen extends StatefulWidget {
  const ChandrasekharLimitScreen({super.key});
  @override
  State<ChandrasekharLimitScreen> createState() => _ChandrasekharLimitScreenState();
}

class _ChandrasekharLimitScreenState extends State<ChandrasekharLimitScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _wdMass = 0.8;
  double _radius = 0.01; bool _isStable = true; String _fate = 'Stable WD';

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
      _radius = 0.013 * math.pow(1.44 / _wdMass, 1.0 / 3.0) * (1 - math.pow(_wdMass / 1.44, 4.0 / 3.0)).abs().clamp(0.01, 1.0);
      _isStable = _wdMass < 1.44;
      _fate = _isStable ? 'Stable WD' : 'Collapse → NS/Ia SN';
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _wdMass = 0.8;
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
          Text('천문학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('찬드라세카르 한계', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '찬드라세카르 한계',
          formula: 'M_Ch ≈ 1.4 M☉',
          formulaDescription: '백색왜성의 질량 한계와 그 이상의 운명을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ChandrasekharLimitScreenPainter(
                time: _time,
                wdMass: _wdMass,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '백색왜성 질량 (M☉)',
                value: _wdMass,
                min: 0.2,
                max: 2.0,
                step: 0.05,
                defaultValue: 0.8,
                formatValue: (v) => '${v.toStringAsFixed(2)} M☉',
                onChanged: (v) => setState(() => _wdMass = v),
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
          _V('반지름', '${(_radius * 100).toStringAsFixed(2)} R☉'),
          _V('안정성', _fate),
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

class _ChandrasekharLimitScreenPainter extends CustomPainter {
  final double time;
  final double wdMass;

  _ChandrasekharLimitScreenPainter({
    required this.time,
    required this.wdMass,
  });

  // Chandrasekhar mass-radius relation: R ∝ (1 - (M/Mch)^(4/3))^(1/2) / M^(1/3)
  double _massToRadius(double m) {
    if (m >= 1.44) return 0;
    final x = math.pow(m / 1.44, 4.0 / 3.0) as double;
    final r = 0.013 * math.pow(1 - x, 0.5) / math.pow(m, 1.0 / 3.0);
    return r.clamp(0.0, 0.05);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    const padL = 52.0, padR = 16.0, padT = 16.0, padB = 44.0;
    final plotW = size.width - padL - padR;
    final plotH = size.height - padT - padB;
    final plotLeft = padL;
    final plotTop = padT;
    final plotBottom = padT + plotH;
    final plotRight = padL + plotW;

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.2;
    canvas.drawLine(Offset(plotLeft, plotTop), Offset(plotLeft, plotBottom), axisPaint);
    canvas.drawLine(Offset(plotLeft, plotBottom), Offset(plotRight, plotBottom), axisPaint);

    // Grid
    final gridPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5;
    for (int i = 1; i <= 5; i++) {
      final y = plotBottom - i * plotH / 5;
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), gridPaint);
    }
    for (int i = 1; i <= 6; i++) {
      final x = plotLeft + i * plotW / 6;
      canvas.drawLine(Offset(x, plotTop), Offset(x, plotBottom), gridPaint);
    }

    // Mass-radius curve
    final curvePaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final path = Path();
    bool started = false;
    const steps = 200;
    for (int i = 0; i <= steps; i++) {
      final m = 0.1 + i * (1.43 / steps); // 0.1 to 1.43 Msun
      final r = _massToRadius(m);
      // x: mass 0->2 Msun, y: radius 0->0.05 Rsun (normalized)
      final xFrac = (m - 0.0) / 2.0;
      final yFrac = r / 0.05;
      final px = plotLeft + xFrac * plotW;
      final py = plotBottom - yFrac * plotH;
      if (!started) { path.moveTo(px, py); started = true; }
      else { path.lineTo(px, py); }
    }
    // After 1.44: collapse to zero (draw dashed drop)
    canvas.drawPath(path, curvePaint);

    // Chandrasekhar limit vertical line
    final limitX = plotLeft + (1.44 / 2.0) * plotW;
    final limitPaint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    // Draw dashed
    double dashY = plotTop;
    while (dashY < plotBottom) {
      canvas.drawLine(Offset(limitX, dashY), Offset(limitX, math.min(dashY + 8, plotBottom)), limitPaint);
      dashY += 14;
    }
    _drawLabel(canvas, '1.44 M☉', Offset(limitX - 24, plotTop + 2), const Color(0xFFFF6B35), 9);

    // Current mass marker
    final curR = _massToRadius(wdMass.clamp(0.1, 1.43));
    final curX = plotLeft + (wdMass.clamp(0.1, 1.43) / 2.0) * plotW;
    final curY = plotBottom - (curR / 0.05) * plotH;
    final isStable = wdMass < 1.44;

    // Connecting lines to axes
    canvas.drawLine(Offset(curX, curY), Offset(curX, plotBottom),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.4)..strokeWidth = 0.8..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(plotLeft, curY), Offset(curX, curY),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.4)..strokeWidth = 0.8..style = PaintingStyle.stroke);

    // Marker dot
    final markerColor = isStable ? const Color(0xFF00D4FF) : const Color(0xFFFF4444);
    final pulse = 0.12 * math.sin(time * 3);
    canvas.drawCircle(Offset(curX, isStable ? curY : plotBottom),
        9 + pulse * 4,
        Paint()..color = markerColor.withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(curX, isStable ? curY : plotBottom), 5.5 + pulse,
        Paint()..color = markerColor);

    // Collapse indicator if over limit
    if (!isStable) {
      final collapseX = plotLeft + (wdMass.clamp(0.0, 2.0) / 2.0) * plotW;
      _drawLabel(canvas, '붕괴! → NS/SN Ia', Offset(collapseX - 40, plotBottom - 50),
          const Color(0xFFFF4444), 10, bold: true);
      // Explosion sparks
      for (int i = 0; i < 8; i++) {
        final angle = time * 2 + i * math.pi / 4;
        final sparkR = 15 + 8 * math.sin(time * 4 + i);
        canvas.drawLine(
          Offset(curX, plotBottom),
          Offset(curX + sparkR * math.cos(angle), plotBottom - sparkR * math.sin(angle).abs()),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)..strokeWidth = 1.5,
        );
      }
    }

    // Axis labels
    final massLabels = ['0', '0.5', '1.0', '1.5', '2.0'];
    for (int i = 0; i < 5; i++) {
      final x = plotLeft + i * plotW / 4;
      _drawLabel(canvas, massLabels[i], Offset(x - 6, plotBottom + 5), const Color(0xFF5A8A9A), 8);
    }
    _drawLabel(canvas, '질량 (M☉)', Offset(plotLeft + plotW / 2 - 18, size.height - 8), const Color(0xFF5A8A9A), 9);

    final radLabels = ['0', '1', '2', '3', '4', '5'];
    for (int i = 0; i <= 5; i++) {
      final y = plotBottom - i * plotH / 5;
      _drawLabel(canvas, radLabels[i], Offset(0, y - 5), const Color(0xFF5A8A9A), 8);
    }
    _drawLabel(canvas, 'R(×10⁻²R☉)', Offset(2, plotTop), const Color(0xFF5A8A9A), 8);

    // Pressure comparison bars (bottom right)
    final barX = plotRight - 80.0;
    final barY = plotTop + 20.0;
    _drawLabel(canvas, '압력 비교', Offset(barX - 2, barY - 12), const Color(0xFF5A8A9A), 8);
    final massFrac = (wdMass / 1.44).clamp(0.0, 1.2);
    // Electron degeneracy pressure
    canvas.drawRect(Rect.fromLTWH(barX, barY, 20, 50), Paint()..color = const Color(0xFF1A3040));
    canvas.drawRect(Rect.fromLTWH(barX, barY + 50 * (1 - 1.0.clamp(0.0, 1.0)), 20, 50 * 1.0.clamp(0.0, 1.0)),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.8));
    _drawLabel(canvas, '축퇴압', Offset(barX - 2, barY + 52), const Color(0xFF00D4FF), 7);
    // Gravity
    canvas.drawRect(Rect.fromLTWH(barX + 28, barY, 20, 50), Paint()..color = const Color(0xFF1A3040));
    final gravFrac = massFrac.clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(barX + 28, barY + 50 * (1 - gravFrac), 20, 50 * gravFrac),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.8));
    _drawLabel(canvas, '중력', Offset(barX + 28, barY + 52), const Color(0xFFFF6B35), 7);
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _ChandrasekharLimitScreenPainter oldDelegate) => true;
}
