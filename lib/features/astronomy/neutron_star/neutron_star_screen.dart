import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class NeutronStarScreen extends StatefulWidget {
  const NeutronStarScreen({super.key});
  @override
  State<NeutronStarScreen> createState() => _NeutronStarScreenState();
}

class _NeutronStarScreenState extends State<NeutronStarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _nsMass = 1.4;
  double _period = 0.033;
  double _radius = 10, _density = 0, _surfaceGravity = 0;

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
      _radius = 10.0 + (_nsMass - 1.4) * (-2);
      _density = _nsMass * 1.989e30 / (4.0 / 3 * math.pi * math.pow(_radius * 1000, 3));
      _surfaceGravity = 6.674e-11 * _nsMass * 1.989e30 / math.pow(_radius * 1000, 2);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _nsMass = 1.4;
      _period = 0.033;
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
          const Text('중성자별', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '중성자별',
          formula: 'ρ ~ 10^17 kg/m³',
          formulaDescription: '중성자별의 극한 밀도와 자기장을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _NeutronStarScreenPainter(
                time: _time,
                nsMass: _nsMass,
                period: _period,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '질량 (M☉)',
                value: _nsMass,
                min: 1.0,
                max: 3.0,
                step: 0.1,
                defaultValue: 1.4,
                formatValue: (v) => '${v.toStringAsFixed(1)} M☉',
                onChanged: (v) => setState(() => _nsMass = v),
              ),
              advancedControls: [
            SimSlider(
                label: '자전 주기 (s)',
                value: _period,
                min: 0.001,
                max: 10.0,
                step: 0.001,
                defaultValue: 0.033,
                formatValue: (v) => '${v.toStringAsFixed(3)} s',
                onChanged: (v) => setState(() => _period = v),
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
          _V('반지름', '${_radius.toStringAsFixed(1)} km'),
          _V('밀도', '${(_density / 1e17).toStringAsFixed(1)}×10¹⁷'),
          _V('주기', '${_period.toStringAsFixed(3)} s'),
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

class _NeutronStarScreenPainter extends CustomPainter {
  final double time;
  final double nsMass;
  final double period;

  _NeutronStarScreenPainter({
    required this.time,
    required this.nsMass,
    required this.period,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // Background stars
    final rng = math.Random(7);
    for (int i = 0; i < 40; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(sx, sy), rng.nextDouble() * 1.2 + 0.3,
          Paint()..color = Colors.white.withValues(alpha: rng.nextDouble() * 0.5 + 0.2));
    }

    final cx = size.width * 0.42;
    final cy = size.height * 0.50;
    final nsR = 36.0 + (nsMass - 1.4) * (-4).clamp(-12.0, 8.0);

    // Rotation angle for magnetic axis tilt
    final rotAngle = time * (2 * math.pi / period.clamp(0.001, 10.0));
    final magTilt = 0.45; // tilt of magnetic axis from rotation axis

    // Magnetic dipole field lines
    final magAxisAngle = rotAngle;
    for (int sign in [-1, 1]) {
      for (int line = 0; line < 5; line++) {
        final spread = math.pi / 8 * line;
        final path = Path();
        bool started = false;
        for (int step = 0; step <= 40; step++) {
          final t2 = step / 40.0;
          final theta = -math.pi / 2 + t2 * math.pi;
          final r = nsR * 2.5 * math.cos(spread) * math.cos(theta) * math.cos(theta);
          final fx = cx + r * math.cos(theta + magAxisAngle + sign * magTilt);
          final fy = cy + r * math.sin(theta + magAxisAngle + sign * magTilt) * 0.6;
          if (!started) { path.moveTo(fx, fy); started = true; }
          else { path.lineTo(fx, fy); }
        }
        canvas.drawPath(path, Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: 0.18 - line * 0.02)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke);
      }
    }

    // Pulsar beam (lighthouse effect)
    final beamAngle1 = magAxisAngle + magTilt;
    final beamAngle2 = magAxisAngle + magTilt + math.pi;
    for (final ba in [beamAngle1, beamAngle2]) {
      final beamLength = size.width * 0.7;
      final beamPath = Path();
      beamPath.moveTo(cx, cy);
      beamPath.lineTo(cx + beamLength * math.cos(ba), cy + beamLength * math.sin(ba) * 0.6);
      final beamPaint = Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFFFAA).withValues(alpha: 0.6),
          const Color(0xFFFFFFAA).withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: beamLength))
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(beamPath, beamPaint);
    }

    // NS cross-section layers
    final layers = [
      {'r': nsR, 'color': const Color(0xFF808090), 'label': '중성자 껍질'},
      {'r': nsR * 0.75, 'color': const Color(0xFF505060), 'label': '중성자 격자'},
      {'r': nsR * 0.5, 'color': const Color(0xFF304050), 'label': '중성자 액체'},
      {'r': nsR * 0.25, 'color': const Color(0xFF603070), 'label': '쿼크?'},
    ];
    for (final layer in layers.reversed) {
      final r = layer['r'] as double;
      final col = layer['color'] as Color;
      canvas.drawCircle(Offset(cx, cy), r + 3,
          Paint()..color = col.withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = col);
      canvas.drawCircle(Offset(cx, cy), r,
          Paint()..color = Colors.white.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }

    // Layer labels
    _drawLabel(canvas, '~${(10.0 + (nsMass - 1.4) * (-2)).clamp(6.0, 14.0).toStringAsFixed(0)} km', Offset(cx + nsR + 6, cy - 6),
        const Color(0xFFE0F4FF), 9, bold: true);

    // Right-side legend
    final legendX = size.width * 0.78;
    final legendLayers = [
      {'label': '중성자 껍질', 'color': const Color(0xFF808090)},
      {'label': '중성자 격자', 'color': const Color(0xFF505060)},
      {'label': '중성자 액체', 'color': const Color(0xFF304050)},
      {'label': '쿼크 수프?', 'color': const Color(0xFF603070)},
    ];
    for (int i = 0; i < legendLayers.length; i++) {
      final ly = size.height * 0.18 + i * 22.0;
      canvas.drawCircle(Offset(legendX, ly + 5), 5,
          Paint()..color = legendLayers[i]['color'] as Color);
      _drawLabel(canvas, legendLayers[i]['label'] as String, Offset(legendX + 9, ly),
          const Color(0xFF5A8A9A), 8);
    }

    // Rotation axis indicator
    canvas.drawLine(Offset(cx, cy - nsR - 30), Offset(cx, cy + nsR + 30),
        Paint()..color = const Color(0xFFFFFFAA).withValues(alpha: 0.4)..strokeWidth = 1
          ..style = PaintingStyle.stroke);
    _drawLabel(canvas, '자전축', Offset(cx + 4, cy - nsR - 28), const Color(0xFFFFFFAA).withValues(alpha: 0.6), 8);

    // Physical info
    _drawLabel(canvas, 'ρ ~ ${(1.0 + (nsMass - 1.4) * 0.5).toStringAsFixed(1)}×10¹⁷ kg/m³',
        Offset(6, size.height - 22), const Color(0xFF5A8A9A), 8);
    _drawLabel(canvas, 'g ~ ${(2.0 * nsMass).toStringAsFixed(1)}×10¹² m/s²',
        Offset(6, size.height - 10), const Color(0xFF5A8A9A), 7);
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
  bool shouldRepaint(covariant _NeutronStarScreenPainter oldDelegate) => true;
}
