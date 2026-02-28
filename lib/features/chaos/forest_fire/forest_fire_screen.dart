import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ForestFireScreen extends StatefulWidget {
  const ForestFireScreen({super.key});
  @override
  State<ForestFireScreen> createState() => _ForestFireScreenState();
}

class _ForestFireScreenState extends State<ForestFireScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _fireProb = 0.001;
  double _growProb = 0.05;
  double _density = 0.5, _burning = 0.01;

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
      _density = _growProb / (_growProb + _fireProb);
      _burning = _fireProb * _density;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _fireProb = 0.001; _growProb = 0.05;
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
          Text('카오스 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('산불 모델', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스 시뮬레이션',
          title: '산불 모델',
          formula: 'p(fire) = f, p(grow) = p',
          formulaDescription: '자기조직 임계 산불 모델을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ForestFireScreenPainter(
                time: _time,
                fireProb: _fireProb,
                growProb: _growProb,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '발화 확률 (f)',
                value: _fireProb,
                min: 0.0001,
                max: 0.01,
                step: 0.0001,
                defaultValue: 0.001,
                formatValue: (v) => v.toStringAsFixed(4),
                onChanged: (v) => setState(() => _fireProb = v),
              ),
              advancedControls: [
            SimSlider(
                label: '성장 확률 (p)',
                value: _growProb,
                min: 0.01,
                max: 0.2,
                step: 0.01,
                defaultValue: 0.05,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _growProb = v),
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
          _V('밀도', (_density * 100).toStringAsFixed(1) + '%'),
          _V('화재', (_burning * 100).toStringAsFixed(3) + '%'),
          _V('f/p', (_fireProb / _growProb).toStringAsFixed(4)),
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

class _ForestFireScreenPainter extends CustomPainter {
  final double time;
  final double fireProb;
  final double growProb;

  _ForestFireScreenPainter({
    required this.time,
    required this.fireProb,
    required this.growProb,
  });

  // Cell states
  static const int _empty = 0, _tree = 1, _burning = 2, _burned = 3;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    const int cols = 40, rows = 28;
    final cellW = size.width / cols;
    final cellH = (size.height - 28) / rows; // leave 28px for stats bar

    // Generate grid state from time using seeded RNG
    // Density of trees based on growProb/fireProb ratio
    final density = (growProb / (growProb + fireProb)).clamp(0.2, 0.95);
    final burnFront = (time * 3.5 * fireProb * 400).clamp(0.0, cols.toDouble());

    final cellPaint = Paint()..style = PaintingStyle.fill;
    int treeCount = 0, burningCount = 0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cellRng = math.Random(r * 1000 + c + 7);
        final baseVal = cellRng.nextDouble();
        int state;
        if (baseVal > density) {
          state = _empty;
        } else {
          // Fire front wave from left
          final distToFront = (c - burnFront).abs();
          if (distToFront < 1.5) {
            state = _burning;
          } else if (c < burnFront - 1.5) {
            // Behind fire: burned or regrown
            final regrowth = ((time * growProb * 8) - c * 0.4).clamp(0.0, 1.0);
            state = cellRng.nextDouble() < regrowth ? _tree : _burned;
          } else {
            state = _tree;
          }
        }

        Color cellColor;
        switch (state) {
          case _tree:
            treeCount++;
            final greenShade = 0.5 + cellRng.nextDouble() * 0.5;
            cellColor = Color.fromRGBO(
              (20 * greenShade).round(), (120 + 80 * greenShade).round(), (30 * greenShade).round(), 1.0);
            break;
          case _burning:
            burningCount++;
            final pulse = 0.6 + 0.4 * math.sin(time * 8 + c * 0.5 + r * 0.3);
            cellColor = Color.fromRGBO(
              255, (80 + 80 * pulse).round(), 0, pulse);
            break;
          case _burned:
            cellColor = const Color(0xFF2A2A2A);
            break;
          default: // empty
            cellColor = AppColors.simBg;
        }

        cellPaint.color = cellColor;
        canvas.drawRect(
          Rect.fromLTWH(c * cellW, r * cellH, cellW - 0.5, cellH - 0.5),
          cellPaint,
        );

        // Glow for burning cells
        if (state == _burning) {
          final glowPulse = 0.5 + 0.5 * math.sin(time * 10 + c + r);
          canvas.drawRect(
            Rect.fromLTWH(c * cellW - 1, r * cellH - 1, cellW + 2, cellH + 2),
            Paint()..color = const Color(0xFFFF6B00).withValues(alpha: 0.3 * glowPulse),
          );
        }
      }
    }

    // Wind arrow (top-right)
    _drawWindArrow(canvas, Offset(size.width - 50, 12), fireProb);

    // Stats bar at bottom
    final statsY = rows * cellH + 4;
    final treePct = treeCount / (cols * rows);
    final burnPct = burningCount / (cols * rows);
    _drawStatsBar(canvas, size, statsY, treePct, burnPct);
  }

  void _drawWindArrow(Canvas canvas, Offset origin, double fireProb) {
    final windStrength = (fireProb * 500).clamp(0.3, 1.0);
    final arrowLen = 20.0 * windStrength;
    final paint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(origin, Offset(origin.dx + arrowLen, origin.dy), paint);
    canvas.drawLine(Offset(origin.dx + arrowLen, origin.dy),
        Offset(origin.dx + arrowLen - 6, origin.dy - 4), paint);
    canvas.drawLine(Offset(origin.dx + arrowLen, origin.dy),
        Offset(origin.dx + arrowLen - 6, origin.dy + 4), paint);
    final tp = TextPainter(
      text: TextSpan(text: '풍', style: TextStyle(color: AppColors.muted.withValues(alpha: 0.6), fontSize: 8)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(origin.dx - 12, origin.dy - 5));
  }

  void _drawStatsBar(Canvas canvas, Size size, double y, double treePct, double burnPct) {
    final barW = size.width - 12;
    // Background
    canvas.drawRect(Rect.fromLTWH(6, y, barW, 18),
        Paint()..color = AppColors.simGrid.withValues(alpha: 0.6));
    // Tree coverage (green)
    canvas.drawRect(Rect.fromLTWH(6, y, barW * treePct, 18),
        Paint()..color = const Color(0xFF2D7A2D).withValues(alpha: 0.8));
    // Burning (orange)
    canvas.drawRect(Rect.fromLTWH(6, y, barW * burnPct, 18),
        Paint()..color = AppColors.accent2.withValues(alpha: 0.7));
    final tp = TextPainter(
      text: TextSpan(
        text: '숲 ${(treePct * 100).toStringAsFixed(0)}%  화재 ${(burnPct * 100).toStringAsFixed(1)}%',
        style: const TextStyle(color: Color(0xFFE0F4FF), fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(10, y + 4));
  }

  @override
  bool shouldRepaint(covariant _ForestFireScreenPainter oldDelegate) => true;
}
