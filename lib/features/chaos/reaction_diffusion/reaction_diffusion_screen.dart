import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ReactionDiffusionScreen extends StatefulWidget {
  const ReactionDiffusionScreen({super.key});
  @override
  State<ReactionDiffusionScreen> createState() => _ReactionDiffusionScreenState();
}

class _ReactionDiffusionScreenState extends State<ReactionDiffusionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _feedRate = 0.04;
  double _killRate = 0.06;
  int _iterCount = 0;

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
      _iterCount++;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _feedRate = 0.04;
      _killRate = 0.06;
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
          Text('혼돈 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('반응-확산 패턴', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '혼돈 시뮬레이션',
          title: '반응-확산 패턴',
          formula: '∂u/∂t = Dᵤ∇²u + f(u,v)',
          formulaDescription: 'Gray-Scott 모델로 튜링 패턴을 생성합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ReactionDiffusionScreenPainter(
                time: _time,
                feedRate: _feedRate,
                killRate: _killRate,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'Feed Rate (F)',
                value: _feedRate,
                min: 0.01,
                max: 0.08,
                step: 0.002,
                defaultValue: 0.04,
                formatValue: (v) => '${v.toStringAsFixed(3)}',
                onChanged: (v) => setState(() => _feedRate = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'Kill Rate (k)',
                value: _killRate,
                min: 0.04,
                max: 0.07,
                step: 0.001,
                defaultValue: 0.06,
                formatValue: (v) => '${v.toStringAsFixed(3)}',
                onChanged: (v) => setState(() => _killRate = v),
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
          _V('F', '${_feedRate.toStringAsFixed(3)}'),
          _V('k', '${_killRate.toStringAsFixed(3)}'),
          _V('반복', '${_iterCount}'),
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

class _ReactionDiffusionScreenPainter extends CustomPainter {
  final double time;
  final double feedRate;
  final double killRate;

  _ReactionDiffusionScreenPainter({
    required this.time,
    required this.feedRate,
    required this.killRate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Gray-Scott reaction-diffusion on 48x48 grid (reduced for performance)
    const G = 48;
    const du = 0.2097;
    const dv = 0.105;
    const dt = 1.0;
    final F = feedRate;
    final k = killRate;

    // Initialize with seeded RNG — central perturbation
    // Deterministic from time bucket so it "evolves" visually
    final steps = (time * 8).toInt().clamp(0, 600);

    final u = List.generate(G, (i) => List.filled(G, 1.0));
    final v = List.generate(G, (i) => List.filled(G, 0.0));

    // Central seed perturbation
    const hw = 4;
    for (int i = G ~/ 2 - hw; i <= G ~/ 2 + hw; i++) {
      for (int j = G ~/ 2 - hw; j <= G ~/ 2 + hw; j++) {
        if (i >= 0 && i < G && j >= 0 && j < G) {
          u[i][j] = 0.5;
          v[i][j] = 0.25;
        }
      }
    }
    // Small random noise
    final rng = math.Random(42);
    for (int i = 0; i < G; i++) {
      for (int j = 0; j < G; j++) {
        u[i][j] += (rng.nextDouble() - 0.5) * 0.02;
        v[i][j] += (rng.nextDouble() - 0.5) * 0.02;
      }
    }

    // Iterate Gray-Scott
    final un = List.generate(G, (i) => List.filled(G, 0.0));
    final vn = List.generate(G, (i) => List.filled(G, 0.0));

    for (int s = 0; s < steps; s++) {
      for (int i = 0; i < G; i++) {
        for (int j = 0; j < G; j++) {
          final ip = (i + 1) % G, im = (i - 1 + G) % G;
          final jp = (j + 1) % G, jm = (j - 1 + G) % G;
          final lapU = u[ip][j] + u[im][j] + u[i][jp] + u[i][jm] - 4 * u[i][j];
          final lapV = v[ip][j] + v[im][j] + v[i][jp] + v[i][jm] - 4 * v[i][j];
          final uv2 = u[i][j] * v[i][j] * v[i][j];
          un[i][j] = (u[i][j] + dt * (du * lapU - uv2 + F * (1 - u[i][j]))).clamp(0.0, 1.0);
          vn[i][j] = (v[i][j] + dt * (dv * lapV + uv2 - (F + k) * v[i][j])).clamp(0.0, 1.0);
        }
      }
      for (int i = 0; i < G; i++) {
        for (int j = 0; j < G; j++) {
          u[i][j] = un[i][j];
          v[i][j] = vn[i][j];
        }
      }
    }

    // Render grid to canvas
    final gridAreaH = h * 0.76;
    final cellW = w / G;
    final cellH = gridAreaH / G;

    for (int i = 0; i < G; i++) {
      for (int j = 0; j < G; j++) {
        final uv = u[i][j].clamp(0.0, 1.0);
        // Color: high u = dark bg, low u = bright (pattern)
        final bright = (1.0 - uv);
        final r = (bright * 0 + uv * 13).toInt();
        final g2 = (bright * 180 + uv * 26).toInt().clamp(0, 255);
        final b2 = (bright * 100 + uv * 32).toInt().clamp(0, 255);
        canvas.drawRect(
          Rect.fromLTWH(j * cellW, i * cellH, cellW + 0.5, cellH + 0.5),
          Paint()..color = Color.fromARGB(255, r, g2, b2),
        );
      }
    }

    // Title
    _text(canvas, '반응-확산 (Gray-Scott) 튜링 패턴', Offset(w / 2 - 88, gridAreaH + 5),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 9, fontWeight: FontWeight.bold));

    // Pattern type label
    final String patternType;
    if (F < 0.025) {
      patternType = '소멸 패턴';
    } else if (F < 0.04 && k < 0.055) {
      patternType = '점상 패턴 (Spots)';
    } else if (F < 0.055 && k > 0.06) {
      patternType = '줄무늬 (Stripes)';
    } else {
      patternType = '미로 패턴 (Maze)';
    }

    _text(canvas, '$patternType   F=${F.toStringAsFixed(3)}  k=${k.toStringAsFixed(3)}  iter=$steps',
        Offset(8, gridAreaH + 20),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));
    _text(canvas, 'du/dt=Dᵤ∇²u−uv²+F(1−u)',
        Offset(8, h - 12),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _ReactionDiffusionScreenPainter oldDelegate) => true;
}
