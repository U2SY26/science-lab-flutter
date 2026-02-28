import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class HessLawScreen extends StatefulWidget {
  const HessLawScreen({super.key});
  @override
  State<HessLawScreen> createState() => _HessLawScreenState();
}

class _HessLawScreenState extends State<HessLawScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _pathType = 0;
  
  double _deltaH = -890.0, _step1 = -394.0, _step2 = -496.0;

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
      _step1 = -394.0 + 10 * math.sin(_time);
      _step2 = _deltaH - _step1;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _pathType = 0.0;
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
          const Text('헤스 법칙', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '헤스 법칙',
          formula: 'ΔH = ΣΔH_products - ΣΔH_reactants',
          formulaDescription: '반응 경로에 무관한 총 엔탈피 변화를 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _HessLawScreenPainter(
                time: _time,
                pathType: _pathType,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '반응 경로',
                value: _pathType,
                min: 0,
                max: 2,
                step: 1,
                defaultValue: 0,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _pathType = v),
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
          _V('ΔH₁', _step1.toStringAsFixed(0) + ' kJ'),
          _V('ΔH₂', _step2.toStringAsFixed(0) + ' kJ'),
          _V('∑ΔH', _deltaH.toStringAsFixed(0) + ' kJ'),
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

class _HessLawScreenPainter extends CustomPainter {
  final double time;
  final double pathType;

  _HessLawScreenPainter({
    required this.time,
    required this.pathType,
  });

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final angle = math.atan2(dy, dx);
    const arrowSize = 8.0;
    final p1 = Offset(
      to.dx - arrowSize * math.cos(angle - 0.4),
      to.dy - arrowSize * math.sin(angle - 0.4),
    );
    final p2 = Offset(
      to.dx - arrowSize * math.cos(angle + 0.4),
      to.dy - arrowSize * math.sin(angle + 0.4),
    );
    canvas.drawLine(to, p1, paint);
    canvas.drawLine(to, p2, paint);
  }

  void _label(Canvas canvas, String text, Offset pos, Color color, {double size = 10}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontFamily: 'monospace')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    const padL = 55.0, padR = 20.0, padT = 30.0, padB = 35.0;
    final plotW = w - padL - padR;
    final plotH = h - padT - padB;

    // Energy levels (fixed for Hess demo: CH4 + 2O2 → CO2 + 2H2O, ΔH=-890)
    // Two paths: direct vs step1+step2
    // Step1: CH4 + O2 → CO + 2H2O + H2 ΔH1≈-607
    // Step2: CO + 0.5O2 → CO2 ΔH2≈-283
    // Total: -890
    final dH1 = -394.0 + 30 * math.sin(time * 0.8);
    final dH2 = -890.0 - dH1;
    final dHtotal = dH1 + dH2; // always -890

    // Map energy to Y: max energy at top (padT), min at bottom
    const eMax = 100.0;
    const eMin = -1000.0;
    double eToY(double e) {
      final frac = (e - eMax) / (eMin - eMax);
      return padT + frac * plotH;
    }

    // Reactant level: 0 kJ/mol
    // Intermediate: dH1
    // Product: dHtotal
    final yReact = eToY(0);
    final yInter = eToY(dH1);
    final yProd = eToY(dHtotal);

    final xLeft = padL;
    final xMid = padL + plotW * 0.42;
    final xRight = padL + plotW;

    // Axis
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0;
    canvas.drawLine(Offset(padL, padT), Offset(padL, padT + plotH), axisPaint);
    canvas.drawLine(Offset(padL, padT + plotH), Offset(padL + plotW, padT + plotH), axisPaint);
    _label(canvas, 'H (kJ/mol)', Offset(2, padT - 8), const Color(0xFF5A8A9A), size: 9);
    _label(canvas, '반응 좌표', Offset(padL + plotW - 30, padT + plotH + 6), const Color(0xFF5A8A9A), size: 9);

    // Energy level lines
    final levelPaint = Paint()..strokeWidth = 2.5..style = PaintingStyle.stroke;

    // Reactant (cyan)
    levelPaint.color = const Color(0xFF00D4FF);
    canvas.drawLine(Offset(xLeft, yReact), Offset(xLeft + plotW * 0.25, yReact), levelPaint);
    _label(canvas, '반응물 (0)', Offset(xLeft - 52, yReact - 6), const Color(0xFF00D4FF), size: 9);

    // Intermediate (orange)
    levelPaint.color = const Color(0xFFFF6B35);
    canvas.drawLine(Offset(xMid - plotW * 0.1, yInter), Offset(xMid + plotW * 0.1, yInter), levelPaint);
    _label(canvas, '중간체\n${dH1.toStringAsFixed(0)}', Offset(xMid + plotW * 0.11, yInter - 8), const Color(0xFFFF6B35), size: 9);

    // Product (green)
    levelPaint.color = const Color(0xFF64FF8C);
    canvas.drawLine(Offset(xRight - plotW * 0.25, yProd), Offset(xRight, yProd), levelPaint);
    _label(canvas, '생성물\n${dHtotal.toStringAsFixed(0)}', Offset(xRight - padR - 40, yProd - 8), const Color(0xFF64FF8C), size: 9);

    // Direct path arrow (dashed-like via segments)
    final directPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    _drawArrow(canvas, Offset(xLeft + plotW * 0.12, yReact), Offset(xRight - plotW * 0.12, yProd), directPaint);
    // Label total
    final midX = (xLeft + plotW * 0.12 + xRight - plotW * 0.12) / 2;
    final midY = (yReact + yProd) / 2;
    _label(canvas, 'ΔH=${dHtotal.toStringAsFixed(0)}', Offset(midX - 30, midY - 14), const Color(0xFF00D4FF), size: 9);

    // Step 1 arrow
    final step1Paint = Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5;
    _drawArrow(canvas, Offset(xLeft + plotW * 0.25, yReact), Offset(xMid - plotW * 0.1, yInter), step1Paint);
    _label(canvas, 'ΔH₁=${dH1.toStringAsFixed(0)}', Offset(xLeft + plotW * 0.15, (yReact + yInter) / 2 - 4), const Color(0xFFFF6B35), size: 9);

    // Step 2 arrow
    final step2Paint = Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5;
    _drawArrow(canvas, Offset(xMid + plotW * 0.1, yInter), Offset(xRight - plotW * 0.25, yProd), step2Paint);
    _label(canvas, 'ΔH₂=${dH2.toStringAsFixed(0)}', Offset(xMid + plotW * 0.12, (yInter + yProd) / 2 - 4), const Color(0xFF64FF8C), size: 9);

    // Hess's law verification
    final verColor = (dHtotal - (-890)).abs() < 50 ? const Color(0xFF64FF8C) : const Color(0xFFFF6B35);
    _label(canvas, 'ΔH₁+ΔH₂ = ${dHtotal.toStringAsFixed(0)} kJ/mol', Offset(padL + 4, padT + plotH + 16), verColor, size: 9);

    // Title
    _label(canvas, '헤스 법칙', Offset(w / 2 - 22, 8), const Color(0xFF00D4FF), size: 12);
  }

  @override
  bool shouldRepaint(covariant _HessLawScreenPainter oldDelegate) => true;
}
