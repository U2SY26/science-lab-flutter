import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class GravitationalTimeScreen extends StatefulWidget {
  const GravitationalTimeScreen({super.key});
  @override
  State<GravitationalTimeScreen> createState() => _GravitationalTimeScreenState();
}

class _GravitationalTimeScreenState extends State<GravitationalTimeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _radius = 10;
  
  double _timeDilation = 1.0, _redshift = 0;

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
      _timeDilation = 1 / math.sqrt(1 - 1 / _radius);
      _redshift = _timeDilation - 1;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _radius = 10.0;
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
          const Text('중력 시간 팽창', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '중력 시간 팽창',
          formula: 'Δt = Δt₀/√(1-2GM/rc²)',
          formulaDescription: '중력장에서의 시간 팽창을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _GravitationalTimeScreenPainter(
                time: _time,
                radius: _radius,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '반지름 (r_s)',
                value: _radius,
                min: 1.1,
                max: 100,
                step: 0.1,
                defaultValue: 10,
                formatValue: (v) => v.toStringAsFixed(1) + ' r_s',
                onChanged: (v) => setState(() => _radius = v),
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
          _V('팝창', _timeDilation.toStringAsFixed(4) + 'x'),
          _V('적색편이', _redshift.toStringAsFixed(4)),
          _V('r', _radius.toStringAsFixed(1) + ' r_s'),
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

class _GravitationalTimeScreenPainter extends CustomPainter {
  final double time;
  final double radius; // in units of Schwarzschild radius (r/rs)

  _GravitationalTimeScreenPainter({
    required this.time,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Time dilation factor: t/t0 = 1/sqrt(1 - 1/r) where r = radius/rs
    final r = radius.clamp(1.01, 100.0);
    final gamma = 1.0 / math.sqrt(1.0 - 1.0 / r);  // how much slower near BH

    // Layout: left clock (near BH, slow), right clock (far away, fast)
    final leftCx = w * 0.26;
    final rightCx = w * 0.74;
    final clockCy = h * 0.44;
    final clockR = math.min(w * 0.16, h * 0.28);

    // --- Black hole gradient on the left ---
    for (int ring = 5; ring >= 1; ring--) {
      final rr = clockR * (0.4 + ring * 0.18);
      final alpha = 0.06 * (6 - ring);
      canvas.drawCircle(
        Offset(leftCx, clockCy + clockR * 1.55),
        rr,
        Paint()..color = Color.fromARGB((alpha * 255).toInt(), 10, 10, 10),
      );
    }

    // --- Left clock (near BH, slow) ---
    // Angular speed: 1/gamma (slowed)
    final leftSpeed = 1.0 / gamma;
    _drawClock(canvas, Offset(leftCx, clockCy), clockR, time * leftSpeed,
        const Color(0xFFFF6B35), '근거리 시계\n(느림)', h);

    // --- Right clock (far away, normal speed) ---
    _drawClock(canvas, Offset(rightCx, clockCy), clockR, time * 1.0,
        const Color(0xFF00D4FF), '원거리 시계\n(정상)', h);

    // --- Gravitational well gradient between them ---
    final wellPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFF6B35).withValues(alpha: 0.08),
          const Color(0xFF0D1A20),
          const Color(0xFF00D4FF).withValues(alpha: 0.08),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(leftCx, 0, rightCx - leftCx, h));
    canvas.drawRect(Rect.fromLTWH(leftCx, clockCy - clockR, rightCx - leftCx, clockR * 2), wellPaint);

    // --- Photon arrows between clocks ---
    // Upgoing photon: redshifted (red → orange gradient)
    final midY = clockCy;
    final arrowY1 = midY - clockR * 0.1;
    _drawPhotonArrow(canvas, Offset(leftCx + clockR + 6, arrowY1 + 6),
        Offset(rightCx - clockR - 6, arrowY1 - 6), const Color(0xFFFF6B35), true, time);

    // Downgoing photon: blueshifted (blue → cyan)
    final arrowY2 = midY + clockR * 0.22;
    _drawPhotonArrow(canvas, Offset(rightCx - clockR - 6, arrowY2 - 6),
        Offset(leftCx + clockR + 6, arrowY2 + 6), const Color(0xFF4488FF), false, time);

    // Labels for photons
    final midX = (leftCx + rightCx) / 2;
    _drawLabel(canvas, '↑ 적색편이', Offset(midX - 22, arrowY1 - 18), 9, const Color(0xFFFF6B35));
    _drawLabel(canvas, '↓ 청색편이', Offset(midX - 22, arrowY2 + 6), 9, const Color(0xFF4488FF));

    // --- Ratio display ---
    final ratioY = h * 0.84;
    _drawLabel(canvas, 'γ = ${gamma.toStringAsFixed(4)}×',
        Offset(midX - 28, ratioY), 12, const Color(0xFF64FF8C));
    _drawLabel(canvas, '좌시계 = 우시계 / γ',
        Offset(midX - 42, ratioY + 16), 10, AppColors.muted);

    // GPS correction note
    _drawLabel(canvas, 'GPS 보정 필요: ~45 μs/일',
        Offset(midX - 48, h * 0.93), 9, AppColors.muted);

    // Title
    _drawLabel(canvas, '중력 시간 팽창', Offset(midX - 30, 8), 11, AppColors.accent);
  }

  void _drawClock(Canvas canvas, Offset center, double r, double t,
      Color accentColor, String label, double h) {
    // Clock face background
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFF101E28));
    canvas.drawCircle(center, r,
        Paint()
          ..color = accentColor.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);

    // Hour ticks
    for (int i = 0; i < 12; i++) {
      final a = i / 12.0 * math.pi * 2 - math.pi / 2;
      final inner = r * 0.82;
      final outer = r * 0.95;
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(a), center.dy + inner * math.sin(a)),
        Offset(center.dx + outer * math.cos(a), center.dy + outer * math.sin(a)),
        Paint()..color = accentColor.withValues(alpha: 0.5)..strokeWidth = 1.2,
      );
    }

    // Hour hand (slow)
    final hourAngle = t * 0.5 - math.pi / 2; // 1 full rotation per 120s
    _drawHand(canvas, center, hourAngle, r * 0.52, accentColor.withValues(alpha: 0.7), 2.5);

    // Minute hand
    final minAngle = t * 3.0 - math.pi / 2;
    _drawHand(canvas, center, minAngle, r * 0.75, accentColor, 1.8);

    // Second hand
    final secAngle = t * 18.0 - math.pi / 2;
    _drawHand(canvas, center, secAngle, r * 0.85, Colors.white.withValues(alpha: 0.8), 1.0);

    // Center dot
    canvas.drawCircle(center, 3, Paint()..color = accentColor);

    // Label
    final lines = label.split('\n');
    for (int i = 0; i < lines.length; i++) {
      _drawLabel(canvas, lines[i],
          Offset(center.dx - 22, center.dy + r + 6 + i * 14), 9, accentColor);
    }
  }

  void _drawHand(Canvas canvas, Offset center, double angle, double len,
      Color color, double width) {
    canvas.drawLine(
      center,
      Offset(center.dx + len * math.cos(angle), center.dy + len * math.sin(angle)),
      Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round,
    );
  }

  void _drawPhotonArrow(Canvas canvas, Offset from, Offset to, Color color,
      bool leftToRight, double t) {
    // Animated photon dot
    final phase = (t * 0.4) % 1.0;
    final px = from.dx + phase * (to.dx - from.dx);
    final py = from.dy + phase * (to.dy - from.dy);
    canvas.drawLine(from, to,
        Paint()..color = color.withValues(alpha: 0.35)..strokeWidth = 1.2);
    canvas.drawCircle(Offset(px, py), 4,
        Paint()..color = color.withValues(alpha: 0.9));
    // Arrowhead
    final dx = to.dx - from.dx, dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final ux = dx / len, uy = dy / len;
    final arrowPath = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - ux * 8 - uy * 5, to.dy - uy * 8 + ux * 5)
      ..lineTo(to.dx - ux * 8 + uy * 5, to.dy - uy * 8 - ux * 5)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = color.withValues(alpha: 0.8));
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _GravitationalTimeScreenPainter oldDelegate) => true;
}
