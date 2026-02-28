import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class EquivalencePrincipleScreen extends StatefulWidget {
  const EquivalencePrincipleScreen({super.key});
  @override
  State<EquivalencePrincipleScreen> createState() => _EquivalencePrincipleScreenState();
}

class _EquivalencePrincipleScreenState extends State<EquivalencePrincipleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _acceleration = 9.8;
  
  double _gField = 9.8;

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
      _gField = _acceleration;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _acceleration = 9.8;
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
          const Text('등가 원리', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '등가 원리',
          formula: 'm_i = m_g',
          formulaDescription: '중력질량과 관성질량의 등가성을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _EquivalencePrincipleScreenPainter(
                time: _time,
                acceleration: _acceleration,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '가속도 (m/s²)',
                value: _acceleration,
                min: 0,
                max: 20,
                step: 0.1,
                defaultValue: 9.8,
                formatValue: (v) => v.toStringAsFixed(1) + ' m/s²',
                onChanged: (v) => setState(() => _acceleration = v),
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
          _V('가속도', _acceleration.toStringAsFixed(1) + ' m/s²'),
          _V('중력장', _gField.toStringAsFixed(1) + ' m/s²'),
          _V('차이', (_acceleration - _gField).abs().toStringAsFixed(3)),
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

class _EquivalencePrincipleScreenPainter extends CustomPainter {
  final double time;
  final double acceleration;

  _EquivalencePrincipleScreenPainter({
    required this.time,
    required this.acceleration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w2 = size.width / 2;
    final h = size.height;
    final gNorm = (acceleration / 20.0).clamp(0.0, 1.0);

    void drawLabel(String txt, Offset pos,
        {Color color = const Color(0xFF5A8A9A), double fs = 9}) {
      final tp = TextPainter(
        text: TextSpan(text: txt, style: TextStyle(color: color, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    // Divider
    canvas.drawLine(
        Offset(w2, 0),
        Offset(w2, h),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1.0);

    // === LEFT PANEL: Gravity field ===
    // Background star field (deterministic)
    final rng = math.Random(42);
    for (int i = 0; i < 18; i++) {
      final sx = rng.nextDouble() * (w2 - 4);
      final sy = rng.nextDouble() * h * 0.55;
      canvas.drawCircle(
          Offset(sx, sy),
          rng.nextDouble() * 1.2 + 0.3,
          Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.4));
    }

    // Planet (bottom left)
    final planetR = 28.0 + gNorm * 8;
    final planetCx = w2 * 0.5;
    final planetCy = h - planetR + 6;
    canvas.drawCircle(
        Offset(planetCx, planetCy),
        planetR,
        Paint()..color = const Color(0xFF1A6040));
    canvas.drawCircle(
        Offset(planetCx, planetCy),
        planetR,
        Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    // Gravity field lines (radial downward)
    final fieldPaint = Paint()
      ..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    for (int i = 0; i < 5; i++) {
      final fx = w2 * 0.15 + (w2 * 0.7) * i / 4;
      canvas.drawLine(
          Offset(fx, h * 0.12),
          Offset(fx, planetCy - planetR - 2),
          fieldPaint);
      // Arrow head downward
      canvas.drawLine(
          Offset(fx, planetCy - planetR - 2),
          Offset(fx - 4, planetCy - planetR - 10),
          fieldPaint);
      canvas.drawLine(
          Offset(fx, planetCy - planetR - 2),
          Offset(fx + 4, planetCy - planetR - 10),
          fieldPaint);
    }
    drawLabel('g', Offset(w2 - 18, h * 0.3),
        color: const Color(0xFF5A8A9A), fs: 10);

    // Elevator box (left)
    final elvL = w2 * 0.12;
    final elvR = w2 * 0.88;
    final elvT = h * 0.15;
    final elvB = h * 0.72;
    final elvPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(Rect.fromLTRB(elvL, elvT, elvR, elvB), elvPaint);

    // Person silhouette (left elevator)
    final pLx = w2 * 0.45;
    final pLy = elvB - 2;
    _drawPerson(canvas, pLx, pLy, const Color(0xFF00D4FF));

    // Falling ball (left) — falls under gravity
    final ballPhase = (time * gNorm * 1.5) % 1.2;
    final ballY = elvT + 10 + (elvB - elvT - 30) * (ballPhase * ballPhase / 1.44);
    canvas.drawCircle(
        Offset(w2 * 0.65, ballY),
        6,
        Paint()..color = const Color(0xFFFF6B35));

    // Parabolic trajectory dots (left)
    for (int k = 1; k <= 5; k++) {
      final ph = ballPhase - k * 0.08;
      if (ph < 0) continue;
      final by = elvT + 10 + (elvB - elvT - 30) * (ph * ph / 1.44);
      canvas.drawCircle(
          Offset(w2 * 0.65, by),
          2.5,
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.3 - k * 0.04));
    }

    // Photon redshift arrow (left): downward → blueshift (photon going down gains energy)
    _drawPhotonArrow(canvas, Offset(elvL + 8, elvT + 20), Offset(elvL + 8, elvT + 60),
        const Color(0xFF4488FF), const Color(0xFF00D4FF));

    // Labels
    drawLabel('중력장 g', Offset(4, 6), color: const Color(0xFF00D4FF), fs: 9);
    drawLabel('m_i = m_g', Offset(8, 20), color: const Color(0xFF5A8A9A), fs: 8);

    // === RIGHT PANEL: Accelerating rocket ===
    final rx = w2;
    // Stars for right panel
    final rng2 = math.Random(99);
    for (int i = 0; i < 18; i++) {
      final sx = rx + rng2.nextDouble() * (w2 - 4);
      final sy = rng2.nextDouble() * h * 0.75;
      canvas.drawCircle(
          Offset(sx, sy),
          rng2.nextDouble() * 1.2 + 0.3,
          Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.3));
    }

    // Rocket body
    final rktCx = rx + w2 * 0.5;
    final rktT = h * 0.10;
    final rktB = h * 0.72;
    final rktW = w2 * 0.38;
    final rktPaint = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rktRect = Rect.fromLTRB(rktCx - rktW / 2, rktT + 14, rktCx + rktW / 2, rktB);
    canvas.drawRect(rktRect, rktPaint);
    // Nose cone
    final nosePath = Path()
      ..moveTo(rktCx - rktW / 2, rktT + 14)
      ..lineTo(rktCx, rktT)
      ..lineTo(rktCx + rktW / 2, rktT + 14);
    canvas.drawPath(nosePath,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.4)..style = PaintingStyle.fill);

    // Rocket exhaust flame (animated)
    final flameH = 15 + gNorm * 25 + math.sin(time * 12) * 5;
    final flamePath = Path()
      ..moveTo(rktCx - rktW / 3, rktB)
      ..lineTo(rktCx, rktB + flameH)
      ..lineTo(rktCx + rktW / 3, rktB)
      ..close();
    canvas.drawPath(
        flamePath,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7));

    // Upward acceleration arrow
    final arrPaint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..strokeWidth = 2.0;
    final arrX = rktCx + rktW / 2 + 10;
    canvas.drawLine(Offset(arrX, rktB - 10), Offset(arrX, rktB - 10 - 30 * gNorm - 10), arrPaint);
    canvas.drawLine(Offset(arrX, rktB - 10 - 30 * gNorm - 10),
        Offset(arrX - 5, rktB - 10 - 30 * gNorm), arrPaint);
    canvas.drawLine(Offset(arrX, rktB - 10 - 30 * gNorm - 10),
        Offset(arrX + 5, rktB - 10 - 30 * gNorm), arrPaint);
    drawLabel('a', Offset(arrX + 7, rktB - 30 * gNorm - 20), color: const Color(0xFFFF6B35), fs: 10);

    // Person silhouette (right rocket)
    _drawPerson(canvas, rktCx, rktB - 2, const Color(0xFFFF6B35));

    // Falling ball (right) — same trajectory as left, synchronized
    canvas.drawCircle(
        Offset(rktCx - rktW * 0.1, rktT + 24 + (rktB - rktT - 40) * (ballPhase * ballPhase / 1.44)),
        6,
        Paint()..color = const Color(0xFFFF6B35));

    // Photon blueshift arrow (right): going up in accelerating frame → redshift
    _drawPhotonArrow(
        canvas,
        Offset(rx + 8, rktT + 20),
        Offset(rx + 8, rktT + 60),
        const Color(0xFF00D4FF),
        const Color(0xFF4488FF));

    // Right panel label
    drawLabel('가속 로켓 a', Offset(rx + 4, 6), color: const Color(0xFFFF6B35), fs: 9);
    drawLabel('a = g', Offset(rx + 4, 20), color: const Color(0xFF5A8A9A), fs: 8);

    // Center "=" sign
    drawLabel('물리적으로 동일!', Offset(w2 - 36, h - 18),
        color: const Color(0xFFE0F4FF), fs: 9);
  }

  void _drawPerson(Canvas canvas, double cx, double baseY, Color color) {
    // Head
    canvas.drawCircle(Offset(cx, baseY - 20), 5, Paint()..color = color.withValues(alpha: 0.8));
    // Body
    canvas.drawLine(Offset(cx, baseY - 15), Offset(cx, baseY - 4),
        Paint()..color = color.withValues(alpha: 0.8)..strokeWidth = 2);
    // Arms
    canvas.drawLine(Offset(cx - 8, baseY - 12), Offset(cx + 8, baseY - 12),
        Paint()..color = color.withValues(alpha: 0.8)..strokeWidth = 1.5);
    // Legs
    canvas.drawLine(Offset(cx, baseY - 4), Offset(cx - 5, baseY),
        Paint()..color = color.withValues(alpha: 0.8)..strokeWidth = 1.5);
    canvas.drawLine(Offset(cx, baseY - 4), Offset(cx + 5, baseY),
        Paint()..color = color.withValues(alpha: 0.8)..strokeWidth = 1.5);
  }

  void _drawPhotonArrow(Canvas canvas, Offset from, Offset to, Color fromColor, Color toColor) {
    // Wavy photon path with gradient color shift
    final steps = 8;
    final dx = (to.dx - from.dx) / steps;
    final dy = (to.dy - from.dy) / steps;
    for (int i = 0; i < steps; i++) {
      final t1 = i / steps;
      final c = Color.lerp(fromColor, toColor, t1)!.withValues(alpha: 0.8);
      canvas.drawLine(
          Offset(from.dx + dx * i + math.cos(i * 1.2) * 3, from.dy + dy * i),
          Offset(from.dx + dx * (i + 1) + math.cos((i + 1) * 1.2) * 3, from.dy + dy * (i + 1)),
          Paint()..color = c..strokeWidth = 1.5);
    }
    // Arrowhead
    canvas.drawLine(
        Offset(to.dx, to.dy),
        Offset(to.dx - 4, to.dy - 6),
        Paint()..color = toColor..strokeWidth = 1.2);
    canvas.drawLine(
        Offset(to.dx, to.dy),
        Offset(to.dx + 4, to.dy - 6),
        Paint()..color = toColor..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant _EquivalencePrincipleScreenPainter oldDelegate) => true;
}
