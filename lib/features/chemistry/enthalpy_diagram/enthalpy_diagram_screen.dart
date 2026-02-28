import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class EnthalpyDiagramScreen extends StatefulWidget {
  const EnthalpyDiagramScreen({super.key});
  @override
  State<EnthalpyDiagramScreen> createState() => _EnthalpyDiagramScreenState();
}

class _EnthalpyDiagramScreenState extends State<EnthalpyDiagramScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _deltaH = -100;
  double _activationE = 50;
  String _reactionType = "발열";

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
      _reactionType = _deltaH < 0 ? "발열" : "흡열";
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _deltaH = -100.0; _activationE = 50.0;
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
          const Text('엔탈피 다이어그램', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '엔탈피 다이어그램',
          formula: 'ΔH = H_products - H_reactants',
          formulaDescription: '반응의 엔탈피 변화를 에너지 다이어그램으로 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _EnthalpyDiagramScreenPainter(
                time: _time,
                deltaH: _deltaH,
                activationE: _activationE,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'ΔH (kJ/mol)',
                value: _deltaH,
                min: -500,
                max: 500,
                step: 10,
                defaultValue: -100,
                formatValue: (v) => v.toStringAsFixed(0) + ' kJ/mol',
                onChanged: (v) => setState(() => _deltaH = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'Ea (kJ/mol)',
                value: _activationE,
                min: 10,
                max: 200,
                step: 5,
                defaultValue: 50,
                formatValue: (v) => v.toStringAsFixed(0) + ' kJ/mol',
                onChanged: (v) => setState(() => _activationE = v),
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
          _V('ΔH', _deltaH.toStringAsFixed(0) + ' kJ'),
          _V('Ea', _activationE.toStringAsFixed(0) + ' kJ'),
          _V('유형', _reactionType),
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

class _EnthalpyDiagramScreenPainter extends CustomPainter {
  final double time;
  final double deltaH;
  final double activationE;

  _EnthalpyDiagramScreenPainter({
    required this.time,
    required this.deltaH,
    required this.activationE,
  });

  void _label(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 10}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final angle = math.atan2(dy, dx);
    const arrowSize = 7.0;
    canvas.drawLine(to, Offset(to.dx - arrowSize * math.cos(angle - 0.5), to.dy - arrowSize * math.sin(angle - 0.5)), paint);
    canvas.drawLine(to, Offset(to.dx - arrowSize * math.cos(angle + 0.5), to.dy - arrowSize * math.sin(angle + 0.5)), paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    const padL = 50.0, padR = 20.0, padT = 28.0, padB = 30.0;
    final plotW = w - padL - padR;
    final plotH = h - padT - padB;

    final isExothermic = deltaH < 0;
    // Energy levels (kJ/mol relative to reactant = 0)
    final eReact = 0.0;
    final eTransition = activationE; // peak
    final eProd = deltaH;
    // Catalyzed: lower Ea by 30%
    final eTransCat = activationE * 0.65;

    // Determine energy range
    final eMax = [eReact, eTransition, eProd, eTransCat].reduce(math.max) + 20;
    final eMin = [eReact, eTransition, eProd, eTransCat].reduce(math.min) - 20;

    double eToY(double e) {
      return padT + (eMax - e) / (eMax - eMin) * plotH;
    }

    // X positions
    final xReact = padL;
    final xPeak = padL + plotW * 0.48;
    final xProd = padL + plotW;

    // Draw axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0;
    canvas.drawLine(Offset(padL, padT), Offset(padL, padT + plotH), axisPaint);
    canvas.drawLine(Offset(padL, padT + plotH), Offset(xProd, padT + plotH), axisPaint);
    _label(canvas, 'E (kJ)', Offset(2, padT - 8), const Color(0xFF5A8A9A), fontSize: 9);
    _label(canvas, '반응 좌표 →', Offset(padL + plotW / 2 - 20, padT + plotH + 8), const Color(0xFF5A8A9A), fontSize: 9);

    // Build smooth reaction curve using Bezier-like path
    // Reactant plateau → peak → product plateau
    final yReact = eToY(eReact);
    final yTrans = eToY(eTransition);
    final yProd = eToY(eProd);
    final yTransCat = eToY(eTransCat);

    // Main reaction curve
    final curvePaint = Paint()
      ..color = isExothermic ? const Color(0xFFFF6B35) : const Color(0xFF00D4FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(xReact, yReact);
    path.cubicTo(
      xReact + plotW * 0.15, yReact,
      xPeak - plotW * 0.15, yTrans,
      xPeak, yTrans,
    );
    path.cubicTo(
      xPeak + plotW * 0.15, yTrans,
      xProd - plotW * 0.15, yProd,
      xProd, yProd,
    );
    canvas.drawPath(path, curvePaint);

    // Catalyzed path (dashed appearance via short segments)
    final catPaint = Paint()
      ..color = const Color(0xFF64FF8C).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final catPath = Path();
    catPath.moveTo(xReact, yReact);
    catPath.cubicTo(
      xReact + plotW * 0.15, yReact,
      xPeak - plotW * 0.15, yTransCat,
      xPeak, yTransCat,
    );
    catPath.cubicTo(
      xPeak + plotW * 0.15, yTransCat,
      xProd - plotW * 0.15, yProd,
      xProd, yProd,
    );
    // Draw as dashed by intervals
    final dashPathEffect = catPath;
    canvas.drawPath(dashPathEffect, catPaint..strokeWidth = 1.5);

    // Energy level lines (horizontal)
    final lvlPaint = Paint()..strokeWidth = 1.5;
    // Reactant
    lvlPaint.color = const Color(0xFF00D4FF);
    canvas.drawLine(Offset(xReact, yReact), Offset(xReact + plotW * 0.22, yReact), lvlPaint);
    _label(canvas, '반응물\n0 kJ', Offset(2, yReact - 14), const Color(0xFF00D4FF), fontSize: 9);

    // Product
    lvlPaint.color = isExothermic ? const Color(0xFFFF6B35) : const Color(0xFF00D4FF);
    canvas.drawLine(Offset(xProd - plotW * 0.22, yProd), Offset(xProd, yProd), lvlPaint);
    _label(canvas, '생성물\n${deltaH.toStringAsFixed(0)}', Offset(xProd - padR - 35, yProd - 14), lvlPaint.color, fontSize: 9);

    // Transition state
    canvas.drawCircle(Offset(xPeak, yTrans), 4, Paint()..color = const Color(0xFFFFD700));
    _label(canvas, '전이 상태', Offset(xPeak - 20, yTrans - 16), const Color(0xFFFFD700), fontSize: 9);

    // Arrows for Ea and ΔH
    final arrPaint = Paint()..strokeWidth = 1.5..style = PaintingStyle.stroke;
    // Ea arrow
    arrPaint.color = const Color(0xFFFFD700);
    final xEaLine = padL + plotW * 0.25;
    _drawArrow(canvas, Offset(xEaLine, yReact), Offset(xEaLine, yTrans), arrPaint);
    _drawArrow(canvas, Offset(xEaLine, yTrans), Offset(xEaLine, yReact), arrPaint);
    _label(canvas, 'Ea=${activationE.toStringAsFixed(0)}', Offset(xEaLine + 4, (yReact + yTrans) / 2 - 5), const Color(0xFFFFD700), fontSize: 9);

    // ΔH arrow
    arrPaint.color = isExothermic ? const Color(0xFFFF6B35) : const Color(0xFF00D4FF);
    final xDHLine = padL + plotW * 0.78;
    _drawArrow(canvas, Offset(xDHLine, yReact), Offset(xDHLine, yProd), arrPaint);
    _label(canvas, 'ΔH=${deltaH.toStringAsFixed(0)}', Offset(xDHLine + 4, (yReact + yProd) / 2 - 5), arrPaint.color, fontSize: 9);

    // Moving particle along curve
    final t = (time * 0.4) % 1.0;
    final metrics = path.computeMetrics().first;
    final tangent = metrics.getTangentForOffset(t * metrics.length);
    if (tangent != null) {
      canvas.drawCircle(tangent.position, 5, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9));
    }

    // Catalyst label
    _label(canvas, '── 촉매 경로', Offset(padL + 4, padT + 4), const Color(0xFF64FF8C), fontSize: 9);
    _label(canvas, isExothermic ? '발열 반응' : '흡열 반응', Offset(w - 60, padT + 4), isExothermic ? const Color(0xFFFF6B35) : const Color(0xFF00D4FF), fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _EnthalpyDiagramScreenPainter oldDelegate) => true;
}
