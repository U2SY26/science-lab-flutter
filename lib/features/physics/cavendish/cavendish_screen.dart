import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CavendishScreen extends StatefulWidget {
  const CavendishScreen({super.key});
  @override
  State<CavendishScreen> createState() => _CavendishScreenState();
}

class _CavendishScreenState extends State<CavendishScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _largeMass = 100;
  double _smallMass = 1;
  double _torque = 0, _deflection = 0;

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
      _torque = 6.674e-11 * _largeMass * _smallMass / (0.1 * 0.1);
      _deflection = _torque * 1e9;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _largeMass = 100; _smallMass = 1.0;
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
          Text('물리 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('캐번디시 실험', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '캐번디시 실험',
          formula: 'G=6.674×10⁻¹¹ N⋅m²/kg²',
          formulaDescription: '캐번디시 비틀림 저울로 G를 측정합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CavendishScreenPainter(
                time: _time,
                largeMass: _largeMass,
                smallMass: _smallMass,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '큰 구 질량 (kg)',
                value: _largeMass,
                min: 10,
                max: 200,
                step: 5,
                defaultValue: 100,
                formatValue: (v) => '${v.toStringAsFixed(0)} kg',
                onChanged: (v) => setState(() => _largeMass = v),
              ),
              advancedControls: [
            SimSlider(
                label: '작은 구 질량 (kg)',
                value: _smallMass,
                min: 0.1,
                max: 5,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                onChanged: (v) => setState(() => _smallMass = v),
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
          _V('토크', '${_torque.toStringAsExponential(2)} N⋅m'),
          _V('편향', '${_deflection.toStringAsFixed(2)} nrad'),
          _V('G 측정', '6.674e-11'),
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

class _CavendishScreenPainter extends CustomPainter {
  final double time;
  final double largeMass;
  final double smallMass;

  _CavendishScreenPainter({
    required this.time,
    required this.largeMass,
    required this.smallMass,
  });

  void _label(Canvas canvas, String text, Offset pos, Color color, double sz,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: sz,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _arrow(Canvas canvas, Offset from, Offset to, Color color, double sw) {
    final p = Paint()..color = color..strokeWidth = sw..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, p);
    final dx = to.dx - from.dx, dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 2) return;
    final nx = dx / len, ny = dy / len;
    const hs = 6.0;
    canvas.drawLine(to, Offset(to.dx - nx * hs - ny * hs * 0.5, to.dy - ny * hs + nx * hs * 0.5), p);
    canvas.drawLine(to, Offset(to.dx - nx * hs + ny * hs * 0.5, to.dy - ny * hs - nx * hs * 0.5), p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;
    final cx = w / 2, cy = h * 0.48;

    // Torque & deflection angle
    final torque = 6.674e-11 * largeMass * smallMass / (0.1 * 0.1);
    // Animate towards equilibrium angle
    final maxDefl = math.atan(torque * 1e10) * 0.4; // scaled for visibility
    final animProgress = math.min(1.0, time * 0.3);
    final defl = maxDefl * (1 - math.exp(-animProgress * 3)) *
        (1 + 0.04 * math.sin(time * 8 * math.exp(-animProgress * 2)));

    // --- Torsion fiber (vertical line at center) ---
    canvas.drawLine(Offset(cx, 8), Offset(cx, cy - 10),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.5);
    // Twist indicator arc
    canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy - 10), width: 20, height: 20),
        -math.pi / 2, defl * 3, false,
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // --- Horizontal rod (rotated by defl) ---
    const rodHalfLen = 55.0;
    final rod1X = cx + rodHalfLen * math.cos(defl);
    final rod1Y = cy + rodHalfLen * math.sin(defl);
    final rod2X = cx - rodHalfLen * math.cos(defl);
    final rod2Y = cy - rodHalfLen * math.sin(defl);

    canvas.drawLine(Offset(rod1X, rod1Y), Offset(rod2X, rod2Y),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 2.5..strokeCap = StrokeCap.round);

    // Small balls on rod ends
    const smallR = 7.0;
    canvas.drawCircle(Offset(rod1X, rod1Y), smallR,
        Paint()..color = const Color(0xFF00D4FF)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(rod1X, rod1Y), smallR,
        Paint()..color = const Color(0xFFE0F4FF)..style = PaintingStyle.stroke..strokeWidth = 1);
    canvas.drawCircle(Offset(rod2X, rod2Y), smallR,
        Paint()..color = const Color(0xFF00D4FF)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(rod2X, rod2Y), smallR,
        Paint()..color = const Color(0xFFE0F4FF)..style = PaintingStyle.stroke..strokeWidth = 1);
    _label(canvas, 'm', Offset(rod1X - 4, rod1Y - 5), const Color(0xFFE0F4FF), 8);
    _label(canvas, 'm', Offset(rod2X - 4, rod2Y - 5), const Color(0xFFE0F4FF), 8);

    // Large balls (fixed, outside the small ones)
    const largeR = 14.0;
    final lg1X = cx + (rodHalfLen + largeR + 4) * math.cos(defl - 0.08);
    final lg1Y = cy + (rodHalfLen + largeR + 4) * math.sin(defl - 0.08);
    final lg2X = cx - (rodHalfLen + largeR + 4) * math.cos(defl - 0.08);
    final lg2Y = cy - (rodHalfLen + largeR + 4) * math.sin(defl - 0.08);

    canvas.drawCircle(Offset(lg1X, lg1Y), largeR,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.85)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(lg1X, lg1Y), largeR,
        Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.stroke..strokeWidth = 1);
    canvas.drawCircle(Offset(lg2X, lg2Y), largeR,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.85)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(lg2X, lg2Y), largeR,
        Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.stroke..strokeWidth = 1);
    _label(canvas, 'M', Offset(lg1X - 5, lg1Y - 6), const Color(0xFFE0F4FF), 8);
    _label(canvas, 'M', Offset(lg2X - 5, lg2Y - 6), const Color(0xFFE0F4FF), 8);

    // Gravitational force arrows between large and small balls
    final dir1X = rod1X - lg1X, dir1Y = rod1Y - lg1Y;
    final d1 = math.sqrt(dir1X * dir1X + dir1Y * dir1Y);
    if (d1 > 1) {
      final forceLen = 14.0 + largeMass * 0.06;
      _arrow(canvas, Offset(rod1X, rod1Y),
          Offset(rod1X + dir1X / d1 * (-forceLen), rod1Y + dir1Y / d1 * (-forceLen)),
          const Color(0xFF00D4FF), 1.5);
    }
    final dir2X = rod2X - lg2X, dir2Y = rod2Y - lg2Y;
    final d2 = math.sqrt(dir2X * dir2X + dir2Y * dir2Y);
    if (d2 > 1) {
      final forceLen = 14.0 + largeMass * 0.06;
      _arrow(canvas, Offset(rod2X, rod2Y),
          Offset(rod2X + dir2X / d2 * (-forceLen), rod2Y + dir2Y / d2 * (-forceLen)),
          const Color(0xFF00D4FF), 1.5);
    }
    _label(canvas, 'Fg', Offset(cx + 12, cy - 24), const Color(0xFF00D4FF), 8);

    // Mirror & laser (right side of pendulum center)
    final mirrorX = cx + 8.0;
    final mirrorY = cy;
    // Laser beam reflecting off mirror
    final laserAngle = defl * 2; // reflection doubles angle
    final laserEndX = mirrorX + 60 * math.cos(-math.pi / 4 + laserAngle);
    final laserEndY = mirrorY + 60 * math.sin(-math.pi / 4 + laserAngle);
    canvas.drawLine(Offset(mirrorX, mirrorY), Offset(laserEndX, laserEndY),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round);
    _label(canvas, 'laser', Offset(laserEndX + 2, laserEndY - 8),
        const Color(0xFFFF6B35), 7);

    // Info panel bottom
    final infoY = h * 0.82;
    canvas.drawRect(Rect.fromLTWH(8, infoY, w - 16, h - infoY - 6),
        Paint()..color = const Color(0xFF0A0A0F));
    _label(canvas, 'G = 6.674×10⁻¹¹ N·m²/kg²',
        Offset(14, infoY + 4), const Color(0xFF5A8A9A), 9, bold: true);
    _label(canvas, 'M=${largeMass.toStringAsFixed(0)}kg  m=${smallMass.toStringAsFixed(1)}kg  τ=${torque.toStringAsExponential(2)} N·m',
        Offset(14, infoY + 16), const Color(0xFF00D4FF), 8);
    _label(canvas, '편향각 θ = ${(defl * 180 / math.pi).toStringAsFixed(4)}°',
        Offset(14, infoY + 28), const Color(0xFFFF6B35), 8);
  }

  @override
  bool shouldRepaint(covariant _CavendishScreenPainter oldDelegate) => true;
}
