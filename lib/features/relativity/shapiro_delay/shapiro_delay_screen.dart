import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ShapiroDelayScreen extends StatefulWidget {
  const ShapiroDelayScreen({super.key});
  @override
  State<ShapiroDelayScreen> createState() => _ShapiroDelayScreenState();
}

class _ShapiroDelayScreenState extends State<ShapiroDelayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _mass = 1;
  
  double _delay = 0, _rs = 3.0;

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
      _rs = 2.95 * _mass;
      _delay = 4 * _mass * 4.93e-6 * math.log(4 * 1e11 * 1e11 / (1e10 * 1e10));
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _mass = 1.0;
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
          const Text('샤피로 시간 지연', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '샤피로 시간 지연',
          formula: 'Δt = (4GM/c³)ln(4r₁r₂/b²)',
          formulaDescription: '중력에 의한 빛의 시간 지연 효과를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ShapiroDelayScreenPainter(
                time: _time,
                mass: _mass,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '중심 질량 (M☉)',
                value: _mass,
                min: 0.1,
                max: 100,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' M☉',
                onChanged: (v) => setState(() => _mass = v),
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
          _V('지연', (_delay * 1e6).toStringAsFixed(1) + ' μs'),
          _V('r_s', _rs.toStringAsFixed(2) + ' km'),
          _V('M', _mass.toStringAsFixed(1) + ' M☉'),
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

class _ShapiroDelayScreenPainter extends CustomPainter {
  final double time;
  final double mass;

  _ShapiroDelayScreenPainter({
    required this.time,
    required this.mass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Layout: Earth left, Sun center, Mercury right
    // Signal travels from Earth → past Sun → Mercury
    final earthX = w * 0.06;
    final sunX   = w * 0.50;
    final mercX  = w * 0.94;
    final baseY  = h * 0.52;

    // Schwarzschild radius → visual sun radius scale
    // Sun M=1: rs=2.95km → use visual radius ~28px; scale with mass^0.4
    final sunVisR = 24.0 * math.pow(mass.clamp(0.1, 100), 0.25);

    // Gravitational potential contours around the Sun
    for (int c = 1; c <= 6; c++) {
      final contourR = sunVisR * (1.5 + c * 0.9);
      final alpha = 0.28 - c * 0.04;
      canvas.drawCircle(
        Offset(sunX, baseY),
        contourR,
        Paint()
          ..color = Color.fromARGB((alpha * 255).toInt(), 255, 200, 80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // --- Sun ---
    canvas.drawCircle(
      Offset(sunX, baseY),
      sunVisR,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFEE88), const Color(0xFFFFAA22), const Color(0xFFFF6600)],
        ).createShader(Rect.fromCircle(center: Offset(sunX, baseY), radius: sunVisR)),
    );

    // --- Earth ---
    canvas.drawCircle(Offset(earthX, baseY), 9,
        Paint()..color = const Color(0xFF2244AA));
    canvas.drawCircle(Offset(earthX, baseY), 9,
        Paint()..color = const Color(0xFF33BB55)..style = PaintingStyle.stroke..strokeWidth = 2.5);
    _drawLabel(canvas, '지구', Offset(earthX - 10, baseY + 13), 9, AppColors.muted);

    // --- Mercury ---
    canvas.drawCircle(Offset(mercX, baseY), 6,
        Paint()..color = const Color(0xFF997755));
    canvas.drawCircle(Offset(mercX, baseY), 6,
        Paint()..color = AppColors.muted..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawLabel(canvas, '수성', Offset(mercX - 8, baseY + 11), 9, AppColors.muted);

    // --- Classical straight path (dashed, orange) ---
    final straightY = baseY - sunVisR * 0.45;
    _drawDashedLine(canvas, Offset(earthX + 10, straightY),
        Offset(mercX - 7, straightY), const Color(0xFFFF6B35), 0.9, 8, 5);
    _drawLabel(canvas, '고전 경로', Offset(earthX + 18, straightY - 13), 9, const Color(0xFFFF6B35));

    // --- GR curved path (bent around Sun) ---
    // Bending impact parameter b proportional to sunVisR; more mass → more bending
    final bParam = sunVisR * 1.05;
    final bendAmp = sunVisR * 0.22 * math.log(1 + mass * 0.3);

    final grPath = Path();
    const int pts = 80;
    for (int i = 0; i <= pts; i++) {
      final t = i / pts;
      final px = earthX + t * (mercX - earthX);
      // Parametric GR deflection: Gaussian dip toward Sun at midpoint
      final dx = px - sunX;
      final deflect = bendAmp * math.exp(-dx * dx / (bParam * bParam * 8));
      final py = straightY - deflect;
      if (i == 0) {
        grPath.moveTo(px, py);
      } else {
        grPath.lineTo(px, py);
      }
    }
    canvas.drawPath(
      grPath,
      Paint()
        ..color = const Color(0xFF00D4FF)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );
    _drawLabel(canvas, 'GR 경로 (지연)', Offset(earthX + 18, straightY + bendAmp + 4), 9, AppColors.accent);

    // --- Animated signal pulses ---
    // Two pulses: classical (orange) and GR (cyan), GR arrives later
    final grDelay = 0.08 * math.log(1 + mass * 0.5); // normalized extra delay
    _drawPulse(canvas, time * 0.22, earthX, mercX, straightY, 0.0, 4.5,
        const Color(0xFFFF6B35));
    _drawPulseGR(canvas, time * 0.22, earthX, mercX, straightY, bParam, bendAmp,
        grDelay, 4.5, const Color(0xFF00D4FF));

    // --- Delay annotation ---
    final delayUs = 4 * mass * 4.93e-6 * math.log(4e22 / (bParam * bParam));
    final delayLabel = '∆t ≈ ${(delayUs * 1e6).abs().toStringAsFixed(0)} μs';
    _drawLabel(canvas, delayLabel, Offset(sunX - 26, baseY - sunVisR - 18), 10, const Color(0xFF64FF8C));

    // --- 1964 Shapiro label ---
    _drawLabel(canvas, 'Shapiro 1964', Offset(w * 0.38, h * 0.88), 9, AppColors.muted);
    _drawLabel(canvas, '샤피로 시간 지연', Offset(w * 0.36, 8), 11, AppColors.accent);
  }

  void _drawPulse(Canvas canvas, double t, double x0, double x1,
      double y, double delay, double r, Color color) {
    final phase = ((t - delay) % 1.0 + 1.0) % 1.0;
    final px = x0 + phase * (x1 - x0);
    canvas.drawCircle(Offset(px, y), r,
        Paint()..color = color.withValues(alpha: 0.9));
  }

  void _drawPulseGR(Canvas canvas, double t, double x0, double x1,
      double y, double bParam, double bendAmp, double delay,
      double r, Color color) {
    final phase = ((t - delay) % 1.0 + 1.0) % 1.0;
    final px = x0 + phase * (x1 - x0);
    final midX = (x0 + x1) / 2;
    final dx = px - midX;
    final deflect = bendAmp * math.exp(-dx * dx / (bParam * bParam * 8));
    final py = y - deflect;
    canvas.drawCircle(Offset(px, py), r,
        Paint()..color = color.withValues(alpha: 0.9));
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Color color,
      double strokeWidth, double dashLen, double gapLen) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final ux = dx / dist, uy = dy / dist;
    double drawn = 0;
    bool drawing = true;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    while (drawn < dist) {
      final segLen = drawing ? dashLen : gapLen;
      final end = (drawn + segLen).clamp(0.0, dist);
      if (drawing) {
        canvas.drawLine(
          Offset(p1.dx + ux * drawn, p1.dy + uy * drawn),
          Offset(p1.dx + ux * end, p1.dy + uy * end),
          paint,
        );
      }
      drawn += segLen;
      drawing = !drawing;
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _ShapiroDelayScreenPainter oldDelegate) => true;
}
