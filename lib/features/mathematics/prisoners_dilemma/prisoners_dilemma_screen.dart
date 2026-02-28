import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class PrisonersDilemmaScreen extends StatefulWidget {
  const PrisonersDilemmaScreen({super.key});
  @override
  State<PrisonersDilemmaScreen> createState() => _PrisonersDilemmaScreenState();
}

class _PrisonersDilemmaScreenState extends State<PrisonersDilemmaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _rounds = 50.0;
  double _strategy1 = 0.0;
  double _score1 = 0, _score2 = 0;

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
      _score1 = 0; _score2 = 0;
      bool lastP2 = true;
      final rng = math.Random(42);
      for (int i = 0; i < _rounds.toInt(); i++) {
        bool c1, c2 = rng.nextBool();
        switch (_strategy1.toInt()) {
          case 0: c1 = true; break;
          case 1: c1 = false; break;
          case 2: c1 = (i == 0) ? true : lastP2; break;
          default: c1 = rng.nextBool();
        }
        if (c1 && c2) { _score1 += 3; _score2 += 3; }
        else if (c1 && !c2) { _score1 += 0; _score2 += 5; }
        else if (!c1 && c2) { _score1 += 5; _score2 += 0; }
        else { _score1 += 1; _score2 += 1; }
        lastP2 = c2;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _rounds = 50.0;
      _strategy1 = 0.0;
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
          const Text('죄수의 딜레마', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '죄수의 딜레마',
          formula: 'T > R > P > S',
          formulaDescription: '반복 게임에서 다양한 전략의 성과를 비교합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PrisonersDilemmaScreenPainter(
                time: _time,
                rounds: _rounds,
                strategy1: _strategy1,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '라운드 수',
                value: _rounds,
                min: 10.0,
                max: 200.0,
                defaultValue: 50.0,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => _rounds = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'P1 전략 (0=협력,1=배신,2=TFT,3=랜덤)',
                value: _strategy1,
                min: 0.0,
                max: 3.0,
                defaultValue: 0.0,
                formatValue: (v) => '${["협력","배신","TFT","랜덤"][v.toInt()]}',
                onChanged: (v) => setState(() => _strategy1 = v),
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
          _V('P1 점수', '${_score1.toStringAsFixed(0)}'),
          _V('P2 점수', '${_score2.toStringAsFixed(0)}'),
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

class _PrisonersDilemmaScreenPainter extends CustomPainter {
  final double time;
  final double rounds;
  final double strategy1;

  _PrisonersDilemmaScreenPainter({
    required this.time,
    required this.rounds,
    required this.strategy1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final n = rounds.toInt();
    final strat = strategy1.toInt();

    // Simulate 3 strategies vs random P2
    final rng = math.Random(42);
    final scores = List.generate(4, (_) => 0.0); // always-C, always-D, TFT, random
    final histories = List.generate(4, (_) => <double>[]);

    final p2Choices = List.generate(n, (_) => rng.nextBool());

    for (int s = 0; s < 4; s++) {
      double sc = 0;
      bool prevP2 = true;
      final rng2 = math.Random(77 + s);
      histories[s].add(0);
      for (int i = 0; i < n; i++) {
        final c2 = p2Choices[i];
        bool c1;
        switch (s) {
          case 0: c1 = true;
          case 1: c1 = false;
          case 2: c1 = (i == 0) ? true : prevP2;
          default: c1 = rng2.nextBool();
        }
        if (c1 && c2) { sc += 3; }
        else if (c1 && !c2) { sc += 0; }
        else if (!c1 && c2) { sc += 5; }
        else { sc += 1; }
        prevP2 = c2;
        histories[s].add(sc);
      }
      scores[s] = sc;
    }

    // ── TOP: Player icons + payoff matrix mini ───────────────
    _text(canvas, '죄수의 딜레마 — 반복 게임', Offset(w / 2 - 62, 4),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold));

    // Mini payoff box
    final boxX = w * 0.04;
    final boxY = 18.0;
    final cellS = (h * 0.095).clamp(18.0, 30.0);
    final payLabels = [['(3,3)', '(0,5)'], ['(5,0)', '(1,1)']];
    final payColors = [
      [const Color(0xFF00D4FF), const Color(0xFFFF6B35)],
      [const Color(0xFF64FF8C), const Color(0xFFFFD700)],
    ];
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 2; c++) {
        final rx = boxX + c * cellS;
        final ry = boxY + r * cellS;
        final isNash = r == 1 && c == 1;
        canvas.drawRect(Rect.fromLTWH(rx, ry, cellS, cellS),
            Paint()..color = (isNash ? const Color(0xFF64FF8C) : payColors[r][c]).withValues(alpha: 0.12));
        canvas.drawRect(Rect.fromLTWH(rx, ry, cellS, cellS),
            Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.stroke..strokeWidth = 0.8);
        _text(canvas, payLabels[r][c], Offset(rx + 2, ry + cellS * 0.3),
            TextStyle(color: payColors[r][c], fontSize: 7, fontWeight: FontWeight.bold));
      }
    }
    _text(canvas, 'C  D', Offset(boxX + cellS * 0.25, boxY - 10),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 7));
    _text(canvas, 'C\nD', Offset(boxX - 10, boxY + cellS * 0.2),
        const TextStyle(color: Color(0xFFFF6B35), fontSize: 7, height: 2.3));

    // Current strategy label
    final stratNames = ['항상 협력', '항상 배신', '팃포탯', '무작위'];
    final stratColors = [const Color(0xFF00D4FF), const Color(0xFFFF6B35), const Color(0xFF64FF8C), const Color(0xFF5A8A9A)];
    _text(canvas, 'P1: ${stratNames[strat]}', Offset(boxX + cellS * 2 + 8, boxY + 4),
        TextStyle(color: stratColors[strat], fontSize: 9, fontWeight: FontWeight.bold));
    _text(canvas, 'P2: 무작위', Offset(boxX + cellS * 2 + 8, boxY + 18),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));

    // ── MIDDLE: Cumulative score graph ───────────────────────
    final graphY = boxY + cellS * 2 + 12;
    final graphH = h * 0.40;
    final padL = 36.0, padR = 8.0;
    final graphW = w - padL - padR;
    final maxScore = scores.reduce(math.max).clamp(1.0, double.infinity);

    // Grid
    canvas.drawLine(Offset(padL, graphY), Offset(padL, graphY + graphH),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(padL, graphY + graphH), Offset(padL + graphW, graphY + graphH),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);

    _text(canvas, '누적 보수', Offset(padL, graphY - 10),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8, fontWeight: FontWeight.bold));

    // Draw each strategy line
    for (int s = 0; s < 4; s++) {
      final hist = histories[s];
      final path = Path();
      for (int i = 0; i < hist.length; i++) {
        final gx = padL + i / n * graphW;
        final gy = graphY + graphH - (hist[i] / maxScore) * graphH;
        if (i == 0) { path.moveTo(gx, gy); } else { path.lineTo(gx, gy); }
      }
      final isActive = s == strat;
      canvas.drawPath(path, Paint()
        ..color = stratColors[s].withValues(alpha: isActive ? 0.95 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 2.0 : 1.0);
    }

    // ── BOTTOM: Score summary bars ───────────────────────────
    final barY = graphY + graphH + 10;
    final barH = (h - barY - 10) / 4.5;
    final barMaxW = graphW * 0.65;

    _text(canvas, '최종 점수 비교', Offset(padL, barY - 2),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8, fontWeight: FontWeight.bold));

    for (int s = 0; s < 4; s++) {
      final by = barY + 10 + s * (barH + 3);
      final bw = (scores[s] / maxScore * barMaxW).clamp(0.0, barMaxW);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(padL, by, bw, barH), const Radius.circular(2)),
          Paint()..color = stratColors[s].withValues(alpha: s == strat ? 0.85 : 0.35));
      _text(canvas, '${stratNames[s]}: ${scores[s].toInt()}',
          Offset(padL + bw + 4, by + 1),
          TextStyle(color: stratColors[s].withValues(alpha: s == strat ? 1.0 : 0.5), fontSize: 7));
    }
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _PrisonersDilemmaScreenPainter oldDelegate) => true;
}
