import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ParametricCurvesScreen extends StatefulWidget {
  const ParametricCurvesScreen({super.key});
  @override
  State<ParametricCurvesScreen> createState() => _ParametricCurvesScreenState();
}

class _ParametricCurvesScreenState extends State<ParametricCurvesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _curveType = 0;
  double _paramR = 0.3;


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
      
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _curveType = 0; _paramR = 0.3;
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
          Text('수학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('매개변수 곡선', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '매개변수 곡선',
          formula: 'x=f(t), y=g(t)',
          formulaDescription: '사이클로이드와 에피사이클로이드 같은 매개변수 곡선을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ParametricCurvesScreenPainter(
                time: _time,
                curveType: _curveType,
                paramR: _paramR,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '곡선 종류',
                value: _curveType,
                min: 0,
                max: 3,
                step: 1,
                defaultValue: 0,
                formatValue: (v) => ['사이클로이드','에피사이클로이드','하이포사이클로이드','인볼류트'][v.toInt()],
                onChanged: (v) => setState(() => _curveType = v),
              ),
              advancedControls: [
            SimSlider(
                label: '반지름 비 r/R',
                value: _paramR,
                min: 0.1,
                max: 1,
                step: 0.05,
                defaultValue: 0.3,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _paramR = v),
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
          _V('종류', ['사이클로이드','에피','하이포','인볼류트'][_curveType.toInt()]),
          _V('r/R', _paramR.toStringAsFixed(2)),
          _V('시간', _time.toStringAsFixed(1)),
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

class _ParametricCurvesScreenPainter extends CustomPainter {
  final double time;
  final double curveType;
  final double paramR;

  _ParametricCurvesScreenPainter({required this.time, required this.curveType, required this.paramR});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 10 || size.height < 10) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final type = curveType.round();
    final r = paramR;
    final R = math.min(cx, cy) * 0.55;

    // Trail path (history of positions)
    const trailSteps = 300;
    final tNow = time * 0.6;
    final trailPath = Path();
    bool started = false;

    for (int s = 0; s <= trailSteps; s++) {
      final t = tNow - (trailSteps - s) * 0.04;
      if (t < 0) continue;
      Offset pt;
      switch (type) {
        case 0: // Cycloid
          pt = Offset(cx - R + (R * r) * (t - math.sin(t)), cy + (R * r) * (1 - math.cos(t)) - R * r);
          // Wrap x
          pt = Offset(((pt.dx - 20) % (size.width - 40)) + 20, pt.dy);
          break;
        case 1: // Epicycloid
          pt = Offset(
            cx + R * (1 + r) * math.cos(t) - R * r * math.cos((1 + r) / r * t),
            cy + R * (1 + r) * math.sin(t) - R * r * math.sin((1 + r) / r * t),
          );
          break;
        case 2: // Hypocycloid
          pt = Offset(
            cx + R * (1 - r) * math.cos(t) + R * r * math.cos((1 - r) / r * t),
            cy + R * (1 - r) * math.sin(t) - R * r * math.sin((1 - r) / r * t),
          );
          break;
        default: // Involute
          pt = Offset(
            cx + R * r * (math.cos(t) + t * math.sin(t)),
            cy + R * r * (math.sin(t) - t * math.cos(t)),
          );
      }
      if (!started) { trailPath.moveTo(pt.dx, pt.dy); started = true; }
      else { trailPath.lineTo(pt.dx, pt.dy); }
    }

    // Draw fading trail
    canvas.drawPath(trailPath, Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke);

    // Draw generating mechanism for current t
    final tCur = tNow;
    switch (type) {
      case 0: // Rolling circle under baseline
        final baseY = cy;
        final rollingR = R * r;
        final rollingCx = cx + rollingR * (tCur - math.sin(tCur)) - R * r;
        final rollingCy = baseY + rollingR;
        canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY),
          Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1.5);
        canvas.drawCircle(Offset(rollingCx, rollingCy), rollingR,
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)..strokeWidth = 1.5..style = PaintingStyle.stroke);
        final dotX = rollingCx + rollingR * math.cos(tCur - math.pi / 2);
        final dotY = rollingCy + rollingR * math.sin(tCur - math.pi / 2);
        canvas.drawCircle(Offset(dotX, dotY), 5, Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.fill);
        break;
      case 1: // Epicycloid outer circle
        canvas.drawCircle(Offset(cx, cy), R,
          Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1.2..style = PaintingStyle.stroke);
        final eCx = cx + R * (1 + r) * math.cos(tCur);
        final eCy = cy + R * (1 + r) * math.sin(tCur);
        canvas.drawCircle(Offset(eCx, eCy), R * r,
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)..strokeWidth = 1.2..style = PaintingStyle.stroke);
        canvas.drawCircle(Offset(eCx, eCy), 4, Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.fill);
        break;
      case 2: // Hypocycloid inner circle
        canvas.drawCircle(Offset(cx, cy), R,
          Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1.2..style = PaintingStyle.stroke);
        final hCx = cx + R * (1 - r) * math.cos(tCur);
        final hCy = cy + R * (1 - r) * math.sin(tCur);
        canvas.drawCircle(Offset(hCx, hCy), R * r,
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)..strokeWidth = 1.2..style = PaintingStyle.stroke);
        canvas.drawCircle(Offset(hCx, hCy), 4, Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.fill);
        break;
      default: // Involute: base circle + unwinding string
        canvas.drawCircle(Offset(cx, cy), R * r,
          Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1.2..style = PaintingStyle.stroke);
        final iDotX = cx + R * r * (math.cos(tCur) + tCur * math.sin(tCur));
        final iDotY = cy + R * r * (math.sin(tCur) - tCur * math.cos(tCur));
        canvas.drawLine(Offset(cx + R * r * math.cos(tCur), cy + R * r * math.sin(tCur)),
          Offset(iDotX, iDotY),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)..strokeWidth = 1.5);
        canvas.drawCircle(Offset(iDotX, iDotY), 5, Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.fill);
    }

    // Curve name label
    const names = ['사이클로이드', '에피사이클로이드', '하이포사이클로이드', '인볼류트'];
    final ltp = TextPainter(
      text: TextSpan(text: names[type.clamp(0, 3)], style: const TextStyle(color: Color(0xFFE0F4FF), fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    ltp.paint(canvas, Offset(8, 8));
  }

  @override
  bool shouldRepaint(covariant _ParametricCurvesScreenPainter oldDelegate) => true;
}
