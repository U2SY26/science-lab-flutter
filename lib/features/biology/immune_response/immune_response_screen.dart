import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ImmuneResponseScreen extends StatefulWidget {
  const ImmuneResponseScreen({super.key});
  @override
  State<ImmuneResponseScreen> createState() => _ImmuneResponseScreenState();
}

class _ImmuneResponseScreenState extends State<ImmuneResponseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _pathogenLoad = 100;
  
  double _innate = 50, _adaptive = 0, _pathogen = 100;

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
      _innate = 50 * (1 + math.sin(_time * 0.5));
      _adaptive = 100 * (1 - math.exp(-_time * 0.3));
      _pathogen = _pathogenLoad * math.exp(-(_innate + _adaptive) * 0.001 * _time);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _pathogenLoad = 100.0;
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
          const Text('면역 반응', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '면역 반응',
          formula: 'Innate + Adaptive',
          formulaDescription: '선천 면역과 적응 면역 반응을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ImmuneResponseScreenPainter(
                time: _time,
                pathogenLoad: _pathogenLoad,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '병원체 부하',
                value: _pathogenLoad,
                min: 1,
                max: 1000,
                step: 10,
                defaultValue: 100,
                formatValue: (v) => v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _pathogenLoad = v),
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
          _V('선천', _innate.toStringAsFixed(0)),
          _V('적응', _adaptive.toStringAsFixed(0)),
          _V('병원체', _pathogen.toStringAsFixed(0)),
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

class _ImmuneResponseScreenPainter extends CustomPainter {
  final double time;
  final double pathogenLoad;

  _ImmuneResponseScreenPainter({
    required this.time,
    required this.pathogenLoad,
  });

