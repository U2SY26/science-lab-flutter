import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class PenroseDiagramScreen extends StatefulWidget {
  const PenroseDiagramScreen({super.key});
  @override
  State<PenroseDiagramScreen> createState() => _PenroseDiagramScreenState();
}

class _PenroseDiagramScreenState extends State<PenroseDiagramScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _compactParam = 1;
  
  double _timelikeRange = 1.0, _spacelikeRange = 1.0;

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
      _timelikeRange = math.atan(_compactParam * 5) * 2 / math.pi;
      _spacelikeRange = _timelikeRange;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _compactParam = 1.0;
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
          const Text('펜로즈 다이어그램', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '펜로즈 다이어그램',
          formula: 'Conformal compactification',
          formulaDescription: '펜로즈 다이어그램으로 시공간의 인과 구조를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PenroseDiagramScreenPainter(
                time: _time,
                compactParam: _compactParam,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '압축 매개변수',
                value: _compactParam,
                min: 0.1,
                max: 3,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _compactParam = v),
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
          _V('시간적', _timelikeRange.toStringAsFixed(3)),
          _V('공간적', _spacelikeRange.toStringAsFixed(3)),
          _V('압축', _compactParam.toStringAsFixed(1)),
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

class _PenroseDiagramScreenPainter extends CustomPainter {
  final double time;
  final double compactParam;

