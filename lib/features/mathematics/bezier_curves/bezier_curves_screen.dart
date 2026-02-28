import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BezierCurvesScreen extends StatefulWidget {
  const BezierCurvesScreen({super.key});
  @override
  State<BezierCurvesScreen> createState() => _BezierCurvesScreenState();
}

class _BezierCurvesScreenState extends State<BezierCurvesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _tParam = 0.5;
  double _degree = 3;
  double _curveX = 0, _curveY = 0;

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
      _curveX = _tParam * 200;
      _curveY = 100 * math.sin(_tParam * math.pi);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _tParam = 0.5; _degree = 3.0;
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
          const Text('베지에 곡선', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '베지에 곡선',
          formula: 'B(t) = Σ C(n,i)t^i(1-t)^(n-i)P_i',
          formulaDescription: '베지에 곡선의 구성과 드 카스텔조 알고리즘을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BezierCurvesScreenPainter(
                time: _time,
                tParam: _tParam,
                degree: _degree,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 't (매개변수)',
                value: _tParam,
                min: 0,
                max: 1,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _tParam = v),
              ),
              advancedControls: [
            SimSlider(
                label: '차수 (n)',
                value: _degree,
                min: 1,
                max: 6,
                step: 1,
                defaultValue: 3,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _degree = v),
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
          _V('B(t)', '(${_curveX.toStringAsFixed(1)}, ${_curveY.toStringAsFixed(1)})'),
          _V('t', _tParam.toStringAsFixed(2)),
          _V('차수', _degree.toInt().toString()),
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

class _BezierCurvesScreenPainter extends CustomPainter {
  final double time;
  final double tParam;
  final double degree;

  _BezierCurvesScreenPainter({required this.time, required this.tParam, required this.degree});

  // Animated t: auto-loops 0→1 if running, else use tParam
  double get _t => (time * 0.25) % 1.0;

  // Fixed cubic control points (relative to canvas size)
  List<Offset> _controlPoints(Size size) {
    final w = size.width, h = size.height;
    return [
      Offset(w * 0.12, h * 0.75),
      Offset(w * 0.30, h * 0.15),
      Offset(w * 0.68, h * 0.85),
      Offset(w * 0.88, h * 0.25),
    ];
  }

  // de Casteljau single-step lerp
  List<Offset> _lerpLevel(List<Offset> pts, double t) =>
      List.generate(pts.length - 1, (i) => Offset(
        pts[i].dx + t * (pts[i+1].dx - pts[i].dx),
        pts[i].dy + t * (pts[i+1].dy - pts[i].dy),
      ));

  // Evaluate full curve at t → returns list of all levels
  List<List<Offset>> _casteljau(List<Offset> pts, double t) {
    final levels = <List<Offset>>[pts];
    var cur = pts;
    while (cur.length > 1) {
      cur = _lerpLevel(cur, t);
      levels.add(cur);
    }
    return levels;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 10 || size.height < 10) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final ctrl = _controlPoints(size);
    final animT = _t;

    // Draw full curve (traced history)
    const steps = 80;
    final curvePath = Path();
    for (int s = 0; s <= steps; s++) {
      final t = s / steps;
      final levels = _casteljau(ctrl, t);
      final pt = levels.last[0];
      if (s == 0) { curvePath.moveTo(pt.dx, pt.dy); } else { curvePath.lineTo(pt.dx, pt.dy); }
    }
    canvas.drawPath(curvePath, Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke);

    // Control polygon (dashed muted)
    final polyPaint = Paint()
      ..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < ctrl.length - 1; i++) {
      // Dashed: alternate segments
      final a = ctrl[i], b = ctrl[i + 1];
      const segs = 8;
      for (int s = 0; s < segs; s++) {
        if (s % 2 == 0) {
          canvas.drawLine(
            Offset(a.dx + (b.dx - a.dx) * s / segs, a.dy + (b.dy - a.dy) * s / segs),
            Offset(a.dx + (b.dx - a.dx) * (s + 0.6) / segs, a.dy + (b.dy - a.dy) * (s + 0.6) / segs),
            polyPaint,
          );
        }
      }
    }

    // de Casteljau construction lines at animT
    final levels = _casteljau(ctrl, animT);
    final levelColors = [
      const Color(0xFF64FF8C),  // level 1: green
      const Color(0xFFFFD700),  // level 2: yellow
      const Color(0xFFFF6B35),  // level 3: orange/red
    ];
    for (int lv = 1; lv < levels.length - 1; lv++) {
      final pts = levels[lv];
      final col = levelColors[(lv - 1).clamp(0, levelColors.length - 1)];
      final lp = Paint()..color = col.withValues(alpha: 0.8)..strokeWidth = 1.2..style = PaintingStyle.stroke;
      for (int i = 0; i < pts.length - 1; i++) {
        canvas.drawLine(pts[i], pts[i + 1], lp);
      }
      for (final p in pts) {
        canvas.drawCircle(p, 3, Paint()..color = col..style = PaintingStyle.fill);
      }
    }

    // Control points (orange squares)
    final cpPaint = Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.fill;
    final cpBorder = Paint()..color = const Color(0xFFFFD700)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    for (final p in ctrl) {
      canvas.drawRect(Rect.fromCenter(center: p, width: 10, height: 10), cpPaint);
      canvas.drawRect(Rect.fromCenter(center: p, width: 10, height: 10), cpBorder);
    }

    // Current point on curve
    final curPt = levels.last[0];
    canvas.drawCircle(curPt, 7, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.3)..style = PaintingStyle.fill);
    canvas.drawCircle(curPt, 5, Paint()..color = const Color(0xFF00D4FF)..style = PaintingStyle.fill);

    // t label
    final ltp = TextPainter(
      text: TextSpan(text: 't = ${animT.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFE0F4FF), fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    ltp.paint(canvas, Offset(8, size.height - 18));
  }

  @override
  bool shouldRepaint(covariant _BezierCurvesScreenPainter oldDelegate) => true;
}
