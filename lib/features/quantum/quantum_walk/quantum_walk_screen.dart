import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class QuantumWalkScreen extends StatefulWidget {
  const QuantumWalkScreen({super.key});
  @override
  State<QuantumWalkScreen> createState() => _QuantumWalkScreenState();
}

class _QuantumWalkScreenState extends State<QuantumWalkScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _steps = 20;
  
  double _spread = 10.0, _classicalSpread = 4.5;

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
      _spread = _steps;
      _classicalSpread = math.sqrt(_steps);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _steps = 20.0;
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
          const Text('양자 랜덤 워크', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '양자 랜덤 워크',
          formula: 'U = S(C ⊗ I)',
          formulaDescription: '양자 랜덤 워크와 고전적 랜덤 워크를 비교합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _QuantumWalkScreenPainter(
                time: _time,
                steps: _steps,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '걸음 수',
                value: _steps,
                min: 5,
                max: 100,
                step: 1,
                defaultValue: 20,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _steps = v),
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
          _V('양자 편차', _spread.toStringAsFixed(1)),
          _V('고전 편차', _classicalSpread.toStringAsFixed(1)),
          _V('비율', '${(_spread / _classicalSpread).toStringAsFixed(1)}x'),
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

class _QuantumWalkScreenPainter extends CustomPainter {
  final double time;
  final double steps;

  _QuantumWalkScreenPainter({
    required this.time,
    required this.steps,
  });

