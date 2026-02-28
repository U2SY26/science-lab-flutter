import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class AharonovBohmScreen extends StatefulWidget {
  const AharonovBohmScreen({super.key});
  @override
  State<AharonovBohmScreen> createState() => _AharonovBohmScreenState();
}

class _AharonovBohmScreenState extends State<AharonovBohmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _flux = 1;
  
  double _phaseShift = 0, _interference = 1.0;

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
      _phaseShift = 2 * math.pi * _flux;
      _interference = math.cos(_phaseShift / 2).abs();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _flux = 1.0;
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
          const Text('아하로노프-봄 효과', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '아하로노프-봄 효과',
          formula: 'Δφ = eΦ/ħc',
          formulaDescription: '자기 벡터 퍼텐셜에 의한 위상 이동을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _AharonovBohmScreenPainter(
                time: _time,
                flux: _flux,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '자기 선속 (Φ₀)',
                value: _flux,
                min: 0,
                max: 5,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => '${v.toStringAsFixed(1)} Φ₀',
                onChanged: (v) => setState(() => _flux = v),
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
          _V('Δφ', '${_phaseShift.toStringAsFixed(2)} rad'),
          _V('간섭', _interference.toStringAsFixed(3)),
          _V('Φ', '${_flux.toStringAsFixed(1)} Φ₀'),
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

class _AharonovBohmScreenPainter extends CustomPainter {
  final double time;
  final double flux;

  _AharonovBohmScreenPainter({
    required this.time,
    required this.flux,
  });

  void _drawText(Canvas canvas, String text, Offset offset,
      {double fontSize = 10, Color color = const Color(0xFFE0F4FF), bool bold = false, TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    double dx = offset.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Phase difference: Δφ = 2π·Φ/Φ₀
    final deltaPhase = 2 * math.pi * flux;
    // Interference amplitude: |ψ₁+ψ₂|² = 2+2cos(Δφ) → normalized
    final interferenceAmp = (1 + math.cos(deltaPhase)) / 2;

    // --- Layout ---
    // Left 60%: electron ring + solenoid diagram
    // Right 40%: interference pattern
    final diagRight = w * 0.60;
    final intLeft = diagRight + 4;

    // ===== Electron Ring Diagram =====
    final ringCx = diagRight * 0.5;
    final ringCy = h * 0.48;
    final ringR = math.min(diagRight * 0.28, h * 0.30);
    final solenoidR = ringR * 0.28;

    _drawText(canvas, '아하로노프-봄 효과', Offset(diagRight / 2, 6),
        fontSize: 9, color: const Color(0xFF00D4FF), bold: true, align: TextAlign.center);

    // Source (left) and detector (right)
    final srcX = ringCx - ringR - 18;
    final detX = ringCx + ringR + 18;

    // Draw incoming electron arrow
    canvas.drawLine(Offset(srcX - 14, ringCy), Offset(srcX, ringCy),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)..strokeWidth = 1.5);
    // Arrowhead
    final arrowPaint = Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)..style = PaintingStyle.fill;
    final arrPath = Path()
      ..moveTo(srcX, ringCy)
      ..lineTo(srcX - 6, ringCy - 4)
      ..lineTo(srcX - 6, ringCy + 4)
      ..close();
    canvas.drawPath(arrPath, arrowPaint);
    _drawText(canvas, 'e⁻', Offset(srcX - 22, ringCy - 10), fontSize: 9, color: const Color(0xFF00D4FF));

    // Outgoing arrow (detector)
    canvas.drawLine(Offset(detX, ringCy), Offset(detX + 14, ringCy),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)..strokeWidth = 1.5);

    // Upper path (above ring)
    // Phase of upper path: φ₁ = reference
    final pathPaint1 = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final pathPaint2 = Paint()
      ..color = const Color(0xFFFF6B35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Upper semi-arc
    final upperArc = Path();
    upperArc.addArc(
      Rect.fromCenter(center: Offset(ringCx, ringCy), width: ringR * 2, height: ringR * 2),
      math.pi, math.pi, // top half: from left to right going up
    );
    canvas.drawPath(upperArc, pathPaint1);

    // Lower semi-arc (with phase shift Δφ)
    final lowerArc = Path();
    lowerArc.addArc(
      Rect.fromCenter(center: Offset(ringCx, ringCy), width: ringR * 2, height: ringR * 2),
      0, math.pi, // bottom half: from right to left going down
    );
    canvas.drawPath(lowerArc, pathPaint2);

    // Solenoid in center (B field confined inside)
    canvas.drawCircle(Offset(ringCx, ringCy), solenoidR,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.15)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(ringCx, ringCy), solenoidR,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 2);
    // B field lines inside solenoid
    for (int i = 0; i < 4; i++) {
      final bx = ringCx - solenoidR * 0.6 + i * solenoidR * 0.4;
      canvas.drawLine(Offset(bx, ringCy - solenoidR * 0.6), Offset(bx, ringCy + solenoidR * 0.6),
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.5)..strokeWidth = 1);
    }
    _drawText(canvas, 'B', Offset(ringCx, ringCy - 5),
        fontSize: 9, color: const Color(0xFF00D4FF), bold: true, align: TextAlign.center);
    _drawText(canvas, 'Φ=${flux.toStringAsFixed(1)}Φ₀', Offset(ringCx, ringCy + solenoidR + 4),
        fontSize: 7, color: const Color(0xFF00D4FF), align: TextAlign.center);

    // Path labels
    _drawText(canvas, 'ψ₁ (위)', Offset(ringCx, ringCy - ringR - 12),
        fontSize: 8, color: const Color(0xFF00D4FF), align: TextAlign.center);
    _drawText(canvas, 'ψ₂ (아래)', Offset(ringCx, ringCy + ringR + 4),
        fontSize: 8, color: const Color(0xFFFF6B35), align: TextAlign.center);

    // Moving electron dot along paths (animation)
    final phase1 = time * 1.5;
    final phase2 = time * 1.5 + deltaPhase;
    final e1x = ringCx + ringR * math.cos(math.pi + phase1 % math.pi);
    final e1y = ringCy - ringR * math.sin(phase1 % math.pi).abs();
    canvas.drawCircle(Offset(e1x, e1y), 4,
        Paint()..color = const Color(0xFF00D4FF));
    final e2x = ringCx + ringR * math.cos(phase2 % math.pi);
    final e2y = ringCy + ringR * math.sin(phase2 % math.pi).abs();
    canvas.drawCircle(Offset(e2x, e2y), 4,
        Paint()..color = const Color(0xFFFF6B35));

    // Phase phasor diagram (small, bottom-left of diagram area)
    final phasorCx = 24.0;
    final phasorCy = h - 30.0;
    final phasorR = 16.0;
    canvas.drawCircle(Offset(phasorCx, phasorCy), phasorR,
        Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(phasorCx, phasorCy), phasorR,
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 1);
    // ψ₁ phasor (reference: angle 0)
    canvas.drawLine(Offset(phasorCx, phasorCy),
        Offset(phasorCx + phasorR, phasorCy),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2);
    // ψ₂ phasor (angle = Δφ)
    canvas.drawLine(Offset(phasorCx, phasorCy),
        Offset(phasorCx + phasorR * math.cos(deltaPhase), phasorCy - phasorR * math.sin(deltaPhase)),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);
    _drawText(canvas, 'Δφ=${(deltaPhase / math.pi).toStringAsFixed(2)}π',
        Offset(phasorCx + phasorR + 4, phasorCy - 6), fontSize: 7, color: const Color(0xFF5A8A9A));

    // ===== Right: Interference Pattern =====
    _drawText(canvas, '검출 강도', Offset(intLeft + (w - intLeft) / 2, 6),
        fontSize: 9, color: const Color(0xFF00D4FF), align: TextAlign.center);

    final intW = w - intLeft - 6;
    const nBars = 40;
    final barW = intW / nBars;

    // Shift pattern based on flux
    for (int i = 0; i < nBars; i++) {
      final y = -1.0 + 2.0 * i / (nBars - 1);
      final envelope = math.exp(-y * y / 0.3);
      // Phase shift from flux shifts fringe pattern
      final fringes = math.cos(6 * math.pi * y + deltaPhase);
      final intensity = (envelope * (1 + fringes) / 2).clamp(0.0, 1.0);
      final bh = intensity * h * 0.85;
      final bx = intLeft + i * barW;
      final col = Color.lerp(const Color(0xFF1A3040), const Color(0xFF00D4FF), intensity)!;
      canvas.drawRect(
        Rect.fromLTWH(bx, h / 2 - bh / 2, barW - 0.5, bh),
        Paint()..color = col.withValues(alpha: 0.85),
      );
    }

    // Interference amplitude readout
    _drawText(canvas, '강도: ${(interferenceAmp * 100).toStringAsFixed(0)}%',
        Offset(intLeft + intW / 2, h - 14),
        fontSize: 9, color: interferenceAmp > 0.5 ? const Color(0xFF64FF8C) : const Color(0xFFFF6B35),
        bold: true, align: TextAlign.center);
    _drawText(canvas, 'B=0이어도 위상차 발생',
        Offset(diagRight / 2, h - 14),
        fontSize: 8, color: const Color(0xFF5A8A9A), align: TextAlign.center);
  }

  @override
  bool shouldRepaint(covariant _AharonovBohmScreenPainter oldDelegate) => true;
}