  _PenroseDiagramScreenPainter({
    required this.time,
    required this.compactParam,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // The Penrose diagram for a Schwarzschild black hole is a square rotated 45°.
    // We draw it as a diamond in the canvas center.
    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = math.min(size.width, size.height) * 0.42;

    // Diamond corners: right(I), top(II future singularity), left(III past), bottom(IV)
    final ptRight = Offset(cx + half, cy);       // i⁰  (spatial infinity, region I)
    final ptTop   = Offset(cx, cy - half);       // i+ future singularity / future timelike inf
    final ptLeft  = Offset(cx - half, cy);       // i⁰  (region III/IV)
    final ptBot   = Offset(cx, cy + half);       // i- past singularity / past timelike inf
    final ptCenter = Offset(cx, cy);             // bifurcation sphere

    void drawText(String txt, Offset pos,
        {Color color = const Color(0xFF5A8A9A), double fs = 8}) {
      final tp = TextPainter(
        text: TextSpan(text: txt, style: TextStyle(color: color, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    // --- Fill four regions ---
    // Region I (right): exterior — cyan tint
    final regionI = Path()
      ..moveTo(ptRight.dx, ptRight.dy)
      ..lineTo(ptTop.dx, ptTop.dy)
      ..lineTo(ptCenter.dx, ptCenter.dy)
      ..lineTo(ptBot.dx, ptBot.dy)
      ..close();
    canvas.drawPath(regionI,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.07));

    // Region II (top): future interior (black hole) — dark orange
    final regionIISimple = Path()
      ..moveTo(ptTop.dx, ptTop.dy)
      ..lineTo(ptLeft.dx, ptLeft.dy)
      ..lineTo(ptCenter.dx, ptCenter.dy)
      ..lineTo(ptRight.dx, ptRight.dy)
      ..close();
    canvas.drawPath(regionIISimple,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.09));

    // Region III (left): white hole interior — bottom-left triangle
    final regionIIIPath = Path()
      ..moveTo(ptBot.dx, ptBot.dy)
      ..lineTo(ptLeft.dx, ptLeft.dy)
      ..lineTo(ptCenter.dx, ptCenter.dy)
      ..close();
    canvas.drawPath(regionIIIPath,
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.10));

    // Region IV (bottom-right): anti-universe
    final regionIVPath = Path()
      ..moveTo(ptBot.dx, ptBot.dy)
      ..lineTo(ptRight.dx, ptRight.dy)
      ..lineTo(ptCenter.dx, ptCenter.dy)
      ..close();
    canvas.drawPath(regionIVPath,
        Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.05));

    // --- Singularity lines at top and bottom ---
    // Future singularity: wavy line at top (region II ceiling)
    final singPaint = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final singPath = Path();
    // Future singularity line: horizontal wavy stripe just inside top corner
    final singY = ptTop.dy + half * 0.05;
    final singHalfW = half * 0.45;
    singPath.moveTo(cx - singHalfW, singY);
    for (int i = 0; i <= 20; i++) {
      final t = i / 20.0;
      final wx = cx - singHalfW + 2 * singHalfW * t;
      final wy = singY + math.sin(t * math.pi * 8 + time * 3) * 3;
      singPath.lineTo(wx, wy);
    }
    canvas.drawPath(singPath, singPaint);
    drawText('미래 특이점', Offset(cx - 26, ptTop.dy + 4),
        color: const Color(0xFFFF6B35), fs: 7);

    // Past singularity (bottom)
    final singPath2 = Path();
    final singY2 = ptBot.dy - half * 0.05;
    singPath2.moveTo(cx - singHalfW, singY2);
    for (int i = 0; i <= 20; i++) {
      final t = i / 20.0;
      final wx = cx - singHalfW + 2 * singHalfW * t;
      final wy = singY2 - math.sin(t * math.pi * 8 + time * 3) * 3;
      singPath2.lineTo(wx, wy);
    }
    canvas.drawPath(singPath2, singPaint..color = const Color(0xFF5A8A9A).withValues(alpha: 0.7));
    drawText('과거 특이점', Offset(cx - 24, ptBot.dy - 16),
        color: const Color(0xFF5A8A9A), fs: 7);

    // --- Diamond border (outer boundary) ---
    final borderPath = Path()
      ..moveTo(ptRight.dx, ptRight.dy)
      ..lineTo(ptTop.dx, ptTop.dy)
      ..lineTo(ptLeft.dx, ptLeft.dy)
      ..lineTo(ptBot.dx, ptBot.dy)
      ..close();
    canvas.drawPath(
        borderPath,
        Paint()
          ..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke);

    // --- Event horizons: diagonal lines through center ---
    // Future EH: ptLeft → ptRight via ptTop direction (45° lines)
    final ehPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    // H+: from ptLeft to ptRight going through top half
    canvas.drawLine(ptLeft, ptRight, ehPaint); // horizontal through center
    // V: from ptBot to ptTop going through center
    canvas.drawLine(ptBot, ptTop,
        Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)
          ..strokeWidth = 1.5);

    // Event horizon labels
    drawText('H⁺', Offset(cx + 6, cy - 12), color: const Color(0xFF00D4FF), fs: 8);
    drawText('H⁻', Offset(cx + 6, cy + 4), color: const Color(0xFF00D4FF), fs: 8);

    // --- Light cone (±45° lines) at a point in region I ---
    final lcX = cx + half * 0.45;
    final lcY = cy + half * 0.1;
    final lcSize = half * 0.15;
    canvas.drawLine(Offset(lcX, lcY), Offset(lcX - lcSize, lcY - lcSize),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..strokeWidth = 1.0);
    canvas.drawLine(Offset(lcX, lcY), Offset(lcX + lcSize, lcY - lcSize),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..strokeWidth = 1.0);

    // --- Worldline: infalling observer (animated) ---
    final wlProgress = (time * 0.15) % 1.0;
    // Path: starts at right edge, moves inward toward top (crosses H+, hits singularity)
    final wlStartX = ptRight.dx - half * 0.05;
    final wlStartY = ptRight.dy + half * 0.1;
    final wlEndX = cx;
    final wlEndY = ptTop.dy + half * 0.06;
    final wlPath = Path();
    wlPath.moveTo(wlStartX, wlStartY);
    // Curve upward and left
    wlPath.cubicTo(
      wlStartX - half * 0.3, wlStartY - half * 0.1,
      cx + half * 0.2, cy - half * 0.3,
      wlEndX, wlEndY,
    );
    canvas.drawPath(wlPath,
        Paint()
          ..color = const Color(0xFF64FF8C).withValues(alpha: 0.5)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke);
    // Animated particle on worldline
    final wlX = wlStartX + (wlEndX - wlStartX) * wlProgress;
    final wlY = wlStartY + (wlEndY - wlStartY) * wlProgress
        - half * 0.15 * math.sin(wlProgress * math.pi);
    canvas.drawCircle(Offset(wlX, wlY), 4,
        Paint()..color = const Color(0xFF64FF8C));

    // --- Corner labels ---
    drawText('i⁰', Offset(ptRight.dx + 3, ptRight.dy - 6), color: const Color(0xFF5A8A9A), fs: 9);
    drawText('i⁰', Offset(ptLeft.dx - 14, ptLeft.dy - 6), color: const Color(0xFF5A8A9A), fs: 9);
    drawText('i⁺', Offset(ptTop.dx + 3, ptTop.dy - 12), color: const Color(0xFFFF6B35), fs: 9);
    drawText('i⁻', Offset(ptBot.dx + 3, ptBot.dy + 4), color: const Color(0xFF5A8A9A), fs: 9);

    // Region labels
    drawText('I\n외부', Offset(cx + half * 0.5 - 8, cy - 10),
        color: const Color(0xFF00D4FF), fs: 8);
    drawText('II\n블랙홀', Offset(cx - 14, cy - half * 0.55),
        color: const Color(0xFFFF6B35), fs: 8);
    drawText('III\n화이트홀', Offset(cx - half * 0.55 - 4, cy - 10),
        color: const Color(0xFF5A8A9A), fs: 8);
    drawText('IV\n반우주', Offset(cx - 12, cy + half * 0.38),
        color: const Color(0xFF64FF8C), fs: 8);

    // Null infinity labels
    drawText('ℐ⁺', Offset(cx + half * 0.3, ptTop.dy + half * 0.18),
        color: const Color(0xFF00D4FF).withValues(alpha: 0.7), fs: 8);
    drawText('ℐ⁻', Offset(cx + half * 0.3, ptBot.dy - half * 0.28),
        color: const Color(0xFF5A8A9A).withValues(alpha: 0.7), fs: 8);
  }

  @override
  bool shouldRepaint(covariant _PenroseDiagramScreenPainter oldDelegate) => true;
}
