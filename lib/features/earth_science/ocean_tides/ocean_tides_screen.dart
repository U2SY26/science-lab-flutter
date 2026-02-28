import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class OceanTidesScreen extends StatefulWidget {
  const OceanTidesScreen({super.key});
  @override
  State<OceanTidesScreen> createState() => _OceanTidesScreenState();
}

class _OceanTidesScreenState extends State<OceanTidesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _moonPhase = 0;
  
  double _tidalRange = 2.0; String _tideType = "사리";

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
      final moonAngle = _moonPhase * math.pi / 180;
      _tidalRange = 1.0 + math.cos(moonAngle).abs();
      _tideType = (_moonPhase % 180).abs() < 30 || (_moonPhase % 180).abs() > 150 ? "사리" : "조금";
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _moonPhase = 0.0;
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
          const Text('조석 패턴', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '조석 패턴',
          formula: 'F = GMm/r²',
          formulaDescription: '달과 태양의 중력에 의한 조석 패턴을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _OceanTidesScreenPainter(
                time: _time,
                moonPhase: _moonPhase,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '달 위상 (°)',
                value: _moonPhase,
                min: 0,
                max: 360,
                step: 1,
                defaultValue: 0,
                formatValue: (v) => v.toStringAsFixed(0) + '°',
                onChanged: (v) => setState(() => _moonPhase = v),
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
          _V('조차', _tidalRange.toStringAsFixed(2) + ' m'),
          _V('유형', _tideType),
          _V('달 위상', _moonPhase.toStringAsFixed(0) + '°'),
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

class _OceanTidesScreenPainter extends CustomPainter {
  final double time;
  final double moonPhase;

  _OceanTidesScreenPainter({
    required this.time,
    required this.moonPhase,
  });

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final dir = (end - start);
    final len = dir.distance;
    if (len < 1) return;
    final unit = dir / len;
    final perp = Offset(-unit.dy, unit.dx);
    final arrowSize = 6.0;
    final tip = end;
    final p1 = tip - unit * arrowSize + perp * arrowSize * 0.5;
    final p2 = tip - unit * arrowSize - perp * arrowSize * 0.5;
    final path = Path()..moveTo(tip.dx, tip.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final cx = size.width / 2;
    final topH = size.height * 0.62;
    final cy = topH * 0.5;

    // Moon orbit animation
    final moonAngle = moonPhase * math.pi / 180 + time * 0.3;
    final orbitR = math.min(cx, cy) * 0.78;
    final moonX = cx + orbitR * math.cos(moonAngle);
    final moonY = cy + orbitR * math.sin(moonAngle);

    // Earth radius
    final earthR = math.min(cx, cy) * 0.22;

    // Tidal bulge: stronger when moon is closer to 0/180 deg (spring tide)
    final phaseRad = moonPhase * math.pi / 180;
    final tidalBulge = earthR * (0.18 + 0.10 * math.cos(phaseRad).abs());

    // Draw tidal water ellipse (bulges toward moon and away)
    final waterPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final waterStroke = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw rotated ellipse via transform
    final bulgeA = earthR + tidalBulge;
    final bulgeB = earthR - tidalBulge * 0.4;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(moonAngle);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: bulgeA * 2, height: bulgeB * 2), waterPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: bulgeA * 2, height: bulgeB * 2), waterStroke);
    canvas.restore();

    // Draw Earth
    final earthPaint = Paint()
      ..color = const Color(0xFF1A5C2A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), earthR, earthPaint);
    final earthStroke = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), earthR, earthStroke);

    // Earth label
    final earthLabel = TextPainter(
      text: const TextSpan(text: '지구', style: TextStyle(color: Color(0xFFE0F4FF), fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    earthLabel.paint(canvas, Offset(cx - earthLabel.width / 2, cy - earthLabel.height / 2));

    // Draw Moon
    final moonPaint = Paint()..color = const Color(0xFFCCCCCC)..style = PaintingStyle.fill;
    final moonR = earthR * 0.28;
    canvas.drawCircle(Offset(moonX, moonY), moonR, moonPaint);
    final moonLabel = TextPainter(
      text: const TextSpan(text: '달', style: TextStyle(color: Color(0xFFE0F4FF), fontSize: 8)),
      textDirection: TextDirection.ltr,
    )..layout();
    moonLabel.paint(canvas, Offset(moonX - moonLabel.width / 2, moonY - moonLabel.height / 2));

    // Gravity arrows from moon toward earth
    final arrowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final gravDir = (Offset(cx, cy) - Offset(moonX, moonY));
    final gravLen = gravDir.distance;
    final gravUnit = gravDir / gravLen;
    final arrowStart = Offset(moonX, moonY) + gravUnit * (moonR + 3);
    final arrowEnd = Offset(moonX, moonY) + gravUnit * (moonR + 22);
    _drawArrow(canvas, arrowStart, arrowEnd, arrowPaint);

    // Spring/Neap tide label
    final isSyzygy = (moonPhase % 180).abs() < 30 || (moonPhase % 180).abs() > 150;
    final tideLabel = TextPainter(
      text: TextSpan(
        text: isSyzygy ? '사리 (대조)' : '조금 (소조)',
        style: TextStyle(
          color: isSyzygy ? const Color(0xFFFF6B35) : const Color(0xFF00D4FF),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tideLabel.paint(canvas, Offset(cx - tideLabel.width / 2, 8));

    // Tidal cycle graph (bottom area)
    final graphTop = topH + 8;
    final graphH = size.height - graphTop - 8;
    if (graphH > 20) {
      final graphL = 16.0;
      final graphR = size.width - 16;
      final graphW = graphR - graphL;
      final graphMid = graphTop + graphH / 2;

      // Axis
      final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1;
      canvas.drawLine(Offset(graphL, graphMid), Offset(graphR, graphMid), axisPaint);
      canvas.drawLine(Offset(graphL, graphTop + 2), Offset(graphL, graphTop + graphH - 2), axisPaint);

      // Axis labels
      final xLabel = TextPainter(
        text: const TextSpan(text: '24h', style: TextStyle(color: Color(0xFF5A8A9A), fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      xLabel.paint(canvas, Offset(graphR - xLabel.width - 2, graphMid - xLabel.height - 1));

      final yLabel = TextPainter(
        text: const TextSpan(text: '해수면', style: TextStyle(color: Color(0xFF5A8A9A), fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      yLabel.paint(canvas, Offset(graphL + 2, graphTop + 2));

      // Tidal curve: two cycles in 24h (semidiurnal)
      final tidalAmplitude = graphH * 0.36 * (0.6 + 0.4 * math.cos(phaseRad).abs());
      final curvePaint = Paint()
        ..color = const Color(0xFF00D4FF)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final curvePath = Path();
      for (int i = 0; i <= 120; i++) {
        final t = i / 120.0;
        final x = graphL + t * graphW;
        final y = graphMid - tidalAmplitude * math.sin(t * 4 * math.pi + time * 0.5);
        if (i == 0) { curvePath.moveTo(x, y); } else { curvePath.lineTo(x, y); }
      }
      canvas.drawPath(curvePath, curvePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OceanTidesScreenPainter oldDelegate) => true;
}
