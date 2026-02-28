import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class StefanBoltzmannScreen extends StatefulWidget {
  const StefanBoltzmannScreen({super.key});
  @override
  State<StefanBoltzmannScreen> createState() => _StefanBoltzmannScreenState();
}

class _StefanBoltzmannScreenState extends State<StefanBoltzmannScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _temperature = 5778;
  
  double _power = 0, _peakWave = 500;

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
      _power = 5.67e-8 * math.pow(_temperature, 4).toDouble();
      _peakWave = 2.898e6 / _temperature;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _temperature = 5778.0;
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
          Text('물리 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('슈테판-볼츠만 복사', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '슈테판-볼츠만 복사',
          formula: 'P = εσAT⁴',
          formulaDescription: '슈테판-볼츠만 법칙에 따른 열복사를 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _StefanBoltzmannScreenPainter(
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
                label: '온도 (K)',
                value: _temperature,
                min: 300,
                max: 30000,
                step: 100,
                defaultValue: 5778,
                formatValue: (v) => v.toStringAsFixed(0) + ' K',
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
          _V('P', (_power / 1e6).toStringAsFixed(1) + ' MW/m²'),
          _V('λ_max', _peakWave.toStringAsFixed(0) + ' nm'),
          _V('T', _temperature.toStringAsFixed(0) + ' K'),
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

class _StefanBoltzmannScreenPainter extends CustomPainter {
  final double time;
  final double temperature;

  _StefanBoltzmannScreenPainter({
    required this.time,
    required this.temperature,
  });

  // Map temperature to body color (blackbody approximation)
  Color _tempToColor(double t) {
    if (t < 800) return const Color(0xFF1A0800);
    if (t < 1500) return Color.fromARGB(255, (80 + (t - 800) / 700 * 120).round().clamp(0, 255), 10, 0);
    if (t < 3000) return Color.fromARGB(255, 200, ((t - 1500) / 1500 * 80).round().clamp(0, 80), 0);
    if (t < 5000) return Color.fromARGB(255, 255, ((t - 3000) / 2000 * 140).round().clamp(0, 140), ((t - 3000) / 2000 * 30).round().clamp(0, 30));
    if (t < 8000) return Color.fromARGB(255, 255, (140 + (t - 5000) / 3000 * 115).round().clamp(0, 255), ((t - 5000) / 3000 * 180).round().clamp(0, 180));
    return Color.fromARGB(255, 255, 255, ((t - 8000) / 22000 * 255).round().clamp(180, 255));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A0A0F));

    final w = size.width;
    final h = size.height;

    // Grid
    final gridPaint = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.3)..strokeWidth = 0.5;
    for (double x = 0; x < w; x += 30) { canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint); }
    for (double y = 0; y < h; y += 30) { canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint); }

    // Derived
    final sigma = 5.67e-8;
    final power = sigma * math.pow(temperature, 4).toDouble();
    final peakNm = 2.898e6 / temperature;
    final bodyColor = _tempToColor(temperature);

    // Normalized glow radius: proportional to T^4, capped for display
    final tNorm = (temperature / 6000.0).clamp(0.05, 5.0);
    final baseR = h * 0.10;
    final glowR = (baseR * math.pow(tNorm, 0.5)).clamp(baseR * 0.3, h * 0.25);

    final bodyCx = w * 0.38;
    final bodyCy = h * 0.40;

    // --- Glow layers (outermost first) ---
    final numGlowLayers = 5;
    for (int g = numGlowLayers; g >= 1; g--) {
      final glowFrac = g / numGlowLayers;
      final layerR = glowR * (1.0 + glowFrac * 1.8);
      canvas.drawCircle(
        Offset(bodyCx, bodyCy),
        layerR,
        Paint()
          ..color = bodyColor.withValues(alpha: 0.04 + (1 - glowFrac) * 0.06 * tNorm.clamp(0.0, 1.0))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, layerR * 0.5),
      );
    }

    // --- Body circle ---
    canvas.drawCircle(Offset(bodyCx, bodyCy), glowR, Paint()..color = bodyColor);
    canvas.drawCircle(
      Offset(bodyCx, bodyCy),
      glowR,
      Paint()..color = Colors.white.withValues(alpha: 0.08 * tNorm.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // --- Radiation arrows (wavy lines outward) ---
    final numRays = 10;
    final rayLen = (20 + tNorm * 35).clamp(20.0, 55.0);
    final rayStart = glowR + 4;
    for (int r = 0; r < numRays; r++) {
      final angle = r * 2 * math.pi / numRays + time * 0.3;
      final rayPaint = Paint()
        ..color = bodyColor.withValues(alpha: 0.6)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      final path = Path();
      final x0 = bodyCx + rayStart * math.cos(angle);
      final y0 = bodyCy + rayStart * math.sin(angle);
      path.moveTo(x0, y0);
      const waveAmp = 2.5;
      const waveFreq = 4.0;
      for (double d = 0; d <= rayLen; d += 2) {
        final t2 = d / rayLen;
        final perpX = -math.sin(angle);
        final perpY = math.cos(angle);
        final wave = waveAmp * math.sin(t2 * waveFreq * math.pi);
        path.lineTo(
          x0 + d * math.cos(angle) + wave * perpX,
          y0 + d * math.sin(angle) + wave * perpY,
        );
      }
      canvas.drawPath(path, rayPaint);
    }

    // --- Planck spectrum curve (right side) ---
    final specLeft = w * 0.58;
    final specBot = h * 0.70;
    final specW = w * 0.36;
    final specH = h * 0.40;
    final specTop = specBot - specH;

    // Axes
    canvas.drawLine(Offset(specLeft, specBot), Offset(specLeft + specW, specBot), Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(specLeft, specTop), Offset(specLeft, specBot), Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _drawLabel(canvas, 'λ (nm)', Offset(specLeft + specW - 10, specBot + 10), const Color(0xFF5A8A9A), 8);
    _drawLabel(canvas, 'I', Offset(specLeft - 8, specTop + 8), const Color(0xFF5A8A9A), 8);

    // Planck curve: B(λ,T) ∝ λ^-5 / (exp(hc/λkT) - 1)
    // Approximate: normalized for display
    const h2 = 6.626e-34;
    const c2 = 3e8;
    const k = 1.38e-23;
    double maxB = 0;
    for (double nm = 100; nm <= 3000; nm += 50) {
      final lam = nm * 1e-9;
      final exponent = (h2 * c2) / (lam * k * temperature);
      if (exponent < 700) {
        final b = 1.0 / (math.pow(lam, 5) * (math.exp(exponent) - 1));
        if (b > maxB) maxB = b;
      }
    }

    final specPath = Path();
    bool firstSpec = true;
    for (double nm = 100; nm <= 3000; nm += 20) {
      final lam = nm * 1e-9;
      final exponent = (h2 * c2) / (lam * k * temperature);
      if (exponent >= 700) continue;
      final b = 1.0 / (math.pow(lam, 5) * (math.exp(exponent) - 1));
      final px = specLeft + ((nm - 100) / 2900) * specW;
      final py = specBot - (b / (maxB > 0 ? maxB : 1)) * specH * 0.9;
      if (firstSpec) {
        specPath.moveTo(px, py);
        firstSpec = false;
      } else {
        specPath.lineTo(px, py);
      }
    }
    canvas.drawPath(
      specPath,
      Paint()..color = bodyColor.withValues(alpha: 0.85)..strokeWidth = 1.5..style = PaintingStyle.stroke,
    );

    // Peak wavelength marker
    final peakX = specLeft + ((peakNm - 100) / 2900).clamp(0.0, 1.0) * specW;
    canvas.drawLine(
      Offset(peakX, specTop),
      Offset(peakX, specBot),
      Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.35)..strokeWidth = 1,
    );
    _drawLabel(canvas, 'λ_max', Offset(peakX, specTop - 8), const Color(0xFFE0F4FF), 8);

    // --- Second body (cool reference, T=300K) for comparison ---
    final refCx = w * 0.72;
    final refCy = h * 0.40;
    final refR = baseR * 0.45;
    canvas.drawCircle(Offset(refCx, refCy), refR, Paint()..color = const Color(0xFF1A2030));
    canvas.drawCircle(Offset(refCx, refCy), refR, Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)..strokeWidth = 1..style = PaintingStyle.stroke);
    _drawLabel(canvas, '300K', Offset(refCx, refCy + refR + 10), const Color(0xFF5A8A9A), 8);

    // --- Temperature label on body ---
    _drawLabel(canvas, '${temperature.toStringAsFixed(0)}K', Offset(bodyCx, bodyCy + glowR + 14), bodyColor, 10, bold: true);

    // --- P = σAT⁴ values ---
    final powerStr = power > 1e9
        ? '${(power / 1e9).toStringAsFixed(1)} GW/m²'
        : power > 1e6
            ? '${(power / 1e6).toStringAsFixed(1)} MW/m²'
            : '${(power / 1e3).toStringAsFixed(1)} kW/m²';
    _drawLabel(canvas, 'P = σAT⁴', Offset(w * 0.27, h * 0.76), const Color(0xFFE0F4FF), 10);
    _drawLabel(canvas, '= $powerStr', Offset(w * 0.27, h * 0.83), const Color(0xFF00D4FF), 10);
    _drawLabel(canvas, 'λ_max = ${peakNm.toStringAsFixed(0)} nm', Offset(w * 0.27, h * 0.90), const Color(0xFFFF6B35), 9);

    // Title
    _drawLabel(canvas, '슈테판-볼츠만 흑체 복사', Offset(w / 2, 14), const Color(0xFF00D4FF), 12, bold: true);
  }

  void _drawLabel(Canvas canvas, String text, Offset center, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _StefanBoltzmannScreenPainter oldDelegate) => true;
}
