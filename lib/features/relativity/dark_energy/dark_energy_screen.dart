import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DarkEnergyScreen extends StatefulWidget {
  const DarkEnergyScreen({super.key});
  @override
  State<DarkEnergyScreen> createState() => _DarkEnergyScreenState();
}

class _DarkEnergyScreenState extends State<DarkEnergyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _omegaLambda = 0.7;
  double _omegaMatter = 0.3;
  double _decelParam = 0;

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
      _decelParam = _omegaMatter / 2 - _omegaLambda;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _omegaLambda = 0.7; _omegaMatter = 0.3;
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
          Text('상대성이론 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('암흑 에너지와 가속 팽창', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '암흑 에너지와 가속 팽창',
          formula: 'H² = H₀²(Ω_m/a³ + Ω_Λ)',
          formulaDescription: '우주의 가속 팽창을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DarkEnergyScreenPainter(
                time: _time,
                omegaLambda: _omegaLambda,
                omegaMatter: _omegaMatter,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'Ω_Λ (암흑 에너지)',
                value: _omegaLambda,
                min: 0,
                max: 1,
                step: 0.05,
                defaultValue: 0.7,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _omegaLambda = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'Ω_m (물질)',
                value: _omegaMatter,
                min: 0,
                max: 1,
                step: 0.05,
                defaultValue: 0.3,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _omegaMatter = v),
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
          _V('Ω_Λ', _omegaLambda.toStringAsFixed(2)),
          _V('Ω_m', _omegaMatter.toStringAsFixed(2)),
          _V('q₀', _decelParam.toStringAsFixed(2)),
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

class _DarkEnergyScreenPainter extends CustomPainter {
  final double time;
  final double omegaLambda;
  final double omegaMatter;

