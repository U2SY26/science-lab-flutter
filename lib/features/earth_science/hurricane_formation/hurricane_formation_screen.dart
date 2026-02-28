import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class HurricaneFormationScreen extends StatefulWidget {
  const HurricaneFormationScreen({super.key});
  @override
  State<HurricaneFormationScreen> createState() => _HurricaneFormationScreenState();
}

class _HurricaneFormationScreenState extends State<HurricaneFormationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _sst = 28.0;
  double _coriolisStr = 0.5;
  double _windSpeed = 0; int _category = 0;

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
      _windSpeed = (_sst > 26.5) ? 50 + (_sst - 26.5) * 20 * _coriolisStr : 20;
      _category = _windSpeed >= 250 ? 5 : _windSpeed >= 209 ? 4 : _windSpeed >= 178 ? 3 : _windSpeed >= 154 ? 2 : _windSpeed >= 119 ? 1 : 0;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _sst = 28.0;
      _coriolisStr = 0.5;
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
          const Text('허리케인 형성', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '허리케인 형성',
          formulaDescription: '해수 온도와 코리올리 효과로 열대 저기압이 발달합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _HurricaneFormationScreenPainter(
                time: _time,
                sst: _sst,
                coriolisStr: _coriolisStr,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '해수 온도 (°C)',
                value: _sst,
                min: 20.0,
                max: 35.0,
                defaultValue: 28.0,
                formatValue: (v) => '${v.toInt()} °C',
                onChanged: (v) => setState(() => _sst = v),
              ),
              advancedControls: [
            SimSlider(
                label: '코리올리 강도',
                value: _coriolisStr,
                min: 0.1,
                max: 1.0,
                step: 0.05,
                defaultValue: 0.5,
                formatValue: (v) => '${v.toStringAsFixed(2)}',
                onChanged: (v) => setState(() => _coriolisStr = v),
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
          _V('풍속', '${_windSpeed.toStringAsFixed(0)} km/h'),
          _V('카테고리', '${_category}'),
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

class _HurricaneFormationScreenPainter extends CustomPainter {
  final double time;
  final double sst;
  final double coriolisStr;

  _HurricaneFormationScreenPainter({
    required this.time,
    required this.sst,
    required this.coriolisStr,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, {Color color = const Color(0xFF5A8A9A), double fontSize = 10}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;

    // Intensity factor (0..1) based on SST
    final intensity = ((sst - 20.0) / 15.0).clamp(0.0, 1.0) * coriolisStr;
    final rotSpeed = 0.4 + intensity * 1.2; // rotation speed
    final maxR = math.min(w, h) * 0.44;     // outer radius
    final eyeR = maxR * 0.1;                 // eye radius
    final eyewallR = maxR * 0.2;             // eyewall radius

    // Ocean background
    final oceanPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          const Color(0xFF0A2545),
          const Color(0xFF051530),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), oceanPaint);

    // Sea surface temperature color hint
    final sstColor = Color.lerp(const Color(0xFF1A3A6A), const Color(0xFF00AACC), (sst - 20) / 15)!;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = sstColor.withValues(alpha: 0.08),
    );

    // Draw spiral cloud bands (5-6 bands, counterclockwise)
    final numBands = 5;
    for (int b = 0; b < numBands; b++) {
      final bandPath = Path();
      final bandOffset = b * math.pi * 2 / numBands;
      final bandAlpha = (0.5 + 0.4 * intensity).clamp(0.0, 1.0);
      final bandColor = Color.lerp(
        const Color(0xFF5A8A9A),
        const Color(0xFF00D4FF),
        intensity,
      )!.withValues(alpha: bandAlpha * (0.4 + b * 0.08).clamp(0.0, 0.9));

      bool first = true;
      for (int step = 0; step <= 200; step++) {
        final t = step / 200.0;
        // Spiral: radius grows from eyewall outward as angle increases
        final spiralAngle = bandOffset - time * rotSpeed + t * math.pi * 3.5;
        final r = eyewallR + (maxR - eyewallR) * math.pow(t, 0.6);
        final x = cx + r * math.cos(spiralAngle);
        final y = cy + r * math.sin(spiralAngle);
        if (first) {
          bandPath.moveTo(x, y);
          first = false;
        } else {
          bandPath.lineTo(x, y);
        }
      }

      final bandPaint = Paint()
        ..color = bandColor
        ..strokeWidth = 10.0 + b * 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(bandPath, bandPaint);
    }

    // Outflow arrows (top, radial)
    final outflowPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + time * 0.1;
      final fromR = maxR * 0.85;
      final toR = maxR * 1.05;
      final fx = cx + fromR * math.cos(angle);
      final fy = cy + fromR * math.sin(angle);
      final tx = cx + toR * math.cos(angle);
      final ty = cy + toR * math.sin(angle);
      canvas.drawLine(Offset(fx, fy), Offset(tx, ty), outflowPaint);
    }

    // Inflow arrows (bottom convergence)
    final inflowPaint = Paint()
      ..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - time * 0.2;
      final fromR = maxR * 0.55;
      final toR = eyewallR * 1.2;
      final fx = cx + fromR * math.cos(angle);
      final fy = cy + fromR * math.sin(angle);
      final tx = cx + toR * math.cos(angle - 0.3);
      final ty = cy + toR * math.sin(angle - 0.3);
      canvas.drawLine(Offset(fx, fy), Offset(tx, ty), inflowPaint);
    }

    // Eyewall glow
    final eyewallPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.3 + 0.3 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy), eyewallR, eyewallPaint);

    // Eye (calm center)
    final eyeFill = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF1A3A5A), const Color(0xFF0D1A20)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: eyeR));
    canvas.drawCircle(Offset(cx, cy), eyeR, eyeFill);
    canvas.drawCircle(Offset(cx, cy), eyeR,
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Category label
    final windSpeed2 = 50 + intensity * 200;
    final cat = windSpeed2 >= 250 ? 5 : windSpeed2 >= 209 ? 4 : windSpeed2 >= 178 ? 3 : windSpeed2 >= 154 ? 2 : windSpeed2 >= 119 ? 1 : 0;
    final catColor = [
      const Color(0xFF5A8A9A),
      const Color(0xFF64FF8C),
      const Color(0xFFFFFF00),
      const Color(0xFFFF8C00),
      const Color(0xFFFF4444),
      const Color(0xFFFF00FF),
    ][cat];

    _drawLabel(canvas, '태풍의 눈', Offset(cx, cy), color: const Color(0xFF00D4FF), fontSize: 9);
    _drawLabel(canvas, 'Cat $cat', Offset(cx, h * 0.12), color: catColor, fontSize: 13);
    _drawLabel(canvas, '${windSpeed2.toStringAsFixed(0)} km/h', Offset(cx, h * 0.12 + 16), color: const Color(0xFF5A8A9A), fontSize: 9);
    _drawLabel(canvas, '눈벽', Offset(cx + eyewallR + 14, cy), color: const Color(0xFF00D4FF).withValues(alpha: 0.8), fontSize: 8);
    _drawLabel(canvas, '나선형\n구름대', Offset(cx + maxR * 0.55, cy - maxR * 0.28), color: const Color(0xFF5A8A9A), fontSize: 8);
    _drawLabel(canvas, 'SST ${sst.toStringAsFixed(0)}°C', Offset(w * 0.12, h * 0.9), color: const Color(0xFF00AACC), fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _HurricaneFormationScreenPainter oldDelegate) => true;
}
