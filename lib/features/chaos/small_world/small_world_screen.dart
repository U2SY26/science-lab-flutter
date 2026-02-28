import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class SmallWorldScreen extends StatefulWidget {
  const SmallWorldScreen({super.key});
  @override
  State<SmallWorldScreen> createState() => _SmallWorldScreenState();
}

class _SmallWorldScreenState extends State<SmallWorldScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _rewireProb = 0.1;
  
  double _avgPath = 5.0, _clustering = 0.5;

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
      _avgPath = 10 * (1 - _rewireProb) + 2;
      _clustering = 0.75 * math.pow(1 - _rewireProb, 3).toDouble();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _rewireProb = 0.1;
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
          const Text('좁은 세상 네트워크', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스 시뮬레이션',
          title: '좁은 세상 네트워크',
          formula: 'L ~ ln(N)/ln(k)',
          formulaDescription: '와츠-스트로가츠 좁은 세상 네트워크를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SmallWorldScreenPainter(
                time: _time,
                rewireProb: _rewireProb,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '재연결 확률 (p)',
                value: _rewireProb,
                min: 0,
                max: 1,
                step: 0.01,
                defaultValue: 0.1,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _rewireProb = v),
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
          _V('평균 경로', _avgPath.toStringAsFixed(1)),
          _V('군집계수', _clustering.toStringAsFixed(3)),
          _V('p', _rewireProb.toStringAsFixed(2)),
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

class _SmallWorldScreenPainter extends CustomPainter {
  final double time;
  final double rewireProb;

  _SmallWorldScreenPainter({
    required this.time,
    required this.rewireProb,
  });

  static const int _n = 20;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final ringR = math.min(size.width, size.height) * 0.38;

    // Node positions on ring
    final nodePos = List.generate(_n, (i) {
      final a = i * math.pi * 2 / _n - math.pi / 2;
      return Offset(cx + ringR * math.cos(a), cy + ringR * math.sin(a));
    });

    // Determine how many shortcuts exist based on rewireProb
    // Each of the _n local edges has rewireProb chance of being a shortcut
    final numShortcuts = (rewireProb * _n * 1.5).round().clamp(0, _n);

    // Deterministic shortcut pairs (seeded, same every frame)
    final rng = math.Random(77);
    final shortcuts = <List<int>>[];
    final used = <int>{};
    int attempts = 0;
    while (shortcuts.length < numShortcuts && attempts < 200) {
      attempts++;
      final a = rng.nextInt(_n);
      final b = rng.nextInt(_n);
      if (a == b || (b - a).abs() <= 2 || used.contains(a * 100 + b)) { continue; }
      used.add(a * 100 + b);
      shortcuts.add([a, b]);
    }

    // Draw local ring edges (cyan, short)
    final localPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < _n; i++) {
      canvas.drawLine(nodePos[i], nodePos[(i + 1) % _n], localPaint);
      canvas.drawLine(nodePos[i], nodePos[(i + 2) % _n],
          localPaint..color = AppColors.accent.withValues(alpha: 0.18));
    }

    // Draw shortcut edges (orange, curved through center)
    final shortcutPaint = Paint()
      ..color = AppColors.accent2.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final sc in shortcuts) {
      final p1 = nodePos[sc[0]], p2 = nodePos[sc[1]];
      // Cubic bezier curving through center
      final ctrl1 = Offset(cx + (p1.dx - cx) * 0.25, cy + (p1.dy - cy) * 0.25);
      final ctrl2 = Offset(cx + (p2.dx - cx) * 0.25, cy + (p2.dy - cy) * 0.25);
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p2.dx, p2.dy);
      canvas.drawPath(path, shortcutPaint);
    }

    // Highlight shortest path between node 0 and node _n~/2
    final highlightA = 0, highlightB = _n ~/ 2;
    // Draw highlighted nodes
    canvas.drawCircle(nodePos[highlightA], 8,
        Paint()..color = AppColors.accent.withValues(alpha: 0.3));
    canvas.drawCircle(nodePos[highlightB], 8,
        Paint()..color = AppColors.accent2.withValues(alpha: 0.3));

    // Draw all nodes
    for (int i = 0; i < _n; i++) {
      final isHighlighted = i == highlightA || i == highlightB;
      final col = isHighlighted ? AppColors.accent : AppColors.muted.withValues(alpha: 0.8);
      final r = isHighlighted ? 5.5 : 4.0;
      canvas.drawCircle(nodePos[i], r, Paint()..color = col);
      canvas.drawCircle(nodePos[i], r,
          Paint()..color = AppColors.ink.withValues(alpha: 0.25)..strokeWidth = 0.8..style = PaintingStyle.stroke);
    }

    // Animated "six degrees" label when rewireProb is high enough
    final avgPath = 10 * (1 - rewireProb) + 2;
    if (avgPath < 6.5) {
      final pulse = 0.7 + 0.3 * math.sin(time * 2.5);
      final tp = TextPainter(
        text: TextSpan(
          text: '6단계 분리!',
          style: TextStyle(
            color: AppColors.accent.withValues(alpha: pulse),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - 12));
    }

    // Shortcuts count label
    final tp2 = TextPainter(
      text: TextSpan(
        text: 'p=${rewireProb.toStringAsFixed(2)}  단축 $numShortcuts개  L=${avgPath.toStringAsFixed(1)}',
        style: const TextStyle(color: Color(0xFF5A8A9A), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(6, size.height - 18));
  }

  @override
  bool shouldRepaint(covariant _SmallWorldScreenPainter oldDelegate) => true;
}
