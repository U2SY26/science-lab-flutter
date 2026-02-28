import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DiffusionModelScreen extends StatefulWidget {
  const DiffusionModelScreen({super.key});
  @override
  State<DiffusionModelScreen> createState() => _DiffusionModelScreenState();
}

class _DiffusionModelScreenState extends State<DiffusionModelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _timestep = 500;
  
  double _noiseLevel = 0.5, _snr = 1.0;

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
      _noiseLevel = _timestep / 1000;
      _snr = (1 - _noiseLevel) / (_noiseLevel + 0.001);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _timestep = 500.0;
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
          const Text('확산 모델', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '확산 모델',
          formula: 'q(x_t|x_{t-1}) = N(x_t; √(1-β)x_{t-1}, βI)',
          formulaDescription: '확산 모델의 노이즈 추가/제거 과정을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DiffusionModelScreenPainter(
                time: _time,
                timestep: _timestep,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '시간 스텝 (t)',
                value: _timestep,
                min: 0,
                max: 1000,
                step: 10,
                defaultValue: 500,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _timestep = v),
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
          _V('노이즈', (_noiseLevel * 100).toStringAsFixed(1) + '%'),
          _V('SNR', _snr.toStringAsFixed(2)),
          _V('t', _timestep.toInt().toString()),
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

class _DiffusionModelScreenPainter extends CustomPainter {
  final double time;
  final double timestep;

  _DiffusionModelScreenPainter({
    required this.time,
    required this.timestep,
  });

  // Stable noise seeds per patch pixel
  static final _rng = math.Random(99);
  static final List<List<Offset>> _noiseSeeds = List.generate(
    6,
    (p) => List.generate(
      120,
      (_) => Offset(
        _rng.nextDouble(),
        _rng.nextDouble(),
      ),
    ),
  );
  static final List<List<double>> _noiseColors = List.generate(
    6,
    (p) => List.generate(120, (_) => _rng.nextDouble()),
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // noiseLevel 0=clean, 1=pure noise  (driven by timestep 0..1000)
    final noiseLevel = (timestep / 1000.0).clamp(0.0, 1.0);

    // Layout: 6 patches in 2 rows × 3 cols, bottom strip for noise schedule
    const cols = 3, rows = 2, patches = 6;
    const schedH = 52.0;
    const pad = 10.0;
    final patchW = (size.width - pad * (cols + 1)) / cols;
    final patchH = (size.height - schedH - pad * (rows + 1)) / rows;

    for (int p = 0; p < patches; p++) {
      final col = p % cols;
      final row = p ~/ cols;
      final left = pad + col * (patchW + pad);
      final top = pad + row * (patchH + pad);
      final rect = Rect.fromLTWH(left, top, patchW, patchH);

      // Each patch represents a different timestep: T → 0
      // patch 0 = noisiest (t=T), patch 5 = cleanest (t=0)
      final patchNoise = (noiseLevel * (1.0 - p / (patches - 1))).clamp(0.0, 1.0);
      _drawPatch(canvas, rect, p, patchNoise, (patches - 1 - p) * 1000 ~/ (patches - 1));
    }

    // Noise schedule curve
    _drawNoiseSchedule(canvas, size, size.height - schedH, schedH, noiseLevel);
  }

