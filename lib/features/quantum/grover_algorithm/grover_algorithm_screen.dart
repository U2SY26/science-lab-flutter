import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class GroverAlgorithmScreen extends StatefulWidget {
  const GroverAlgorithmScreen({super.key});
  @override
  State<GroverAlgorithmScreen> createState() => _GroverAlgorithmScreenState();
}

class _GroverAlgorithmScreenState extends State<GroverAlgorithmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _dbSize = 16.0;
  double _iterations = 3.0;
  double _targetProb = 0, _optimalIter = 0;

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
      final N = _dbSize.toInt();
      final optIter = (math.pi / 4 * math.sqrt(N.toDouble())).round();
      final theta = math.asin(1.0 / math.sqrt(N.toDouble()));
      _targetProb = math.pow(math.sin((2 * _iterations.toInt() + 1) * theta), 2).toDouble();
      _optimalIter = optIter.toDouble();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _dbSize = 16.0;
      _iterations = 3.0;
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
          Text('양자역학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('그로버 탐색 알고리즘', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '그로버 탐색 알고리즘',
          formula: 'O(√N) iterations',
          formulaDescription: '진폭 증폭을 이용하여 비정렬 데이터에서 O(√N)에 탐색합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _GroverAlgorithmScreenPainter(
                time: _time,
                dbSize: _dbSize,
                iterations: _iterations,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '데이터베이스 크기 N',
                value: _dbSize,
                min: 4.0,
                max: 64.0,
                defaultValue: 16.0,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => _dbSize = v),
              ),
              advancedControls: [
            SimSlider(
                label: '반복 횟수',
                value: _iterations,
                min: 1.0,
                max: 10.0,
                defaultValue: 3.0,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => _iterations = v),
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
          _V('탐색 확률', '${(_targetProb * 100).toStringAsFixed(1)}%'),
          _V('최적 반복', '${_optimalIter.toStringAsFixed(0)}'),
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

class _GroverAlgorithmScreenPainter extends CustomPainter {
  final double time;
  final double dbSize;
  final double iterations;

  _GroverAlgorithmScreenPainter({
    required this.time,
    required this.dbSize,
    required this.iterations,
  });

  void _lbl(Canvas canvas, String text, Offset center, Color color, double sz,
      {FontWeight fw = FontWeight.normal}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: sz, fontFamily: 'monospace', fontWeight: fw)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final N = dbSize.toInt().clamp(4, 64);
    final iter = iterations.toInt().clamp(1, 10);

    // Fixed target index (deterministic)
    final targetIdx = (N * 0.4).toInt().clamp(0, N - 1);

    _lbl(canvas, '그로버 탐색: N=$N  반복=$iter', Offset(w / 2, 13),
        const Color(0xFF00D4FF), 11, fw: FontWeight.bold);

    // ============ TOP: Amplitude bar chart ============
    final chartTop = 26.0;
    final chartBot = h * 0.56;
    final chartH = chartBot - chartTop;
    final chartL = 32.0;
    final chartR = w - 12.0;
    final chartW = chartR - chartL;

    // Compute amplitudes after `iter` Grover iterations
    final theta = math.asin(1.0 / math.sqrt(N.toDouble()));
    final List<double> amps = List.generate(N, (i) {
      if (i == targetIdx) {
        return math.sin((2 * iter + 1) * theta);
      } else {
        return math.cos((2 * iter + 1) * theta) / math.sqrt((N - 1).toDouble());
      }
    });
    final maxAmp = amps.reduce((a, b) => a > b ? a : b).clamp(0.05, 1.0);

    // Axes
    final axisP = Paint()..color = const Color(0xFF2A4050)..strokeWidth = 1..style = PaintingStyle.stroke;
    // X axis (baseline at 0)
    final baselineY = chartBot - 2;
    canvas.drawLine(Offset(chartL, baselineY), Offset(chartR, baselineY), axisP);
    // Y axis
    canvas.drawLine(Offset(chartL, chartTop), Offset(chartL, baselineY), axisP);

    // Y labels
    _lbl(canvas, '1.0', Offset(chartL - 12, chartTop + 5), const Color(0xFF5A8A9A), 8);
    _lbl(canvas, '0', Offset(chartL - 8, baselineY), const Color(0xFF5A8A9A), 8);
    _lbl(canvas, '진폭', Offset(chartL - 14, (chartTop + baselineY) / 2), const Color(0xFF5A8A9A), 8);

    // Draw bars
    final barW = chartW / N;
    for (int i = 0; i < N; i++) {
      final amp = amps[i].abs();
      final barH2 = (amp / maxAmp) * (chartH - 10);
      final bx = chartL + i * barW;
      final by = baselineY - barH2;

      Color barColor;
      if (i == targetIdx) {
        barColor = const Color(0xFFFF6B35);
      } else {
        barColor = const Color(0xFF00D4FF).withValues(alpha: 0.6);
      }

      // Animated highlight pulse on target
      if (i == targetIdx) {
        final pulse = (math.sin(time * 4) * 0.5 + 0.5) * 0.4;
        canvas.drawRect(
            Rect.fromLTWH(bx + 0.5, by - 2, barW - 1, barH2 + 2),
            Paint()..color = barColor.withValues(alpha: 0.2 + pulse));
      }
      canvas.drawRect(
          Rect.fromLTWH(bx + 0.5, by, barW - 1, barH2),
          Paint()..color = barColor);

      // Tick every N/4
      if (i % (N ~/ 4).clamp(1, 16) == 0) {
        _lbl(canvas, '$i', Offset(bx + barW / 2, baselineY + 7), const Color(0xFF5A8A9A), 7);
      }
    }

    // Target label arrow
    final targetBx = chartL + targetIdx * barW + barW / 2;
    final targetAmp = amps[targetIdx].abs();
    final targetBarTop = baselineY - (targetAmp / maxAmp) * (chartH - 10);
    _lbl(canvas, '타깃 #$targetIdx', Offset(targetBx, targetBarTop - 10),
        const Color(0xFFFF6B35), 9, fw: FontWeight.bold);
    canvas.drawLine(
        Offset(targetBx, targetBarTop - 4),
        Offset(targetBx, targetBarTop),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5);

    // Average line (1/√N)
    final avgAmp = 1.0 / math.sqrt(N.toDouble());
    final avgY = baselineY - (avgAmp / maxAmp) * (chartH - 10);
    final avgPath = Path()..moveTo(chartL, avgY);
    avgPath.lineTo(chartR, avgY);
    double dx2 = chartL;
    while (dx2 < chartR) {
      canvas.drawLine(Offset(dx2, avgY), Offset(math.min(dx2 + 5, chartR), avgY),
          Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.5)..strokeWidth = 1..style = PaintingStyle.stroke);
      dx2 += 9;
    }
    _lbl(canvas, '균등 1/√N', Offset(chartR - 20, avgY - 6), const Color(0xFF64FF8C), 7);

    // ============ BOTTOM: Probability vs iterations graph ============
    final graphTop = h * 0.62;
    final graphBot = h - 18.0;
    final graphH = graphBot - graphTop;
    final graphL = 36.0;
    final graphR = w - 12.0;
    final graphW = graphR - graphL;
    final maxIter2 = (math.pi / 4 * math.sqrt(N.toDouble())).ceil() + 2;

    _lbl(canvas, '반복 횟수 vs 성공 확률', Offset(graphL + graphW / 2, graphTop - 7),
        const Color(0xFFE0F4FF), 9);

    // Axes
    canvas.drawLine(Offset(graphL, graphTop), Offset(graphL, graphBot), axisP);
    canvas.drawLine(Offset(graphL, graphBot), Offset(graphR, graphBot), axisP);
    _lbl(canvas, '1.0', Offset(graphL - 10, graphTop + 4), const Color(0xFF5A8A9A), 7);
    _lbl(canvas, '0', Offset(graphL - 8, graphBot), const Color(0xFF5A8A9A), 7);

    // Classical O(N) success prob line (linear: k/N)
    final classPath = Path();
    for (int k = 0; k <= maxIter2; k++) {
      final px = graphL + (k / maxIter2) * graphW;
      final prob = (k / N).clamp(0.0, 1.0);
      final py = graphBot - prob * (graphH - 4);
      if (k == 0) { classPath.moveTo(px, py); } else { classPath.lineTo(px, py); }
    }
    canvas.drawPath(classPath,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Quantum O(√N) success prob
    final quantPath = Path();
    for (int k = 0; k <= maxIter2; k++) {
      final px = graphL + (k / maxIter2) * graphW;
      final prob = math.pow(math.sin((2 * k + 1) * theta), 2).toDouble().clamp(0.0, 1.0);
      final py = graphBot - prob * (graphH - 4);
      if (k == 0) { quantPath.moveTo(px, py); } else { quantPath.lineTo(px, py); }
    }
    canvas.drawPath(quantPath,
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2..style = PaintingStyle.stroke);

    // Current iteration marker
    final curX = graphL + (iter / maxIter2).clamp(0.0, 1.0) * graphW;
    final curProb = math.pow(math.sin((2 * iter + 1) * theta), 2).toDouble().clamp(0.0, 1.0);
    final curY = graphBot - curProb * (graphH - 4);
    canvas.drawCircle(Offset(curX, curY), 5,
        Paint()..color = const Color(0xFF00D4FF));
    _lbl(canvas, '${(curProb * 100).toStringAsFixed(0)}%', Offset(curX + 14, curY),
        const Color(0xFF00D4FF), 9);

    // Legend
    _lbl(canvas, '─ 양자 O(√N)', Offset(graphL + graphW * 0.62, graphTop + 8),
        const Color(0xFF00D4FF), 8);
    _lbl(canvas, '─ 고전 O(N)', Offset(graphL + graphW * 0.62, graphTop + 18),
        const Color(0xFFFF6B35).withValues(alpha: 0.7), 8);

    // Optimal iteration label
    final optIter = (math.pi / 4 * math.sqrt(N.toDouble())).round();
    _lbl(canvas, '최적 반복: $optIter ≈ π/4·√N', Offset(graphL + graphW * 0.28, graphBot + 11),
        const Color(0xFF5A8A9A), 8);
  }

  @override
  bool shouldRepaint(covariant _GroverAlgorithmScreenPainter oldDelegate) => true;
}
