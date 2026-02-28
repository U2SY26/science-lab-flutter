import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CarbonFixationScreen extends StatefulWidget {
  const CarbonFixationScreen({super.key});
  @override
  State<CarbonFixationScreen> createState() => _CarbonFixationScreenState();
}

class _CarbonFixationScreenState extends State<CarbonFixationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _co2Level = 400;
  
  double _fixRate = 1.0, _g3p = 0.0;

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
      _fixRate = _co2Level / 400;
      _g3p = _fixRate * _time * 0.1;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _co2Level = 400.0;
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
          Text('생물학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('탄소 고정 (캘빈 회로)', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '탄소 고정 (캘빈 회로)',
          formula: '3CO₂ + 9ATP + 6NADPH → G3P',
          formulaDescription: '캘빈 회로의 탄소 고정 과정을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CarbonFixationScreenPainter(
                time: _time,
                co2Level: _co2Level,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'CO₂ 농도 (ppm)',
                value: _co2Level,
                min: 100,
                max: 1000,
                step: 10,
                defaultValue: 400,
                formatValue: (v) => v.toStringAsFixed(0) + ' ppm',
                onChanged: (v) => setState(() => _co2Level = v),
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
          _V('고정율', _fixRate.toStringAsFixed(2)),
          _V('G3P', _g3p.toStringAsFixed(2) + ' mol'),
          _V('CO₂', _co2Level.toStringAsFixed(0) + ' ppm'),
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

class _CarbonFixationScreenPainter extends CustomPainter {
  final double time;
  final double co2Level;

  _CarbonFixationScreenPainter({
    required this.time,
    required this.co2Level,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final paint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, paint);
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final arrowHead = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - 8 * math.cos(angle - 0.4), to.dy - 8 * math.sin(angle - 0.4))
      ..lineTo(to.dx - 8 * math.cos(angle + 0.4), to.dy - 8 * math.sin(angle + 0.4))
      ..close();
    canvas.drawPath(arrowHead, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final cycleR = math.min(size.width, size.height) * 0.28;
    final speedFactor = co2Level / 400.0;

    // Stage node positions (3 stages at 120-degree intervals)
    const stageCount = 3;
    final stageAngles = [
      -math.pi / 2,                      // top: CO2 fixation
      -math.pi / 2 + 2 * math.pi / 3,   // bottom-right: reduction
      -math.pi / 2 + 4 * math.pi / 3,   // bottom-left: RuBP regen
    ];
    final stagePositions = stageAngles.map((a) => Offset(cx + cycleR * math.cos(a), cy + cycleR * math.sin(a))).toList();

    // Stage colors
    final stageColors = [
      const Color(0xFF00D4FF), // cyan - CO2 fixation
      const Color(0xFF64FF8C), // green - reduction
      const Color(0xFFFF6B35), // orange - RuBP regen
    ];

    final stageNames = ['탄소 고정', '환원', 'RuBP 재생'];
    final stageDetails = ['CO₂+RuBP→3-PGA', 'ATP+NADPH→G3P', 'G3P→RuBP'];

    // Draw cycle arc arrows between stages
    for (int i = 0; i < stageCount; i++) {
      final from = stagePositions[i];
      final to = stagePositions[(i + 1) % stageCount];
      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      // Curve outward slightly
      final dir = Offset(to.dx - from.dx, to.dy - from.dy);
      final perp = Offset(-dir.dy, dir.dx);
      final perpLen = math.sqrt(perp.dx * perp.dx + perp.dy * perp.dy);
      final ctrl = mid + Offset(perp.dx / perpLen * 18, perp.dy / perpLen * 18);

      final path = Path()..moveTo(from.dx, from.dy)..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);
      canvas.drawPath(path, Paint()..color = stageColors[i].withValues(alpha: 0.5)..strokeWidth = 2..style = PaintingStyle.stroke);

      // Arrow tip at midpoint of arc
      final tParam = 0.6;
      final arrowX = (1 - tParam) * (1 - tParam) * from.dx + 2 * (1 - tParam) * tParam * ctrl.dx + tParam * tParam * to.dx;
      final arrowY = (1 - tParam) * (1 - tParam) * from.dy + 2 * (1 - tParam) * tParam * ctrl.dy + tParam * tParam * to.dy;
      final dtX = 2 * (1 - tParam) * (ctrl.dx - from.dx) + 2 * tParam * (to.dx - ctrl.dx);
      final dtY = 2 * (1 - tParam) * (ctrl.dy - from.dy) + 2 * tParam * (to.dy - ctrl.dy);
      final arrowAngle = math.atan2(dtY, dtX);
      final arrowHead = Path()
        ..moveTo(arrowX, arrowY)
        ..lineTo(arrowX - 7 * math.cos(arrowAngle - 0.4), arrowY - 7 * math.sin(arrowAngle - 0.4))
        ..lineTo(arrowX - 7 * math.cos(arrowAngle + 0.4), arrowY - 7 * math.sin(arrowAngle + 0.4))
        ..close();
      canvas.drawPath(arrowHead, Paint()..color = stageColors[i]..style = PaintingStyle.fill);
    }

    // Draw stage nodes
    for (int i = 0; i < stageCount; i++) {
      final pos = stagePositions[i];
      final nodeR = 28.0;
      canvas.drawCircle(pos, nodeR, Paint()..color = stageColors[i].withValues(alpha: 0.18));
      canvas.drawCircle(pos, nodeR, Paint()..color = stageColors[i]..style = PaintingStyle.stroke..strokeWidth = 2);
      _drawLabel(canvas, stageNames[i], pos - const Offset(0, 7), stageColors[i], 8.5);
      _drawLabel(canvas, stageDetails[i], pos + const Offset(0, 6), const Color(0xFFE0F4FF), 7.0);
    }

    // Animated molecules on cycle path
    final moleculeCount = (3 * speedFactor).clamp(1, 5).toInt() + 2;
    for (int m = 0; m < moleculeCount; m++) {
      final t = (time * speedFactor * 0.4 + m / moleculeCount) % 1.0;
      // Determine which arc segment
      final segment = (t * stageCount).floor() % stageCount;
      final tInSeg = (t * stageCount) - segment;
      final from = stagePositions[segment];
      final to = stagePositions[(segment + 1) % stageCount];
      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      final dir = Offset(to.dx - from.dx, to.dy - from.dy);
      final perp = Offset(-dir.dy, dir.dx);
      final perpLen = math.sqrt(perp.dx * perp.dx + perp.dy * perp.dy);
      final ctrl = mid + Offset(perp.dx / perpLen * 18, perp.dy / perpLen * 18);
      final mx = (1 - tInSeg) * (1 - tInSeg) * from.dx + 2 * (1 - tInSeg) * tInSeg * ctrl.dx + tInSeg * tInSeg * to.dx;
      final my = (1 - tInSeg) * (1 - tInSeg) * from.dy + 2 * (1 - tInSeg) * tInSeg * ctrl.dy + tInSeg * tInSeg * to.dy;
      canvas.drawCircle(Offset(mx, my), 4, Paint()..color = stageColors[segment].withValues(alpha: 0.85));
    }

    // Center label
    _drawLabel(canvas, 'Calvin', Offset(cx, cy - 8), const Color(0xFF5A8A9A), 11);
    _drawLabel(canvas, 'Cycle', Offset(cx, cy + 8), const Color(0xFF5A8A9A), 11);

    // Inputs/outputs outside the cycle
    final topPos = stagePositions[0];

    // CO2 input arrow (into top node)
    final co2Pos = Offset(topPos.dx, topPos.dy - 52);
    _drawArrow(canvas, co2Pos, Offset(topPos.dx, topPos.dy - 28), const Color(0xFF5A8A9A));
    _drawLabel(canvas, 'CO₂ ×3', Offset(co2Pos.dx, co2Pos.dy - 8), const Color(0xFF9ECFDE), 9);

    // ATP + NADPH input for reduction
    final redPos = stagePositions[1];
    final atpPos = Offset(redPos.dx + 50, redPos.dy - 20);
    _drawArrow(canvas, atpPos, Offset(redPos.dx + 28, redPos.dy - 10), const Color(0xFF64FF8C));
    _drawLabel(canvas, 'ATP', Offset(atpPos.dx + 10, atpPos.dy - 8), const Color(0xFF64FF8C), 8.5);
    _drawLabel(canvas, 'NADPH', Offset(atpPos.dx + 10, atpPos.dy + 6), const Color(0xFF00D4FF), 8.5);

    // G3P output from reduction
    final g3pPos = Offset(redPos.dx + 52, redPos.dy + 22);
    _drawArrow(canvas, Offset(redPos.dx + 28, redPos.dy + 10), g3pPos, const Color(0xFF64FF8C));
    _drawLabel(canvas, 'G3P', Offset(g3pPos.dx + 12, g3pPos.dy), const Color(0xFFFFD700), 9);

    // Title
    _drawLabel(canvas, '캘빈 회로 (Calvin Cycle)', Offset(cx, 14), const Color(0xFF00D4FF), 11);
  }

  @override
  bool shouldRepaint(covariant _CarbonFixationScreenPainter oldDelegate) => true;
}
