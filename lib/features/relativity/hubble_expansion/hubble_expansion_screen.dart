import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class HubbleExpansionScreen extends StatefulWidget {
  const HubbleExpansionScreen({super.key});
  @override
  State<HubbleExpansionScreen> createState() => _HubbleExpansionScreenState();
}

class _HubbleExpansionScreenState extends State<HubbleExpansionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _hubbleConst = 70;
  double _distance = 100;
  double _recessionV = 7000;

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
      _recessionV = _hubbleConst * _distance;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _hubbleConst = 70.0; _distance = 100.0;
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
          Text('상대성이론 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('허블 팽창', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '허블 팽창',
          formula: 'v = H₀d',
          formulaDescription: '허블 법칙에 따른 우주 팽창을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _HubbleExpansionScreenPainter(
                time: _time,
                hubbleConst: _hubbleConst,
                distance: _distance,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'H₀ (km/s/Mpc)',
                value: _hubbleConst,
                min: 50,
                max: 100,
                step: 1,
                defaultValue: 70,
                formatValue: (v) => v.toStringAsFixed(0) + ' km/s/Mpc',
                onChanged: (v) => setState(() => _hubbleConst = v),
              ),
              advancedControls: [
            SimSlider(
                label: '거리 (Mpc)',
                value: _distance,
                min: 1,
                max: 1000,
                step: 10,
                defaultValue: 100,
                formatValue: (v) => v.toStringAsFixed(0) + ' Mpc',
                onChanged: (v) => setState(() => _distance = v),
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
          _V('후퇴속도', _recessionV.toStringAsFixed(0) + ' km/s'),
          _V('H₀', _hubbleConst.toStringAsFixed(0)),
          _V('d', _distance.toStringAsFixed(0) + ' Mpc'),
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

class _HubbleExpansionScreenPainter extends CustomPainter {
  final double time;
  final double hubbleConst;
  final double distance;

  _HubbleExpansionScreenPainter({
    required this.time,
    required this.hubbleConst,
    required this.distance,
  });

  // Seeded galaxy positions (deterministic)
  static final List<_Galaxy> _galaxies = _buildGalaxies();

  static List<_Galaxy> _buildGalaxies() {
    final rng = math.Random(1234);
    final list = <_Galaxy>[];
    for (int i = 0; i < 28; i++) {
      // Distribute in normalised [-1,1] x [-1,1] space
      final gx = (rng.nextDouble() * 2 - 1);
      final gy = (rng.nextDouble() * 2 - 1);
      final dist = math.sqrt(gx * gx + gy * gy);
      list.add(_Galaxy(gx, gy, dist));
    }
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // Split canvas: top half = galaxy expansion view, bottom half = Hubble diagram
    final topH = size.height * 0.48;
    final botH = size.height - topH;

    _drawExpansion(canvas, size, topH);
    _drawHubbleDiagram(canvas, Offset(0, topH), size.width, botH);
  }

  void _drawExpansion(Canvas canvas, Size size, double h) {
    final cx = size.width / 2;
    final cy = h / 2;

    // Expansion scale factor: oscillate slightly with time to show expansion
    final expandFactor = 1.0 + (time * 0.06) % 0.8;
    // Background grid (faint)
    final gridPaint = Paint()
      ..color = const Color(0xFF1A3040).withValues(alpha: 0.5)
      ..strokeWidth = 0.4;
    for (int i = 0; i <= 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
      final y = h * i / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Label
    void drawText(String txt, Offset pos,
        {Color color = const Color(0xFF5A8A9A), double fs = 9}) {
      final tp = TextPainter(
        text: TextSpan(text: txt, style: TextStyle(color: color, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    drawText('우주 팽창 뷰', Offset(6, 4), color: const Color(0xFF5A8A9A), fs: 8);
    drawText('H₀=${hubbleConst.toStringAsFixed(0)} km/s/Mpc',
        Offset(size.width - 120, 4), color: const Color(0xFF00D4FF), fs: 8);

    // Draw galaxies expanding from centre
    for (final g in _galaxies) {
      final scaledX = cx + g.normX * expandFactor * cx * 0.85;
      final scaledY = cy + g.normY * expandFactor * cy * 0.85;

      // Only draw if within bounds
      if (scaledX < 0 || scaledX > size.width || scaledY < 0 || scaledY > h) {
        continue;
      }

      // Galaxy colour by distance: closer=cyan, farther=orange
      final distFrac = g.normDist.clamp(0.0, 1.0);
      final gColor = Color.lerp(
          const Color(0xFF00D4FF), const Color(0xFFFF6B35), distFrac)!;

      // Recession velocity arrow (points away from centre)
      final vx = g.normX * (hubbleConst / 50.0) * 8;
      final vy = g.normY * (hubbleConst / 50.0) * 8;
      if (g.normDist > 0.1) {
        canvas.drawLine(
            Offset(scaledX, scaledY),
            Offset(scaledX + vx, scaledY + vy),
            Paint()
              ..color = gColor.withValues(alpha: 0.5)
              ..strokeWidth = 1.0);
      }

      // Galaxy dot (size by brightness)
      final dotR = 2.5 + (1 - distFrac) * 2.0;
      canvas.drawCircle(Offset(scaledX, scaledY), dotR,
          Paint()..color = gColor.withValues(alpha: 0.85));

      // Small spiral indicator for larger galaxies
      if (distFrac < 0.4 && dotR > 3.5) {
        canvas.drawCircle(Offset(scaledX, scaledY), dotR + 2,
            Paint()
              ..color = gColor.withValues(alpha: 0.25)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.8);
      }
    }

    // Observer at centre (us)
    canvas.drawCircle(Offset(cx, cy), 6,
        Paint()..color = const Color(0xFFE0F4FF));
    canvas.drawCircle(Offset(cx, cy), 10,
        Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    drawText('관측자', Offset(cx + 8, cy - 6),
        color: const Color(0xFFE0F4FF), fs: 8);

    // Hubble sphere (radius where v=c)
    final hubbleSphereR = cx * 0.75 * (70.0 / hubbleConst);
    canvas.drawCircle(
        Offset(cx, cy),
        hubbleSphereR.clamp(10.0, cx - 4),
        Paint()
          ..color = const Color(0xFF64FF8C).withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round);
    drawText('허블 구', Offset(cx + hubbleSphereR.clamp(10.0, cx - 30) + 2, cy - 8),
        color: const Color(0xFF64FF8C), fs: 7);

    // Divider line
    canvas.drawLine(Offset(0, h), Offset(size.width, h),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1.0);
  }

  void _drawHubbleDiagram(Canvas canvas, Offset origin, double w, double h) {
    const padL = 50.0;
    const padR = 10.0;
    const padT = 18.0;
    const padB = 28.0;
    final plotW = w - padL - padR;
    final plotH = h - padT - padB;
    final ox = origin.dx + padL;
    final oy = origin.dy + padT + plotH;

    void drawText(String txt, Offset pos,
        {Color color = const Color(0xFF5A8A9A), double fs = 9}) {
      final tp = TextPainter(
        text: TextSpan(text: txt, style: TextStyle(color: color, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..strokeWidth = 0.4;
    for (int i = 0; i <= 5; i++) {
      final x = ox + plotW * i / 5;
      canvas.drawLine(Offset(x, origin.dy + padT), Offset(x, oy), gridPaint);
      final y = origin.dy + padT + plotH * i / 5;
      canvas.drawLine(Offset(ox, y), Offset(ox + plotW, y), gridPaint);
    }

    // Axes
    final axisPaint = Paint()
      ..color = const Color(0xFF5A8A9A)
      ..strokeWidth = 1.3;
    canvas.drawLine(Offset(ox, oy), Offset(ox + plotW, oy), axisPaint);
    canvas.drawLine(Offset(ox, oy), Offset(ox, origin.dy + padT), axisPaint);

    // Axis labels
    drawText('d (Mpc)', Offset(ox + plotW - 30, oy + 4));
    drawText('v (km/s)', Offset(origin.dx + 2, origin.dy + padT - 2));

    // Scale: x = 0..1000 Mpc, y = 0..H0*1000 km/s
    const dMax = 1000.0;
    final vMax = hubbleConst * dMax;

    // Tick labels
    for (int i = 1; i <= 5; i++) {
      final d = dMax * i / 5;
      final x = ox + plotW * d / dMax;
      drawText('${(d / 100).toStringAsFixed(0)}h', Offset(x - 6, oy + 4), fs: 7);
    }
    for (int i = 1; i <= 4; i++) {
      final v = vMax * i / 4;
      final y = oy - plotH * v / vMax;
      drawText('${(v / 1000).toStringAsFixed(0)}k', Offset(origin.dx + 2, y - 5), fs: 7);
    }

    // v = H₀·d line (orange)
    final hubbleLine = Path()
      ..moveTo(ox, oy)
      ..lineTo(ox + plotW, oy - plotH);
    canvas.drawPath(
        hubbleLine,
        Paint()
          ..color = const Color(0xFFFF6B35)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke);
    drawText('v=H₀d', Offset(ox + plotW * 0.55, oy - plotH * 0.62),
        color: const Color(0xFFFF6B35), fs: 8);

    // Scatter plot (seeded galaxy observations with scatter)
    final rng = math.Random(9999);
    for (int i = 0; i < 25; i++) {
      final d = rng.nextDouble() * dMax * 0.9 + dMax * 0.05;
      final noise = (rng.nextDouble() - 0.5) * hubbleConst * d * 0.18;
      final v = (hubbleConst * d + noise).clamp(0.0, vMax * 1.05);
      final px = ox + plotW * d / dMax;
      final py = oy - plotH * v / vMax;
      if (py < origin.dy + padT) {
        continue;
      }
      canvas.drawCircle(Offset(px, py), 2.5,
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7));
      // Error bar (vertical)
      final errSize = plotH * hubbleConst * d * 0.05 / vMax;
      canvas.drawLine(
          Offset(px, py - errSize),
          Offset(px, py + errSize),
          Paint()
            ..color = const Color(0xFF00D4FF).withValues(alpha: 0.35)
            ..strokeWidth = 1.0);
    }

    // Current distance marker
    final selD = distance.clamp(1.0, dMax);
    final selV = hubbleConst * selD;
    final selX = ox + plotW * selD / dMax;
    final selY = oy - plotH * selV / vMax;
    if (selY >= origin.dy + padT) {
      canvas.drawCircle(Offset(selX, selY), 5,
          Paint()..color = const Color(0xFF64FF8C));
      canvas.drawCircle(Offset(selX, selY), 7,
          Paint()
            ..color = const Color(0xFF64FF8C).withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      // Dotted cross hairs
      final dPaint = Paint()
        ..color = const Color(0xFF64FF8C).withValues(alpha: 0.3)
        ..strokeWidth = 0.8;
      for (double x2 = ox; x2 < selX; x2 += 6) {
        canvas.drawLine(Offset(x2, selY), Offset(x2 + 3, selY), dPaint);
      }
      for (double y2 = selY; y2 < oy; y2 += 6) {
        canvas.drawLine(Offset(selX, y2), Offset(selX, y2 + 3), dPaint);
      }
      drawText('v=${selV.toStringAsFixed(0)}', Offset(selX + 4, selY - 12),
          color: const Color(0xFF64FF8C), fs: 8);
    }

    // Universe age  t = 1/H0 (in Gyr, H0 in km/s/Mpc → 977.8/H0 Gyr)
    final tAge = 977.8 / hubbleConst;
    drawText('t_universe≈${tAge.toStringAsFixed(1)} Gyr',
        Offset(ox + 4, origin.dy + padT + 4),
        color: const Color(0xFF5A8A9A), fs: 8);
  }

  @override
  bool shouldRepaint(covariant _HubbleExpansionScreenPainter oldDelegate) => true;
}

class _Galaxy {
  final double normX, normY, normDist;
  const _Galaxy(this.normX, this.normY, this.normDist);
}
