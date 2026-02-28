import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class GameTheoryScreen extends StatefulWidget {
  const GameTheoryScreen({super.key});
  @override
  State<GameTheoryScreen> createState() => _GameTheoryScreenState();
}

class _GameTheoryScreenState extends State<GameTheoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _p1Prob = 0.5;
  double _p2Prob = 0.5;
  double _eu1 = 0, _eu2 = 0;

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
      _eu1 = _p1Prob * (_p2Prob * 3 + (1 - _p2Prob) * 0) + (1 - _p1Prob) * (_p2Prob * 5 + (1 - _p2Prob) * 1);
      _eu2 = _p2Prob * (_p1Prob * 3 + (1 - _p1Prob) * 0) + (1 - _p2Prob) * (_p1Prob * 5 + (1 - _p1Prob) * 1);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _p1Prob = 0.5;
      _p2Prob = 0.5;
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
          const Text('내시 균형', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '내시 균형',
          formula: 'argmax U_i(s_i, s_{-i})',
          formulaDescription: '각 플레이어가 상대방 전략이 주어졌을 때 최선의 전략을 선택합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _GameTheoryScreenPainter(
                time: _time,
                p1Prob: _p1Prob,
                p2Prob: _p2Prob,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'P1 혼합전략',
                value: _p1Prob,
                min: 0.0,
                max: 1.0,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => '${(v * 100).toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _p1Prob = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'P2 혼합전략',
                value: _p2Prob,
                min: 0.0,
                max: 1.0,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => '${(v * 100).toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _p2Prob = v),
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
          _V('P1 기대보수', '${_eu1.toStringAsFixed(2)}'),
          _V('P2 기대보수', '${_eu2.toStringAsFixed(2)}'),
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

class _GameTheoryScreenPainter extends CustomPainter {
  final double time;
  final double p1Prob;
  final double p2Prob;

  _GameTheoryScreenPainter({
    required this.time,
    required this.p1Prob,
    required this.p2Prob,
  });

  // Payoff matrix (Prisoner's Dilemma variant): R=3, T=5, S=0, P=1
  // P1 rows: C, D   P2 cols: C, D
  // payoff[p1][p2] = (p1payoff, p2payoff)
  static const _pay = [
    [(3, 3), (0, 5)], // P1=C
    [(5, 0), (1, 1)], // P1=D
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    _text(canvas, '내시 균형 — 보수 행렬', Offset(w / 2 - 58, 4),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold));

    // ── Payoff Matrix ────────────────────────────────────────
    final matLeft = w * 0.08;
    final matTop = 22.0;
    final cellW = (w * 0.52) / 3;
    final cellH = (h * 0.42) / 3;

    final strategies = ['', 'C', 'D'];

    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final rx = matLeft + c * cellW;
        final ry = matTop + r * cellH;
        final rect = Rect.fromLTWH(rx, ry, cellW, cellH);

        if (r == 0 && c == 0) {
          // corner
        } else if (r == 0 || c == 0) {
          // Headers
          canvas.drawRect(rect, Paint()..color = const Color(0xFF1A3040));
          final label = r == 0 ? strategies[c] : strategies[r];
          final col = r == 0 ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35);
          _text(canvas, label, Offset(rx + cellW / 2 - 4, ry + cellH / 2 - 6),
              TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.bold));
        } else {
          // Data cells
          final pi = r - 1;
          final pj = c - 1;
          final pay = _pay[pi][pj];
          // Nash equilibrium: both playing D (pi=1, pj=1)
          final isNash = pi == 1 && pj == 1;
          // Best response for P1: D dominates (row 1 always >= row 0)
          final isBrP1 = pi == 1;
          final isBrP2 = pj == 1;

          Color bgCol = const Color(0xFF0D1A20);
          if (isNash) { bgCol = const Color(0xFF64FF8C).withValues(alpha: 0.18); }
          else if (isBrP1 && isBrP2) { bgCol = const Color(0xFF00D4FF).withValues(alpha: 0.08); }

          canvas.drawRect(rect, Paint()..color = bgCol);
          canvas.drawRect(rect, Paint()..color = const Color(0xFF1A3040)
            ..style = PaintingStyle.stroke..strokeWidth = 0.8);

          if (isNash) {
            canvas.drawRect(rect, Paint()..color = const Color(0xFF64FF8C)
              ..style = PaintingStyle.stroke..strokeWidth = 2.0);
          }

          // P1 payoff (top-left, orange)
          final v1 = pay.$1;
          final v2 = pay.$2;
          final c1 = v1 > 1 ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35);
          final c2 = v2 > 1 ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35);
          _text(canvas, '$v1', Offset(rx + 5, ry + 4), TextStyle(color: c1, fontSize: 10, fontWeight: FontWeight.bold));
          _text(canvas, '$v2', Offset(rx + cellW - 14, ry + cellH - 16), TextStyle(color: c2, fontSize: 10, fontWeight: FontWeight.bold));

          // Best response arrows
          if (isBrP1) {
            canvas.drawLine(Offset(rx + 3, ry + cellH - 5), Offset(rx + 3, ry + cellH - 2),
                Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..strokeWidth = 2);
          }
          if (isBrP2) {
            canvas.drawLine(Offset(rx + cellW - 3, ry + 3), Offset(rx + cellW - 6, ry + 3),
                Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..strokeWidth = 2);
          }
        }
      }
    }

    // Player labels
    _text(canvas, 'P2→', Offset(matLeft + cellW * 0.8, matTop - 12),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 8));
    _text(canvas, 'P1↓', Offset(matLeft - 22, matTop + cellH * 0.6),
        const TextStyle(color: Color(0xFFFF6B35), fontSize: 8));

    // Nash label
    _text(canvas, '★ 내시 균형: (D,D)=(1,1)', Offset(matLeft, matTop + cellH * 3 + 6),
        const TextStyle(color: Color(0xFF64FF8C), fontSize: 8, fontWeight: FontWeight.bold));

    // ── Mixed strategy / Expected utility ──────────────────
    final rightX = w * 0.64;
    final rightY = 18.0;

    _text(canvas, '혼합 전략', Offset(rightX, rightY),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8, fontWeight: FontWeight.bold));

    // EU = p1*(p2*3+…) etc
    final eu1 = p1Prob * (p2Prob * 3 + (1 - p2Prob) * 0) +
        (1 - p1Prob) * (p2Prob * 5 + (1 - p2Prob) * 1);
    final eu2 = p2Prob * (p1Prob * 3 + (1 - p1Prob) * 0) +
        (1 - p2Prob) * (p1Prob * 5 + (1 - p1Prob) * 1);

    final infoItems = [
      ('p₁(C)', '${(p1Prob * 100).toStringAsFixed(0)}%', const Color(0xFFFF6B35)),
      ('p₂(C)', '${(p2Prob * 100).toStringAsFixed(0)}%', const Color(0xFF00D4FF)),
      ('EU₁', eu1.toStringAsFixed(2), const Color(0xFFFF6B35)),
      ('EU₂', eu2.toStringAsFixed(2), const Color(0xFF00D4FF)),
    ];

    final lineH = (h * 0.18).clamp(20.0, 36.0);
    for (int i = 0; i < infoItems.length; i++) {
      final item = infoItems[i];
      final iy = rightY + 14 + i * lineH;
      _text(canvas, item.$1, Offset(rightX, iy),
          const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));
      _text(canvas, item.$2, Offset(rightX, iy + lineH * 0.45),
          TextStyle(color: item.$3, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'));
    }

    // Best response diagram: P1's best response curve
    final brX = rightX;
    final brY = h * 0.56;
    final brW = w - rightX - 8;
    final brH = h - brY - 14;

    _text(canvas, '최선 대응', Offset(brX, brY - 10),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7, fontWeight: FontWeight.bold));

    canvas.drawRect(Rect.fromLTWH(brX, brY, brW, brH),
        Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.3));

    // P1's best response: if p2 < p*, D; else C. For Prisoner's Dilemma D always dominates.
    // P2's best response: same. Nash at (0,0) = (D,D)
    // Show current point
    final ptX = brX + (1 - p2Prob) * brW;
    final ptY = brY + (1 - p1Prob) * brH;
    canvas.drawCircle(Offset(ptX, ptY), 5,
        Paint()..color = const Color(0xFFFFD700));
    // Nash equilibrium corner
    canvas.drawCircle(Offset(brX + brW, brY + brH), 5,
        Paint()..color = const Color(0xFF64FF8C));

    _text(canvas, 'p₂(C)', Offset(brX + brW / 2 - 8, brY + brH + 2),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));
    _text(canvas, 'p₁', Offset(brX - 12, brY + brH / 2 - 4),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _GameTheoryScreenPainter oldDelegate) => true;
}
