import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BarnsleyFernScreen extends StatefulWidget {
  const BarnsleyFernScreen({super.key});
  @override
  State<BarnsleyFernScreen> createState() => _BarnsleyFernScreenState();
}

class _BarnsleyFernScreenState extends State<BarnsleyFernScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _speed = 500.0;
  double _fx = 0, _fy = 0; int _totalPoints = 0; final List<Offset> _points = [];

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
      for (int i = 0; i < _speed.toInt(); i++) {
        final r = rng.nextDouble();
        double nx, ny;
        if (r < 0.01) { nx = 0; ny = 0.16 * _fy; }
        else if (r < 0.86) { nx = 0.85 * _fx + 0.04 * _fy; ny = -0.04 * _fx + 0.85 * _fy + 1.6; }
        else if (r < 0.93) { nx = 0.2 * _fx - 0.26 * _fy; ny = 0.23 * _fx + 0.22 * _fy + 1.6; }
        else { nx = -0.15 * _fx + 0.28 * _fy; ny = 0.26 * _fx + 0.24 * _fy + 0.44; }
        _fx = nx; _fy = ny;
        _points.add(Offset(_fx, _fy));
        if (_points.length > 50000) _points.removeAt(0);
        _totalPoints++;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _speed = 500.0;
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
          const Text('반슬리 양치류', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '혼돈 시뮬레이션',
          title: '반슬리 양치류',
          formula: 'IFS: f₁,f₂,f₃,f₄',
          formulaDescription: '반복 함수 시스템으로 양치류 프랙탈을 생성합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BarnsleyFernScreenPainter(
                time: _time,
                speed: _speed,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '점/프레임',
                value: _speed,
                min: 50.0,
                max: 5000.0,
                defaultValue: 500.0,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => _speed = v),
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
          _V('총 점', '${_totalPoints}'),
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

class _BarnsleyFernScreenPainter extends CustomPainter {
  final double time;
  final double speed;

  _BarnsleyFernScreenPainter({
    required this.time,
    required this.speed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // IFS Barnsley fern — generate deterministic points using seeded RNG
    // Points generated based on time to animate growth
    final totalPts = ((time * speed).clamp(200, 40000)).toInt();
    final rng = math.Random(1337);

    double fx = 0, fy = 0;
    // Scale: fern data is roughly x in [-2.2, 2.7], y in [0, 9.9]
    // Map to canvas: center-x, bottom margin
    const fernXMin = -2.7, fernXMax = 2.7;
    const fernYMin = 0.0, fernYMax = 10.0;
    final scaleX = w / (fernXMax - fernXMin);
    final scaleY = h * 0.92 / (fernYMax - fernYMin);
    double mapX(double x) => (x - fernXMin) * scaleX;
    double mapY(double y) => h * 0.96 - (y - fernYMin) * scaleY;

    // Title
    _text(canvas, '반슬리 양치류 IFS', Offset(w / 2 - 50, 3),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold));

    // Draw points
    for (int i = 0; i < totalPts; i++) {
      final r = rng.nextDouble();
      double nx, ny;
      if (r < 0.01) {
        nx = 0;
        ny = 0.16 * fy;
      } else if (r < 0.86) {
        nx = 0.85 * fx + 0.04 * fy;
        ny = -0.04 * fx + 0.85 * fy + 1.6;
      } else if (r < 0.93) {
        nx = 0.20 * fx - 0.26 * fy;
        ny = 0.23 * fx + 0.22 * fy + 1.6;
      } else {
        nx = -0.15 * fx + 0.28 * fy;
        ny = 0.26 * fx + 0.24 * fy + 0.44;
      }
      fx = nx;
      fy = ny;

      // Skip first 20 warm-up points
      if (i < 20) continue;

      // Color by height: low=light green, high=dark green
      final tHeight = (fy / 10.0).clamp(0.0, 1.0);
      final green = (80 + tHeight * 120).toInt();
      final col = Color.fromARGB(200, 0, green, (30 - tHeight * 20).toInt());

      canvas.drawRect(
        Rect.fromLTWH(mapX(fx), mapY(fy), 1.2, 1.2),
        Paint()..color = col,
      );
    }

    // Transform labels
    final lblY = h - 40.0;
    _text(canvas, 'f₁ 줄기(1%)  f₂ 큰잎(85%)  f₃,f₄ 작은잎(7%)',
        Offset(8, lblY),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));
    _text(canvas, '점: $totalPts', Offset(8, lblY + 11),
        const TextStyle(color: Color(0xFF64FF8C), fontSize: 7));
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _BarnsleyFernScreenPainter oldDelegate) => true;
}
