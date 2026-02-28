import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class AsteroidBeltScreen extends StatefulWidget {
  const AsteroidBeltScreen({super.key});
  @override
  State<AsteroidBeltScreen> createState() => _AsteroidBeltScreenState();
}

class _AsteroidBeltScreenState extends State<AsteroidBeltScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _resonanceRatio = 3;
  double _asteroidCount = 200;
  double _gapDistance = 0;

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
      _gapDistance = 5.2 / math.pow(_resonanceRatio, 2.0 / 3);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _resonanceRatio = 3; _asteroidCount = 200;
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
          Text('천문학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('소행성대와 커크우드 간극', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '소행성대와 커크우드 간극',
          formula: 'P/P_J = p/q (공명)',
          formulaDescription: '소행성대와 공명 간극을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _AsteroidBeltScreenPainter(
                time: _time,
                resonanceRatio: _resonanceRatio,
                asteroidCount: _asteroidCount,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '공명 비 (p:q)',
                value: _resonanceRatio,
                min: 2,
                max: 5,
                step: 1,
                defaultValue: 3,
                formatValue: (v) => '${v.toStringAsFixed(0)}:1',
                onChanged: (v) => setState(() => _resonanceRatio = v),
              ),
              advancedControls: [
            SimSlider(
                label: '소행성 수',
                value: _asteroidCount,
                min: 50,
                max: 500,
                step: 50,
                defaultValue: 200,
                formatValue: (v) => v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _asteroidCount = v),
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
          _V('간극 거리', '${_gapDistance.toStringAsFixed(2)} AU'),
          _V('공명', '${_resonanceRatio.toStringAsFixed(0)}:1'),
          _V('소행성', _asteroidCount.toStringAsFixed(0)),
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

class _AsteroidBeltScreenPainter extends CustomPainter {
  final double time;
  final double resonanceRatio;
  final double asteroidCount;

  _AsteroidBeltScreenPainter({
    required this.time,
    required this.resonanceRatio,
    required this.asteroidCount,
  });

  void _label(Canvas canvas, String text, Offset pos, {double fs = 8, Color col = const Color(0xFF5A8A9A), bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? pos.dx - tp.width / 2 : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // === Top panel: Solar system top-view ===
    final topH = h * 0.60;
    final cx = w / 2;
    final cy = topH / 2;

    // Scale: Jupiter at 5.2 AU. We map AU to pixels.
    // Panel width ~ w, Jupiter at 90% from center at edge
    final auScale = (w * 0.44) / 5.2;

    // Background stars
    final rng = math.Random(42);
    for (int i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * topH),
        rng.nextDouble() * 1.0 + 0.2,
        Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: rng.nextDouble() * 0.3 + 0.1),
      );
    }

    // Sun
    canvas.drawCircle(Offset(cx, cy), 8,
        Paint()..color = const Color(0xFFFFDD44)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = const Color(0xFFFFDD44));

    // Inner planets (Mercury 0.39, Venus 0.72, Earth 1.0, Mars 1.52)
    final planets = [
      (0.39, 3.0, const Color(0xFF888888), 'Mercury'),
      (0.72, 4.0, const Color(0xFFFFAA44), 'Venus'),
      (1.00, 4.5, const Color(0xFF44AAFF), 'Earth'),
      (1.52, 3.5, const Color(0xFFFF6644), 'Mars'),
    ];
    for (final planet in planets) {
      final r = planet.$1 * auScale;
      // Orbit circle
      canvas.drawCircle(Offset(cx, cy), r,
          Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.stroke..strokeWidth = 0.5);
      // Planet position
      final angle = time * 0.3 / planet.$1 + rng.nextDouble() * math.pi * 2;
      final px = cx + r * math.cos(angle);
      final py = cy + r * math.sin(angle);
      canvas.drawCircle(Offset(px, py), planet.$2, Paint()..color = planet.$3);
    }

    // Jupiter
    final jupR = 5.2 * auScale;
    canvas.drawCircle(Offset(cx, cy), jupR,
        Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.stroke..strokeWidth = 0.7);
    final jupAngle = time * 0.05;
    final jupX = cx + jupR * math.cos(jupAngle);
    final jupY = cy + jupR * math.sin(jupAngle);
    canvas.drawCircle(Offset(jupX, jupY), 9, Paint()..color = const Color(0xFFBB8833));
    canvas.drawCircle(Offset(jupX, jupY), 9,
        Paint()..color = const Color(0xFFFFBB55).withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _label(canvas, 'Jupiter', Offset(jupX + 10, jupY - 5), fs: 7, col: const Color(0xFFBB8833));

    // Asteroid belt: 2.2–3.2 AU, with Kirkwood gaps
    // Gaps at 3:1 (2.50), 5:2 (2.82), 7:3 (2.96), 2:1 (3.28) resonances with Jupiter
    final gapAUs = [2.50, 2.82, 2.96, 3.28]; // Kirkwood gaps in AU
    final gapWidth = 0.06; // AU

    final int nAsteroids = asteroidCount.toInt();
    final astRng = math.Random(7);
    for (int i = 0; i < nAsteroids; i++) {
      double au = 2.2 + astRng.nextDouble() * 1.0; // 2.2 to 3.2 AU
      // Remove asteroids near gaps
      bool inGap = false;
      for (final gap in gapAUs) {
        if ((au - gap).abs() < gapWidth) {
          inGap = true;
          break;
        }
      }
      if (inGap) continue;

      final r = au * auScale;
      // Random angle with slow drift based on orbital period
      final baseAngle = astRng.nextDouble() * math.pi * 2;
      final angularSpeed = time * 0.15 / au;
      final a = baseAngle + angularSpeed;
      final ax = cx + r * math.cos(a);
      final ay = cy + r * math.sin(a);
      canvas.drawCircle(Offset(ax, ay), 1.0,
          Paint()..color = const Color(0xFF8899AA).withValues(alpha: 0.7));
    }

    // Ceres marker
    final ceresAu = 2.77;
    final ceresR = ceresAu * auScale;
    final ceresAngle = time * 0.12 + 1.2;
    final ceresX = cx + ceresR * math.cos(ceresAngle);
    final ceresY = cy + ceresR * math.sin(ceresAngle);
    canvas.drawCircle(Offset(ceresX, ceresY), 3.5,
        Paint()..color = const Color(0xFF00D4FF));
    _label(canvas, 'Ceres', Offset(ceresX + 4, ceresY - 8), fs: 7, col: const Color(0xFF00D4FF));

    _label(canvas, '소행성대 (2.2–3.2 AU)', Offset(cx, 6), fs: 8, col: const Color(0xFFE0F4FF), center: true);

    // === Bottom panel: histogram of asteroid distribution ===
    final histTop = topH + 10;
    final histH = h - histTop - 8;
    if (histH < 20) return;
    final histBot = histTop + histH;
    final histLeft = 40.0;
    final histRight = w - 8;
    final histW = histRight - histLeft;

    canvas.drawLine(Offset(histLeft, histTop), Offset(histLeft, histBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(histLeft, histBot), Offset(histRight, histBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _label(canvas, '수', Offset(2, histTop), fs: 7);
    _label(canvas, '반장축 (AU)', Offset(histLeft + histW / 2, histBot + 2), fs: 7, col: const Color(0xFF5A8A9A), center: true);

    // Bins from 2.0 to 3.4 AU
    const binMin = 2.0;
    const binMax = 3.4;
    const nBins = 28;
    final binW = histW / nBins;

    // Generate asteroid distribution (Gaussian-like with gaps)
    final histRng = math.Random(99);
    final bins = List.filled(nBins, 0);
    for (int i = 0; i < 500; i++) {
      double au = 2.2 + histRng.nextDouble() * 1.0;
      bool inGap = false;
      for (final gap in gapAUs) {
        if ((au - gap).abs() < gapWidth) {
          inGap = true;
          break;
        }
      }
      if (inGap) continue;
      final bin = ((au - binMin) / (binMax - binMin) * nBins).floor().clamp(0, nBins - 1);
      bins[bin]++;
    }
    final maxBin = bins.reduce(math.max);

    for (int b = 0; b < nBins; b++) {
      final au = binMin + (b + 0.5) / nBins * (binMax - binMin);
      final x = histLeft + b * binW;
      bool inGap = false;
      for (final gap in gapAUs) {
        if ((au - gap).abs() < gapWidth + 0.03) {
          inGap = true;
          break;
        }
      }
      final barH = maxBin > 0 ? (bins[b] / maxBin) * histH * 0.85 : 0.0;
      final barRect = Rect.fromLTWH(x + 1, histBot - barH, binW - 2, barH);
      canvas.drawRect(barRect,
          Paint()..color = (inGap ? const Color(0xFF1A3040) : const Color(0xFF8899AA)).withValues(alpha: 0.8));
    }

    // Gap markers on histogram
    for (final gap in gapAUs) {
      final gx = histLeft + (gap - binMin) / (binMax - binMin) * histW;
      canvas.drawLine(Offset(gx, histTop), Offset(gx, histBot),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)..strokeWidth = 1..style = PaintingStyle.stroke);
    }
    // Resonance labels
    final resonanceLabels = ['3:1', '5:2', '7:3', '2:1'];
    for (int i = 0; i < gapAUs.length; i++) {
      final gx = histLeft + (gapAUs[i] - binMin) / (binMax - binMin) * histW;
      _label(canvas, resonanceLabels[i], Offset(gx - 5, histTop - 2), fs: 6, col: const Color(0xFFFF6B35));
    }
    // 2.0 AU and 3.4 AU labels
    _label(canvas, '2.0', Offset(histLeft - 4, histBot + 2), fs: 6);
    _label(canvas, '3.4', Offset(histRight - 8, histBot + 2), fs: 6);
    _label(canvas, '커크우드 간극', Offset(histLeft + histW * 0.6, histTop - 2), fs: 7, col: const Color(0xFFFF6B35));
  }

  @override
  bool shouldRepaint(covariant _AsteroidBeltScreenPainter oldDelegate) => true;
}