  void _drawText(Canvas canvas, String text, Offset offset,
      {double fontSize = 10, Color color = const Color(0xFFE0F4FF), bool bold = false, TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    double dx = offset.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  // Compute quantum walk probability distribution using Hadamard coin
  List<double> _quantumWalkProbs(int n) {
    final size = 2 * n + 1;
    // State: complex amplitudes for (position, spin) pairs
    // spin 0=up, 1=down; position index: -n..n -> 0..2n
    final ampR = List.filled(size, 0.0); // spin=right
    final ampL = List.filled(size, 0.0);
    final ampRI = List.filled(size, 0.0);
    final ampLI = List.filled(size, 0.0);
    // Start at center with |up⟩ = (|R⟩ + i|L⟩)/√2
    ampR[n] = 1 / math.sqrt(2);
    ampLI[n] = 1 / math.sqrt(2);

    for (int step = 0; step < n; step++) {
      final nR = List.filled(size, 0.0);
      final nL = List.filled(size, 0.0);
      final nRI = List.filled(size, 0.0);
      final nLI = List.filled(size, 0.0);
      for (int pos = 0; pos < size; pos++) {
        // Hadamard: |R⟩ → (|R⟩+|L⟩)/√2, |L⟩ → (|R⟩-|L⟩)/√2
        final hRR = ampR[pos] / math.sqrt(2);
        final hRL = ampR[pos] / math.sqrt(2);
        final hLR = ampL[pos] / math.sqrt(2);
        final hLL = -ampL[pos] / math.sqrt(2);
        final hRRI = ampRI[pos] / math.sqrt(2);
        final hRLI = ampRI[pos] / math.sqrt(2);
        final hLRI = ampLI[pos] / math.sqrt(2);
        final hLLI = -ampLI[pos] / math.sqrt(2);
        // Shift: R→pos+1, L→pos-1
        if (pos + 1 < size) {
          nR[pos + 1] += hRR + hLR;
          nRI[pos + 1] += hRRI + hLRI;
        }
        if (pos - 1 >= 0) {
          nL[pos - 1] += hRL + hLL;
          nLI[pos - 1] += hRLI + hLLI;
        }
      }
      for (int i = 0; i < size; i++) {
        ampR[i] = nR[i]; ampL[i] = nL[i];
        ampRI[i] = nRI[i]; ampLI[i] = nLI[i];
      }
    }
    return List.generate(size, (i) =>
        ampR[i] * ampR[i] + ampL[i] * ampL[i] + ampRI[i] * ampRI[i] + ampLI[i] * ampLI[i]);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final n = steps.toInt().clamp(5, 30);
    final nPositions = 2 * n + 1;

    // --- Layout ---
    final leftMargin = 30.0;
    final rightMargin = 10.0;
    final topMargin = 30.0;
    final bottomMargin = 48.0;
    final plotW = w - leftMargin - rightMargin;
    final plotH = (h - topMargin - bottomMargin) * 0.55;
    final plotBottom = topMargin + plotH;

    // Title
    _drawText(canvas, '양자 워크 vs 고전 워크 (n=$n 걸음)',
        Offset(w / 2, 6), fontSize: 9, color: const Color(0xFF00D4FF), align: TextAlign.center);

    // Quantum walk probabilities
    final qProbs = _quantumWalkProbs(n);
    final maxQProb = qProbs.reduce(math.max).clamp(0.001, 1.0);

    // Classical walk: Gaussian P(x) = exp(-x²/(2n)) / √(2πn)
    // Normalized for display
    final classicalMax = 1.0 / math.sqrt(2 * math.pi * n);

    // Y-axis label
    _drawText(canvas, 'P(x)', Offset(2, topMargin + plotH / 2 - 5),
        fontSize: 8, color: const Color(0xFF5A8A9A));

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..strokeWidth = 1;
    canvas.drawLine(Offset(leftMargin, topMargin), Offset(leftMargin, plotBottom), axisPaint);
    canvas.drawLine(Offset(leftMargin, plotBottom), Offset(w - rightMargin, plotBottom), axisPaint);

    final barW = plotW / nPositions;

    // Draw classical (Gaussian) bars first (orange, behind)
    for (int i = 0; i < nPositions; i++) {
      final pos = i - n;
      final classP = math.exp(-pos * pos / (2.0 * n)) * classicalMax;
      final normP = classP / classicalMax;
      final bh = normP * plotH * 0.9;
      final bx = leftMargin + i * barW;
      canvas.drawRect(
        Rect.fromLTWH(bx + 1, plotBottom - bh, barW - 2, bh),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.45),
      );
    }

    // Draw quantum walk bars (cyan, in front)
    for (int i = 0; i < nPositions; i++) {
      final qp = qProbs[i] / maxQProb;
      final bh = qp * plotH * 0.9;
      final bx = leftMargin + i * barW;
      canvas.drawRect(
        Rect.fromLTWH(bx + 1, plotBottom - bh, barW - 2, bh),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7),
      );
    }

    // X-axis tick labels
    for (int i = 0; i <= 4; i++) {
      final pos = -n + (n * 2 * i / 4).round();
      final bx = leftMargin + (pos + n) * barW + barW / 2;
      _drawText(canvas, '$pos', Offset(bx, plotBottom + 2),
          fontSize: 7, color: const Color(0xFF5A8A9A), align: TextAlign.center);
    }
    _drawText(canvas, '위치 x', Offset(w / 2, plotBottom + 14),
        fontSize: 8, color: const Color(0xFF5A8A9A), align: TextAlign.center);

    // --- Legend ---
    final legendY = plotBottom + 26.0;
    canvas.drawRect(Rect.fromLTWH(leftMargin, legendY, 14, 8),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7));
    _drawText(canvas, '양자 워크 (σ~n)', Offset(leftMargin + 18, legendY),
        fontSize: 8, color: const Color(0xFF00D4FF));
    canvas.drawRect(Rect.fromLTWH(w / 2 + 10, legendY, 14, 8),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.55));
    _drawText(canvas, '고전 워크 (σ~√n)', Offset(w / 2 + 28, legendY),
        fontSize: 8, color: const Color(0xFFFF6B35));

    // --- Std dev comparison ---
    final statY = h - 16.0;
    final qStd = n.toDouble();
    final cStd = math.sqrt(n.toDouble());
    _drawText(canvas, '양자 σ≈$n  vs  고전 σ≈${cStd.toStringAsFixed(1)}  (비율 ${(qStd / cStd).toStringAsFixed(1)}×)',
        Offset(w / 2, statY),
        fontSize: 8, color: const Color(0xFF5A8A9A), align: TextAlign.center);
  }

  @override
  bool shouldRepaint(covariant _QuantumWalkScreenPainter oldDelegate) => true;
}
