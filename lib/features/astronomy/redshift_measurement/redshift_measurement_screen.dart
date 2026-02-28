import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class RedshiftMeasurementScreen extends StatefulWidget {
  const RedshiftMeasurementScreen({super.key});
  @override
  State<RedshiftMeasurementScreen> createState() => _RedshiftMeasurementScreenState();
}

class _RedshiftMeasurementScreenState extends State<RedshiftMeasurementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _redshift = 0.1;
  
  double _velocity = 0, _distanceMpc = 0;

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
      _velocity = ((math.pow(1 + _redshift, 2).toDouble() - 1) / (math.pow(1 + _redshift, 2).toDouble() + 1)) * 3e5;
      _distanceMpc = _velocity / 70;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _redshift = 0.1;
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
          Text('천문학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('적색편이 측정', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '적색편이 측정',
          formula: 'z = (λ_obs - λ_em)/λ_em',
          formulaDescription: '스펙트럼 적색편이를 이용한 후퇴 속도 측정을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _RedshiftMeasurementScreenPainter(
                time: _time,
                redshift: _redshift,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '적색편이 (z)',
                value: _redshift,
                min: 0,
                max: 5,
                step: 0.01,
                defaultValue: 0.1,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _redshift = v),
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
          _V('v', _velocity.toStringAsFixed(0) + ' km/s'),
          _V('거리', _distanceMpc.toStringAsFixed(0) + ' Mpc'),
          _V('z', _redshift.toStringAsFixed(2)),
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

class _RedshiftMeasurementScreenPainter extends CustomPainter {
  final double time;
  final double redshift;

  _RedshiftMeasurementScreenPainter({
    required this.time,
    required this.redshift,
  });

  // Convert wavelength (nm) to approximate RGB color
  Color _wavelengthToColor(double nm) {
    if (nm < 380) return const Color(0xFF6600CC);
    if (nm < 440) {
      final t = (nm - 380) / 60;
      return Color.fromARGB(255, (148 * (1 - t)).round(), 0, 211);
    }
    if (nm < 490) {
      final t = (nm - 440) / 50;
      return Color.fromARGB(255, 0, (t * 255).round(), 255);
    }
    if (nm < 510) {
      final t = (nm - 490) / 20;
      return Color.fromARGB(255, 0, 255, (255 * (1 - t)).round());
    }
    if (nm < 580) {
      final t = (nm - 510) / 70;
      return Color.fromARGB(255, (t * 255).round(), 255, 0);
    }
    if (nm < 645) {
      final t = (nm - 580) / 65;
      return Color.fromARGB(255, 255, (255 * (1 - t)).round(), 0);
    }
    if (nm <= 780) return const Color(0xFFFF0000);
    return const Color(0xFF800000);
  }

  void _drawSpectrum(Canvas canvas, Size size, double yTop, double height,
      List<double> restLines, double shift, String label, Color labelColor) {
    final left = 10.0, right = size.width - 10.0;
    final w = right - left;
    // Draw continuous visible spectrum background
    for (double x = left; x < right; x += 1) {
      final nm = 380 + (x - left) / w * (780 - 380);
      final col = _wavelengthToColor(nm);
      canvas.drawRect(
        Rect.fromLTWH(x, yTop, 1.5, height),
        Paint()..color = col.withValues(alpha: 0.7),
      );
    }
    // Draw absorption lines
    for (final rest in restLines) {
      final obsNm = rest * (1 + shift);
      if (obsNm < 380 || obsNm > 780) continue;
      final x = left + (obsNm - 380) / (780 - 380) * w;
      canvas.drawLine(
        Offset(x, yTop),
        Offset(x, yTop + height),
        Paint()
          ..color = const Color(0xFF0D1A20)
          ..strokeWidth = 2.5,
      );
      canvas.drawLine(
        Offset(x, yTop),
        Offset(x, yTop + height),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.85)
          ..strokeWidth = 1.2,
      );
    }
    // Label
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(color: labelColor, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(left, yTop - 13));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // Rest wavelengths (nm): Hα=656, Hβ=486, NaD=589
    const restLines = [486.0, 589.0, 656.0];
    const lineLabels = ['Hβ', 'Na', 'Hα'];

    final specH = size.height * 0.12;
    final refY = size.height * 0.08;
    final obsY = size.height * 0.28;

    // Reference spectrum (no shift)
    _drawSpectrum(canvas, size, refY, specH, restLines, 0.0,
        '참조 스펙트럼 (실험실)', AppColors.ink);
    // Observed spectrum (with redshift)
    _drawSpectrum(canvas, size, obsY, specH, restLines, redshift,
        '관측 스펙트럼 (z=${redshift.toStringAsFixed(2)})', const Color(0xFF00D4FF));

