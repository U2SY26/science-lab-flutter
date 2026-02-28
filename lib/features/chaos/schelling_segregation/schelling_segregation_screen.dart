import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class SchellingSegregationScreen extends StatefulWidget {
  const SchellingSegregationScreen({super.key});
  @override
  State<SchellingSegregationScreen> createState() => _SchellingSegregationScreenState();
}

class _SchellingSegregationScreenState extends State<SchellingSegregationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _tolerance = 0.3;
  double _vacancy = 0.1;
  double _satisfaction = 0;

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
      _satisfaction = math.min(1.0, _tolerance + _time * 0.05);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _tolerance = 0.3; _vacancy = 0.1;
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
          Text('카오스/복잡계 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('셸링 분리 모델', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스/복잡계 시뮬레이션',
          title: '셸링 분리 모델',
          formula: 'T = similar/total neighbors',
          formulaDescription: '온건한 개인 선호에서 분리가 발생하는 것을 모델링합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SchellingSegregationScreenPainter(
                time: _time,
                tolerance: _tolerance,
                vacancy: _vacancy,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '허용 임계값',
                value: _tolerance,
                min: 0.1,
                max: 0.8,
                step: 0.05,
                defaultValue: 0.3,
                formatValue: (v) => '${(v * 100).toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _tolerance = v),
              ),
              advancedControls: [
            SimSlider(
                label: '빈 공간 비율',
                value: _vacancy,
                min: 0.05,
                max: 0.3,
                step: 0.05,
                defaultValue: 0.1,
                formatValue: (v) => '${(v * 100).toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _vacancy = v),
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
          _V('허용도', '${(_tolerance * 100).toStringAsFixed(0)}%'),
          _V('만족도', '${(_satisfaction * 100).toStringAsFixed(0)}%'),
          _V('빈 공간', '${(_vacancy * 100).toStringAsFixed(0)}%'),
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

class _SchellingSegregationScreenPainter extends CustomPainter {
  final double time;
  final double tolerance;
  final double vacancy;

  _SchellingSegregationScreenPainter({
    required this.time,
    required this.tolerance,
    required this.vacancy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 1 || size.height < 1) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    const int N = 40;
    // Reserve bottom 28px for status bar
    const double botBar = 28.0;
    final gridSize = math.min(size.width, size.height - botBar);
    final cellSize = gridSize / N;
    final ox = (size.width - gridSize) / 2;
    const oy = 0.0;

    // Deterministic grid: seed=99, evolve based on time steps
    final rng = math.Random(99);
    // -1=empty, 0=group A (cyan), 1=group B (orange)
    final grid = List<int>.generate(N * N, (_) {
      final r = rng.nextDouble();
      if (r < vacancy) return -1;
      return r < vacancy + (1 - vacancy) / 2 ? 0 : 1;
    });

    // Run Schelling swaps based on time
    final swapRng = math.Random(42);
    final swapSteps = (time * 8).toInt().clamp(0, 2000);
    for (int s = 0; s < swapSteps; s++) {
      // Find a dissatisfied agent
      final idx = swapRng.nextInt(N * N);
      final agent = grid[idx];
      if (agent == -1) continue;
      final row = idx ~/ N;
      final col = idx % N;
      // Count same-type neighbors (Moore neighborhood)
      int same = 0, total = 0;
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final nr = row + dr;
          final nc = col + dc;
          if (nr < 0 || nr >= N || nc < 0 || nc >= N) continue;
          final nb = grid[nr * N + nc];
          if (nb != -1) {
            total++;
            if (nb == agent) same++;
          }
        }
      }
      final satisfied = total == 0 || (same / total) >= tolerance;
      if (!satisfied) {
        // Swap with a random empty cell
        final emptyIdx = swapRng.nextInt(N * N);
        if (grid[emptyIdx] == -1) {
          grid[emptyIdx] = agent;
          grid[idx] = -1;
        }
      }
    }

    // Compute satisfaction ratio
    int satisfiedCount = 0, agentCount = 0;
    for (int i = 0; i < N * N; i++) {
      final agent = grid[i];
      if (agent == -1) continue;
      agentCount++;
      final row = i ~/ N;
      final col = i % N;
      int same = 0, total = 0;
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final nr = row + dr;
          final nc = col + dc;
          if (nr < 0 || nr >= N || nc < 0 || nc >= N) continue;
          final nb = grid[nr * N + nc];
          if (nb != -1) {
            total++;
            if (nb == agent) same++;
          }
        }
      }
      if (total == 0 || (same / total) >= tolerance) satisfiedCount++;
    }
    final satRatio = agentCount > 0 ? satisfiedCount / agentCount : 0.0;

    // Draw cells
    for (int row = 0; row < N; row++) {
      for (int col = 0; col < N; col++) {
        final agent = grid[row * N + col];
        if (agent == -1) continue;
        final rx = ox + col * cellSize;
        final ry = oy + row * cellSize;
        final rect = Rect.fromLTWH(rx, ry, cellSize - 0.4, cellSize - 0.4);

        // Check satisfaction
        int same = 0, total = 0;
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue;
            final nr = row + dr;
            final nc = col + dc;
            if (nr < 0 || nr >= N || nc < 0 || nc >= N) continue;
            final nb = grid[nr * N + nc];
            if (nb != -1) {
              total++;
              if (nb == agent) same++;
            }
          }
        }
        final isSatisfied = total == 0 || (same / total) >= tolerance;

        Color baseColor = agent == 0 ? AppColors.accent : AppColors.accent2;
        if (!isSatisfied) {
          // Dissatisfied: red tint
          baseColor = Color.lerp(baseColor, const Color(0xFFFF2222), 0.5)!;
        }
        canvas.drawRect(rect, Paint()..color = baseColor.withValues(alpha: 0.85));
        if (!isSatisfied) {
          canvas.drawRect(rect, Paint()
            ..color = const Color(0xFFFF2222).withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8);
        }
      }
    }

    // Bottom status bar: satisfaction progress + label
    final barY = size.height - botBar + 4;
    final barW = size.width - 16;
    // Background track
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(8, barY + 8, barW, 10), const Radius.circular(5)),
      Paint()..color = AppColors.simGrid,
    );
    // Fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(8, barY + 8, barW * satRatio, 10), const Radius.circular(5)),
      Paint()..color = satRatio >= 0.95 ? const Color(0xFF64FF8C) : AppColors.accent,
    );
    // Label
    final label = satRatio >= 0.95 ? '분리 완료 ✓' : '만족도 ${(satRatio * 100).toStringAsFixed(0)}%';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: satRatio >= 0.95 ? const Color(0xFF64FF8C) : AppColors.ink,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, barY - 2));
  }

  @override
  bool shouldRepaint(covariant _SchellingSegregationScreenPainter oldDelegate) => true;
}
