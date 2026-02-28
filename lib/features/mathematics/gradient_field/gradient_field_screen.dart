import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class GradientFieldScreen extends StatefulWidget {
  const GradientFieldScreen({super.key});
  @override
  State<GradientFieldScreen> createState() => _GradientFieldScreenState();
}

class _GradientFieldScreenState extends State<GradientFieldScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _fieldType = 0;
  
  double _maxMag = 1.0;

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
      _maxMag = 1.0 + _fieldType;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _fieldType = 0.0;
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
          const Text('기울기 벡터장', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '기울기 벡터장',
          formula: '∇f = (∂f/∂x, ∂f/∂y)',
          formulaDescription: '스칼라 함수의 기울기 벡터장을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _GradientFieldScreenPainter(
                time: _time,
                fieldType: _fieldType,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '필드 유형',
                value: _fieldType,
                min: 0,
                max: 3,
                step: 1,
                defaultValue: 0,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _fieldType = v),
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
          _V('유형', ['x²+y²', 'sin(x)cos(y)', 'xy', 'x²-y²'][_fieldType.toInt()]),
          _V('최대크기', _maxMag.toStringAsFixed(1)),
          _V('차원', '2D'),
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

class _GradientFieldScreenPainter extends CustomPainter {
  final double time;
  final double fieldType;

  _GradientFieldScreenPainter({
    required this.time,
    required this.fieldType,
  });

  // Gradient of f(x,y) based on fieldType
  // Returns (gx, gy) in normalized field coords
  (double, double) _gradient(double nx, double ny) {
    switch (fieldType.toInt()) {
      case 0: // x^2+y^2 => grad = (2x, 2y)
        return (2 * nx, 2 * ny);
      case 1: // sin(x)cos(y) => grad = (cos(x)cos(y), -sin(x)sin(y))
        return (math.cos(nx) * math.cos(ny + time * 0.3),
                -math.sin(nx) * math.sin(ny + time * 0.3));
      case 2: // xy => grad = (y, x)
        return (ny, nx);
      case 3: // x^2-y^2 => grad = (2x, -2y)
        return (2 * nx, -2 * ny);
      default:
        return (math.cos(nx + time * 0.2), math.sin(ny + time * 0.2));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final cols = 10, rows = 8;
    final cellW = size.width / (cols + 1);
    final cellH = size.height / (rows + 1);
    final maxArrow = math.min(cellW, cellH) * 0.4;

    // Draw faint grid
    final gridP = Paint()..color = AppColors.simGrid.withValues(alpha: 0.25)..strokeWidth = 0.5;
    for (double x = 0; x <= size.width; x += cellW) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridP); }
    for (double y = 0; y <= size.height; y += cellH) { canvas.drawLine(Offset(0, y), Offset(size.width, y), gridP); }

    // Compute max magnitude for color mapping
    double maxMag = 0.001;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final nx = (c / (cols - 1) - 0.5) * math.pi * 2;
        final ny = (r / (rows - 1) - 0.5) * math.pi * 2;
        final (gx, gy) = _gradient(nx, ny);
        final mag = math.sqrt(gx * gx + gy * gy);
        if (mag > maxMag) maxMag = mag;
      }
    }

    // Draw arrows
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final px = (c + 1) * cellW;
        final py = (r + 1) * cellH;
        final nx = (c / (cols - 1) - 0.5) * math.pi * 2;
        final ny = (r / (rows - 1) - 0.5) * math.pi * 2;
        final (gx, gy) = _gradient(nx, ny);
        final mag = math.sqrt(gx * gx + gy * gy);
        final norm = mag / maxMag;
        // Color: cyan=low, orange=high
        final color = Color.lerp(AppColors.accent, AppColors.accent2, norm.clamp(0, 1))!;
        final arrowLen = maxArrow * norm.clamp(0.05, 1.0);
        final angle = math.atan2(gy, gx);
        final ex = px + arrowLen * math.cos(angle);
        final ey = py + arrowLen * math.sin(angle);
        final arrowP = Paint()..color = color..strokeWidth = 1.5..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(px, py), Offset(ex, ey), arrowP);
        // Arrowhead
        final headLen = arrowLen * 0.35;
        final headAngle1 = angle + math.pi * 0.75;
        final headAngle2 = angle - math.pi * 0.75;
        canvas.drawLine(Offset(ex, ey),
          Offset(ex + headLen * math.cos(headAngle1), ey + headLen * math.sin(headAngle1)), arrowP);
        canvas.drawLine(Offset(ex, ey),
          Offset(ex + headLen * math.cos(headAngle2), ey + headLen * math.sin(headAngle2)), arrowP);
      }
    }

    // Draw particle following gradient path (orange dot)
    final angle = time * 0.7;
    final pnx = math.sin(angle) * 2.0;
    final pny = math.cos(angle * 0.6) * 1.5;
    final px = (pnx / (math.pi * 2) + 0.5) * size.width;
    final py = (pny / (math.pi * 2) + 0.5) * size.height;
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(Offset(px, py), 4.0 + i * 2,
        Paint()..color = AppColors.accent2.withValues(alpha: 0.15 * i));
    }
    canvas.drawCircle(Offset(px, py), 5, Paint()..color = AppColors.accent2);

    // Title label
    final tp = TextPainter(
      text: const TextSpan(text: '기울기 벡터장  ∇f',
        style: TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(8, 8));
  }

  @override
  bool shouldRepaint(covariant _GradientFieldScreenPainter oldDelegate) => true;
}
