import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class OsmosisScreen extends StatefulWidget {
  const OsmosisScreen({super.key});
  @override
  State<OsmosisScreen> createState() => _OsmosisScreenState();
}

class _OsmosisScreenState extends State<OsmosisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _concentration = 0.5;
  
  double _osmoticP = 12.2, _waterFlow = 0;

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
      _osmoticP = _concentration * 0.0821 * 298;
      _waterFlow = _osmoticP * 0.01;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _concentration = 0.5;
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
          Text('생물학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('삼투와 확산', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '삼투와 확산',
          formula: 'π = iMRT',
          formulaDescription: '반투막을 통한 삼투 현상을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _OsmosisScreenPainter(
                time: _time,
                concentration: _concentration,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '용질 농도 (M)',
                value: _concentration,
                min: 0,
                max: 3,
                step: 0.05,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(2) + ' M',
                onChanged: (v) => setState(() => _concentration = v),
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
          _V('삼투압', _osmoticP.toStringAsFixed(1) + ' atm'),
          _V('수분 이동', _waterFlow.toStringAsFixed(3) + ' L/s'),
          _V('농도', _concentration.toStringAsFixed(2) + ' M'),
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

class _OsmosisScreenPainter extends CustomPainter {
  final double time;
  final double concentration;

  _OsmosisScreenPainter({
    required this.time,
    required this.concentration,
  });

  void _lbl(Canvas canvas, String text, Offset pos, Color color, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // U-tube dimensions
    final tubeTop = 28.0;
    final tubeBottom = h * 0.78;
    final tubeH = tubeBottom - tubeTop;
    final leftX = cx - 60.0;
    final rightX = cx + 60.0;
    final tubeW = 46.0;
    final wallThick = 3.0;

    // Equilibration progress (0 to 1 over time, capped)
    final maxTime = 30.0;
    final tProgress = (time / maxTime).clamp(0.0, 1.0);

    // Right side water level rises with concentration
    final concFactor = concentration / 3.0; // max 3M
    final rightRise = tubeH * 0.25 * concFactor * tProgress;

    // Left water level (base)
    final leftWaterTop = tubeTop + tubeH * 0.25;
    // Right water level (higher due to osmosis)
    final rightWaterTop = tubeTop + tubeH * 0.25 - rightRise;

    // Draw tube walls (left arm, right arm)
    final wallPaint = Paint()..color = const Color(0xFF2A4A5A);
    canvas.drawRect(Rect.fromLTWH(leftX - tubeW / 2 - wallThick, tubeTop, wallThick, tubeH + 30), wallPaint);
    canvas.drawRect(Rect.fromLTWH(leftX + tubeW / 2, tubeTop, wallThick, tubeH + 30), wallPaint);
    canvas.drawRect(Rect.fromLTWH(rightX - tubeW / 2 - wallThick, tubeTop, wallThick, tubeH + 30), wallPaint);
    canvas.drawRect(Rect.fromLTWH(rightX + tubeW / 2, tubeTop, wallThick, tubeH + 30), wallPaint);

    // Bottom connecting tube
    canvas.drawRect(Rect.fromLTWH(leftX + tubeW / 2, tubeBottom, rightX - leftX - tubeW, 30), Paint()..color = const Color(0xFF0D1A20));
    canvas.drawRect(Rect.fromLTWH(leftX - tubeW / 2 - wallThick, tubeBottom, (rightX - leftX) + tubeW + wallThick * 2, wallThick), Paint()..color = const Color(0xFF2A4A5A));
    canvas.drawRect(Rect.fromLTWH(leftX - tubeW / 2 - wallThick, tubeBottom + 30, (rightX - leftX) + tubeW + wallThick * 2, wallThick), Paint()..color = const Color(0xFF2A4A5A));

    // Left water fill (low concentration - lighter blue)
    final leftWaterRect = Rect.fromLTWH(leftX - tubeW / 2, leftWaterTop, tubeW, tubeBottom - leftWaterTop + 30);
    canvas.drawRect(leftWaterRect, Paint()..color = const Color(0xFF003A6B).withValues(alpha: 0.7));

    // Right water fill (high concentration - deeper blue)
    final rightWaterRect = Rect.fromLTWH(rightX - tubeW / 2, rightWaterTop, tubeW, tubeBottom - rightWaterTop + 30);
    canvas.drawRect(rightWaterRect, Paint()..color = const Color(0xFF0A1E3A).withValues(alpha: 0.9));

    // Semipermeable membrane at bottom junction
    final memY = tubeBottom + 15;
    final memX = leftX + tubeW / 2;
    final memXEnd = rightX - tubeW / 2;
    // Dotted membrane
    final memPaint = Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2;
    for (double mx = memX; mx < memXEnd; mx += 6) {
      canvas.drawLine(Offset(mx, memY - 5), Offset(mx + 3, memY + 5), memPaint);
    }
    _lbl(canvas, '반투막', Offset((memX + memXEnd) / 2, memY + 16), const Color(0xFF00D4FF), 8.5);

    // Water molecules (small blue circles) in left side
    final rng = math.Random(42);
    for (int i = 0; i < 14; i++) {
      final mx = leftX - tubeW / 2 + rng.nextDouble() * tubeW;
      final my = leftWaterTop + rng.nextDouble() * (tubeBottom - leftWaterTop);
      canvas.drawCircle(Offset(mx, my), 3.5, Paint()..color = const Color(0xFF4DB8FF).withValues(alpha: 0.75));
    }

    // Solute molecules (orange dots) in right side
    final rng2 = math.Random(99);
    final soluteCount = (4 + concentration * 3).clamp(4, 14).toInt();
    for (int i = 0; i < soluteCount; i++) {
      final mx = rightX - tubeW / 2 + rng2.nextDouble() * tubeW;
      final my = rightWaterTop + rng2.nextDouble() * (tubeBottom - rightWaterTop);
      canvas.drawCircle(Offset(mx, my), 4.0, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.8));
    }

    // Water flow animation: molecules crossing membrane (left to right)
    if (concentration > 0.05) {
      for (int i = 0; i < 3; i++) {
        final t = (time * 0.6 + i / 3.0) % 1.0;
        final wx = memX + (memXEnd - memX) * (i + 1) / 4.0;
        final wy = memY - 5 + t * 12;
        canvas.drawCircle(Offset(wx, wy), 3, Paint()..color = const Color(0xFF4DB8FF).withValues(alpha: (1.0 - t) * 0.9));
      }
    }

    // Osmotic pressure arrow on right side
    if (rightRise > 5) {
      final arrowX = rightX + tubeW / 2 + 12;
      canvas.drawLine(Offset(arrowX, rightWaterTop + 10), Offset(arrowX, leftWaterTop - 10),
          Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);
      final aHead = Path()
        ..moveTo(arrowX, rightWaterTop + 2)
        ..lineTo(arrowX - 5, rightWaterTop + 12)
        ..lineTo(arrowX + 5, rightWaterTop + 12)
        ..close();
      canvas.drawPath(aHead, Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.fill);
      _lbl(canvas, 'Π', Offset(arrowX + 12, (rightWaterTop + leftWaterTop) / 2), const Color(0xFFFF6B35), 11);
    }

    // Labels
    _lbl(canvas, '저농도', Offset(leftX, tubeTop - 10), const Color(0xFF4DB8FF), 9);
    _lbl(canvas, '고농도', Offset(rightX, tubeTop - 10), const Color(0xFFFF6B35), 9);

    // Osmotic pressure formula at bottom
    final osmoticP = concentration * 0.0821 * 298;
    _lbl(canvas, 'Π = iCRT = ${osmoticP.toStringAsFixed(1)} atm', Offset(cx, h - 18), const Color(0xFF5A8A9A), 9);

    // Title
    _lbl(canvas, '삼투와 확산 (Osmosis)', Offset(cx, 14), const Color(0xFF00D4FF), 11);

    // Water flow direction label
    if (concentration > 0.05) {
      _lbl(canvas, '물 분자 이동 →', Offset(cx, memY), const Color(0xFF00D4FF), 8);
    }
  }

  @override
  bool shouldRepaint(covariant _OsmosisScreenPainter oldDelegate) => true;
}
