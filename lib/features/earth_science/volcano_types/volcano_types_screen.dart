import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class VolcanoTypesScreen extends StatefulWidget {
  const VolcanoTypesScreen({super.key});
  @override
  State<VolcanoTypesScreen> createState() => _VolcanoTypesScreenState();
}

class _VolcanoTypesScreenState extends State<VolcanoTypesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _volcanoType = 0;
  double _vei = 3;
  double _ejectaVol = 0.01;

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
      _ejectaVol = math.pow(10, _vei - 2).toDouble();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _volcanoType = 0.0; _vei = 3.0;
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
          Text('지구과학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('화산 유형과 분출', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '화산 유형과 분출',
          formula: 'VEI 0-8',
          formulaDescription: '다양한 화산 유형과 분출 메커니즘을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _VolcanoTypesScreenPainter(
                time: _time,
                volcanoType: _volcanoType,
                vei: _vei,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '화산 유형',
                value: _volcanoType,
                min: 0,
                max: 2,
                step: 1,
                defaultValue: 0,
                formatValue: (v) => ['순상','성층','화구'][v.toInt()],
                onChanged: (v) => setState(() => _volcanoType = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'VEI (화산 폭발지수)',
                value: _vei,
                min: 0,
                max: 8,
                step: 1,
                defaultValue: 3,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _vei = v),
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
          _V('유형', ['순상','성층','화구'][_volcanoType.toInt()]),
          _V('VEI', _vei.toInt().toString()),
          _V('분출량', _ejectaVol.toStringAsFixed(2) + ' km³'),
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

class _VolcanoTypesScreenPainter extends CustomPainter {
  final double time;
  final double volcanoType;
  final double vei;

  _VolcanoTypesScreenPainter({
    required this.time,
    required this.volcanoType,
    required this.vei,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, {Color color = const Color(0xFF5A8A9A), double fontSize = 9}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawVolcano(Canvas canvas, double cx, double groundY, double peakH, double baseW, int type) {
    // type 0 = shield (flat), 1 = composite (steep), 2 = caldera (sunken top)
    final Path path = Path();
    if (type == 0) {
      // Shield: wide, flat
      path.moveTo(cx - baseW, groundY);
      path.quadraticBezierTo(cx - baseW * 0.5, groundY - peakH * 0.6, cx, groundY - peakH);
      path.quadraticBezierTo(cx + baseW * 0.5, groundY - peakH * 0.6, cx + baseW, groundY);
    } else if (type == 1) {
      // Composite: steep cone
      path.moveTo(cx - baseW, groundY);
      path.lineTo(cx, groundY - peakH);
      path.lineTo(cx + baseW, groundY);
    } else {
      // Caldera: cone with sunken top
      path.moveTo(cx - baseW, groundY);
      path.lineTo(cx - baseW * 0.15, groundY - peakH + peakH * 0.18);
      path.lineTo(cx + baseW * 0.15, groundY - peakH + peakH * 0.18);
      path.lineTo(cx + baseW, groundY);
    }
    path.close();
    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF5A4A3A), const Color(0xFF2A1A10)],
      ).createShader(Rect.fromLTWH(cx - baseW, groundY - peakH, baseW * 2, peakH)));
    canvas.drawPath(path, Paint()..color = const Color(0xFF3A2A1A)..strokeWidth = 1..style = PaintingStyle.stroke);
  }

  void _drawMagmaChamber(Canvas canvas, double cx, double groundY, double h) {
    // Underground magma chamber
    final chamberY = groundY + h * 0.08;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, chamberY), width: 36, height: 18),
      Paint()..color = const Color(0xFFFF4400).withValues(alpha: 0.7),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, chamberY), width: 36, height: 18),
      Paint()..color = const Color(0xFFFF8800).withValues(alpha: 0.4)..strokeWidth = 1.5..style = PaintingStyle.stroke,
    );
    // Conduit line
    canvas.drawLine(
      Offset(cx, groundY),
      Offset(cx, chamberY - 8),
      Paint()..color = const Color(0xFFFF4400).withValues(alpha: 0.6)..strokeWidth = 3,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;
    final int vType = volcanoType.round().clamp(0, 2);
    final intensityFrac = (vei / 8.0).clamp(0.0, 1.0);

    // Sky gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.65),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(const Color(0xFF0A0A14), const Color(0xFF1A0808), intensityFrac)!,
          const Color(0xFF0D1A20),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.65)),
    );

    // Ground
    final groundY = h * 0.68;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, w, h - groundY),
      Paint()..color = const Color(0xFF1A0A05),
    );

    // Volcano parameters per type
    final configs = [
      (w / 2, h * 0.22, w * 0.38, 0, '순상화산'),  // shield: short, wide
      (w / 2, h * 0.38, w * 0.22, 1, '성층화산'),  // composite: tall, narrow
      (w / 2, h * 0.26, w * 0.30, 2, '칼데라'),    // caldera: mid height, wide
    ];

    final cfg = configs[vType];
    final vcx = cfg.$1, peakH = cfg.$2, baseW = cfg.$3;
    final vt = cfg.$4;
    final vtName = cfg.$5;

    // Magma chamber underground
    _drawMagmaChamber(canvas, vcx, groundY, h);

    // Draw volcano body
    _drawVolcano(canvas, vcx, groundY, peakH, baseW, vt);

    // Peak Y
    final peakY = (vType == 2) ? groundY - peakH + peakH * 0.18 : groundY - peakH;

    // Lava flows on slope sides (animated)
    final lavaAlpha = (0.3 + intensityFrac * 0.5).clamp(0.0, 0.9);
    for (int side = -1; side <= 1; side += 2) {
      final lavaPath = Path();
      lavaPath.moveTo(vcx, peakY);
      final endX = vcx + side * baseW * (0.4 + intensityFrac * 0.5);
      final endY = groundY - 4;
      lavaPath.quadraticBezierTo(
        vcx + side * baseW * 0.2, groundY - peakH * 0.3,
        endX, endY,
      );
      canvas.drawPath(lavaPath, Paint()
        ..color = const Color(0xFFFF4400).withValues(alpha: lavaAlpha * 0.5)
        ..strokeWidth = 4 + intensityFrac * 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round);
    }

    // Eruption particles (popping from crater)
    final particleCount = (4 + vei * 2).round();
    final rng = math.Random(42);
    for (int p = 0; p < particleCount; p++) {
      final tFrac = ((time * (0.6 + rng.nextDouble() * 0.6) + p / particleCount.toDouble())) % 1.0;
      final angle = -math.pi / 2 + (rng.nextDouble() - 0.5) * (0.8 + intensityFrac * 1.2);
      final launchSpeed = 60 + intensityFrac * 120;
      final px = vcx + math.cos(angle) * launchSpeed * tFrac;
      final py = peakY + math.sin(angle) * launchSpeed * tFrac + 0.5 * 200 * tFrac * tFrac; // gravity
      if (py > groundY) continue;
      final pSize = 2.0 + (1 - tFrac) * 3;
      final pColor = Color.lerp(const Color(0xFFFFDD00), const Color(0xFFFF2200), tFrac)!;
      canvas.drawCircle(Offset(px, py), pSize,
        Paint()..color = pColor.withValues(alpha: (1 - tFrac * 0.7)));
    }

    // Gas/ash cloud at top
    final cloudAlpha = (0.15 + intensityFrac * 0.45).clamp(0.0, 0.7);
    final cloudR = 20 + intensityFrac * 40 + 8 * math.sin(time * 1.5);
    for (int ci = 0; ci < 4; ci++) {
      final cAngle = ci * math.pi / 2 + time * 0.4;
      final cr = cloudR * (0.5 + ci * 0.15);
      canvas.drawCircle(
        Offset(vcx + math.cos(cAngle) * cr * 0.4, peakY - 12 - ci * 8),
        cr,
        Paint()..color = Color.lerp(
          const Color(0xFF888888),
          const Color(0xFFDD4400),
          intensityFrac,
        )!.withValues(alpha: cloudAlpha * (1 - ci * 0.2)),
      );
    }

    // Crater glow
    canvas.drawCircle(Offset(vcx, peakY), 6 + intensityFrac * 8,
      Paint()..color = const Color(0xFFFF6600).withValues(alpha: 0.6 + 0.3 * math.sin(time * 4)));

    // Labels
    _drawLabel(canvas, vtName, Offset(vcx, groundY + 18), color: const Color(0xFFFF6B35), fontSize: 10);
    _drawLabel(canvas, 'VEI ${vei.toInt()}', Offset(vcx, h * 0.06), color: const Color(0xFFFF4400), fontSize: 11);
    _drawLabel(canvas, '마그마 챔버', Offset(vcx + baseW * 0.5, groundY + h * 0.1), color: const Color(0xFF5A3A2A), fontSize: 8);
    _drawLabel(canvas, '분화구', Offset(vcx + 28, peakY - 6), color: const Color(0xFF5A8A9A), fontSize: 8);
  }

  @override
  bool shouldRepaint(covariant _VolcanoTypesScreenPainter oldDelegate) => true;
}
