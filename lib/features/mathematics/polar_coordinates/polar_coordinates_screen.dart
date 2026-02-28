import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class PolarCoordinatesScreen extends StatefulWidget {
  const PolarCoordinatesScreen({super.key});
  @override
  State<PolarCoordinatesScreen> createState() => _PolarCoordinatesScreenState();
}

class _PolarCoordinatesScreenState extends State<PolarCoordinatesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _petalCount = 3;
  double _amplitude = 1;


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
      
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _petalCount = 3; _amplitude = 1.0;
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
          Text('수학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('극좌표와 장미 곡선', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '극좌표와 장미 곡선',
          formula: 'r = cos(nθ)',
          formulaDescription: '장미와 나선 패턴을 포함한 극좌표 곡선을 그립니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PolarCoordinatesScreenPainter(
                time: _time,
                petalCount: _petalCount,
                amplitude: _amplitude,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '꽃잎 수 n',
                value: _petalCount,
                min: 1,
                max: 12,
                step: 1,
                defaultValue: 3,
                formatValue: (v) => v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _petalCount = v),
              ),
              advancedControls: [
            SimSlider(
                label: '진폭 A',
                value: _amplitude,
                min: 0.5,
                max: 3,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _amplitude = v),
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
          _V('꽃잎 수', _petalCount.toStringAsFixed(0)),
          _V('진폭', _amplitude.toStringAsFixed(1)),
          _V('시간', _time.toStringAsFixed(1)),
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

class _PolarCoordinatesScreenPainter extends CustomPainter {
  final double time;
  final double petalCount;
  final double amplitude;

  _PolarCoordinatesScreenPainter({required this.time, required this.petalCount, required this.amplitude});

  static const List<Color> _petalColors = [
    Color(0xFF00D4FF), Color(0xFF64FF8C), Color(0xFFFFD700),
    Color(0xFFFF6B35), Color(0xFFCC44FF), Color(0xFF00FFCC),
    Color(0xFFFF4488), Color(0xFF88CCFF), Color(0xFFFFAA00),
    Color(0xFF44FF88), Color(0xFFFF88CC), Color(0xFF00AAFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 10 || size.height < 10) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final chartH = size.height * 0.72;
    final cx = size.width / 2;
    final cy = chartH / 2 + 10;
    final maxR = (math.min(cx, cy) - 16) * 0.85;
    final n = petalCount.round();

    // Polar grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int ring = 1; ring <= 4; ring++) {
      canvas.drawCircle(Offset(cx, cy), maxR * ring / 4, gridPaint);
    }
    for (int deg = 0; deg < 360; deg += 30) {
      final a = deg * math.pi / 180;
      canvas.drawLine(Offset(cx, cy), Offset(cx + maxR * math.cos(a), cy + maxR * math.sin(a)), gridPaint);
    }
    // Axis labels
    for (int d = 0; d < 360; d += 90) {
      final a = d * math.pi / 180;
      final lbl = ['0°', '90°', '180°', '270°'][d ~/ 90];
      final tp = TextPainter(
        text: TextSpan(text: lbl, style: const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx + (maxR + 6) * math.cos(a) - tp.width / 2, cy + (maxR + 6) * math.sin(a) - tp.height / 2));
    }

    // Rose curve r = A·cos(n·θ), animated sweep
    final sweepAngle = (time * 0.8) % (2 * math.pi);
    final rosePath = Path();
    bool roseStarted = false;
    const steps = 200;
    for (int s = 0; s <= steps; s++) {
      final theta = s / steps * 2 * math.pi;
      if (theta > sweepAngle) break;
      final r = amplitude * maxR * math.cos(n * theta).abs();
      final x = cx + r * math.cos(theta);
      final y = cy + r * math.sin(theta);
      if (!roseStarted) { rosePath.moveTo(x, y); roseStarted = true; }
      else { rosePath.lineTo(x, y); }
    }
    canvas.drawPath(rosePath, Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke);

    // Current point glow
    final theta0 = sweepAngle;
    final r0 = amplitude * maxR * math.cos(n * theta0).abs();
    final curX = cx + r0 * math.cos(theta0);
    final curY = cy + r0 * math.sin(theta0);
    canvas.drawCircle(Offset(curX, curY), 8, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.25)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(curX, curY), 4, Paint()..color = const Color(0xFF00D4FF)..style = PaintingStyle.fill);

    // Archimedean spiral r = A·θ (second curve, orange)
    final spiralPath = Path();
    bool spiralStarted = false;
    const spiralSteps = 200;
    for (int s = 0; s <= spiralSteps; s++) {
      final theta = s / spiralSteps * 4 * math.pi;
      final r = amplitude * maxR * theta / (4 * math.pi);
      final x = cx + r * math.cos(theta);
      final y = cy + r * math.sin(theta);
      if (!spiralStarted) { spiralPath.moveTo(x, y); spiralStarted = true; }
      else { spiralPath.lineTo(x, y); }
    }
    canvas.drawPath(spiralPath, Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke);

    // Bar graph at bottom: r(θ) amplitude vs angle
    final barTop = chartH + 14;
    final barH = size.height - barTop - 10;
    const barSteps = 36;
    for (int s = 0; s < barSteps; s++) {
      final theta = s / barSteps * 2 * math.pi;
      final r = (amplitude * math.cos(n * theta)).abs();
      final barX = s / barSteps * size.width;
      final barW = size.width / barSteps - 1;
      final barPxH = r * barH;
      final col = _petalColors[s % _petalColors.length];
      canvas.drawRect(
        Rect.fromLTWH(barX, barTop + barH - barPxH, barW, barPxH),
        Paint()..color = col.withValues(alpha: 0.6)..style = PaintingStyle.fill,
      );
    }

    // Formula label
    final ftp = TextPainter(
      text: TextSpan(text: 'r = ${amplitude.toStringAsFixed(1)}·cos($nθ)', style: const TextStyle(color: Color(0xFFE0F4FF), fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    ftp.paint(canvas, Offset(8, 8));
  }

  @override
  bool shouldRepaint(covariant _PolarCoordinatesScreenPainter oldDelegate) => true;
}
