import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DimensionalityReductionScreen extends StatefulWidget {
  const DimensionalityReductionScreen({super.key});
  @override
  State<DimensionalityReductionScreen> createState() => _DimensionalityReductionScreenState();
}

class _DimensionalityReductionScreenState extends State<DimensionalityReductionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _perplexity = 30;
  double _learningRate = 200;
  double _kl = 0;

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
      _kl = math.max(0, 5.0 - _time * 0.1);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _perplexity = 30; _learningRate = 200;
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
          Text('AI/ML 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('t-SNE 시각화', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: 't-SNE 시각화',
          formula: 'p_j|i = exp(-||x_i-x_j||²/2σ²)',
          formulaDescription: 't-SNE로 고차원 데이터를 축소합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DimensionalityReductionScreenPainter(
                time: _time,
                perplexity: _perplexity,
                learningRate: _learningRate,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '퍼플렉시티',
                value: _perplexity,
                min: 5,
                max: 50,
                step: 1,
                defaultValue: 30,
                formatValue: (v) => v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _perplexity = v),
              ),
              advancedControls: [
            SimSlider(
                label: '학습률',
                value: _learningRate,
                min: 10,
                max: 500,
                step: 10,
                defaultValue: 200,
                formatValue: (v) => v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _learningRate = v),
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
          _V('퍼플렉시티', _perplexity.toStringAsFixed(0)),
          _V('KL 발산', _kl.toStringAsFixed(2)),
          _V('반복', (_time * 10).toStringAsFixed(0)),
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

class _DimensionalityReductionScreenPainter extends CustomPainter {
  final double time;
  final double perplexity;
  final double learningRate;

  _DimensionalityReductionScreenPainter({
    required this.time,
    required this.perplexity,
    required this.learningRate,
  });

  static const int _numClusters = 5;
  static const int _pointsPerCluster = 22;
  static const List<Color> _clusterColors = [
    Color(0xFF00D4FF), // cyan
    Color(0xFFFF6B35), // orange
    Color(0xFF64FF8C), // green
    Color(0xFFB57BFF), // purple
    Color(0xFFFFE066), // yellow
  ];

  // Cluster centers in normalized [0,1] space
  static const List<Offset> _centers = [
    Offset(0.22, 0.28),
    Offset(0.75, 0.22),
    Offset(0.50, 0.62),
    Offset(0.18, 0.72),
    Offset(0.80, 0.72),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final rng = math.Random(7);
    final pad = 28.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    // Convergence progress: 0=scattered, 1=clustered
    // Perplexity affects cluster spread, learningRate affects speed
    final speed = (learningRate / 200.0).clamp(0.3, 2.0);
    final rawT = (time * speed * 0.18).clamp(0.0, 3.0);
    final convergeT = (rawT / 3.0).clamp(0.0, 1.0);
    // Ease in-out
    final t = convergeT < 0.5
        ? 2 * convergeT * convergeT
        : 1 - 2 * (1 - convergeT) * (1 - convergeT);

    // Spread based on perplexity (higher = tighter clusters at convergence)
    final spread = (0.08 + (50 - perplexity) / 50 * 0.06).clamp(0.04, 0.14);

    final totalPoints = _numClusters * _pointsPerCluster;

    // Pre-generate stable random offsets
    final initX = List.generate(totalPoints, (i) => rng.nextDouble());
    final initY = List.generate(totalPoints, (i) => rng.nextDouble());
    final localOffX = List.generate(totalPoints, (i) => (rng.nextDouble() - 0.5) * spread * 2);
    final localOffY = List.generate(totalPoints, (i) => (rng.nextDouble() - 0.5) * spread * 2);

    // Draw faint axis grid lines
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.18)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      final gx = pad + w * i / 4;
      final gy = pad + h * i / 4;
      canvas.drawLine(Offset(gx, pad), Offset(gx, pad + h), gridPaint);
      canvas.drawLine(Offset(pad, gy), Offset(pad + w, gy), gridPaint);
    }

    // Draw inter-cluster distance arrows when converged
    if (t > 0.7) {
      final arrowAlpha = ((t - 0.7) / 0.3).clamp(0.0, 1.0) * 0.25;
      final arrowPaint = Paint()
        ..color = AppColors.muted.withValues(alpha: arrowAlpha)
        ..strokeWidth = 0.8;
      for (int c1 = 0; c1 < _numClusters; c1++) {
        for (int c2 = c1 + 1; c2 < _numClusters; c2++) {
          final p1 = Offset(
            pad + _centers[c1].dx * w,
            pad + _centers[c1].dy * h,
          );
          final p2 = Offset(
            pad + _centers[c2].dx * w,
            pad + _centers[c2].dy * h,
          );
          canvas.drawLine(p1, p2, arrowPaint);
        }
      }
    }

    // Draw points
    for (int c = 0; c < _numClusters; c++) {
      final color = _clusterColors[c];
      final cx = _centers[c].dx;
      final cy = _centers[c].dy;

      for (int p = 0; p < _pointsPerCluster; p++) {
        final idx = c * _pointsPerCluster + p;
        // Interpolate from scattered to clustered
        final nx = initX[idx] * (1 - t) + (cx + localOffX[idx]) * t;
        final ny = initY[idx] * (1 - t) + (cy + localOffY[idx]) * t;
        final px = pad + nx.clamp(0.0, 1.0) * w;
        final py = pad + ny.clamp(0.0, 1.0) * h;

        // Soft glow halo
        for (int g = 2; g >= 0; g--) {
          canvas.drawCircle(
            Offset(px, py),
            3.5 + g * 2.5,
            Paint()..color = color.withValues(alpha: 0.04 + g * 0.02),
          );
        }
        // Point
        canvas.drawCircle(Offset(px, py), 3.2, Paint()..color = color.withValues(alpha: 0.85));
      }
    }

    // Draw cluster centroids as glowing stars when converged
    if (t > 0.5) {
      final starAlpha = ((t - 0.5) / 0.5).clamp(0.0, 1.0);
      for (int c = 0; c < _numClusters; c++) {
        final color = _clusterColors[c];
        final px = pad + _centers[c].dx * w;
        final py = pad + _centers[c].dy * h;
        final pulse = 1.0 + math.sin(time * 2.5 + c * 1.2) * 0.18;

        // Glow rings
        for (int g = 4; g >= 1; g--) {
          canvas.drawCircle(
            Offset(px, py),
            6.0 * pulse + g * 3.5,
            Paint()..color = color.withValues(alpha: starAlpha * 0.06 * g),
          );
        }
        // Star body
        canvas.drawCircle(
          Offset(px, py),
          5.5 * pulse,
          Paint()..color = color.withValues(alpha: starAlpha * 0.95),
        );
        // Star cross
        final starPaint = Paint()
          ..color = Colors.white.withValues(alpha: starAlpha * 0.7)
          ..strokeWidth = 1.5;
        final sr = 8.0 * pulse;
        canvas.drawLine(Offset(px - sr, py), Offset(px + sr, py), starPaint);
        canvas.drawLine(Offset(px, py - sr), Offset(px, py + sr), starPaint);
      }
    }

    // Phase label
    final phase = t < 0.05 ? '초기화' : t < 0.95 ? '수렴 중...' : '수렴 완료';
    final phaseColor = t < 0.95 ? AppColors.accent2 : AppColors.accent;
    final ptp = TextPainter(
      text: TextSpan(text: phase, style: TextStyle(color: phaseColor, fontSize: 10, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    ptp.paint(canvas, Offset(size.width - ptp.width - 8, 6));
  }

  @override
  bool shouldRepaint(covariant _DimensionalityReductionScreenPainter oldDelegate) => true;
}
