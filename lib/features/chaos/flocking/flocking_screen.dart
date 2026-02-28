import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class FlockingScreen extends StatefulWidget {
  const FlockingScreen({super.key});
  @override
  State<FlockingScreen> createState() => _FlockingScreenState();
}

class _FlockingScreenState extends State<FlockingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _separation = 1.5;
  double _alignment = 1;
  double _cohesion = 1.0, _avgSpeed = 2.0;

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
      _avgSpeed = 2.0 + _alignment - _separation * 0.3;
      _cohesion = 1.0;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _separation = 1.5; _alignment = 1.0;
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
          const Text('보이드 떼지어 행동', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스 시뮬레이션',
          title: '보이드 떼지어 행동',
          formula: 'Alignment + Cohesion + Separation',
          formulaDescription: '보이드 알고리즘의 떼지어 행동을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _FlockingScreenPainter(
                time: _time,
                separation: _separation,
                alignment: _alignment,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '분리 가중치',
                value: _separation,
                min: 0,
                max: 5,
                step: 0.1,
                defaultValue: 1.5,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _separation = v),
              ),
              advancedControls: [
            SimSlider(
                label: '정렬 가중치',
                value: _alignment,
                min: 0,
                max: 5,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _alignment = v),
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
          _V('분리', _separation.toStringAsFixed(1)),
          _V('정렬', _alignment.toStringAsFixed(1)),
          _V('속도', _avgSpeed.toStringAsFixed(1)),
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

class _FlockingScreenPainter extends CustomPainter {
  final double time;
  final double separation;
  final double alignment;

  _FlockingScreenPainter({
    required this.time,
    required this.separation,
    required this.alignment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final rng = math.Random(42);
    const int numBoids = 80;
    const double speed = 28.0;

    // Generate deterministic boid state from time
    final List<Offset> positions = [];
    final List<double> angles = [];
    for (int i = 0; i < numBoids; i++) {
      final seed = i * 137.508;
      final baseAngle = seed % (math.pi * 2);
      // Each boid orbits a flock center with phase offset
      final flockX = size.width * (0.2 + 0.6 * (rng.nextDouble()));
      final flockY = size.height * (0.2 + 0.6 * (rng.nextDouble()));
      final orbitR = 20.0 + 60.0 * rng.nextDouble();
      final phase = time * (0.4 + alignment * 0.2) + seed;
      final px = flockX + orbitR * math.cos(phase + baseAngle);
      final py = flockY + orbitR * math.sin(phase + baseAngle) * 0.6;
      positions.add(Offset(
        px.clamp(4, size.width - 4),
        py.clamp(4, size.height - 4),
      ));
      angles.add((phase + math.pi / 2) % (math.pi * 2));
    }
    // Rebuild with fixed seeds so flock structure is stable
    final rng2 = math.Random(7);
    final List<Offset> pos2 = [];
    final List<double> ang2 = [];
    final List<int> flockId = [];
    const int numFlocks = 4;
    final flockCenters = List.generate(numFlocks, (f) => Offset(
      size.width * (0.15 + 0.7 * rng2.nextDouble()),
      size.height * (0.15 + 0.7 * rng2.nextDouble()),
    ));
    final rng3 = math.Random(42);
    for (int i = 0; i < numBoids; i++) {
      final fid = i % numFlocks;
      flockId.add(fid);
      final orbitR = 15.0 + 55.0 * rng3.nextDouble();
      final phaseOffset = rng3.nextDouble() * math.pi * 2;
      final angSpeed = 0.3 + alignment * 0.15 + rng3.nextDouble() * 0.2;
      final phase = time * angSpeed + phaseOffset;
      final fc = flockCenters[fid];
      // Separation: higher sep = larger spread
      final spreadFactor = 1.0 + separation * 0.3;
      final px = fc.dx + orbitR * spreadFactor * math.cos(phase);
      final py = fc.dy + orbitR * spreadFactor * 0.65 * math.sin(phase);
      pos2.add(Offset(
        px.clamp(4, size.width - 4),
        py.clamp(4, size.height - 4),
      ));
      ang2.add(phase + math.pi / 2);
    }

    // Flock colors by ID
    const flockColors = [
      Color(0xFF00D4FF), // cyan
      Color(0xFF64FF8C), // green
      Color(0xFFFF6B35), // orange
      Color(0xFFAA88FF), // purple
    ];

    // Draw velocity vectors (faint)
    final vecPaint = Paint()
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < numBoids; i++) {
      final p = pos2[i];
      final a = ang2[i];
      final col = flockColors[flockId[i]];
      vecPaint.color = col.withValues(alpha: 0.18);
      canvas.drawLine(p, Offset(p.dx + speed * 0.3 * math.cos(a), p.dy + speed * 0.3 * math.sin(a)), vecPaint);
    }

    // Draw boids as triangles
    for (int i = 0; i < numBoids; i++) {
      final p = pos2[i];
      final a = ang2[i];
      final col = flockColors[flockId[i]];
      _drawBoidTriangle(canvas, p, a, col);
    }

    // Labels
    final tp = TextPainter(
      text: TextSpan(
        text: 'sep=${separation.toStringAsFixed(1)}  align=${alignment.toStringAsFixed(1)}',
        style: const TextStyle(color: Color(0xFF5A8A9A), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(6, size.height - 18));
  }

  void _drawBoidTriangle(Canvas canvas, Offset pos, double angle, Color col) {
    const double len = 7.0;
    const double half = 3.5;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    // tip
    final tip = Offset(pos.dx + cosA * len, pos.dy + sinA * len);
    // left base
    final lx = pos.dx - cosA * half + sinA * half;
    final ly = pos.dy - sinA * half - cosA * half;
    // right base
    final rx = pos.dx - cosA * half - sinA * half;
    final ry = pos.dy - sinA * half + cosA * half;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(lx, ly)
      ..lineTo(rx, ry)
      ..close();
    canvas.drawPath(path, Paint()..color = col.withValues(alpha: 0.9));
    canvas.drawPath(path, Paint()..color = col..strokeWidth = 0.8..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _FlockingScreenPainter oldDelegate) => true;
}
