import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class LogisticGrowthScreen extends StatefulWidget {
  const LogisticGrowthScreen({super.key});
  @override
  State<LogisticGrowthScreen> createState() => _LogisticGrowthScreenState();
}

class _LogisticGrowthScreenState extends State<LogisticGrowthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _growthRate = 1;
  double _carryCapacity = 500;
  double _population = 10;

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
      final dN = _growthRate * _population * (1 - _population / _carryCapacity) * 0.016;
      _population = math.max(1, _population + dN);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _growthRate = 1.0; _carryCapacity = 500; _population = 10;
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
          const Text('로지스틱 개체군 성장', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '로지스틱 개체군 성장',
          formula: 'dN/dt = rN(1-N/K)',
          formulaDescription: '환경 수용력을 가진 개체군 성장을 모델링합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _LogisticGrowthScreenPainter(
                time: _time,
                growthRate: _growthRate,
                carryCapacity: _carryCapacity,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '성장률 r',
                value: _growthRate,
                min: 0.1,
                max: 3,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _growthRate = v),
              ),
              advancedControls: [
            SimSlider(
                label: '수용력 K',
                value: _carryCapacity,
                min: 50,
                max: 1000,
                step: 50,
                defaultValue: 500,
                formatValue: (v) => v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _carryCapacity = v),
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
          _V('N', _population.toStringAsFixed(0)),
          _V('K', _carryCapacity.toStringAsFixed(0)),
          _V('r', _growthRate.toStringAsFixed(1)),
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

class _LogisticGrowthScreenPainter extends CustomPainter {
  final double time;
  final double growthRate;
  final double carryCapacity;

  _LogisticGrowthScreenPainter({
    required this.time,
    required this.growthRate,
    required this.carryCapacity,
  });

  void _label(Canvas canvas, String text, Offset pos, {double fs = 8, Color col = const Color(0xFF5A8A9A), bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? pos.dx - tp.width / 2 : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // --- Upper panel: N vs time ---
    final topPad = 18.0;
    final chartH = h * 0.52;
    final chartBot = topPad + chartH;
    final chartLeft = 46.0;
    final chartRight = w - 10;
    final chartW = chartRight - chartLeft;
    final k = carryCapacity;
    final r = growthRate;
    const n0 = 10.0;

    // Axes
    canvas.drawLine(Offset(chartLeft, topPad), Offset(chartLeft, chartBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(chartLeft, chartBot), Offset(chartRight, chartBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _label(canvas, 'N', Offset(2, topPad), fs: 9, col: const Color(0xFFE0F4FF));
    _label(canvas, '시간 →', Offset(chartRight - 32, chartBot + 2), fs: 7);
    _label(canvas, k.toStringAsFixed(0), Offset(2, topPad + 2), fs: 7);

    // K carrying capacity line (dashed)
    final kY = topPad + 4.0; // K is at top of chart
    final dashPaint = Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.4)..strokeWidth = 1;
    for (double dx = chartLeft; dx < chartRight; dx += 8) {
      canvas.drawLine(Offset(dx, kY), Offset(dx + 5, kY), dashPaint);
    }
    _label(canvas, 'K', Offset(chartLeft + 2, kY - 10), fs: 8, col: const Color(0xFFE0F4FF));

    // Exponential growth (orange dashed)
    final expPath = Path();
    bool firstExp = true;
    for (int px = 0; px <= chartW.toInt(); px++) {
      final t = px / chartW * 20.0; // 0–20 time units
      final nExp = n0 * math.exp(r * t);
      final normN = (nExp / k).clamp(0.0, 1.05);
      final y = chartBot - normN * chartH;
      final x = chartLeft + px.toDouble();
      if (firstExp) {
        expPath.moveTo(x, y);
        firstExp = false;
      } else {
        expPath.lineTo(x, y);
      }
    }
    final dashExpPaint = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(expPath, dashExpPaint);

    // Logistic curve (cyan solid)
    final logPath = Path();
    bool firstLog = true;
    for (int px = 0; px <= chartW.toInt(); px++) {
      final t = px / chartW * 20.0;
      // Logistic: N(t) = K / (1 + ((K-N0)/N0) * e^(-r*t))
      final denom = 1.0 + ((k - n0) / n0) * math.exp(-r * t);
      final nLog = k / denom;
      final normN = (nLog / k).clamp(0.0, 1.0);
      final y = chartBot - normN * chartH;
      final x = chartLeft + px.toDouble();
      if (firstLog) {
        logPath.moveTo(x, y);
        firstLog = false;
      } else {
        logPath.lineTo(x, y);
      }
    }
    canvas.drawPath(logPath,
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2..style = PaintingStyle.stroke);

    // K/2 line (max growth rate point)
    final k2Y = topPad + chartH * 0.5;
    for (double dx = chartLeft; dx < chartRight; dx += 6) {
      canvas.drawLine(Offset(dx, k2Y), Offset(dx + 3, k2Y),
          Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.5)..strokeWidth = 1);
    }
    _label(canvas, 'K/2 (최대 성장)', Offset(chartLeft + 4, k2Y - 10), fs: 7, col: const Color(0xFF64FF8C));

    // Seeded data points on logistic curve
    final rng = math.Random(42);
    for (int i = 0; i < 10; i++) {
      final t = (i + 1) / 11.0 * 20.0;
      final denom = 1.0 + ((k - n0) / n0) * math.exp(-r * t);
      final nLog = k / denom;
      final noise = (rng.nextDouble() - 0.5) * k * 0.08;
      final normN = ((nLog + noise) / k).clamp(0.0, 1.0);
      final y = chartBot - normN * chartH;
      final x = chartLeft + (t / 20.0) * chartW;
      canvas.drawCircle(Offset(x, y), 3,
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7));
    }

    // Legend
    canvas.drawLine(Offset(chartRight - 90, topPad + 6), Offset(chartRight - 70, topPad + 6),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2);
    _label(canvas, '로지스틱', Offset(chartRight - 68, topPad + 2), fs: 7, col: const Color(0xFF00D4FF));
    canvas.drawLine(Offset(chartRight - 90, topPad + 16), Offset(chartRight - 70, topPad + 16),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..strokeWidth = 1.5);
    _label(canvas, '지수 성장', Offset(chartRight - 68, topPad + 12), fs: 7, col: const Color(0xFFFF6B35));

    // --- Lower panel: dN/dt vs N ---
    final lowerTop = chartBot + 22.0;
    final lowerH = h - lowerTop - 8;
    if (lowerH < 20) return;
    final lLeft = chartLeft;
    final lRight = chartRight;
    final lW = lRight - lLeft;
    final lBot = lowerTop + lowerH;

    canvas.drawLine(Offset(lLeft, lowerTop), Offset(lLeft, lBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(lLeft, lBot), Offset(lRight, lBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _label(canvas, 'dN/dt', Offset(2, lowerTop), fs: 7);
    _label(canvas, 'N →', Offset(lRight - 20, lBot + 2), fs: 7);
    _label(canvas, 'K/2', Offset(lLeft + lW * 0.5 - 8, lBot + 2), fs: 7, col: const Color(0xFF64FF8C));

    // dN/dt = rN(1-N/K) — parabola shape
    final dnPath = Path();
    bool firstDn = true;
    final maxDn = r * k / 4.0; // peak at K/2
    for (int px = 0; px <= lW.toInt(); px++) {
      final nVal = (px / lW) * k;
      final dndt = r * nVal * (1 - nVal / k);
      final normDn = (dndt / maxDn).clamp(0.0, 1.0);
      final y = lBot - normDn * lowerH * 0.9;
      final x = lLeft + px.toDouble();
      if (firstDn) {
        dnPath.moveTo(x, y);
        firstDn = false;
      } else {
        dnPath.lineTo(x, y);
      }
    }
    canvas.drawPath(dnPath,
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    // Peak marker
    canvas.drawCircle(Offset(lLeft + lW * 0.5, lBot - lowerH * 0.9), 3,
        Paint()..color = const Color(0xFF64FF8C));
    _label(canvas, '최대 성장률', Offset(lLeft + lW * 0.5 + 4, lBot - lowerH * 0.9 - 4), fs: 7, col: const Color(0xFF64FF8C));
    _label(canvas, 'r=${r.toStringAsFixed(1)}  K=${k.toStringAsFixed(0)}', Offset(lLeft + 4, lowerTop - 2), fs: 7, col: const Color(0xFF5A8A9A));
  }

  @override
  bool shouldRepaint(covariant _LogisticGrowthScreenPainter oldDelegate) => true;
}
