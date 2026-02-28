import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class IdealSolutionScreen extends StatefulWidget {
  const IdealSolutionScreen({super.key});
  @override
  State<IdealSolutionScreen> createState() => _IdealSolutionScreenState();
}

class _IdealSolutionScreenState extends State<IdealSolutionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _moleFraction = 0.5;
  double _purePressure = 100;
  double _partialP = 0, _totalP = 0;

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
      _partialP = _moleFraction * _purePressure;
      _totalP = _partialP + (1 - _moleFraction) * _purePressure * 0.6;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _moleFraction = 0.5; _purePressure = 100;
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
          Text('화학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('라울 법칙', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '라울 법칙',
          formula: 'P_A = x_A · P*_A',
          formulaDescription: '라울 법칙으로 이상 용액의 행동을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _IdealSolutionScreenPainter(
                time: _time,
                moleFraction: _moleFraction,
                purePressure: _purePressure,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '몰 분율 x_A',
                value: _moleFraction,
                min: 0,
                max: 1,
                step: 0.05,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _moleFraction = v),
              ),
              advancedControls: [
            SimSlider(
                label: '순수 증기압 P*_A (kPa)',
                value: _purePressure,
                min: 10,
                max: 200,
                step: 5,
                defaultValue: 100,
                formatValue: (v) => '${v.toStringAsFixed(0)} kPa',
                onChanged: (v) => setState(() => _purePressure = v),
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
          _V('P_A', '${_partialP.toStringAsFixed(1)} kPa'),
          _V('P_total', '${_totalP.toStringAsFixed(1)} kPa'),
          _V('x_A', _moleFraction.toStringAsFixed(2)),
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

class _IdealSolutionScreenPainter extends CustomPainter {
  final double time;
  final double moleFraction;
  final double purePressure;

  _IdealSolutionScreenPainter({
    required this.time,
    required this.moleFraction,
    required this.purePressure,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;

    // Axes margins
    final left = 42.0, right = 12.0, top = 18.0, bottom = 36.0;
    final plotW = w - left - right;
    final plotH = h - top - bottom;
    final pStarA = purePressure;          // P*_A
    final pStarB = purePressure * 0.6;    // P*_B (fixed ratio)
    final maxP = pStarA * 1.05;

    // Coordinate helpers
    Offset coord(double xFrac, double p) => Offset(
      left + xFrac * plotW,
      top + plotH * (1 - p / maxP),
    );

    // Faint grid
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final gy = top + plotH * i / 4;
      canvas.drawLine(Offset(left, gy), Offset(left + plotW, gy), gridP);
      final gx = left + plotW * i / 4;
      canvas.drawLine(Offset(gx, top), Offset(gx, top + plotH), gridP);
    }

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.2;
    canvas.drawLine(Offset(left, top), Offset(left, top + plotH), axisPaint);
    canvas.drawLine(Offset(left, top + plotH), Offset(left + plotW, top + plotH), axisPaint);

    // Axis labels
    void axisLabel(String t, double x, double y, Color c, {double fs = 8}) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: TextStyle(color: c, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
    axisLabel('증기압 (kPa)', left - 28, top + plotH / 2, const Color(0xFF5A8A9A));
    axisLabel('몰 분율 x_A', left + plotW / 2, top + plotH + 20, const Color(0xFF5A8A9A));
    axisLabel('0', left - 8, top + plotH, const Color(0xFF5A8A9A));
    axisLabel('1', left + plotW + 4, top + plotH, const Color(0xFF5A8A9A));
    axisLabel(pStarA.toStringAsFixed(0), left - 8, top, const Color(0xFF00D4FF), fs: 7);
    axisLabel(pStarB.toStringAsFixed(0), left - 8, top + plotH * (1 - pStarB / maxP), const Color(0xFFFF6B35), fs: 7);

    // P_A = x_A * P*_A  (cyan line)
    final pathA = Path()..moveTo(coord(0, 0).dx, coord(0, 0).dy);
    pathA.lineTo(coord(1, pStarA).dx, coord(1, pStarA).dy);
    canvas.drawPath(pathA, Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.8..style = PaintingStyle.stroke);

    // P_B = (1-x_A) * P*_B  (orange line)
    final pathB = Path()..moveTo(coord(0, pStarB).dx, coord(0, pStarB).dy);
    pathB.lineTo(coord(1, 0).dx, coord(1, 0).dy);
    canvas.drawPath(pathB, Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.8..style = PaintingStyle.stroke);

    // P_total = x_A*P*_A + (1-x_A)*P*_B  (white line)
    final pathT = Path()..moveTo(coord(0, pStarB).dx, coord(0, pStarB).dy);
    pathT.lineTo(coord(1, pStarA).dx, coord(1, pStarA).dy);
    canvas.drawPath(pathT,
        Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.8)..strokeWidth = 2.0..style = PaintingStyle.stroke);

    // Current mole fraction vertical marker
    final xCur = moleFraction;
    final pACur = xCur * pStarA;
    final pBCur = (1 - xCur) * pStarB;
    final pTotCur = pACur + pBCur;

    canvas.drawLine(
      coord(xCur, 0),
      coord(xCur, maxP),
      Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.3)..strokeWidth = 1.0..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Dots at intersections
    canvas.drawCircle(coord(xCur, pACur), 5,
        Paint()..color = const Color(0xFF00D4FF)..style = PaintingStyle.fill);
    canvas.drawCircle(coord(xCur, pBCur), 5,
        Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.fill);
    canvas.drawCircle(coord(xCur, pTotCur), 6,
        Paint()..color = const Color(0xFFE0F4FF)..style = PaintingStyle.fill);

    // Legend
    void legendItem(String t, double x, double y, Color c) {
      canvas.drawLine(Offset(x, y + 4), Offset(x + 14, y + 4),
          Paint()..color = c..strokeWidth = 2.0);
      final tp = TextPainter(
        text: TextSpan(text: t, style: TextStyle(color: c, fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + 17, y));
    }
    legendItem('P_A (라울)', left + 2, top + 2, const Color(0xFF00D4FF));
    legendItem('P_B', left + 2, top + 14, const Color(0xFFFF6B35));
    legendItem('P_total', left + 2, top + 26, const Color(0xFFE0F4FF));

    // Current values display
    axisLabel('x_A=${xCur.toStringAsFixed(2)}  P_tot=${pTotCur.toStringAsFixed(1)} kPa',
        left + plotW / 2, top + plotH + 8, const Color(0xFFE0F4FF), fs: 9);
  }

  @override
  bool shouldRepaint(covariant _IdealSolutionScreenPainter oldDelegate) => true;
}
