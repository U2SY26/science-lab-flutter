import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class GeneticDriftScreen extends StatefulWidget {
  const GeneticDriftScreen({super.key});
  @override
  State<GeneticDriftScreen> createState() => _GeneticDriftScreenState();
}

class _GeneticDriftScreenState extends State<GeneticDriftScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _popSize = 50.0;
  double _initFreq = 0.5;
  final List<double> _generations = [];

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
      if (_generations.isEmpty) {
        _generations.add(_initFreq);
      }
      if (_generations.length < 200) {
        final n = _popSize.toInt();
        final rng = math.Random();
        double p = _generations.last;
        int count = 0;
        for (int i = 0; i < 2 * n; i++) {
          if (rng.nextDouble() < p) count++;
        }
        _generations.add(count / (2 * n));
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _popSize = 50.0;
      _initFreq = 0.5;
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
          Text('생물 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('유전적 부동', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물 시뮬레이션',
          title: '유전적 부동',
          formula: 'p(t+1) ~ Binomial(2N, p(t)) / 2N',
          formulaDescription: '소규모 개체군에서 대립유전자 빈도의 무작위 변동을 관찰합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _GeneticDriftScreenPainter(
                time: _time,
                popSize: _popSize,
                initFreq: _initFreq,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '개체군 크기',
                value: _popSize,
                min: 10.0,
                max: 500.0,
                defaultValue: 50.0,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => _popSize = v),
              ),
              advancedControls: [
            SimSlider(
                label: '초기 빈도',
                value: _initFreq,
                min: 0.1,
                max: 0.9,
                step: 0.05,
                defaultValue: 0.5,
                formatValue: (v) => '${v.toStringAsFixed(2)}',
                onChanged: (v) => setState(() => _initFreq = v),
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
          _V('세대', '${_generations.length}'),
          _V('현재 빈도', '${_generations.isEmpty ? 0 : _generations.last.toStringAsFixed(3)}'),
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

class _GeneticDriftScreenPainter extends CustomPainter {
  final double time;
  final double popSize;
  final double initFreq;

  _GeneticDriftScreenPainter({
    required this.time,
    required this.popSize,
    required this.initFreq,
  });

  void _drawLabel(Canvas canvas, String text, Offset center, {double fontSize = 10, Color? color}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color ?? const Color(0xFF5A8A9A), fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    const cyanColor = Color(0xFF00D4FF);
    const orangeColor = Color(0xFFFF6B35);
    const greenColor = Color(0xFF64FF8C);
    const mutedColor = Color(0xFF5A8A9A);
    const inkColor = Color(0xFFE0F4FF);

    final w = size.width;
    final h = size.height;

    // Title
    final titleTp = TextPainter(
      text: const TextSpan(text: '유전적 부동 — 대립유전자 빈도 변화', style: TextStyle(color: cyanColor, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, Offset((w - titleTp.width) / 2, 5));

    // Plot area
    const plotLeft = 42.0;
    const plotTop = 28.0;
    final plotRight = w - 12;
    final plotBottom = h * 0.78;
    final plotW = plotRight - plotLeft;
    final plotH = plotBottom - plotTop;

    // Grid lines
    final gridPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = plotTop + plotH * i / 4;
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), gridPaint);
      _drawLabel(canvas, (1 - i / 4).toStringAsFixed(2), Offset(plotLeft - 16, y), fontSize: 8, color: mutedColor);
    }
    for (int i = 0; i <= 5; i++) {
      final x = plotLeft + plotW * i / 5;
      canvas.drawLine(Offset(x, plotTop), Offset(x, plotBottom), gridPaint);
      _drawLabel(canvas, '${(i * 40).toInt()}', Offset(x, plotBottom + 9), fontSize: 8, color: mutedColor);
    }

    // Axis labels
    _drawLabel(canvas, 'p (대립유전자 빈도)', Offset(plotLeft - 28, plotTop + plotH / 2), fontSize: 9, color: mutedColor);
    _drawLabel(canvas, '세대', Offset(plotLeft + plotW / 2, plotBottom + 20), fontSize: 9, color: mutedColor);

    // Fixation lines
    canvas.drawLine(Offset(plotLeft, plotTop), Offset(plotRight, plotTop),
        Paint()..color = cyanColor.withValues(alpha: 0.3)..strokeWidth = 1.0..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(plotLeft, plotBottom), Offset(plotRight, plotBottom),
        Paint()..color = orangeColor.withValues(alpha: 0.3)..strokeWidth = 1.0);
    _drawLabel(canvas, 'p=1 고정', Offset(plotRight - 28, plotTop + 7), fontSize: 7, color: cyanColor);
    _drawLabel(canvas, 'p=0 소실', Offset(plotRight - 28, plotBottom - 7), fontSize: 7, color: orangeColor);

    // Simulate multiple population lines with seeded random
    final numLines = 8;
    final totalGens = 200;
    final lineColors = [
      cyanColor, orangeColor, greenColor,
      const Color(0xFFAA66FF), const Color(0xFFFFCC00),
      const Color(0xFF00FFCC), const Color(0xFFFF88AA), const Color(0xFF88AAFF),
    ];

    int fixedCount = 0;
    for (int line = 0; line < numLines; line++) {
      final rng = math.Random(line * 999 + popSize.toInt() * 7 + (initFreq * 100).toInt());
      final points = <Offset>[];
      double p = initFreq;
      bool fixed = false;

      for (int gen = 0; gen <= totalGens; gen++) {
        if (p <= 0 || p >= 1) {
          fixed = true;
          p = p <= 0 ? 0 : 1;
        }
        final x = plotLeft + plotW * gen / totalGens;
        final y = plotTop + plotH * (1 - p);
        points.add(Offset(x, y));
        if (!fixed) {
          final n = popSize.toInt();
          int count = 0;
          for (int i = 0; i < 2 * n; i++) {
            if (rng.nextDouble() < p) { count++; }
          }
          p = count / (2 * n);
        }
      }

      if (points.last.dy <= plotTop + 2 || points.last.dy >= plotBottom - 2) fixedCount++;

      final linePaint = Paint()
        ..color = lineColors[line % lineColors.length].withValues(alpha: 0.75)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path();
      for (int i = 0; i < points.length; i++) {
        if (i == 0) path.moveTo(points[i].dx, points[i].dy);
        else path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Plot border
    canvas.drawRect(
      Rect.fromLTRB(plotLeft, plotTop, plotRight, plotBottom),
      Paint()..color = mutedColor.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 1.0,
    );

    // Initial frequency line
    final initY = plotTop + plotH * (1 - initFreq);
    canvas.drawLine(Offset(plotLeft, initY), Offset(plotRight, initY),
        Paint()..color = inkColor.withValues(alpha: 0.2)..strokeWidth = 1.0..strokeJoin = StrokeJoin.round);
    _drawLabel(canvas, 'p₀=${initFreq.toStringAsFixed(2)}', Offset(plotLeft + 28, initY - 8), fontSize: 8, color: inkColor);

    // Bottom stats
    final statsY = h * 0.87;
    final statData = [
      ('개체군 크기 N', '${popSize.toInt()}'),
      ('초기 빈도 p₀', initFreq.toStringAsFixed(2)),
      ('고정 집단 수', '$fixedCount / $numLines'),
    ];
    final statW = w / 3;
    for (int i = 0; i < statData.length; i++) {
      _drawLabel(canvas, statData[i].$1, Offset(statW * i + statW / 2, statsY - 7), fontSize: 9, color: mutedColor);
      _drawLabel(canvas, statData[i].$2, Offset(statW * i + statW / 2, statsY + 8), fontSize: 12, color: cyanColor);
    }

    // Small population vs large annotation
    final nSmall = popSize < 30;
    _drawLabel(canvas, nSmall ? '소집단 → 빠른 부동 (병목 효과 강함)' : '대집단 → 느린 부동 (선택의 영향 우세)',
        Offset(w / 2, h - 8), fontSize: 9, color: nSmall ? orangeColor : greenColor);
  }

  @override
  bool shouldRepaint(covariant _GeneticDriftScreenPainter oldDelegate) => true;
}
