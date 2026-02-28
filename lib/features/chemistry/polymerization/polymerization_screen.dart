import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class PolymerizationScreen extends StatefulWidget {
  const PolymerizationScreen({super.key});
  @override
  State<PolymerizationScreen> createState() => _PolymerizationScreenState();
}

class _PolymerizationScreenState extends State<PolymerizationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _degree = 100;
  
  double _molWeight = 0, _conversion = 0;

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
      _molWeight = _degree * 104;
      _conversion = 1 - 1 / _degree;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _degree = 100.0;
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
          const Text('중합 반응', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '중합 반응',
          formula: 'n(monomer) → polymer',
          formulaDescription: '축합 중합과 첨가 중합 과정을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PolymerizationScreenPainter(
                time: _time,
                degree: _degree,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '중합도 (n)',
                value: _degree,
                min: 10,
                max: 10000,
                step: 10,
                defaultValue: 100,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _degree = v),
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
          _V('Mw', '${(_molWeight / 1000).toStringAsFixed(1)} kDa'),
          _V('전환율', '${(_conversion * 100).toStringAsFixed(1)}%'),
          _V('n', _degree.toInt().toString()),
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

class _PolymerizationScreenPainter extends CustomPainter {
  final double time;
  final double degree;

  _PolymerizationScreenPainter({
    required this.time,
    required this.degree,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;
    // Chain area: left 65%, histogram: right 35%
    final chainW = w * 0.65;
    final histX = chainW + 8;
    final histW = w - histX - 8;

    // How many monomers to show based on degree (log scale, capped at display)
    final int displayN = (math.log(degree) / math.log(10000) * 18).clamp(2, 18).toInt();
    // Animate: some monomers "linking" with oscillating bond highlight
    final int animBond = (time * 2).toInt() % (displayN > 1 ? displayN - 1 : 1);

    // -- Draw polymer chain --
    final double monR = 10.0;
    final double spacing = (chainW - 20) / (displayN > 1 ? displayN : 1);
    final double chainY = h * 0.38;

    // Grid lines faint
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.4;
    for (double gx = 0; gx < chainW; gx += 24) {
      canvas.drawLine(Offset(gx, 0), Offset(gx, h), gridP);
    }
    for (double gy = 0; gy < h; gy += 24) {
      canvas.drawLine(Offset(0, gy), Offset(chainW, gy), gridP);
    }

    // Monomers and bonds
    final positions = <Offset>[];
    for (int i = 0; i < displayN; i++) {
      final x = 14 + i * spacing;
      // Slight zigzag
      final y = chainY + (i % 2 == 0 ? -10.0 : 10.0);
      positions.add(Offset(x, y));
    }

    // Draw bonds first
    for (int i = 0; i < displayN - 1; i++) {
      final isAnimated = (i == animBond);
      final bondColor = isAnimated
          ? const Color(0xFF00D4FF)
          : const Color(0xFF64FF8C);
      final bp = Paint()
        ..color = bondColor
        ..strokeWidth = isAnimated ? 2.5 : 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(positions[i], positions[i + 1], bp);
      // "Double bond" opening on animated bond (isoelectronic)
      if (isAnimated) {
        final dx = positions[i + 1].dx - positions[i].dx;
        final dy = positions[i + 1].dy - positions[i].dy;
        final len = math.sqrt(dx * dx + dy * dy);
        if (len > 0) {
          final nx = -dy / len * 3, ny = dx / len * 3;
          canvas.drawLine(
            Offset(positions[i].dx + nx, positions[i].dy + ny),
            Offset(positions[i + 1].dx + nx, positions[i + 1].dy + ny),
            Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.5)..strokeWidth = 1.0,
          );
        }
      }
    }

    // Draw monomer units
    for (int i = 0; i < displayN; i++) {
      final p = positions[i];
      final isEnd = (i == 0 || i == displayN - 1);
      final fillColor = isEnd
          ? const Color(0xFFFF6B35).withValues(alpha: 0.25)
          : const Color(0xFF64FF8C).withValues(alpha: 0.15);
      final strokeColor = isEnd ? const Color(0xFFFF6B35) : const Color(0xFF64FF8C);
      canvas.drawCircle(p, monR, Paint()..color = fillColor..style = PaintingStyle.fill);
      canvas.drawCircle(p, monR, Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.2);
      final tp = TextPainter(
        text: TextSpan(text: 'CH₂', style: TextStyle(color: strokeColor, fontSize: 6)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
    }

    // Label
    void drawLabel(String text, double x, double y, Color color, {double fontSize = 9}) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y));
    }

    drawLabel('폴리에틸렌 체인 (n = ${degree.toInt()})', chainW / 2, chainY + 28, const Color(0xFF00D4FF), fontSize: 10);
    drawLabel('CH₂=CH₂  →  -(CH₂-CH₂)ₙ-', chainW / 2, chainY + 42, const Color(0xFF5A8A9A), fontSize: 8);

    // Conversion progress bar
    final conv = 1.0 - 1.0 / degree;
    final barY = h * 0.72;
    final barW = chainW - 28;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(14, barY, barW, 10), const Radius.circular(5)),
      Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(14, barY, barW * conv, 10), const Radius.circular(5)),
      Paint()..color = const Color(0xFF64FF8C)..style = PaintingStyle.fill,
    );
    drawLabel('전환율: ${(conv * 100).toStringAsFixed(1)}%', chainW / 2, barY + 14, const Color(0xFF64FF8C), fontSize: 9);
    drawLabel('Mw: ${(degree * 104 / 1000).toStringAsFixed(1)} kDa', chainW / 2, barY + 26, const Color(0xFF5A8A9A), fontSize: 9);

    // -- Histogram (MW distribution) --
    canvas.drawLine(Offset(histX, h * 0.85), Offset(histX + histW, h * 0.85),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0);
    canvas.drawLine(Offset(histX, h * 0.1), Offset(histX, h * 0.85),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0);

    // Gaussian-like distribution bars
    final int bars = 8;
    final peakI = bars ~/ 2;
    for (int b = 0; b < bars; b++) {
      final frac = math.exp(-0.5 * math.pow((b - peakI) / 1.8, 2));
      final bH = (h * 0.75 - h * 0.1) * frac;
      final bX = histX + b * (histW / bars);
      final bW = histW / bars - 2;
      canvas.drawRect(
        Rect.fromLTWH(bX, h * 0.85 - bH, bW, bH),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.5 + 0.3 * frac)..style = PaintingStyle.fill,
      );
    }

    final histLabelTp = TextPainter(
      text: const TextSpan(text: 'MW 분포', style: TextStyle(color: Color(0xFF5A8A9A), fontSize: 8)),
      textDirection: TextDirection.ltr,
    )..layout();
    histLabelTp.paint(canvas, Offset(histX + histW / 2 - histLabelTp.width / 2, h * 0.87));
  }

  @override
  bool shouldRepaint(covariant _PolymerizationScreenPainter oldDelegate) => true;
}
