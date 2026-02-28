import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class QuantumErrorCorrectionScreen extends StatefulWidget {
  const QuantumErrorCorrectionScreen({super.key});
  @override
  State<QuantumErrorCorrectionScreen> createState() => _QuantumErrorCorrectionScreenState();
}

class _QuantumErrorCorrectionScreenState extends State<QuantumErrorCorrectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _errorProb = 0.1;
  double _successRate = 1;

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
      final p = _errorProb;
      _successRate = (1 - p) * (1 - p) * (1 - p) + 3 * p * (1 - p) * (1 - p);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _errorProb = 0.1;
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
          const Text('양자 오류 정정', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '양자 오류 정정',
          formula: '|0⟩_L = |000⟩,  |1⟩_L = |111⟩',
          formulaDescription: '3-큐비트 비트 플립 코드로 양자 오류를 정정합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _QuantumErrorCorrectionScreenPainter(
                time: _time,
                errorProb: _errorProb,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '오류 확률',
                value: _errorProb,
                min: 0.0,
                max: 0.5,
                step: 0.01,
                defaultValue: 0.1,
                formatValue: (v) => '${(v * 100).toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _errorProb = v),
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
          _V('성공률', '${(_successRate * 100).toStringAsFixed(1)}%'),
          _V('오류율', '${(_errorProb * 100).toStringAsFixed(0)}%'),
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

class _QuantumErrorCorrectionScreenPainter extends CustomPainter {
  final double time;
  final double errorProb;

  _QuantumErrorCorrectionScreenPainter({
    required this.time,
    required this.errorProb,
  });

  void _lbl(Canvas canvas, String text, Offset center, Color color, double sz) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: sz, fontFamily: 'monospace')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _gate(Canvas canvas, String label, Offset center, Color color) {
    final rect = Rect.fromCenter(center: center, width: 24, height: 20);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = const Color(0xFF1A3040));
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = color..strokeWidth = 1.2..style = PaintingStyle.stroke);
    _lbl(canvas, label, center, color, 9);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    _lbl(canvas, '3-큐비트 비트 플립 오류 정정 코드', Offset(w / 2, 13), const Color(0xFF00D4FF), 11);

    // Determine error qubit based on animated time & errorProb
    final errorQubit = errorProb > 0.01 ? ((time * 0.5).toInt() % 3) : -1;

    // ======= CIRCUIT LAYOUT =======
    // Top 60%: circuit diagram
    final circuitTop = 26.0;
    final circuitBot = h * 0.62;
    final cH = circuitBot - circuitTop;

    // 3 physical qubit lines + 2 ancilla lines
    final qY = [
      circuitTop + cH * 0.12,
      circuitTop + cH * 0.30,
      circuitTop + cH * 0.48,
      circuitTop + cH * 0.68,
      circuitTop + cH * 0.86,
    ];
    final qColors = [
      const Color(0xFF00D4FF),
      const Color(0xFF64FF8C),
      const Color(0xFFFF6B35),
      const Color(0xFF5A8A9A),
      const Color(0xFF5A8A9A),
    ];
    final qLabels = ['|ψ⟩ Q0', '|0⟩ Q1', '|0⟩ Q2', 'anc₁', 'anc₂'];

    final xStart = 50.0, xEnd = w - 8.0;

    // Draw qubit lines
    for (int i = 0; i < 5; i++) {
      final lp = Paint()..color = qColors[i].withValues(alpha: 0.35)..strokeWidth = 1..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(xStart, qY[i]), Offset(xEnd, qY[i]), lp);
      _lbl(canvas, qLabels[i], Offset(xStart - 26, qY[i]), qColors[i], 8);
    }

    // ---- ENCODING block ----
    final encX = xStart + 12;
    final encBlockR = Rect.fromLTRB(encX - 10, qY[0] - 14, encX + 36, qY[2] + 14);
    canvas.drawRRect(RRect.fromRectAndRadius(encBlockR, const Radius.circular(5)),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.08));
    canvas.drawRRect(RRect.fromRectAndRadius(encBlockR, const Radius.circular(5)),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.3)..strokeWidth = 1..style = PaintingStyle.stroke);
    _lbl(canvas, 'ENCODE', Offset(encX + 13, qY[0] - 8), const Color(0xFF00D4FF), 7);

    // Encoding CNOT gates
    final encCnot1X = encX + 8.0;
    final encCnot2X = encX + 26.0;
    // CNOT Q0->Q1
    canvas.drawCircle(Offset(encCnot1X, qY[0]), 4, Paint()..color = const Color(0xFF00D4FF));
    canvas.drawLine(Offset(encCnot1X, qY[0]), Offset(encCnot1X, qY[1]),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1);
    canvas.drawCircle(Offset(encCnot1X, qY[1]), 8, Paint()..color = const Color(0xFF0D1A20));
    canvas.drawCircle(Offset(encCnot1X, qY[1]), 8, Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(encCnot1X - 8, qY[1]), Offset(encCnot1X + 8, qY[1]),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1);
    // CNOT Q0->Q2
    canvas.drawCircle(Offset(encCnot2X, qY[0]), 4, Paint()..color = const Color(0xFF00D4FF));
    canvas.drawLine(Offset(encCnot2X, qY[0]), Offset(encCnot2X, qY[2]),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1);
    canvas.drawCircle(Offset(encCnot2X, qY[2]), 8, Paint()..color = const Color(0xFF0D1A20));
    canvas.drawCircle(Offset(encCnot2X, qY[2]), 8, Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(encCnot2X - 8, qY[2]), Offset(encCnot2X + 8, qY[2]),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1);

    // ---- ERROR injection ----
    final errX = xStart + (xEnd - xStart) * 0.30;
    if (errorQubit >= 0 && errorQubit < 3) {
      final errColor = const Color(0xFFFF3333);
      _gate(canvas, 'X', Offset(errX, qY[errorQubit]), errColor);
      _lbl(canvas, '오류!', Offset(errX, qY[errorQubit] - 14), errColor, 8);
      // Animated flash
      final flashAlpha = (math.sin(time * 8) * 0.5 + 0.5) * 0.6;
      canvas.drawCircle(Offset(errX, qY[errorQubit]), 14,
          Paint()..color = errColor.withValues(alpha: flashAlpha));
    }

    // ---- SYNDROME MEASUREMENT ----
    final synX = xStart + (xEnd - xStart) * 0.50;
    final synBlockR = Rect.fromLTRB(synX - 12, qY[0] - 14, synX + 40, qY[4] + 14);
    canvas.drawRRect(RRect.fromRectAndRadius(synBlockR, const Radius.circular(5)),
        Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.06));
    canvas.drawRRect(RRect.fromRectAndRadius(synBlockR, const Radius.circular(5)),
        Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.3)..strokeWidth = 1..style = PaintingStyle.stroke);
    _lbl(canvas, 'SYNDROME', Offset(synX + 14, qY[0] - 8), const Color(0xFF64FF8C), 7);
    // Ancilla CNOT syndrome gates
    final s1X = synX + 6.0, s2X = synX + 26.0;
    for (final sx in [s1X, s2X]) {
      final qi = sx == s1X ? 0 : 1;
      final ai = sx == s1X ? 3 : 4;
      canvas.drawCircle(Offset(sx, qY[qi]), 4, Paint()..color = const Color(0xFF64FF8C));
      canvas.drawLine(Offset(sx, qY[qi]), Offset(sx, qY[qi + 1]),
          Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1);
      canvas.drawCircle(Offset(sx, qY[qi + 1]), 8, Paint()..color = const Color(0xFF0D1A20));
      canvas.drawCircle(Offset(sx, qY[qi + 1]), 8,
          Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1..style = PaintingStyle.stroke);
      canvas.drawLine(Offset(sx - 8, qY[qi + 1]), Offset(sx + 8, qY[qi + 1]),
          Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1);
      // Ancilla measure
      final mRect = Rect.fromCenter(center: Offset(sx + 10, qY[ai]), width: 18, height: 14);
      canvas.drawRRect(RRect.fromRectAndRadius(mRect, const Radius.circular(3)),
          Paint()..color = const Color(0xFF1A3040));
      canvas.drawRRect(RRect.fromRectAndRadius(mRect, const Radius.circular(3)),
          Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 0.8..style = PaintingStyle.stroke);
      _lbl(canvas, 'M', Offset(sx + 10, qY[ai]), const Color(0xFF5A8A9A), 8);
    }

    // Syndrome result
    final s0 = errorQubit == 1 || errorQubit == 2 ? 1 : 0;
    final s1 = errorQubit == 0 || errorQubit == 2 ? 1 : 0;
    _lbl(canvas, 'S₀=$s0', Offset(synX + 40, qY[3]), const Color(0xFF5A8A9A), 9);
    _lbl(canvas, 'S₁=$s1', Offset(synX + 40, qY[4]), const Color(0xFF5A8A9A), 9);

    // ---- CORRECTION ----
    final corrX = xStart + (xEnd - xStart) * 0.76;
    final corrBlockR = Rect.fromLTRB(corrX - 14, qY[0] - 14, corrX + 28, qY[2] + 14);
    canvas.drawRRect(RRect.fromRectAndRadius(corrBlockR, const Radius.circular(5)),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.06));
    canvas.drawRRect(RRect.fromRectAndRadius(corrBlockR, const Radius.circular(5)),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.3)..strokeWidth = 1..style = PaintingStyle.stroke);
    _lbl(canvas, 'CORRECT', Offset(corrX + 7, qY[0] - 8), const Color(0xFFFF6B35), 7);
    for (int qi = 0; qi < 3; qi++) {
      final needCorr = errorQubit == qi;
      final gColor = needCorr ? const Color(0xFF00D4FF) : const Color(0xFF2A4050);
      final gRect = Rect.fromCenter(center: Offset(corrX + 7, qY[qi]), width: 20, height: 16);
      canvas.drawRRect(RRect.fromRectAndRadius(gRect, const Radius.circular(3)),
          Paint()..color = const Color(0xFF0D1A20));
      canvas.drawRRect(RRect.fromRectAndRadius(gRect, const Radius.circular(3)),
          Paint()..color = gColor..strokeWidth = 1..style = PaintingStyle.stroke);
      _lbl(canvas, needCorr ? 'X' : 'I', Offset(corrX + 7, qY[qi]), gColor, 9);
    }

    // ===== BOTTOM: Success rate bar =====
    final barTop = h * 0.66;
    final barH = h * 0.14;
    final barW = w * 0.72;
    final barX = (w - barW) / 2;

    final successRate = (1 - errorProb) * (1 - errorProb) * (1 - errorProb)
        + 3 * errorProb * (1 - errorProb) * (1 - errorProb);
    _lbl(canvas, '오류 정정 성공률', Offset(w / 2, barTop - 8), const Color(0xFFE0F4FF), 9);
    // Background bar
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(barX, barTop, barW, barH), const Radius.circular(4)),
        Paint()..color = const Color(0xFF1A3040));
    // Success fill
    final fillW = barW * successRate;
    final successColor = successRate > 0.9
        ? const Color(0xFF64FF8C)
        : successRate > 0.7 ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(barX, barTop, fillW, barH), const Radius.circular(4)),
        Paint()..color = successColor.withValues(alpha: 0.8));
    _lbl(canvas, '${(successRate * 100).toStringAsFixed(1)}%', Offset(barX + barW / 2, barTop + barH / 2), const Color(0xFFE0F4FF), 10);

    // Threshold line at 50%
    final threshX = barX + barW * 0.5;
    canvas.drawLine(Offset(threshX, barTop - 2), Offset(threshX, barTop + barH + 2),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.2..style = PaintingStyle.stroke);
    _lbl(canvas, 'QEC임계', Offset(threshX, barTop + barH + 8), const Color(0xFFFF6B35), 7);

    // ===== ERROR RATE vs SUCCESS RATE INFO =====
    final infoY = h * 0.88;
    _lbl(canvas, '오류율 p=${(errorProb * 100).toStringAsFixed(0)}%', Offset(w * 0.3, infoY), const Color(0xFF5A8A9A), 9);
    _lbl(canvas, '물리큐비트 3개 → 논리큐비트 1개', Offset(w * 0.65, infoY), const Color(0xFF5A8A9A), 9);
  }

  @override
  bool shouldRepaint(covariant _QuantumErrorCorrectionScreenPainter oldDelegate) => true;
}
