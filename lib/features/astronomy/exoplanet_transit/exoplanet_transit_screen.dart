import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ExoplanetTransitScreen extends StatefulWidget {
  const ExoplanetTransitScreen({super.key});
  @override
  State<ExoplanetTransitScreen> createState() => _ExoplanetTransitScreenState();
}

class _ExoplanetTransitScreenState extends State<ExoplanetTransitScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _planetRadius = 1;
  
  double _transitDepth = 0.01, _starRadiusRatio = 0.01;

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
      _starRadiusRatio = _planetRadius * 0.009; // R_earth/R_sun ratio
      _transitDepth = _starRadiusRatio * _starRadiusRatio;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _planetRadius = 1.0;
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
          const Text('외계행성 통과법', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '외계행성 통과법',
          formula: 'ΔF/F = (R_p/R_s)²',
          formulaDescription: '외계행성 통과법을 이용한 행성 탐지를 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ExoplanetTransitScreenPainter(
                time: _time,
                planetRadius: _planetRadius,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '행성 반지름 (R⊕)',
                value: _planetRadius,
                min: 0.3,
                max: 15,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' R⊕',
                onChanged: (v) => setState(() => _planetRadius = v),
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
          _V('통과 깊이', (_transitDepth * 100).toStringAsFixed(4) + '%'),
          _V('Rp/Rs', _starRadiusRatio.toStringAsFixed(4)),
          _V('Rp', _planetRadius.toStringAsFixed(1) + ' R⊕'),
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

class _ExoplanetTransitScreenPainter extends CustomPainter {
  final double time;
  final double planetRadius;

  _ExoplanetTransitScreenPainter({
    required this.time,
    required this.planetRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // Layout: top 58% = transit scene, bottom 42% = light curve
    final sceneH = size.height * 0.56;
    final lcTop = sceneH + 4;
    final lcH = size.height - lcTop - 6;

    // Transit animation: planet moves across star
    // Phase 0→1 over a slow cycle; transit occurs at phase 0.3→0.7
    final phase = (time * 0.12) % 1.0;

    // Star parameters
    final starR = math.min(size.width, sceneH) * 0.28;
    final starCx = size.width / 2;
    final starCy = sceneH * 0.50;

    // Star with limb darkening (radial gradient from bright center to darker edge)
    final starPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFFFF),
          const Color(0xFFFFF0AA),
          const Color(0xFFFFDD66),
          const Color(0xFFFF8800),
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(starCx, starCy), radius: starR));
    canvas.drawCircle(Offset(starCx, starCy), starR, starPaint);
    // Glow
    canvas.drawCircle(Offset(starCx, starCy), starR + 8,
        Paint()..color = const Color(0xFFFFAA00).withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));

    // Planet radius in pixels (Rp/Rs = planetRadius*0.009, max visual scale)
    final rpFrac = (planetRadius * 0.009).clamp(0.01, 0.25);
    final planetR = starR * rpFrac * 6.0; // visual scale for visibility

    // Planet position: sweeps from left to right across star
    final transitStart = 0.25;
    final transitEnd = 0.75;
    final travelW = size.width * 0.85;
    final planetX = size.width * 0.075 + phase * travelW;
    final planetY = starCy + starR * 0.15; // slightly off-center

    // Shadow of planet on star (clip)
    canvas.save();
    final starClip = Path()..addOval(Rect.fromCircle(center: Offset(starCx, starCy), radius: starR));
    canvas.clipPath(starClip);
    canvas.drawCircle(Offset(planetX, planetY), planetR,
        Paint()..color = const Color(0xFF050D12));
    canvas.restore();

    // Planet body (visible outside star as dark disk)
    final isInFront = phase > transitStart && phase < transitEnd;
    if (!isInFront) {
      canvas.drawCircle(Offset(planetX, planetY), planetR,
          Paint()..color = const Color(0xFF203040));
      canvas.drawCircle(Offset(planetX, planetY), planetR,
          Paint()..color = const Color(0xFF406080).withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke..strokeWidth = 1.2);
    } else {
      // Atmosphere rim glow
      canvas.drawCircle(Offset(planetX, planetY), planetR + 3,
          Paint()..color = const Color(0xFF4488AA).withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(Offset(planetX, planetY), planetR,
          Paint()..color = const Color(0xFF1A2A3A));
    }

    // Ingress / Egress labels
    final ingressX = size.width * 0.075 + transitStart * travelW;
    final egressX = size.width * 0.075 + transitEnd * travelW;
    canvas.drawLine(Offset(ingressX, sceneH * 0.08), Offset(ingressX, sceneH * 0.92),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.35)..strokeWidth = 0.8
          ..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(egressX, sceneH * 0.08), Offset(egressX, sceneH * 0.92),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.35)..strokeWidth = 0.8
          ..style = PaintingStyle.stroke);
    _drawLabel(canvas, '입사', Offset(ingressX - 8, sceneH * 0.06), const Color(0xFF5A8A9A), 8);
    _drawLabel(canvas, '출사', Offset(egressX - 8, sceneH * 0.06), const Color(0xFF5A8A9A), 8);

    // Rp/Rs annotation
    final transitDepth = rpFrac * rpFrac;
    _drawLabel(canvas, 'Rp/Rs = ${rpFrac.toStringAsFixed(3)}',
        Offset(6, 6), const Color(0xFF00D4FF), 9, bold: true);
    _drawLabel(canvas, 'ΔF = ${(transitDepth * 100).toStringAsFixed(3)}%',
        Offset(6, 18), const Color(0xFF5A8A9A), 9);
    _drawLabel(canvas, 'Rp = ${planetRadius.toStringAsFixed(1)} R⊕',
        Offset(6, 30), const Color(0xFF5A8A9A), 8);

    // ---- Light Curve ----
    canvas.drawRect(Rect.fromLTWH(0, lcTop, size.width, size.height - lcTop),
        Paint()..color = const Color(0xFF050D12));

    final lcPadL = 32.0, lcPadR = 10.0;
    final lcW = size.width - lcPadL - lcPadR;
    _drawLabel(canvas, '광도 곡선', Offset(size.width / 2 - 14, lcTop + 2), const Color(0xFF5A8A9A), 8);

    // Y axis labels
    _drawLabel(canvas, '1.00', Offset(2, lcTop + 4), const Color(0xFF5A8A9A), 7);
    final depthLabel = (1 - transitDepth);
    _drawLabel(canvas, depthLabel.toStringAsFixed(3), Offset(2, lcTop + lcH * 0.72),
        const Color(0xFF5A8A9A), 7);

    // Baseline
    canvas.drawLine(Offset(lcPadL, lcTop + lcH * 0.12), Offset(lcPadL + lcW, lcTop + lcH * 0.12),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5);

    // Light curve path
    final lcPath = Path();
    for (int i = 0; i <= 300; i++) {
      final p2 = i / 300.0;
      double flux = 1.0;
      if (p2 > transitStart && p2 < transitEnd) {
        // Smooth ingress/egress with quadratic limb darkening effect
        final ingressDur = 0.04;
        final egressStart = transitEnd - ingressDur;
        if (p2 < transitStart + ingressDur) {
          final t2 = (p2 - transitStart) / ingressDur;
          flux = 1.0 - transitDepth * (t2 * t2);
        } else if (p2 > egressStart) {
          final t2 = (p2 - egressStart) / ingressDur;
          flux = 1.0 - transitDepth * ((1 - t2) * (1 - t2));
        } else {
          // Mid-transit: slight limb-darkening variation
          final midFrac = (p2 - (transitStart + ingressDur)) /
              (egressStart - (transitStart + ingressDur));
          final ldFactor = 1.0 - 0.15 * (1 - 4 * (midFrac - 0.5) * (midFrac - 0.5));
          flux = 1.0 - transitDepth * ldFactor;
        }
      }
      final px = lcPadL + p2 * lcW;
      final py = lcTop + lcH * 0.12 + (1 - flux) * lcH * 0.75;
      if (i == 0) { lcPath.moveTo(px, py); } else { lcPath.lineTo(px, py); }
    }
    canvas.drawPath(lcPath,
        Paint()..color = const Color(0xFFFFCC44).withValues(alpha: 0.9)
          ..strokeWidth = 1.8..style = PaintingStyle.stroke);

    // Current time marker
    final markerX = lcPadL + phase * lcW;
    canvas.drawLine(Offset(markerX, lcTop + 2), Offset(markerX, lcTop + lcH),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..strokeWidth = 1.2);
    canvas.drawCircle(Offset(markerX, lcTop + lcH * 0.12 + (phase > transitStart && phase < transitEnd
        ? (1 - (1 - transitDepth)) * lcH * 0.75 : 0)),
        3.5, Paint()..color = const Color(0xFF00D4FF));

    // Depth marker lines
    final depthY = lcTop + lcH * 0.12 + transitDepth * lcH * 0.75;
    canvas.drawLine(Offset(lcPadL, depthY), Offset(lcPadL + lcW, depthY),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.2)
          ..strokeWidth = 0.5..style = PaintingStyle.stroke);
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
  bool shouldRepaint(covariant _ExoplanetTransitScreenPainter oldDelegate) => true;
}
