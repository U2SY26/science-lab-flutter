import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class SpeciationScreen extends StatefulWidget {
  const SpeciationScreen({super.key});
  @override
  State<SpeciationScreen> createState() => _SpeciationScreenState();
}

class _SpeciationScreenState extends State<SpeciationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _isolation = 5;
  
  double _divergence = 0.0, _reproIsolation = 0.0;

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
      _divergence = 1 - math.exp(-_isolation * 0.1);
      _reproIsolation = _divergence * _divergence;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _isolation = 5.0;
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
          const Text('종 분화', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '종 분화',
          formula: 'Reproductive Isolation',
          formulaDescription: '지리적 격리에 의한 종 분화 과정을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SpeciationScreenPainter(
                time: _time,
                isolation: _isolation,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '격리 기간 (Myr)',
                value: _isolation,
                min: 0,
                max: 50,
                step: 0.5,
                defaultValue: 5,
                formatValue: (v) => v.toStringAsFixed(1) + ' Myr',
                onChanged: (v) => setState(() => _isolation = v),
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
          _V('분기도', (_divergence * 100).toStringAsFixed(1) + '%'),
          _V('생식 격리', (_reproIsolation * 100).toStringAsFixed(1) + '%'),
          _V('기간', _isolation.toStringAsFixed(1) + ' Myr'),
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

class _SpeciationScreenPainter extends CustomPainter {
  final double time;
  final double isolation;

  _SpeciationScreenPainter({
    required this.time,
    required this.isolation,
  });

  void _drawLabel(Canvas canvas, String text, Offset center,
      {double fontSize = 10, Color? color, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color ?? const Color(0xFF5A8A9A),
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  // Draw a simple stylised organism blob at pos with given color and spread
  void _drawPopulation(Canvas canvas, Offset center, double spread, Color color, int count, math.Random rng) {
    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final dist = rng.nextDouble() * spread;
      final pos = center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      canvas.drawCircle(pos, 4.0, Paint()..color = color.withValues(alpha: 0.55));
      canvas.drawCircle(pos, 4.0,
          Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }
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

    final w = size.width;
    final h = size.height;

    // Derived values
    final divergence = 1 - math.exp(-isolation * 0.1);
    final reproIso = divergence * divergence;
    final isNewSpecies = reproIso > 0.8;

    // Title
    final titleTp = TextPainter(
      text: const TextSpan(
          text: '종 분화 — 지리적 격리에 의한 이소적 분화',
          style: TextStyle(color: cyanColor, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, Offset((w - titleTp.width) / 2, 5));

    // ── Map area (top 58%) ─────────────────────────────────────────────
    final mapTop = 26.0;
    final mapBottom = h * 0.58;
    final mapH = mapBottom - mapTop;
    final mapLeft = w * 0.05;
    final mapRight = w * 0.95;
    final mapW = mapRight - mapLeft;

    // Background land mass
    final landPaint = Paint()..color = const Color(0xFF162830);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(mapLeft, mapTop, mapRight, mapBottom), const Radius.circular(8)),
        landPaint);

    // Left population territory
    final leftCenter = Offset(mapLeft + mapW * 0.25, mapTop + mapH * 0.5);
    final rightCenter = Offset(mapLeft + mapW * 0.75, mapTop + mapH * 0.5);

    // Color of populations diverges with isolation
    final leftColor = Color.lerp(cyanColor, const Color(0xFF0066FF), divergence)!;
    final rightColor = Color.lerp(cyanColor, orangeColor, divergence)!;

    // Territory circles
    canvas.drawCircle(leftCenter, mapW * 0.22,
        Paint()..color = leftColor.withValues(alpha: 0.08));
    canvas.drawCircle(leftCenter, mapW * 0.22,
        Paint()..color = leftColor.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    canvas.drawCircle(rightCenter, mapW * 0.22,
        Paint()..color = rightColor.withValues(alpha: 0.08));
    canvas.drawCircle(rightCenter, mapW * 0.22,
        Paint()..color = rightColor.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Geographic barrier (mountain/river) in center — grows with isolation
    final barrierX = mapLeft + mapW / 2;
    final barrierWidth = 4.0 + divergence * 18.0;
    final barrierPaint = Paint()..color = const Color(0xFF8B6914).withValues(alpha: 0.7 + divergence * 0.3);
    canvas.drawRect(
        Rect.fromCenter(center: Offset(barrierX, mapTop + mapH / 2), width: barrierWidth, height: mapH * 0.7),
        barrierPaint);
    // Mountain peaks on barrier
    for (int i = 0; i < 4; i++) {
      final py = mapTop + mapH * 0.15 + i * mapH * 0.18;
      final path = Path()
        ..moveTo(barrierX - barrierWidth / 2 - 4, py + 8)
        ..lineTo(barrierX, py - 8)
        ..lineTo(barrierX + barrierWidth / 2 + 4, py + 8);
      canvas.drawPath(path, Paint()..color = const Color(0xFFBB9933)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    }
    _drawLabel(canvas, '지리적 장벽', Offset(barrierX, mapBottom + 8), fontSize: 8, color: const Color(0xFFBB9933));

    // Draw organisms
    final rng1 = math.Random(42);
    final rng2 = math.Random(77);
    _drawPopulation(canvas, leftCenter, mapW * 0.16, leftColor, 12, rng1);
    _drawPopulation(canvas, rightCenter, mapW * 0.16, rightColor, 12, rng2);

    // Population labels
    _drawLabel(canvas, '집단 A', leftCenter - Offset(0, mapH * 0.28), fontSize: 10, color: leftColor, bold: true);
    _drawLabel(canvas, '집단 B', rightCenter - Offset(0, mapH * 0.28), fontSize: 10, color: rightColor, bold: true);

    // Species label — show "새 종!" when speciation complete
    if (isNewSpecies) {
      _drawLabel(canvas, '종 A', leftCenter + Offset(0, mapH * 0.24), fontSize: 10, color: leftColor, bold: true);
      _drawLabel(canvas, '종 B', rightCenter + Offset(0, mapH * 0.24), fontSize: 10, color: rightColor, bold: true);
      final newSpTp = TextPainter(
        text: const TextSpan(text: '종 분화 완료!', style: TextStyle(color: greenColor, fontSize: 13, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      newSpTp.paint(canvas, Offset((w - newSpTp.width) / 2, mapTop + mapH / 2 - 8));
    }

    // ── Progress bars (bottom area) ────────────────────────────────────
    final barAreaTop = h * 0.62;
    final barLeft = w * 0.08;
    final barRight = w * 0.92;
    final barW = barRight - barLeft;
    final barH2 = 14.0;
    final barGap = 36.0;

    void drawBar(double topY, double value, Color barColor, String label, String valText) {
      // Background
      canvas.drawRect(Rect.fromLTWH(barLeft, topY, barW, barH2),
          Paint()..color = const Color(0xFF1A3040));
      // Fill
      canvas.drawRect(Rect.fromLTWH(barLeft, topY, barW * value.clamp(0.0, 1.0), barH2),
          Paint()..color = barColor.withValues(alpha: 0.75));
      // Border
      canvas.drawRect(Rect.fromLTWH(barLeft, topY, barW, barH2),
          Paint()..color = barColor.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 0.8);
      _drawLabel(canvas, label, Offset(barLeft - 2, topY - 9), fontSize: 9, color: mutedColor);
      _drawLabel(canvas, valText, Offset(barRight + 2, topY + barH2 / 2), fontSize: 9, color: barColor);
    }

    drawBar(barAreaTop, divergence, cyanColor, '형질 분기도', '${(divergence * 100).toStringAsFixed(1)}%');
    drawBar(barAreaTop + barGap, reproIso, orangeColor, '생식 격리도', '${(reproIso * 100).toStringAsFixed(1)}%');

    // Threshold line on repro isolation bar
    final thresholdX = barLeft + barW * 0.8;
    canvas.drawLine(Offset(thresholdX, barAreaTop + barGap - 4), Offset(thresholdX, barAreaTop + barGap + barH2 + 4),
        Paint()..color = greenColor.withValues(alpha: 0.7)..strokeWidth = 1.0);
    _drawLabel(canvas, '임계값', Offset(thresholdX, barAreaTop + barGap + barH2 + 12), fontSize: 8, color: greenColor);

    // Time label
    _drawLabel(canvas, '격리 기간: ${isolation.toStringAsFixed(1)} Myr',
        Offset(w / 2, h - 10), fontSize: 10, color: inkColor);
  }

  @override
  bool shouldRepaint(covariant _SpeciationScreenPainter oldDelegate) => true;
}
