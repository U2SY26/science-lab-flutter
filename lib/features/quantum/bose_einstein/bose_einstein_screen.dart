import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BoseEinsteinScreen extends StatefulWidget {
  const BoseEinsteinScreen({super.key});
  @override
  State<BoseEinsteinScreen> createState() => _BoseEinsteinScreenState();
}

class _BoseEinsteinScreenState extends State<BoseEinsteinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _temperature = 100;
  
  double _condensateFrac = 0, _tc = 170;

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
      _tc = 170;
      _condensateFrac = _temperature < _tc ? math.pow(1 - _temperature / _tc, 1.5).toDouble() : 0;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _temperature = 100.0;
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
          const Text('보즈-아인슈타인 응축', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '보즈-아인슈타인 응축',
          formula: 'T_c = (2πħ²/mk_B)(n/2.612)^(2/3)',
          formulaDescription: '보즈-아인슈타인 응축 과정을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BoseEinsteinScreenPainter(
                time: _time,
                temperature: _temperature,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '온도 (nK)',
                value: _temperature,
                min: 1,
                max: 500,
                step: 1,
                defaultValue: 100,
                formatValue: (v) => v.toStringAsFixed(0) + ' nK',
                onChanged: (v) => setState(() => _temperature = v),
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
          _V('N₀/N', (_condensateFrac * 100).toStringAsFixed(1) + '%'),
          _V('T_c', _tc.toStringAsFixed(0) + ' nK'),
          _V('T', _temperature.toStringAsFixed(0) + ' nK'),
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

class _BoseEinsteinScreenPainter extends CustomPainter {
  final double time;
  final double temperature;

  _BoseEinsteinScreenPainter({
    required this.time,
    required this.temperature,
  });

  void _label(Canvas canvas, String text, Offset offset,
      {double fontSize = 9, Color color = const Color(0xFF5A8A9A)}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final tc = 170.0; // critical temperature nK
    final condensateFrac = temperature < tc
        ? math.pow(1 - temperature / tc, 1.5).toDouble()
        : 0.0;

    // Layout: top 55% = velocity distribution, bottom 45% = atom cloud + bar
    final splitY = h * 0.56;

    // ---- TOP: velocity distribution ----
    final padL = 36.0, padR = 12.0, padT = 14.0;
    final plotW = w - padL - padR;
    final plotH = splitY - padT - 12;
    final plotBot = padT + plotH;

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1;
    canvas.drawLine(Offset(padL, plotBot), Offset(padL + plotW, plotBot), axisPaint);
    canvas.drawLine(Offset(padL, padT), Offset(padL, plotBot), axisPaint);

    _label(canvas, 'v', Offset(padL + plotW - 4, plotBot + 2));
    _label(canvas, 'n(v)', Offset(2, padT), fontSize: 8);

    // Maxwell-Boltzmann distribution: n(v) ~ v² * exp(-mv²/2kT)
    // Normalized to fit plot. Width scales with sqrt(T).
    final vMax = plotW;
    final sigma = plotW * 0.12 * math.sqrt(temperature / 100.0).clamp(0.2, 3.0);
    final mbPeak = plotH * 0.65;

    double mbY(double px) {
      final v = (px - padL) / vMax;
      if (v < 0) return plotBot;
      final exponent = -0.5 * math.pow(v / (sigma / vMax), 2);
      return plotBot - mbPeak * v * v * math.exp(exponent) * 20;
    }

    // Draw MB distribution (orange)
    final mbPath = Path()..moveTo(padL, plotBot);
    for (int i = 0; i <= 200; i++) {
      final px = padL + i / 200.0 * plotW;
      final py = mbY(px).clamp(padT, plotBot);
      mbPath.lineTo(px, py);
    }
    mbPath.lineTo(padL + plotW, plotBot);
    mbPath.close();
    canvas.drawPath(mbPath, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.25));
    final mbStroke = Path()..moveTo(padL, plotBot);
    for (int i = 0; i <= 200; i++) {
      final px = padL + i / 200.0 * plotW;
      final py = mbY(px).clamp(padT, plotBot);
      mbStroke.lineTo(px, py);
    }
    canvas.drawPath(mbStroke, Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // BEC spike at v=0 (k=0 mode)
    if (condensateFrac > 0.01) {
      final spikeHeight = plotH * condensateFrac * 0.85;
      final spikeW = plotW * 0.018;
      final spikePaint = Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.8);
      canvas.drawRect(
        Rect.fromLTWH(padL - spikeW / 2, plotBot - spikeHeight, spikeW, spikeHeight),
        spikePaint,
      );
      // Glow
      canvas.drawRect(
        Rect.fromLTWH(padL - spikeW, plotBot - spikeHeight * 0.7, spikeW * 2, spikeHeight * 0.7),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.2),
      );
      _label(canvas, 'BEC', Offset(padL + 4, plotBot - spikeHeight - 12),
          color: const Color(0xFF00D4FF), fontSize: 9);
    }

    // Tc marker
    final tcX = padL + plotW * (tc / 500.0).clamp(0.0, 1.0);
    canvas.drawLine(Offset(tcX, padT), Offset(tcX, plotBot),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.4)..strokeWidth = 1);
    _label(canvas, 'T_c=${tc.toStringAsFixed(0)}nK', Offset(tcX + 2, padT),
        color: const Color(0xFFFF6B35), fontSize: 8);

    // T label
    _label(canvas, 'T=${temperature.toStringAsFixed(0)}nK', Offset(padL + 4, padT),
        color: temperature < tc ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35), fontSize: 9);
    _label(canvas, temperature < tc ? 'T < Tc (BEC)' : 'T > Tc (정상)', Offset(padL + plotW * 0.45, padT),
        color: temperature < tc ? const Color(0xFF00D4FF) : const Color(0xFF5A8A9A), fontSize: 9);

    // ---- BOTTOM: atom cloud + condensate fraction bar ----
    final cloudTop = splitY + 8;
    final cloudBot = h - 24.0;
    final cloudCy = (cloudTop + cloudBot) / 2;
    final cloudCx = w * 0.35;
    final cloudR = math.min((cloudBot - cloudTop) / 2, w * 0.18);

    // Draw atom cloud: dots
    final rng = math.Random(42);
    final cloudScale = 1.0 + (temperature / tc).clamp(0.0, 3.0) * 0.5;
    final nAtoms = 120;
    for (int i = 0; i < nAtoms; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final r = rng.nextDouble();
      // Condensed atoms cluster at center
      final isCondensed = i < (nAtoms * condensateFrac).round();
      final radius = isCondensed
          ? r * cloudR * 0.18
          : r * cloudR * cloudScale;
      final ax = cloudCx + radius * math.cos(angle);
      final ay = cloudCy + radius * math.sin(angle);
      if (ay < cloudTop || ay > cloudBot) continue;
      final dotColor = isCondensed
          ? const Color(0xFF00D4FF)
          : const Color(0xFFFF6B35).withValues(alpha: 0.6);
      canvas.drawCircle(Offset(ax, ay), isCondensed ? 2.5 : 1.5,
          Paint()..color = dotColor);
    }
    _label(canvas, '원자 구름', Offset(cloudCx - 16, cloudBot + 4));

    // Condensate fraction bar
    final barLeft = w * 0.62;
    final barRight = w - 12.0;
    final barTop = cloudTop + 4;
    final barBot = cloudBot - 4;
    final barH = barBot - barTop;

    canvas.drawRect(Rect.fromLTRB(barLeft, barTop, barRight, barBot),
        Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.fill);
    canvas.drawRect(Rect.fromLTRB(barLeft, barTop, barRight, barBot),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1..style = PaintingStyle.stroke);

    // Filled portion
    final fillH = barH * condensateFrac;
    if (fillH > 0) {
      canvas.drawRect(
        Rect.fromLTRB(barLeft + 1, barBot - fillH, barRight - 1, barBot - 1),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7),
      );
    }

    _label(canvas, 'N₀/N', Offset(barLeft + (barRight - barLeft) / 2 - 8, barTop - 12));
    _label(canvas, '${(condensateFrac * 100).toStringAsFixed(0)}%',
        Offset(barLeft + (barRight - barLeft) / 2 - 10, barBot - fillH - 14),
        color: const Color(0xFF00D4FF), fontSize: 10);

    // 0% and 100% labels
    _label(canvas, '100%', Offset(barLeft - 28, barTop - 2), fontSize: 8);
    _label(canvas, '0%', Offset(barLeft - 16, barBot - 8), fontSize: 8);
  }

  @override
  bool shouldRepaint(covariant _BoseEinsteinScreenPainter oldDelegate) => true;
}
