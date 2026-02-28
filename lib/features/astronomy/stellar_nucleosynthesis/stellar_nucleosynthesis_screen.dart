import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class StellarNucleosynthesisScreen extends StatefulWidget {
  const StellarNucleosynthesisScreen({super.key});
  @override
  State<StellarNucleosynthesisScreen> createState() => _StellarNucleosynthesisScreenState();
}

class _StellarNucleosynthesisScreenState extends State<StellarNucleosynthesisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _stellarMass = 5.0;
  String _maxElement = 'He'; double _coreTemp = 1.5e7;

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
      _maxElement = _stellarMass > 8 ? 'Fe' : _stellarMass > 4 ? 'C/O' : 'He';
      _coreTemp = _stellarMass > 8 ? 3.5e9 : _stellarMass > 4 ? 6e8 : 1.5e7;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _stellarMass = 5.0;
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
          Text('천문학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('항성 핵합성', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '항성 핵합성',
          formula: '4H → He + 26.7 MeV',
          formulaDescription: '항성 핵에서 핵융합으로 원소가 형성됩니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _StellarNucleosynthesisScreenPainter(
                time: _time,
                stellarMass: _stellarMass,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '항성 질량 (M☉)',
                value: _stellarMass,
                min: 0.5,
                max: 25.0,
                step: 0.5,
                defaultValue: 5.0,
                formatValue: (v) => '${v.toStringAsFixed(1)} M☉',
                onChanged: (v) => setState(() => _stellarMass = v),
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
          _V('최대 원소', _maxElement),
          _V('핵 온도', '${(_coreTemp / 1e6).toStringAsFixed(0)} MK'),
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

class _StellarNucleosynthesisScreenPainter extends CustomPainter {
  final double time;
  final double stellarMass;

  _StellarNucleosynthesisScreenPainter({
    required this.time,
    required this.stellarMass,
  });

  // Layers from outer to inner: [name, color, reaction]
  // Visible layers depend on stellarMass
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final cx = size.width * 0.42;
    final cy = size.height * 0.52;
    final maxR = math.min(cx, cy) * 0.82;

    // Determine active layers based on mass
    final bool hasO  = stellarMass > 4;
    final bool hasSi = stellarMass > 8;
    final bool hasFe = stellarMass > 10;

    // Layer definitions: [label, reaction, fill color, fraction of maxR]
    final layers = <Map<String, dynamic>>[
      {'label': 'H', 'rx': 'p-p / CNO', 'color': const Color(0xFF1A6FA0), 'frac': 1.0},
      {'label': 'He', 'rx': '3α: 3He→C', 'color': const Color(0xFF2DA86B), 'frac': 0.78},
      if (hasO) {'label': 'C/O', 'rx': 'C+C→Ne,Na', 'color': const Color(0xFFE8A020), 'frac': 0.58},
      if (hasO) {'label': 'O/Ne', 'rx': 'O+O→Si,S', 'color': const Color(0xFFD05010), 'frac': 0.42},
      if (hasSi) {'label': 'Si/S', 'rx': 'Si→Fe', 'color': const Color(0xFF8A4A10), 'frac': 0.28},
      if (hasFe) {'label': 'Fe', 'rx': '끝 (Fe 핵)', 'color': const Color(0xFF606070), 'frac': 0.15},
    ];

    // Draw layers from outermost to innermost
    for (final layer in layers) {
      final r = maxR * (layer['frac'] as double);
      final color = layer['color'] as Color;
      // Glow
      canvas.drawCircle(
        Offset(cx, cy), r + 4,
        Paint()..color = color.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color.withValues(alpha: 0.85));
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.2);
    }

    // Animated fusion particles flowing inward
    for (int i = 0; i < 8; i++) {
      final angle = (time * 0.7 + i * math.pi * 2 / 8);
      final progress = (time * 0.4 + i * 0.13) % 1.0;
      final r = maxR * (0.9 - progress * 0.75);
      final px = cx + r * math.cos(angle);
      final py = cy + r * math.sin(angle);
      final alpha = (1.0 - progress) * 0.7;
      canvas.drawCircle(Offset(px, py), 2.5, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: alpha));
    }

    // Labels on right side
    final labelX = cx + maxR + 14;
    for (int i = 0; i < layers.length; i++) {
      final layer = layers[i];
      final r = maxR * (layer['frac'] as double);
      final labelY = cy - r + r * 0.18;
      _drawLabel(canvas, layer['label'] as String, Offset(labelX, labelY - 7),
          (layer['color'] as Color).withValues(alpha: 1.0), 11, bold: true);
      _drawLabel(canvas, layer['rx'] as String, Offset(labelX, labelY + 5),
          const Color(0xFF5A8A9A), 8);
      // Connector line
      canvas.drawLine(
        Offset(cx + r, cy),
        Offset(labelX - 4, labelY),
        Paint()..color = (layer['color'] as Color).withValues(alpha: 0.4)..strokeWidth = 0.7,
      );
    }

    // CNO cycle diagram (bottom-left corner)
    final cnoX = size.width * 0.12;
    final cnoY = size.height * 0.88;
    _drawLabel(canvas, 'CNO Cycle', Offset(cnoX - 20, cnoY - 55), const Color(0xFF00D4FF).withValues(alpha: 0.7), 9, bold: true);
    final cnoNodes = ['¹²C', '¹³N', '¹³C', '¹⁴N', '¹⁵O', '¹⁵N'];
    final cnoAngles = List.generate(6, (i) => -math.pi / 2 + i * math.pi * 2 / 6);
    final cnoR = 22.0;
    for (int i = 0; i < 6; i++) {
      final nx = cnoX + cnoR * math.cos(cnoAngles[i]);
      final ny = cnoY + cnoR * math.sin(cnoAngles[i]);
      final nx2 = cnoX + cnoR * math.cos(cnoAngles[(i + 1) % 6]);
      final ny2 = cnoY + cnoR * math.sin(cnoAngles[(i + 1) % 6]);
      canvas.drawLine(Offset(nx, ny), Offset(nx2, ny2),
          Paint()..color = const Color(0xFF2DA86B).withValues(alpha: 0.5)..strokeWidth = 1);
      canvas.drawCircle(Offset(nx, ny), 3, Paint()..color = const Color(0xFF2DA86B).withValues(alpha: 0.8));
      _drawLabel(canvas, cnoNodes[i], Offset(nx - 6, ny - 5), const Color(0xFFE0F4FF), 7);
    }
    // Animated position on CNO cycle
    final cnoProgress = (time * 0.4) % 1.0;
    final cnoIdx = (cnoProgress * 6).floor();
    final cnoProg2 = (cnoProgress * 6) - cnoIdx;
    final cnoA1 = cnoAngles[cnoIdx % 6];
    final cnoA2 = cnoAngles[(cnoIdx + 1) % 6];
    final cnoAx = cnoX + cnoR * (math.cos(cnoA1) * (1 - cnoProg2) + math.cos(cnoA2) * cnoProg2);
    final cnoAy = cnoY + cnoR * (math.sin(cnoA1) * (1 - cnoProg2) + math.sin(cnoA2) * cnoProg2);
    canvas.drawCircle(Offset(cnoAx, cnoAy), 4, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.9));

    // Mass label
    _drawLabel(canvas, '${stellarMass.toStringAsFixed(1)} M☉', Offset(cx - 18, cy - 8),
        Colors.white.withValues(alpha: 0.7), 10, bold: true);
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _StellarNucleosynthesisScreenPainter oldDelegate) => true;
}