  void _lbl(Canvas canvas, String text, Offset pos, Color color, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  // Draw a hexagon (antigen shape)
  void _drawHexagon(Canvas canvas, Offset center, double r, Color color, bool filled) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = math.pi / 6 + i * math.pi / 3;
      final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      if (i == 0) { path.moveTo(p.dx, p.dy); } else { path.lineTo(p.dx, p.dy); }
    }
    path.close();
    if (filled) {
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.35));
    }
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  // Draw Y-shaped antibody
  void _drawAntibody(Canvas canvas, Offset base, double size, Color color) {
    final stemEnd = Offset(base.dx, base.dy - size * 0.4);
    canvas.drawLine(base, stemEnd, Paint()..color = color..strokeWidth = 2);
    final leftArm = Offset(stemEnd.dx - size * 0.35, stemEnd.dy - size * 0.4);
    final rightArm = Offset(stemEnd.dx + size * 0.35, stemEnd.dy - size * 0.4);
    canvas.drawLine(stemEnd, leftArm, Paint()..color = color..strokeWidth = 2);
    canvas.drawLine(stemEnd, rightArm, Paint()..color = color..strokeWidth = 2);
    canvas.drawCircle(leftArm, 3, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawCircle(rightArm, 3, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Layout: upper 55% = immune cell diagram, lower 45% = antibody titer graph
    final diagBottom = h * 0.56;
    final graphTop = diagBottom + 6;

    // ── Upper: Immune cell diagram ──────────────────────────────────────
    // Columns: Antigen | Macrophage | B cell/Plasma | T cell
    final col1 = w * 0.12; // antigen
    final col2 = w * 0.38; // macrophage
    final col3 = w * 0.65; // plasma cell / antibody
    final col4 = w * 0.88; // T cell
    final midY = diagBottom * 0.52;

    // Antigens (hexagons) entering from left
    final antigenCount = (pathogenLoad / 100 * 4).clamp(1, 5).toInt();
    for (int i = 0; i < antigenCount; i++) {
      final ax = col1 + math.sin(time * 0.8 + i) * 8;
      final ay = midY - 24 + i * 14.0;
      _drawHexagon(canvas, Offset(ax, ay), 7, const Color(0xFFFF4444), true);
    }
    _lbl(canvas, '항원', Offset(col1, diagBottom * 0.88), const Color(0xFFFF4444), 8);

    // Arrow antigen → macrophage
    canvas.drawLine(Offset(col1 + 12, midY), Offset(col2 - 22, midY),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.2);
    final arr1 = Path()
      ..moveTo(col2 - 22, midY)
      ..lineTo(col2 - 30, midY - 4)
      ..lineTo(col2 - 30, midY + 4)
      ..close();
    canvas.drawPath(arr1, Paint()..color = const Color(0xFF5A8A9A)..style = PaintingStyle.fill);

    // Macrophage (large circle with pseudopods)
    final macR = 22.0;
    canvas.drawCircle(Offset(col2, midY), macR, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.2));
    canvas.drawCircle(Offset(col2, midY), macR, Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.stroke..strokeWidth = 2);
    // Pseudopods
    for (int i = 0; i < 6; i++) {
      final a = time * 0.4 + i * math.pi / 3;
      final px = col2 + (macR + 6) * math.cos(a);
      final py = midY + (macR + 6) * math.sin(a);
      canvas.drawCircle(Offset(px, py), 4, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.55));
    }
    // MHC flag on macrophage
    canvas.drawLine(Offset(col2 + 2, midY - macR), Offset(col2 + 2, midY - macR - 10),
        Paint()..color = const Color(0xFFFFD700)..strokeWidth = 1.5);
    canvas.drawRect(Rect.fromLTWH(col2 + 2, midY - macR - 10, 10, 6),
        Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.7));
    _lbl(canvas, 'MHC', Offset(col2 + 9, midY - macR - 7), const Color(0xFFFFD700), 6);
    _lbl(canvas, '대식세포', Offset(col2, diagBottom * 0.88), const Color(0xFFFF6B35), 8);

    // Arrow macrophage → plasma cell
    canvas.drawLine(Offset(col2 + macR + 2, midY), Offset(col3 - 20, midY),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.2);
    final arr2 = Path()
      ..moveTo(col3 - 20, midY)
      ..lineTo(col3 - 28, midY - 4)
      ..lineTo(col3 - 28, midY + 4)
      ..close();
    canvas.drawPath(arr2, Paint()..color = const Color(0xFF5A8A9A)..style = PaintingStyle.fill);

    // B cell / Plasma cell
    final bcR = 16.0;
    canvas.drawCircle(Offset(col3, midY), bcR, Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.2));
    canvas.drawCircle(Offset(col3, midY), bcR, Paint()..color = const Color(0xFF64FF8C)..style = PaintingStyle.stroke..strokeWidth = 1.8);
    _lbl(canvas, 'B', Offset(col3, midY), const Color(0xFF64FF8C), 10);
    _lbl(canvas, '형질세포', Offset(col3, diagBottom * 0.88), const Color(0xFF64FF8C), 8);

    // Antibodies emitted from plasma cell (animated)
    final adaptiveProgress = (1 - math.exp(-time * 0.25)).clamp(0.0, 1.0);
    final abCount = (adaptiveProgress * 4).toInt() + 1;
    for (int i = 0; i < abCount; i++) {
      final t2 = (time * 0.5 + i * 0.3) % 1.0;
      final abX = col3 + 18 + t2 * 28;
      final abY = midY - 16 + i * 12.0;
      _drawAntibody(canvas, Offset(abX, abY + 8), 14, const Color(0xFF00D4FF).withValues(alpha: (1.0 - t2) * 0.9 + 0.1));
    }

    // T cell (cytotoxic)
    final tcR = 14.0;
    canvas.drawCircle(Offset(col4, midY), tcR, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.2));
    canvas.drawCircle(Offset(col4, midY), tcR, Paint()..color = const Color(0xFF00D4FF)..style = PaintingStyle.stroke..strokeWidth = 1.8);
    _lbl(canvas, 'T', Offset(col4, midY), const Color(0xFF00D4FF), 10);
    _lbl(canvas, '세포독성 T', Offset(col4, diagBottom * 0.88), const Color(0xFF00D4FF), 7.5);

    // Memory cell (small, bottom area)
    canvas.drawCircle(Offset(col3 - 10, diagBottom * 0.72), 8,
        Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.15));
    canvas.drawCircle(Offset(col3 - 10, diagBottom * 0.72), 8,
        Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    _lbl(canvas, 'M', Offset(col3 - 10, diagBottom * 0.72), const Color(0xFFFFD700), 7);
    _lbl(canvas, '기억세포', Offset(col3 + 18, diagBottom * 0.72), const Color(0xFFFFD700), 7);

    // Divider
    canvas.drawLine(Offset(0, diagBottom), Offset(w, diagBottom),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    // ── Lower: Antibody titer graph ──────────────────────────────────────
    final gLeft = 32.0;
    final gRight = w - 10.0;
    final gBottom = h - 18.0;
    final gTop = graphTop + 4;
    final gW = gRight - gLeft;
    final gH = gBottom - gTop;

    // Axes
    canvas.drawLine(Offset(gLeft, gTop), Offset(gLeft, gBottom), Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);
    canvas.drawLine(Offset(gLeft, gBottom), Offset(gRight, gBottom), Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);
    _lbl(canvas, '항체 역가', Offset(gLeft - 12, gTop + gH / 2), const Color(0xFF5A8A9A), 7);
    _lbl(canvas, '시간 (일)', Offset(gLeft + gW / 2, gBottom + 10), const Color(0xFF5A8A9A), 7);

    // Primary response curve
    final primPath = Path();
    final secondPath = Path();
    for (int i = 0; i <= 100; i++) {
      final tx = i / 100.0;
      final x = gLeft + tx * gW;
      // Primary: slow rise, decay
      double pv = 0;
      if (tx > 0.05) { pv = math.exp(-(tx - 0.3) * (tx - 0.3) / 0.025) * 0.55; }
      // Secondary (2nd exposure at tx=0.55): faster, higher
      double sv = 0;
      if (tx > 0.55) { sv = math.exp(-(tx - 0.78) * (tx - 0.78) / 0.012) * 0.95; }
      final yP = gBottom - pv * gH;
      final yS = gBottom - sv * gH;
      if (i == 0) {
        primPath.moveTo(x, yP);
        secondPath.moveTo(x, yS);
      } else {
        primPath.lineTo(x, yP);
        secondPath.lineTo(x, yS);
      }
    }
    canvas.drawPath(primPath, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    canvas.drawPath(secondPath, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Legends
    canvas.drawLine(Offset(gLeft + gW * 0.04, gTop + 7), Offset(gLeft + gW * 0.12, gTop + 7),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5);
    _lbl(canvas, '1차 반응', Offset(gLeft + gW * 0.18, gTop + 7), const Color(0xFF00D4FF), 7.5);
    canvas.drawLine(Offset(gLeft + gW * 0.35, gTop + 7), Offset(gLeft + gW * 0.43, gTop + 7),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5);
    _lbl(canvas, '2차 반응', Offset(gLeft + gW * 0.49, gTop + 7), const Color(0xFFFF6B35), 7.5);

    // Title
    _lbl(canvas, '면역 반응 (Immune Response)', Offset(w / 2, 11), const Color(0xFF00D4FF), 10);
  }

  @override
  bool shouldRepaint(covariant _ImmuneResponseScreenPainter oldDelegate) => true;
}
