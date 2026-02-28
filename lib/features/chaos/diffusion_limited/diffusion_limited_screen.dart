import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DiffusionLimitedScreen extends StatefulWidget {
  const DiffusionLimitedScreen({super.key});
  @override
  State<DiffusionLimitedScreen> createState() => _DiffusionLimitedScreenState();
}

class _DiffusionLimitedScreenState extends State<DiffusionLimitedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _stickProb = 0.8;
  final List<Offset> _cluster = [const Offset(0, 0)];
  bool _isNearCluster(double x, double y) {
    for (final p in _cluster) {
      if ((p.dx - x).abs() < 3 && (p.dy - y).abs() < 3) return true;
    }
    return false;
  }

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
      final rng = math.Random();
      for (int i = 0; i < 5; i++) {
        double px = rng.nextDouble() * 200 - 100;
        double py = rng.nextDouble() * 200 - 100;
        for (int s = 0; s < 100; s++) {
          px += rng.nextDouble() * 4 - 2;
          py += rng.nextDouble() * 4 - 2;
          if (_isNearCluster(px, py) && rng.nextDouble() < _stickProb) {
            _cluster.add(Offset(px, py));
            break;
          }
        }
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _stickProb = 0.8;
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
          const Text('확산 제한 응집', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '혼돈 시뮬레이션',
          title: '확산 제한 응집',
          formula: 'DLA fractal',
          formulaDescription: '무작위 입자가 응집하여 프랙탈 구조를 형성합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DiffusionLimitedScreenPainter(
                time: _time,
                stickProb: _stickProb,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '부착 확률',
                value: _stickProb,
                min: 0.1,
                max: 1.0,
                step: 0.05,
                defaultValue: 0.8,
                formatValue: (v) => '${(v * 100).toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _stickProb = v),
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
          _V('입자 수', '${_cluster.length}'),
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

class _DiffusionLimitedScreenPainter extends CustomPainter {
  final double time;
  final double stickProb;

  _DiffusionLimitedScreenPainter({
    required this.time,
    required this.stickProb,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Main DLA cluster area (top 70%)
    final dlaH = h * 0.70;
    final cx = w / 2;
    final cy = dlaH * 0.52;

    // Generate DLA cluster deterministically using seeded RNG
    // Number of particles grows with time (up to 200)
    final nParticles = (time * 8 * stickProb).clamp(1, 200).toInt();
    final rng = math.Random(2024);

    // Seed
    final cluster = <(double, double)>[(0.0, 0.0)];

    bool isNearCluster(double px, double py) {
      for (final p in cluster) {
        final dx = p.$1 - px;
        final dy = p.$2 - py;
        if (dx * dx + dy * dy < 9) return true;
      }
      return false;
    }

    for (int p = 0; p < nParticles; p++) {
      // Start particle from a circle around the cluster
      final radius2 = 15.0 + p * 0.8;
      final startAngle = rng.nextDouble() * 2 * math.pi;
      double px = radius2 * math.cos(startAngle);
      double py = radius2 * math.sin(startAngle);

      for (int step = 0; step < 300; step++) {
        px += (rng.nextDouble() - 0.5) * 2.5;
        py += (rng.nextDouble() - 0.5) * 2.5;
        if (isNearCluster(px, py) && rng.nextDouble() < stickProb) {
          cluster.add((px, py));
          break;
        }
        // Boundary check: restart if too far
        if (px * px + py * py > (radius2 + 20) * (radius2 + 20)) { break; }
      }
    }

    // Find scale
    double maxR = 1.0;
    for (final p in cluster) {
      final r = math.sqrt(p.$1 * p.$1 + p.$2 * p.$2);
      if (r > maxR) { maxR = r; }
    }
    final scale = math.min(w * 0.44, dlaH * 0.44) / maxR.clamp(1.0, 1e9);

    // Draw cluster particles color-coded by attachment order
    for (int i = 0; i < cluster.length; i++) {
      final p = cluster[i];
      final t = i / cluster.length.clamp(1, 1000000);
      // Early particles bright (seed=white), later=dimmer cyan/teal
      final alpha = (0.9 - t * 0.4).clamp(0.3, 1.0);
      final green = (180 + (1 - t) * 75).toInt().clamp(0, 255);
      final col = Color.fromARGB((alpha * 255).toInt(), 0, green, (200 + t * 55).toInt().clamp(0, 255));
      final ptR = i == 0 ? 3.5 : (1.2 + (1 - t) * 0.8);
      canvas.drawCircle(Offset(cx + p.$1 * scale, cy + p.$2 * scale), ptR, Paint()..color = col);
    }

    // Seed highlight
    canvas.drawCircle(Offset(cx, cy), 4,
        Paint()..color = const Color(0xFFFFD700));

    // Title
    _text(canvas, '확산 제한 응집 (DLA)', Offset(w / 2 - 52, 4),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold));

    // ── Bottom: log-log graph R vs N ─────────────────────────
    final graphY = dlaH + 8;
    final graphH = h - graphY - 14;
    final padL = 32.0, padR = 8.0;
    final graphW = w - padL - padR;

    _text(canvas, 'log(R) vs log(N)  Df≈1.71', Offset(padL, graphY - 2),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8, fontWeight: FontWeight.bold));

    canvas.drawLine(Offset(padL, graphY + graphH), Offset(padL + graphW, graphY + graphH),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 0.8);
    canvas.drawLine(Offset(padL, graphY), Offset(padL, graphY + graphH),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 0.8);

    // Plot theoretical D=1.71 line and actual radius data
    final logPath = Path();
    bool firstLog = true;
    const df = 1.71;
    for (int i = 1; i <= 10; i++) {
      final logN = math.log(cluster.length * i / 10.0 + 1);
      final logR = logN / df;
      final gx = padL + (logN / 6) * graphW;
      final gy = graphY + graphH - (logR / 4) * graphH;
      if (firstLog) { logPath.moveTo(gx, gy.clamp(graphY, graphY + graphH)); firstLog = false; }
      else { logPath.lineTo(gx, gy.clamp(graphY, graphY + graphH)); }
    }
    canvas.drawPath(logPath, Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke..strokeWidth = 1.5);

    _text(canvas, '입자: ${cluster.length}  부착확률: ${(stickProb * 100).toInt()}%',
        Offset(padL, h - 12),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _DiffusionLimitedScreenPainter oldDelegate) => true;
}
