import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ErosionDepositionScreen extends StatefulWidget {
  const ErosionDepositionScreen({super.key});
  @override
  State<ErosionDepositionScreen> createState() => _ErosionDepositionScreenState();
}

class _ErosionDepositionScreenState extends State<ErosionDepositionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _flowRate = 5;
  double _slope = 10;
  double _erosionRate = 0.0, _sediment = 0.0;

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
      _erosionRate = 0.01 * math.pow(_flowRate, 0.6).toDouble() * math.pow(_slope / 45.0, 1.5).toDouble();
      _sediment = _erosionRate * _time;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _flowRate = 5.0; _slope = 10.0;
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
          const Text('침식과 퇴적', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '침식과 퇴적',
          formula: 'Q = KA^m S^n',
          formulaDescription: '물의 흐름에 의한 침식과 퇴적 과정을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ErosionDepositionScreenPainter(
                time: _time,
                flowRate: _flowRate,
                slope: _slope,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '유량 (m³/s)',
                value: _flowRate,
                min: 0.1,
                max: 50,
                step: 0.5,
                defaultValue: 5,
                formatValue: (v) => v.toStringAsFixed(1) + ' m³/s',
                onChanged: (v) => setState(() => _flowRate = v),
              ),
              advancedControls: [
            SimSlider(
                label: '경사도 (°)',
                value: _slope,
                min: 0,
                max: 45,
                step: 1,
                defaultValue: 10,
                formatValue: (v) => v.toStringAsFixed(0) + '°',
                onChanged: (v) => setState(() => _slope = v),
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
          _V('침식률', _erosionRate.toStringAsFixed(3) + ' m/yr'),
          _V('퇴적량', _sediment.toStringAsFixed(2) + ' m³'),
          _V('경사', _slope.toStringAsFixed(0) + '°'),
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

class _ErosionDepositionScreenPainter extends CustomPainter {
  final double time;
  final double flowRate;
  final double slope;

  _ErosionDepositionScreenPainter({
    required this.time,
    required this.flowRate,
    required this.slope,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, {Color color = const Color(0xFF5A8A9A), double fontSize = 8}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;
    final slopeFrac = (slope / 45.0).clamp(0.0, 1.0);
    final flowFrac = (flowRate / 50.0).clamp(0.0, 1.0);

    // Sky background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.5),
      Paint()..color = const Color(0xFF080E18),
    );

    // === Terrain profile ===
    // Three zones: upper (mountain/erosion), middle (plain/transport), lower (delta/deposition)
    // Ground profile curve from upper-left to lower-right
    final groundY = h * 0.62; // sea level / floodplain baseline

    // Mountain zone (left 35%)
    final mountainPeakY = h * 0.15 + (1 - slopeFrac) * h * 0.18;
    final mountainEndX = w * 0.32;

    // River path control points (meandering)
    // Upper: steep V valley
    // Middle: wider, meandering
    // Lower: broad delta

    // Draw sky to ground background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF08100A));

    // ---- Terrain fill ----
    // Mountain
    final mountainPath = Path()
      ..moveTo(0, groundY)
      ..lineTo(0, mountainPeakY + h * 0.06)
      ..quadraticBezierTo(w * 0.05, mountainPeakY, w * 0.12, mountainPeakY + h * 0.04)
      ..quadraticBezierTo(w * 0.2, mountainPeakY + h * 0.08, mountainEndX, groundY)
      ..lineTo(0, groundY)
      ..close();
    canvas.drawPath(mountainPath, Paint()..color = const Color(0xFF1E2A14));

    // Mountain highlight (erosion face - steep side)
    final erosionPath = Path()
      ..moveTo(w * 0.12, mountainPeakY + h * 0.04)
      ..quadraticBezierTo(w * 0.18, groundY - h * 0.08, mountainEndX, groundY);
    canvas.drawPath(erosionPath, Paint()
      ..color = const Color(0xFF2A1810).withValues(alpha: 0.6)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke);

    // Floodplain (middle zone)
    canvas.drawRect(
      Rect.fromLTWH(mountainEndX, groundY, w * 0.38, h - groundY),
      Paint()..color = const Color(0xFF1A2A0E),
    );

    // Delta / coast (right zone)
    final deltaStartX = w * 0.70;
    final deltaPath = Path()
      ..moveTo(deltaStartX, groundY)
      ..lineTo(w, groundY - h * 0.04)
      ..lineTo(w, h)
      ..lineTo(deltaStartX, h)
      ..close();
    canvas.drawPath(deltaPath, Paint()..color = const Color(0xFF1A2808));

    // Ocean
    final oceanPath = Path()
      ..moveTo(w * 0.88, groundY - h * 0.02)
      ..lineTo(w, groundY - h * 0.04)
      ..lineTo(w, h)
      ..lineTo(w * 0.88, h)
      ..close();
    canvas.drawPath(oceanPath, Paint()..color = const Color(0xFF082840));

    // ---- River channel ----
    // River centerline — meanders increase in middle zone
    List<Offset> riverPoints = [];
    for (int px = 0; px <= 200; px++) {
      final t = px / 200.0;
      final x = t * w;
      double y;
      if (t < 0.32) {
        // Upper: steep, narrow V-valley trace (river at bottom of valley)
        final lerpT = t / 0.32;
        y = mountainPeakY + h * 0.06 + (groundY - (mountainPeakY + h * 0.06)) * math.pow(lerpT, 1.8);
        y += math.sin(t * math.pi * 6) * 3 * lerpT;
      } else if (t < 0.70) {
        // Middle: meander on floodplain
        final lerpT = (t - 0.32) / 0.38;
        final meanderAmp = h * 0.04 * (0.5 + lerpT * 0.5);
        y = groundY - h * 0.005 + math.sin(lerpT * math.pi * 3 - time * flowFrac * 0.8) * meanderAmp;
      } else {
        // Lower delta: fan out
        final lerpT = (t - 0.70) / 0.30;
        y = groundY - h * 0.005 - lerpT * h * 0.02 + math.sin(lerpT * math.pi * 2) * h * 0.015;
      }
      riverPoints.add(Offset(x, y));
    }

    // River width varies: narrow upstream, wide downstream
    for (int layer = 2; layer >= 0; layer--) {
      final riverPath = Path();
      final widthMult = [1.0, 1.6, 2.4][layer];
      final alphaVal = [0.9, 0.5, 0.25][layer];

      // Compute river width at each point
      for (int i = 0; i < riverPoints.length; i++) {
        final t = i / 200.0;
        final baseW = 2.0 + t * 14.0 * flowFrac;
        final ww = baseW * widthMult;
        final p = riverPoints[i];
        // Perpendicular offset
        double nx = 0, ny = 1;
        if (i < riverPoints.length - 1) {
          final dx = riverPoints[i + 1].dx - p.dx;
          final dy = riverPoints[i + 1].dy - p.dy;
          final len = math.sqrt(dx * dx + dy * dy);
          if (len > 0) { nx = -dy / len; ny = dx / len; }
        }
        final top = Offset(p.dx + nx * ww, p.dy + ny * ww);
        if (i == 0) { riverPath.moveTo(top.dx, top.dy); } else { riverPath.lineTo(top.dx, top.dy); }
      }
      for (int i = riverPoints.length - 1; i >= 0; i--) {
        final t = i / 200.0;
        final baseW = 2.0 + t * 14.0 * flowFrac;
        final ww = baseW * widthMult;
        final p = riverPoints[i];
        double nx = 0, ny = 1;
        if (i > 0) {
          final dx = riverPoints[i].dx - riverPoints[i - 1].dx;
          final dy = riverPoints[i].dy - riverPoints[i - 1].dy;
          final len = math.sqrt(dx * dx + dy * dy);
          if (len > 0) { nx = -dy / len; ny = dx / len; }
        }
        riverPath.lineTo(p.dx - nx * ww, p.dy - ny * ww);
      }
      riverPath.close();

      // Color: fast=cyan, slow=blue
      final speedColor = Color.lerp(const Color(0xFF1A4A8A), const Color(0xFF00AADD), flowFrac)!;
      canvas.drawPath(riverPath, Paint()..color = speedColor.withValues(alpha: alphaVal));
    }

    // ---- Sediment particles (animated) ----
    final rng = math.Random(123);
    final particleCount = (8 + flowFrac * 16).round();
    for (int p = 0; p < particleCount; p++) {
      // Particle moves along river path
      final tBase = (p / particleCount + time * flowFrac * 0.12) % 1.0;
      final idx = (tBase * (riverPoints.length - 1)).toInt().clamp(0, riverPoints.length - 1);
      final pos = riverPoints[idx];

      // Particle size: large upstream (coarse), small downstream (fine)
      final coarseness = 1.0 - tBase; // 1 = coarse at source, 0 = fine at delta
      final particleR = 2.0 + coarseness * 4.0 * (0.5 + rng.nextDouble() * 0.5);
      final particleColor = Color.lerp(
        const Color(0xFFAA8844), // fine sediment (brown)
        const Color(0xFF6A5030), // coarse gravel
        coarseness,
      )!.withValues(alpha: 0.75);

      canvas.drawCircle(pos + Offset((rng.nextDouble() - 0.5) * 6, (rng.nextDouble() - 0.5) * 4), particleR, Paint()..color = particleColor);
    }

    // ---- Zone labels ----
    _drawLabel(canvas, 'V자 계곡\n(침식)', Offset(w * 0.10, mountainPeakY - 10), color: const Color(0xFFFF6B35), fontSize: 8);
    _drawLabel(canvas, '사행 (퇴적)', Offset(w * 0.51, groundY - h * 0.09), color: const Color(0xFF64FF8C), fontSize: 8);
    _drawLabel(canvas, '삼각주', Offset(w * 0.82, groundY - h * 0.06), color: const Color(0xFF00D4FF), fontSize: 8);
    _drawLabel(canvas, '상류', Offset(w * 0.08, groundY + 12), color: const Color(0xFF3A5A3A), fontSize: 8);
    _drawLabel(canvas, '중류', Offset(w * 0.51, groundY + 12), color: const Color(0xFF3A5A3A), fontSize: 8);
    _drawLabel(canvas, '하류', Offset(w * 0.80, groundY + 12), color: const Color(0xFF3A5A3A), fontSize: 8);

    // Deposition gradient legend
    _drawLabel(canvas, '조립←입자→세립', Offset(w * 0.5, h * 0.96), color: const Color(0xFF5A6A5A), fontSize: 7);
    for (int i = 0; i < 5; i++) {
      final lx = w * 0.3 + i * w * 0.08;
      final coarseness = 1.0 - i / 4.0;
      final r = 3.0 + coarseness * 3.5;
      final c = Color.lerp(const Color(0xFFAA8844), const Color(0xFF6A5030), coarseness)!;
      canvas.drawCircle(Offset(lx, h * 0.91), r, Paint()..color = c);
    }

    // Flow speed indicator
    _drawLabel(canvas, '유량 ${flowRate.toStringAsFixed(1)} m³/s', Offset(w * 0.15, h * 0.96), color: const Color(0xFF00AADD), fontSize: 8);
    _drawLabel(canvas, '경사 ${slope.toStringAsFixed(0)}°', Offset(w * 0.85, h * 0.96), color: const Color(0xFFFF6B35), fontSize: 8);
  }

  @override
  bool shouldRepaint(covariant _ErosionDepositionScreenPainter oldDelegate) => true;
}
