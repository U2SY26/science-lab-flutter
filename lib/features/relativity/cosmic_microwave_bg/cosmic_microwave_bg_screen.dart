import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CosmicMicrowaveBgScreen extends StatefulWidget {
  const CosmicMicrowaveBgScreen({super.key});
  @override
  State<CosmicMicrowaveBgScreen> createState() => _CosmicMicrowaveBgScreenState();
}

class _CosmicMicrowaveBgScreenState extends State<CosmicMicrowaveBgScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _tempCmb = 2.725;
  
  double _peakFreq = 160, _anisotropy = 0.00003;

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
      _peakFreq = 58.8 * _tempCmb;
      _anisotropy = 0.00003 * (_tempCmb / 2.725);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _tempCmb = 2.725;
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
          const Text('우주 마이크로파 배경', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '우주 마이크로파 배경',
          formula: 'T = 2.725 K',
          formulaDescription: 'CMB 흑체 복사와 온도 이방성을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CosmicMicrowaveBgScreenPainter(
                time: _time,
                tempCmb: _tempCmb,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'CMB 온도 (K)',
                value: _tempCmb,
                min: 2,
                max: 5,
                step: 0.001,
                defaultValue: 2.725,
                formatValue: (v) => v.toStringAsFixed(3) + ' K',
                onChanged: (v) => setState(() => _tempCmb = v),
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
          _V('피크', _peakFreq.toStringAsFixed(1) + ' GHz'),
          _V('ΔT/T', (_anisotropy * 1e5).toStringAsFixed(1) + '×10⁻⁵'),
          _V('T', _tempCmb.toStringAsFixed(3) + ' K'),
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

class _CosmicMicrowaveBgScreenPainter extends CustomPainter {
  final double time;
  final double tempCmb;

  _CosmicMicrowaveBgScreenPainter({
    required this.time,
    required this.tempCmb,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final rng = math.Random(42);

    // --- CMB map area (left ~60%) ---
    final mapW = size.width * 0.60;
    final mapH = size.height * 0.78;
    final mapLeft = 6.0;
    final mapTop = (size.height - mapH) / 2;

    // Mollweide-style ellipse clip
    canvas.save();
    final ellipseRect = Rect.fromLTWH(mapLeft, mapTop, mapW, mapH);
    final clipPath = Path()..addOval(ellipseRect);
    canvas.clipPath(clipPath);

    // Draw CMB temperature fluctuation pixels
    const int cols = 80;
    const int rows = 40;
    final cellW = mapW / cols;
    final cellH = mapH / rows;

    // Amplitude scales with tempCmb deviation from baseline
    final ampScale = tempCmb / 2.725;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Mollweide projection: skip cells outside ellipse
        final nx = (col + 0.5) / cols * 2 - 1; // -1..1
        final ny = (row + 0.5) / rows * 2 - 1; // -1..1
        if (nx * nx + (ny * ny) * 4 > 4.0) continue; // rough ellipse mask

        // Generate temperature fluctuation using low-frequency modes
        final lon = nx * math.pi;
        final lat = ny * math.pi / 2;
        double deltaT = 0;
        // Sum low-order spherical harmonics approximation
        deltaT += rng.nextDouble() * 2 - 1; // high-freq noise seed
        // Low multipole modes (large angular scale patterns)
        deltaT = (math.sin(lon * 2 + lat * 1.5 + 0.3) * 0.5
                + math.cos(lon * 3 - lat * 2 + 1.1) * 0.3
                + math.sin(lon * 1 + lat * 3 + 2.0) * 0.4
                + math.cos(lon * 4 + lat * 1 + 0.7) * 0.2
                + (rng.nextDouble() - 0.5) * 0.3) // small-scale noise
            * ampScale;

        // Map deltaT ∈ [-1, 1] → color: blue→white→red
        final t = (deltaT.clamp(-1.0, 1.0) + 1.0) / 2.0;
        Color cellColor;
        if (t < 0.5) {
          final f = t * 2.0;
          cellColor = Color.fromARGB(
            255,
            (30 + f * 180).toInt().clamp(0, 255),
            (80 + f * 140).toInt().clamp(0, 255),
            (200 + f * 55).toInt().clamp(0, 255),
          );
        } else {
          final f = (t - 0.5) * 2.0;
          cellColor = Color.fromARGB(
            255,
            (210 + f * 45).toInt().clamp(0, 255),
            (220 - f * 120).toInt().clamp(0, 255),
            (255 - f * 200).toInt().clamp(0, 255),
          );
        }

        canvas.drawRect(
          Rect.fromLTWH(mapLeft + col * cellW, mapTop + row * cellH, cellW + 1, cellH + 1),
          Paint()..color = cellColor,
        );
      }
    }
    canvas.restore();

    // Ellipse border
    canvas.drawOval(
      Rect.fromLTWH(mapLeft, mapTop, mapW, mapH),
      Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // T label
    _drawLabel(canvas, 'T = ${tempCmb.toStringAsFixed(3)} K',
        Offset(mapLeft + mapW / 2, mapTop + mapH + 10), 11, AppColors.muted);

    // --- Power spectrum graph (right ~38%) ---
    final graphLeft = mapLeft + mapW + 14.0;
    final graphW = size.width - graphLeft - 8.0;
    final graphTop = mapTop + 10.0;
    final graphH = mapH - 20.0;
    final graphBottom = graphTop + graphH;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(graphLeft, graphTop, graphW, graphH),
      Paint()..color = const Color(0xFF0A1520),
    );

    // Axes
    final axisPaint = Paint()
      ..color = const Color(0xFF5A8A9A)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(graphLeft, graphBottom), Offset(graphLeft + graphW, graphBottom), axisPaint);
    canvas.drawLine(Offset(graphLeft, graphTop), Offset(graphLeft, graphBottom), axisPaint);

    // Power spectrum: approximate Cl ∝ l(l+1) * [acoustic peaks]
    // First peak at l≈220, second l≈540, third l≈800
    final specPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Path specPath = Path();
    bool firstPt = true;
    const int lMax = 1000;
    for (int l = 2; l <= lMax; l++) {
      final lFrac = (l - 2) / (lMax - 2); // 0..1
      final lx = graphLeft + lFrac * graphW;

      // Approximate CMB power spectrum shape
      final peak1 = math.exp(-math.pow((l - 220) / 60.0, 2)) * 1.0;
      final peak2 = math.exp(-math.pow((l - 540) / 70.0, 2)) * 0.45;
      final peak3 = math.exp(-math.pow((l - 800) / 80.0, 2)) * 0.25;
      final dampedNoise = math.exp(-l / 600.0) * 0.08;
      final sachs = math.exp(-math.pow((l - 30) / 80.0, 2)) * 0.2;
      double dl = (peak1 + peak2 + peak3 + dampedNoise + sachs) * ampScale;
      dl = dl.clamp(0.0, 1.2);

      final ly = graphBottom - dl * graphH * 0.82;
      if (firstPt) {
        specPath.moveTo(lx, ly);
        firstPt = false;
      } else {
        specPath.lineTo(lx, ly);
      }
    }
    canvas.drawPath(specPath, specPaint);

    // Highlight first acoustic peak
    final peakX = graphLeft + (218.0 / lMax) * graphW;
    canvas.drawLine(
      Offset(peakX, graphTop + 4),
      Offset(peakX, graphBottom),
      Paint()
        ..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
    _drawLabel(canvas, 'ℓ≈220', Offset(peakX + 2, graphTop + 4), 9, AppColors.accent2);

    // Axis labels
    _drawLabel(canvas, 'ℓ', Offset(graphLeft + graphW - 6, graphBottom + 8), 10, AppColors.muted);
    _drawLabel(canvas, 'D_ℓ', Offset(graphLeft + 2, graphTop - 2), 10, AppColors.muted);
    _drawLabel(canvas, '파워 스펙트럼', Offset(graphLeft + graphW / 2 - 18, graphTop - 1), 9, AppColors.accent);

    // Color scale legend
    final legendTop = mapTop;
    final legendH = mapH;
    final legendX = mapLeft + mapW + 2;
    final legendW = 8.0;
    for (int i = 0; i < 30; i++) {
      final t = i / 29.0;
      Color c;
      if (t < 0.5) {
        final f = t * 2.0;
        c = Color.fromARGB(200, (30 + f * 180).toInt(), (80 + f * 140).toInt(), (200 + f * 55).toInt());
      } else {
        final f = (t - 0.5) * 2.0;
        c = Color.fromARGB(200, (210 + f * 45).toInt(), (220 - f * 120).toInt(), (255 - f * 200).toInt());
      }
      canvas.drawRect(
        Rect.fromLTWH(legendX, legendTop + (1 - t) * legendH, legendW, legendH / 30 + 1),
        Paint()..color = c,
      );
    }
    _drawLabel(canvas, '+ΔT', Offset(legendX - 2, legendTop - 1), 8, AppColors.accent2);
    _drawLabel(canvas, '-ΔT', Offset(legendX - 2, legendTop + legendH + 1), 8, const Color(0xFF3399FF));
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _CosmicMicrowaveBgScreenPainter oldDelegate) => true;
}
