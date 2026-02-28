import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class KrebsCycleScreen extends StatefulWidget {
  const KrebsCycleScreen({super.key});
  @override
  State<KrebsCycleScreen> createState() => _KrebsCycleScreenState();
}

class _KrebsCycleScreenState extends State<KrebsCycleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _acetylCoA = 1;
  
  double _nadh = 3.0, _atp = 1.0, _co2Out = 2.0;

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
      _nadh = 3 * _acetylCoA;
      _atp = _acetylCoA;
      _co2Out = 2 * _acetylCoA;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _acetylCoA = 1.0;
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
          const Text('크렙스 회로', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '크렙스 회로',
          formula: 'Acetyl-CoA → 2CO₂ + 3NADH',
          formulaDescription: '크렙스 회로의 대사 과정을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _KrebsCycleScreenPainter(
                time: _time,
                acetylCoA: _acetylCoA,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'Acetyl-CoA (mM)',
                value: _acetylCoA,
                min: 0.1,
                max: 5,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' mM',
                onChanged: (v) => setState(() => _acetylCoA = v),
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
          _V('NADH', _nadh.toStringAsFixed(1)),
          _V('ATP', _atp.toStringAsFixed(1)),
          _V('CO₂', _co2Out.toStringAsFixed(1)),
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

class _KrebsCycleScreenPainter extends CustomPainter {
  final double time;
  final double acetylCoA;

  _KrebsCycleScreenPainter({
    required this.time,
    required this.acetylCoA,
  });

  void _lbl(Canvas canvas, String text, Offset pos, Color color, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fs, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawArrowOnArc(Canvas canvas, Offset center, double r, double angle, Color color) {
    final tangentAngle = angle + math.pi / 2;
    final pos = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
    final arrowHead = Path()
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(pos.dx - 8 * math.cos(tangentAngle - 0.5), pos.dy - 8 * math.sin(tangentAngle - 0.5))
      ..lineTo(pos.dx - 8 * math.cos(tangentAngle + 0.5), pos.dy - 8 * math.sin(tangentAngle + 0.5))
      ..close();
    canvas.drawPath(arrowHead, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final cx = size.width / 2;
    final cy = size.height / 2 + 8;
    final cycleR = math.min(size.width, size.height) * 0.26;
    final speed = acetylCoA * 0.25;

    // 8 intermediates of Krebs cycle
    final intermediates = [
      'Oxaloacetate\n(4C)',  // 0 - top
      'Citrate\n(6C)',       // 1
      'Isocitrate\n(6C)',    // 2
      'α-KG\n(5C)',          // 3
      'Succinyl\n(4C)',      // 4
      'Succinate\n(4C)',     // 5
      'Fumarate\n(4C)',      // 6
      'Malate\n(4C)',        // 7
    ];

    final byproducts = [
      null,           // 0→1: Acetyl-CoA enters
      null,           // 1→2
      'CO₂\nNADH',   // 2→3: isocitrate dehydrogenase
      'CO₂\nNADH',   // 3→4: α-KG dehydrogenase
      'ATP\nCoA',    // 4→5: succinyl-CoA synthetase
      'FADH₂',       // 5→6: succinate dehydrogenase
      null,          // 6→7
      'NADH',        // 7→0: malate dehydrogenase
    ];

    final byproductColors = [
      null,
      null,
      const Color(0xFF5A8A9A),  // CO2=muted, NADH=cyan
      const Color(0xFF5A8A9A),
      const Color(0xFF64FF8C),  // ATP=green
      const Color(0xFFFF6B35),  // FADH2=orange
      null,
      const Color(0xFF00D4FF),  // NADH=cyan
    ];

    // Draw mitochodria outline (ellipse bg)
    final mitoRect = Rect.fromCenter(center: Offset(cx, cy), width: cycleR * 2.6, height: cycleR * 2.4);
    canvas.drawOval(mitoRect, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.04));
    canvas.drawOval(mitoRect, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.12)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Draw cycle circle
    canvas.drawCircle(Offset(cx, cy), cycleR, Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Draw animated arc (clockwise progress)
    final progressAngle = (time * speed) % (2 * math.pi);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: cycleR),
      -math.pi / 2,
      progressAngle,
      false,
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.4)..strokeWidth = 3..style = PaintingStyle.stroke,
    );

    // Arrow on arc
    _drawArrowOnArc(canvas, Offset(cx, cy), cycleR, -math.pi / 2 + progressAngle, const Color(0xFF00D4FF));

    // Draw 8 nodes
    for (int i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 8;
      final pos = Offset(cx + cycleR * math.cos(angle), cy + cycleR * math.sin(angle));

      // Highlight current node
      final cyclePhase = (time * speed / (2 * math.pi)) % 1.0;
      final nodePhase = i / 8.0;
      final isActive = ((cyclePhase - nodePhase + 1) % 1.0) < 0.125;
      final nodeColor = isActive ? const Color(0xFF00D4FF) : const Color(0xFF5A8A9A);

      canvas.drawCircle(pos, 16, Paint()..color = nodeColor.withValues(alpha: 0.15));
      canvas.drawCircle(pos, 16, Paint()..color = nodeColor..style = PaintingStyle.stroke..strokeWidth = isActive ? 2 : 1);

      // Node label
      final lines = intermediates[i].split('\n');
      for (int l = 0; l < lines.length; l++) {
        _lbl(canvas, lines[l], pos + Offset(0, (l - (lines.length - 1) / 2) * 8), nodeColor, 6.5);
      }

      // Byproduct labels on the outside
      if (byproducts[i] != null) {
        final nextAngle = -math.pi / 2 + (i + 0.5) * 2 * math.pi / 8;
        final outerPos = Offset(cx + (cycleR + 30) * math.cos(nextAngle), cy + (cycleR + 30) * math.sin(nextAngle));
        final blines = byproducts[i]!.split('\n');
        for (int l = 0; l < blines.length; l++) {
          _lbl(canvas, blines[l], outerPos + Offset(0, (l - (blines.length - 1) / 2) * 9), byproductColors[i]!, 7.5);
        }
      }
    }

    // Acetyl-CoA input arrow
    final topPos = Offset(cx + cycleR * math.cos(-math.pi / 2 + math.pi / 8), cy + cycleR * math.sin(-math.pi / 2 + math.pi / 8));
    final acInPos = Offset(topPos.dx + 30, topPos.dy - 28);
    canvas.drawLine(acInPos, Offset(topPos.dx + 14, topPos.dy - 12),
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5);
    _lbl(canvas, 'Acetyl-CoA', Offset(acInPos.dx + 14, acInPos.dy - 6), const Color(0xFF64FF8C), 8);

    // Title
    _lbl(canvas, '크렙스 회로 (TCA Cycle)', Offset(cx, 13), const Color(0xFF00D4FF), 11);
    // Center text
    _lbl(canvas, 'TCA', Offset(cx, cy - 8), const Color(0xFF5A8A9A), 10);
    _lbl(canvas, 'Cycle', Offset(cx, cy + 8), const Color(0xFF5A8A9A), 10);

    // Energy yield summary at bottom
    final yBottom = size.height - 18;
    _lbl(canvas, '수율: 3NADH · 1FADH₂ · 1ATP · 2CO₂', Offset(cx, yBottom), const Color(0xFF5A8A9A), 8.5);
  }

  @override
  bool shouldRepaint(covariant _KrebsCycleScreenPainter oldDelegate) => true;
}
