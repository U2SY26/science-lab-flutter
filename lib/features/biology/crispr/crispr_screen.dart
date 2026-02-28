import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CrisprScreen extends StatefulWidget {
  const CrisprScreen({super.key});
  @override
  State<CrisprScreen> createState() => _CrisprScreenState();
}

class _CrisprScreenState extends State<CrisprScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _guideEfficiency = 80;
  double _hdrRate = 30;
  double _editSuccess = 0, _nhejRate = 0;

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
      _editSuccess = _guideEfficiency / 100;
      _nhejRate = _editSuccess * (100 - _hdrRate) / 100;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _guideEfficiency = 80; _hdrRate = 30;
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
          Text('생물학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('크리스퍼 유전자 편집', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '크리스퍼 유전자 편집',
          formula: 'Cas9 + sgRNA → DSB → HDR/NHEJ',
          formulaDescription: 'CRISPR-Cas9 유전자 편집 메커니즘을 애니메이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CrisprScreenPainter(
                time: _time,
                guideEfficiency: _guideEfficiency,
                hdrRate: _hdrRate,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '가이드 효율 (%)',
                value: _guideEfficiency,
                min: 10,
                max: 100,
                step: 5,
                defaultValue: 80,
                formatValue: (v) => '${v.toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _guideEfficiency = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'HDR 비율 (%)',
                value: _hdrRate,
                min: 5,
                max: 80,
                step: 5,
                defaultValue: 30,
                formatValue: (v) => '${v.toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _hdrRate = v),
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
          _V('편집 성공', '${(_editSuccess * 100).toStringAsFixed(0)}%'),
          _V('HDR', '${_hdrRate.toStringAsFixed(0)}%'),
          _V('NHEJ', '${(_nhejRate * 100).toStringAsFixed(0)}%'),
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

class _CrisprScreenPainter extends CustomPainter {
  final double time;
  final double guideEfficiency;
  final double hdrRate;

  _CrisprScreenPainter({
    required this.time,
    required this.guideEfficiency,
    required this.hdrRate,
  });

  void _label(Canvas canvas, String text, Offset pos, {double fs = 8, Color col = const Color(0xFF5A8A9A), bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? pos.dx - tp.width / 2 : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  // Draw a DNA double helix segment
  void _drawDNA(Canvas canvas, Offset start, double length, double y, double amplitude, double phase, bool cut, double cutPos) {
    final strand1 = Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2..style = PaintingStyle.stroke;
    final strand2 = Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 2..style = PaintingStyle.stroke;
    final backbonePaint = Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)..strokeWidth = 1;

    final path1 = Path();
    final path2 = Path();
    const steps = 60;
    for (int i = 0; i <= steps; i++) {
      final frac = i / steps.toDouble();
      final x = start.dx + frac * length;
      final angle = frac * math.pi * 4 + phase;
      final y1 = y - amplitude * math.sin(angle);
      final y2 = y + amplitude * math.sin(angle);
      if (i == 0) {
        path1.moveTo(x, y1);
        path2.moveTo(x, y2);
      } else {
        // If cut, stop drawing at cutPos
        if (cut && frac > cutPos - 0.05 && frac < cutPos + 0.05) {
          continue;
        }
        path1.lineTo(x, y1);
        path2.lineTo(x, y2);
      }
      // Bases (rungs)
      if (i % 6 == 0) {
        canvas.drawLine(Offset(x, y1), Offset(x, y2), backbonePaint);
      }
    }
    // Draw cut gap if needed
    if (cut) {
      final cutX = start.dx + cutPos * length;
      canvas.drawLine(Offset(cutX - 3, y - amplitude - 4), Offset(cutX + 3, y + amplitude + 4),
          Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2.5);
    }
    canvas.drawPath(path1, strand1);
    canvas.drawPath(path2, strand2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Animation phase: 0→1 = approach, 1→2 = bind, 2→3 = cut, 3→4 = repair
    final phase = (time * 0.4) % 4.0;
    final approach = phase < 1.0 ? phase : 1.0;
    final bound = phase >= 1.0 && phase < 2.0 ? (phase - 1.0) : (phase >= 2.0 ? 1.0 : 0.0);
    final cut = phase >= 2.5;
    final repairPhase = phase >= 3.0 ? (phase - 3.0).clamp(0.0, 1.0) : 0.0;

    // --- DNA double helix (horizontal, middle) ---
    final dnaY = h * 0.38;
    final dnaLeft = 16.0;
    final dnaLen = w - 32;
    final dnaAmplitude = 10.0;
    final cutPosNorm = 0.45; // cut at 45% along DNA
    _drawDNA(canvas, Offset(dnaLeft, dnaY), dnaLen, dnaY, dnaAmplitude, time * 0.3, cut, cutPosNorm);

    // PAM sequence label
    final pamX = dnaLeft + cutPosNorm * dnaLen + 14;
    _label(canvas, "5'-NGG-3'\n(PAM)", Offset(pamX, dnaY + dnaAmplitude + 4), fs: 7, col: const Color(0xFFFF6B35));

    // Target sequence highlight
    final targetStart = dnaLeft + (cutPosNorm - 0.18) * dnaLen;
    final targetEnd = dnaLeft + cutPosNorm * dnaLen;
    canvas.drawRect(
      Rect.fromLTWH(targetStart, dnaY - dnaAmplitude - 4, targetEnd - targetStart, dnaAmplitude * 2 + 8),
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.15),
    );

    // --- sgRNA (red line approaching from top) ---
    final sgRnaTargetY = dnaY - dnaAmplitude - 2;
    final sgRnaStartY = h * 0.08;
    final sgRnaCurY = sgRnaStartY + approach * (sgRnaTargetY - sgRnaStartY);
    final sgRnaCx = dnaLeft + (cutPosNorm - 0.1) * dnaLen;
    // sgRNA as wavy line
    final sgPath = Path();
    for (int i = 0; i <= 20; i++) {
      final t = i / 20.0;
      final x = sgRnaCx - 30 + t * 60;
      final y = sgRnaCurY - 5 + math.sin(t * math.pi * 3 + time) * 3;
      if (i == 0) {
        sgPath.moveTo(x, y);
      } else {
        sgPath.lineTo(x, y);
      }
    }
    canvas.drawPath(sgPath, Paint()..color = const Color(0xFFFF4444)..strokeWidth = 2..style = PaintingStyle.stroke);
    _label(canvas, 'sgRNA', Offset(sgRnaCx + 32, sgRnaCurY - 6), fs: 8, col: const Color(0xFFFF4444));

    // --- Cas9 protein (cyan oval, approaches from top-left) ---
    final cas9TargetX = dnaLeft + (cutPosNorm - 0.12) * dnaLen - 20;
    final cas9TargetY = dnaY - 28.0;
    final cas9StartX = w * 0.1;
    final cas9StartY = h * 0.06;
    final cas9X = cas9StartX + approach * (cas9TargetX - cas9StartX);
    final cas9Y = cas9StartY + approach * (cas9TargetY - cas9StartY);
    final cas9Rect = Rect.fromCenter(center: Offset(cas9X, cas9Y), width: 52, height: 28);
    canvas.drawOval(cas9Rect, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.3 + bound * 0.2));
    canvas.drawOval(cas9Rect,
        Paint()..color = const Color(0xFF00D4FF)..style = PaintingStyle.stroke..strokeWidth = 2);
    _label(canvas, 'Cas9', Offset(cas9X - 12, cas9Y - 5), fs: 8, col: const Color(0xFF00D4FF));

    // Bound indicator
    if (bound > 0.3) {
      canvas.drawLine(Offset(cas9X, cas9Y + 14), Offset(sgRnaCx, sgRnaCurY),
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: bound * 0.5)..strokeWidth = 1.5);
    }

    // --- Cut effect ---
    if (cut) {
      final cutX = dnaLeft + cutPosNorm * dnaLen;
      // Scissors icon (two crossing lines)
      canvas.drawLine(Offset(cutX - 10, dnaY - 16), Offset(cutX + 10, dnaY + 16),
          Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2.5);
      canvas.drawLine(Offset(cutX + 10, dnaY - 16), Offset(cutX - 10, dnaY + 16),
          Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2.5);
      _label(canvas, 'DSB', Offset(cutX + 12, dnaY - 8), fs: 8, col: const Color(0xFFFF6B35));
    }

    // --- Repair pathway split (bottom) ---
    final splitY = h * 0.62;
    final hdrX = w * 0.28;
    final nhejX = w * 0.72;
    final midX = w / 2;

    if (cut) {
      // Lines from cut to HDR/NHEJ boxes
      canvas.drawLine(Offset(midX, dnaY + dnaAmplitude + 8), Offset(hdrX, splitY - 4),
          Paint()..color = const Color(0xFF64FF8C).withValues(alpha: repairPhase)..strokeWidth = 1.5);
      canvas.drawLine(Offset(midX, dnaY + dnaAmplitude + 8), Offset(nhejX, splitY - 4),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: repairPhase)..strokeWidth = 1.5);

      // HDR box
      final hdrBoxAlpha = (repairPhase * hdrRate / 100).clamp(0.0, 1.0);
      final hdrRect = Rect.fromCenter(center: Offset(hdrX, splitY + 18), width: 90, height: 32);
      canvas.drawRRect(RRect.fromRectAndRadius(hdrRect, const Radius.circular(6)),
          Paint()..color = const Color(0xFF64FF8C).withValues(alpha: hdrBoxAlpha * 0.25));
      canvas.drawRRect(RRect.fromRectAndRadius(hdrRect, const Radius.circular(6)),
          Paint()..color = const Color(0xFF64FF8C).withValues(alpha: hdrBoxAlpha * 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      _label(canvas, 'HDR', Offset(hdrX, splitY + 8), fs: 9, col: const Color(0xFF64FF8C), center: true);
      _label(canvas, '정밀 교정', Offset(hdrX, splitY + 20), fs: 7, col: const Color(0xFF64FF8C), center: true);
      _label(canvas, '${hdrRate.toStringAsFixed(0)}%', Offset(hdrX, splitY + 30), fs: 8, col: const Color(0xFF64FF8C), center: true);

      // NHEJ box
      final nhejBoxAlpha = (repairPhase * (100 - hdrRate) / 100).clamp(0.0, 1.0);
      final nhejRect = Rect.fromCenter(center: Offset(nhejX, splitY + 18), width: 90, height: 32);
      canvas.drawRRect(RRect.fromRectAndRadius(nhejRect, const Radius.circular(6)),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: nhejBoxAlpha * 0.25));
      canvas.drawRRect(RRect.fromRectAndRadius(nhejRect, const Radius.circular(6)),
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: nhejBoxAlpha * 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      _label(canvas, 'NHEJ', Offset(nhejX, splitY + 8), fs: 9, col: const Color(0xFFFF6B35), center: true);
      _label(canvas, '비정밀 수선', Offset(nhejX, splitY + 20), fs: 7, col: const Color(0xFFFF6B35), center: true);
      _label(canvas, '${(100 - hdrRate).toStringAsFixed(0)}%', Offset(nhejX, splitY + 30), fs: 8, col: const Color(0xFFFF6B35), center: true);
    }

    // --- Efficiency bar at bottom ---
    final barY = h * 0.9;
    final barLeft = 40.0;
    final barW = w - 56;
    canvas.drawRect(Rect.fromLTWH(barLeft, barY, barW, 10),
        Paint()..color = const Color(0xFF1A3040));
    canvas.drawRect(Rect.fromLTWH(barLeft, barY, barW * guideEfficiency / 100, 10),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7));
    canvas.drawRect(Rect.fromLTWH(barLeft, barY, barW, 10),
        Paint()..color = const Color(0xFF5A8A9A)..style = PaintingStyle.stroke..strokeWidth = 1);
    _label(canvas, '편집 효율 ${guideEfficiency.toStringAsFixed(0)}%', Offset(barLeft, barY - 12), fs: 8, col: const Color(0xFF00D4FF));
    _label(canvas, '유전병 치료 · 농작물 개량 · 기초연구', Offset(barLeft, barY + 13), fs: 7, col: const Color(0xFF5A8A9A));
  }

  @override
  bool shouldRepaint(covariant _CrisprScreenPainter oldDelegate) => true;
}
