import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class RadioactiveDecayScreen extends StatefulWidget {
  const RadioactiveDecayScreen({super.key});
  @override
  State<RadioactiveDecayScreen> createState() => _RadioactiveDecayScreenState();
}

class _RadioactiveDecayScreenState extends State<RadioactiveDecayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _halfLife = 5;
  
  double _remaining = 1.0, _decayed = 0.0;

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
      final lambda = math.ln2 / _halfLife;
      _remaining = math.exp(-lambda * _time);
      _decayed = 1 - _remaining;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _halfLife = 5.0;
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
          const Text('방사성 붕괴', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '방사성 붕괴',
          formula: 'N(t) = N₀e^(-λt)',
          formulaDescription: '방사성 동위원소의 붕괴 과정을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _RadioactiveDecayScreenPainter(
                time: _time,
                halfLife: _halfLife,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '반감기 (s)',
                value: _halfLife,
                min: 0.5,
                max: 30,
                step: 0.5,
                defaultValue: 5,
                formatValue: (v) => v.toStringAsFixed(1) + ' s',
                onChanged: (v) => setState(() => _halfLife = v),
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
          _V('잔량', (_remaining * 100).toStringAsFixed(1) + '%'),
          _V('붕괴', (_decayed * 100).toStringAsFixed(1) + '%'),
          _V('t/T½', (_time / _halfLife).toStringAsFixed(2)),
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

class _RadioactiveDecayScreenPainter extends CustomPainter {
  final double time;
  final double halfLife;

  _RadioactiveDecayScreenPainter({
    required this.time,
    required this.halfLife,
  });

  void _label(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 10, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    final lambda = math.ln2 / halfLife;
    // Display time range: 0 to 5 half-lives
    final tMax = halfLife * 5;
    final currentRemaining = math.exp(-lambda * time);

    // Layout: left=decay curve chart, right=atom grid
    const padL = 46.0, padR = 8.0, padT = 28.0, padB = 36.0;
    final chartW = w * 0.58 - padL;
    final plotH = h - padT - padB;

    // ─── Atom grid (right side) ─────────────────────────────────
    final gridLeft = w * 0.60;
    final gridRight = w - padR;
    final gridTop = padT;
    final gridBottom = h - padB;
    final gridW = gridRight - gridLeft;
    final gridH = gridBottom - gridTop;

    // 10×10 = 100 atoms, deterministic positions
    const cols = 10, rows = 10;
    const total = cols * rows;
    final surviving = (currentRemaining * total).round().clamp(0, total);
    final rng = math.Random(42); // seeded, deterministic
    // Pre-generate random order for decay
    final decayOrder = List<int>.generate(total, (i) => i)..shuffle(rng);

    final atomR = (math.min(gridW / cols, gridH / rows) * 0.38).clamp(2.0, 6.0);
    for (int i = 0; i < total; i++) {
      final idx = decayOrder[i];
      final col = idx % cols;
      final row = idx ~/ cols;
      final cx = gridLeft + (col + 0.5) * gridW / cols;
      final cy = gridTop + (row + 0.5) * gridH / rows;
      final isAlive = i < surviving;
      if (isAlive) {
        canvas.drawCircle(Offset(cx, cy), atomR, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.2));
        canvas.drawCircle(Offset(cx, cy), atomR, Paint()..color = const Color(0xFF00D4FF)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      } else {
        // Decayed: show decay particle flash
        canvas.drawCircle(Offset(cx, cy), atomR * 0.5, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.18));
        canvas.drawCircle(Offset(cx, cy), atomR * 0.5, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 0.8);
      }
    }
    _label(canvas, '$surviving/$total 생존', Offset(gridLeft, gridBottom + 6), const Color(0xFF00D4FF), fontSize: 8);

    // Decay type legend (alpha, beta, gamma)
    final lx = gridLeft;
    final ly = gridTop - 14;
    canvas.drawCircle(Offset(lx + 5, ly + 5), 4, Paint()..color = const Color(0xFFFF4444));
    _label(canvas, 'α', Offset(lx + 11, ly), const Color(0xFFFF4444), fontSize: 9);
    canvas.drawCircle(Offset(lx + 28, ly + 5), 4, Paint()..color = const Color(0xFF4488FF));
    _label(canvas, 'β', Offset(lx + 34, ly), const Color(0xFF4488FF), fontSize: 9);
    canvas.drawCircle(Offset(lx + 51, ly + 5), 4, Paint()..color = const Color(0xFFFFD700));
    _label(canvas, 'γ', Offset(lx + 57, ly), const Color(0xFFFFD700), fontSize: 9);

    // ─── Decay curve chart (left side) ─────────────────────────
    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0;
    canvas.drawLine(Offset(padL, padT), Offset(padL, padT + plotH), axisPaint);
    canvas.drawLine(Offset(padL, padT + plotH), Offset(padL + chartW, padT + plotH), axisPaint);

    double tToX(double t) => padL + (t / tMax) * chartW;
    double nToY(double n) => padT + (1 - n) * plotH;

    // Half-life markers
    for (int i = 1; i <= 5; i++) {
      final xt = tToX(halfLife * i);
      final yt = nToY(math.pow(0.5, i).toDouble());
      canvas.drawLine(Offset(xt, padT + plotH - 3), Offset(xt, padT + plotH + 3), axisPaint);
      canvas.drawLine(Offset(xt, padT), Offset(xt, padT + plotH), Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.8);
      canvas.drawCircle(Offset(xt, yt), 3, Paint()..color = const Color(0xFFFFD700));
      _label(canvas, 't½×$i', Offset(xt - 12, padT + plotH + 6), const Color(0xFF5A8A9A), fontSize: 7);
    }

    // Y axis labels
    for (int i = 0; i <= 4; i++) {
      final frac = i * 0.25;
      final yp = nToY(frac);
      _label(canvas, frac.toStringAsFixed(2), Offset(2, yp - 5), const Color(0xFF5A8A9A), fontSize: 7);
      canvas.drawLine(Offset(padL - 3, yp), Offset(padL, yp), axisPaint);
    }
    _label(canvas, 'N/N₀', Offset(2, padT - 10), const Color(0xFF5A8A9A), fontSize: 8);
    _label(canvas, '시간 →', Offset(padL + chartW - 22, padT + plotH + 18), const Color(0xFF5A8A9A), fontSize: 8);

    // Decay curve
    final curvePath = Path();
    bool firstPt = true;
    for (double t = 0; t <= tMax; t += tMax / 200) {
      final n = math.exp(-lambda * t);
      final px = tToX(t);
      final py = nToY(n);
      if (firstPt) {
        curvePath.moveTo(px, py);
        firstPt = false;
      } else {
        curvePath.lineTo(px, py);
      }
    }
    canvas.drawPath(curvePath, Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2.5..style = PaintingStyle.stroke);

    // Current time indicator
    final curT = time.clamp(0.0, tMax);
    final curN = math.exp(-lambda * curT);
    final dotX = tToX(curT);
    final dotY = nToY(curN);
    canvas.drawLine(Offset(dotX, padT), Offset(dotX, padT + plotH), Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..strokeWidth = 1.0);
    canvas.drawCircle(Offset(dotX, dotY), 5, Paint()..color = const Color(0xFFFF6B35));

    // Labels
    _label(canvas, 'N(t)=N₀e^(−λt)', Offset(padL + 4, padT + 4), const Color(0xFF64FF8C), fontSize: 8);
    _label(canvas, 't½=${halfLife.toStringAsFixed(1)}s', Offset(padL + 4, padT + 14), const Color(0xFFFFD700), fontSize: 9, bold: true);
    _label(canvas, '잔량: ${(currentRemaining * 100).toStringAsFixed(1)}%', Offset(padL + 4, padT + 25), const Color(0xFF00D4FF), fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _RadioactiveDecayScreenPainter oldDelegate) => true;
}
