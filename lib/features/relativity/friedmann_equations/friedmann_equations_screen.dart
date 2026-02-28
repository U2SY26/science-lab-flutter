import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class FriedmannEquationsScreen extends StatefulWidget {
  const FriedmannEquationsScreen({super.key});
  @override
  State<FriedmannEquationsScreen> createState() => _FriedmannEquationsScreenState();
}

class _FriedmannEquationsScreenState extends State<FriedmannEquationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _omegaM = 0.3;
  double _omegaL = 0.7;
  double _hubble = 70, _curvature = 0;

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
      _curvature = 1 - _omegaM - _omegaL;
      _hubble = 70 * math.sqrt(_omegaM + _omegaL + _curvature);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _omegaM = 0.3; _omegaL = 0.7;
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
          const Text('프리드만 방정식', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '프리드만 방정식',
          formula: 'H² = 8πGρ/3 - k/a²',
          formulaDescription: '프리드만 방정식으로 우주 팽창을 모델링합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _FriedmannEquationsScreenPainter(
                time: _time,
                omegaM: _omegaM,
                omegaL: _omegaL,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'Ω_m (물질 밀도)',
                value: _omegaM,
                min: 0,
                max: 2,
                step: 0.01,
                defaultValue: 0.3,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _omegaM = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'Ω_Λ (암흑 에너지)',
                value: _omegaL,
                min: 0,
                max: 2,
                step: 0.01,
                defaultValue: 0.7,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _omegaL = v),
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
          _V('H₀', _hubble.toStringAsFixed(1) + ' km/s/Mpc'),
          _V('곡률', _curvature.toStringAsFixed(2)),
          _V('Ω', (_omegaM + _omegaL).toStringAsFixed(2)),
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

class _FriedmannEquationsScreenPainter extends CustomPainter {
  final double time;
  final double omegaM;
  final double omegaL;

  _FriedmannEquationsScreenPainter({
    required this.time,
    required this.omegaM,
    required this.omegaL,
  });

