import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DivergenceCurlScreen extends StatefulWidget {
  const DivergenceCurlScreen({super.key});
  @override
  State<DivergenceCurlScreen> createState() => _DivergenceCurlScreenState();
}

class _DivergenceCurlScreenState extends State<DivergenceCurlScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _fieldStrength = 1;
  
  double _div = 2.0, _curl = 0.0;

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
      _div = 2.0 * _fieldStrength;
      _curl = _fieldStrength * math.sin(_time);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _fieldStrength = 1.0;
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
          const Text('발산과 회전', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '발산과 회전',
          formula: 'div F = ∇·F, curl F = ∇×F',
          formulaDescription: '벡터장의 발산과 회전을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DivergenceCurlScreenPainter(
                time: _time,
                fieldStrength: _fieldStrength,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '장 세기',
                value: _fieldStrength,
                min: 0.1,
                max: 5,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _fieldStrength = v),
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
          _V('div F', _div.toStringAsFixed(2)),
          _V('curl F', _curl.toStringAsFixed(2)),
          _V('세기', _fieldStrength.toStringAsFixed(1)),
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

class _DivergenceCurlScreenPainter extends CustomPainter {
  final double time;
  final double fieldStrength;

  _DivergenceCurlScreenPainter({
    required this.time,
    required this.fieldStrength,
  });

  void _drawArrow(Canvas canvas, Offset from, double angle, double len, Paint p) {
    final to = Offset(from.dx + len * math.cos(angle), from.dy + len * math.sin(angle));
    canvas.drawLine(from, to, p);
    final hLen = len * 0.35;
    canvas.drawLine(to, Offset(to.dx + hLen * math.cos(angle + 2.5), to.dy + hLen * math.sin(angle + 2.5)), p);
    canvas.drawLine(to, Offset(to.dx + hLen * math.cos(angle - 2.5), to.dy + hLen * math.sin(angle - 2.5)), p);
  }

  void _drawHalf(Canvas canvas, Rect rect, bool isDivergence) {
    final cx = rect.left + rect.width / 2;
    final cy = rect.top + rect.height / 2;
    const cols = 5, rows = 5;
    final cellW = rect.width / (cols + 1);
    final cellH = rect.height / (rows + 1);
    final arrowLen = math.min(cellW, cellH) * 0.38 * fieldStrength.clamp(0.1, 5.0);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final px = rect.left + (c + 1) * cellW;
        final py = rect.top + (r + 1) * cellH;
        final dx = px - cx, dy = py - cy;
        double angle;
        Color color;
        if (isDivergence) {
          // Source/sink pattern
          angle = math.atan2(dy, dx);
          final dist = math.sqrt(dx * dx + dy * dy);
          // Source near center = red expanding, far = blue converging
          if (dist < rect.width * 0.25) {
            color = const Color(0xFFFF4444).withValues(alpha: 0.85);
          } else {
            color = const Color(0xFF4488FF).withValues(alpha: 0.75);
            angle += math.pi; // converging
          }
        } else {
          // Curl: rotation pattern, animated
          angle = math.atan2(dy, dx) + math.pi / 2 + time * 0.8;
          final ccw = (dx * math.cos(time) - dy * math.sin(time)) > 0;
          color = ccw ? AppColors.accent.withValues(alpha: 0.85)
                      : AppColors.accent2.withValues(alpha: 0.8);
        }
        _drawArrow(canvas, Offset(px, py), angle, arrowLen,
          Paint()..color = color..strokeWidth = 1.4..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Background grid
    final gridP = Paint()..color = AppColors.simGrid.withValues(alpha: 0.2)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridP); }
    for (double y = 0; y < size.height; y += 28) { canvas.drawLine(Offset(0, y), Offset(size.width, y), gridP); }

    final halfW = size.width / 2;
    final leftRect  = Rect.fromLTWH(0, 0, halfW, size.height);
    final rightRect = Rect.fromLTWH(halfW, 0, halfW, size.height);

    // Divider
    canvas.drawLine(Offset(halfW, 0), Offset(halfW, size.height),
      Paint()..color = AppColors.muted.withValues(alpha: 0.4)..strokeWidth = 1);

    _drawHalf(canvas, leftRect, true);
    _drawHalf(canvas, rightRect, false);

    // Rotation circles for curl half
    final curlCx = halfW + halfW / 2;
    final curlCy = size.height / 2;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(Offset(curlCx, curlCy), i * 22.0,
        Paint()..color = AppColors.accent.withValues(alpha: 0.06 * i)
               ..style = PaintingStyle.stroke..strokeWidth = 1.0);
    }

    // Labels
    void label(String text, double x, double y, Color c) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y));
    }
    label('발산  div F = ∇·F', halfW / 2, 8, AppColors.ink);
    label('회전  curl F = ∇×F', halfW + halfW / 2, 8, AppColors.ink);
  }

  @override
  bool shouldRepaint(covariant _DivergenceCurlScreenPainter oldDelegate) => true;
}
