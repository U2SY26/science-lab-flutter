import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class RocheLimitScreen extends StatefulWidget {
  const RocheLimitScreen({super.key});
  @override
  State<RocheLimitScreen> createState() => _RocheLimitScreenState();
}

class _RocheLimitScreenState extends State<RocheLimitScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _densityRatio = 2;
  
  double _rocheR = 2.46, _dist = 3.0;

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
      _rocheR = math.pow(2 * _densityRatio, 1/3).toDouble();
      _dist = _rocheR + 0.5 * math.sin(_time);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _densityRatio = 2.0;
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
          const Text('로슈 한계', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '로슈 한계',
          formula: 'd = R(2ρ_M/ρ_m)^(1/3)',
          formulaDescription: '로슈 한계와 위성의 조석 파괴를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _RocheLimitScreenPainter(
                time: _time,
                densityRatio: _densityRatio,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'ρ_M/ρ_m (밀도비)',
                value: _densityRatio,
                min: 0.1,
                max: 10,
                step: 0.1,
                defaultValue: 2,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _densityRatio = v),
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
          _V('로슈 한계', _rocheR.toStringAsFixed(3) + ' R'),
          _V('거리', _dist.toStringAsFixed(3) + ' R'),
          _V('상태', _dist < _rocheR ? '파괴' : '안전'),
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

class _RocheLimitScreenPainter extends CustomPainter {
  final double time;
  final double densityRatio;

  _RocheLimitScreenPainter({
    required this.time,
    required this.densityRatio,
  });