  // Compute scale factor a(t) for given cosmological parameters
  // Uses simplified Friedmann integration
  // omegaK = 1 - omegaM - omegaL
  double _scaleAt(double t, double oM, double oL) {
    // Use simple power law + exponential approximation
    final omegaK = (1.0 - oM - oL).clamp(-1.0, 1.0);
    if (t <= 0) return 0.001;
    if (oL > 0.8 && oM < 0.3) {
      // Dark energy dominated: exponential late-time
      final a0 = math.pow(t, 2.0 / 3.0).toDouble();
      return a0 * math.exp(math.sqrt(oL / 3.0) * (t - 1.0) * 0.5);
    } else if (omegaK > 0.3) {
      // Open universe: faster expansion
      return math.pow(t, 0.5).toDouble() * (1.0 + omegaK * 0.3 * t);
    } else if (omegaK < -0.3) {
      // Closed universe: expansion then contraction
      final peak = 1.5 / oM.clamp(0.1, 5.0);
      if (t < peak) {
        return math.pow(t / peak, 2.0 / 3.0).toDouble();
      } else {
        return math.pow((2 * peak - t) / peak, 2.0 / 3.0).toDouble().clamp(0.001, 2.0);
      }
    } else {
      // Flat: a ∝ t^(2/3)
      return math.pow(t, 2.0 / 3.0).toDouble();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    const padL = 50.0;
    const padR = 16.0;
    const padT = 30.0;
    const padB = 36.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;
    final originX = padL;
    final originY = padT + h;

    void drawText(String txt, Offset pos,
        {Color color = const Color(0xFF5A8A9A), double fs = 9}) {
      final tp = TextPainter(
        text: TextSpan(text: txt, style: TextStyle(color: color, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 8; i++) {
      final x = originX + w * i / 8;
      canvas.drawLine(Offset(x, padT), Offset(x, originY), gridPaint);
    }
    for (int i = 0; i <= 6; i++) {
      final y = padT + h * i / 6;
      canvas.drawLine(Offset(originX, y), Offset(originX + w, y), gridPaint);
    }

    // Axes
    final axisPaint = Paint()
      ..color = const Color(0xFF5A8A9A)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(originX, originY), Offset(originX + w, originY), axisPaint);
    canvas.drawLine(Offset(originX, originY), Offset(originX, padT), axisPaint);
    drawText('t', Offset(originX + w - 6, originY + 4));
    drawText('a(t)', Offset(2, padT - 2));

    // Axis tick labels
    for (int i = 1; i <= 4; i++) {
      final x = originX + w * i / 4;
      drawText('${i}τ', Offset(x - 4, originY + 4));
    }
    for (int i = 1; i <= 3; i++) {
      final y = originY - h * i / 3;
      drawText('${i}', Offset(2, y - 5));
    }

    // Big Bang marker
    canvas.drawLine(Offset(originX, originY), Offset(originX, originY - 10),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);
    drawText('빅뱅', Offset(originX - 14, originY + 4), color: const Color(0xFFFF6B35), fs: 8);

    // Time axis range: 0..4
    const tMax = 4.0;
    const aMax = 3.0;

    Offset toCanvas(double t, double a) => Offset(
          originX + w * t / tMax,
          originY - h * a / aMax,
        );

    // Helper to draw a cosmological model curve
    void drawCurve(double oM, double oL, Color color, double strokeW) {
      final path = Path();
      bool first = true;
      for (int i = 1; i <= 300; i++) {
        final t = i / 300.0 * tMax;
        final a = _scaleAt(t, oM, oL);
        if (a < 0 || a.isNaN || a.isInfinite) {
          first = true;
          continue;
        }
        final pt = toCanvas(t, a);
        if (pt.dy < padT - 5) {
          first = true;
          continue;
        }
        if (first) {
          path.moveTo(pt.dx, pt.dy);
          first = false;
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path,
          Paint()
            ..color = color
            ..strokeWidth = strokeW
            ..style = PaintingStyle.stroke);
    }

    // Closed universe (Ω>1): orange parabola
    drawCurve(1.5, 0.0, const Color(0xFFFF6B35), 1.8);
    drawText('Ω>1 닫힌', Offset(originX + w * 0.55, padT + 14),
        color: const Color(0xFFFF6B35), fs: 8);

    // Flat universe (Ω=1): cyan a∝t^2/3
    drawCurve(1.0, 0.0, const Color(0xFF00D4FF), 2.2);
    drawText('Ω=1 평탄', Offset(originX + w * 0.62, padT + h * 0.28),
        color: const Color(0xFF00D4FF), fs: 8);

    // Open universe (Ω<1): muted a∝t^1/2
    drawCurve(0.3, 0.0, const Color(0xFF5A8A9A), 1.8);
    drawText('Ω<1 열린', Offset(originX + w * 0.68, padT + h * 0.48),
        color: const Color(0xFF5A8A9A), fs: 8);

    // Dark energy model (current user parameters)
    drawCurve(omegaM, omegaL, const Color(0xFF64FF8C), 2.0);

    // Current universe position marker (t = 1 unit = today)
    final tNow = 1.0;
    final aNow = _scaleAt(tNow, omegaM, omegaL).clamp(0.001, aMax);
    final nowPt = toCanvas(tNow, aNow);
    if (nowPt.dy >= padT && nowPt.dy <= originY) {
      // Vertical dashed line at t=now
      final dashPt = Paint()
        ..color = const Color(0xFF64FF8C).withValues(alpha: 0.4)
        ..strokeWidth = 1.0;
      for (double y2 = nowPt.dy; y2 <= originY; y2 += 6) {
        canvas.drawLine(Offset(nowPt.dx, y2), Offset(nowPt.dx, y2 + 3), dashPt);
      }
      canvas.drawCircle(nowPt, 5, Paint()..color = const Color(0xFF64FF8C));
      canvas.drawCircle(nowPt, 7,
          Paint()
            ..color = const Color(0xFF64FF8C).withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      drawText('현재', Offset(nowPt.dx + 4, nowPt.dy - 14),
          color: const Color(0xFF64FF8C), fs: 8);
    }

    // Hubble constant indicator
    final omegaTot = omegaM + omegaL;
    final curvatureK = 1.0 - omegaTot;
    final curvLabel = curvatureK.abs() < 0.05
        ? '평탄'
        : (curvatureK > 0 ? '열린' : '닫힌');
    drawText('Ω_m=${omegaM.toStringAsFixed(2)}  Ω_Λ=${omegaL.toStringAsFixed(2)}  K:$curvLabel',
        Offset(originX + 4, padT + 4),
        color: const Color(0xFF5A8A9A), fs: 8);

    // Dark energy acceleration note
    if (omegaL > 0.3) {
      drawText('가속 팽창 (Λ>0)', Offset(originX + w * 0.1, padT + 16),
          color: const Color(0xFF64FF8C), fs: 8);
    }
  }

  @override
  bool shouldRepaint(covariant _FriedmannEquationsScreenPainter oldDelegate) => true;
}
