import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DarkMatterScreen extends StatefulWidget {
  const DarkMatterScreen({super.key});
  @override
  State<DarkMatterScreen> createState() => _DarkMatterScreenState();
}

class _DarkMatterScreenState extends State<DarkMatterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _darkMatterRatio = 5;
  double _rotVelocity = 0;

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
      _rotVelocity = 220 * math.sqrt(1 + _darkMatterRatio / 5);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _darkMatterRatio = 5;
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
          const Text('암흑 물질 증거', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '암흑 물질 증거',
          formula: 'v(r) = √(GM(r)/r)',
          formulaDescription: '암흑 물질에 대한 관측 증거를 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DarkMatterScreenPainter(
                time: _time,
                darkMatterRatio: _darkMatterRatio,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '암흑 물질 비율',
                value: _darkMatterRatio,
                min: 0,
                max: 10,
                step: 0.5,
                defaultValue: 5,
                formatValue: (v) => '${v.toStringAsFixed(1)}x',
                onChanged: (v) => setState(() => _darkMatterRatio = v),
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
          _V('회전 속도', '${_rotVelocity.toStringAsFixed(0)} km/s'),
          _V('DM 비율', '${_darkMatterRatio.toStringAsFixed(1)}x'),
          _V('시간', _time.toStringAsFixed(1)),
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

class _DarkMatterScreenPainter extends CustomPainter {
  final double time;
  final double darkMatterRatio;

  _DarkMatterScreenPainter({
    required this.time,
    required this.darkMatterRatio,
  });

  void _label(Canvas canvas, String text, Offset pos, {double fs = 8, Color col = const Color(0xFF5A8A9A), bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? pos.dx - tp.width / 2 : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // --- Left panel: gravitational lensing image ---
    final lensW = w * 0.48;
    final lensCx = lensW / 2;
    final lensCy = h * 0.35;
    final lensR = math.min(lensW, h * 0.62) * 0.4;

    // Deep field background (random stars)
    final rng = math.Random(77);
    for (int i = 0; i < 80; i++) {
      final sx = rng.nextDouble() * lensW;
      final sy = rng.nextDouble() * h * 0.7;
      final sr = rng.nextDouble() * 1.5 + 0.3;
      canvas.drawCircle(Offset(sx, sy),
          sr, Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: rng.nextDouble() * 0.5 + 0.2));
    }

    // Dark matter halo (diffuse blue-purple ring)
    final haloR = lensR * (1.5 + darkMatterRatio * 0.2);
    for (int ring = 4; ring >= 0; ring--) {
      final rr = haloR * (0.6 + ring * 0.1);
      canvas.drawCircle(Offset(lensCx, lensCy), rr,
          Paint()..color = const Color(0xFF3344AA).withValues(alpha: 0.04 * darkMatterRatio));
    }
    _label(canvas, '암흑 물질 헤일로', Offset(lensCx, lensCy - haloR - 10), fs: 7,
        col: const Color(0xFF8899FF), center: true);

    // Galaxy cluster (bright points)
    canvas.drawCircle(Offset(lensCx, lensCy), lensR * 0.08,
        Paint()..color = const Color(0xFFFFFFCC)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi * 2 / 8 + time * 0.05;
      final r = lensR * 0.25 * (0.5 + rng.nextDouble() * 0.5);
      canvas.drawCircle(Offset(lensCx + r * math.cos(a), lensCy + r * math.sin(a)), 2.5,
          Paint()..color = const Color(0xFFFFEEAA).withValues(alpha: 0.9));
    }
    _label(canvas, '은하단', Offset(lensCx, lensCy + 6), fs: 7, col: const Color(0xFFFFEEAA), center: true);

    // Gravitational lensing arcs (background galaxies bent into arcs)
    final arcPaint = Paint()..color = const Color(0xFF88CCFF).withValues(alpha: 0.7)..strokeWidth = 2..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      final baseAngle = i * math.pi * 2 / 5 + time * 0.02;
      final arcRadius = lensR * (0.7 + darkMatterRatio * 0.08);
      final arcStart = baseAngle - 0.4;
      final arcEnd = baseAngle + 0.4;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(lensCx, lensCy), width: arcRadius * 2, height: arcRadius * 2 * 0.6),
        arcStart, arcEnd - arcStart, false, arcPaint,
      );
    }
    _label(canvas, '중력 렌즈 원호', Offset(2, h * 0.64), fs: 7, col: const Color(0xFF88CCFF));

    // Divider
    canvas.drawLine(Offset(lensW + 2, 4), Offset(lensW + 2, h * 0.72),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    // --- Right panel: rotation curve ---
    final rcLeft = lensW + 12;
    final rcRight = w - 8;
    final rcTop = 14.0;
    final rcH = h * 0.58;
    final rcBot = rcTop + rcH;
    final rcW = rcRight - rcLeft;

    canvas.drawLine(Offset(rcLeft, rcTop), Offset(rcLeft, rcBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(rcLeft, rcBot), Offset(rcRight, rcBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _label(canvas, 'v\n(km/s)', Offset(rcLeft - 12, rcTop), fs: 7);
    _label(canvas, 'r →', Offset(rcRight - 16, rcBot + 2), fs: 7);
    _label(canvas, '220', Offset(rcLeft - 24, rcTop + 4), fs: 7);

    // Keplerian prediction (falling off) — orange dashed
    final kepPath = Path();
    for (int px = 1; px <= rcW.toInt(); px++) {
      final r = px / rcW;
      final vKep = 0.95 * math.sqrt(1.0 / r); // falls off as 1/sqrt(r)
      final normV = vKep.clamp(0.0, 1.2);
      final y = rcBot - normV.clamp(0.0, 1.0) * rcH;
      final x = rcLeft + px.toDouble();
      if (px == 1) {
        kepPath.moveTo(x, y);
      } else {
        kepPath.lineTo(x, y);
      }
    }
    final dashKep = Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawPath(kepPath, dashKep);

    // Observed (flat) rotation curve — cyan solid
    final obsPath = Path();
    for (int px = 1; px <= rcW.toInt(); px++) {
      final r = px / rcW;
      // Flat beyond bulge, boosted by dark matter halo
      final vObs = r < 0.12 ? r / 0.12 : (0.95 + darkMatterRatio * 0.03);
      final normV = vObs.clamp(0.0, 1.2);
      final y = rcBot - normV.clamp(0.0, 1.0) * rcH;
      final x = rcLeft + px.toDouble();
      if (px == 1) {
        obsPath.moveTo(x, y);
      } else {
        obsPath.lineTo(x, y);
      }
    }
    canvas.drawPath(obsPath,
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2..style = PaintingStyle.stroke);

    // Legend
    canvas.drawLine(Offset(rcLeft + 4, rcTop + 8), Offset(rcLeft + 18, rcTop + 8),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2);
    _label(canvas, '관측값', Offset(rcLeft + 20, rcTop + 4), fs: 7, col: const Color(0xFF00D4FF));
    canvas.drawLine(Offset(rcLeft + 4, rcTop + 18), Offset(rcLeft + 18, rcTop + 18),
        dashKep);
    _label(canvas, '예측(암흑X)', Offset(rcLeft + 20, rcTop + 14), fs: 7, col: const Color(0xFFFF6B35));

    // NFW profile label
    final rcMid = (rcLeft + rcRight) / 2;
    _label(canvas, '은하 회전 곡선', Offset(rcMid, rcBot + 4), fs: 8, col: const Color(0xFFE0F4FF), center: true);
    _label(canvas, 'NFW ρ(r)∝1/r(1+r)²', Offset(rcLeft + 2, rcBot + 14), fs: 7, col: const Color(0xFF5A8A9A));

    // --- Bottom: DM ratio display ---
    final barY = h * 0.82;
    final barLeft = 16.0;
    final barW = w - 32;
    canvas.drawRect(Rect.fromLTWH(barLeft, barY, barW, 8),
        Paint()..color = const Color(0xFF1A3040));
    canvas.drawRect(Rect.fromLTWH(barLeft, barY, barW * darkMatterRatio / 10, 8),
        Paint()..color = const Color(0xFF3344AA).withValues(alpha: 0.8));
    canvas.drawRect(Rect.fromLTWH(barLeft, barY, barW, 8),
        Paint()..color = const Color(0xFF5A8A9A)..style = PaintingStyle.stroke..strokeWidth = 1);
    _label(canvas, '암흑 물질 비율 ${darkMatterRatio.toStringAsFixed(1)}x  |  우주의 ~27% 차지', Offset(barLeft, barY - 12), fs: 8, col: const Color(0xFF8899FF));
    _label(canvas, '총 질량 = 일반 물질 + 암흑 물질 헤일로', Offset(barLeft, barY + 10), fs: 7, col: const Color(0xFF5A8A9A));
  }

  @override
  bool shouldRepaint(covariant _DarkMatterScreenPainter oldDelegate) => true;
}
