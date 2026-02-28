import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class OrbitalTransferScreen extends StatefulWidget {
  const OrbitalTransferScreen({super.key});
  @override
  State<OrbitalTransferScreen> createState() => _OrbitalTransferScreenState();
}

class _OrbitalTransferScreenState extends State<OrbitalTransferScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _r1 = 1;
  double _r2 = 1.52;
  double _dv1 = 0, _dv2 = 0, _transferTime = 0;

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
      final a = (_r1 + _r2) / 2;
      _dv1 = (math.sqrt(2 * _r2 / (_r1 * (_r1 + _r2))) - 1 / math.sqrt(_r1)).abs() * 29.8;
      _dv2 = (1 / math.sqrt(_r2) - math.sqrt(2 * _r1 / (_r2 * (_r1 + _r2)))).abs() * 29.8;
      _transferTime = math.pi * math.sqrt(math.pow(a, 3).toDouble()) * 58.1;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _r1 = 1.0; _r2 = 1.52;
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
          const Text('호만 전이 궤도', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '호만 전이 궤도',
          formula: 'Δv = √(μ/r₁)(√(2r₂/(r₁+r₂))-1)',
          formulaDescription: '호만 전이 궤도의 에너지 효율을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _OrbitalTransferScreenPainter(
                time: _time,
                r1: _r1,
                r2: _r2,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '출발 궤도 (AU)',
                value: _r1,
                min: 0.3,
                max: 5,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' AU',
                onChanged: (v) => setState(() => _r1 = v),
              ),
              advancedControls: [
            SimSlider(
                label: '도착 궤도 (AU)',
                value: _r2,
                min: 0.3,
                max: 30,
                step: 0.1,
                defaultValue: 1.52,
                formatValue: (v) => v.toStringAsFixed(2) + ' AU',
                onChanged: (v) => setState(() => _r2 = v),
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
          _V('Δv₁', _dv1.toStringAsFixed(2) + ' km/s'),
          _V('Δv₂', _dv2.toStringAsFixed(2) + ' km/s'),
          _V('시간', _transferTime.toStringAsFixed(0) + ' days'),
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

class _OrbitalTransferScreenPainter extends CustomPainter {
  final double time;
  final double r1;
  final double r2;

  _OrbitalTransferScreenPainter({
    required this.time,
    required this.r1,
    required this.r2,
  });

  void _label(Canvas canvas, String text, Offset pos, Color col, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _arrowHead(Canvas canvas, Offset tip, double angle, Color col,
      double sz) {
    final p = Paint()
      ..color = col
      ..strokeWidth = 1.5;
    canvas.drawLine(
        tip,
        Offset(tip.dx - sz * math.cos(angle - 0.4),
            tip.dy - sz * math.sin(angle - 0.4)),
        p);
    canvas.drawLine(
        tip,
        Offset(tip.dx - sz * math.cos(angle + 0.4),
            tip.dy - sz * math.sin(angle + 0.4)),
        p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final cx = size.width / 2;
    final cy = size.height * 0.46;

    // Scale: r1 maps to a comfortable pixel radius
    final rMax = math.max(r1, r2);
    final availR = math.min(cx - 10, cy - 10) * 0.95;
    final scale = availR / rMax;

    final pr1 = r1 * scale; // inner orbit px
    final pr2 = r2 * scale; // outer orbit px

    // Transfer ellipse: semi-major = (r1+r2)/2, semi-minor derived
    final ta = (r1 + r2) / 2 * scale; // semi-major axis px
    final tb = math.sqrt(pr1 * pr2); // semi-minor axis px (geometric mean approx)
    final transferCx = cx + (pr2 - pr1) / 2; // ellipse centre offset

    // ── Inner circular orbit (LEO) ──
    canvas.drawCircle(
        Offset(cx, cy),
        pr1,
        Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // ── Outer circular orbit (GEO) ──
    canvas.drawCircle(
        Offset(cx, cy),
        pr2,
        Paint()
          ..color = const Color(0xFF64FF8C).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // ── Transfer ellipse (dashed) ──
    const dashCount = 48;
    final ellipsePaint = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        final a1 = 2 * math.pi * i / dashCount;
        final a2 = 2 * math.pi * (i + 0.7) / dashCount;
        final x1 = transferCx + ta * math.cos(a1);
        final y1 = cy + tb * math.sin(a1);
        final x2 = transferCx + ta * math.cos(a2);
        final y2 = cy + tb * math.sin(a2);
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), ellipsePaint);
      }
    }

    // ── Sun ──
    canvas.drawCircle(
        Offset(cx, cy),
        9,
        Paint()
          ..color = const Color(0xFFFFDD44).withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawCircle(
        Offset(cx, cy), 7, Paint()..color = const Color(0xFFFFEE88));

    // ── Spacecraft animation ──
    // Phase 1: on inner orbit → burn1 → transfer ellipse → burn2 → outer orbit
    // Period normalised to 8 seconds cycle
    final phase = (time * 0.2) % 1.0;
    final Offset shipPos;
    if (phase < 0.5) {
      // On transfer ellipse (half-period)
      final t = phase / 0.5; // 0..1 along transfer
      final a = math.pi + t * math.pi; // from periapsis (right) to apoapsis (left)
      final sx = transferCx + ta * math.cos(a);
      final sy = cy + tb * math.sin(a);
      shipPos = Offset(sx, sy);
    } else if (phase < 0.75) {
      // On outer orbit
      final t = (phase - 0.5) / 0.25;
      final a = math.pi - t * math.pi / 3;
      shipPos = Offset(cx + pr2 * math.cos(a), cy + pr2 * math.sin(a));
    } else {
      // On inner orbit
      final t = (phase - 0.75) / 0.25;
      final a = 0.0 - t * math.pi * 1.5;
      shipPos = Offset(cx + pr1 * math.cos(a), cy + pr1 * math.sin(a));
    }

    // Ship glow
    canvas.drawCircle(
        shipPos,
        6,
        Paint()
          ..color = const Color(0xFFFF6B35).withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(shipPos, 4, Paint()..color = const Color(0xFFFF6B35));

    // ── Burn points ──
    // Burn 1: periapsis (right side of transfer ellipse, = inner orbit)
    final burn1 = Offset(cx + pr1, cy);
    // Burn 2: apoapsis (left side of transfer ellipse, = outer orbit)
    final burn2 = Offset(cx - pr2, cy);

    // Δv1 arrow (tangential, upward at periapsis)
    final dv1Paint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2;
    canvas.drawLine(burn1, Offset(burn1.dx, burn1.dy - 18), dv1Paint);
    _arrowHead(canvas, Offset(burn1.dx, burn1.dy - 18), -math.pi / 2,
        const Color(0xFF00D4FF), 6);
    _label(canvas, 'Δv₁', Offset(burn1.dx + 3, burn1.dy - 22),
        const Color(0xFF00D4FF), 9);

    // Δv2 arrow
    final dv2Paint = Paint()
      ..color = const Color(0xFF64FF8C)
      ..strokeWidth = 2;
    canvas.drawLine(burn2, Offset(burn2.dx, burn2.dy - 18), dv2Paint);
    _arrowHead(canvas, Offset(burn2.dx, burn2.dy - 18), -math.pi / 2,
        const Color(0xFF64FF8C), 6);
    _label(canvas, 'Δv₂', Offset(burn2.dx + 3, burn2.dy - 22),
        const Color(0xFF64FF8C), 9);

    // Burn markers
    canvas.drawCircle(burn1, 4, Paint()..color = const Color(0xFF00D4FF));
    canvas.drawCircle(burn2, 4, Paint()..color = const Color(0xFF64FF8C));

    // ── Labels ──
    _label(canvas, 'LEO (r₁=${r1.toStringAsFixed(1)} AU)',
        Offset(cx + pr1 + 4, cy - 10), const Color(0xFF00D4FF), 8);
    _label(canvas, 'GEO (r₂=${r2.toStringAsFixed(1)} AU)',
        Offset(cx + pr2 + 4, cy - 10), const Color(0xFF64FF8C), 8);
    _label(canvas, '전이 궤도', Offset(cx - 20, cy + tb + 8),
        const Color(0xFFFF6B35), 8);

    // ── Energy diagram (bottom strip) ──
    final eTop = size.height * 0.80;
    final eH = size.height * 0.14;
    final eLeft = 10.0;
    final eRight = size.width - 10.0;
    final eW = eRight - eLeft;

    canvas.drawRect(
      Rect.fromLTWH(eLeft, eTop, eW, eH),
      Paint()..color = const Color(0xFF0A1520),
    );
    canvas.drawRect(
      Rect.fromLTWH(eLeft, eTop, eW, eH),
      Paint()
        ..color = const Color(0xFF1A3040)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Energy levels: E = -μ/(2a), so inner orbit has more negative energy
    // Normalise: inner orbit E at 70%, outer orbit E at 30% height
    const innerFrac = 0.8;
    const transferFrac = 0.5;
    const outerFrac = 0.2;
    final eyInner = eTop + eH * innerFrac;
    final eyTransfer = eTop + eH * transferFrac;
    final eyOuter = eTop + eH * outerFrac;

    // Draw horizontal lines for energy levels
    void eLine(double y, Color col, String lbl) {
      canvas.drawLine(
          Offset(eLeft + 40, y), Offset(eRight - 4, y),
          Paint()
            ..color = col.withValues(alpha: 0.6)
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke);
      _label(canvas, lbl, Offset(eLeft + 2, y - 5), col, 7);
    }

    eLine(eyInner, const Color(0xFF00D4FF), 'E(LEO)');
    eLine(eyTransfer, const Color(0xFFFF6B35), 'E(전이)');
    eLine(eyOuter, const Color(0xFF64FF8C), 'E(GEO)');

    _label(canvas, '에너지 준위', Offset(eLeft + eW / 2 - 20, eTop + 2),
        const Color(0xFF5A8A9A), 8);
  }

  @override
  bool shouldRepaint(covariant _OrbitalTransferScreenPainter oldDelegate) =>
      true;
}
