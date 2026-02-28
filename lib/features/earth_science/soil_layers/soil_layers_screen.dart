import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class SoilLayersScreen extends StatefulWidget {
  const SoilLayersScreen({super.key});
  @override
  State<SoilLayersScreen> createState() => _SoilLayersScreenState();
}

class _SoilLayersScreenState extends State<SoilLayersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _depth = 2;
  
  String _horizon = "A";

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
      _horizon = _depth < 0.1 ? "O" : _depth < 0.5 ? "A" : _depth < 1.5 ? "B" : _depth < 3.0 ? "C" : "R";
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _depth = 2.0;
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
          const Text('토양층', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '토양층',
          formula: 'O-A-B-C-R horizons',
          formulaDescription: '토양의 층위 구조를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SoilLayersScreenPainter(
                time: _time,
                depth: _depth,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '깊이 (m)',
                value: _depth,
                min: 0,
                max: 10,
                step: 0.1,
                defaultValue: 2,
                formatValue: (v) => v.toStringAsFixed(1) + ' m',
                onChanged: (v) => setState(() => _depth = v),
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
          _V('깊이', _depth.toStringAsFixed(1) + ' m'),
          _V('층위', _horizon),
          _V('유형', {'O':'유기물층','A':'표토','B':'집적층','C':'모재층','R':'기반암'}[_horizon] ?? ''),
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

class _SoilLayersScreenPainter extends CustomPainter {
  final double time;
  final double depth;

  _SoilLayersScreenPainter({
    required this.time,
    required this.depth,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, {Color color = const Color(0xFF5A8A9A), double fontSize = 9}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx, pos.dy - tp.height / 2));
  }

  void _drawArrowDown(Canvas canvas, double x, double y1, double y2, Color color) {
    final p = Paint()..color = color..strokeWidth = 1.2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x, y1), Offset(x, y2), p);
    final path = Path()
      ..moveTo(x, y2)
      ..lineTo(x - 4, y2 - 7)
      ..lineTo(x + 4, y2 - 7)
      ..close();
    canvas.drawPath(path, p..style = PaintingStyle.fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;

    // Layout: left label column + right cross-section
    final labelW = w * 0.28;
    final sectionX = labelW;
    final sectionW = w - labelW - 8;

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF080E08));

    // Horizon definitions: [label, name, color, fraction of display height, depth_m_start, depth_m_end]
    // Total simulated depth: 10m mapped to h
    final horizons = [
      ('O', '유기물층', const Color(0xFF4A2800), 0.06, 0.0,  0.05),
      ('A', '표토',    const Color(0xFF3A1E00), 0.14, 0.05, 0.3),
      ('B', '집적층',  const Color(0xFF6B3A12), 0.20, 0.3,  1.5),
      ('C', '모재층',  const Color(0xFF6B6040), 0.25, 1.5,  4.0),
      ('R', '기반암',  const Color(0xFF3A3A3A), 0.35, 4.0,  10.0),
    ];

    // Compute pixel boundaries for each horizon
    double yOff = 0;
    final List<(String, String, Color, double, double, double, double, double)> horizonRects = [];
    for (final hz in horizons) {
      final pxH = h * hz.$4;
      horizonRects.add((hz.$1, hz.$2, hz.$3, sectionX, yOff, sectionW, pxH, hz.$6));
      yOff += pxH;
    }

    // Draw each horizon
    for (final hr in horizonRects) {
      final label = hr.$1;
      final color = hr.$3;
      final rx = hr.$4, ry = hr.$5, rw = hr.$6, rh = hr.$7;

      canvas.drawRect(Rect.fromLTWH(rx, ry, rw, rh), Paint()..color = color);

      // Texture overlay
      final rng = math.Random(label.codeUnitAt(0));
      if (label == 'O') {
        // Leaf litter dots
        for (int i = 0; i < 20; i++) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(rx + rng.nextDouble() * rw, ry + rng.nextDouble() * rh), width: 8, height: 4),
            Paint()..color = const Color(0xFF2A1400).withValues(alpha: 0.7),
          );
        }
      } else if (label == 'A') {
        // Dark humus dots
        for (int i = 0; i < 30; i++) {
          canvas.drawCircle(
            Offset(rx + rng.nextDouble() * rw, ry + rng.nextDouble() * rh),
            rng.nextDouble() * 3 + 1,
            Paint()..color = const Color(0xFF1A0800).withValues(alpha: 0.5),
          );
        }
      } else if (label == 'B') {
        // Iron oxide blotches
        for (int i = 0; i < 18; i++) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(rx + rng.nextDouble() * rw, ry + rng.nextDouble() * rh), width: 14, height: 8),
            Paint()..color = const Color(0xFF8B4513).withValues(alpha: 0.35),
          );
        }
      } else if (label == 'C') {
        // Rock fragment lines
        for (int i = 0; i < 12; i++) {
          final fx = rx + rng.nextDouble() * rw;
          final fy = ry + rng.nextDouble() * rh;
          canvas.drawLine(Offset(fx, fy), Offset(fx + 15, fy + 5),
            Paint()..color = const Color(0xFF8A8060).withValues(alpha: 0.5)..strokeWidth = 2);
        }
      } else if (label == 'R') {
        // Rock crack pattern
        for (int i = 0; i < 8; i++) {
          final fx = rx + rng.nextDouble() * rw;
          final fy = ry + rng.nextDouble() * rh;
          canvas.drawLine(Offset(fx, fy), Offset(fx + rng.nextDouble() * 30 - 15, fy + rng.nextDouble() * 20),
            Paint()..color = const Color(0xFF222222).withValues(alpha: 0.7)..strokeWidth = 1.5);
        }
      }

      // Horizon boundary line
      canvas.drawLine(
        Offset(rx, ry),
        Offset(rx + rw, ry),
        Paint()..color = const Color(0xFF0D1A20).withValues(alpha: 0.6)..strokeWidth = 1.2,
      );
    }

    // Plant roots from top
    final rootPaint = Paint()..color = const Color(0xFF3A6A1A).withValues(alpha: 0.75)..strokeWidth = 1.2..style = PaintingStyle.stroke;
    final rootDepthPx = math.min(h * 0.4, h * 0.4);
    for (int r = 0; r < 4; r++) {
      final rx2 = sectionX + sectionW * (0.2 + r * 0.2);
      final path = Path()..moveTo(rx2, 0);
      path.cubicTo(
        rx2 - 10 + r * 5, rootDepthPx * 0.3,
        rx2 + 8 - r * 4, rootDepthPx * 0.6,
        rx2 - 5 + r * 3, rootDepthPx,
      );
      canvas.drawPath(path, rootPaint);
      // Branch
      canvas.drawLine(
        Offset(rx2 - 5 + r * 3, rootDepthPx * 0.5),
        Offset(rx2 + 12 - r * 6, rootDepthPx * 0.6),
        rootPaint,
      );
    }

    // Earthworm (animated)
    final wormY = h * 0.25 + math.sin(time * 1.5) * h * 0.04;
    final wormX = sectionX + sectionW * 0.6 + math.cos(time * 1.5) * sectionW * 0.06;
    final wormPaint = Paint()..color = const Color(0xFFCC8844)..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final wormPath = Path();
    for (int i = 0; i <= 10; i++) {
      final t = i / 10.0;
      final wx = wormX + t * 20;
      final wy = wormY + math.sin(t * math.pi * 2 + time * 3) * 3;
      if (i == 0) { wormPath.moveTo(wx, wy); } else { wormPath.lineTo(wx, wy); }
    }
    canvas.drawPath(wormPath, wormPaint);

    // Water infiltration arrows
    final waterAlpha = 0.5 + 0.3 * math.sin(time * 2);
    _drawArrowDown(canvas, sectionX + sectionW * 0.82, 4, h * 0.18, const Color(0xFF4488FF).withValues(alpha: waterAlpha));
    _drawArrowDown(canvas, sectionX + sectionW * 0.88, h * 0.22, h * 0.38, const Color(0xFF4488FF).withValues(alpha: waterAlpha * 0.7));
    _drawArrowDown(canvas, sectionX + sectionW * 0.84, h * 0.42, h * 0.56, const Color(0xFF4488FF).withValues(alpha: waterAlpha * 0.45));

    // Depth indicator line
    final depthFrac = (depth / 10.0).clamp(0.0, 1.0);
    final depthY = h * depthFrac;
    canvas.drawLine(
      Offset(sectionX, depthY),
      Offset(sectionX + sectionW, depthY),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..strokeWidth = 1.5..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(Offset(sectionX + sectionW - 4, depthY), 3,
      Paint()..color = const Color(0xFF00D4FF));

    // Left label column
    canvas.drawRect(Rect.fromLTWH(0, 0, labelW - 2, h),
      Paint()..color = const Color(0xFF080E08));

    double labelY = 0;
    for (final hz in horizons) {
      final pxH = h * hz.$4;
      final midY = labelY + pxH / 2;
      // Horizon letter
      final tp = TextPainter(
        text: TextSpan(text: hz.$1,
          style: TextStyle(color: hz.$3.withValues(alpha: 1.0).withAlpha(255).withRed(
            (hz.$3.r * 1.4).clamp(0, 255).toInt(),
          ).withGreen(
            (hz.$3.g * 1.4).clamp(0, 255).toInt(),
          ).withBlue(
            (hz.$3.b * 1.4).clamp(0, 255).toInt(),
          ),
          fontSize: 14, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(6, midY - tp.height / 2));

      _drawLabel(canvas, hz.$2, Offset(22, midY), color: const Color(0xFF8AAAAA), fontSize: 8);
      _drawLabel(canvas, '${hz.$5.toStringAsFixed(1)}m', Offset(22, midY + 9), color: const Color(0xFF3A5A5A), fontSize: 7);

      // Divider
      canvas.drawLine(Offset(0, labelY + pxH), Offset(labelW - 2, labelY + pxH),
        Paint()..color = const Color(0xFF1A2A1A)..strokeWidth = 0.8);
      labelY += pxH;
    }

    // Depth label overlay
    _drawLabel(canvas, '깊이: ${depth.toStringAsFixed(1)}m', Offset(sectionX + 6, depthY - 8),
      color: const Color(0xFF00D4FF), fontSize: 8);
  }

  @override
  bool shouldRepaint(covariant _SoilLayersScreenPainter oldDelegate) => true;
}
