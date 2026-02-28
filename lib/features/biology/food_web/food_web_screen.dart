import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class FoodWebScreen extends StatefulWidget {
  const FoodWebScreen({super.key});
  @override
  State<FoodWebScreen> createState() => _FoodWebScreenState();
}

class _FoodWebScreenState extends State<FoodWebScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _primaryProd = 10000;
  
  double _level2 = 1000, _level3 = 100, _level4 = 10;

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
      _level2 = _primaryProd * 0.1;
      _level3 = _level2 * 0.1;
      _level4 = _level3 * 0.1;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _primaryProd = 10000.0;
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
          const Text('먹이 그물 역학', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '먹이 그물 역학',
          formula: 'Energy transfer ~10%',
          formulaDescription: '먹이 그물의 에너지 흐름과 영양 단계를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _FoodWebScreenPainter(
                time: _time,
                primaryProd: _primaryProd,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '1차 생산량 (kcal)',
                value: _primaryProd,
                min: 1000,
                max: 50000,
                step: 1000,
                defaultValue: 10000,
                formatValue: (v) => v.toStringAsFixed(0) + ' kcal',
                onChanged: (v) => setState(() => _primaryProd = v),
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
          _V('2차 소비', _level2.toStringAsFixed(0) + ' kcal'),
          _V('3차 소비', _level3.toStringAsFixed(0) + ' kcal'),
          _V('4차 소비', _level4.toStringAsFixed(0) + ' kcal'),
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

class _FoodWebScreenPainter extends CustomPainter {
  final double time;
  final double primaryProd;

  _FoodWebScreenPainter({
    required this.time,
    required this.primaryProd,
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

  void _drawArrow(Canvas canvas, Offset from, Offset to, double thickness, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);
    // Arrowhead
    final dir = (to - from);
    final len = dir.distance;
    if (len < 1) { return; }
    final norm = Offset(dir.dx / len, dir.dy / len);
    final perp = Offset(-norm.dy, norm.dx);
    const headLen = 6.0;
    const headWid = 3.5;
    final tip = to;
    final base = tip - norm * headLen;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((base + perp * headWid).dx, (base + perp * headWid).dy)
      ..lineTo((base - perp * headWid).dx, (base - perp * headWid).dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    const greenColor = Color(0xFF64FF8C);
    const cyanColor = Color(0xFF00D4FF);
    const orangeColor = Color(0xFFFF6B35);
    const purpleColor = Color(0xFFAA66FF);
    const mutedColor = Color(0xFF5A8A9A);
    const inkColor = Color(0xFFE0F4FF);

    final w = size.width;
    final h = size.height;

    // Title
    final titleTp = TextPainter(
      text: const TextSpan(
          text: '먹이 그물 — 에너지 흐름 (10% 전달 법칙)',
          style: TextStyle(color: cyanColor, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, Offset((w - titleTp.width) / 2, 5));

    // Energy at each level
    final e1 = primaryProd;
    final e2 = e1 * 0.1;
    final e3 = e2 * 0.1;
    final e4 = e3 * 0.1;

    // Network area: top 65%
    final netTop = 24.0;
    final netBottom = h * 0.65;
    final netH = netBottom - netTop;

    // 4 trophic levels, Y positions
    final levelY = [
      netTop + netH * 0.82,  // L1 producers
      netTop + netH * 0.55,  // L2 primary consumers
      netTop + netH * 0.28,  // L3 secondary consumers
      netTop + netH * 0.04,  // L4 apex
    ];

    // Species nodes: [name, x, level, color]
    final nodes = [
      // L1 producers (3)
      ('풀', w * 0.22, 0, greenColor),
      ('나무', w * 0.50, 0, greenColor),
      ('조류', w * 0.78, 0, greenColor),
      // L2 primary consumers (3)
      ('메뚜기', w * 0.18, 1, cyanColor),
      ('사슴', w * 0.50, 1, cyanColor),
      ('물고기', w * 0.82, 1, cyanColor),
      // L3 secondary consumers (2)
      ('뱀', w * 0.30, 2, orangeColor),
      ('독수리', w * 0.70, 2, orangeColor),
      // L4 apex (1)
      ('호랑이', w * 0.50, 3, purpleColor),
    ];

    // Food web connections: [predator idx, prey idx]
    final edges = [
      (3, 0), (4, 1), (4, 0), (5, 2), // L1→L2
      (6, 3), (7, 4), (7, 5),          // L2→L3
      (8, 6), (8, 7),                  // L3→L4
    ];

    // Draw edges (arrows from prey to predator)
    for (final edge in edges) {
      final pred = nodes[edge.$1];
      final prey = nodes[edge.$2];
      final fromPos = Offset(prey.$2, levelY[prey.$3]);
      final toPos = Offset(pred.$2, levelY[pred.$3]);
      // Arrow thickness proportional to energy flow at prey's level
      final levels = [e1, e2, e3, e4];
      final baseE = levels[prey.$3];
      final thickness = (baseE / primaryProd * 4.0).clamp(0.8, 4.0);
      _drawArrow(canvas, fromPos, toPos - Offset(0, 12), thickness,
          prey.$4.withValues(alpha: 0.5));
    }

    // Draw nodes
    final nodeR = 14.0;
    for (int i = 0; i < nodes.length; i++) {
      final nd = nodes[i];
      final pos = Offset(nd.$2, levelY[nd.$3]);
      // Pulse animation on apex predator
      double r = nodeR;
      if (i == 8) {
        r = nodeR + 2 * math.sin(time * 2.5).abs();
      }
      canvas.drawCircle(pos, r, Paint()..color = nd.$4.withValues(alpha: 0.22));
      canvas.drawCircle(pos, r,
          Paint()..color = nd.$4..style = PaintingStyle.stroke..strokeWidth = 1.8);
      _drawLabel(canvas, nd.$1, pos, fontSize: 9, color: nd.$4, bold: true);
    }

    // Trophic level labels (right side)
    const levelLabels = ['1차 생산자', '1차 소비자', '2차 소비자', '최상위 포식자'];
    final levelEnergies = [e1, e2, e3, e4];
    for (int i = 0; i < 4; i++) {
      _drawLabel(canvas, levelLabels[i], Offset(w * 0.06, levelY[i]), fontSize: 7.5, color: mutedColor);
    }

    // Energy pyramid (right side)
    final pyrLeft = w * 0.82;
    final pyrRight = w * 0.98;
    const pyrColors = [greenColor, cyanColor, orangeColor, purpleColor];
    for (int i = 0; i < 4; i++) {
      final frac = (levelEnergies[i] / e1).clamp(0.0, 1.0);
      final barW2 = (pyrRight - pyrLeft) * frac;
      final barCx = (pyrLeft + pyrRight) / 2;
      final barRect = Rect.fromCenter(
          center: Offset(barCx, levelY[i]), width: barW2.clamp(4.0, pyrRight - pyrLeft), height: 12);
      canvas.drawRect(barRect, Paint()..color = pyrColors[i].withValues(alpha: 0.55));
      canvas.drawRect(barRect,
          Paint()..color = pyrColors[i].withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 0.7);
      final kcal = levelEnergies[i] >= 1000
          ? '${(levelEnergies[i] / 1000).toStringAsFixed(0)}k'
          : levelEnergies[i].toStringAsFixed(0);
      _drawLabel(canvas, kcal, Offset(barCx, levelY[i]), fontSize: 7.5, color: inkColor);
    }

    // Bottom: Lotka-Volterra style population graph
    final graphTop = h * 0.68;
    final graphBottom = h * 0.96;
    final graphLeft = w * 0.08;
    final graphRight = w * 0.92;
    final graphH = graphBottom - graphTop;
    final graphW = graphRight - graphLeft;

    // Background
    canvas.drawRect(Rect.fromLTRB(graphLeft, graphTop, graphRight, graphBottom),
        Paint()..color = const Color(0xFF0A1520));

    // Plot oscillating populations (Lotka-Volterra inspired)
    final tOffset = time * 0.8;
    final seriesData = [
      (greenColor, 0.0),    // producer: base wave
      (cyanColor, 0.9),     // primary consumer: lags behind
      (orangeColor, 1.8),   // secondary consumer: more lag
    ];

    for (final series in seriesData) {
      final path = Path();
      for (int px = 0; px <= graphW.toInt(); px++) {
        final t2 = tOffset + px / graphW * 4 * math.pi;
        final baseAmp = 0.3 + 0.2 * math.sin(t2 * 0.3);
        final y2 = graphTop + graphH * 0.5 - graphH * 0.38 * math.sin(t2 - series.$2) * baseAmp;
        final x2 = graphLeft + px.toDouble();
        if (px == 0) {
          path.moveTo(x2, y2.clamp(graphTop + 2, graphBottom - 2));
        } else {
          path.lineTo(x2, y2.clamp(graphTop + 2, graphBottom - 2));
        }
      }
      canvas.drawPath(path,
          Paint()..color = series.$1.withValues(alpha: 0.7)..strokeWidth = 1.2..style = PaintingStyle.stroke);
    }

    // Graph border and labels
    canvas.drawRect(Rect.fromLTRB(graphLeft, graphTop, graphRight, graphBottom),
        Paint()..color = mutedColor.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    _drawLabel(canvas, '개체수 진동 (시간)', Offset((graphLeft + graphRight) / 2, graphTop - 6), fontSize: 8, color: mutedColor);

    // Legend
    final legItems = [('생산자', greenColor), ('1차 소비자', cyanColor), ('2차 소비자', orangeColor)];
    for (int i = 0; i < 3; i++) {
      final lx = graphLeft + graphW * 0.12 + i * graphW * 0.32;
      canvas.drawLine(Offset(lx - 10, graphBottom + 8), Offset(lx + 2, graphBottom + 8),
          Paint()..color = legItems[i].$2..strokeWidth = 2.0);
      _drawLabel(canvas, legItems[i].$1, Offset(lx + 20, graphBottom + 8), fontSize: 8, color: legItems[i].$2);
    }
  }

  @override
  bool shouldRepaint(covariant _FoodWebScreenPainter oldDelegate) => true;
}
