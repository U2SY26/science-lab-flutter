import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BinaryStarScreen extends StatefulWidget {
  const BinaryStarScreen({super.key});
  @override
  State<BinaryStarScreen> createState() => _BinaryStarScreenState();
}

class _BinaryStarScreenState extends State<BinaryStarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _massRatio = 0.5;
  double _separation = 1;
  double _period = 1.0, _v1 = 0.0, _v2 = 0.0;

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
      _period = math.pow(_separation, 1.5).toDouble() / math.sqrt(1 + _massRatio);
      _v1 = 2 * math.pi * _separation * _massRatio / (_period * (1 + _massRatio));
      _v2 = _v1 / _massRatio;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _massRatio = 0.5; _separation = 1.0;
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
          const Text('쌍성계', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '쌍성계',
          formula: 'P² = (4π²/G(M₁+M₂))a³',
          formulaDescription: '쌍성계의 궤도 운동을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BinaryStarScreenPainter(
                time: _time,
                massRatio: _massRatio,
                separationDist: _separation,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '질량 비 (M₂/M₁)',
                value: _massRatio,
                min: 0.1,
                max: 1,
                step: 0.05,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _massRatio = v),
              ),
              advancedControls: [
            SimSlider(
                label: '분리 거리 (AU)',
                value: _separation,
                min: 0.1,
                max: 10,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' AU',
                onChanged: (v) => setState(() => _separation = v),
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
          _V('주기', _period.toStringAsFixed(2) + ' yr'),
          _V('v₁', _v1.toStringAsFixed(2) + ' AU/yr'),
          _V('v₂', _v2.toStringAsFixed(2) + ' AU/yr'),
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

class _BinaryStarScreenPainter extends CustomPainter {
  final double time;
  final double massRatio;
  final double separationDist;

  _BinaryStarScreenPainter({
    required this.time,
    required this.massRatio,
    required this.separationDist,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // Layout: top 65% = orbit view, bottom 35% = light curve
    final orbitH = size.height * 0.62;
    final lcTop = orbitH + 4;
    final lcH = size.height - lcTop - 6;

    // Background stars
    final rng = math.Random(31);
    for (int i = 0; i < 35; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * orbitH;
      canvas.drawCircle(Offset(sx, sy), rng.nextDouble() * 0.9 + 0.2,
          Paint()..color = Colors.white.withValues(alpha: rng.nextDouble() * 0.4 + 0.15));
    }

    // Masses: M1=1.0, M2=massRatio
    final m1 = 1.0;
    final m2 = massRatio;
    final totalM = m1 + m2;

    // Orbital scale
    final scaleAU = math.min(size.width, orbitH) * 0.32 / separationDist.clamp(0.1, 10.0);
    final sepPx = separationDist * scaleAU;

    // Center of mass
    final comX = size.width / 2;
    final comY = orbitH * 0.48;

    // Orbital period (Kepler 3rd law in AU, Msun, yr units)
    final period = math.pow(separationDist, 1.5) / math.sqrt(totalM);
    final angVel = 2 * math.pi / period;
    final angle = time * angVel * 0.3;

    // Positions relative to COM
    final r1 = sepPx * m2 / totalM;
    final r2 = sepPx * m1 / totalM;
    final x1 = comX + r1 * math.cos(angle + math.pi);
    final y1 = comY + r1 * math.sin(angle + math.pi) * 0.45; // tilt for 3D feel
    final x2 = comX + r2 * math.cos(angle);
    final y2 = comY + r2 * math.sin(angle) * 0.45;

    // Draw orbital ellipses (trails)
    final orbit1Paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.18)
      ..strokeWidth = 1.0..style = PaintingStyle.stroke;
    final orbit2Paint = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.18)
      ..strokeWidth = 1.0..style = PaintingStyle.stroke;
    canvas.drawOval(Rect.fromCenter(center: Offset(comX, comY), width: r1 * 2, height: r1 * 0.9), orbit1Paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(comX, comY), width: r2 * 2, height: r2 * 0.9), orbit2Paint);

    // COM marker
    canvas.drawCircle(Offset(comX, comY), 2.5,
        Paint()..color = Colors.white.withValues(alpha: 0.4));

    // Roche lobe approximation (egg-shaped contours around each star)
    _drawRocheLobe(canvas, Offset(x1, y1), Offset(x2, y2), r1 * 0.55, const Color(0xFF00D4FF));
    _drawRocheLobe(canvas, Offset(x2, y2), Offset(x1, y1), r2 * 0.55 * m2, const Color(0xFFFF6B35));

    // Trail dots (recent positions)
    for (int i = 1; i <= 12; i++) {
      final a = angle + math.pi - i * 0.22;
      final tx1 = comX + r1 * math.cos(a + math.pi);
      final ty1 = comY + r1 * math.sin(a + math.pi) * 0.45;
      final tx2 = comX + r2 * math.cos(a);
      final ty2 = comY + r2 * math.sin(a) * 0.45;
      final alpha = (1 - i / 12) * 0.35;
      canvas.drawCircle(Offset(tx1, ty1), 1.5, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: alpha));
      canvas.drawCircle(Offset(tx2, ty2), 1.5, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: alpha));
    }

    // Star 1 (larger, cyan)
    final r1Vis = (5 + m1 * 7).clamp(5.0, 18.0);
    canvas.drawCircle(Offset(x1, y1), r1Vis + 4,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(Offset(x1, y1), r1Vis,
        Paint()..color = const Color(0xFFCCEEFF));
    _drawLabel(canvas, 'M₁', Offset(x1 - 8, y1 - r1Vis - 14), const Color(0xFF00D4FF), 9, bold: true);

    // Star 2 (smaller, orange)
    final r2Vis = (4 + m2 * 6).clamp(4.0, 14.0);
    canvas.drawCircle(Offset(x2, y2), r2Vis + 3,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(x2, y2), r2Vis,
        Paint()..color = const Color(0xFFFF9966));
    _drawLabel(canvas, 'M₂', Offset(x2 - 8, y2 - r2Vis - 14), const Color(0xFFFF6B35), 9, bold: true);

    // Doppler shift indicator arrows
    final vel1x = -math.sin(angle + math.pi);
    final vel2x = -math.sin(angle);
    final dopplerStr1 = vel1x > 0 ? '→ 청색편이' : '← 적색편이';
    final dopplerStr2 = vel2x > 0 ? '→ 청색편이' : '← 적색편이';
    _drawLabel(canvas, dopplerStr1, Offset(x1 - 20, y1 + r1Vis + 4),
        vel1x > 0 ? const Color(0xFF6688FF) : const Color(0xFFFF4444), 7);
    _drawLabel(canvas, dopplerStr2, Offset(x2 - 20, y2 + r2Vis + 4),
        vel2x > 0 ? const Color(0xFF6688FF) : const Color(0xFFFF4444), 7);

    // ---- Light Curve (eclipse binary) ----
    canvas.drawRect(Rect.fromLTWH(0, lcTop, size.width, size.height - lcTop),
        Paint()..color = const Color(0xFF050D12));

    final lcPadL = 10.0;
    final lcPadR = 10.0;
    final lcW = size.width - lcPadL - lcPadR;
    _drawLabel(canvas, '광도 곡선 (식쌍성)', Offset(size.width / 2 - 30, lcTop + 2), const Color(0xFF5A8A9A), 8);

    // Axis line
    canvas.drawLine(Offset(lcPadL, lcTop + lcH * 0.15), Offset(lcPadL + lcW, lcTop + lcH * 0.15),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5);

    // Light curve: eclipses at phase 0 (primary) and 0.5 (secondary)
    final lcPath = Path();
    for (int i = 0; i <= 200; i++) {
      final phase = i / 200.0; // 0 to 1
      double lum = 1.0;
      // Primary eclipse at phase 0 (deeper)
      final d1 = math.min((phase).abs(), (1 - phase).abs());
      if (d1 < 0.12) {
        final depth = massRatio * 0.35;
        lum -= depth * math.max(0, 1 - (d1 / 0.12) * (d1 / 0.12));
      }
      // Secondary eclipse at phase 0.5
      final d2 = (phase - 0.5).abs();
      if (d2 < 0.10) {
        final depth2 = massRatio * 0.18;
        lum -= depth2 * math.max(0, 1 - (d2 / 0.10) * (d2 / 0.10));
      }
      final px = lcPadL + phase * lcW;
      final py = lcTop + lcH * 0.15 + (1 - lum) * lcH * 0.75;
      if (i == 0) { lcPath.moveTo(px, py); } else { lcPath.lineTo(px, py); }
    }
    canvas.drawPath(lcPath,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.85)
          ..strokeWidth = 1.6..style = PaintingStyle.stroke);

    // Time marker on light curve
    final lcPhase = (angle / (2 * math.pi)) % 1.0;
    final markerX = lcPadL + lcPhase * lcW;
    canvas.drawLine(Offset(markerX, lcTop + 2), Offset(markerX, lcTop + lcH),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)..strokeWidth = 1.2);
  }

  void _drawRocheLobe(Canvas canvas, Offset star, Offset other, double approxR, Color color) {
    // Approximate Roche lobe as slightly elongated ellipse toward the companion
    final dx = other.dx - star.dx;
    final dy = other.dy - star.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return;
    final angle = math.atan2(dy, dx);
    canvas.save();
    canvas.translate(star.dx, star.dy);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(approxR * 0.15, 0), width: approxR * 2.3, height: approxR * 1.6),
      Paint()..color = color.withValues(alpha: 0.08)..style = PaintingStyle.stroke..strokeWidth = 0.8,
    );
    canvas.restore();
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
  bool shouldRepaint(covariant _BinaryStarScreenPainter oldDelegate) => true;
}
