import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class QuantumWellScreen extends StatefulWidget {
  const QuantumWellScreen({super.key});
  @override
  State<QuantumWellScreen> createState() => _QuantumWellScreenState();
}

class _QuantumWellScreenState extends State<QuantumWellScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _wellWidth = 1;
  double _wellDepth = 1;
  double _e1 = 0.04, _e2 = 0.16; int _boundStates = 3;

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
      final L = _wellWidth * 1e-9;
      _e1 = 3.8e-38 / (9.11e-31 * L * L) / 1.6e-19;
      _e2 = 4 * _e1;
      _boundStates = (_wellDepth / (_e1 > 0 ? _e1 : 0.01)).floor().clamp(1, 20);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _wellWidth = 1.0; _wellDepth = 1.0;
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
          const Text('양자 우물', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '양자 우물',
          formula: 'E_n = n²π²ħ²/(2mL²)',
          formulaDescription: '유한 깊이 양자 우물의 속박 상태를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _QuantumWellScreenPainter(
                time: _time,
                wellWidth: _wellWidth,
                wellDepth: _wellDepth,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '우물 너비 (nm)',
                value: _wellWidth,
                min: 0.1,
                max: 5,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' nm',
                onChanged: (v) => setState(() => _wellWidth = v),
              ),
              advancedControls: [
            SimSlider(
                label: '우물 깊이 (eV)',
                value: _wellDepth,
                min: 0.1,
                max: 10,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' eV',
                onChanged: (v) => setState(() => _wellDepth = v),
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
          _V('E₁', _e1.toStringAsFixed(3) + ' eV'),
          _V('E₂', _e2.toStringAsFixed(3) + ' eV'),
          _V('속박', '$_boundStates'),
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

class _QuantumWellScreenPainter extends CustomPainter {
  final double time;
  final double wellWidth;
  final double wellDepth;

  _QuantumWellScreenPainter({
    required this.time,
    required this.wellWidth,
    required this.wellDepth,
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

    // Layout margins
    final padL = 36.0, padR = 16.0, padT = 16.0, padB = 24.0;
    final plotW = w - padL - padR;
    final plotH = h - padT - padB;

    // Well geometry in plot coordinates
    final wellFrac = (wellWidth / 5.0).clamp(0.05, 1.0); // fraction of plot width
    final wellLeft = padL + plotW * (0.5 - wellFrac * 0.35);
    final wellRight = padL + plotW * (0.5 + wellFrac * 0.35);
    final wellPx = wellRight - wellLeft;

    // Energy mapping: E=0 at bottom, E=wellDepth at top of well
    // Y axis: padT = max energy (above well), padT+plotH = 0 (bottom)
    final eMax = wellDepth * 1.3;
    double eToY(double e) => padT + plotH * (1.0 - (e / eMax).clamp(0.0, 1.2));

    // Infinite well energy levels: En = n²π²ħ²/2mL²
    // In eV: En ≈ 3.81e-38 / (9.11e-31 * L² * 1.6e-19) where L in m
    final L = wellWidth * 1e-9;
    final e1 = (3.81e-38 / (9.11e-31 * L * L) / 1.6e-19).clamp(0.001, wellDepth * 2);

    final levelColors = [
      const Color(0xFF00D4FF),
      const Color(0xFF64FF8C),
      const Color(0xFFFF6B35),
    ];

    // Draw potential well walls
    final wallPaint = Paint()
      ..color = const Color(0xFF5A8A9A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final wallTop = eToY(eMax * 0.98);
    final wellBottom = eToY(0);

    // Left wall (extends upward from bottom)
    canvas.drawLine(Offset(wellLeft, wellBottom), Offset(wellLeft, wallTop), wallPaint);
    // Right wall
    canvas.drawLine(Offset(wellRight, wellBottom), Offset(wellRight, wallTop), wallPaint);
    // Bottom
    canvas.drawLine(Offset(wellLeft, wellBottom), Offset(wellRight, wellBottom), wallPaint);
    // Left extension outward (finite well tail region shown as dashed)
    final dashPaint = Paint()
      ..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(padL, wallTop), Offset(wellLeft, wallTop), dashPaint);
    canvas.drawLine(Offset(wellRight, wallTop), Offset(padL + plotW, wallTop), dashPaint);

    // Well depth label (V0)
    _label(canvas, 'V₀=${wellDepth.toStringAsFixed(1)}eV', Offset(padL, wallTop - 12),
        color: const Color(0xFF5A8A9A));

    // Draw energy levels and wavefunctions
    final maxN = 3;
    for (int n = 1; n <= maxN; n++) {
      final en = e1 * n * n;
      if (en > wellDepth) break;

      final ey = eToY(en);
      final color = levelColors[n - 1];

      // Energy level line
      final levelPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(wellLeft, ey), Offset(wellRight, ey), levelPaint);
      _label(canvas, 'n=$n  E=${en.toStringAsFixed(2)}eV', Offset(wellRight + 4, ey - 5),
          color: color, fontSize: 8);

      // Wavefunction ψn(x): amplitude scaled to fit between levels
      final waveAmp = plotH * 0.06;
      final wavePath = Path();
      bool first = true;
      const steps = 80;
      for (int s = 0; s <= steps; s++) {
        final t = s / steps;
        final px = wellLeft + t * wellPx;
        final xNorm = t; // 0..1 inside well
        final psi = math.sin(n * math.pi * xNorm);
        final py = ey - psi * waveAmp;
        if (first) {
          wavePath.moveTo(px, py);
          first = false;
        } else {
          wavePath.lineTo(px, py);
        }
      }
      final wavePaint = Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(wavePath, wavePaint);

      // Probability density fill |ψ|²
      final fillPath = Path();
      fillPath.moveTo(wellLeft, ey);
      for (int s = 0; s <= steps; s++) {
        final t = s / steps;
        final px = wellLeft + t * wellPx;
        final xNorm = t;
        final psi2 = math.pow(math.sin(n * math.pi * xNorm), 2).toDouble();
        final py = ey - psi2 * waveAmp * 0.8;
        fillPath.lineTo(px, py);
      }
      fillPath.lineTo(wellRight, ey);
      fillPath.close();
      canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.12));
    }

    // Y axis
    final axisPaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(padL, padT), Offset(padL, padT + plotH), axisPaint);
    _label(canvas, 'E(eV)', Offset(2, padT), color: const Color(0xFF5A8A9A), fontSize: 9);

    // X axis label
    _label(canvas, 'x (위치)', Offset(padL + plotW * 0.4, h - padB + 6),
        color: const Color(0xFF5A8A9A), fontSize: 9);

    // L label below well
    _label(canvas, 'L=${wellWidth.toStringAsFixed(1)}nm',
        Offset(wellLeft + wellPx / 2 - 18, wellBottom + 4),
        color: const Color(0xFF5A8A9A), fontSize: 9);

    // Outside-well decay tails (finite well effect)
    if (wellDepth < 5.0) {
      final decayLen = plotW * 0.12 * (1 - wellDepth / 10);
      for (int n = 1; n <= maxN; n++) {
        final en = e1 * n * n;
        if (en > wellDepth) break;
        final ey = eToY(en);
        final color = levelColors[n - 1];
        final tailPaint = Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        // Left tail
        final leftTailPath = Path()..moveTo(wellLeft, ey);
        for (int s = 1; s <= 20; s++) {
          final dx = s / 20.0 * decayLen;
          final decay = math.exp(-dx / decayLen * 3);
          leftTailPath.lineTo(wellLeft - dx, ey - decay * 6 * (n % 2 == 0 ? -1 : 1));
        }
        canvas.drawPath(leftTailPath, tailPaint);
        // Right tail
        final rightTailPath = Path()..moveTo(wellRight, ey);
        for (int s = 1; s <= 20; s++) {
          final dx = s / 20.0 * decayLen;
          final decay = math.exp(-dx / decayLen * 3);
          rightTailPath.lineTo(wellRight + dx, ey - decay * 6 * (n % 2 == 0 ? 1 : -1));
        }
        canvas.drawPath(rightTailPath, tailPaint);
      }
    }

    // Title
    _label(canvas, '양자 우물 (L=${wellWidth.toStringAsFixed(1)}nm, V₀=${wellDepth.toStringAsFixed(1)}eV)',
        Offset(padL, 2), color: const Color(0xFF00D4FF), fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _QuantumWellScreenPainter oldDelegate) => true;
}
