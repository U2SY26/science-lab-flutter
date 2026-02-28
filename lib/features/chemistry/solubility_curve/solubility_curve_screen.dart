import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class SolubilityCurveScreen extends StatefulWidget {
  const SolubilityCurveScreen({super.key});
  @override
  State<SolubilityCurveScreen> createState() => _SolubilityCurveScreenState();
}

class _SolubilityCurveScreenState extends State<SolubilityCurveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _tempC = 40.0;
  double _solNaCl = 0, _solKNO3 = 0, _solSugar = 0;

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
      _solNaCl = 35.7 + 0.04 * _tempC;
      _solKNO3 = 13.3 + 0.5 * _tempC + 0.003 * _tempC * _tempC;
      _solSugar = 179 + 0.7 * _tempC;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _tempC = 40.0;
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
          const Text('용해도 곡선', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '용해도 곡선',
          formula: 'S = f(T)',
          formulaDescription: '온도에 따른 용해도 변화를 관찰합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SolubilityCurveScreenPainter(
                time: _time,
                tempC: _tempC,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '온도 (°C)',
                value: _tempC,
                min: 0.0,
                max: 100.0,
                defaultValue: 40.0,
                formatValue: (v) => '${v.toInt()} °C',
                onChanged: (v) => setState(() => _tempC = v),
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
          _V('NaCl', '${_solNaCl.toStringAsFixed(1)} g/100mL'),
          _V('KNO₃', '${_solKNO3.toStringAsFixed(1)} g/100mL'),
          _V('설탕', '${_solSugar.toStringAsFixed(0)} g/100mL'),
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

class _SolubilityCurveScreenPainter extends CustomPainter {
  final double time;
  final double tempC;

  _SolubilityCurveScreenPainter({
    required this.time,
    required this.tempC,
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

  // Solubility functions (g / 100g H₂O)
  double _kno3(double t) => 13.3 + 0.5 * t + 0.003 * t * t;
  double _nacl(double t) => 35.7 + 0.04 * t;
  double _na2so4(double t) => t < 32 ? (4.9 + 1.1 * t) : (49.7 - 0.25 * (t - 32));
  double _caoh2(double t) => math.max(0.5, 1.85 - 0.012 * t);
  double _kclo3(double t) => 3.3 + 0.32 * t;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final T = tempC.clamp(0.0, 100.0);

    _lbl(canvas, '용해도 곡선 (g/100g H₂O)', Offset(w / 2, 12),
        const Color(0xFF00D4FF), 11, fw: FontWeight.bold);

    // Chart area
    final cL = 38.0, cT = 24.0, cR = w - 90.0, cB = h * 0.82;
    final cW = cR - cL, cHh = cB - cT;

    // Axes
    final axisP = Paint()..color = const Color(0xFF2A4050)..strokeWidth = 1..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cL, cT), Offset(cL, cB), axisP);
    canvas.drawLine(Offset(cL, cB), Offset(cR, cB), axisP);

    // Grid lines
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5..style = PaintingStyle.stroke;
    for (int yi = 0; yi <= 4; yi++) {
      final gy = cB - yi * (cHh / 4);
      canvas.drawLine(Offset(cL, gy), Offset(cR, gy), gridP);
      _lbl(canvas, '${(yi * 50).toString()}', Offset(cL - 14, gy), const Color(0xFF5A8A9A), 7);
    }
    for (int xi = 0; xi <= 5; xi++) {
      final gx = cL + xi * (cW / 5);
      canvas.drawLine(Offset(gx, cT), Offset(gx, cB), gridP);
      _lbl(canvas, '${(xi * 20).toString()}', Offset(gx, cB + 7), const Color(0xFF5A8A9A), 7);
    }

    // Axis labels
    _lbl(canvas, '온도 (°C)', Offset(cL + cW / 2, cB + 16), const Color(0xFF5A8A9A), 8);
    _lbl(canvas, 'g/100g', Offset(cL - 22, cT + 8), const Color(0xFF5A8A9A), 7);

    // Max solubility for scaling
    const maxSol = 200.0;

    // Curve definitions
    final curves = <(String, Color, double Function(double))>[
      ('KNO₃', const Color(0xFF00D4FF), _kno3),
      ('NaCl', const Color(0xFFFF6B35), _nacl),
      ('Na₂SO₄', const Color(0xFF64FF8C), _na2so4),
      ('Ca(OH)₂', const Color(0xFFFFD700), _caoh2),
      ('KClO₃', const Color(0xFFFF69B4), _kclo3),
    ];

    for (final curve in curves) {
      final curvePath = Path();
      bool first = true;
      for (double t2 = 0; t2 <= 100; t2 += 0.5) {
        final sol = curve.$3(t2).clamp(0.0, maxSol);
        final px = cL + (t2 / 100) * cW;
        final py = cB - (sol / maxSol) * (cHh - 2);
        if (first) { curvePath.moveTo(px, py); first = false; } else { curvePath.lineTo(px, py); }
      }
      canvas.drawPath(curvePath,
          Paint()..color = curve.$2..strokeWidth = 1.8..style = PaintingStyle.stroke);

      // Endpoint dot + label on right
      final endSol = curve.$3(100).clamp(0.0, maxSol);
      final endX = cR;
      final endY = cB - (endSol / maxSol) * (cHh - 2);
      canvas.drawCircle(Offset(endX, endY), 3, Paint()..color = curve.$2);
      _lbl(canvas, curve.$1, Offset(cR + 26, endY), curve.$2, 8);
    }

    // Current temperature vertical line
    final curX = cL + (T / 100) * cW;
    double dashY = cT;
    while (dashY < cB) {
      canvas.drawLine(Offset(curX, dashY), Offset(curX, math.min(dashY + 5, cB)),
          Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.7)..strokeWidth = 1.2..style = PaintingStyle.stroke);
      dashY += 9;
    }
    _lbl(canvas, '${T.toInt()}°C', Offset(curX, cT - 5), const Color(0xFFE0F4FF), 8);

    // Dots at current temperature for each substance
    for (int ci = 0; ci < curves.length; ci++) {
      final sol = curves[ci].$3(T).clamp(0.0, maxSol);
      final dotY = cB - (sol / maxSol) * (cHh - 2);
      canvas.drawCircle(Offset(curX, dotY), 5, Paint()..color = curves[ci].$2);
    }

    // ===== BOTTOM: Saturation region table =====
    final tableTop = cB + 26;
    _lbl(canvas, '현재 T=${T.toInt()}°C 용해도', Offset(w / 2, tableTop + 6),
        const Color(0xFFE0F4FF), 9, fw: FontWeight.bold);

    final colW2 = (w - 10) / 5;
    for (int ci = 0; ci < curves.length; ci++) {
      final sol = curves[ci].$3(T);
      final cx2 = 5.0 + (ci + 0.5) * colW2;
      final rowY = tableTop + 17.0;
      _lbl(canvas, curves[ci].$1, Offset(cx2, rowY), curves[ci].$2, 8, fw: FontWeight.bold);
      _lbl(canvas, '${sol.toStringAsFixed(1)}g', Offset(cx2, rowY + 12), curves[ci].$2, 8);
    }
  }

  @override
  bool shouldRepaint(covariant _SolubilityCurveScreenPainter oldDelegate) => true;
}
