import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class WavePacketScreen extends StatefulWidget {
  const WavePacketScreen({super.key});
  @override
  State<WavePacketScreen> createState() => _WavePacketScreenState();
}

class _WavePacketScreenState extends State<WavePacketScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _centralK = 5;
  double _sigmaK = 1;
  double _phaseV = 0, _groupV = 0;

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
      _phaseV = 1.0 + 0.1 * _centralK;
      _groupV = 1.0 + 0.2 * _centralK;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _centralK = 5; _sigmaK = 1.0;
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
          Text('물리 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('파동 패킷', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '파동 패킷',
          formula: 'v_g = dω/dk',
          formulaDescription: '파동 패킷의 위상 속도와 군 속도를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _WavePacketScreenPainter(
                time: _time,
                centralK: _centralK,
                sigmaK: _sigmaK,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '중심 파수 k₀',
                value: _centralK,
                min: 1,
                max: 20,
                step: 0.5,
                defaultValue: 5,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _centralK = v),
              ),
              advancedControls: [
            SimSlider(
                label: '파수 폭 Δk',
                value: _sigmaK,
                min: 0.1,
                max: 5,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _sigmaK = v),
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
          _V('위상 속도', _phaseV.toStringAsFixed(2)),
          _V('군 속도', _groupV.toStringAsFixed(2)),
          _V('Δk', _sigmaK.toStringAsFixed(1)),
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

class _WavePacketScreenPainter extends CustomPainter {
  final double time;
  final double centralK;
  final double sigmaK;

  _WavePacketScreenPainter({
    required this.time,
    required this.centralK,
    required this.sigmaK,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;
    // Layout: main wave area top 65%, spectrum bottom 30%
    final mainH = h * 0.62;
    final specY = mainH + 14;
    final specH = h - specY - 8;

    // Group velocity & phase velocity
    final omega0 = centralK * (1.0 + 0.1 * centralK);
    final vp = omega0 / centralK;
    final vg = 1.0 + 0.2 * centralK;
    final sigma = 1.0 / (sigmaK.clamp(0.1, 5.0));

    // Envelope center position (group velocity)
    final envCenterNorm = ((vg * time * 0.3) % 1.2) - 0.1;
    final envCenterX = envCenterNorm * w;

    // Grid lines (subtle)
    final gridP = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.5)..strokeWidth = 0.5;
    for (double x = 0; x < w; x += w / 8) canvas.drawLine(Offset(x, 0), Offset(x, mainH), gridP);
    final axisY = mainH * 0.5;
    canvas.drawLine(Offset(0, axisY), Offset(w, axisY),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    // Draw carrier wave ψ(x,t) = envelope(x) * cos(k0*x - ω0*t)
    final carrierPath = Path();
    final envelopePath = Path();
    final envelopePathNeg = Path();
    bool firstCarrier = true;

    for (int px = 0; px < w.toInt(); px++) {
      final xNorm = px / w;
      final xPhys = xNorm * 10.0; // physical x in [0,10]
      final envCenterPhys = envCenterNorm * 10.0;
      final dx = xPhys - envCenterPhys;
      final envelope = math.exp(-(dx * dx) / (2 * sigma * sigma));
      final carrier = math.cos(centralK * xPhys - omega0 * time * 0.5);
      final psi = envelope * carrier;

      final screenY = axisY - psi * (mainH * 0.38);
      final envY = axisY - envelope * (mainH * 0.38);
      final envYNeg = axisY + envelope * (mainH * 0.38);

      if (firstCarrier) {
        carrierPath.moveTo(px.toDouble(), screenY);
        envelopePath.moveTo(px.toDouble(), envY);
        envelopePathNeg.moveTo(px.toDouble(), envYNeg);
        firstCarrier = false;
      } else {
        carrierPath.lineTo(px.toDouble(), screenY);
        envelopePath.lineTo(px.toDouble(), envY);
        envelopePathNeg.lineTo(px.toDouble(), envYNeg);
      }
    }

    // Draw dashed orange envelope
    final dashP = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    // Manually dash the envelope
    _drawDashedPath(canvas, envelopePath, dashP, 8, 4, w, mainH);
    _drawDashedPath(canvas, envelopePathNeg, dashP, 8, 4, w, mainH);

    // Draw cyan carrier wave
    canvas.drawPath(carrierPath, Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);

    // Phase velocity indicator (small arrow on carrier crest)
    final crestNorm = ((vp * time * 0.3 - 0.5 / centralK) % 1.2) - 0.1;
    final crestX = crestNorm * w;
    if (crestX > 10 && crestX < w - 30) {
      final arrowP = Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5;
      canvas.drawLine(Offset(crestX, axisY - 12), Offset(crestX + 18, axisY - 12), arrowP);
      canvas.drawLine(Offset(crestX + 18, axisY - 12), Offset(crestX + 13, axisY - 16), arrowP);
      canvas.drawLine(Offset(crestX + 18, axisY - 12), Offset(crestX + 13, axisY - 8), arrowP);
      _drawLabel(canvas, 'vₚ', Offset(crestX + 20, axisY - 18), const Color(0xFF00D4FF), 9);
    }

    // Group velocity indicator (arrow at envelope peak)
    final grpX = envCenterX;
    if (grpX > 20 && grpX < w - 40) {
      final arrowP = Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5;
      canvas.drawLine(Offset(grpX, axisY - mainH * 0.40), Offset(grpX + 22, axisY - mainH * 0.40), arrowP);
      canvas.drawLine(Offset(grpX + 22, axisY - mainH * 0.40), Offset(grpX + 16, axisY - mainH * 0.40 - 5), arrowP);
      canvas.drawLine(Offset(grpX + 22, axisY - mainH * 0.40), Offset(grpX + 16, axisY - mainH * 0.40 + 5), arrowP);
      _drawLabel(canvas, 'vg', Offset(grpX + 24, axisY - mainH * 0.40 - 6), const Color(0xFFFF6B35), 9);
    }

    // Labels top-left
    _drawLabel(canvas, 'ψ(x,t)=A(x,t)·cos(k₀x-ω₀t)', Offset(6, 5), const Color(0xFF5A8A9A), 9);

    // Legend
    canvas.drawLine(Offset(w - 90, 10), Offset(w - 72, 10),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2);
    _drawLabel(canvas, '반송파', Offset(w - 70, 5), const Color(0xFFE0F4FF), 9);
    canvas.drawLine(Offset(w - 90, 22), Offset(w - 72, 22),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    _drawLabel(canvas, '포락선', Offset(w - 70, 17), const Color(0xFFE0F4FF), 9);

    // ---- Frequency spectrum (k-space) ----
    canvas.drawRect(Rect.fromLTWH(0, specY, w, specH),
        Paint()..color = const Color(0xFF0A0A0F));
    canvas.drawLine(Offset(0, specY + specH * 0.8), Offset(w, specY + specH * 0.8),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    _drawLabel(canvas, '주파수 스펙트럼 (k-공간)', Offset(6, specY + 2), const Color(0xFF5A8A9A), 8);

    final specBaseline = specY + specH * 0.8;
    final k0Norm = centralK / 22.0;
    final k0X = k0Norm * w;
    final specPath = Path();
    bool firstSpec = true;
    for (int px = 0; px < w.toInt(); px++) {
      final k = (px / w) * 22.0;
      final dk = k - centralK;
      final amp = math.exp(-(dk * dk) / (2 * sigmaK * sigmaK));
      final sy = specBaseline - amp * specH * 0.65;
      if (firstSpec) { specPath.moveTo(px.toDouble(), sy); firstSpec = false; }
      else specPath.lineTo(px.toDouble(), sy);
    }
    canvas.drawPath(specPath, Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);
    // Fill under spectrum
    specPath.lineTo(w, specBaseline);
    specPath.lineTo(0, specBaseline);
    specPath.close();
    canvas.drawPath(specPath, Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.08));

    // k0 marker
    if (k0X > 0 && k0X < w) {
      canvas.drawLine(Offset(k0X, specY + 2), Offset(k0X, specBaseline),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..strokeWidth = 1
            ..strokeCap = StrokeCap.round);
      _drawLabel(canvas, 'k₀', Offset(k0X + 2, specY + 2), const Color(0xFFFF6B35), 8);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashLen, double gapLen, double w, double h) {
    // Approximate dashing by sampling the path
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      bool drawing = true;
      while (dist < metric.length) {
        final end = (dist + (drawing ? dashLen : gapLen)).clamp(0.0, metric.length);
        if (drawing) { canvas.drawPath(metric.extractPath(dist, end), paint); }
        dist = end;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WavePacketScreenPainter oldDelegate) => true;
}
