import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class IceAgesScreen extends StatefulWidget {
  const IceAgesScreen({super.key});
  @override
  State<IceAgesScreen> createState() => _IceAgesScreenState();
}

class _IceAgesScreenState extends State<IceAgesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _eccentricity = 0.017;
  double _obliquity = 23.5;
  double _insolation = 1.0, _tempAnomaly = 0;

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
      _insolation = 1 + _eccentricity * 10 + (_obliquity - 23.5) * 0.05;
      _tempAnomaly = (_insolation - 1) * 10;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _eccentricity = 0.017; _obliquity = 23.5;
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
          const Text('빙하기 주기', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '빙하기 주기',
          formula: 'Milankovitch cycles',
          formulaDescription: '밀란코비치 주기에 의한 빙하기 순환을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _IceAgesScreenPainter(
                time: _time,
                eccentricity: _eccentricity,
                obliquity: _obliquity,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '이심률',
                value: _eccentricity,
                min: 0,
                max: 0.06,
                step: 0.001,
                defaultValue: 0.017,
                formatValue: (v) => v.toStringAsFixed(3),
                onChanged: (v) => setState(() => _eccentricity = v),
              ),
              advancedControls: [
            SimSlider(
                label: '기울기 (°)',
                value: _obliquity,
                min: 22,
                max: 25,
                step: 0.1,
                defaultValue: 23.5,
                formatValue: (v) => v.toStringAsFixed(1) + '°',
                onChanged: (v) => setState(() => _obliquity = v),
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
          _V('일사량', _insolation.toStringAsFixed(3)),
          _V('온도차', _tempAnomaly.toStringAsFixed(1) + ' °C'),
          _V('이심률', _eccentricity.toStringAsFixed(3)),
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

class _IceAgesScreenPainter extends CustomPainter {
  final double time;
  final double eccentricity;
  final double obliquity;

  _IceAgesScreenPainter({
    required this.time,
    required this.eccentricity,
    required this.obliquity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    const pad = 12.0;
    const labelW = 32.0;
    const titleH = 18.0;

    void drawLabel(String text, double x, double y, Color color, double fs) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    drawLabel('밀란코비치 사이클 (800 kyr)', w / 2, pad + titleH / 2, const Color(0xFF00D4FF), 10);

    // Layout: 4 chart rows
    // Row 0: δ18O (temperature proxy)  ~30% of remaining height
    // Row 1: Eccentricity              ~20%
    // Row 2: Obliquity                 ~20%
    // Row 3: Precession                ~20%
    final chartTop = pad + titleH + 4;
    final chartBot = h - pad;
    final totalH = chartBot - chartTop;
    final rowHeights = [totalH * 0.32, totalH * 0.22, totalH * 0.22, totalH * 0.22];
    final gL = pad + labelW;
    final gR = w - pad;
    final gW = gR - gL;

    final axPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.8;
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1;

    double rowY = chartTop;
    final rowConfigs = [
      ('δ¹⁸O', const Color(0xFFE0F4FF), 1.0),
      ('이심률', const Color(0xFFFF6B35), eccentricity / 0.06),
      ('기울기', const Color(0xFF00D4FF), (obliquity - 22.0) / 3.0),
      ('세차', const Color(0xFF64FF8C), 1.0),
    ];

    // Simulated ice-age cycle data (800kyr = 800 points conceptually)
    // We render X axis as 0..800 kyr ago (right=present)
    for (int row = 0; row < 4; row++) {
      final rH = rowHeights[row];
      final rTop = rowY;
      final rBot = rowY + rH;
      final rMid = rTop + rH / 2;
      final label = rowConfigs[row].$1;
      final color = rowConfigs[row].$2;

      // Row background grid line
      canvas.drawLine(Offset(gL, rMid), Offset(gR, rMid), axPaint);
      canvas.drawLine(Offset(gL, rTop + 2), Offset(gL, rBot - 2), axisPaint);

      // Row label
      final lTp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: color, fontSize: 7.5)),
        textDirection: TextDirection.ltr,
      )..layout();
      lTp.paint(canvas, Offset(pad, rMid - lTp.height / 2));

      // Draw curve
      final curvePaint = Paint()
        ..color = color
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      final path = Path();
      const nPts = 200;
      for (int i = 0; i <= nPts; i++) {
        final t = i / nPts.toDouble();
        final x = gL + t * gW;
        double y;
        if (row == 0) {
          // δ18O: composite of 100kyr + 41kyr + 23kyr cycles
          final v = math.sin(t * 2 * math.pi * 8.0)       // 100kyr
                  + 0.4 * math.sin(t * 2 * math.pi * 19.5) // 41kyr
                  + 0.25 * math.sin(t * 2 * math.pi * 34.8);// 23kyr
          y = rMid - v * rH * 0.38;
        } else if (row == 1) {
          // Eccentricity: 100kyr cycle, modulated by eccentricity param
          final amp = 0.3 + eccentricity * 5.0;
          y = rMid - math.sin(t * 2 * math.pi * 8.0) * rH * amp;
        } else if (row == 2) {
          // Obliquity: 41kyr cycle
          final amp = (obliquity - 22.0) / 3.0 * 0.5 + 0.3;
          y = rMid - math.sin(t * 2 * math.pi * 19.5) * rH * amp;
        } else {
          // Precession: 23kyr cycle
          y = rMid - math.sin(t * 2 * math.pi * 34.8) * rH * 0.38;
        }
        if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
      }
      canvas.drawPath(path, curvePaint);

      // Ice age highlight bands on row 0 only
      if (row == 0) {
        final icePaint = Paint()..color = const Color(0xFFADD8E6).withValues(alpha: 0.10);
        // Approximate glacial maxima positions (every ~100kyr)
        for (int g = 1; g <= 7; g++) {
          final cx = gL + gW * (g * 0.125 - 0.04);
          canvas.drawRect(Rect.fromLTRB(cx, rTop, cx + gW * 0.04, rBot), icePaint);
        }
        // "현재" marker at right edge
        canvas.drawLine(Offset(gR - 1, rTop), Offset(gR - 1, rBot),
            Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5);
        drawLabel('현재', gR - 1, rTop + 6, const Color(0xFFFF6B35), 7);
      }

      rowY += rH + 2;
    }

    // X axis labels
    drawLabel('800 kyr 전', gL + 10, chartBot - 6, const Color(0xFF5A8A9A), 7.5);
    drawLabel('400 kyr', gL + gW * 0.5, chartBot - 6, const Color(0xFF5A8A9A), 7.5);
    drawLabel('현재', gR - 8, chartBot - 6, const Color(0xFF5A8A9A), 7.5);
  }

  @override
  bool shouldRepaint(covariant _IceAgesScreenPainter oldDelegate) => true;
}
