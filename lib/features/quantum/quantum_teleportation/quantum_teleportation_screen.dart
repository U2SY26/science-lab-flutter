import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class QuantumTeleportationScreen extends StatefulWidget {
  const QuantumTeleportationScreen({super.key});
  @override
  State<QuantumTeleportationScreen> createState() => _QuantumTeleportationScreenState();
}

class _QuantumTeleportationScreenState extends State<QuantumTeleportationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _theta = 0.5;
  double _phi = 0.0;
  int _currentStep = 0; double _fidelity = 0;

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
      _currentStep = ((_time * 0.4).toInt() % 5);
      _fidelity = _currentStep >= 4 ? 1.0 : 0.0;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _theta = 0.5;
      _phi = 0.0;
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
          const Text('양자 텔레포테이션', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '양자 텔레포테이션',
          formula: '|ψ⟩ → Bell pair → Measure → Correct',
          formulaDescription: '얽힌 큐비트를 이용하여 양자 상태를 전송합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _QuantumTeleportationScreenPainter(
                time: _time,
                theta: _theta,
                phi: _phi,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'Bloch 각도 θ',
                value: _theta,
                min: 0.0,
                max: 3.14,
                step: 0.05,
                defaultValue: 0.5,
                formatValue: (v) => '${(v * 180 / math.pi).toStringAsFixed(0)}°',
                onChanged: (v) => setState(() => _theta = v),
              ),
              advancedControls: [
            SimSlider(
                label: '위상 φ',
                value: _phi,
                min: 0.0,
                max: 6.28,
                step: 0.05,
                defaultValue: 0.0,
                formatValue: (v) => '${(v * 180 / math.pi).toStringAsFixed(0)}°',
                onChanged: (v) => setState(() => _phi = v),
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
          _V('단계', '${_currentStep + 1}/5'),
          _V('충실도', '${_fidelity.toStringAsFixed(1)}'),
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

class _QuantumTeleportationScreenPainter extends CustomPainter {
  final double time;
  final double theta;
  final double phi;

  _QuantumTeleportationScreenPainter({
    required this.time,
    required this.theta,
    required this.phi,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontFamily: 'monospace')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawLabelLeft(Canvas canvas, String text, Offset pos, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontFamily: 'monospace')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _drawBlochSphere(Canvas canvas, Offset center, double r, double th, double ph, Color color, String label) {
    final strokeP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1..style = PaintingStyle.stroke;
    final fillP = Paint()..color = const Color(0xFF0D1A20);
    canvas.drawCircle(center, r, fillP);
    canvas.drawCircle(center, r, strokeP);
    // Equator ellipse
    final eqRect = Rect.fromCenter(center: center, width: r * 2, height: r * 0.6);
    canvas.drawArc(eqRect, 0, math.pi, false, strokeP);
    final dashedP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5..style = PaintingStyle.stroke;
    canvas.drawArc(eqRect, math.pi, math.pi, false, dashedP);
    // Axes
    final axisP = Paint()..color = const Color(0xFF2A4050)..strokeWidth = 1..style = PaintingStyle.stroke;
    canvas.drawLine(center - Offset(0, r), center + Offset(0, r), axisP);
    // State vector
    final vx = r * math.sin(th) * math.cos(ph);
    final vy = -r * math.cos(th);
    final vecP = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(center, center + Offset(vx, vy), vecP);
    final headSize = 5.0;
    final tip = center + Offset(vx, vy);
    canvas.drawCircle(tip, headSize / 2, Paint()..color = color);
    // Label
    _drawLabel(canvas, label, center - Offset(0, r + 10), color, 9);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // ---- Title ----
    _drawLabel(canvas, '양자 텔레포테이션 프로토콜', Offset(w / 2, 14), const Color(0xFF00D4FF), 12);

    // ---- Section split: top 55% = circuit, bottom 45% = bloch ----
    final circuitH = h * 0.55;

    // ====== QUANTUM CIRCUIT DIAGRAM ======
    // 3 qubit lines
    final lineColors = [const Color(0xFF00D4FF), const Color(0xFF64FF8C), const Color(0xFFFF6B35)];
    final lineLabels = ['|ψ⟩ Alice', 'EPR₁ Alice', 'EPR₂ Bob'];
    final yLines = [circuitH * 0.25, circuitH * 0.55, circuitH * 0.80];
    final xStart = 52.0, xEnd = w - 10.0;

    for (int i = 0; i < 3; i++) {
      final lp = Paint()..color = lineColors[i].withValues(alpha: 0.4)..strokeWidth = 1.5..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(xStart, yLines[i]), Offset(xEnd, yLines[i]), lp);
      _drawLabelLeft(canvas, lineLabels[i], Offset(2, yLines[i] - 6), lineColors[i], 8);
    }

    // EPR source (Bell pair generator) in center-left
    final eprX = xStart + (xEnd - xStart) * 0.18;
    final eprRect = Rect.fromCenter(center: Offset(eprX, (yLines[1] + yLines[2]) / 2), width: 34, height: 44);
    canvas.drawRRect(RRect.fromRectAndRadius(eprRect, const Radius.circular(4)),
        Paint()..color = const Color(0xFF1A3040));
    canvas.drawRRect(RRect.fromRectAndRadius(eprRect, const Radius.circular(4)),
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1..style = PaintingStyle.stroke);
    _drawLabel(canvas, 'Bell', Offset(eprX, (yLines[1] + yLines[2]) / 2 - 5), const Color(0xFF64FF8C), 8);
    _drawLabel(canvas, 'Pair', Offset(eprX, (yLines[1] + yLines[2]) / 2 + 5), const Color(0xFF64FF8C), 8);
    // Entanglement line
    final entP = Paint()
      ..color = const Color(0xFF64FF8C).withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(eprX, yLines[1]), Offset(eprX, yLines[2]), entP);

    // Animated entanglement wave on the EPR line
    final wavePath = Path();
    final waveAmp = 4.0;
    final waveFreq = 4.0;
    for (double dx = 0; dx <= 1.0; dx += 0.05) {
      final xi = eprX + (xEnd * 0.5 - eprX) * dx;
      final yi1 = yLines[1] + waveAmp * math.sin(dx * math.pi * waveFreq + time * 3);
      if (dx == 0) { wavePath.moveTo(xi, yi1); } else { wavePath.lineTo(xi, yi1); }
    }
    canvas.drawPath(wavePath, Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.35)..strokeWidth = 1..style = PaintingStyle.stroke);

    // CNOT gate (Alice qubit 0 controls qubit 1)
    final cnotX = xStart + (xEnd - xStart) * 0.38;
    // Control dot on line 0
    canvas.drawCircle(Offset(cnotX, yLines[0]), 5, Paint()..color = const Color(0xFF00D4FF));
    // CNOT target on line 1
    canvas.drawCircle(Offset(cnotX, yLines[1]), 10, Paint()..color = const Color(0xFF0D1A20));
    canvas.drawCircle(Offset(cnotX, yLines[1]), 10, Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(cnotX - 10, yLines[1]), Offset(cnotX + 10, yLines[1]),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5);
    canvas.drawLine(Offset(cnotX, yLines[0] + 5), Offset(cnotX, yLines[1] - 10),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5);

    // H gate (Hadamard) on qubit 0
    final hX = cnotX + 30.0;
    final hRect = Rect.fromCenter(center: Offset(hX, yLines[0]), width: 22, height: 18);
    canvas.drawRRect(RRect.fromRectAndRadius(hRect, const Radius.circular(3)),
        Paint()..color = const Color(0xFF1A3040));
    canvas.drawRRect(RRect.fromRectAndRadius(hRect, const Radius.circular(3)),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1..style = PaintingStyle.stroke);
    _drawLabel(canvas, 'H', Offset(hX, yLines[0]), const Color(0xFF00D4FF), 10);

    // Measurement boxes
    final mX0 = hX + 30.0;
    for (int qi = 0; qi < 2; qi++) {
      final mRect = Rect.fromCenter(center: Offset(mX0, yLines[qi]), width: 22, height: 18);
      canvas.drawRRect(RRect.fromRectAndRadius(mRect, const Radius.circular(3)),
          Paint()..color = const Color(0xFF1A3040));
      canvas.drawRRect(RRect.fromRectAndRadius(mRect, const Radius.circular(3)),
          Paint()..color = lineColors[qi]..strokeWidth = 1..style = PaintingStyle.stroke);
      // Meter arc
      final meterPath = Path();
      meterPath.moveTo(mX0 - 7, yLines[qi] + 2);
      meterPath.quadraticBezierTo(mX0, yLines[qi] - 5, mX0 + 7, yLines[qi] + 2);
      canvas.drawPath(meterPath, Paint()..color = lineColors[qi]..strokeWidth = 1..style = PaintingStyle.stroke);
      canvas.drawLine(Offset(mX0, yLines[qi] + 2), Offset(mX0 + 5, yLines[qi] - 3),
          Paint()..color = lineColors[qi]..strokeWidth = 1);
    }

    // Classical communication (dashed) from measurement to Bob
    final classX = mX0 + 14;
    final bobCorrX = classX + (xEnd - classX) * 0.35;
    final dashedClassP = Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)..strokeWidth = 1.2..style = PaintingStyle.stroke;
    // Dashed line effect - draw segments
    double cx0 = classX;
    while (cx0 < bobCorrX - 5) {
      canvas.drawLine(Offset(cx0, yLines[0]), Offset(math.min(cx0 + 6, bobCorrX), yLines[0]), dashedClassP);
      canvas.drawLine(Offset(cx0, yLines[1]), Offset(math.min(cx0 + 6, bobCorrX), yLines[1]), dashedClassP);
      cx0 += 10;
    }
    _drawLabel(canvas, '고전비트', Offset((classX + bobCorrX) / 2, yLines[0] - 10), const Color(0xFFFF6B35), 8);

    // Bob's correction gates (X, Z)
    final xGateX = bobCorrX + 5;
    final zGateX = xGateX + 30;
    for (int gi = 0; gi < 2; gi++) {
      final gx = gi == 0 ? xGateX : zGateX;
      final label = gi == 0 ? 'X' : 'Z';
      final gy = yLines[1 - gi];
      final gColor = gi == 0 ? const Color(0xFFFF6B35) : const Color(0xFF64FF8C);
      final gRect = Rect.fromCenter(center: Offset(gx, gy), width: 22, height: 18);
      canvas.drawRRect(RRect.fromRectAndRadius(gRect, const Radius.circular(3)),
          Paint()..color = const Color(0xFF1A3040));
      canvas.drawRRect(RRect.fromRectAndRadius(gRect, const Radius.circular(3)),
          Paint()..color = gColor..strokeWidth = 1..style = PaintingStyle.stroke);
      _drawLabel(canvas, label, Offset(gx, gy), gColor, 10);
    }

    // Bob output label
    _drawLabel(canvas, '|ψ⟩ 복원', Offset(xEnd - 20, yLines[2] - 10), const Color(0xFFFF6B35), 8);

    // Animated photon traveling on qubit line 2
    final photonX = xStart + ((xEnd - xStart) * ((time * 0.3) % 1.0));
    canvas.drawCircle(Offset(photonX, yLines[2]),
        4, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.9));

    // ====== BLOCH SPHERES (bottom section) ======
    final blochY = circuitH + (h - circuitH) / 2;
    final blochR = (h - circuitH) * 0.32;
    final aliceBlochX = w * 0.25;
    final bobBlochX = w * 0.75;

    _drawBlochSphere(canvas, Offset(aliceBlochX, blochY), blochR, theta, phi,
        const Color(0xFF00D4FF), '앨리스 |ψ⟩');
    // Bob gets the same state after teleportation (animate arriving)
    final bobAlpha = math.sin(time * 0.5).abs().clamp(0.3, 1.0);
    _drawBlochSphere(canvas, Offset(bobBlochX, blochY), blochR, theta, phi,
        const Color(0xFFFF6B35).withValues(alpha: bobAlpha), '밥 |ψ⟩ 복원');

    // Arrow between bloch spheres
    final arrowColor = const Color(0xFF64FF8C);
    final arrowP = Paint()..color = arrowColor..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(aliceBlochX + blochR + 4, blochY),
        Offset(bobBlochX - blochR - 4, blochY), arrowP);
    canvas.drawLine(Offset(bobBlochX - blochR - 10, blochY - 4),
        Offset(bobBlochX - blochR - 4, blochY), arrowP);
    canvas.drawLine(Offset(bobBlochX - blochR - 10, blochY + 4),
        Offset(bobBlochX - blochR - 4, blochY), arrowP);
    _drawLabel(canvas, '텔레포테이션', Offset((aliceBlochX + bobBlochX) / 2, blochY - blochR - 6),
        arrowColor, 8);
  }

  @override
  bool shouldRepaint(covariant _QuantumTeleportationScreenPainter oldDelegate) => true;
}
