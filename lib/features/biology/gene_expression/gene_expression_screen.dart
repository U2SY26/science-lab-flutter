import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class GeneExpressionScreen extends StatefulWidget {
  const GeneExpressionScreen({super.key});
  @override
  State<GeneExpressionScreen> createState() => _GeneExpressionScreenState();
}

class _GeneExpressionScreenState extends State<GeneExpressionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _speed = 1.0;
  int _stage = 0;

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
      _stage = (_time * _speed * 0.3).toInt() % 3;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _speed = 1.0;
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
          Text('생물 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('유전자 발현', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물 시뮬레이션',
          title: '유전자 발현',
          formula: 'DNA → mRNA → Protein',
          formulaDescription: 'DNA에서 단백질로의 전사와 번역 과정을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _GeneExpressionScreenPainter(
                time: _time,
                speed: _speed,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '속도',
                value: _speed,
                min: 0.1,
                max: 3.0,
                step: 0.1,
                defaultValue: 1.0,
                formatValue: (v) => '${v.toStringAsFixed(1)}x',
                onChanged: (v) => setState(() => _speed = v),
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
          _V('단계', '${["전사","번역","접힘"][_stage]}'),
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

class _GeneExpressionScreenPainter extends CustomPainter {
  final double time;
  final double speed;

  _GeneExpressionScreenPainter({
    required this.time,
    required this.speed,
  });

  void _drawLabel(Canvas canvas, String text, Offset center, {double fontSize = 10, Color? color, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color ?? const Color(0xFF5A8A9A), fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    const cyanColor = Color(0xFF00D4FF);
    const orangeColor = Color(0xFFFF6B35);
    const greenColor = Color(0xFF64FF8C);
    const mutedColor = Color(0xFF5A8A9A);
    const inkColor = Color(0xFFE0F4FF);
    const gridColor = Color(0xFF1A3040);

    final w = size.width;
    final h = size.height;

    // Animated progress: 0..1 cycles with time*speed
    final cycleLen = 8.0 / speed;
    final phase = (time % cycleLen) / cycleLen; // 0..1
    // 0..0.45 = transcription, 0.45..1.0 = translation
    final isTranscription = phase < 0.45;
    final subPhase = isTranscription ? phase / 0.45 : (phase - 0.45) / 0.55;

    // Title
    final titleTp = TextPainter(
      text: const TextSpan(text: 'DNA → mRNA → 단백질 (전사 & 번역)', style: TextStyle(color: cyanColor, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, Offset((w - titleTp.width) / 2, 5));

    // ── Section 1: DNA double helix (top third) ──────────────────────────
    final dnaY = h * 0.22;
    final dnaLeft = w * 0.06;
    final dnaRight = w * 0.94;
    final dnaLen = dnaRight - dnaLeft;
    final amplitude = 12.0;
    final freq = 2 * math.pi / (dnaLen / 4.5);

    final strandPaint1 = Paint()..color = cyanColor..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final strandPaint2 = Paint()..color = orangeColor..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final rungPaint = Paint()..color = gridColor..strokeWidth = 1.0;

    // Draw strands with rungs
    final path1 = Path();
    final path2 = Path();
    for (double x = dnaLeft; x <= dnaRight; x += 1.5) {
      final t = (x - dnaLeft) * freq;
      final y1 = dnaY + amplitude * math.sin(t);
      final y2 = dnaY - amplitude * math.sin(t);
      if (x == dnaLeft) {
        path1.moveTo(x, y1);
        path2.moveTo(x, y2);
      } else {
        path1.lineTo(x, y1);
        path2.lineTo(x, y2);
      }
    }
    canvas.drawPath(path1, strandPaint1);
    canvas.drawPath(path2, strandPaint2);

    // Rungs (base pairs)
    for (int i = 0; i < 10; i++) {
      final x = dnaLeft + dnaLen * i / 9;
      final t = (x - dnaLeft) * freq;
      final y1 = dnaY + amplitude * math.sin(t);
      final y2 = dnaY - amplitude * math.sin(t);
      canvas.drawLine(Offset(x, y1), Offset(x, y2), rungPaint);
    }

    // DNA label
    _drawLabel(canvas, 'DNA', Offset(dnaLeft - 16, dnaY), fontSize: 10, color: mutedColor);

    // ── RNA Polymerase moving along DNA ─────────────────────────────────
    final polX = dnaLeft + dnaLen * (isTranscription ? subPhase : 1.0);
    if (isTranscription) {
      // Polymerase bubble
      canvas.drawOval(
        Rect.fromCenter(center: Offset(polX, dnaY), width: 22, height: 26),
        Paint()..color = greenColor.withValues(alpha: 0.25),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(polX, dnaY), width: 22, height: 26),
        Paint()..color = greenColor..style = PaintingStyle.stroke..strokeWidth = 1.5,
      );
      _drawLabel(canvas, 'RNA\nPol', Offset(polX, dnaY), fontSize: 7, color: greenColor);
    }

    // ── Section 2: mRNA strand ────────────────────────────────────────────
    final mrnaY = h * 0.48;
    final mrnaProgress = isTranscription ? subPhase : 1.0;
    final mrnaEnd = dnaLeft + dnaLen * mrnaProgress;

    // Label
    _drawLabel(canvas, 'mRNA', Offset(dnaLeft - 18, mrnaY), fontSize: 10, color: orangeColor);

    // mRNA backbone
    if (mrnaEnd > dnaLeft + 2) {
      canvas.drawLine(
        Offset(dnaLeft, mrnaY),
        Offset(mrnaEnd, mrnaY),
        Paint()..color = orangeColor..strokeWidth = 3.0,
      );
      // Codons (every ~28px = 3 nucleotides)
      final codonW = dnaLen / 12.0;
      int visibleCodons = ((mrnaEnd - dnaLeft) / codonW).floor();
      const codonLabels = ['AUG', 'UCA', 'GCU', 'UAG', 'CAU', 'GGA', 'UUC', 'ACG', 'GAA', 'UCU', 'CGG', 'UGA'];
      for (int i = 0; i < visibleCodons && i < 12; i++) {
        final cx2 = dnaLeft + codonW * i + codonW / 2;
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx2, mrnaY), width: codonW - 3, height: 8),
          Paint()..color = (i % 2 == 0 ? orangeColor : const Color(0xFFCC5522)).withValues(alpha: 0.35),
        );
        _drawLabel(canvas, codonLabels[i], Offset(cx2, mrnaY), fontSize: 6.5, color: inkColor);
      }
    }

    // Transcription label arrow
    if (isTranscription && mrnaEnd > dnaLeft + 10) {
      canvas.drawLine(Offset(w / 2, dnaY + amplitude + 4), Offset(w / 2, mrnaY - 8),
          Paint()..color = greenColor.withValues(alpha: 0.6)..strokeWidth = 1.0);
      _drawLabel(canvas, '전사', Offset(w / 2 + 18, (dnaY + amplitude + mrnaY) / 2), fontSize: 9, color: greenColor);
    }

    // ── Section 3: Ribosome + polypeptide chain ──────────────────────────
    final riboY = h * 0.74;
    final codonW2 = dnaLen / 12.0;
    final riboProgress = isTranscription ? 0.0 : subPhase;
    final riboX = dnaLeft + dnaLen * riboProgress;

    // Ribosome
    if (!isTranscription || subPhase > 0.9) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(riboX, riboY), width: 36, height: 24),
        Paint()..color = const Color(0xFF5A3080).withValues(alpha: 0.4),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(riboX, riboY), width: 36, height: 24),
        Paint()..color = const Color(0xFFAA66FF)..style = PaintingStyle.stroke..strokeWidth = 1.5,
      );
      _drawLabel(canvas, '리보솜', Offset(riboX, riboY), fontSize: 8, color: const Color(0xFFAA66FF));

      // tRNA below ribosome
      final tRnaY = riboY + 22;
      canvas.drawLine(Offset(riboX, riboY + 12), Offset(riboX, tRnaY + 10),
          Paint()..color = greenColor.withValues(alpha: 0.7)..strokeWidth = 1.5);
      canvas.drawCircle(Offset(riboX, tRnaY + 14), 8, Paint()..color = greenColor.withValues(alpha: 0.25));
      canvas.drawCircle(Offset(riboX, tRnaY + 14), 8, Paint()..color = greenColor..style = PaintingStyle.stroke..strokeWidth = 1.0);
      _drawLabel(canvas, 'tRNA', Offset(riboX, tRnaY + 14), fontSize: 7, color: greenColor);

      // Polypeptide beads (left of ribosome)
      final numAA = ((riboProgress * dnaLen) / codonW2).floor();
      final aaColors = [cyanColor, greenColor, orangeColor, const Color(0xFFAA66FF), const Color(0xFFFFCC00)];
      for (int i = 0; i < numAA && i < 10; i++) {
        final bx = riboX - 20 - i * 14.0;
        if (bx < dnaLeft) break;
        canvas.drawCircle(Offset(bx, riboY - 18), 6, Paint()..color = aaColors[i % aaColors.length].withValues(alpha: 0.6));
        canvas.drawCircle(Offset(bx, riboY - 18), 6, Paint()..color = aaColors[i % aaColors.length]..style = PaintingStyle.stroke..strokeWidth = 1.0);
        if (i > 0) {
          canvas.drawLine(Offset(bx + 6, riboY - 18), Offset(bx + 14, riboY - 18),
              Paint()..color = mutedColor..strokeWidth = 1.5);
        }
      }
      if (numAA > 0) {
        _drawLabel(canvas, '폴리펩타이드', Offset(riboX - 20 - math.min(numAA - 1, 9) * 7.0, riboY - 32), fontSize: 8, color: mutedColor);
      }
    }

    // mRNA label row at ribosome level
    _drawLabel(canvas, 'mRNA', Offset(dnaLeft - 18, riboY + 1), fontSize: 10, color: orangeColor);
    canvas.drawLine(Offset(dnaLeft, riboY), Offset(dnaLeft + dnaLen, riboY),
        Paint()..color = orangeColor.withValues(alpha: 0.3)..strokeWidth = 2.0);

    // Translation label
    if (!isTranscription) {
      _drawLabel(canvas, '번역', Offset(riboX + 30, riboY - 10), fontSize: 9, color: const Color(0xFFAA66FF));
    }

    // Stage indicator bottom
    final stageText = isTranscription ? '전사 진행 중... ${(subPhase * 100).toInt()}%' : '번역 진행 중... ${(subPhase * 100).toInt()}%';
    _drawLabel(canvas, stageText, Offset(w / 2, h - 10), fontSize: 10, color: isTranscription ? greenColor : const Color(0xFFAA66FF));
  }

  @override
  bool shouldRepaint(covariant _GeneExpressionScreenPainter oldDelegate) => true;
}
