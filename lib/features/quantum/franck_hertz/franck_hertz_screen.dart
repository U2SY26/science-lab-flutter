import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class FranckHertzScreen extends StatefulWidget {
  const FranckHertzScreen({super.key});
  @override
  State<FranckHertzScreen> createState() => _FranckHertzScreenState();
}

class _FranckHertzScreenState extends State<FranckHertzScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _voltage = 5;
  
  double _currentOut = 0.0; int _dips = 0;

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
      _dips = (_voltage / 4.9).floor();
      final remainder = _voltage % 4.9;
      _currentOut = (remainder / 4.9) * math.exp(-_dips * 0.3);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _voltage = 5.0;
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
          Text('양자역학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('프랑크-헤르츠 실험', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '프랑크-헤르츠 실험',
          formula: 'eV = ΔE',
          formulaDescription: '프랑크-헤르츠 실험의 전자 에너지 양자화를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _FranckHertzScreenPainter(
                time: _time,
                voltage: _voltage,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '가속 전압 (V)',
                value: _voltage,
                min: 0,
                max: 30,
                step: 0.1,
                defaultValue: 5,
                formatValue: (v) => '${v.toStringAsFixed(1)} V',
                onChanged: (v) => setState(() => _voltage = v),
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
          _V('전류', '${_currentOut.toStringAsFixed(3)} mA'),
          _V('딕 수', '$_dips'),
          _V('ΔE', '4.9 eV'),
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

class _FranckHertzScreenPainter extends CustomPainter {
  final double time;
  final double voltage;

  _FranckHertzScreenPainter({
    required this.time,
    required this.voltage,
  });

  void _drawText(Canvas canvas, String text, Offset offset,
      {double fontSize = 10, Color color = const Color(0xFFE0F4FF), bool bold = false, TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    double dx = offset.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  // Franck-Hertz I-V curve: peaks every 4.9V, each peak attenuated by collisions
  double _current(double v) {
    if (v <= 0) { return 0; }
    // Saw-tooth modulated by inelastic collision peaks
    final phase = v / 4.9;
    final frac = phase - phase.floor();
    // Suppressed at each multiple of 4.9V
    final nCollisions = phase.floor();
    final envelope = math.exp(-nCollisions * 0.25);
    // Rising ramp with sudden dip at each collision threshold
    final ramp = math.pow(math.sin(frac * math.pi / 2), 2).toDouble();
    return ramp * envelope;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    const maxV = 30.0;
    const excitationV = 4.9;

    // --- Layout: top=apparatus diagram, bottom=I-V curve ---
    final diagH = h * 0.30;
    final diagBottom = diagH;
    final curveTop = diagBottom + 10;
    final curveH = h - curveTop - 28;
    final leftMargin = 32.0;
    final rightMargin = 6.0;
    final plotW = w - leftMargin - rightMargin;
    final curveBottom = curveTop + curveH;

    // ===== Apparatus Diagram =====
    _drawText(canvas, '프랑크-헤르츠 장치', Offset(w / 2, 4),
        fontSize: 9, color: const Color(0xFF00D4FF), bold: true, align: TextAlign.center);

    final appY = diagH * 0.55;
    final appLeft = 16.0;
    final appRight = w - 16.0;
    final appW = appRight - appLeft;

    // Tube outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(appLeft, appY - 18, appW, 36), const Radius.circular(8)),
      Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(appLeft, appY - 18, appW, 36), const Radius.circular(8)),
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.2,
    );

    // Mercury vapor dots (background)
    final rng2 = math.Random(7);
    for (int i = 0; i < 12; i++) {
      final mx = appLeft + 20 + rng2.nextDouble() * (appW - 40);
      final my = appY - 10 + rng2.nextDouble() * 20;
      canvas.drawCircle(Offset(mx, my), 2.5,
          Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.25));
    }

    // Cathode (electron gun)
    final cathX = appLeft + 14;
    canvas.drawLine(Offset(cathX, appY - 14), Offset(cathX, appY + 14),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 3..strokeCap = StrokeCap.round);
    _drawText(canvas, 'K', Offset(cathX, appY + 16), fontSize: 7, color: const Color(0xFFFF6B35), align: TextAlign.center);

    // Grid (anode)
    final gridX = appLeft + appW * 0.55;
    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(Offset(gridX, appY - 14 + i * 5), Offset(gridX + 6, appY - 14 + i * 5),
          Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    }
    _drawText(canvas, 'G', Offset(gridX + 3, appY + 16), fontSize: 7, color: const Color(0xFF5A8A9A), align: TextAlign.center);

    // Collector plate
    final collX = appRight - 14;
    canvas.drawLine(Offset(collX, appY - 14), Offset(collX, appY + 14),
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 3..strokeCap = StrokeCap.round);
    _drawText(canvas, 'C', Offset(collX, appY + 16), fontSize: 7, color: const Color(0xFF64FF8C), align: TextAlign.center);

    // Electron animation: travel from cathode to collector, collide at Hg atoms
    final nDips = (voltage / excitationV).floor();
    final eProgress = (time * 0.5) % 1.0;
    final eX = cathX + (collX - cathX) * eProgress;
    final eY = appY + math.sin(eProgress * math.pi * 4) * 4;
    // Draw electron
    canvas.drawCircle(Offset(eX, eY), 3.5,
        Paint()..color = const Color(0xFF00D4FF));
    // Collision flash at multiples of 4.9V within tube
    for (int d = 1; d <= nDips; d++) {
      final collFrac = d * excitationV / voltage;
      if (collFrac < 1.0) {
        final collisionX = cathX + (collX - cathX) * collFrac;
        final flashAlpha = 0.3 + 0.7 * math.sin(time * 3 + d).abs();
        canvas.drawCircle(Offset(collisionX, appY), 6,
            Paint()..color = const Color(0xFFFFFF80).withValues(alpha: flashAlpha));
        // Photon burst lines
        for (int li = 0; li < 4; li++) {
          final ang = li * math.pi / 2 + time;
          canvas.drawLine(
            Offset(collisionX + 7 * math.cos(ang), appY + 7 * math.sin(ang)),
            Offset(collisionX + 12 * math.cos(ang), appY + 12 * math.sin(ang)),
            Paint()..color = const Color(0xFFFFFF80).withValues(alpha: flashAlpha * 0.7)..strokeWidth = 1,
          );
        }
      }
    }

    // Voltage label
    _drawText(canvas, 'V=${voltage.toStringAsFixed(1)}V', Offset(w / 2, appY - 22),
        fontSize: 8, color: const Color(0xFF5A8A9A), align: TextAlign.center);

    // ===== I-V Curve =====
    _drawText(canvas, 'I-V 특성 곡선', Offset(w / 2, curveTop - 8),
        fontSize: 8, color: const Color(0xFF5A8A9A), align: TextAlign.center);

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..strokeWidth = 1;
    canvas.drawLine(Offset(leftMargin, curveTop), Offset(leftMargin, curveBottom), axisPaint);
    canvas.drawLine(Offset(leftMargin, curveBottom), Offset(w - rightMargin, curveBottom), axisPaint);
    _drawText(canvas, 'I', Offset(4, curveTop + curveH / 2 - 5), fontSize: 8, color: const Color(0xFF5A8A9A));
    _drawText(canvas, 'V(V)', Offset(w - rightMargin - 16, curveBottom + 4), fontSize: 7, color: const Color(0xFF5A8A9A));

    // X-axis: voltage ticks every 4.9V
    for (double v = 0; v <= maxV; v += excitationV) {
      final tx = leftMargin + (v / maxV) * plotW;
      canvas.drawLine(Offset(tx, curveBottom - 3), Offset(tx, curveBottom + 3), axisPaint);
      _drawText(canvas, v.toStringAsFixed(1), Offset(tx, curveBottom + 5),
          fontSize: 6, color: const Color(0xFF5A8A9A).withValues(alpha: 0.7), align: TextAlign.center);
      // Vertical dashed lines at peaks
      if (v > 0) {
        final dashPaint = Paint()
          ..color = const Color(0xFF5A8A9A).withValues(alpha: 0.25)
          ..strokeWidth = 0.8;
        canvas.drawLine(Offset(tx, curveTop), Offset(tx, curveBottom), dashPaint);
        _drawText(canvas, '${v.toStringAsFixed(1)}V', Offset(tx, curveTop + 2),
            fontSize: 6, color: const Color(0xFF5A8A9A).withValues(alpha: 0.5), align: TextAlign.center);
      }
    }

    // Draw I-V curve (quantum: periodic dips)
    const nPts = 150;
    final curvePaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final curvePath = Path();
    for (int i = 0; i <= nPts; i++) {
      final v = maxV * i / nPts;
      final curr = _current(v);
      final px = leftMargin + (v / maxV) * plotW;
      final py = curveBottom - curr * curveH * 0.88;
      if (i == 0) { curvePath.moveTo(px, py); } else { curvePath.lineTo(px, py); }
    }
    canvas.drawPath(curvePath, curvePaint);

    // Classic prediction: monotonically rising (orange dashed)
    final classicPath = Path();
    for (int i = 0; i <= nPts; i++) {
      final v = maxV * i / nPts;
      final curr = (v / maxV) * 0.9;
      final px = leftMargin + (v / maxV) * plotW;
      final py = curveBottom - curr * curveH * 0.88;
      if (i == 0) { classicPath.moveTo(px, py); } else { classicPath.lineTo(px, py); }
    }
    final dashEffect = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(classicPath, dashEffect);

    // Current voltage indicator
    if (voltage > 0) {
      final indX = leftMargin + (voltage / maxV) * plotW;
      final indCurr = _current(voltage);
      final indY = curveBottom - indCurr * curveH * 0.88;
      canvas.drawLine(Offset(indX, curveBottom), Offset(indX, curveTop),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.35)..strokeWidth = 1);
      canvas.drawCircle(Offset(indX, indY), 5,
          Paint()..color = const Color(0xFFFF6B35));
    }

    // Legend
    final legY = curveBottom - 18.0;
    canvas.drawLine(Offset(leftMargin + 4, legY), Offset(leftMargin + 18, legY),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2);
    _drawText(canvas, '양자 예측', Offset(leftMargin + 22, legY - 5), fontSize: 7, color: const Color(0xFF00D4FF));
    canvas.drawLine(Offset(leftMargin + 4, legY + 10), Offset(leftMargin + 18, legY + 10), dashEffect);
    _drawText(canvas, '고전 예측', Offset(leftMargin + 22, legY + 5), fontSize: 7, color: const Color(0xFFFF6B35));

    // Dip count
    _drawText(canvas, 'Hg 5.4eV 들뜸  |  딥 $nDips개  |  Δ=${excitationV}eV',
        Offset(w / 2, h - 6), fontSize: 7, color: const Color(0xFF5A8A9A), align: TextAlign.center);
  }

  @override
  bool shouldRepaint(covariant _FranckHertzScreenPainter oldDelegate) => true;
}
