import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class LeChatelierScreen extends StatefulWidget {
  const LeChatelierScreen({super.key});
  @override
  State<LeChatelierScreen> createState() => _LeChatelierScreenState();
}

class _LeChatelierScreenState extends State<LeChatelierScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _temperature = 300;
  double _pressure = 1;
  double _kEq = 1.0, _qr = 1.0;

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
      _kEq = math.exp(-5000 / _temperature + 10);
      _qr = _pressure * _kEq;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _temperature = 300.0; _pressure = 1.0;
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
          const Text('르 샤틀리에 원리', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '르 샤틀리에 원리',
          formula: 'K = [C]^c[D]^d / [A]^a[B]^b',
          formulaDescription: '평형 이동에 대한 르 샤틀리에 원리를 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _LeChatelierScreenPainter(
                time: _time,
                temperature: _temperature,
                pressure: _pressure,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '온도 (K)',
                value: _temperature,
                min: 200,
                max: 600,
                step: 10,
                defaultValue: 300,
                formatValue: (v) => v.toStringAsFixed(0) + ' K',
                onChanged: (v) => setState(() => _temperature = v),
              ),
              advancedControls: [
            SimSlider(
                label: '압력 (atm)',
                value: _pressure,
                min: 0.1,
                max: 10,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' atm',
                onChanged: (v) => setState(() => _pressure = v),
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
          _V('K', _kEq.toStringAsFixed(2)),
          _V('Q', _qr.toStringAsFixed(2)),
          _V('방향', _qr < _kEq ? '정방향' : _qr > _kEq ? '역방향' : '평형'),
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

class _LeChatelierScreenPainter extends CustomPainter {
  final double time;
  final double temperature;
  final double pressure;

  _LeChatelierScreenPainter({
    required this.time,
    required this.temperature,
    required this.pressure,
  });

  void _label(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 10, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // N2 + 3H2 <-> 2NH3 (Haber-Bosch)
    // Kp(T) ~ exp(-ΔH/RT), ΔH = -92 kJ/mol
    // Higher pressure → favors NH3 (fewer moles: 1+3=4 → 2)
    // Higher temperature → favors N2+H2 (reverse, endothermic direction)
    final kEq = math.exp(11000 / temperature - 12.0).clamp(0.001, 1000.0);
    // Simple equilibrium: N2 0.3+x, H2 0.9+3x, NH3 0.2-2x at equilibrium
    // Approximate: [NH3] proportional to kEq * pressure^2 effect
    final pressFactor = pressure * pressure; // P^2 effect for NH3 (mole count reduction)
    final totalK = kEq * pressFactor.clamp(0.1, 100.0);
    final nh3Frac = totalK / (1 + totalK);
    final n2Frac = (1 - nh3Frac) * 0.25;
    final h2Frac = (1 - nh3Frac) * 0.75;

    // Bar chart area
    const padL = 50.0, padT = 40.0, padB = 55.0;
    final barAreaW = w - padL - 20;
    final barAreaH = h - padT - padB;
    final barW = barAreaW / 5;

    // Axis
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0;
    canvas.drawLine(Offset(padL, padT), Offset(padL, padT + barAreaH), axisPaint);
    canvas.drawLine(Offset(padL, padT + barAreaH), Offset(padL + barAreaW, padT + barAreaH), axisPaint);

    // Y axis labels
    _label(canvas, '농도', Offset(4, padT - 8), const Color(0xFF5A8A9A), fontSize: 9);
    for (int i = 0; i <= 4; i++) {
      final yVal = i * 0.25;
      final yPos = padT + barAreaH - yVal * barAreaH;
      _label(canvas, yVal.toStringAsFixed(2), Offset(2, yPos - 5), const Color(0xFF5A8A9A), fontSize: 8);
      canvas.drawLine(Offset(padL - 3, yPos), Offset(padL, yPos), axisPaint);
    }

    // Helper to draw one bar
    void drawBar(int index, double fraction, String label, Color color) {
      final x = padL + index * barW + barW * 0.15;
      final bw = barW * 0.7;
      final bh = fraction.clamp(0.0, 1.0) * barAreaH;
      final rect = Rect.fromLTWH(x, padT + barAreaH - bh, bw, bh);
      canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.25));
      canvas.drawRect(rect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);
      _label(canvas, label, Offset(x + bw / 2 - 8, padT + barAreaH + 6), color, fontSize: 10);
      _label(canvas, fraction.toStringAsFixed(2), Offset(x + bw / 2 - 10, padT + barAreaH - bh - 14), color, fontSize: 9);
    }

    drawBar(0, n2Frac, 'N₂', const Color(0xFF00D4FF));
    drawBar(1, h2Frac, 'H₂', const Color(0xFF5A8A9A));
    drawBar(2, nh3Frac, 'NH₃', const Color(0xFF64FF8C));

    // Equilibrium direction arrow
    final qRatio = nh3Frac / (n2Frac * h2Frac * h2Frac * h2Frac + 0.0001);
    String direction;
    Color dirColor;
    if (qRatio < kEq * 0.9) {
      direction = '→ 정반응 (NH₃ 생성)';
      dirColor = const Color(0xFF64FF8C);
    } else if (qRatio > kEq * 1.1) {
      direction = '← 역반응';
      dirColor = const Color(0xFFFF6B35);
    } else {
      direction = '⇌ 평형';
      dirColor = const Color(0xFFFFD700);
    }

    // Reaction equation
    _label(canvas, 'N₂ + 3H₂ ⇌ 2NH₃', Offset(padL + 2, 10), const Color(0xFF00D4FF), fontSize: 11, bold: true);
    _label(canvas, 'ΔH = -92 kJ/mol', Offset(w - 100, 10), const Color(0xFFFF6B35), fontSize: 9);

    // K value
    _label(canvas, 'K = ${kEq.toStringAsFixed(3)}', Offset(padL + barAreaW * 0.65, padT + 6), const Color(0xFFFFD700), fontSize: 10);

    // Direction
    _label(canvas, direction, Offset(padL, padT + barAreaH + 28), dirColor, fontSize: 10, bold: true);

    // Condition indicators (pressure and temperature icons)
    final pressColor = pressure > 3 ? const Color(0xFFFF6B35) : const Color(0xFF00D4FF);
    final tempColor = temperature > 450 ? const Color(0xFFFF6B35) : const Color(0xFF64FF8C);
    _label(canvas, 'P: ${pressure.toStringAsFixed(1)} atm', Offset(w - 90, padT + barAreaH + 6), pressColor, fontSize: 9);
    _label(canvas, 'T: ${temperature.toStringAsFixed(0)} K', Offset(w - 90, padT + barAreaH + 18), tempColor, fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _LeChatelierScreenPainter oldDelegate) => true;
}
