import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ChromatographyScreen extends StatefulWidget {
  const ChromatographyScreen({super.key});
  @override
  State<ChromatographyScreen> createState() => _ChromatographyScreenState();
}

class _ChromatographyScreenState extends State<ChromatographyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _solventFront = 8;
  double _spotCount = 3;


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
      
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _solventFront = 8; _spotCount = 3;
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
          Text('화학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('크로마토그래피', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '크로마토그래피',
          formula: 'R_f = d_solute / d_solvent',
          formulaDescription: '종이 크로마토그래피로 혼합물을 분리합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ChromatographyScreenPainter(
                time: _time,
                solventFront: _solventFront,
                spotCount: _spotCount,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '용매 전선 (cm)',
                value: _solventFront,
                min: 1,
                max: 15,
                step: 0.5,
                defaultValue: 8,
                formatValue: (v) => '${v.toStringAsFixed(1)} cm',
                onChanged: (v) => setState(() => _solventFront = v),
              ),
              advancedControls: [
            SimSlider(
                label: '시료 수',
                value: _spotCount,
                min: 1,
                max: 5,
                step: 1,
                defaultValue: 3,
                formatValue: (v) => v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _spotCount = v),
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
          _V('용매 전선', '${_solventFront.toStringAsFixed(1)} cm'),
          _V('R_f 범위', '0.1-0.9'),
          _V('시료 수', _spotCount.toStringAsFixed(0)),
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

class _ChromatographyScreenPainter extends CustomPainter {
  final double time;
  final double solventFront;
  final double spotCount;

  _ChromatographyScreenPainter({
    required this.time,
    required this.solventFront,
    required this.spotCount,
  });

  // Rf values and colors for up to 5 components
  static const _rfValues  = [0.82, 0.55, 0.31, 0.70, 0.18];
  static const _compColors = [
    Color(0xFF00D4FF),
    Color(0xFFFF6B35),
    Color(0xFF64FF8C),
    Color(0xFFFFD700),
    Color(0xFFFF69B4),
  ];
  static const _compNames = ['A', 'B', 'C', 'D', 'E'];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;
    final n = spotCount.toInt().clamp(1, 5);

    // Layout: TLC plate (left 55%) | chromatogram graph (right 45%)
    final plateW = w * 0.52;
    final graphX = plateW + 8;
    final graphW = w - graphX - 8;

    // ── TLC Plate ────────────────────────────────────────────────────────
    final plateLeft = 16.0, plateRight = plateW - 8;
    final plateTop  = 20.0, plateBottom = h - 30.0;
    final plateH = plateBottom - plateTop;

    // Plate background (silica = off-white tint)
    canvas.drawRect(
      Rect.fromLTRB(plateLeft, plateTop, plateRight, plateBottom),
      Paint()..color = const Color(0xFF0E2030)..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      Rect.fromLTRB(plateLeft, plateTop, plateRight, plateBottom),
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)
        ..strokeWidth = 1.2..style = PaintingStyle.stroke,
    );

    // Solvent front line
    final maxSF = 15.0;
    final sfFrac = (solventFront / maxSF).clamp(0.0, 1.0);
    final sfY = plateBottom - sfFrac * plateH * 0.88;
    canvas.drawLine(
      Offset(plateLeft, sfY),
      Offset(plateRight, sfY),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)
        ..strokeWidth = 1.2..style = PaintingStyle.stroke,
    );
    // Solvent front label
    final sfTp = TextPainter(
      text: const TextSpan(text: '용매 전선', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 7)),
      textDirection: TextDirection.ltr,
    )..layout();
    sfTp.paint(canvas, Offset(plateLeft + 2, sfY - 10));

    // Origin line
    final originY = plateBottom - plateH * 0.06;
    canvas.drawLine(
      Offset(plateLeft, originY),
      Offset(plateRight, originY),
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)
        ..strokeWidth = 0.8..style = PaintingStyle.stroke,
    );

    // Spots for each component
    final spotXSpacing = (plateRight - plateLeft) / (n + 1);
    for (int i = 0; i < n; i++) {
      final rf = _rfValues[i];
      final spotX = plateLeft + spotXSpacing * (i + 1);
      // spot migrates: distance = rf * sfFrac * plateH * 0.88
      final migDist = rf * sfFrac * plateH * 0.88;
      final spotY = originY - migDist;
      final col = _compColors[i];

      // Spot glow
      canvas.drawCircle(Offset(spotX, spotY), 9,
          Paint()..color = col.withValues(alpha: 0.15)..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(spotX, spotY), 6,
          Paint()..color = col.withValues(alpha: 0.7)..style = PaintingStyle.fill);

      // Origin dot
      canvas.drawCircle(Offset(spotX, originY), 4,
          Paint()..color = col.withValues(alpha: 0.35)..style = PaintingStyle.fill);

      // Rf label below spot
      final rfTp = TextPainter(
        text: TextSpan(
          text: '${_compNames[i]}\nRf=${rf.toStringAsFixed(2)}',
          style: TextStyle(color: col, fontSize: 7),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 40);
      rfTp.paint(canvas, Offset(spotX - rfTp.width / 2, plateBottom + 2));
    }

    // TLC title
    final tlcTp = TextPainter(
      text: const TextSpan(text: 'TLC 플레이트', style: TextStyle(color: Color(0xFF5A8A9A), fontSize: 8)),
      textDirection: TextDirection.ltr,
    )..layout();
    tlcTp.paint(canvas, Offset((plateLeft + plateRight) / 2 - tlcTp.width / 2, plateTop + 3));

    // ── Chromatogram Graph ────────────────────────────────────────────────
    final gLeft = graphX, gRight = graphX + graphW - 6;
    final gTop  = 20.0,  gBottom = h - 30.0;
    final gH = gBottom - gTop;
    final gW = gRight - gLeft;

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0;
    canvas.drawLine(Offset(gLeft, gTop), Offset(gLeft, gBottom), axisPaint);
    canvas.drawLine(Offset(gLeft, gBottom), Offset(gRight, gBottom), axisPaint);

    // Axis labels
    void gLabel(String t, double x, double y, Color c, {double fs = 7}) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: TextStyle(color: c, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
    gLabel('크로마토그램', gLeft + gW / 2, gTop + 5, const Color(0xFF5A8A9A), fs: 8);
    gLabel('Rf', gLeft + gW / 2, gBottom + 12, const Color(0xFF5A8A9A));
    gLabel('흡광도', gLeft - 4, gTop + gH / 2, const Color(0xFF5A8A9A));

    // Gaussian peaks at each Rf position
    const peakSigma = 0.06;
    for (int i = 0; i < n; i++) {
      final rf = _rfValues[i];
      final col = _compColors[i];
      final path = Path();
      bool started = false;
      for (int px = 0; px <= gW.toInt(); px++) {
        final xFrac = px / gW;
        final peak = math.exp(-0.5 * math.pow((xFrac - rf) / peakSigma, 2));
        final py = gBottom - peak * gH * 0.75;
        if (!started) { path.moveTo(gLeft + px, py); started = true; }
        else { path.lineTo(gLeft + px, py); }
      }
      canvas.drawPath(path,
          Paint()..color = col..strokeWidth = 1.5..style = PaintingStyle.stroke);

      // Fill under peak
      final fillPath = Path()..addPath(path, Offset.zero);
      fillPath.lineTo(gRight, gBottom);
      fillPath.lineTo(gLeft, gBottom);
      fillPath.close();
      canvas.drawPath(fillPath,
          Paint()..color = col.withValues(alpha: 0.08)..style = PaintingStyle.fill);

      // Peak label
      final peakX = gLeft + rf * gW;
      gLabel(_compNames[i], peakX, gBottom - gH * 0.78, col, fs: 8);
    }

    // Rf tick marks on x-axis
    for (int t = 0; t <= 4; t++) {
      final tx = gLeft + t * gW / 4;
      canvas.drawLine(Offset(tx, gBottom), Offset(tx, gBottom + 3), axisPaint);
      gLabel((t * 0.25).toStringAsFixed(2), tx, gBottom + 10, const Color(0xFF5A8A9A));
    }
  }

  @override
  bool shouldRepaint(covariant _ChromatographyScreenPainter oldDelegate) => true;
}