  void _drawPatch(Canvas canvas, Rect rect, int patchIdx, double noiseLevel, int tLabel) {
    // Clip to patch
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)));

    // Background
    canvas.drawRect(rect, Paint()..color = AppColors.simGrid.withValues(alpha: 0.5));

    final cleanAmt = 1.0 - noiseLevel;

    // ---- Clean signal: sine wave pattern (cyan) ----
    if (cleanAmt > 0.02) {
      final wavePaint = Paint()
        ..color = AppColors.accent.withValues(alpha: cleanAmt * 0.85)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final path = Path();
      const pts = 40;
      for (int i = 0; i <= pts; i++) {
        final t = i / pts;
        final x = rect.left + t * rect.width;
        final y = rect.top + rect.height / 2 +
            math.sin(t * math.pi * 3 + time * 0.5) * rect.height * 0.28 * cleanAmt;
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, wavePaint);

      // Subtle glow fill under wave
      final fillPath = Path();
      for (int i = 0; i <= pts; i++) {
        final t = i / pts;
        final x = rect.left + t * rect.width;
        final y = rect.top + rect.height / 2 +
            math.sin(t * math.pi * 3 + time * 0.5) * rect.height * 0.28 * cleanAmt;
        i == 0 ? fillPath.moveTo(x, y) : fillPath.lineTo(x, y);
      }
      fillPath.lineTo(rect.right, rect.top + rect.height / 2);
      fillPath.lineTo(rect.left, rect.top + rect.height / 2);
      fillPath.close();
      canvas.drawPath(
        fillPath,
        Paint()..color = AppColors.accent.withValues(alpha: cleanAmt * 0.08),
      );
    }

    // ---- Noise: random colored specks ----
    if (noiseLevel > 0.02) {
      final seeds = _noiseSeeds[patchIdx];
      final colors = _noiseColors[patchIdx];
      final count = (120 * noiseLevel).toInt();
      for (int i = 0; i < count; i++) {
        final sx = rect.left + seeds[i].dx * rect.width;
        final sy = rect.top + seeds[i].dy * rect.height;
        final nc = colors[i];
        final speckColor = nc < 0.33
            ? AppColors.accent.withValues(alpha: noiseLevel * 0.7)
            : nc < 0.66
                ? AppColors.accent2.withValues(alpha: noiseLevel * 0.6)
                : Colors.white.withValues(alpha: noiseLevel * 0.5);
        canvas.drawCircle(Offset(sx, sy), 1.2, Paint()..color = speckColor);
      }
    }

    canvas.restore();

    // Patch border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.15 + cleanAmt * 0.25)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Timestep label inside top-left
    _drawText(canvas, 't=$tLabel',
        Offset(rect.left + 4, rect.top + 3), 8,
        AppColors.muted.withValues(alpha: 0.7));
  }

  void _drawNoiseSchedule(Canvas canvas, Size size, double top, double h, double noiseLevel) {
    const pad = 10.0;
    final left = pad, right = size.width - pad;
    final w = right - left;
    final graphTop = top + 14;
    final graphH = h - 20;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h - 4), const Radius.circular(5)),
      Paint()..color = AppColors.simGrid.withValues(alpha: 0.35),
    );

    // Axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.4)
      ..strokeWidth = 0.6;
    canvas.drawLine(Offset(left + 14, graphTop), Offset(right - 4, graphTop + graphH), axisPaint);
    canvas.drawLine(Offset(left + 14, graphTop), Offset(left + 14, graphTop + graphH), axisPaint);

    // Exponential noise schedule: β(t) = 1 - exp(-4t)
    final curvePaint = Paint()
      ..color = AppColors.accent2.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    const steps = 80;
    for (int i = 0; i <= steps; i++) {
      final tNorm = i / steps;
      final noiseVal = 1.0 - math.exp(-4.0 * tNorm);
      final x = left + 14 + tNorm * (w - 18);
      final y = graphTop + graphH - noiseVal * graphH;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, curvePaint);

    // Current timestep indicator (vertical line)
    final curX = left + 14 + noiseLevel * (w - 18);
    canvas.drawLine(
      Offset(curX, graphTop),
      Offset(curX, graphTop + graphH),
      Paint()..color = AppColors.accent.withValues(alpha: 0.6)..strokeWidth = 1.0,
    );
    // Dot on curve
    final curY = graphTop + graphH - (1.0 - math.exp(-4.0 * noiseLevel)) * graphH;
    canvas.drawCircle(Offset(curX, curY), 3.5, Paint()..color = AppColors.accent);
    canvas.drawCircle(Offset(curX, curY), 6.5, Paint()..color = AppColors.accent.withValues(alpha: 0.22));

    _drawText(canvas, 'Noise Schedule  t →', Offset(left + 16, top + 2), 8,
        AppColors.muted.withValues(alpha: 0.7));
    _drawText(canvas, 'T=0', Offset(left + 16, graphTop + graphH - 9), 7,
        AppColors.accent.withValues(alpha: 0.55));
    _drawText(canvas, 'T=1000', Offset(right - 28, graphTop + 2), 7,
        AppColors.accent2.withValues(alpha: 0.55));
  }

  void _drawText(Canvas canvas, String text, Offset pos, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _DiffusionModelScreenPainter oldDelegate) => true;
}
