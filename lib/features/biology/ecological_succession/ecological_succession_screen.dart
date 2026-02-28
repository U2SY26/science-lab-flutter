import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class EcologicalSuccessionScreen extends StatefulWidget {
  const EcologicalSuccessionScreen({super.key});
  @override
  State<EcologicalSuccessionScreen> createState() => _EcologicalSuccessionScreenState();
}

class _EcologicalSuccessionScreenState extends State<EcologicalSuccessionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _years = 50;
  
  String _stage = "개척종";double _biodiversity = 0.1;

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
      _stage = _years < 5 ? "개척종" : _years < 30 ? "초본" : _years < 100 ? "관목" : _years < 300 ? "양수림" : "극상";
      _biodiversity = 1 - math.exp(-_years * 0.01);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _years = 50.0;
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
          const Text('생태 천이', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '생태 천이',
          formula: 'Pioneer → Climax',
          formulaDescription: '생태 천이의 단계를 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _EcologicalSuccessionScreenPainter(
                time: _time,
                years: _years,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '경과 시간 (년)',
                value: _years,
                min: 0,
                max: 500,
                step: 10,
                defaultValue: 50,
                formatValue: (v) => v.toStringAsFixed(0) + '년',
                onChanged: (v) => setState(() => _years = v),
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
          _V('단계', _stage),
          _V('다양성', (_biodiversity * 100).toStringAsFixed(1) + '%'),
          _V('경과', _years.toStringAsFixed(0) + '년'),
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

class _EcologicalSuccessionScreenPainter extends CustomPainter {
  final double time;
  final double years;

  _EcologicalSuccessionScreenPainter({
    required this.time,
    required this.years,
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

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    const cyanColor = Color(0xFF00D4FF);
    const greenColor = Color(0xFF64FF8C);
    const mutedColor = Color(0xFF5A8A9A);
    const brownColor = Color(0xFF8B5E3C);

    final w = size.width;
    final h = size.height;

    // Stage from years: 0=나지, 1=이끼, 2=초본, 3=관목, 4=교목, 5=극상
    final maxYears = 500.0;
    final stageBreaks = [0.0, 5.0, 30.0, 100.0, 300.0, 500.0];
    final stageNames = ['나지', '이끼류', '초본식물', '관목', '교목림', '극상림'];
    final stageColors = [
      const Color(0xFF3A3020),
      const Color(0xFF557722),
      const Color(0xFF66AA33),
      const Color(0xFF33AA55),
      const Color(0xFF228844),
      const Color(0xFF116633),
    ];

    int currentStage = 0;
    for (int i = stageBreaks.length - 1; i >= 0; i--) {
      if (years >= stageBreaks[i]) {
        currentStage = i;
        break;
      }
    }
    final stageProgress = currentStage < 5
        ? ((years - stageBreaks[currentStage]) /
                (stageBreaks[currentStage + 1] - stageBreaks[currentStage]))
            .clamp(0.0, 1.0)
        : 1.0;

    // Title
    final titleTp = TextPainter(
      text: const TextSpan(
          text: '생태 천이 — 1차 천이 (나지 → 극상림)',
          style: TextStyle(color: cyanColor, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, Offset((w - titleTp.width) / 2, 5));

    // ── Vegetation scene (top ~54%) ─────────────────────────────────────
    final sceneTop = 24.0;
    final sceneBottom = h * 0.56;
    final sceneLeft = w * 0.04;
    final sceneRight = w * 0.96;
    final sceneW = sceneRight - sceneLeft;

    // Sky gradient replaced by simple rect
    canvas.drawRect(Rect.fromLTRB(sceneLeft, sceneTop, sceneRight, sceneBottom),
        Paint()..color = const Color(0xFF0A1828));

    // Ground
    final groundY = sceneBottom - 18.0;
    canvas.drawRect(Rect.fromLTRB(sceneLeft, groundY, sceneRight, sceneBottom),
        Paint()..color = Color.lerp(brownColor, const Color(0xFF2A5020), (currentStage / 5.0))!);

    // Draw 6 stage sections from left to right
    final sectionW = sceneW / 6;
    for (int s = 0; s < 6; s++) {
      final secLeft = sceneLeft + sectionW * s;
      final secRight = secLeft + sectionW;
      final secCx = (secLeft + secRight) / 2;
      final isActive = s == currentStage;
      final isDone = s < currentStage;
      final alpha = isDone ? 1.0 : (isActive ? stageProgress : 0.15);

      // Stage background tint
      canvas.drawRect(Rect.fromLTRB(secLeft, sceneTop, secRight, groundY),
          Paint()..color = stageColors[s].withValues(alpha: alpha * 0.12));

      final rng = math.Random(s * 17);
      if (s == 0) {
        // Bare ground — rocks
        for (int r = 0; r < 3; r++) {
          final rx = secLeft + sectionW * (0.2 + r * 0.3);
          canvas.drawOval(
              Rect.fromCenter(center: Offset(rx, groundY - 4), width: 10, height: 6),
              Paint()..color = const Color(0xFF667788).withValues(alpha: alpha));
        }
      } else if (s == 1) {
        // Moss patches
        for (int m = 0; m < 5; m++) {
          final mx = secLeft + sectionW * (0.1 + m * 0.18);
          canvas.drawOval(
              Rect.fromCenter(center: Offset(mx, groundY - 3), width: 8, height: 4),
              Paint()..color = stageColors[s].withValues(alpha: alpha * 0.8));
        }
      } else if (s == 2) {
        // Grass tufts
        for (int g = 0; g < 4; g++) {
          final gx = secLeft + sectionW * (0.15 + g * 0.22);
          final gH = 10.0 + rng.nextDouble() * 8;
          for (int blade = -2; blade <= 2; blade++) {
            canvas.drawLine(
                Offset(gx + blade * 2.0, groundY),
                Offset(gx + blade * 3.0, groundY - gH * alpha),
                Paint()..color = stageColors[s].withValues(alpha: alpha * 0.9)..strokeWidth = 1.2);
          }
        }
      } else if (s == 3) {
        // Shrubs
        for (int sh = 0; sh < 3; sh++) {
          final sx = secLeft + sectionW * (0.2 + sh * 0.3);
          final sH = 18.0 + rng.nextDouble() * 10;
          canvas.drawLine(Offset(sx, groundY), Offset(sx, groundY - sH * alpha * 0.6),
              Paint()..color = brownColor.withValues(alpha: alpha)..strokeWidth = 2.0);
          canvas.drawCircle(Offset(sx, groundY - sH * alpha),
              10 * alpha, Paint()..color = stageColors[s].withValues(alpha: alpha * 0.8));
        }
      } else {
        // Trees (s==4 and s==5)
        final treeCount = s == 4 ? 2 : 3;
        for (int t = 0; t < treeCount; t++) {
          final tx = secLeft + sectionW * ((t + 1) / (treeCount + 1));
          final tH = (s == 4 ? 32.0 : 42.0) + rng.nextDouble() * 10;
          // Trunk
          canvas.drawLine(Offset(tx, groundY), Offset(tx, groundY - tH * alpha * 0.55),
              Paint()..color = brownColor.withValues(alpha: alpha)..strokeWidth = 3.0);
          // Canopy
          final canopyR = (s == 4 ? 12.0 : 16.0) * alpha;
          canvas.drawCircle(Offset(tx, groundY - tH * alpha),
              canopyR, Paint()..color = stageColors[s].withValues(alpha: alpha * 0.85));
          if (s == 5) {
            // Extra canopy layer
            canvas.drawCircle(Offset(tx - 8, groundY - tH * alpha * 0.85),
                canopyR * 0.7, Paint()..color = stageColors[s].withValues(alpha: alpha * 0.7));
          }
        }
      }

      // Active stage highlight border
      if (isActive) {
        canvas.drawRect(Rect.fromLTRB(secLeft + 1, sceneTop + 1, secRight - 1, sceneBottom - 1),
            Paint()..color = cyanColor.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }

      // Stage name label
      _drawLabel(canvas, stageNames[s], Offset(secCx, sceneBottom - 8),
          fontSize: 8, color: isActive ? cyanColor : (isDone ? mutedColor : mutedColor.withValues(alpha: 0.3)));
    }

    // ── Soil profile (thin strip below scene) ─────────────────────────
    final soilTop = sceneBottom + 2;
    final soilBottom = sceneBottom + 16.0;
    final soilDepth = (years / maxYears).clamp(0.0, 1.0);
    for (int s = 0; s < 6; s++) {
      final secLeft2 = sceneLeft + sectionW * s;
      final active = s <= currentStage;
      final soilH = active ? (soilBottom - soilTop) : 2.0;
      canvas.drawRect(Rect.fromLTWH(secLeft2 + 1, soilTop, sectionW - 2, soilH),
          Paint()..color = Color.lerp(const Color(0xFF3A2010), const Color(0xFF7A5A30), s / 5.0)!
              .withValues(alpha: active ? 0.8 : 0.2));
    }
    _drawLabel(canvas, '토양 발달', Offset(sceneLeft - 2, (soilTop + soilBottom) / 2), fontSize: 7.5, color: brownColor);

    // ── Biodiversity curve (bottom) ───────────────────────────────────
    final graphTop2 = soilBottom + 10.0;
    final graphBottom2 = h - 14.0;
    final graphLeft2 = sceneLeft + 18;
    final graphRight2 = sceneRight;
    final graphH2 = graphBottom2 - graphTop2;
    final graphW2 = graphRight2 - graphLeft2;

    canvas.drawRect(Rect.fromLTRB(graphLeft2, graphTop2, graphRight2, graphBottom2),
        Paint()..color = const Color(0xFF0A1520));

    // Draw diversity curve
    final divPath = Path();
    for (int px = 0; px <= graphW2.toInt(); px++) {
      final yr = maxYears * px / graphW2;
      final div = 1 - math.exp(-yr * 0.012);
      final py = graphTop2 + graphH2 * (1 - div);
      if (px == 0) {
        divPath.moveTo(graphLeft2 + px.toDouble(), py);
      } else {
        divPath.lineTo(graphLeft2 + px.toDouble(), py);
      }
    }
    canvas.drawPath(divPath,
        Paint()..color = greenColor.withValues(alpha: 0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Current position marker
    final curX = graphLeft2 + graphW2 * (years / maxYears).clamp(0.0, 1.0);
    final curDiv = 1 - math.exp(-years * 0.012);
    final curY = graphTop2 + graphH2 * (1 - curDiv);
    canvas.drawCircle(Offset(curX, curY), 4.5, Paint()..color = cyanColor.withValues(alpha: 0.4));
    canvas.drawCircle(Offset(curX, curY), 4.5,
        Paint()..color = cyanColor..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Graph labels
    canvas.drawRect(Rect.fromLTRB(graphLeft2, graphTop2, graphRight2, graphBottom2),
        Paint()..color = mutedColor.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    _drawLabel(canvas, '종 다양도', Offset(graphLeft2 - 8, graphTop2 + graphH2 / 2), fontSize: 7.5, color: greenColor);
    _drawLabel(canvas, '0년', Offset(graphLeft2, graphBottom2 + 6), fontSize: 7.5, color: mutedColor);
    _drawLabel(canvas, '500년', Offset(graphRight2, graphBottom2 + 6), fontSize: 7.5, color: mutedColor);
    _drawLabel(canvas, '${years.toStringAsFixed(0)}년 / ${stageNames[currentStage]}',
        Offset((graphLeft2 + graphRight2) / 2, graphTop2 - 7), fontSize: 9, color: cyanColor);
  }

  @override
  bool shouldRepaint(covariant _EcologicalSuccessionScreenPainter oldDelegate) => true;
}
