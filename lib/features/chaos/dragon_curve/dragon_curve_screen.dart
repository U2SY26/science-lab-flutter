import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DragonCurveScreen extends StatefulWidget {
  const DragonCurveScreen({super.key});
  @override
  State<DragonCurveScreen> createState() => _DragonCurveScreenState();
}

class _DragonCurveScreenState extends State<DragonCurveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _level = 10.0;
  int _segments = 0;

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
      _segments = math.pow(2, _level.toInt()).toInt();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _level = 10.0;
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
          const Text('드래곤 커브', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '혼돈 시뮬레이션',
          title: '드래곤 커브',
          formula: 'L-system: FX → X+YF+, Y → −FX−Y',
          formulaDescription: '재귀적 종이 접기로 드래곤 커브 프랙탈을 생성합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DragonCurveScreenPainter(
                time: _time,
                level: _level,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '반복 레벨',
                value: _level,
                min: 1.0,
                max: 17.0,
                defaultValue: 10.0,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => _level = v),
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
          _V('레벨', '${_level.toInt()}'),
          _V('선분 수', '${_segments}'),
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

class _DragonCurveScreenPainter extends CustomPainter {
  final double time;
  final double level;

  _DragonCurveScreenPainter({
    required this.time,
    required this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final n = level.toInt().clamp(1, 14);

    // Generate dragon curve using fold-sequence method
    // The turn sequence: for i=1..2^n, turn = ((i >> trailing_zeros(i)) >> 1) & 1 ? L : R
    // Use iterative bit method
    final turns = <bool>[]; // true = left (CCW +90), false = right (CW -90)
    for (int i = 1; i < math.pow(2, n); i++) {
      // bit rule: look at bit above lowest set bit
      int k = i;
      while (k & 1 == 0) { k >>= 1; }
      k >>= 1;
      turns.add((k & 1) == 0);
    }

    final numSeg = math.pow(2, n).toInt();
    // Estimate bounding box first
    double cx = 0, cy = 0;
    double ang = 0;
    double minX = 0, maxX = 0, minY = 0, maxY = 0;
    final stepSize = 1.0;
    for (int i = 0; i < numSeg; i++) {
      cx += stepSize * math.cos(ang);
      cy += stepSize * math.sin(ang);
      minX = math.min(minX, cx); maxX = math.max(maxX, cx);
      minY = math.min(minY, cy); maxY = math.max(maxY, cy);
      if (i < turns.length) {
        ang += turns[i] ? math.pi / 2 : -math.pi / 2;
      }
    }

    // Scale to fit canvas
    final rangeX = (maxX - minX).clamp(1.0, 1e9);
    final rangeY = (maxY - minY).clamp(1.0, 1e9);
    final margin = 24.0;
    final scl = math.min((w - margin * 2) / rangeX, (h - margin * 2 - 30) / rangeY);
    final offX = margin - minX * scl + (w - margin * 2 - rangeX * scl) / 2;
    final offY = margin + 20 - minY * scl + (h - margin * 2 - 20 - rangeY * scl) / 2;

    // Draw curve with color gradient
    cx = 0; cy = 0; ang = 0;
    Offset prev = Offset(cx * scl + offX, cy * scl + offY);

    for (int i = 0; i < numSeg; i++) {
      cx += stepSize * math.cos(ang);
      cy += stepSize * math.sin(ang);
      final next = Offset(cx * scl + offX, cy * scl + offY);

      // Color: gradient cyan → purple → orange by progress
      final t = i / numSeg;
      final Color col;
      if (t < 0.5) {
        col = Color.lerp(const Color(0xFF00D4FF), const Color(0xFF8B00FF), t * 2)!
            .withValues(alpha: 0.8);
      } else {
        col = Color.lerp(const Color(0xFF8B00FF), const Color(0xFFFF6B35), (t - 0.5) * 2)!
            .withValues(alpha: 0.8);
      }

      canvas.drawLine(prev, next,
          Paint()..color = col..strokeWidth = n > 11 ? 0.6 : (n > 8 ? 0.8 : 1.2)
            ..strokeCap = StrokeCap.round);
      prev = next;

      if (i < turns.length) {
        ang += turns[i] ? math.pi / 2 : -math.pi / 2;
      }
    }

    // Title and info
    _text(canvas, '드래곤 커브 L-시스템', Offset(w / 2 - 52, 4),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold));
    _text(canvas, '레벨 n=$n   선분 수: $numSeg   프랙탈 차원≈2',
        Offset(8, h - 14),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _DragonCurveScreenPainter oldDelegate) => true;
}
