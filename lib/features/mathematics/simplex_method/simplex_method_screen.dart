import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class SimplexMethodScreen extends StatefulWidget {
  const SimplexMethodScreen({super.key});
  @override
  State<SimplexMethodScreen> createState() => _SimplexMethodScreenState();
}

class _SimplexMethodScreenState extends State<SimplexMethodScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _step = 0.0;
  double _objValue = 0, _vertexX = 0, _vertexY = 0;

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
      _objValue = [0, 6, 14, 21, 24, 24][_step.toInt().clamp(0, 5)].toDouble();
      _vertexX = [0, 2, 3, 4, 4, 4][_step.toInt().clamp(0, 5)].toDouble();
      _vertexY = [0, 0, 2, 3, 4, 4][_step.toInt().clamp(0, 5)].toDouble();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _step = 0.0;
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
          const Text('심플렉스 알고리즘', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '심플렉스 알고리즘',
          formula: 'pivot → BFS → optimal',
          formulaDescription: '심플렉스 방법으로 선형 계획 문제를 단계별로 풉니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SimplexMethodScreenPainter(
                time: _time,
                step: _step,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '단계',
                value: _step,
                min: 0.0,
                max: 5.0,
                defaultValue: 0.0,
                formatValue: (v) => '${v.toInt()}/5',
                onChanged: (v) => setState(() => _step = v),
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
          _V('꼭짓점', '(${_vertexX.toInt()}, ${_vertexY.toInt()})'),
          _V('목적값', '${_objValue.toStringAsFixed(0)}'),
          _V('반복', '${_step.toInt()}'),
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

class _SimplexMethodScreenPainter extends CustomPainter {
  final double time;
  final double step;

  _SimplexMethodScreenPainter({
    required this.time,
    required this.step,
  });

  // Vertices of feasible polygon for problem: max 3x1+4x2 s.t. x1+x2<=4, x1<=3, x2<=3, x1,x2>=0
  static const _vertices = [
    (0.0, 0.0), // V0
    (3.0, 0.0), // V1
    (3.0, 1.0), // V2
    (1.0, 3.0), // V3
    (0.0, 3.0), // V4
  ];
  static const _objValues = [0.0, 9.0, 13.0, 15.0, 12.0];
  // Simplex path: V0 -> V1 -> V2 -> V3 (optimal)
  static const _path = [0, 1, 2, 3];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final currentStep = step.toInt().clamp(0, 5);

    // ── LEFT PANEL: feasible polygon + simplex path ──────────
    final plotW = w * 0.50;
    final padL = 30.0, padT = 20.0, padB = 24.0;
    final areaW = plotW - padL - 8;
    final areaH = h * 0.62 - padT - padB;
    const domMax = 4.5;

    double sx(double x) => padL + x / domMax * areaW;
    double sy(double y) => padT + areaH - y / domMax * areaH;

    // Grid
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      canvas.drawLine(Offset(sx(i.toDouble()), padT), Offset(sx(i.toDouble()), padT + areaH), gridP);
      canvas.drawLine(Offset(padL, sy(i.toDouble())), Offset(padL + areaW, sy(i.toDouble())), gridP);
    }

    // Axes
    canvas.drawLine(Offset(padL, padT), Offset(padL, padT + areaH),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(padL, padT + areaH), Offset(padL + areaW, padT + areaH),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _text(canvas, 'x₁', Offset(padL + areaW - 8, padT + areaH + 5),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));
    _text(canvas, 'x₂', Offset(padL - 14, padT - 2),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));

    _text(canvas, '심플렉스 알고리즘', Offset(4, 4),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold));

    // Feasible region fill
    final feasPath = Path()
      ..moveTo(sx(0), sy(0))
      ..lineTo(sx(3), sy(0))
      ..lineTo(sx(3), sy(1))
      ..lineTo(sx(1), sy(3))
      ..lineTo(sx(0), sy(3))
      ..close();
    canvas.drawPath(feasPath, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.08));
    canvas.drawPath(feasPath, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke..strokeWidth = 1.2);

    // Objective contour at current best
    final currentVertexIdx = currentStep < _path.length ? _path[currentStep] : _path.last;
    final bestZ = _objValues[currentVertexIdx];
    // 3x1+4x2=z => x2=(z-3x1)/4
    if (bestZ > 0) {
      final x1a = 0.0, y1a = bestZ / 4;
      final x2a = bestZ / 3, y2a = 0.0;
      canvas.drawLine(Offset(sx(x1a), sy(y1a.clamp(0, domMax))),
          Offset(sx(x2a.clamp(0, domMax)), sy(y2a)),
          Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.4)..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round);
    }

    // Simplex path so far
    for (int s = 0; s < currentStep && s < _path.length - 1; s++) {
      final v1 = _vertices[_path[s]];
      final v2 = _vertices[_path[s + 1]];
      canvas.drawLine(Offset(sx(v1.$1), sy(v1.$2)), Offset(sx(v2.$1), sy(v2.$2)),
          Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 2.0..strokeCap = StrokeCap.round);
    }

    // Vertices
    for (int i = 0; i < _vertices.length; i++) {
      final v = _vertices[i];
      final isActive = i == currentVertexIdx;
      final isPath = _path.take(currentStep + 1).contains(i);
      canvas.drawCircle(Offset(sx(v.$1), sy(v.$2)),
          isActive ? 6.0 : 3.5,
          Paint()..color = isActive
              ? const Color(0xFFFFD700)
              : isPath ? const Color(0xFF64FF8C) : const Color(0xFF5A8A9A).withValues(alpha: 0.6));
      _text(canvas, 'V$i', Offset(sx(v.$1) + 5, sy(v.$2) - 10),
          TextStyle(color: isActive ? const Color(0xFFFFD700) : const Color(0xFF5A8A9A), fontSize: 7));
    }

    // ── RIGHT PANEL: simplex table ───────────────────────────
    final tableX = plotW + 4;
    final tableW = w - tableX - 4;
    final tableY = 18.0;
    final colW = tableW / 4;
    const rowH = 18.0;

    _text(canvas, '심플렉스 표', Offset(tableX, tableY - 4),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8, fontWeight: FontWeight.bold));

    // Table header
    final headers = ['기저', 'x₁', 'x₂', 'z'];
    for (int c = 0; c < 4; c++) {
      canvas.drawRect(Rect.fromLTWH(tableX + c * colW, tableY + 4, colW, rowH),
          Paint()..color = const Color(0xFF1A3040));
      _text(canvas, headers[c], Offset(tableX + c * colW + 3, tableY + 7),
          const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7, fontWeight: FontWeight.bold));
    }

    // Table rows based on current step
    final tableData = [
      [['s₁', '1', '1', '0'], ['s₂', '1', '0', '0'], ['-z', '-3', '-4', '0']],
      [['s₁', '0', '1', '0'], ['x₁', '1', '0', '0'], ['-z', '0', '-4', '9']],
      [['s₂', '0', '1', '0'], ['x₁', '1', '0', '0'], ['-z', '0', '0', '13']],
      [['x₂', '0', '1', '0'], ['x₁', '1', '0', '0'], ['-z', '0', '0', '15']],
    ];
    final tData = tableData[currentStep.clamp(0, tableData.length - 1)];

    for (int r = 0; r < tData.length; r++) {
      final row = tData[r];
      for (int c = 0; c < 4; c++) {
        final isPivot = r == 1 && c == 1 && currentStep < 3;
        canvas.drawRect(Rect.fromLTWH(tableX + c * colW, tableY + 4 + (r + 1) * rowH, colW, rowH),
            Paint()..color = isPivot ? const Color(0xFF00D4FF).withValues(alpha: 0.15) : const Color(0xFF0D1A20));
        canvas.drawRect(Rect.fromLTWH(tableX + c * colW, tableY + 4 + (r + 1) * rowH, colW, rowH),
            Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.stroke..strokeWidth = 0.5);
        _text(canvas, row[c], Offset(tableX + c * colW + 3, tableY + 8 + (r + 1) * rowH),
            TextStyle(color: isPivot ? const Color(0xFF00D4FF) : const Color(0xFFE0F4FF), fontSize: 7));
      }
    }

    // Objective value progression chart
    final chartY = tableY + 4 + 4 * rowH + 12;
    final chartH = h - chartY - 8;
    final chartW = tableW;

    _text(canvas, '목적값 수렴', Offset(tableX, chartY - 2),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7, fontWeight: FontWeight.bold));

    canvas.drawLine(Offset(tableX, chartY + chartH), Offset(tableX + chartW, chartY + chartH),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.8);

    final zMax = _objValues.reduce(math.max);
    final convPath = Path();
    bool firstZ = true;
    for (int s = 0; s <= currentStep && s < _path.length; s++) {
      final zv = _objValues[_path[s]];
      final gx = tableX + s / (_path.length - 1) * chartW;
      final gy = chartY + chartH - (zv / zMax) * chartH;
      if (firstZ) { convPath.moveTo(gx, gy); firstZ = false; } else { convPath.lineTo(gx, gy); }
      canvas.drawCircle(Offset(gx, gy), s == currentStep ? 4.5 : 2.5,
          Paint()..color = s == currentStep ? const Color(0xFFFFD700) : const Color(0xFF64FF8C));
      _text(canvas, '${_objValues[_path[s]].toInt()}', Offset(gx + 2, gy - 12),
          const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));
    }
    canvas.drawPath(convPath, Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Bottom status
    final status = currentStep >= _path.length - 1 ? '최적 (reduced cost ≥ 0)' : '피벗 진행 중...';
    _text(canvas, status, Offset(padL, h - 12),
        TextStyle(color: currentStep >= _path.length - 1 ? const Color(0xFF64FF8C) : const Color(0xFFFF6B35), fontSize: 8));
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _SimplexMethodScreenPainter oldDelegate) => true;
}
