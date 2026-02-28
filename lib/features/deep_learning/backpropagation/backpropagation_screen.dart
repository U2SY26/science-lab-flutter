import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BackpropagationScreen extends StatefulWidget {
  const BackpropagationScreen({super.key});
  @override
  State<BackpropagationScreen> createState() => _BackpropagationScreenState();
}

class _BackpropagationScreenState extends State<BackpropagationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _layers = 3;
  
  double _gradMag = 1.0, _vanishing = 0.0;

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
      _gradMag = math.pow(0.9, _layers).toDouble();
      _vanishing = 1.0 - _gradMag;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _layers = 3.0;
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
          const Text('역전파', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '역전파',
          formula: '∂L/∂w = ∂L/∂y · ∂y/∂w',
          formulaDescription: '신경망의 역전파 알고리즘을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BackpropagationScreenPainter(
                time: _time,
                layers: _layers,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '레이어 수',
                value: _layers,
                min: 1,
                max: 8,
                step: 1,
                defaultValue: 3,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _layers = v),
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
          _V('기울기 크기', _gradMag.toStringAsFixed(4)),
          _V('소실률', (_vanishing * 100).toStringAsFixed(1) + '%'),
          _V('레이어', _layers.toInt().toString()),
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

class _BackpropagationScreenPainter extends CustomPainter {
  final double time;
  final double layers;

  _BackpropagationScreenPainter({
    required this.time,
    required this.layers,
  });

  static const _cyan = AppColors.accent;
  static const _orange = AppColors.accent2;
  static const _muted = AppColors.muted;

  // Network architecture: Input(3) -> Hidden1(4) -> Hidden2(4) -> Output(2)
  static const List<int> _arch = [3, 4, 4, 2];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final numLayers = math.min(layers.toInt() + 1, 4);
    final usedArch = _arch.sublist(0, numLayers);

    // Layout: leave 55px bottom for loss graph
    final graphH = 55.0;
    final netH = size.height - graphH - 8;
    final layerW = size.width / (usedArch.length + 1);
    final layerXs = List.generate(usedArch.length, (i) => layerW * (i + 1));

    // Gradient magnitude per layer (vanishing gradient effect)
    final gradMags = List.generate(usedArch.length, (i) {
      return math.pow(0.82, (usedArch.length - 1 - i)).toDouble();
    });

    // Precompute node positions
    final nodePos = <List<Offset>>[];
    for (int l = 0; l < usedArch.length; l++) {
      final n = usedArch[l];
      final spacing = netH / (n + 1);
      nodePos.add(List.generate(n, (i) => Offset(layerXs[l], spacing * (i + 1) + 4)));
    }

    // Draw connections with gradient coloring + animated backprop particles
    for (int l = 0; l < usedArch.length - 1; l++) {
      final fromNodes = nodePos[l];
      final toNodes = nodePos[l + 1];
      final gMag = gradMags[l];

      // Color: hot=large gradient (orange), cool=small (cyan/muted)
      final t = gMag.clamp(0.0, 1.0);
      final connColor = Color.lerp(
        _muted.withValues(alpha: 0.25),
        _orange.withValues(alpha: 0.55),
        t,
      )!;

      final connPaint = Paint()
        ..color = connColor
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;

      for (final from in fromNodes) {
        for (final to in toNodes) {
          canvas.drawLine(from, to, connPaint);

          // Backprop particle: travels right→left (to→from)
          final phase = (time * 1.2 + from.dy * 0.05 + to.dy * 0.03) % 1.0;
          // Reverse direction for backprop
          final px = to.dx + (from.dx - to.dx) * phase;
          final py = to.dy + (from.dy - to.dy) * phase;
          final pColor = Color.lerp(_cyan, _orange, t)!;

          // Glow particle
          for (final r in [5.0, 3.0, 1.5]) {
            canvas.drawCircle(
              Offset(px, py),
              r,
              Paint()..color = pColor.withValues(alpha: r == 1.5 ? 0.9 : 0.15),
            );
          }
        }
      }
    }

    // Draw nodes with glow + activation fill
    for (int l = 0; l < usedArch.length; l++) {
      final gMag = gradMags[l];

      for (int n = 0; n < nodePos[l].length; n++) {
        final pos = nodePos[l][n];
        final nodeAct = (math.sin(time * 2.1 + n * 1.3 + l * 0.9) + 1) / 2;

        // Outer glow rings
        for (final r in [18.0, 12.0, 8.0]) {
          canvas.drawCircle(
            pos, r,
            Paint()..color = _cyan.withValues(alpha: (18 - r) / 18 * 0.12 * gMag),
          );
        }

        // Fill: activation level
        canvas.drawCircle(
          pos, 7,
          Paint()
            ..color = _cyan.withValues(alpha: 0.1 + nodeAct * 0.35)
            ..style = PaintingStyle.fill,
        );

        // Stroke
        canvas.drawCircle(
          pos, 7,
          Paint()
            ..color = _cyan.withValues(alpha: 0.4 + gMag * 0.5)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
      }

      // Layer label
      final labels = ['Input', 'H1', 'H2', 'Output'];
      _drawText(canvas, l < labels.length ? labels[l] : 'H$l',
          Offset(layerXs[l], netH + 2), 9,
          _muted.withValues(alpha: 0.8));
    }

    // Loss curve at bottom
    _drawLossCurve(canvas, size, netH + 14, graphH - 14);
  }

  void _drawLossCurve(Canvas canvas, Size size, double top, double h) {
    final left = 16.0, right = size.width - 16;
    final w = right - left;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), const Radius.circular(4)),
      Paint()..color = AppColors.simGrid.withValues(alpha: 0.4),
    );

    // Axes
    final axisPaint = Paint()..color = _muted.withValues(alpha: 0.4)..strokeWidth = 0.5;
    canvas.drawLine(Offset(left + 2, top + 2), Offset(left + 2, top + h - 2), axisPaint);
    canvas.drawLine(Offset(left + 2, top + h - 2), Offset(right - 2, top + h - 2), axisPaint);

    // Loss curve: exponential decay driven by time
    final curvePaint = Paint()
      ..color = _orange.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    const steps = 60;
    for (int i = 0; i <= steps; i++) {
      final tNorm = i / steps;
      // Simulated loss: decays with time, oscillates slightly
      final tAgo = tNorm * math.min(time, 8.0);
      final loss = math.exp(-tAgo * 0.4) * (0.85 + 0.1 * math.sin(tAgo * 3.1));
      final x = left + 4 + tNorm * (w - 6);
      final y = top + (h - 4) * (1 - loss.clamp(0.0, 1.0));
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, curvePaint);

    // Current loss dot
    final curLoss = math.exp(-math.min(time, 8.0) * 0.4) *
        (0.85 + 0.1 * math.sin(math.min(time, 8.0) * 3.1));
    final dotX = right - 6;
    final dotY = top + (h - 4) * (1 - curLoss.clamp(0.0, 1.0));
    canvas.drawCircle(Offset(dotX, dotY), 3,
        Paint()..color = _orange);
    canvas.drawCircle(Offset(dotX, dotY), 6,
        Paint()..color = _orange.withValues(alpha: 0.25));

    _drawText(canvas, 'Loss', Offset(left + 5, top + 2), 8, _orange.withValues(alpha: 0.7));
  }

  void _drawText(Canvas canvas, String text, Offset pos, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _BackpropagationScreenPainter oldDelegate) => true;
}