  void _label(Canvas canvas, String text, Offset pos, Color col, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // Roche limit in units of planet radius R_planet
    // d_Roche ≈ R_planet * (2 * rho_M / rho_m)^(1/3)
    // We normalise so planet R = 1 unit displayed as planetPx pixels
    final rocheMultiplier = math.pow(2 * densityRatio, 1.0 / 3.0).toDouble();

    // Layout: planet on left-centre, satellite orbits rightward
    final cx = size.width * 0.30;
    final cy = size.height * 0.46;
    final planetPx = math.min(size.width, size.height) * 0.095;

    // Scale: 1 unit = planetPx pixels
    // Max display range = 3.5 Roche units → maps to available right width
    final maxUnits = 3.5;
    final scale = (size.width * 0.65) / maxUnits; // px per unit
    final rochePx = rocheMultiplier * scale; // Roche limit distance in px

    // Oscillate satellite distance between 0.6 and 2.8 Roche units
    final satDist = rocheMultiplier * (0.85 + 0.85 * math.sin(time * 0.6));
    final satX = cx + satDist * scale;
    final satY = cy;
    final insideRoche = satDist < rocheMultiplier;

    // ── Background glow for planet ──
    canvas.drawCircle(
      Offset(cx, cy),
      planetPx * 1.6,
      Paint()
        ..color = const Color(0xFF1A3A6A).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ── Planet (Saturn-like with rings) ──
    // Ring
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: planetPx * 3.2,
          height: planetPx * 0.55),
      Paint()
        ..color = const Color(0xFFD4AA55).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: planetPx * 2.4,
          height: planetPx * 0.4),
      Paint()
        ..color = const Color(0xFFD4AA55).withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Planet body
    canvas.drawCircle(Offset(cx, cy), planetPx,
        Paint()..color = const Color(0xFF3A6EA5));
    canvas.drawCircle(
      Offset(cx, cy),
      planetPx,
      Paint()
        ..color = const Color(0xFF5A9EC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _label(canvas, '행성', Offset(cx - 10, cy + planetPx + 4),
        const Color(0xFF5A8A9A), 9);
    _label(canvas, '(토성)', Offset(cx - 12, cy + planetPx + 15),
        const Color(0xFF5A8A9A), 8);

    // ── Roche limit circle (dashed) ──
    final rochePaint = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dashCount = 36;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        final a1 = 2 * math.pi * i / dashCount;
        final a2 = 2 * math.pi * (i + 0.8) / dashCount;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: rochePx),
          a1,
          a2 - a1,
          false,
          rochePaint,
        );
      }
    }
    // Roche limit label
    _label(canvas, 'Roche 한계', Offset(cx + rochePx * 0.68, cy - rochePx - 12),
        const Color(0xFFFF6B35), 8);

    // ── Satellite or debris ──
    if (!insideRoche) {
      // Intact satellite
      canvas.drawCircle(
        Offset(satX, satY),
        7,
        Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
          Offset(satX, satY), 5, Paint()..color = const Color(0xFF00D4FF));
      _label(canvas, '위성', Offset(satX - 8, satY + 9),
          const Color(0xFF00D4FF), 8);
    } else {
      // Debris field — satellite broken apart
      final rng = math.Random(17);
      for (int i = 0; i < 14; i++) {
        final angle = rng.nextDouble() * 2 * math.pi;
        final dist = 3 + rng.nextDouble() * 14 + 4 * math.sin(time * 2 + i);
        final dx = dist * math.cos(angle);
        final dy = dist * math.sin(angle) * 0.3;
        canvas.drawCircle(
          Offset(satX + dx, satY + dy),
          1.2 + rng.nextDouble() * 2,
          Paint()
            ..color = const Color(0xFFFF6B35)
                .withValues(alpha: 0.5 + 0.5 * rng.nextDouble()),
        );
      }
      _label(canvas, '파괴!', Offset(satX - 12, satY - 20),
          const Color(0xFFFF6B35), 10);
    }

    // ── Tidal force arrows on satellite ──
    if (!insideRoche) {
      final tidalPaint = Paint()
        ..color = const Color(0xFF64FF8C).withValues(alpha: 0.7)
        ..strokeWidth = 1.5;
      // Arrow toward planet (tidal stretch)
      canvas.drawLine(Offset(satX - 6, satY), Offset(satX - 16, satY), tidalPaint);
      canvas.drawLine(Offset(satX + 6, satY), Offset(satX + 16, satY), tidalPaint);
    }

    // ── Force comparison bar chart (bottom section) ──
    final barTop = size.height * 0.72;
    final barH = size.height * 0.18;
    final barLeft = 12.0;
    final barWidth = size.width - 24;

    canvas.drawRect(
      Rect.fromLTWH(barLeft, barTop - 16, barWidth, barH + 20),
      Paint()..color = const Color(0xFF0A1520),
    );
    canvas.drawRect(
      Rect.fromLTWH(barLeft, barTop - 16, barWidth, barH + 20),
      Paint()
        ..color = const Color(0xFF1A3040)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    _label(canvas, '기조력 vs 자체 중력', Offset(barLeft + 6, barTop - 14),
        const Color(0xFF5A8A9A), 9);

    // Self-gravity is fixed; tidal force ∝ 1/d³
    final selfGrav = 0.6;
    final tidalForce =
        (rocheMultiplier / satDist).clamp(0.0, 1.2) * selfGrav * 1.1;

    final barY1 = barTop + 4;
    final barY2 = barTop + barH * 0.52;
    final maxBarW = barWidth - 60.0;

    // Self-gravity bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft + 52, barY1, maxBarW * selfGrav, 12),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.75),
    );
    _label(canvas, '자체 중력', Offset(barLeft + 4, barY1 + 1),
        const Color(0xFF00D4FF), 8);

    // Tidal force bar
    final tidalW = (maxBarW * tidalForce).clamp(0.0, maxBarW);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft + 52, barY2, tidalW, 12),
        const Radius.circular(3),
      ),
      Paint()
        ..color = (insideRoche ? const Color(0xFFFF6B35) : const Color(0xFF64FF8C))
            .withValues(alpha: 0.8),
    );
    _label(canvas, '기조력', Offset(barLeft + 4, barY2 + 1),
        insideRoche ? const Color(0xFFFF6B35) : const Color(0xFF64FF8C), 8);

    // Status label
    _label(
      canvas,
      insideRoche ? '기조력 > 자체 중력 → 파괴' : '자체 중력 우세 → 안전',
      Offset(barLeft + 6, barTop + barH * 0.9),
      insideRoche ? const Color(0xFFFF6B35) : const Color(0xFF00D4FF),
      9,
    );
  }

  @override
  bool shouldRepaint(covariant _RocheLimitScreenPainter oldDelegate) => true;
}
