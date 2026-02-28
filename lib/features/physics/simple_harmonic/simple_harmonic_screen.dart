import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class SimpleHarmonicScreen extends StatefulWidget {
  const SimpleHarmonicScreen({super.key});
  @override
  State<SimpleHarmonicScreen> createState() => _SimpleHarmonicScreenState();
}

class _SimpleHarmonicScreenState extends State<SimpleHarmonicScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _amplitude = 80.0;
  double _springK = 2.0;
  double _mass = 1.0;
  double _position = 0, _velocity = 0, _period = 0;

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
      final omega = math.sqrt(_springK / _mass);
      _position = _amplitude * math.cos(omega * _time);
      _velocity = -_amplitude * omega * math.sin(omega * _time);
      _period = 2 * math.pi / omega;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _amplitude = 80.0;
      _springK = 2.0;
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
          Text('물리 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('단순 조화 운동', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '단순 조화 운동',
          formula: 'x(t) = A·cos(ωt + φ)',
          formulaDescription: '진폭 A, 각진동수 ω, 초기 위상 φ에 의해 위치가 결정됩니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SimpleHarmonicScreenPainter(
                time: _time,
                amplitude: _amplitude,
                springK: _springK,
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
                label: '진폭 (A)',
                value: _amplitude,
                min: 10.0,
                max: 150.0,
                defaultValue: 80.0,
                formatValue: (v) => '${v.toInt()} px',
                onChanged: (v) => setState(() => _amplitude = v),
              ),
              advancedControls: [
            SimSlider(
                label: '탄성계수 (k)',
                value: _springK,
                min: 0.5,
                max: 10.0,
                step: 0.1,
                defaultValue: 2.0,
                formatValue: (v) => '${v.toStringAsFixed(1)} N/m',
                onChanged: (v) => setState(() => _springK = v),
              ),
            SimSlider(
                label: '질량 (m)',
                value: _mass,
                min: 0.5,
                max: 5.0,
                step: 0.1,
                defaultValue: 1.0,
                formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                onChanged: (v) => setState(() => _mass = v),
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
          _V('위치', '${_position.toStringAsFixed(1)} px'),
          _V('속도', '${_velocity.toStringAsFixed(1)} px/s'),
          _V('주기', '${_period.toStringAsFixed(2)} s'),
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

class _SimpleHarmonicScreenPainter extends CustomPainter {
  final double time;
  final double amplitude;
  final double springK;
  final double mass;

  _SimpleHarmonicScreenPainter({
    required this.time,
    required this.amplitude,
    required this.springK,
    required this.mass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final omega = math.sqrt(springK / mass);
    final pos = amplitude * math.cos(omega * time);
    final vel = -amplitude * omega * math.sin(omega * time);
    final A = amplitude;

    // ── LEFT PANEL: spring-mass system ──────────────────────
    final springX = w * 0.28;
    final ceilY = 16.0;
    final equilibriumY = h * 0.42;
    final maxDisp = (h * 0.32).clamp(30.0, 130.0);
    final scale = maxDisp / A.clamp(1.0, 200.0);
    final massY = equilibriumY + pos * scale;
    final massSize = 22.0;

    // Ceiling
    canvas.drawRect(Rect.fromLTWH(springX - 20, ceilY, 40, 5),
        Paint()..color = const Color(0xFF5A8A9A));

    // Spring coils
    final springTop = ceilY + 5;
    final springBot = massY - massSize / 2;
    final coils = 10;
    final coilW = 12.0;
    final path = Path();
    path.moveTo(springX, springTop);
    for (int i = 0; i <= coils; i++) {
      final t = i / coils;
      final cx2 = springX + (i % 2 == 0 ? -coilW : coilW);
      final cy2 = springTop + t * (springBot - springTop);
      if (i == 0) { path.lineTo(cx2, cy2); } else { path.lineTo(cx2, cy2); }
    }
    path.lineTo(springX, springBot);
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF5A8A9A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round);

    // Mass block
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(springX, massY), width: massSize, height: massSize),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.85),
    );

    // Equilibrium line
    canvas.drawLine(Offset(springX - 28, equilibriumY), Offset(springX + 28, equilibriumY),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round);

    // Velocity arrow
    if (vel.abs() > 0.5) {
      final arrowLen = (vel * scale * 0.3).clamp(-40.0, 40.0);
      final arrowY = massY + arrowLen;
      canvas.drawLine(Offset(springX + massSize / 2 + 4, massY),
          Offset(springX + massSize / 2 + 4, arrowY),
          Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round);
      _text(canvas, 'v', Offset(springX + massSize / 2 + 8, arrowY - 6),
          const TextStyle(color: Color(0xFFFF6B35), fontSize: 8));
    }

    _text(canvas, 'x(t)=A·cos(ωt)', Offset(4, ceilY),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 9, fontWeight: FontWeight.bold));

    // ── RIGHT PANEL: phase space + time graph ───────────────
    final rightX = w * 0.52;
    final rightW = w - rightX - 8;

    // Phase space (x vs v) — top right
    final phaseH = h * 0.44;
    final phaseCX = rightX + rightW / 2;
    final phaseCY = phaseH / 2 + 10;
    final phaseRX = rightW * 0.42;
    final phaseRY = phaseH * 0.36;

    _text(canvas, '위상 공간 (x vs v)', Offset(rightX, 6),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8, fontWeight: FontWeight.bold));

    // Ellipse trajectory
    canvas.drawOval(
      Rect.fromCenter(center: Offset(phaseCX, phaseCY), width: phaseRX * 2, height: phaseRY * 2),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 1.2,
    );

    // Current point on phase ellipse
    final phX = phaseCX + (pos / A.clamp(1.0, 200.0)) * phaseRX;
    final phY = phaseCY - (vel / (A * omega).clamp(1.0, 1000.0)) * phaseRY;
    canvas.drawCircle(Offset(phX, phY), 4, Paint()..color = const Color(0xFF00D4FF));

    // x(t) waveform — bottom right
    final waveY = phaseH + 14;
    final waveH = h - waveY - 8;
    final waveMidY = waveY + waveH / 2;

    _text(canvas, 'x(t)', Offset(rightX, waveY - 2),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));

    canvas.drawLine(Offset(rightX, waveMidY), Offset(rightX + rightW, waveMidY),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.8);

    final wavePath = Path();
    bool wFirst = true;
    final period = 2 * math.pi / omega;
    for (int i = 0; i <= 80; i++) {
      final t2 = time - period * 1.5 + i / 80 * period * 2;
      final xv = A * math.cos(omega * t2);
      final wx = rightX + i / 80 * rightW;
      final wy = waveMidY - xv / A.clamp(1.0, 200.0) * waveH * 0.45;
      if (wFirst) { wavePath.moveTo(wx, wy); wFirst = false; } else { wavePath.lineTo(wx, wy); }
    }
    canvas.drawPath(wavePath, Paint()
      ..color = const Color(0xFF00D4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // ── ENERGY BARS (bottom left) ──────────────────────────
    final eBarX = 8.0;
    final eBarY = h * 0.74;
    final eBarH = h - eBarY - 8;
    final eBarW = springX - 16;

    final ke = 0.5 * mass * vel * vel;
    final pe = 0.5 * springK * pos * pos;
    final totalE = 0.5 * springK * A * A;

    _text(canvas, '에너지', Offset(eBarX, eBarY - 10),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));

    void eBar(double y, double frac, Color c, String lbl) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(eBarX, y, eBarW, 8), const Radius.circular(2)),
        Paint()..color = c.withValues(alpha: 0.15),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(eBarX, y, (frac * eBarW).clamp(0, eBarW), 8), const Radius.circular(2)),
        Paint()..color = c.withValues(alpha: 0.8),
      );
      _text(canvas, lbl, Offset(eBarX + eBarW + 3, y - 1),
          TextStyle(color: c.withValues(alpha: 0.9), fontSize: 7));
    }

    final gap = eBarH / 3.5;
    eBar(eBarY, ke / totalE.clamp(0.01, 1e9), const Color(0xFFFF6B35), 'KE');
    eBar(eBarY + gap, pe / totalE.clamp(0.01, 1e9), const Color(0xFF00D4FF), 'PE');
    eBar(eBarY + gap * 2, 1.0, const Color(0xFFE0F4FF), 'E');
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _SimpleHarmonicScreenPainter oldDelegate) => true;
}
