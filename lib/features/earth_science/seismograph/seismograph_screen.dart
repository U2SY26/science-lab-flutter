import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class SeismographScreen extends StatefulWidget {
  const SeismographScreen({super.key});
  @override
  State<SeismographScreen> createState() => _SeismographScreenState();
}

class _SeismographScreenState extends State<SeismographScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _magnitude = 5;
  double _distance = 100;
  double _amplitude = 0, _intensity = 0;

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
      _amplitude = math.pow(10, _magnitude - 3) / (_distance / 100);
      _intensity = math.min(12, _magnitude * 1.5 - math.log(_distance) / math.ln10);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _magnitude = 5; _distance = 100;
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
          Text('지구과학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('지진계 판독', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '지진계 판독',
          formula: 'M_L = log₁₀(A) + 3log₁₀(8Δt) - 2.92',
          formulaDescription: '지진계 기록을 판독하여 지진을 위치합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SeismographScreenPainter(
                time: _time,
                magnitude: _magnitude,
                distance: _distance,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '규모 (M)',
                value: _magnitude,
                min: 1,
                max: 9,
                step: 0.5,
                defaultValue: 5,
                formatValue: (v) => 'M ${v.toStringAsFixed(1)}',
                onChanged: (v) => setState(() => _magnitude = v),
              ),
              advancedControls: [
            SimSlider(
                label: '진앙 거리 (km)',
                value: _distance,
                min: 10,
                max: 1000,
                step: 10,
                defaultValue: 100,
                formatValue: (v) => '${v.toStringAsFixed(0)} km',
                onChanged: (v) => setState(() => _distance = v),
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
          _V('진폭', '${_amplitude.toStringAsFixed(2)} mm'),
          _V('진도', _intensity.toStringAsFixed(1)),
          _V('거리', '${_distance.toStringAsFixed(0)} km'),
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

class _SeismographScreenPainter extends CustomPainter {
  final double time;
  final double magnitude;
  final double distance;

  _SeismographScreenPainter({
    required this.time,
    required this.magnitude,
    required this.distance,
  });

  void _label(Canvas canvas, String text, Offset pos, {double fs = 9, Color col = const Color(0xFF5A8A9A)}) {
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

    // Seismogram occupies top 60% of canvas
    final seisTop = size.height * 0.05;
    final seisH = size.height * 0.55;
    final seisBot = seisTop + seisH;
    final seisLeft = 48.0;
    final seisRight = size.width - 12;
    final seisW = seisRight - seisLeft;
    final midY = seisTop + seisH / 2;

    // Baseline
    canvas.drawLine(Offset(seisLeft, midY), Offset(seisRight, midY),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);
    // Axes
    canvas.drawLine(Offset(seisLeft, seisTop), Offset(seisLeft, seisBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(seisLeft, seisBot), Offset(seisRight, seisBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);

    // Amplitudes depend on magnitude and distance
    final amp = math.pow(10, (magnitude - 3).clamp(0, 6)).toDouble() / (distance / 50.0).clamp(0.5, 20.0);
    final pAmp = (amp * 0.05).clamp(0.5, seisH * 0.12);
    final sAmp = (amp * 0.2).clamp(1.0, seisH * 0.28);
    final surfAmp = (amp * 0.5).clamp(2.0, seisH * 0.42);

    // P-wave arrival: starts at ~15% of width; S-wave at ~35%; Surface at ~50%
    // Time axis scrolls with `time`
    final scrollOffset = (time * 30) % seisW;
    final pStart = seisW * 0.15;
    final sStart = seisW * 0.35;
    final surfStart = seisW * 0.50;

    // Draw seismogram as path
    final path = Path();
    bool first = true;
    for (int px = 0; px < seisW.toInt(); px++) {
      final frac = px / seisW;
      double y = 0;
      // Noise baseline
      final rng = math.sin(px * 7.3 + scrollOffset * 0.1) * 1.5;
      y += rng;

      // P wave section
      if (frac > pStart / seisW && frac < sStart / seisW) {
        final t = (frac - pStart / seisW) / ((sStart - pStart) / seisW);
        final env = math.min(t * 4, 1.0) * math.exp(-t * 2);
        y += math.sin((px + scrollOffset) * 0.6) * pAmp * env;
      }
      // S wave section
      if (frac > sStart / seisW && frac < surfStart / seisW) {
        final t = (frac - sStart / seisW) / ((surfStart - sStart) / seisW);
        final env = math.min(t * 3, 1.0) * math.exp(-t * 1.5);
        y += math.sin((px + scrollOffset) * 0.3 + 1) * sAmp * env;
      }
      // Surface waves
      if (frac > surfStart / seisW) {
        final t = (frac - surfStart / seisW) / (1.0 - surfStart / seisW);
        final env = math.min(t * 2, 1.0) * math.exp(-t * 0.8);
        y += math.sin((px + scrollOffset) * 0.15 + 2) * surfAmp * env;
        y += math.sin((px + scrollOffset) * 0.12 + 3) * surfAmp * 0.5 * env;
      }

      final canvasX = seisLeft + px;
      final canvasY = midY - y.clamp(-seisH * 0.45, seisH * 0.45);
      if (first) {
        path.moveTo(canvasX, canvasY);
        first = false;
      } else {
        path.lineTo(canvasX, canvasY);
      }
    }
    canvas.drawPath(path, Paint()..color = const Color(0xFFE0F4FF)..strokeWidth = 1.2..style = PaintingStyle.stroke);

    // Color-coded arrival markers
    final pX = seisLeft + pStart;
    final sX = seisLeft + sStart;
    final surfX = seisLeft + surfStart;
    canvas.drawLine(Offset(pX, seisTop + 4), Offset(pX, seisBot),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(sX, seisTop + 4), Offset(sX, seisBot),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(surfX, seisTop + 4), Offset(surfX, seisBot),
        Paint()..color = const Color(0xFFE0F4FF)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    _label(canvas, 'P파', Offset(pX + 2, seisTop + 4), col: const Color(0xFFFF6B35), fs: 8);
    _label(canvas, 'S파', Offset(sX + 2, seisTop + 4), col: const Color(0xFF00D4FF), fs: 8);
    _label(canvas, '표면파', Offset(surfX + 2, seisTop + 4), col: const Color(0xFFE0F4FF), fs: 8);

    // S-P time label
    final spTime = distance / 8.0; // km / (8 km/s)
    _label(canvas, 'S-P = ${spTime.toStringAsFixed(1)}s → ${distance.toStringAsFixed(0)}km', Offset(seisLeft + 2, seisTop - 2), fs: 8, col: const Color(0xFFFF6B35));
    _label(canvas, '진폭', Offset(2, midY - 8), fs: 8);
    _label(canvas, '시간 →', Offset(seisRight - 32, seisBot + 2), fs: 8);

    // --- Cross-section showing P/S ray paths (bottom panel) ---
    final crossTop = seisBot + 14;
    final crossH = size.height - crossTop - 8;
    if (crossH < 30) return;
    final earthCx = size.width / 2;
    final earthCy = crossTop + crossH * 0.55;
    final earthR = crossH * 0.4;

    // Earth fill
    canvas.drawCircle(Offset(earthCx, earthCy), earthR,
        Paint()..color = const Color(0xFF1A3040));
    // Core
    canvas.drawCircle(Offset(earthCx, earthCy), earthR * 0.45,
        Paint()..color = const Color(0xFF8B4513).withValues(alpha: 0.6));
    // Outline
    canvas.drawCircle(Offset(earthCx, earthCy), earthR,
        Paint()..color = const Color(0xFF5A8A9A)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // P-wave ray (refracted, orange arc)
    final pPath = Path();
    final pRayPaint = Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    pPath.moveTo(earthCx - earthR, earthCy);
    pPath.quadraticBezierTo(earthCx, earthCy + earthR * 0.3, earthCx + earthR, earthCy);
    canvas.drawPath(pPath, pRayPaint);

    // S-wave ray (cyan, shallower curve)
    final sPath = Path();
    final sRayPaint = Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    sPath.moveTo(earthCx - earthR, earthCy);
    sPath.quadraticBezierTo(earthCx, earthCy - earthR * 0.1, earthCx + earthR, earthCy);
    canvas.drawPath(sPath, sRayPaint);

    // Epicenter marker
    canvas.drawCircle(Offset(earthCx - earthR, earthCy), 4,
        Paint()..color = const Color(0xFFFF6B35));
    _label(canvas, '진앙', Offset(earthCx - earthR - 16, earthCy - 12), fs: 7, col: const Color(0xFFFF6B35));
    _label(canvas, 'M ${magnitude.toStringAsFixed(1)}', Offset(earthCx - 12, crossTop), fs: 8, col: const Color(0xFFE0F4FF));
  }

  @override
  bool shouldRepaint(covariant _SeismographScreenPainter oldDelegate) => true;
}
