import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class SierpinskiCarpetScreen extends StatefulWidget {
  const SierpinskiCarpetScreen({super.key});
  @override
  State<SierpinskiCarpetScreen> createState() => _SierpinskiCarpetScreenState();
}

class _SierpinskiCarpetScreenState extends State<SierpinskiCarpetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _iterations = 3;
  
  int _holes = 0; double _dimension = 1.893;

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
      final n = _iterations.toInt();
      _holes = (math.pow(8, n).toInt() - math.pow(8, n - 1 < 0 ? 0 : n - 1).toInt());
      _dimension = 1.893;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _iterations = 3.0;
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
          const Text('시어핀스키 카펫', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스 시뮬레이션',
          title: '시어핀스키 카펫',
          formula: 'D = ln(8)/ln(3) ≈ 1.893',
          formulaDescription: '시어핀스키 카펫 프랙탈을 생성합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SierpinskiCarpetScreenPainter(
                time: _time,
                iterations: _iterations,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '반복 횟수',
                value: _iterations,
                min: 0,
                max: 6,
                step: 1,
                defaultValue: 3,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _iterations = v),
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
          _V('구멍', '$_holes'),
          _V('차원', _dimension.toStringAsFixed(3)),
          _V('반복', _iterations.toInt().toString()),
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

class _SierpinskiCarpetScreenPainter extends CustomPainter {
  final double time;
  final double iterations;

  _SierpinskiCarpetScreenPainter({
    required this.time,
    required this.iterations,
  });

  void _drawCarpet(Canvas canvas, double x, double y, double w, double h, int depth, double glowPhase) {
    if (depth == 0) {
      // Filled cell: draw with cyan + slight glow
      final alpha = (0.7 + 0.3 * math.sin(glowPhase)).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(x, y, w, h),
        Paint()..color = AppColors.accent.withValues(alpha: alpha),
      );
      return;
    }
    final sw = w / 3;
    final sh = h / 3;
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        if (row == 1 && col == 1) continue; // center hole
        _drawCarpet(canvas, x + col * sw, y + row * sh, sw, sh, depth - 1, glowPhase + row * 0.3 + col * 0.2);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 1 || size.height < 1) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Animated level: reveal 0 → iterations progressively
    final maxDepth = iterations.toInt().clamp(0, 5);
    final animCycle = time * 0.4;
    final currentDepth = ((animCycle % (maxDepth + 2)).toInt()).clamp(0, maxDepth);

    const double topPad = 24.0;
    const double botPad = 36.0;
    final side = math.min(size.width, size.height - topPad - botPad) * 0.92;
    final ox = (size.width - side) / 2;
    final oy = topPad + (size.height - topPad - botPad - side) / 2;

    // Draw outer border
    canvas.drawRect(
      Rect.fromLTWH(ox, oy, side, side),
      Paint()..color = AppColors.simGrid..style = PaintingStyle.stroke..strokeWidth = 0.8,
    );

    // Draw carpet
    if (currentDepth > 0) {
      _drawCarpet(canvas, ox, oy, side, side, currentDepth, time * 1.5);
    } else {
      // Depth 0: fully filled square
      canvas.drawRect(
        Rect.fromLTWH(ox, oy, side, side),
        Paint()..color = AppColors.accent.withValues(alpha: 0.8),
      );
    }

    // Glow effect on boundary (outer rect outline)
    final glowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.25 + 0.1 * math.sin(time * 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRect(Rect.fromLTWH(ox, oy, side, side), glowPaint);

    // Label: fractal dimension
    final labelText = 'D = ln(8)/ln(3) ≈ 1.893   레벨: $currentDepth/$maxDepth';
    final tp = TextPainter(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 16);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height - botPad + 8));
  }

  @override
  bool shouldRepaint(covariant _SierpinskiCarpetScreenPainter oldDelegate) => true;
}
