import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class FermiDiracScreen extends StatefulWidget {
  const FermiDiracScreen({super.key});
  @override
  State<FermiDiracScreen> createState() => _FermiDiracScreenState();
}

class _FermiDiracScreenState extends State<FermiDiracScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _temperature = 300;
  double _fermiEnergy = 5;
  double _kT = 0;

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
      _kT = 8.617e-5 * _temperature;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _temperature = 300; _fermiEnergy = 5.0;
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
          const Text('페르미-디랙 분포', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '페르미-디랙 분포',
          formula: 'f(E)=1/(e^{(E-μ)/kT}+1)',
          formulaDescription: '다른 온도에서 페르미-디랙 분포를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _FermiDiracScreenPainter(
                time: _time,
                temperature: _temperature,
                fermiEnergy: _fermiEnergy,
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
                min: 10,
                max: 10000,
                step: 100,
                defaultValue: 300,
                formatValue: (v) => '${v.toStringAsFixed(0)} K',
                onChanged: (v) => setState(() => _temperature = v),
              ),
              advancedControls: [
            SimSlider(
                label: '페르미 에너지 (eV)',
                value: _fermiEnergy,
                min: 0.1,
                max: 10,
                step: 0.1,
                defaultValue: 5,
                formatValue: (v) => '${v.toStringAsFixed(1)} eV',
                onChanged: (v) => setState(() => _fermiEnergy = v),
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
          _V('kT', '${_kT.toStringAsFixed(4)} eV'),
          _V('E_F', '${_fermiEnergy.toStringAsFixed(1)} eV'),
          _V('T', '${_temperature.toStringAsFixed(0)} K'),
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

class _FermiDiracScreenPainter extends CustomPainter {
  final double time;
  final double temperature;
  final double fermiEnergy;

  _FermiDiracScreenPainter({
    required this.time,
    required this.temperature,
    required this.fermiEnergy,
  });

  void _label(Canvas canvas, String text, Offset offset,
      {double fontSize = 9, Color color = const Color(0xFF5A8A9A)}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  // Fermi-Dirac distribution: f(E) = 1 / (exp((E-Ef)/kT) + 1)
  double _fd(double e, double ef, double kT) {
    if (kT < 1e-10) return e < ef ? 1.0 : 0.0;
    final x = (e - ef) / kT;
    if (x > 50) return 0.0;
    if (x < -50) return 1.0;
    return 1.0 / (math.exp(x) + 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Layout: left 58% = f(E) plot, right 42% = D(E)*f(E) electron distribution
    final splitX = w * 0.58;

    // ---- LEFT: Fermi-Dirac curves ----
    final padL = 34.0, padR = 8.0, padT = 14.0, padB = 22.0;
    final plotW = splitX - padL - padR;
    final plotH = h - padT - padB;
    final plotBot = padT + plotH;

    // E axis: 0 to 2*Ef
    final eMax = fermiEnergy * 2.0;
    double eToX(double e) => padL + (e / eMax).clamp(0.0, 1.0) * plotW;
    double fToY(double f) => plotBot - f * plotH;

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1;
    canvas.drawLine(Offset(padL, padT), Offset(padL, plotBot), axisPaint);
    canvas.drawLine(Offset(padL, plotBot), Offset(padL + plotW, plotBot), axisPaint);
    _label(canvas, 'E/E_F', Offset(padL + plotW - 20, plotBot + 4), fontSize: 8);
    _label(canvas, 'f(E)', Offset(2, padT), fontSize: 8);

    // Y-axis ticks
    for (int i = 0; i <= 4; i++) {
      final f = i / 4.0;
      final y = fToY(f);
      canvas.drawLine(Offset(padL - 3, y), Offset(padL, y), axisPaint);
      _label(canvas, f.toStringAsFixed(2), Offset(2, y - 5), fontSize: 7);
    }
    // X-axis ticks
    for (int i = 0; i <= 4; i++) {
      final e = i / 4.0 * eMax;
      final x = eToX(e);
      canvas.drawLine(Offset(x, plotBot), Offset(x, plotBot + 3), axisPaint);
      _label(canvas, (i / 2.0).toStringAsFixed(1), Offset(x - 5, plotBot + 5), fontSize: 7);
    }

    // Draw multiple temperature curves
    final temps = [0.0, 300.0, 1000.0, 5000.0];
    final tempColors = [
      const Color(0xFF00D4FF),
      const Color(0xFF64FF8C),
      const Color(0xFFFF6B35),
      const Color(0xFFFFD700),
    ];
    final kb = 8.617e-5; // eV/K

    for (int ti = 0; ti < temps.length; ti++) {
      final T = ti == 1 ? temperature : temps[ti];
      final kT = kb * T;
      final color = ti == 1
          ? (temperature < 500
              ? const Color(0xFF64FF8C)
              : temperature < 2000
                  ? const Color(0xFFFF6B35)
                  : const Color(0xFFFFD700))
          : tempColors[ti];

      final path = Path();
      bool first = true;
      for (int i = 0; i <= 200; i++) {
        final e = i / 200.0 * eMax;
        final f = _fd(e, fermiEnergy, kT);
        final x = eToX(e);
        final y = fToY(f);
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      final strokeW = (ti == 0) ? 2.0 : 1.5;
      canvas.drawPath(path,
          Paint()..color = color..strokeWidth = strokeW..style = PaintingStyle.stroke);

      // Label at right edge
      final fRight = _fd(eMax * 0.95, fermiEnergy, kT);
      final lx = eToX(eMax * 0.95) + 2;
      final ly = fToY(fRight) - 8;
      if (ti == 0) {
        _label(canvas, 'T=0', Offset(lx, ly.clamp(padT, plotBot - 10)), color: color, fontSize: 8);
      }
    }

    // Current T label
    final kTcurrent = kb * temperature;
    _label(canvas, 'T=${temperature.toStringAsFixed(0)}K  kT=${(kTcurrent * 1000).toStringAsFixed(2)}meV',
        Offset(padL + 2, padT), color: const Color(0xFF64FF8C), fontSize: 8);

    // Ef vertical line (dashed)
    final efX = eToX(fermiEnergy);
    for (double dy = padT; dy < plotBot; dy += 8) {
      canvas.drawLine(Offset(efX, dy), Offset(efX, dy + 4),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.8)..strokeWidth = 1);
    }
    _label(canvas, 'E_F', Offset(efX + 2, padT), color: const Color(0xFFFF6B35), fontSize: 8);

    // f=0.5 horizontal dashed line
    final halfY = fToY(0.5);
    for (double dx = padL; dx < padL + plotW; dx += 8) {
      canvas.drawLine(Offset(dx, halfY), Offset(dx + 4, halfY),
          Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..strokeWidth = 1);
    }
    _label(canvas, '0.5', Offset(padL + plotW + 2, halfY - 5),
        color: const Color(0xFF5A8A9A), fontSize: 8);

    // ---- RIGHT: Electron energy distribution D(E)*f(E) ----
    canvas.drawLine(Offset(splitX, 0), Offset(splitX, h),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    final rPadL = 10.0, rPadR = 12.0;
    final rLeft = splitX + rPadL;
    final rRight = w - rPadR;
    final rW = rRight - rLeft;
    final rPadT = padT, rPadB = padB;
    final rH = h - rPadT - rPadB;
    final rBot = rPadT + rH;

    // D(E) ~ sqrt(E), n(E) = D(E)*f(E)
    // X axis: n(E) (horizontal), Y axis: E (vertical)
    double defy(double e) {
      // sqrt(E) * f(E), normalized
      final de = math.sqrt(e / fermiEnergy);
      return de * _fd(e, fermiEnergy, kb * temperature);
    }

    // Find max for normalization
    double nMax = 0;
    for (int i = 1; i <= 100; i++) {
      final e = i / 100.0 * eMax;
      final n = defy(e);
      if (n > nMax) nMax = n;
    }
    if (nMax < 1e-10) nMax = 1;

    // Axes
    canvas.drawLine(Offset(rLeft, rPadT), Offset(rLeft, rBot), axisPaint);
    canvas.drawLine(Offset(rLeft, rBot), Offset(rRight, rBot), axisPaint);
    _label(canvas, 'n(E)', Offset(rLeft + rW / 2 - 8, rBot + 5), fontSize: 8);
    _label(canvas, 'E', Offset(rLeft - 10, rPadT), fontSize: 8);

    // Fill curve
    final nPath = Path()..moveTo(rLeft, rBot);
    for (int i = 0; i <= 200; i++) {
      final e = i / 200.0 * eMax;
      final eY = rPadT + rH * (1.0 - e / eMax);
      final nX = rLeft + (defy(e) / nMax) * rW;
      nPath.lineTo(nX, eY);
    }
    nPath.lineTo(rLeft, rPadT);
    nPath.close();
    canvas.drawPath(nPath, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.2));

    // Stroke
    final nStroke = Path()..moveTo(rLeft, rBot);
    for (int i = 0; i <= 200; i++) {
      final e = i / 200.0 * eMax;
      final eY = rPadT + rH * (1.0 - e / eMax);
      final nX = rLeft + (defy(e) / nMax) * rW;
      nStroke.lineTo(nX, eY);
    }
    canvas.drawPath(nStroke,
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Ef line on right plot
    final efY = rPadT + rH * (1.0 - fermiEnergy / eMax);
    for (double dx = rLeft; dx < rRight; dx += 6) {
      canvas.drawLine(Offset(dx, efY), Offset(dx + 3, efY),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)..strokeWidth = 1);
    }
    _label(canvas, 'E_F', Offset(rLeft + 2, efY - 11), color: const Color(0xFFFF6B35), fontSize: 8);
    _label(canvas, 'n(E)=D(E)·f(E)', Offset(rLeft + 2, rPadT),
        color: const Color(0xFF5A8A9A), fontSize: 8);
  }

  @override
  bool shouldRepaint(covariant _FermiDiracScreenPainter oldDelegate) => true;
}
