import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CosmologicalRedshiftScreen extends StatefulWidget {
  const CosmologicalRedshiftScreen({super.key});
  @override
  State<CosmologicalRedshiftScreen> createState() => _CosmologicalRedshiftScreenState();
}

class _CosmologicalRedshiftScreenState extends State<CosmologicalRedshiftScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _redshiftZ = 1;
  double _scaleFactor = 0, _lookbackTime = 0;

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
      _scaleFactor = 1.0 / (1 + _redshiftZ);
      _lookbackTime = 13.8 * (1 - _scaleFactor);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _redshiftZ = 1.0;
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
          const Text('우주론적 적색편이', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '우주론적 적색편이',
          formula: '1+z = a(t_obs)/a(t_em)',
          formulaDescription: '우주론적 적색편이와 도플러 적색편이를 구별합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CosmologicalRedshiftScreenPainter(
                time: _time,
                redshiftZ: _redshiftZ,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '적색편이 z',
                value: _redshiftZ,
                min: 0,
                max: 10,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => 'z = ${v.toStringAsFixed(1)}',
                onChanged: (v) => setState(() => _redshiftZ = v),
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
          _V('z', _redshiftZ.toStringAsFixed(1)),
          _V('척도 인자', _scaleFactor.toStringAsFixed(3)),
          _V('되돌림 시간', '${_lookbackTime.toStringAsFixed(1)} Gyr'),
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

class _CosmologicalRedshiftScreenPainter extends CustomPainter {
  final double time;
  final double redshiftZ;

  _CosmologicalRedshiftScreenPainter({
    required this.time,
    required this.redshiftZ,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final z = redshiftZ.clamp(0.0, 10.0);
    final scaleFactor = 1.0 / (1.0 + z); // a = 1/(1+z)

    // ===== TOP: Universe expansion panel (top 55%) =====
    final uniH = h * 0.52;
    final uniCy = uniH / 2;

    // Grid of galaxies that expand outward
    final rng = math.Random(999);
    const int nGal = 9;
    final List<double> galX0 = List.generate(nGal, (_) => (rng.nextDouble() - 0.5));
    final List<double> galY0 = List.generate(nGal, (_) => (rng.nextDouble() - 0.5));
    final List<int> galColors = [
      0xFF8888FF, 0xFF99AAFF, 0xFF6677EE, 0xFFAABBFF,
      0xFF7788EE, 0xFF55AAFF, 0xFF8899FF, 0xFF99BBFF, 0xFF7799EE,
    ];

    // Observer galaxy at center
    final centX = w * 0.5;
    final centY = uniCy;

    // Expansion: scale positions by 1/scaleFactor (farther as z increases → bigger separation)
    final expansionFactor = 1.0 / scaleFactor; // grows with z
    final maxSpread = math.min(w, uniH) * 0.42;

    for (int i = 0; i < nGal; i++) {
      // Animate slow outward drift
      final drift = (time * 0.06 * z.clamp(0.1, 5.0)) % 1.0;
      final ex = galX0[i] * maxSpread * (expansionFactor.clamp(1.0, 5.0) + drift * 0.3);
      final ey = galY0[i] * maxSpread * (expansionFactor.clamp(1.0, 5.0) + drift * 0.3);
      final gx = centX + ex;
      final gy = centY + ey;

      if (gx < 4 || gx > w - 4 || gy < 4 || gy > uniH - 4) continue;

      // Distance → redshift color
      final dist = math.sqrt(ex * ex + ey * ey);
      final t = (dist / maxSpread).clamp(0.0, 1.0);
      final galColor = Color(galColors[i]);
      final gr = ((galColor.r * 255.0).round() & 0xff);
      final gg = ((galColor.g * 255.0).round() & 0xff);
      final gb = ((galColor.b * 255.0).round() & 0xff);
      // Redshift tint: more distant = more red
      final redTint = Color.fromARGB(
        255,
        (gr + t * (220 - gr)).toInt().clamp(0, 255),
        (gg * (1.0 - t * 0.7)).toInt().clamp(0, 255),
        (gb * (1.0 - t * 0.9)).toInt().clamp(0, 255),
      );

      // Draw galaxy as small spiral approximation
      _drawGalaxy(canvas, Offset(gx, gy), 5.0, redTint);

      // Arrow from center
      if (dist > 10) {
        final ux = ex / dist, uy = ey / dist;
        canvas.drawLine(
          Offset(centX + ux * 12, centY + uy * 12),
          Offset(gx - ux * 8, gy - uy * 8),
          Paint()
            ..color = redTint.withValues(alpha: 0.25 + t * 0.35)
            ..strokeWidth = 0.8,
        );
      }
    }

    // Observer galaxy
    _drawGalaxy(canvas, Offset(centX, centY), 7.0, const Color(0xFF00D4FF));
    _drawLabel(canvas, '관측자', Offset(centX + 9, centY - 5), 8, AppColors.accent);

    // z label
    _drawLabel(canvas, 'z = ${z.toStringAsFixed(1)}  a = ${scaleFactor.toStringAsFixed(3)}',
        Offset(w * 0.06, uniH - 14), 10, AppColors.muted);
    _drawLabel(canvas, '은하 팽창', Offset(w * 0.44, 7), 10, AppColors.accent);

    // Divider
    canvas.drawLine(Offset(0, uniH), Offset(w, uniH),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1.0);

    // ===== BOTTOM: Spectrum panel (bottom 45%) =====
    final specTop = uniH + 4.0;
    final specH = h - specTop - 4.0;
    final specW = w - 20.0;
    final specLeft = 10.0;
    final specBottom = specTop + specH * 0.52;
    final barH = specH * 0.22;

    _drawLabel(canvas, '스펙트럼 비교', Offset(specLeft, specTop + 2), 9, AppColors.muted);

    // Emitted spectrum (blue/violet)
    _drawSpectrum(canvas,
        Rect.fromLTWH(specLeft, specTop + 14, specW, barH),
        0.0, '방출 시 (청색)');

    // Observed spectrum (redshifted)
    _drawSpectrum(canvas,
        Rect.fromLTWH(specLeft, specTop + 14 + barH + 6, specW, barH),
        z, '수신 시 (적색편이)');

    // Lyman alpha line indicator
    // Lyman-alpha rest wavelength: 121.6 nm → visible at z≈2: 364nm (UV to optical)
    final lymanRestFrac = 0.18; // position on bar
    final lymanObsFrac = lymanRestFrac * (1 + z);
    final lyRestX = specLeft + lymanRestFrac * specW;
    final lyObsX = specLeft + lymanObsFrac.clamp(0.0, 1.0) * specW;

    canvas.drawLine(
      Offset(lyRestX, specTop + 14),
      Offset(lyRestX, specTop + 14 + barH),
      Paint()..color = Colors.white.withValues(alpha: 0.8)..strokeWidth = 1.5,
    );
    if (lymanObsFrac <= 1.0) {
      canvas.drawLine(
        Offset(lyObsX, specTop + 14 + barH + 6),
        Offset(lyObsX, specTop + 14 + barH * 2 + 6),
        Paint()..color = Colors.white.withValues(alpha: 0.8)..strokeWidth = 1.5,
      );
      canvas.drawLine(
        Offset(lyRestX, specTop + 14 + barH + 3),
        Offset(lyObsX, specTop + 14 + barH + 3),
        Paint()
          ..color = const Color(0xFF64FF8C).withValues(alpha: 0.7)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );
      _drawLabel(canvas, 'Ly-α', Offset(lyObsX - 8, specTop + 14 + barH * 2 + 7), 8,
          const Color(0xFF64FF8C));
    }

    // Hubble diagram section
    final hubbleTop = specBottom + barH + 22.0;
    final hubbleH = h - hubbleTop - 6.0;
    if (hubbleH > 20) {
      _drawLabel(canvas, 'z vs 거리', Offset(specLeft, hubbleTop), 8, AppColors.muted);
      final graphRect = Rect.fromLTWH(specLeft + 20, hubbleTop + 10, specW - 24, hubbleH - 10);
      canvas.drawRect(graphRect, Paint()..color = const Color(0xFF0A1520));
      // Axes
      canvas.drawLine(Offset(graphRect.left, graphRect.bottom),
          Offset(graphRect.right, graphRect.bottom),
          Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.8);
      canvas.drawLine(Offset(graphRect.left, graphRect.top),
          Offset(graphRect.left, graphRect.bottom),
          Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.8);
      // Hubble line z ≈ H0*d/c
      final hubblePath = Path();
      hubblePath.moveTo(graphRect.left, graphRect.bottom);
      hubblePath.lineTo(graphRect.right, graphRect.top);
      canvas.drawPath(hubblePath,
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..strokeWidth = 1.2);
      // Current z marker
      final markerX = graphRect.left + (z / 10.0).clamp(0.0, 1.0) * graphRect.width;
      canvas.drawCircle(Offset(markerX, graphRect.bottom - (z / 10.0).clamp(0.0, 1.0) * graphRect.height),
          3.5, Paint()..color = const Color(0xFFFF6B35));
    }
  }

  void _drawGalaxy(Canvas canvas, Offset center, double r, Color color) {
    canvas.drawCircle(center, r * 0.4, Paint()..color = color.withValues(alpha: 0.9));
    for (int arm = 0; arm < 2; arm++) {
      final path = Path();
      for (int j = 0; j <= 20; j++) {
        final t = j / 20.0;
        final ang = arm * math.pi + t * math.pi * 1.5;
        final dist = t * r;
        final px = center.dx + dist * math.cos(ang);
        final py = center.dy + dist * math.sin(ang) * 0.5;
        if (j == 0) { path.moveTo(px, py); } else { path.lineTo(px, py); }
      }
      canvas.drawPath(path,
          Paint()
            ..color = color.withValues(alpha: 0.5)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke);
    }
  }

  void _drawSpectrum(Canvas canvas, Rect rect, double z, String label) {
    // Rainbow spectrum stretched by (1+z)
    final nBands = 80;
    for (int i = 0; i < nBands; i++) {
      final frac = i / nBands.toDouble();
      // Map to wavelength: 380nm (violet) to 700nm (red), shifted by (1+z)
      final obsWav = 380 + frac * 320; // nm as received
      final emWav = obsWav / (1.0 + z); // original emitted wavelength
      final Color c = _wavelengthToColor(emWav, z);
      canvas.drawRect(
        Rect.fromLTWH(rect.left + frac * rect.width, rect.top, rect.width / nBands + 1, rect.height),
        Paint()..color = c,
      );
    }
    canvas.drawRect(rect, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    _drawLabel(canvas, label, Offset(rect.right + 3, rect.top + rect.height / 3), 8, AppColors.muted);
  }

  Color _wavelengthToColor(double wav, double z) {
    // Rough wavelength to RGB
    if (wav < 380) return const Color(0xFF440088).withValues(alpha: 0.6);
    if (wav < 440) {
      final t = (wav - 380) / 60;
      return Color.fromARGB(200, (t * 100).toInt(), 0, 255);
    }
    if (wav < 490) {
      final t = (wav - 440) / 50;
      return Color.fromARGB(200, 0, (t * 255).toInt(), 255);
    }
    if (wav < 510) {
      final t = (wav - 490) / 20;
      return Color.fromARGB(200, 0, 255, (255 - t * 255).toInt());
    }
    if (wav < 580) {
      final t = (wav - 510) / 70;
      return Color.fromARGB(200, (t * 255).toInt(), 255, 0);
    }
    if (wav < 645) {
      final t = (wav - 580) / 65;
      return Color.fromARGB(200, 255, (255 - t * 255).toInt(), 0);
    }
    if (wav <= 700) return const Color(0xFFFF0000).withValues(alpha: 0.8);
    // Redshifted into infrared → dark red
    final t = ((wav - 700) / 300).clamp(0.0, 1.0);
    return Color.fromARGB((180 - t * 150).toInt(), 180, 0, 0);
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _CosmologicalRedshiftScreenPainter oldDelegate) => true;
}
