import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class WeatherFrontsScreen extends StatefulWidget {
  const WeatherFrontsScreen({super.key});
  @override
  State<WeatherFrontsScreen> createState() => _WeatherFrontsScreenState();
}

class _WeatherFrontsScreenState extends State<WeatherFrontsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _frontType = 0.0;
  double _windSpeed = 20.0;
  double _tempDiff = 0; String _precip = 'Light';

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
      _tempDiff = 5 + _windSpeed * 0.2;
      _precip = _windSpeed > 30 ? 'Heavy' : _windSpeed > 15 ? 'Moderate' : 'Light';
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _frontType = 0.0;
      _windSpeed = 20.0;
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
          Text('지구과학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('기상 전선', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '기상 전선',
          formulaDescription: '한랭, 온난, 정체, 폐색 전선의 특성을 관찰합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _WeatherFrontsScreenPainter(
                time: _time,
                frontType: _frontType,
                windSpeed: _windSpeed,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '전선 유형',
                value: _frontType,
                min: 0.0,
                max: 3.0,
                defaultValue: 0.0,
                formatValue: (v) => '${["한랭","온난","정체","폐색"][v.toInt()]}',
                onChanged: (v) => setState(() => _frontType = v),
              ),
              advancedControls: [
            SimSlider(
                label: '풍속 (km/h)',
                value: _windSpeed,
                min: 5.0,
                max: 60.0,
                defaultValue: 20.0,
                formatValue: (v) => '${v.toInt()} km/h',
                onChanged: (v) => setState(() => _windSpeed = v),
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
          _V('온도차', '${_tempDiff.toStringAsFixed(1)} °C'),
          _V('강수', _precip),
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

class _WeatherFrontsScreenPainter extends CustomPainter {
  final double time;
  final double frontType;
  final double windSpeed;

  _WeatherFrontsScreenPainter({
    required this.time,
    required this.frontType,
    required this.windSpeed,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, {Color color = const Color(0xFF5A8A9A), double fontSize = 10}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    final dx = to.dx - from.dx, dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final ux = dx / len, uy = dy / len;
    final arrowSize = 7.0;
    final p1 = Offset(to.dx - arrowSize * (ux - uy * 0.5), to.dy - arrowSize * (uy + ux * 0.5));
    final p2 = Offset(to.dx - arrowSize * (ux + uy * 0.5), to.dy - arrowSize * (uy - ux * 0.5));
    final path = Path()..moveTo(to.dx, to.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;
    final cx = w / 2;
    final speed = windSpeed / 60.0;
    final int fType = frontType.round().clamp(0, 3);

    // Background: sky gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF0A1628), const Color(0xFF0D1A20)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // Grid (lat/lon lines)
    final gridPaint = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.6)..strokeWidth = 0.5;
    for (double x = 0; x < w; x += w / 8) canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    for (double y = 0; y < h; y += h / 6) canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);

    // Isobars (pressure contours)
    final isobarPaint = Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)..strokeWidth = 1.0..style = PaintingStyle.stroke;
    final pressures = [996, 1000, 1004, 1008, 1012];
    for (int i = 0; i < pressures.length; i++) {
      final rx = w * 0.28 + i * w * 0.06;
      final ry = h * 0.18 + i * h * 0.05;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx * 0.7, h * 0.5), width: rx, height: ry), isobarPaint);
    }
    final isobarPaint2 = Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.3)..strokeWidth = 1.0..style = PaintingStyle.stroke;
    for (int i = 0; i < pressures.length; i++) {
      final rx = w * 0.2 + i * w * 0.055;
      final ry = h * 0.14 + i * h * 0.05;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx * 1.4, h * 0.45), width: rx, height: ry), isobarPaint2);
    }

    // L (low pressure) center
    final lowX = cx * 0.7 + math.sin(time * speed) * 8;
    final lowY = h * 0.5;
    _drawLabel(canvas, 'L', Offset(lowX, lowY), color: const Color(0xFFFF6B6B), fontSize: 18);
    _drawLabel(canvas, '996 hPa', Offset(lowX, lowY + 16), color: const Color(0xFF5A8A9A), fontSize: 8);

    // H (high pressure) center
    final hiX = cx * 1.4;
    final hiY = h * 0.45;
    _drawLabel(canvas, 'H', Offset(hiX, hiY), color: const Color(0xFF64FF8C), fontSize: 18);
    _drawLabel(canvas, '1016 hPa', Offset(hiX, hiY + 16), color: const Color(0xFF5A8A9A), fontSize: 8);

    // Wind arrows around L (counterclockwise)
    final windPaint = Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.7)..strokeWidth = 1.2..style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      final baseAngle = i * math.pi / 3 + time * speed * 0.5;
      final r = h * 0.15;
      final ox = lowX + r * math.cos(baseAngle);
      final oy = lowY + r * math.sin(baseAngle);
      // counterclockwise direction
      final dirAngle = baseAngle + math.pi / 2;
      final tx = ox + 18 * math.cos(dirAngle);
      final ty = oy + 18 * math.sin(dirAngle);
      _drawArrow(canvas, Offset(ox, oy), Offset(tx, ty), windPaint);
    }

    // Wind arrows around H (clockwise)
    final windPaint2 = Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.5)..strokeWidth = 1.2..style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      final baseAngle = i * math.pi / 3 - time * speed * 0.3;
      final r = h * 0.12;
      final ox = hiX + r * math.cos(baseAngle);
      final oy = hiY + r * math.sin(baseAngle);
      final dirAngle = baseAngle - math.pi / 2;
      final tx = ox + 15 * math.cos(dirAngle);
      final ty = oy + 15 * math.sin(dirAngle);
      _drawArrow(canvas, Offset(ox, oy), Offset(tx, ty), windPaint2);
    }

    // Front line origin: near low center moving right
    final frontOffset = (time * speed * 30) % (w * 0.35);
    final frontStartX = lowX + 15 + frontOffset;
    final frontY = lowY;

    if (fType == 0) {
      // Cold front: blue triangles pointing in direction of movement
      final coldPaint = Paint()..color = const Color(0xFF4488FF)..strokeWidth = 2.5..style = PaintingStyle.stroke;
      final path = Path();
      for (double x = frontStartX; x < frontStartX + w * 0.35; x += 18) {
        path.moveTo(x, frontY);
        path.lineTo(x + 18, frontY);
      }
      canvas.drawPath(path, coldPaint);
      // Triangles
      for (double x = frontStartX; x < frontStartX + w * 0.35; x += 18) {
        final tri = Path()
          ..moveTo(x + 4, frontY)
          ..lineTo(x + 11, frontY - 10)
          ..lineTo(x + 18, frontY)
          ..close();
        canvas.drawPath(tri, Paint()..color = const Color(0xFF4488FF)..style = PaintingStyle.fill);
      }
      _drawLabel(canvas, '한랭전선', Offset(frontStartX + w * 0.17, frontY - 18), color: const Color(0xFF4488FF), fontSize: 10);
    } else if (fType == 1) {
      // Warm front: red semicircles
      final warmPaint = Paint()..color = const Color(0xFFFF4444)..strokeWidth = 2.5..style = PaintingStyle.stroke;
      for (double x = frontStartX; x < frontStartX + w * 0.35; x += 18) {
        canvas.drawLine(Offset(x, frontY), Offset(x + 18, frontY), warmPaint);
      }
      for (double x = frontStartX + 9; x < frontStartX + w * 0.35; x += 18) {
        final semiRect = Rect.fromCenter(center: Offset(x, frontY), width: 14, height: 14);
        canvas.drawArc(semiRect, math.pi, math.pi, false, warmPaint);
      }
      _drawLabel(canvas, '온난전선', Offset(frontStartX + w * 0.17, frontY + 18), color: const Color(0xFFFF4444), fontSize: 10);
    } else if (fType == 2) {
      // Stationary front: alternating triangles and semicircles
      for (double x = frontStartX; x < frontStartX + w * 0.35; x += 18) {
        canvas.drawLine(Offset(x, frontY), Offset(x + 18, frontY),
          Paint()..color = const Color(0xFF4488FF)..strokeWidth = 2.0..style = PaintingStyle.stroke);
      }
      for (int i = 0; i * 18 < w * 0.35; i++) {
        final x = frontStartX + i * 18 + 4;
        if (i.isEven) {
          final tri = Path()
            ..moveTo(x, frontY)
            ..lineTo(x + 7, frontY - 9)
            ..lineTo(x + 14, frontY)
            ..close();
          canvas.drawPath(tri, Paint()..color = const Color(0xFF4488FF)..style = PaintingStyle.fill);
        } else {
          final semiRect = Rect.fromCenter(center: Offset(x + 7, frontY), width: 12, height: 12);
          canvas.drawArc(semiRect, 0, math.pi, false,
            Paint()..color = const Color(0xFFFF4444)..strokeWidth = 2.0..style = PaintingStyle.stroke);
        }
      }
      _drawLabel(canvas, '정체전선', Offset(frontStartX + w * 0.17, frontY - 18), color: const Color(0xFFAA88FF), fontSize: 10);
    } else {
      // Occluded front: purple mixed symbols
      final occPaint = Paint()..color = const Color(0xFF9944FF)..strokeWidth = 2.5..style = PaintingStyle.stroke;
      for (double x = frontStartX; x < frontStartX + w * 0.35; x += 18) {
        canvas.drawLine(Offset(x, frontY), Offset(x + 18, frontY), occPaint);
      }
      for (int i = 0; i * 18 < w * 0.35; i++) {
        final x = frontStartX + i * 18;
        if (i.isEven) {
          final tri = Path()
            ..moveTo(x + 4, frontY)
            ..lineTo(x + 11, frontY - 9)
            ..lineTo(x + 18, frontY)
            ..close();
          canvas.drawPath(tri, Paint()..color = const Color(0xFF9944FF)..style = PaintingStyle.fill);
        } else {
          final semiRect = Rect.fromCenter(center: Offset(x + 9, frontY), width: 14, height: 14);
          canvas.drawArc(semiRect, math.pi, math.pi, false, occPaint);
        }
      }
      _drawLabel(canvas, '폐색전선', Offset(frontStartX + w * 0.17, frontY - 18), color: const Color(0xFF9944FF), fontSize: 10);
    }

    // Cloud patches moving with wind
    final cloudPaint = Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.15)..style = PaintingStyle.fill;
    final rng = math.Random(42);
    for (int i = 0; i < 6; i++) {
      final baseX = rng.nextDouble() * w;
      final baseY = rng.nextDouble() * h * 0.8 + h * 0.05;
      final cx2 = (baseX + time * speed * 25 * (0.5 + rng.nextDouble() * 0.5)) % w;
      final r = 18.0 + rng.nextDouble() * 16;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx2, baseY), width: r * 2.2, height: r), cloudPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx2 + r * 0.5, baseY - r * 0.3), width: r * 1.4, height: r * 0.8), cloudPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherFrontsScreenPainter oldDelegate) => true;
}
