import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class OrographicRainfallScreen extends StatefulWidget {
  const OrographicRainfallScreen({super.key});
  @override
  State<OrographicRainfallScreen> createState() => _OrographicRainfallScreenState();
}

class _OrographicRainfallScreenState extends State<OrographicRainfallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _mountainH = 2000.0;
  double _moisture = 0.7;
  double _windwardRain = 0, _leewardRain = 0;

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
      _windwardRain = _mountainH / 1000 * _moisture * 500;
      _leewardRain = _windwardRain * 0.2;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _mountainH = 2000.0;
      _moisture = 0.7;
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
          const Text('지형성 강수', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '지형성 강수',
          formulaDescription: '산이 공기를 상승시켜 강수를 일으키는 과정입니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _OrographicRainfallScreenPainter(
                time: _time,
                mountainH: _mountainH,
                moisture: _moisture,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '산 높이 (m)',
                value: _mountainH,
                min: 500.0,
                max: 5000.0,
                defaultValue: 2000.0,
                formatValue: (v) => '${v.toInt()} m',
                onChanged: (v) => setState(() => _mountainH = v),
              ),
              advancedControls: [
            SimSlider(
                label: '습도',
                value: _moisture,
                min: 0.1,
                max: 1.0,
                step: 0.05,
                defaultValue: 0.7,
                formatValue: (v) => '${(v * 100).toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _moisture = v),
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
          _V('바람받이 강수', '${_windwardRain.toStringAsFixed(0)} mm'),
          _V('비 그늘 강수', '${_leewardRain.toStringAsFixed(0)} mm'),
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

class _OrographicRainfallScreenPainter extends CustomPainter {
  final double time;
  final double mountainH;
  final double moisture;

  _OrographicRainfallScreenPainter({
    required this.time,
    required this.mountainH,
    required this.moisture,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, {Color color = const Color(0xFF5A8A9A), double fontSize = 9, bool centered = true}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = centered ? pos.dx - tp.width / 2 : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy - tp.height / 2));
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    final dx = to.dx - from.dx, dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final ux = dx / len, uy = dy / len;
    const as_ = 7.0;
    final p1 = Offset(to.dx - as_ * (ux - uy * 0.5), to.dy - as_ * (uy + ux * 0.5));
    final p2 = Offset(to.dx - as_ * (ux + uy * 0.5), to.dy - as_ * (uy - ux * 0.5));
    final path = Path()..moveTo(to.dx, to.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;
    final heightFrac = (mountainH - 500) / 4500; // 0..1
    final groundY = h * 0.72;
    final peakH = h * 0.18 + heightFrac * h * 0.28; // mountain peak height from ground
    final mountainPeakY = groundY - peakH;

    // Sky background: left moist (blue) vs right dry (orange-brown)
    final skyLeft = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.center,
        colors: [
          Color.lerp(const Color(0xFF0A1A30), const Color(0xFF1A3A6A), moisture)!,
          const Color(0xFF0D1A20),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w * 0.5, groundY));
    canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.5, groundY), skyLeft);

    final skyRight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.center,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF0D1A20),
          Color.lerp(const Color(0xFF1A0D06), const Color(0xFF2A1508), heightFrac)!,
        ],
      ).createShader(Rect.fromLTWH(w * 0.5, 0, w * 0.5, groundY));
    canvas.drawRect(Rect.fromLTWH(w * 0.5, 0, w * 0.5, groundY), skyRight);

    // Sea on the left
    final seaRect = Rect.fromLTWH(0, groundY, w * 0.15, h - groundY);
    canvas.drawRect(seaRect, Paint()..color = const Color(0xFF0A2A45));
    _drawLabel(canvas, '바다', Offset(w * 0.075, groundY + (h - groundY) * 0.5), color: const Color(0xFF3A7AAA), fontSize: 9);

    // Mountain shape
    final mountainX = w * 0.45; // mountain center x
    final slopeW = w * 0.28;    // half-width of mountain base

    final mountainPath = Path()
      ..moveTo(mountainX - slopeW, groundY)
      ..lineTo(mountainX, mountainPeakY)
      ..lineTo(mountainX + slopeW, groundY)
      ..close();

    canvas.drawPath(mountainPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF3A3A4A), const Color(0xFF2A2A3A)],
      ).createShader(Rect.fromLTWH(mountainX - slopeW, mountainPeakY, slopeW * 2, peakH)));

    // Snow cap if high enough
    if (mountainH > 2500) {
      final snowH = peakH * ((mountainH - 2500) / 2500).clamp(0.0, 0.4);
      final snowPath = Path()
        ..moveTo(mountainX - slopeW * snowH / peakH, mountainPeakY + snowH)
        ..lineTo(mountainX, mountainPeakY)
        ..lineTo(mountainX + slopeW * snowH / peakH, mountainPeakY + snowH)
        ..close();
      canvas.drawPath(snowPath, Paint()..color = const Color(0xFFDDEEFF).withValues(alpha: 0.85));
    }

    // Ground / terrain
    final groundPath = Path()
      ..moveTo(0, groundY)
      ..lineTo(mountainX - slopeW, groundY)
      ..lineTo(mountainX, mountainPeakY)
      ..lineTo(mountainX + slopeW, groundY)
      ..lineTo(w, groundY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(groundPath, Paint()..color = const Color(0xFF1A1A0A));

    // Vegetation on windward side (left slope) - green
    if (moisture > 0.3) {
      for (int i = 0; i < 5; i++) {
        final tx = mountainX - slopeW + slopeW * 0.15 * i;
        final tFrac = i / 5.0;
        final ty = groundY - (groundY - mountainPeakY) * tFrac * 0.9;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(tx, ty - 4), width: 14, height: 10),
          Paint()..color = const Color(0xFF2A6A1A).withValues(alpha: 0.7),
        );
      }
    }

    // Dry vegetation on leeward side (right slope) - brown/sparse
    for (int i = 0; i < 3; i++) {
      final tx = mountainX + slopeW * 0.2 + slopeW * 0.25 * i;
      final tFrac = i / 3.0;
      final ty = groundY - (groundY - mountainPeakY) * (1 - tFrac) * 0.5;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(tx, ty - 3), width: 10, height: 6),
        Paint()..color = const Color(0xFF5A3A0A).withValues(alpha: 0.5),
      );
    }

    // Cloud (lifting condensation level)
    final lclFrac = (1 - moisture) * 0.5 + 0.15; // lower with more moisture
    final cloudBaseY = groundY - peakH * (1 - lclFrac);
    final cloudX = mountainX - slopeW * 0.4;
    final cloudW = slopeW * 0.7 + moisture * slopeW * 0.3;
    final cloudAlpha = moisture.clamp(0.2, 0.9);

    // Cloud body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cloudX, cloudBaseY - 8), width: cloudW, height: 24 + moisture * 20),
      Paint()..color = const Color(0xFFCCDDEE).withValues(alpha: cloudAlpha * 0.5),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cloudX - cloudW * 0.2, cloudBaseY - 18), width: cloudW * 0.6, height: 20),
      Paint()..color = const Color(0xFFCCDDEE).withValues(alpha: cloudAlpha * 0.45),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cloudX + cloudW * 0.2, cloudBaseY - 14), width: cloudW * 0.5, height: 16),
      Paint()..color = const Color(0xFFCCDDEE).withValues(alpha: cloudAlpha * 0.4),
    );

    // Cloud base line (LCL)
    canvas.drawLine(
      Offset(mountainX - slopeW, cloudBaseY),
      Offset(mountainX, cloudBaseY),
      Paint()..color = const Color(0xFF4488AA).withValues(alpha: 0.4)..strokeWidth = 0.8..style = PaintingStyle.stroke,
    );
    _drawLabel(canvas, '구름 저면 (LCL)', Offset(mountainX - slopeW * 0.5, cloudBaseY - 9), color: const Color(0xFF4488AA), fontSize: 7);

    // Rain drops on windward side (animated)
    final rainCount = (moisture * 12).toInt();
    final rainPaint = Paint()..color = const Color(0xFF4488FF).withValues(alpha: 0.7)..strokeWidth = 1.2..style = PaintingStyle.stroke;
    final rng = math.Random(7);
    for (int i = 0; i < rainCount; i++) {
      final rx = mountainX - slopeW + rng.nextDouble() * slopeW * 0.85;
      final ry0 = cloudBaseY + (time * 60 + rng.nextDouble() * 80) % (groundY - cloudBaseY - 4);
      canvas.drawLine(Offset(rx, ry0), Offset(rx - 2, ry0 + 8), rainPaint);
    }

    // Wind arrows coming from the left
    final windPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 4; i++) {
      final wy = groundY * 0.2 + i * groundY * 0.18;
      final wx0 = w * 0.04 + (time * 30) % (mountainX - slopeW - w * 0.04);
      _drawArrow(canvas, Offset(wx0, wy), Offset(wx0 + 28, wy), windPaint);
    }

    // Adiabatic lapse rate labels
    _drawLabel(canvas, '건조단열\n-9.8°C/km', Offset(mountainX - slopeW * 0.15, groundY - peakH * 0.55), color: const Color(0xFFFF6B35).withValues(alpha: 0.8), fontSize: 7);
    _drawLabel(canvas, '습윤단열\n-6°C/km', Offset(mountainX - slopeW * 0.55, groundY - peakH * 0.7), color: const Color(0xFF4488FF).withValues(alpha: 0.8), fontSize: 7);

    // Labels
    _drawLabel(canvas, '${mountainH.toInt()} m', Offset(mountainX - 18, mountainPeakY - 10), color: const Color(0xFFE0F4FF), fontSize: 9);
    _drawLabel(canvas, '바람받이 (다우)', Offset(mountainX - slopeW * 0.55, groundY + 14), color: const Color(0xFF4488FF), fontSize: 8);
    _drawLabel(canvas, '비그늘 (건조)', Offset(mountainX + slopeW * 0.6, groundY + 14), color: const Color(0xFFFF6B35), fontSize: 8);
    _drawLabel(canvas, '습도 ${(moisture * 100).toInt()}%', Offset(w * 0.08, h * 0.1), color: const Color(0xFF4488AA), fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _OrographicRainfallScreenPainter oldDelegate) => true;
}
