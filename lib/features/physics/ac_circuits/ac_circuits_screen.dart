import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class AcCircuitsScreen extends StatefulWidget {
  const AcCircuitsScreen({super.key});
  @override
  State<AcCircuitsScreen> createState() => _AcCircuitsScreenState();
}

class _AcCircuitsScreenState extends State<AcCircuitsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _resistance = 100;
  double _frequency = 60;
  double _impedance = 100, _phase = 0;

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
      final xl = 2 * math.pi * _frequency * 0.1;
      final xc = 1 / (2 * math.pi * _frequency * 0.00001);
      _impedance = math.sqrt(_resistance * _resistance + (xl - xc) * (xl - xc));
      _phase = math.atan2(xl - xc, _resistance) * 180 / math.pi;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _resistance = 100.0; _frequency = 60.0;
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
          const Text('교류 회로 분석', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '교류 회로 분석',
          formula: 'Z = √(R²+(XL-XC)²)',
          formulaDescription: 'RLC 교류 회로의 임피던스와 위상을 분석합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _AcCircuitsScreenPainter(
                time: _time,
                resistance: _resistance,
                frequency: _frequency,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '저항 R (Ω)',
                value: _resistance,
                min: 10,
                max: 1000,
                step: 10,
                defaultValue: 100,
                formatValue: (v) => v.toStringAsFixed(0) + ' Ω',
                onChanged: (v) => setState(() => _resistance = v),
              ),
              advancedControls: [
            SimSlider(
                label: '주파수 (Hz)',
                value: _frequency,
                min: 10,
                max: 1000,
                step: 10,
                defaultValue: 60,
                formatValue: (v) => v.toStringAsFixed(0) + ' Hz',
                onChanged: (v) => setState(() => _frequency = v),
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
          _V('Z', _impedance.toStringAsFixed(1) + ' Ω'),
          _V('위상', _phase.toStringAsFixed(1) + '°'),
          _V('f', _frequency.toStringAsFixed(0) + ' Hz'),
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

class _AcCircuitsScreenPainter extends CustomPainter {
  final double time;
  final double resistance;
  final double frequency;

  _AcCircuitsScreenPainter({
    required this.time,
    required this.resistance,
    required this.frequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Grid
    final gridPaint = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.4)..strokeWidth = 0.5;
    for (double x = 0; x < w; x += 30) { canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint); }
    for (double y = 0; y < h; y += 30) { canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint); }

    // Derived values
    final omega = 2 * math.pi * frequency;
    final xl = omega * 0.1;
    final xc = 1.0 / (omega * 0.00001);
    final z = math.sqrt(resistance * resistance + (xl - xc) * (xl - xc));
    final phase = math.atan2(xl - xc, resistance);
    final isResonance = (xl - xc).abs() < resistance * 0.15;

    // --- Waveform area (top half) ---
    final waveTop = h * 0.08;
    final waveH = h * 0.38;
    final waveCy = waveTop + waveH / 2;
    final waveAmp = waveH * 0.4;
    final waveW = w * 0.92;
    final waveLeft = w * 0.04;
    final cycles = 2.5;

    // Axis
    canvas.drawLine(
      Offset(waveLeft, waveCy),
      Offset(waveLeft + waveW, waveCy),
      Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1,
    );

    // Draw sinusoid helper
    void drawWave(Color color, double phaseOffset, double amp) {
      final path = Path();
      bool first = true;
      for (double px = 0; px <= waveW; px += 1.5) {
        final t = px / waveW * cycles * 2 * math.pi;
        final y = waveCy - amp * math.sin(t - time * omega * 0.05 + phaseOffset);
        if (first) {
          path.moveTo(waveLeft + px, y);
          first = false;
        } else {
          path.lineTo(waveLeft + px, y);
        }
      }
      canvas.drawPath(path, Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke);
    }

    // V_R (cyan, in phase with I)
    drawWave(const Color(0xFF00D4FF), 0, waveAmp * 0.7);
    // V_L (orange, leads 90°)
    drawWave(const Color(0xFFFF6B35), math.pi / 2, waveAmp * (xl / z).clamp(0.2, 1.0));
    // V_C (green, lags 90°)
    drawWave(const Color(0xFF64FF8C), -math.pi / 2, waveAmp * (xc / z).clamp(0.2, 1.0));
    // V_total (white, phase-shifted)
    drawWave(const Color(0xFFE0F4FF).withValues(alpha: 0.85), -phase, waveAmp);

    // Wave legend
    _drawLabel(canvas, 'V_R', Offset(waveLeft + waveW * 0.15, waveTop + 8), const Color(0xFF00D4FF), 9);
    _drawLabel(canvas, 'V_L', Offset(waveLeft + waveW * 0.38, waveTop + 8), const Color(0xFFFF6B35), 9);
    _drawLabel(canvas, 'V_C', Offset(waveLeft + waveW * 0.60, waveTop + 8), const Color(0xFF64FF8C), 9);
    _drawLabel(canvas, 'V_tot', Offset(waveLeft + waveW * 0.82, waveTop + 8), const Color(0xFFE0F4FF), 9);

    // Resonance glow
    if (isResonance) {
      canvas.drawRect(
        Rect.fromLTWH(waveLeft, waveTop, waveW, waveH),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      _drawLabel(canvas, '공진!', Offset(w / 2, waveTop + waveH + 6), const Color(0xFF00D4FF), 10);
    }

    // --- Phasor diagram (bottom left) ---
    final pCx = w * 0.28;
    final pCy = h * 0.78;
    final pR = h * 0.14;

    // Phasor circle guide
    canvas.drawCircle(
      Offset(pCx, pCy), pR,
      Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1..style = PaintingStyle.stroke,
    );

    // Rotating phasors
    final pAngle = time * omega * 0.04;
    void drawPhasor(Color color, double mag, double phOff) {
      final ax = pCx + mag * pR * math.cos(pAngle + phOff);
      final ay = pCy - mag * pR * math.sin(pAngle + phOff);
      canvas.drawLine(
        Offset(pCx, pCy), Offset(ax, ay),
        Paint()..color = color..strokeWidth = 2,
      );
      canvas.drawCircle(Offset(ax, ay), 3, Paint()..color = color);
    }
    drawPhasor(const Color(0xFF00D4FF), (resistance / z).clamp(0.1, 1.0), 0);
    drawPhasor(const Color(0xFFFF6B35), (xl / z).clamp(0.1, 1.0), math.pi / 2);
    drawPhasor(const Color(0xFF64FF8C), (xc / z).clamp(0.1, 1.0), -math.pi / 2);
    drawPhasor(const Color(0xFFE0F4FF), 1.0, -phase);
    _drawLabel(canvas, '위상도', Offset(pCx, pCy + pR + 10), const Color(0xFF5A8A9A), 9);

    // --- Circuit diagram (bottom right) ---
    final cLeft = w * 0.48;
    final cTop = h * 0.58;
    final cW = w * 0.48;
    final cH = h * 0.22;
    final cY = cTop + cH / 2;

    final wirePaint = Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    // Top wire segments: source → R → L → C → back
    final seg = cW / 4;
    // Bottom rail
    canvas.drawLine(Offset(cLeft, cY + cH / 2), Offset(cLeft + cW, cY + cH / 2), wirePaint);
    // Left vertical
    canvas.drawLine(Offset(cLeft, cY - cH / 2), Offset(cLeft, cY + cH / 2), wirePaint);
    // Right vertical
    canvas.drawLine(Offset(cLeft + cW, cY - cH / 2), Offset(cLeft + cW, cY + cH / 2), wirePaint);

    // AC source symbol
    final srcX = cLeft;
    canvas.drawCircle(Offset(srcX, cY), 9, wirePaint..color = const Color(0xFF00D4FF).withValues(alpha: 0.6));
    final srcPath = Path()..moveTo(srcX - 5, cY)..quadraticBezierTo(srcX - 2.5, cY - 5, srcX, cY)..quadraticBezierTo(srcX + 2.5, cY + 5, srcX + 5, cY);
    canvas.drawPath(srcPath, wirePaint..color = const Color(0xFF00D4FF)..strokeWidth = 1);

    // Wire from source to R
    canvas.drawLine(Offset(cLeft + 9, cY - cH / 2 + 9), Offset(cLeft + seg * 0.5, cY - cH / 2), wirePaint..color = const Color(0xFF5A8A9A).withValues(alpha: 0.8));
    canvas.drawLine(Offset(cLeft, cY - 9), Offset(cLeft, cY - cH / 2), wirePaint..color = const Color(0xFF5A8A9A).withValues(alpha: 0.8));

    // Top wire
    canvas.drawLine(Offset(cLeft, cY - cH / 2), Offset(cLeft + cW, cY - cH / 2), wirePaint..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5));

    // Resistor (zigzag)
    final rx = cLeft + seg * 0.8;
    final rPath = Path()..moveTo(rx, cY - cH / 2);
    for (int i = 0; i < 5; i++) {
      rPath.lineTo(rx + 4, cY - cH / 2 - (i.isEven ? 5 : -5));
      rPath.lineTo(rx + 8, cY - cH / 2);
    }
    canvas.drawPath(rPath, wirePaint..color = const Color(0xFF00D4FF)..strokeWidth = 1.5);
    _drawLabel(canvas, 'R', Offset(rx + 4, cY - cH / 2 - 12), const Color(0xFF00D4FF), 9);

    // Inductor (bumps)
    final lx = cLeft + seg * 1.7;
    final lPath = Path()..moveTo(lx, cY - cH / 2);
    for (int i = 0; i < 3; i++) {
      lPath.arcToPoint(
        Offset(lx + (i + 1) * 7.0, cY - cH / 2),
        radius: const Radius.circular(3.5),
        clockwise: false,
      );
    }
    canvas.drawPath(lPath, wirePaint..color = const Color(0xFFFF6B35)..strokeWidth = 1.5);
    _drawLabel(canvas, 'L', Offset(lx + 10, cY - cH / 2 - 12), const Color(0xFFFF6B35), 9);

    // Capacitor (two lines)
    final capX = cLeft + seg * 2.8;
    canvas.drawLine(Offset(capX, cY - cH / 2), Offset(capX + 8, cY - cH / 2), wirePaint..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5));
    canvas.drawLine(Offset(capX + 8, cY - cH / 2 - 6), Offset(capX + 8, cY - cH / 2 + 6), wirePaint..color = const Color(0xFF64FF8C)..strokeWidth = 2);
    canvas.drawLine(Offset(capX + 11, cY - cH / 2 - 6), Offset(capX + 11, cY - cH / 2 + 6), wirePaint..color = const Color(0xFF64FF8C)..strokeWidth = 2);
    canvas.drawLine(Offset(capX + 11, cY - cH / 2), Offset(capX + 19, cY - cH / 2), wirePaint..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5));
    _drawLabel(canvas, 'C', Offset(capX + 9, cY - cH / 2 - 13), const Color(0xFF64FF8C), 9);

    // Z label
    final zStr = 'Z=${z.toStringAsFixed(0)}Ω';
    _drawLabel(canvas, zStr, Offset(w * 0.75, h * 0.92), const Color(0xFFE0F4FF), 10);

    // Title
    _drawLabel(canvas, 'RLC 교류 회로', Offset(w / 2, 14), const Color(0xFF00D4FF), 12, bold: true);
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
  bool shouldRepaint(covariant _AcCircuitsScreenPainter oldDelegate) => true;
}
