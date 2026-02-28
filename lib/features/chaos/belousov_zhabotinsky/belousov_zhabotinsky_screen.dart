import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BelousovZhabotinskyScreen extends StatefulWidget {
  const BelousovZhabotinskyScreen({super.key});
  @override
  State<BelousovZhabotinskyScreen> createState() => _BelousovZhabotinskyScreenState();
}

class _BelousovZhabotinskyScreenState extends State<BelousovZhabotinskyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _paramA = 1;
  double _paramQ = 0.01;
  double _concX = 1, _concY = 1;

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
      final dt = 0.016;
      final dxdt = _paramA * (_concY - _concX * _concY + _concX - _paramQ * _concX * _concX);
      final dydt = (-_concY - _concX * _concY + _concX) / _paramA;
      _concX = math.max(0, _concX + dxdt * dt);
      _concY = math.max(0, _concY + dydt * dt);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _paramA = 1.0; _paramQ = 0.01; _concX = 1; _concY = 1;
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
          const Text('벨루소프-자보틴스키 반응', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스/복잡계 시뮬레이션',
          title: '벨루소프-자보틴스키 반응',
          formula: 'dx/dt = a(y-xy+x-qx²)',
          formulaDescription: '진동하는 화학 반응을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BelousovZhabotinskyScreenPainter(
                time: _time,
                paramA: _paramA,
                paramQ: _paramQ,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '매개변수 a',
                value: _paramA,
                min: 0.1,
                max: 5,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _paramA = v),
              ),
              advancedControls: [
            SimSlider(
                label: '매개변수 q',
                value: _paramQ,
                min: 0.001,
                max: 0.1,
                step: 0.001,
                defaultValue: 0.01,
                formatValue: (v) => v.toStringAsFixed(3),
                onChanged: (v) => setState(() => _paramQ = v),
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
          _V('[X]', _concX.toStringAsFixed(3)),
          _V('[Y]', _concY.toStringAsFixed(3)),
          _V('a', _paramA.toStringAsFixed(1)),
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

class _BelousovZhabotinskyScreenPainter extends CustomPainter {
  final double time;
  final double paramA;
  final double paramQ;

  _BelousovZhabotinskyScreenPainter({
    required this.time,
    required this.paramA,
    required this.paramQ,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 1 || size.height < 1) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    const int N = 80;
    // 3 states: 0=resting, 1=excited, 2=refractory
    // Determine cell pixel size to fit in available area
    final gridSide = math.min(size.width, size.height);
    final cellW = size.width / N;
    final cellH = gridSide / N;

    // Build spiral initial condition (seed once, evolve with time)
    // Use integer step derived from time for deterministic evolution
    final steps = (time * 6).toInt();

    // Initialize grid with spiral seed
    final grid = List<int>.filled(N * N, 0);
    final gridNext = List<int>.filled(N * N, 0);

    // Spiral seed: place an excited arc in the center
    final cx = N ~/ 2;
    final cy = N ~/ 2;
    // Seed a small spiral by placing excited+refractory cells
    final seedRng = math.Random(7);
    for (int i = 0; i < N * N; i++) {
      final row = i ~/ N;
      final col = i % N;
      final dr = row - cy;
      final dc = col - cx;
      final dist = math.sqrt(dr * dr + dc * dc);
      final angle = math.atan2(dr.toDouble(), dc.toDouble());
      // Archimedean spiral: state depends on distance and angle
      final spiralPhase = (dist * 0.6 - angle * 2) % (math.pi * 2);
      if (dist < 2) {
        grid[i] = 1; // center excited
      } else if (spiralPhase < 0.8) {
        grid[i] = 1; // excited band
      } else if (spiralPhase < 2.2) {
        grid[i] = 2; // refractory band
      } else {
        grid[i] = seedRng.nextDouble() < 0.02 ? 1 : 0; // mostly resting
      }
    }

    // Evolve BZ rules for `steps` iterations
    // Rules: excited→refractory, refractory→resting,
    //        resting→excited if >=k excited neighbors (threshold based on paramA)
    final threshold = math.max(1, (3.0 / paramA).round());
    for (int s = 0; s < steps % 200; s++) {
      for (int i = 0; i < N * N; i++) {
        final row = i ~/ N;
        final col = i % N;
        final state = grid[i];
        if (state == 1) {
          gridNext[i] = 2; // excited → refractory
        } else if (state == 2) {
          gridNext[i] = 0; // refractory → resting
        } else {
          // Count excited neighbors (Moore neighborhood)
          int excitedNb = 0;
          for (int dr = -1; dr <= 1; dr++) {
            for (int dc = -1; dc <= 1; dc++) {
              if (dr == 0 && dc == 0) continue;
              final nr = row + dr;
              final nc = col + dc;
              if (nr < 0 || nr >= N || nc < 0 || nc >= N) continue;
              if (grid[nr * N + nc] == 1) excitedNb++;
            }
          }
          gridNext[i] = excitedNb >= threshold ? 1 : 0;
        }
      }
      for (int i = 0; i < N * N; i++) { grid[i] = gridNext[i]; }
    }

    // Draw cells
    for (int row = 0; row < N; row++) {
      for (int col = 0; col < N; col++) {
        final state = grid[row * N + col];
        if (state == 0) continue; // resting = background (skip drawing = simBg)
        final rx = col * cellW;
        final ry = row * cellH;
        final rect = Rect.fromLTWH(rx, ry, cellW, cellH);
        if (state == 1) {
          // Excited: bright cyan with glow
          canvas.drawRect(rect, Paint()..color = AppColors.accent.withValues(alpha: 0.95));
          // Inner glow
          canvas.drawRect(
            rect.deflate(0.5),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.25)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
          );
        } else {
          // Refractory: gradient cyan → dark (fade by step fraction)
          // Use a fixed gradient appearance
          final alpha = 0.55 + 0.1 * math.sin(time + row * 0.1);
          canvas.drawRect(
            rect,
            Paint()..color = AppColors.accent.withValues(alpha: alpha.clamp(0.0, 1.0) * 0.5),
          );
        }
      }
    }

    // Speed / state label
    final labelTp = TextPainter(
      text: TextSpan(
        text: 'BZ 반응  a=${paramA.toStringAsFixed(1)}  q=${paramQ.toStringAsFixed(3)}  단계: ${steps % 200}',
        style: const TextStyle(color: AppColors.muted, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 8);
    labelTp.paint(canvas, Offset(4, size.height - 14));
  }

  @override
  bool shouldRepaint(covariant _BelousovZhabotinskyScreenPainter oldDelegate) => true;
}
