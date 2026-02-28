import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class HrDiagramScreen extends StatefulWidget {
  const HrDiagramScreen({super.key});
  @override
  State<HrDiagramScreen> createState() => _HrDiagramScreenState();
}

class _HrDiagramScreenState extends State<HrDiagramScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _starMass = 1.0;
  double _luminosity = 1, _temperature = 5778, _lifetime = 10; String _spectralType = 'G';

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
      _luminosity = math.pow(_starMass, 3.5).toDouble();
      _temperature = 5778 * math.pow(_starMass, 0.505).toDouble();
      _lifetime = 10 / math.pow(_starMass, 2.5).toDouble();
      _spectralType = _temperature > 30000 ? 'O' : _temperature > 10000 ? 'B' : _temperature > 7500 ? 'A' : _temperature > 6000 ? 'F' : _temperature > 5200 ? 'G' : _temperature > 3700 ? 'K' : 'M';
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _starMass = 1.0;
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
          const Text('HR 도표', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: 'HR 도표',
          formula: 'L ∝ M^3.5',
          formulaDescription: 'HR 다이어그램에 별을 표시하고 항성 분류를 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _HrDiagramScreenPainter(
                time: _time,
                starMass: _starMass,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '항성 질량 (M☉)',
                value: _starMass,
                min: 0.1,
                max: 50.0,
                step: 0.1,
                defaultValue: 1.0,
                formatValue: (v) => '${v.toStringAsFixed(1)} M☉',
                onChanged: (v) => setState(() => _starMass = v),
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
          _V('광도', '${_luminosity.toStringAsFixed(1)} L☉'),
          _V('온도', '${_temperature.toStringAsFixed(0)} K'),
          _V('수명', '${_lifetime.toStringAsFixed(1)} Gyr'),
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

class _HrDiagramScreenPainter extends CustomPainter {
  final double time;
  final double starMass;

  _HrDiagramScreenPainter({
    required this.time,
    required this.starMass,
  });

  // Convert temperature & luminosity to canvas XY position
  Offset _hrToCanvas(double tempK, double lumSun, Size size, Rect plotArea) {
    // X: temperature 30000->3000 (reversed, log scale)
    final tMin = math.log(3000), tMax = math.log(30000);
    final tLog = math.log(tempK.clamp(3000, 30000));
    final xFrac = (tMax - tLog) / (tMax - tMin);
    // Y: luminosity log scale 1e-4 -> 1e6
    final lMin = math.log(1e-4), lMax = math.log(1e6);
    final lLog = math.log(lumSun.clamp(1e-4, 1e6));
    final yFrac = 1.0 - (lLog - lMin) / (lMax - lMin);
    return Offset(
      plotArea.left + xFrac * plotArea.width,
      plotArea.top + yFrac * plotArea.height,
    );
  }

  Color _tempToColor(double tempK) {
    if (tempK > 25000) return const Color(0xFF9BB0FF); // Blue-white O/B
    if (tempK > 10000) return const Color(0xFFCAD7FF); // White A
    if (tempK > 7500) return const Color(0xFFF8F7FF);  // Yellow-white F
    if (tempK > 6000) return const Color(0xFFFFFFCC);  // Yellow G
    if (tempK > 5200) return const Color(0xFFFFD2A1);  // Orange-yellow K
    if (tempK > 3700) return const Color(0xFFFFBD6F);  // Orange K/M
    return const Color(0xFFFF7C00);                     // Red M
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    const pad = EdgeInsets.fromLTRB(44, 12, 12, 36);
    final plotArea = Rect.fromLTRB(pad.left, pad.top, size.width - pad.right, size.height - pad.bottom);

    // Grid
    final gridPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5;
    for (int i = 0; i <= 5; i++) {
      final y = plotArea.top + i * plotArea.height / 5;
      canvas.drawLine(Offset(plotArea.left, y), Offset(plotArea.right, y), gridPaint);
    }
    for (int i = 0; i <= 5; i++) {
      final x = plotArea.left + i * plotArea.width / 5;
      canvas.drawLine(Offset(x, plotArea.top), Offset(x, plotArea.bottom), gridPaint);
    }

    // Star regions background tint
    // Main sequence band
    final msBand = Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.04);
    final msPath = Path();
    final msPoints = <Offset>[];
    final msTops = <Offset>[];
    final msTempRange = [30000.0, 20000.0, 10000.0, 7500.0, 6000.0, 5200.0, 3700.0, 3000.0];
    final msLumTop = [1e5, 2e4, 1e3, 50.0, 5.0, 1.0, 0.1, 0.02];
    final msLumBot = [2e4, 4e3, 100.0, 8.0, 0.8, 0.12, 0.01, 0.003];
    for (int i = 0; i < msTempRange.length; i++) {
      msPoints.add(_hrToCanvas(msTempRange[i], msLumBot[i], size, plotArea));
      msTops.add(_hrToCanvas(msTempRange[i], msLumTop[i], size, plotArea));
    }
    msPath.moveTo(msPoints[0].dx, msPoints[0].dy);
    for (final p in msPoints.skip(1)) { msPath.lineTo(p.dx, p.dy); }
    for (final p in msTops.reversed) { msPath.lineTo(p.dx, p.dy); }
    msPath.close();
    canvas.drawPath(msPath, msBand);

    // Draw background stars (seeded random)
    // Main sequence stars
    final msStarData = [
      [30000.0, 1e5], [25000.0, 5e4], [20000.0, 2e4], [15000.0, 8e3],
      [10000.0, 1e3], [8000.0, 150.0], [7000.0, 30.0], [6000.0, 3.0],
      [5778.0, 1.0],  [5000.0, 0.3], [4000.0, 0.05], [3500.0, 0.01],
    ];
    for (final s in msStarData) {
      final pos = _hrToCanvas(s[0], s[1], size, plotArea);
      final col = _tempToColor(s[0]);
      final r = (math.log(s[1].clamp(0.01, 1e6)) / math.log(1e6) * 3 + 1.5).clamp(1.2, 5.0);
      // Glow
      canvas.drawCircle(pos, r * 2.5, Paint()..color = col.withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(pos, r, Paint()..color = col);
    }

    // Giant branch stars (upper right)
    final giantData = [
      [5000.0, 200.0], [4500.0, 500.0], [4000.0, 1200.0], [3800.0, 3000.0],
      [5500.0, 100.0], [4800.0, 350.0],
    ];
    for (final s in giantData) {
      final pos = _hrToCanvas(s[0], s[1], size, plotArea);
      final col = _tempToColor(s[0]);
      canvas.drawCircle(pos, 5, Paint()..color = col.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(pos, 3.5, Paint()..color = col);
    }

    // White dwarf stars (lower left)
    final wdData = [
      [25000.0, 3e-4], [20000.0, 1e-3], [15000.0, 5e-4], [30000.0, 1e-4],
      [12000.0, 2e-3],
    ];
    for (final s in wdData) {
      final pos = _hrToCanvas(s[0], s[1], size, plotArea);
      canvas.drawCircle(pos, 2.5, Paint()..color = const Color(0xFFCCEEFF).withValues(alpha: 0.6));
    }

    // Supergiants (top)
    final sgData = [
      [6000.0, 3e5], [5000.0, 1e5], [3800.0, 2e5], [8000.0, 5e4],
    ];
    for (final s in sgData) {
      final pos = _hrToCanvas(s[0], s[1], size, plotArea);
      final col = _tempToColor(s[0]);
      canvas.drawCircle(pos, 7, Paint()..color = col.withValues(alpha: 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(pos, 5, Paint()..color = col);
    }

    // Current star (from slider)
    final curLum = math.pow(starMass, 3.5).toDouble();
    final curTemp = 5778 * math.pow(starMass, 0.505).toDouble();
    final curPos = _hrToCanvas(curTemp, curLum, size, plotArea);
    final curCol = _tempToColor(curTemp);
    final pulse = 0.15 * math.sin(time * 3);
    canvas.drawCircle(curPos, 10 + pulse * 4, Paint()..color = curCol.withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(curPos, 6.5 + pulse, Paint()..color = curCol);
    canvas.drawCircle(curPos, 6.5 + pulse, Paint()..color = Colors.white.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Sun marker
    final sunPos = _hrToCanvas(5778, 1.0, size, plotArea);
    _drawLabel(canvas, '☉', sunPos + const Offset(8, -8), const Color(0xFFFFFFCC), 10);

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1;
    canvas.drawLine(Offset(plotArea.left, plotArea.top), Offset(plotArea.left, plotArea.bottom), axisPaint);
    canvas.drawLine(Offset(plotArea.left, plotArea.bottom), Offset(plotArea.right, plotArea.bottom), axisPaint);

    // X axis labels (temperature, reversed)
    final xTemps = [30000.0, 10000.0, 6000.0, 3500.0];
    final xLabels = ['30k', '10k', '6k', '3.5k'];
    for (int i = 0; i < xTemps.length; i++) {
      final x = plotArea.left + (math.log(30000) - math.log(xTemps[i])) / (math.log(30000) - math.log(3000)) * plotArea.width;
      _drawLabel(canvas, xLabels[i], Offset(x, plotArea.bottom + 5), const Color(0xFF5A8A9A), 8);
    }
    _drawLabel(canvas, '온도 (K) →', Offset(plotArea.left + plotArea.width / 2 - 20, size.height - 4), const Color(0xFF5A8A9A), 8);

    // Y axis labels (luminosity)
    final yLums = [1e6, 1e4, 1e2, 1.0, 1e-2, 1e-4];
    final yLabels = ['10⁶', '10⁴', '10²', '1', '10⁻²', '10⁻⁴'];
    for (int i = 0; i < yLums.length; i++) {
      final yPos = _hrToCanvas(5000, yLums[i], size, plotArea);
      _drawLabel(canvas, yLabels[i], Offset(0, yPos.dy - 4), const Color(0xFF5A8A9A), 7);
    }

    // Region labels
    _drawLabel(canvas, 'Main Seq.', Offset(plotArea.left + plotArea.width * 0.4, plotArea.top + plotArea.height * 0.35), const Color(0xFF00D4FF).withValues(alpha: 0.8), 9);
    _drawLabel(canvas, '거성', Offset(plotArea.left + plotArea.width * 0.15, plotArea.top + plotArea.height * 0.3), const Color(0xFFFF6B35).withValues(alpha: 0.9), 9);
    _drawLabel(canvas, '백색왜성', Offset(plotArea.left + plotArea.width * 0.55, plotArea.bottom - 30), const Color(0xFFCCEEFF).withValues(alpha: 0.8), 8);
    _drawLabel(canvas, '초거성', Offset(plotArea.left + plotArea.width * 0.3, plotArea.top + 6), const Color(0xFFFFD2A1).withValues(alpha: 0.9), 9);
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _HrDiagramScreenPainter oldDelegate) => true;
}
