import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class VelocityAdditionScreen extends StatefulWidget {
  const VelocityAdditionScreen({super.key});
  @override
  State<VelocityAdditionScreen> createState() => _VelocityAdditionScreenState();
}

class _VelocityAdditionScreenState extends State<VelocityAdditionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _u = 0.5;
  double _v = 0.5;
  double _classical = 0, _relativistic = 0;

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
      _classical = _u + _v;
      _relativistic = (_u + _v) / (1 + _u * _v);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _u = 0.5;
      _v = 0.5;
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
          const Text('상대론적 속도 합성', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '상대론적 속도 합성',
          formula: "u' = (u+v)/(1+uv/c\u00B2)",
          formulaDescription: '고전적 합성과 상대론적 합성을 비교합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _VelocityAdditionScreenPainter(
                time: _time,
                u: _u,
                v: _v,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '속도 u (c)',
                value: _u,
                min: 0.0,
                max: 0.99,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => '${v.toStringAsFixed(2)} c',
                onChanged: (v) => setState(() => _u = v),
              ),
              advancedControls: [
            SimSlider(
                label: '속도 v (c)',
                value: _v,
                min: 0.0,
                max: 0.99,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => '${v.toStringAsFixed(2)} c',
                onChanged: (v) => setState(() => _v = v),
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
          _V('고전적', '${_classical.toStringAsFixed(3)} c'),
          _V('상대론적', '${_relativistic.toStringAsFixed(3)} c'),
          _V('차이', '${(_classical - _relativistic).toStringAsFixed(3)} c'),
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

class _VelocityAdditionScreenPainter extends CustomPainter {
  final double time;
  final double u;
  final double v;

  _VelocityAdditionScreenPainter({
    required this.time,
    required this.u,
    required this.v,
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
    final u2 = u.clamp(0.0, 0.99);
    final v2 = v.clamp(0.0, 0.99);
    final classical = (u2 + v2).clamp(0.0, 2.0);
    final relativistic = (u2 + v2) / (1 + u2 * v2);

    _lbl(canvas, '상대론적 속도 합성', Offset(w / 2, 12),
        const Color(0xFF00D4FF), 11, fw: FontWeight.bold);

    final axisP = Paint()..color = const Color(0xFF2A4050)..strokeWidth = 1..style = PaintingStyle.stroke;

    // ======= TOP: w(v₁) graph for fixed v₂ =======
    final gL = 36.0, gT = 24.0, gR = w - 10.0, gB = h * 0.54;
    final gW = gR - gL;
    final gH = gB - gT;

    // Axes
    canvas.drawLine(Offset(gL, gT + 6), Offset(gL, gB), axisP);
    canvas.drawLine(Offset(gL, gB), Offset(gR, gB), axisP);

    // Grid
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5..style = PaintingStyle.stroke;
    for (int gi = 0; gi <= 4; gi++) {
      final gy = gT + gi * (gH / 4);
      final gx2 = gL + gi * (gW / 4);
      canvas.drawLine(Offset(gL, gy), Offset(gR, gy), gridP);
      canvas.drawLine(Offset(gx2, gT), Offset(gx2, gB), gridP);
    }

    // Axis labels
    _lbl(canvas, 'v₁ (c)', Offset(gR - 10, gB + 8), const Color(0xFF5A8A9A), 8);
    _lbl(canvas, 'w (c)', Offset(gL - 14, gT + 8), const Color(0xFF5A8A9A), 8);
    for (int gi = 0; gi <= 4; gi++) {
      _lbl(canvas, '${(gi * 0.25).toStringAsFixed(2)}',
          Offset(gL + gi * (gW / 4), gB + 7), const Color(0xFF5A8A9A), 7);
      _lbl(canvas, '${(gi * 0.5).toStringAsFixed(1)}',
          Offset(gL - 14, gB - gi * (gH / 4)), const Color(0xFF5A8A9A), 7);
    }

    // Light speed limit line c=1
    final cLineY = gB - (1.0 / 2.0) * gH; // w=1.0 mapped to half of 2c range
    double dashX = gL;
    while (dashX < gR) {
      canvas.drawLine(Offset(dashX, cLineY), Offset(math.min(dashX + 5, gR), cLineY),
          Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.6)..strokeWidth = 1.2..style = PaintingStyle.stroke);
      dashX += 9;
    }
    _lbl(canvas, 'c (광속 한계)', Offset(gR - 28, cLineY - 7), const Color(0xFFFFD700), 8);

    // Classical curve w = v1 + v2 (can exceed c)
    final classPath = Path();
    for (double v1 = 0; v1 <= 0.99; v1 += 0.01) {
      final wc = (v1 + v2).clamp(0.0, 2.0);
      final px = gL + (v1 / 1.0) * gW;
      final py = gB - (wc / 2.0) * gH;
      if (v1 == 0) { classPath.moveTo(px, py); } else { classPath.lineTo(px, py); }
    }
    canvas.drawPath(classPath,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)..strokeWidth = 1.8..style = PaintingStyle.stroke);

    // Relativistic curve w = (v1+v2)/(1+v1*v2)
    final relPath = Path();
    for (double v1 = 0; v1 <= 0.99; v1 += 0.01) {
      final wr = (v1 + v2) / (1 + v1 * v2);
      final px = gL + (v1 / 1.0) * gW;
      final py = gB - (wr / 2.0) * gH;
      if (v1 == 0) { relPath.moveTo(px, py); } else { relPath.lineTo(px, py); }
    }
    canvas.drawPath(relPath,
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2.2..style = PaintingStyle.stroke);

    // Current v1=u marker
    final curX = gL + (u2 / 1.0) * gW;
    final curClassY = gB - (classical / 2.0) * gH;
    final curRelY = gB - (relativistic / 2.0) * gH;
    canvas.drawCircle(Offset(curX, curClassY.clamp(gT, gB)), 5,
        Paint()..color = const Color(0xFFFF6B35));
    canvas.drawCircle(Offset(curX, curRelY.clamp(gT, gB)), 5,
        Paint()..color = const Color(0xFF00D4FF));
    // Vertical marker line
    canvas.drawLine(Offset(curX, gT), Offset(curX, gB),
        Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.3)..strokeWidth = 1..style = PaintingStyle.stroke);

    // Legend
    _lbl(canvas, '─ 상대론적', Offset(gL + gW * 0.72, gT + 10), const Color(0xFF00D4FF), 8);
    _lbl(canvas, '─ 고전적', Offset(gL + gW * 0.72, gT + 21), const Color(0xFFFF6B35).withValues(alpha: 0.7), 8);

    // ======= BOTTOM: Comparison bars =======
    final barSect = h * 0.60;
    _lbl(canvas, 'v₁=${u2.toStringAsFixed(2)}c  v₂=${v2.toStringAsFixed(2)}c', Offset(w / 2, barSect + 8),
        const Color(0xFFE0F4FF), 9);

    final barMaxW = 2.0; // max display = 2c
    final barL2 = 36.0, barR2 = w - 10.0;
    final barW7 = barR2 - barL2;
    final barH5 = 22.0;

    // Classical bar
    final classBarY = barSect + 22;
    final classBarW = (classical / barMaxW).clamp(0.0, 1.0) * barW7;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(barL2, classBarY, barW7, barH5), const Radius.circular(3)),
        Paint()..color = const Color(0xFF1A3040));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(barL2, classBarY, classBarW, barH5), const Radius.circular(3)),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.75));
    // c limit marker
    final cMarkX = barL2 + (1.0 / barMaxW) * barW7;
    canvas.drawLine(Offset(cMarkX, classBarY - 2), Offset(cMarkX, classBarY + barH5 + 2),
        Paint()..color = const Color(0xFFFFD700)..strokeWidth = 1.5);
    _lbl(canvas, '고전 w=${classical.toStringAsFixed(3)}c', Offset(barL2 + barW7 / 2, classBarY + barH5 / 2),
        const Color(0xFFE0F4FF), 9);
    if (classical > 1.0) {
      _lbl(canvas, '광속 초과!', Offset(classBarW + barL2 + 16, classBarY + barH5 / 2),
          const Color(0xFFFF3333), 8, fw: FontWeight.bold);
    }

    // Relativistic bar
    final relBarY = classBarY + barH5 + 10;
    final relBarW = (relativistic / barMaxW).clamp(0.0, 1.0) * barW7;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(barL2, relBarY, barW7, barH5), const Radius.circular(3)),
        Paint()..color = const Color(0xFF1A3040));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(barL2, relBarY, relBarW, barH5), const Radius.circular(3)),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.8));
    canvas.drawLine(Offset(cMarkX, relBarY - 2), Offset(cMarkX, relBarY + barH5 + 2),
        Paint()..color = const Color(0xFFFFD700)..strokeWidth = 1.5);
    _lbl(canvas, '상대론 w=${relativistic.toStringAsFixed(3)}c', Offset(barL2 + barW7 / 2, relBarY + barH5 / 2),
        const Color(0xFFE0F4FF), 9);

    // Difference
    final diffY = relBarY + barH5 + 18;
    final diff = (classical - relativistic);
    _lbl(canvas, '차이: ${diff.toStringAsFixed(3)}c  (${(diff / classical * 100).toStringAsFixed(1)}%)',
        Offset(w / 2, diffY), const Color(0xFF64FF8C), 9);

    // Formula
    _lbl(canvas, "w = (v₁+v₂) / (1 + v₁v₂/c²)", Offset(w / 2, h - 8),
        const Color(0xFF5A8A9A), 9, fw: FontWeight.bold);
  }

  @override
  bool shouldRepaint(covariant _VelocityAdditionScreenPainter oldDelegate) => true;
}