  _DarkEnergyScreenPainter({
    required this.time,
    required this.omegaLambda,
    required this.omegaMatter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Deceleration parameter q0 = Om/2 - OL
    final q0 = omegaMatter / 2.0 - omegaLambda;
    final isAccelerating = q0 < 0;

    // ===== LEFT: Scale factor a(t) graph (left 62%) =====
    final graphLeft = 10.0;
    final graphTop = 22.0;
    final graphW = w * 0.60;
    final graphH = h * 0.58;
    final graphRight = graphLeft + graphW;
    final graphBottom = graphTop + graphH;

    // Graph background
    canvas.drawRect(
      Rect.fromLTWH(graphLeft, graphTop, graphW, graphH),
      Paint()..color = const Color(0xFF0A1520),
    );

    // Grid lines
    for (int i = 1; i <= 4; i++) {
      final gy = graphTop + i * graphH / 4;
      canvas.drawLine(Offset(graphLeft, gy), Offset(graphRight, gy),
          Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5);
    }
    for (int i = 1; i <= 4; i++) {
      final gx = graphLeft + i * graphW / 4;
      canvas.drawLine(Offset(gx, graphTop), Offset(gx, graphBottom),
          Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5);
    }

    // Axes
    canvas.drawLine(Offset(graphLeft, graphBottom), Offset(graphRight, graphBottom),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0);
    canvas.drawLine(Offset(graphLeft, graphTop), Offset(graphLeft, graphBottom),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0);
    _drawLabel(canvas, 't', Offset(graphRight - 6, graphBottom + 4), 9, AppColors.muted);
    _drawLabel(canvas, 'a(t)', Offset(graphLeft + 2, graphTop - 2), 9, AppColors.muted);

    // Three scenarios
    final scenarios = [
      {'OL': 0.0,  'Om': 0.3,  'label': 'Ω_Λ=0',   'color': const Color(0xFFFF6B35)},
      {'OL': 0.7,  'Om': 0.3,  'label': 'Ω_Λ=0.7', 'color': const Color(0xFF00D4FF)},
      {'OL': 1.0,  'Om': 0.1,  'label': 'Ω_Λ=1.0', 'color': const Color(0xFF64FF8C)},
    ];

    for (final sc in scenarios) {
      final oL = sc['OL'] as double;
      final oM = sc['Om'] as double;
      final color = sc['color'] as Color;
      final label = sc['label'] as String;
      _drawScaleFactor(canvas, graphLeft, graphTop, graphW, graphH, oL, oM, color);
      _drawLabel(canvas, label,
          Offset(graphRight + 4, graphTop + _scenarioLabelY(oL, oM) * graphH), 8, color);
    }

    // Current scenario (user slider)
    _drawScaleFactor(canvas, graphLeft, graphTop, graphW, graphH,
        omegaLambda, omegaMatter, const Color(0xFFFFCC44), strokeWidth: 2.2);

    // "Now" marker (t = 0.65 of timeline ≈ present)
    final nowX = graphLeft + 0.65 * graphW;
    canvas.drawLine(
      Offset(nowX, graphTop + 4),
      Offset(nowX, graphBottom),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
    _drawLabel(canvas, '현재', Offset(nowX - 6, graphTop + 2), 8, AppColors.muted);

    // Big Freeze / Big Rip labels
    _drawLabel(canvas, isAccelerating ? 'Big Freeze →' : '감속 팽창',
        Offset(graphLeft + 4, graphTop + 4), 8,
        isAccelerating ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35));

    // q0 label
    _drawLabel(canvas, 'q₀ = ${q0.toStringAsFixed(2)}  ${isAccelerating ? "가속" : "감속"}',
        Offset(graphLeft, graphBottom + 6), 9,
        isAccelerating ? const Color(0xFF64FF8C) : const Color(0xFFFF6B35));

    _drawLabel(canvas, '암흑 에너지 가속 팽창', Offset(w * 0.28, 8), 11, AppColors.accent);

    // ===== RIGHT: Pie chart (right 36%) =====
    final pieCx = w * 0.81;
    final pieCy = h * 0.28;
    final pieR = math.min(w * 0.14, h * 0.17);

    _drawPieChart(canvas, Offset(pieCx, pieCy), pieR, omegaLambda, omegaMatter);

    // ===== BOTTOM: Expansion acceleration bar =====
    final barTop = graphBottom + 26.0;
    final barH2 = math.min(28.0, h - barTop - 8);
    if (barH2 > 10) {
      _drawLabel(canvas, 'ä/a', Offset(graphLeft, barTop), 9, AppColors.muted);
      final barLeft = graphLeft + 24.0;
      final barW2 = graphW - 28.0;
      canvas.drawRect(
        Rect.fromLTWH(barLeft, barTop, barW2, barH2),
        Paint()..color = const Color(0xFF0A1520),
      );
      // Zero line at center
      final zeroX = barLeft + barW2 / 2;
      canvas.drawLine(
        Offset(zeroX, barTop),
        Offset(zeroX, barTop + barH2),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1.0,
      );
      // Fill bar
      final qNorm = (-q0).clamp(-1.2, 1.2) / 1.2;
      final fillW = (qNorm.abs() * barW2 / 2).clamp(0.0, barW2 / 2);
      canvas.drawRect(
        Rect.fromLTWH(
          qNorm >= 0 ? zeroX : zeroX - fillW,
          barTop + 3,
          fillW,
          barH2 - 6,
        ),
        Paint()..color = isAccelerating
            ? const Color(0xFF64FF8C).withValues(alpha: 0.7)
            : const Color(0xFFFF6B35).withValues(alpha: 0.7),
      );
      _drawLabel(canvas, isAccelerating ? '가속' : '감속',
          Offset(zeroX + (isAccelerating ? 4 : -28), barTop + 6), 8,
          isAccelerating ? const Color(0xFF64FF8C) : const Color(0xFFFF6B35));
    }
  }

  void _drawScaleFactor(Canvas canvas, double gLeft, double gTop,
      double gW, double gH, double oL, double oM, Color color,
      {double strokeWidth = 1.2}) {
    final path = Path();
    bool first = true;
    const int steps = 60;
    for (int i = 0; i <= steps; i++) {
      final tNorm = i / steps.toDouble(); // 0..1 timeline
      // Simple scale factor approximation: a(t) ∝ power law + lambda boost
      double a;
      if (oL < 0.01) {
        // matter dominated: a ∝ t^(2/3)
        a = math.pow(tNorm + 0.05, 2.0 / 3.0).toDouble();
      } else {
        // dark energy dominated: accelerated (exponential-like at late times)
        final matterPart = math.pow(tNorm + 0.05, 2.0 / 3.0).toDouble() * (1 - oL);
        final lambdaPart = oL * math.exp(tNorm * oL * 1.5) * 0.3;
        a = matterPart + lambdaPart;
      }
      // Normalize: a at tNorm=0.65 (now) → 1.0
      final aNow = oL < 0.01
          ? math.pow(0.7, 2.0 / 3.0).toDouble()
          : (math.pow(0.7, 2.0 / 3.0).toDouble() * (1 - oL) + oL * math.exp(0.7 * oL * 1.5) * 0.3);
      a = a / aNow;

      final px = gLeft + tNorm * gW;
      final py = gTop + gH - (a.clamp(0.0, 2.2) / 2.2) * gH;
      if (first) {
        path.moveTo(px, py);
        first = false;
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );
  }

  double _scenarioLabelY(double oL, double oM) {
    if (oL >= 0.9) return 0.08;
    if (oL >= 0.5) return 0.25;
    return 0.55;
  }

  void _drawPieChart(Canvas canvas, Offset center, double r,
      double oL, double oM) {
    // Composition: dark energy (oL), matter (oM~0.27), radiation (rest ~0.05)
    final oR = math.max(0.0, 1.0 - oL - oM); // radiation + other
    final total = oL + oM + oR;
    final fracs = [oL / total, oM / total, oR / total];
    final colors = [
      const Color(0xFF9955EE),
      const Color(0xFF4488FF),
      const Color(0xFFFF8833),
    ];
    final labels = ['암흑E', '물질', '복사'];

    double startAngle = -math.pi / 2;
    for (int i = 0; i < 3; i++) {
      final sweep = fracs[i] * math.pi * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle, sweep, true,
        Paint()..color = colors[i].withValues(alpha: 0.8),
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle, sweep, true,
        Paint()
          ..color = const Color(0xFF0D1A20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      // Label
      final midAngle = startAngle + sweep / 2;
      final lx = center.dx + r * 0.65 * math.cos(midAngle);
      final ly = center.dy + r * 0.65 * math.sin(midAngle);
      _drawLabel(canvas, '${(fracs[i] * 100).toStringAsFixed(0)}%',
          Offset(lx - 10, ly - 5), 7.5, Colors.white.withValues(alpha: 0.9));
      final lx2 = center.dx + (r + 10) * math.cos(midAngle);
      final ly2 = center.dy + (r + 10) * math.sin(midAngle);
      _drawLabel(canvas, labels[i], Offset(lx2 - 10, ly2 - 4), 7, colors[i]);
      startAngle += sweep;
    }
    _drawLabel(canvas, '우주 구성', Offset(center.dx - 20, center.dy + r + 16), 8, AppColors.muted);
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _DarkEnergyScreenPainter oldDelegate) => true;
}
