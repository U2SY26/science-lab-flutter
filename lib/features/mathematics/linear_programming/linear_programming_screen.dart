import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class LinearProgrammingScreen extends StatefulWidget {
  const LinearProgrammingScreen({super.key});
  @override
  State<LinearProgrammingScreen> createState() => _LinearProgrammingScreenState();
}

class _LinearProgrammingScreenState extends State<LinearProgrammingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _objAngle = 0.7;
  double _constraint1 = 6.0;
  double _optX = 0, _optY = 0, _objValue = 0;

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
      _optX = (_constraint1 * 0.6).clamp(0, 8);
      _optY = (_constraint1 * 0.4).clamp(0, 6);
      _objValue = _optX * math.cos(_objAngle) + _optY * math.sin(_objAngle);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _objAngle = 0.7;
      _constraint1 = 6.0;
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
          const Text('선형 계획법', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '선형 계획법',
          formula: 'max c·x  s.t.  Ax ≤ b',
          formulaDescription: '제약 조건 내에서 목적 함수를 최적화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _LinearProgrammingScreenPainter(
                time: _time,
                objAngle: _objAngle,
                constraint1: _constraint1,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '목적함수 방향',
                value: _objAngle,
                min: 0.0,
                max: 3.14,
                step: 0.05,
                defaultValue: 0.7,
                formatValue: (v) => '${(v * 180 / math.pi).toStringAsFixed(0)}°',
                onChanged: (v) => setState(() => _objAngle = v),
              ),
              advancedControls: [
            SimSlider(
                label: '제약식 1 한계',
                value: _constraint1,
                min: 2.0,
                max: 12.0,
                defaultValue: 6.0,
                formatValue: (v) => '${v.toStringAsFixed(0)}',
                onChanged: (v) => setState(() => _constraint1 = v),
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
          _V('최적 x', '${_optX.toStringAsFixed(1)}'),
          _V('최적 y', '${_optY.toStringAsFixed(1)}'),
          _V('목적값', '${_objValue.toStringAsFixed(2)}'),
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

class _LinearProgrammingScreenPainter extends CustomPainter {
  final double time;
  final double objAngle;
  final double constraint1;

  _LinearProgrammingScreenPainter({
    required this.time,
    required this.objAngle,
    required this.constraint1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Plot area [0, b] x [0, b] with b = constraint1
    final b = constraint1;
    final padL = 34.0, padR = 12.0, padT = 20.0, padB = 24.0;
    final plotW = w - padL - padR;
    final plotH = h * 0.70 - padT - padB;

    // Coordinate transforms: data [0, b+1] -> screen
    final domMax = b + 1.0;
    double sx(double x) => padL + x / domMax * plotW;
    double sy(double y) => padT + plotH - y / domMax * plotH;

    // Grid
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5;
    for (int i = 0; i <= 5; i++) {
      canvas.drawLine(Offset(sx(i * domMax / 5), padT), Offset(sx(i * domMax / 5), padT + plotH), gridP);
      canvas.drawLine(Offset(padL, sy(i * domMax / 5)), Offset(padL + plotW, sy(i * domMax / 5)), gridP);
    }

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1;
    canvas.drawLine(Offset(padL, padT), Offset(padL, padT + plotH), axisPaint);
    canvas.drawLine(Offset(padL, padT + plotH), Offset(padL + plotW, padT + plotH), axisPaint);
    _text(canvas, 'x₁', Offset(padL + plotW - 10, padT + plotH + 5),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));
    _text(canvas, 'x₂', Offset(padL - 14, padT - 2),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));

    // Axis tick labels
    for (int i = 0; i <= 3; i++) {
      final val = (b * i / 3).toStringAsFixed(0);
      _text(canvas, val, Offset(sx(b * i / 3) - 4, padT + plotH + 4),
          const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));
      _text(canvas, val, Offset(padL - 16, sy(b * i / 3) - 4),
          const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));
    }

    _text(canvas, '선형 계획법  max c·x  s.t. Ax≤b', Offset(w / 2 - 76, 4),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 9, fontWeight: FontWeight.bold));

    // Constraints:
    //   C1: x1 + x2 <= b         (active)
    //   C2: x1 <= b*0.8
    //   C3: x2 <= b*0.8
    //   x1 >= 0, x2 >= 0
    final c2 = b * 0.8;
    final c3 = b * 0.8;

    // Feasible region vertices (polygon):
    // O=(0,0), A=(c2,0), B=(b-c2>0?(c2,b-c2):(c2,0):...) complex
    // Simplify: vertices of intersection
    // x1+x2=b, x1=c2 => x2=b-c2
    // x1+x2=b, x2=c3 => x1=b-c3
    final vx = [0.0, c2, math.min(c2, b - c3), b - c3, 0.0];
    final vy = [0.0, 0.0, b - math.min(c2, b - c3), c3, c3];
    // Filter valid vertices
    final polyPts = <Offset>[];
    for (int i = 0; i < vx.length; i++) {
      if (vx[i] >= -0.01 && vy[i] >= -0.01) {
        polyPts.add(Offset(sx(vx[i].clamp(0, domMax)), sy(vy[i].clamp(0, domMax))));
      }
    }

    // Fill feasible region
    if (polyPts.length >= 3) {
      final path = Path()..moveTo(polyPts[0].dx, polyPts[0].dy);
      for (int i = 1; i < polyPts.length; i++) { path.lineTo(polyPts[i].dx, polyPts[i].dy); }
      path.close();
      canvas.drawPath(path, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.1));
    }

    // Constraint lines
    void drawConstraintLine(double x1a, double y1a, double x2a, double y2a, Color col, String lbl) {
      canvas.drawLine(Offset(sx(x1a), sy(y1a)), Offset(sx(x2a), sy(y2a)),
          Paint()..color = col..strokeWidth = 1.2..strokeCap = StrokeCap.round);
      _text(canvas, lbl, Offset(sx(x2a) + 2, sy(y2a) - 4), TextStyle(color: col, fontSize: 7));
    }

    drawConstraintLine(0, b, b, 0, const Color(0xFF00D4FF), 'C₁');
    drawConstraintLine(c2, 0, c2, domMax.clamp(0, b * 1.1), const Color(0xFFFF6B35), 'C₂');
    drawConstraintLine(0, c3, domMax.clamp(0, b * 1.1), c3, const Color(0xFF64FF8C), 'C₃');

    // Vertex dots
    final corners = [
      Offset(sx(0), sy(0)),
      Offset(sx(c2), sy(0)),
      Offset(sx(c2), sy(b - c2)),
      Offset(sx(b - c3), sy(c3)),
      Offset(sx(0), sy(c3)),
    ];
    for (final pt in corners) {
      canvas.drawCircle(pt, 3.5, Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.7));
    }

    // Objective function contour (moving line): c1*x1 + c2*x2 = z
    final c1 = math.cos(objAngle);
    final c2obj = math.sin(objAngle);

    // Optimal vertex: maximize c1*x1+c2*x2 over corners
    double bestZ = double.negativeInfinity;
    Offset bestPt = corners[0];
    final candidateData = [
      (0.0, 0.0), (c2, 0.0), (c2, b - c2), (b - c3, c3), (0.0, c3),
    ];
    for (final cd in candidateData) {
      final z = c1 * cd.$1 + c2obj * cd.$2;
      if (z > bestZ) { bestZ = z; bestPt = Offset(sx(cd.$1), sy(cd.$2)); }
    }

    // Animated iso-lines
    for (int k = 1; k <= 3; k++) {
      final zk = bestZ * k / 3.5;
      // c1*x + c2obj*y = zk => y = (zk - c1*x)/c2obj  or x = (zk - c2obj*y)/c1
      if (c2obj.abs() > 0.01) {
        final xL = 0.0;
        final yL = (zk - c1 * xL) / c2obj;
        final xR = domMax;
        final yR = (zk - c1 * xR) / c2obj;
        canvas.drawLine(
          Offset(sx(xL), sy(yL.clamp(-1, domMax + 1))),
          Offset(sx(xR), sy(yR.clamp(-1, domMax + 1))),
          Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.2 + k * 0.1)..strokeWidth = 0.8,
        );
      }
    }

    // Optimal point star
    canvas.drawCircle(bestPt, 6, Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.3));
    canvas.drawCircle(bestPt, 4, Paint()..color = const Color(0xFFFFD700));
    _text(canvas, 'z*=${bestZ.toStringAsFixed(1)}', Offset(bestPt.dx + 6, bestPt.dy - 10),
        const TextStyle(color: Color(0xFFFFD700), fontSize: 8, fontWeight: FontWeight.bold));

    // ── Bottom: summary ───────────────────────────────────────
    final sumY = h * 0.70 + 4;
    final optX = candidateData.reduce((a, b2) {
      return (c1 * a.$1 + c2obj * a.$2) >= (c1 * b2.$1 + c2obj * b2.$2) ? a : b2;
    });
    _text(canvas, '최적해: (x₁=${optX.$1.toStringAsFixed(1)}, x₂=${optX.$2.toStringAsFixed(1)})  z*=${bestZ.toStringAsFixed(2)}',
        Offset(padL, sumY),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));
    _text(canvas, '목적함수 방향: ${(objAngle * 180 / math.pi).toStringAsFixed(0)}°',
        Offset(padL, sumY + 12),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));
    _text(canvas, '★ 최적해는 항상 꼭짓점에 존재',
        Offset(padL, sumY + 24),
        const TextStyle(color: Color(0xFF64FF8C), fontSize: 8));
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _LinearProgrammingScreenPainter oldDelegate) => true;
}
