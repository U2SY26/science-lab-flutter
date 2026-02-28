import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class AntColonyScreen extends StatefulWidget {
  const AntColonyScreen({super.key});
  @override
  State<AntColonyScreen> createState() => _AntColonyScreenState();
}

class _AntColonyScreenState extends State<AntColonyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _evapRate = 0.1;
  double _numAnts = 20;
  double _bestPath = 100.0, _avgPath = 150.0;

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
      _bestPath = 100 - _time * 2 * _evapRate;
      if (_bestPath < 50) _bestPath = 50;
      _avgPath = _bestPath * 1.5;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _evapRate = 0.1; _numAnts = 20.0;
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
          const Text('개미 군체 최적화', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스 시뮬레이션',
          title: '개미 군체 최적화',
          formula: 'τ_ij = (1-ρ)τ_ij + Δτ_ij',
          formulaDescription: '개미 군체 최적화 알고리즘의 경로 탐색을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _AntColonyScreenPainter(
                time: _time,
                evapRate: _evapRate,
                numAnts: _numAnts,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '증발률 (ρ)',
                value: _evapRate,
                min: 0.01,
                max: 0.5,
                step: 0.01,
                defaultValue: 0.1,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _evapRate = v),
              ),
              advancedControls: [
            SimSlider(
                label: '개미 수',
                value: _numAnts,
                min: 5,
                max: 100,
                step: 5,
                defaultValue: 20,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _numAnts = v),
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
          _V('최적 경로', _bestPath.toStringAsFixed(1)),
          _V('평균 경로', _avgPath.toStringAsFixed(1)),
          _V('개미 수', _numAnts.toInt().toString()),
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

class _AntColonyScreenPainter extends CustomPainter {
  final double time;
  final double evapRate;
  final double numAnts;

  _AntColonyScreenPainter({
    required this.time,
    required this.evapRate,
    required this.numAnts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Nest: bottom-left; Food: top-right
    final nest = Offset(size.width * 0.12, size.height * 0.82);
    final food = Offset(size.width * 0.88, size.height * 0.12);

    // Pheromone trail strength decays with evapRate
    final trailAge = time * evapRate;
    final trailAlpha = (1.0 - (trailAge % 1.0) * 0.5).clamp(0.15, 0.95);

    // Draw 3 candidate paths (waypoints vary)
    final rng = math.Random(17);
    final paths = <List<Offset>>[];
    for (int p = 0; p < 5; p++) {
      final mid1 = Offset(
        nest.dx + (food.dx - nest.dx) * 0.33 + (rng.nextDouble() - 0.5) * size.width * 0.3,
        nest.dy + (food.dy - nest.dy) * 0.33 + (rng.nextDouble() - 0.5) * size.height * 0.3,
      );
      final mid2 = Offset(
        nest.dx + (food.dx - nest.dx) * 0.66 + (rng.nextDouble() - 0.5) * size.width * 0.3,
        nest.dy + (food.dy - nest.dy) * 0.66 + (rng.nextDouble() - 0.5) * size.height * 0.3,
      );
      paths.add([nest, mid1, mid2, food]);
    }

    // Best path index (converges over time)
    final convergence = (time * 0.3).clamp(0.0, 1.0);
    final bestIdx = 2;

    // Draw pheromone trails
    for (int pi = 0; pi < paths.length; pi++) {
      final isBest = pi == bestIdx;
      // Best path gets stronger pheromone
      final pherStrength = isBest
          ? (0.3 + convergence * 0.65).clamp(0.0, 1.0)
          : (0.3 - convergence * 0.25).clamp(0.05, 0.4);
      final strokeW = isBest ? 2.5 + convergence * 2.0 : 1.0;
      final col = isBest
          ? AppColors.accent.withValues(alpha: pherStrength * trailAlpha)
          : AppColors.muted.withValues(alpha: pherStrength * 0.5);
      final paint = Paint()
        ..color = col
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final pts = paths[pi];
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int s = 1; s < pts.length; s++) { path.lineTo(pts[s].dx, pts[s].dy); }
      canvas.drawPath(path, paint);
    }

    // Draw ants moving on paths
    final antCount = numAnts.toInt();
    final antPaint = Paint()..style = PaintingStyle.fill;
    for (int a = 0; a < antCount; a++) {
      // Which path does this ant prefer?
      final rngA = math.Random(a * 31 + 7);
      final prefBest = rngA.nextDouble() < (0.2 + convergence * 0.6);
      final pathIdx = prefBest ? bestIdx : (a % paths.length);
      final pts = paths[pathIdx];
      // Ant progress along path
      final progress = ((time * 0.4 + a * 0.13) % 2.0); // 0→1 outward, 1→2 return
      final t = progress < 1.0 ? progress : 2.0 - progress;
      // Interpolate along 3 segments
      Offset antPos;
      final segT = t * (pts.length - 1);
      final seg = segT.floor().clamp(0, pts.length - 2);
      final localT = segT - seg;
      antPos = Offset(
        pts[seg].dx + (pts[seg + 1].dx - pts[seg].dx) * localT,
        pts[seg].dy + (pts[seg + 1].dy - pts[seg].dy) * localT,
      );
      final isReturning = progress >= 1.0;
      antPaint.color = isReturning
          ? AppColors.accent2.withValues(alpha: 0.85) // returning with food
          : const Color(0xFFFF4444).withValues(alpha: 0.8);
      canvas.drawCircle(antPos, 2.5, antPaint);
    }

    // Draw nest glow (cyan, bottom-left)
    _drawGlowCircle(canvas, nest, AppColors.accent, 12, '巢');
    // Draw food glow (green, top-right)
    _drawGlowCircle(canvas, food, const Color(0xFF64FF8C), 10, '食');

    // Stats label
    final tp = TextPainter(
      text: TextSpan(
        text: 'ρ=${evapRate.toStringAsFixed(2)}  ants=${numAnts.toInt()}',
        style: const TextStyle(color: Color(0xFF5A8A9A), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(6, size.height - 18));
  }

  void _drawGlowCircle(Canvas canvas, Offset center, Color col, double r, String label) {
    for (double g = r + 10; g >= r; g -= 4) {
      canvas.drawCircle(center, g, Paint()..color = col.withValues(alpha: 0.06));
    }
    canvas.drawCircle(center, r, Paint()..color = col.withValues(alpha: 0.8));
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(color: col, fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - r - 14));
  }

  @override
  bool shouldRepaint(covariant _AntColonyScreenPainter oldDelegate) => true;
}