    // Draw shift arrows between reference and observed lines
    final left = 10.0, right = size.width - 10.0;
    final w = right - left;
    final arrowPaint = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.85)
      ..strokeWidth = 1.5;

    for (int i = 0; i < restLines.length; i++) {
      final rest = restLines[i];
      final obs = rest * (1 + redshift);
      if (obs < 380 || obs > 780) continue;
      final xRest = left + (rest - 380) / (780 - 380) * w;
      final xObs = left + (obs - 380) / (780 - 380) * w;
      final arrowY = obsY + specH + 6;
      canvas.drawLine(Offset(xRest, refY + specH + 6), Offset(xObs, arrowY), arrowPaint);
      // Arrowhead
      final angle = math.atan2(arrowY - (refY + specH + 6), xObs - xRest);
      final aSize = 5.0;
      canvas.drawLine(
        Offset(xObs, arrowY),
        Offset(xObs - aSize * math.cos(angle - 0.4), arrowY - aSize * math.sin(angle - 0.4)),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(xObs, arrowY),
        Offset(xObs - aSize * math.cos(angle + 0.4), arrowY - aSize * math.sin(angle + 0.4)),
        arrowPaint,
      );
      // Δλ label
      final delta = obs - rest;
      final ltp = TextPainter(
        text: TextSpan(
          text: 'Δ${delta.toStringAsFixed(0)}nm',
          style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ltp.paint(canvas, Offset((xRest + xObs) / 2 - ltp.width / 2, arrowY + 2));

      // Line labels above ref spectrum
      final lltp = TextPainter(
        text: TextSpan(
          text: lineLabels[i],
          style: const TextStyle(color: Color(0xFFE0F4FF), fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      lltp.paint(canvas, Offset(xRest - lltp.width / 2, refY - 11));
    }

    // Hubble diagram panel (lower half)
    final graphTop = size.height * 0.58;
    final graphH = size.height * 0.36;
    final graphLeft = 44.0;
    final graphRight = size.width - 12.0;
    final graphBottom = graphTop + graphH;

    // Background rect
    canvas.drawRect(
      Rect.fromLTRB(graphLeft, graphTop, graphRight, graphBottom),
      Paint()..color = const Color(0xFF0A1520),
    );
    canvas.drawRect(
      Rect.fromLTRB(graphLeft, graphTop, graphRight, graphBottom),
      Paint()
        ..color = const Color(0xFF1A3040)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Axes
    final axisPaint = Paint()
      ..color = const Color(0xFF5A8A9A)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(graphLeft, graphBottom), Offset(graphRight, graphBottom), axisPaint);
    canvas.drawLine(Offset(graphLeft, graphTop), Offset(graphLeft, graphBottom), axisPaint);

    // Axis labels
    void tp2(String text, Offset pos, Color col, double fs) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    tp2('v (km/s)', Offset(graphLeft + 2, graphTop + 2), const Color(0xFF5A8A9A), 9);
    tp2('z', Offset(graphRight - 10, graphBottom + 4), const Color(0xFF5A8A9A), 9);

    // Hubble line: v = H0 * d, d = z*c/H0 => v = z*c
    final maxZ = 2.0;
    final graphW = graphRight - graphLeft;
    final maxV = maxZ * 3e5 * 0.5; // scale

    final path = Path();
    bool started = false;
    for (double z = 0; z <= maxZ; z += 0.05) {
      final vRel = ((math.pow(1 + z, 2).toDouble() - 1) /
              (math.pow(1 + z, 2).toDouble() + 1)) *
          3e5;
      final x = graphLeft + (z / maxZ) * graphW;
      final y = graphBottom - (vRel / maxV).clamp(0.0, 1.0) * graphH;
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Current galaxy marker
    final curZ = redshift.clamp(0.0, maxZ);
    final curV = ((math.pow(1 + curZ, 2).toDouble() - 1) /
            (math.pow(1 + curZ, 2).toDouble() + 1)) *
        3e5;
    final markerX = graphLeft + (curZ / maxZ) * graphW;
    final markerY = graphBottom - (curV / maxV).clamp(0.0, 1.0) * graphH;
    canvas.drawCircle(
      Offset(markerX, markerY),
      5,
      Paint()..color = const Color(0xFFFF6B35),
    );
    tp2('현재 은하', Offset(markerX + 6, markerY - 8), const Color(0xFFFF6B35), 8);

    // Tick marks on x axis
    for (double z = 0; z <= maxZ; z += 0.5) {
      final x = graphLeft + (z / maxZ) * graphW;
      canvas.drawLine(Offset(x, graphBottom), Offset(x, graphBottom + 3), axisPaint);
      tp2(z.toStringAsFixed(1), Offset(x - 6, graphBottom + 5), const Color(0xFF5A8A9A), 8);
    }
    // v axis ticks
    for (double frac = 0; frac <= 1.0; frac += 0.25) {
      final y = graphBottom - frac * graphH;
      canvas.drawLine(Offset(graphLeft - 3, y), Offset(graphLeft, y), axisPaint);
      final vVal = (frac * maxV / 1000).round();
      final ltp = TextPainter(
        text: TextSpan(
          text: '${vVal}k',
          style: const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ltp.paint(canvas, Offset(graphLeft - ltp.width - 4, y - 4));
    }

    tp2('허블 다이어그램', Offset(graphLeft + graphW / 2 - 28, graphTop + 2),
        const Color(0xFF5A8A9A), 8);
  }

  @override
  bool shouldRepaint(covariant _RedshiftMeasurementScreenPainter oldDelegate) => true;
}
