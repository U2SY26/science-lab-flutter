import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class GreenhouseGasesScreen extends StatefulWidget {
  const GreenhouseGasesScreen({super.key});
  @override
  State<GreenhouseGasesScreen> createState() => _GreenhouseGasesScreenState();
}

class _GreenhouseGasesScreenState extends State<GreenhouseGasesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _co2Level = 420;
  double _methaneLevel = 1900;
  double _forcing = 0, _tempRise = 0;

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
      _forcing = 5.35 * math.log(_co2Level / 280);
      _tempRise = _forcing * 0.8;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _co2Level = 420; _methaneLevel = 1900;
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
          const Text('온실 기체 비교', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '온실 기체 비교',
          formula: 'ΔF = 5.35 ln(C/C₀)',
          formulaDescription: '온실 기체의 효과와 지구 온난화 잠재력을 비교합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _GreenhouseGasesScreenPainter(
                time: _time,
                co2Level: _co2Level,
                methaneLevel: _methaneLevel,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'CO₂ 농도 (ppm)',
                value: _co2Level,
                min: 200,
                max: 1000,
                step: 10,
                defaultValue: 420,
                formatValue: (v) => '${v.toStringAsFixed(0)} ppm',
                onChanged: (v) => setState(() => _co2Level = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'CH₄ 농도 (ppb)',
                value: _methaneLevel,
                min: 500,
                max: 5000,
                step: 100,
                defaultValue: 1900,
                formatValue: (v) => '${v.toStringAsFixed(0)} ppb',
                onChanged: (v) => setState(() => _methaneLevel = v),
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
          _V('복사 강제력', '${_forcing.toStringAsFixed(2)} W/m²'),
          _V('온도 상승', '${_tempRise.toStringAsFixed(1)} °C'),
          _V('CO₂', '${_co2Level.toStringAsFixed(0)} ppm'),
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

class _GreenhouseGasesScreenPainter extends CustomPainter {
  final double time;
  final double co2Level;
  final double methaneLevel;

  _GreenhouseGasesScreenPainter({
    required this.time,
    required this.co2Level,
    required this.methaneLevel,
  });

  void _label(Canvas canvas, String text, Offset pos, {double fs = 9, Color col = const Color(0xFF5A8A9A), bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? pos.dx - tp.width / 2 : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // ---- GWP bar chart (top half) ----
    // Gases: CO2(1), CH4(28), N2O(265), H2O(~0.5 relative), O3(~7)
    final gases = [
      ('CO₂', 1.0, const Color(0xFF5A8A9A)),
      ('CH₄', 28.0, const Color(0xFFFF6B35)),
      ('N₂O', 265.0, const Color(0xFF00D4FF)),
      ('H₂O', 0.5, const Color(0xFF4488BB)),
      ('O₃', 7.0, const Color(0xFF64FF8C)),
    ];
    const maxGwp = 265.0;
    final chartTop = h * 0.06;
    final chartH = h * 0.36;
    final chartBot = chartTop + chartH;
    final chartLeft = 38.0;
    final chartRight = w - 10;
    final chartW = chartRight - chartLeft;
    final barW = chartW / gases.length - 8;

    // Axes
    canvas.drawLine(Offset(chartLeft, chartTop), Offset(chartLeft, chartBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(chartLeft, chartBot), Offset(chartRight, chartBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _label(canvas, 'GWP (100yr)', Offset(0, chartTop - 2), fs: 8, col: const Color(0xFFE0F4FF));
    _label(canvas, '265', Offset(2, chartTop), fs: 7);
    _label(canvas, '1', Offset(8, chartBot - 10), fs: 7);

    for (int i = 0; i < gases.length; i++) {
      final g = gases[i];
      final x = chartLeft + i * (barW + 8) + 4;
      final normH = (g.$2 / maxGwp) * chartH;
      final barRect = Rect.fromLTWH(x, chartBot - normH, barW, normH);
      canvas.drawRect(barRect, Paint()..color = g.$3.withValues(alpha: 0.8));
      canvas.drawRect(barRect, Paint()..color = g.$3..style = PaintingStyle.stroke..strokeWidth = 1);
      _label(canvas, g.$1, Offset(x + barW / 2, chartBot + 2), fs: 8, col: g.$3, center: true);
      if (g.$2 >= 1.0) {
        _label(canvas, g.$2 >= 10 ? '${g.$2.toStringAsFixed(0)}x' : '${g.$2.toStringAsFixed(1)}x',
            Offset(x + barW / 2, chartBot - normH - 11), fs: 7, col: g.$3, center: true);
      }
    }

    // ---- CO2 time series (middle) ----
    final tsTop = h * 0.48;
    final tsH = h * 0.26;
    final tsBot = tsTop + tsH;
    final tsLeft = 48.0;
    final tsRight = w - 10;
    final tsW = tsRight - tsLeft;

    canvas.drawLine(Offset(tsLeft, tsTop), Offset(tsLeft, tsBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(tsLeft, tsBot), Offset(tsRight, tsBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _label(canvas, 'ppm', Offset(2, tsTop - 2), fs: 7);
    _label(canvas, '420', Offset(2, tsTop + 2), fs: 7, col: const Color(0xFF5A8A9A));
    _label(canvas, '315', Offset(2, tsBot - 8), fs: 7, col: const Color(0xFF5A8A9A));
    _label(canvas, '1950', Offset(tsLeft + 2, tsBot + 2), fs: 7);
    _label(canvas, '현재', Offset(tsRight - 18, tsBot + 2), fs: 7);

    // CO2 Keeling curve: 315 ppm in 1950 → co2Level now (animated)
    // Map year to X, ppm to Y
    final co2Path = Path();
    for (int px = 0; px <= tsW.toInt(); px++) {
      final frac = px / tsW;
      // Non-linear growth: exponential-ish
      final basePpm = 315 + (co2Level - 315) * math.pow(frac, 1.8);
      // Seasonal wiggle (Keeling sawtooth)
      final wiggle = math.sin(frac * math.pi * 2 * 30 + time * 0.5) * 2.5;
      final ppm = basePpm + wiggle;
      final normPpm = (ppm - 315) / (co2Level - 315 + 0.01);
      final y = tsBot - normPpm.clamp(0.0, 1.0) * tsH;
      final x = tsLeft + px;
      if (px == 0) {
        co2Path.moveTo(x, y);
      } else {
        co2Path.lineTo(x, y);
      }
    }
    canvas.drawPath(co2Path, Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    _label(canvas, 'CO₂ 농도 추이 (1950→현재)', Offset(tsLeft + 4, tsTop - 2), fs: 7, col: const Color(0xFF5A8A9A));
    _label(canvas, '${co2Level.toStringAsFixed(0)} ppm', Offset(tsRight - 32, tsTop + 4), fs: 9, col: const Color(0xFF00D4FF));

    // ---- Greenhouse effect diagram (bottom) ----
    final diagY = tsBot + 14;
    final diagH = h - diagY - 4;
    if (diagH < 20) return;

    // Sun arrow down
    canvas.drawLine(Offset(w * 0.12, diagY + 2), Offset(w * 0.12, diagY + diagH * 0.5),
        Paint()..color = const Color(0xFFFFD700)..strokeWidth = 2);
    _drawArrowHead(canvas, Offset(w * 0.12, diagY + diagH * 0.5), const Color(0xFFFFD700));
    _label(canvas, '태양', Offset(w * 0.04, diagY), fs: 8, col: const Color(0xFFFFD700));

    // Ground
    canvas.drawLine(Offset(w * 0.05, diagY + diagH * 0.7), Offset(w * 0.95, diagY + diagH * 0.7),
        Paint()..color = const Color(0xFF4A7C3F)..strokeWidth = 2);
    _label(canvas, '지표', Offset(w * 0.05, diagY + diagH * 0.72), fs: 7, col: const Color(0xFF4A7C3F));

    // IR up arrow
    canvas.drawLine(Offset(w * 0.35, diagY + diagH * 0.68), Offset(w * 0.35, diagY + diagH * 0.15),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);
    _drawArrowHead(canvas, Offset(w * 0.35, diagY + diagH * 0.15), const Color(0xFFFF6B35), up: true);
    _label(canvas, '적외선', Offset(w * 0.36, diagY + diagH * 0.3), fs: 7, col: const Color(0xFFFF6B35));

    // Greenhouse gas layer
    final forcing = 5.35 * math.log(co2Level / 280);
    final layerAlpha = (0.2 + forcing * 0.08).clamp(0.15, 0.75);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.05, diagY + diagH * 0.15, w * 0.9, diagH * 0.25),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: layerAlpha),
    );
    _label(canvas, '온실 기체층  CO₂=${co2Level.toStringAsFixed(0)}ppm', Offset(w * 0.08, diagY + diagH * 0.24), fs: 7, col: const Color(0xFFE0F4FF));

    // Re-emission arrow down
    canvas.drawLine(Offset(w * 0.65, diagY + diagH * 0.4), Offset(w * 0.65, diagY + diagH * 0.68),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)..strokeWidth = 2);
    _drawArrowHead(canvas, Offset(w * 0.65, diagY + diagH * 0.68), const Color(0xFFFF6B35).withValues(alpha: 0.7));
    _label(canvas, '재방출', Offset(w * 0.66, diagY + diagH * 0.52), fs: 7, col: const Color(0xFFFF6B35));

    // Temperature rise label
    final tempRise = forcing * 0.8;
    final tempCol = tempRise > 2 ? const Color(0xFFFF6B35) : const Color(0xFF00D4FF);
    _label(canvas, '+${tempRise.toStringAsFixed(1)}°C', Offset(w * 0.78, diagY + 2), fs: 10, col: tempCol);
    _label(canvas, '예상 기온 상승', Offset(w * 0.68, diagY + 14), fs: 7, col: const Color(0xFF5A8A9A));
  }

  void _drawArrowHead(Canvas canvas, Offset tip, Color color, {bool up = false}) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    if (up) {
      path.moveTo(tip.dx, tip.dy);
      path.lineTo(tip.dx - 5, tip.dy + 8);
      path.lineTo(tip.dx + 5, tip.dy + 8);
    } else {
      path.moveTo(tip.dx, tip.dy);
      path.lineTo(tip.dx - 5, tip.dy - 8);
      path.lineTo(tip.dx + 5, tip.dy - 8);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GreenhouseGasesScreenPainter oldDelegate) => true;
}
