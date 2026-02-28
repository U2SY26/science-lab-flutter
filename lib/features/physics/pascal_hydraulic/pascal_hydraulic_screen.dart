import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class PascalHydraulicScreen extends StatefulWidget {
  const PascalHydraulicScreen({super.key});
  @override
  State<PascalHydraulicScreen> createState() => _PascalHydraulicScreenState();
}

class _PascalHydraulicScreenState extends State<PascalHydraulicScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _force1 = 10;
  double _areaRatio = 10;
  double _force2 = 100, _pressure = 0;

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
      _force2 = _force1 * _areaRatio;
      _pressure = _force1 / 0.001;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _force1 = 10.0; _areaRatio = 10.0;
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
          Text('물리 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('파스칼 유압기', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '파스칼 유압기',
          formula: 'F₂/F₁ = A₂/A₁',
          formulaDescription: '파스칼의 원리에 의한 유압 시스템을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PascalHydraulicScreenPainter(
                time: _time,
                force1: _force1,
                areaRatio: _areaRatio,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '입력 힘 (N)',
                value: _force1,
                min: 1,
                max: 100,
                step: 1,
                defaultValue: 10,
                formatValue: (v) => v.toStringAsFixed(0) + ' N',
                onChanged: (v) => setState(() => _force1 = v),
              ),
              advancedControls: [
            SimSlider(
                label: '면적 비 (A₂/A₁)',
                value: _areaRatio,
                min: 1,
                max: 50,
                step: 1,
                defaultValue: 10,
                formatValue: (v) => v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _areaRatio = v),
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
          _V('F₂', _force2.toStringAsFixed(0) + ' N'),
          _V('P', (_pressure / 1000).toStringAsFixed(1) + ' kPa'),
          _V('비율', _areaRatio.toStringAsFixed(0) + 'x'),
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

class _PascalHydraulicScreenPainter extends CustomPainter {
  final double time;
  final double force1;
  final double areaRatio;

  _PascalHydraulicScreenPainter({
    required this.time,
    required this.force1,
    required this.areaRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Grid
    final gridPaint = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.4)..strokeWidth = 0.5;
    for (double x = 0; x < w; x += 30) { canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint); }
    for (double y = 0; y < h; y += 30) { canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint); }

    final force2 = force1 * areaRatio;
    // Animated piston phase: push small piston down
    final pistonPhase = (math.sin(time * 0.9) * 0.5 + 0.5); // 0..1

    // --- Hydraulic system layout ---
    // Small cylinder (left), connected U-tube, large cylinder (right)
    final fluidColor = const Color(0xFF00D4FF).withValues(alpha: 0.55);
    final wallPaint = Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.8)..strokeWidth = 2..style = PaintingStyle.stroke;

    // Small cylinder geometry
    final scCx = w * 0.22;
    final scW = w * 0.10;
    final scTop = h * 0.10;
    final scBot = h * 0.72;
    final scH = scBot - scTop;

    // Large cylinder geometry
    final lcCx = w * 0.72;
    final lcW = scW * math.sqrt(areaRatio).clamp(1.5, 5.0);
    final lcTop = h * 0.10;
    final lcBot = h * 0.72;
    final lcH = lcBot - lcTop;

    // U-tube connecting bottom
    final uTop = h * 0.72;
    final uBot = h * 0.84;

    // --- Fluid level calculation ---
    // Small piston pushes down → fluid rises on large side
    // Conservation: A1 * d1 = A2 * d2
    final a1 = scW;
    final a2 = lcW;
    final smallPistonDisp = pistonPhase * scH * 0.25; // small piston moves down
    final largePistonRise = smallPistonDisp * (a1 / a2); // large piston rises less

    // Fluid fill in cylinders
    final smallFluidTop = scBot - scH * 0.4 + smallPistonDisp * 0.5;
    final largeFluidTop = lcBot - lcH * 0.4 - largePistonRise;

    // Draw fluid in small cylinder
    canvas.drawRect(
      Rect.fromLTWH(scCx - scW / 2, smallFluidTop, scW, scBot - smallFluidTop),
      Paint()..color = fluidColor,
    );
    // Draw fluid in large cylinder
    canvas.drawRect(
      Rect.fromLTWH(lcCx - lcW / 2, largeFluidTop, lcW, lcBot - largeFluidTop),
      Paint()..color = fluidColor,
    );
    // Fluid in U-tube
    canvas.drawRect(
      Rect.fromLTWH(scCx - scW / 2, uTop, lcCx + lcW / 2 - (scCx - scW / 2), uBot - uTop),
      Paint()..color = fluidColor,
    );

    // Pressure equal lines (dashed horizontal)
    final pressureY = uTop + (uBot - uTop) * 0.5;
    for (double px2 = scCx - scW / 2; px2 < lcCx + lcW / 2; px2 += 8) {
      canvas.drawLine(
        Offset(px2, pressureY),
        Offset(px2 + 5, pressureY),
        Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: 0.3)..strokeWidth = 1,
      );
    }
    _drawLabel(canvas, 'P₁ = P₂', Offset(w * 0.47, pressureY), const Color(0xFFE0F4FF).withValues(alpha: 0.7), 8);

    // --- Small cylinder walls ---
    canvas.drawLine(Offset(scCx - scW / 2, scTop), Offset(scCx - scW / 2, scBot), wallPaint);
    canvas.drawLine(Offset(scCx + scW / 2, scTop), Offset(scCx + scW / 2, scBot), wallPaint);
    // U-tube bottom
    canvas.drawLine(Offset(scCx - scW / 2, uBot), Offset(lcCx + lcW / 2, uBot), wallPaint);
    canvas.drawLine(Offset(scCx - scW / 2, uTop), Offset(scCx - scW / 2, uBot), wallPaint..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4));
    canvas.drawLine(Offset(lcCx + lcW / 2, uTop), Offset(lcCx + lcW / 2, uBot), wallPaint..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4));

    // --- Large cylinder walls ---
    canvas.drawLine(Offset(lcCx - lcW / 2, lcTop), Offset(lcCx - lcW / 2, lcBot), wallPaint..color = const Color(0xFF5A8A9A).withValues(alpha: 0.8));
    canvas.drawLine(Offset(lcCx + lcW / 2, lcTop), Offset(lcCx + lcW / 2, lcBot), wallPaint);

    // --- Small piston ---
    final spY = scTop + scH * 0.1 + smallPistonDisp;
    canvas.drawRect(
      Rect.fromLTWH(scCx - scW / 2 + 1, spY, scW - 2, 8),
      Paint()..color = const Color(0xFF5A8A9A),
    );
    // Piston rod
    canvas.drawLine(
      Offset(scCx, scTop),
      Offset(scCx, spY),
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.6)..strokeWidth = 3,
    );

    // --- Large piston ---
    final lpY = lcTop + lcH * 0.1 - largePistonRise * 2;
    canvas.drawRect(
      Rect.fromLTWH(lcCx - lcW / 2 + 1, lpY, lcW - 2, 10),
      Paint()..color = const Color(0xFF5A8A9A),
    );
    canvas.drawLine(
      Offset(lcCx, lcTop),
      Offset(lcCx, lpY),
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.6)..strokeWidth = 4,
    );

    // --- Force arrows ---
    // Small: downward force F1
    final f1ArrowLen = (force1 / 100 * 22 + 10).clamp(10.0, 32.0);
    canvas.drawLine(Offset(scCx, scTop - 6), Offset(scCx, scTop - 6 - f1ArrowLen),
      Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);
    canvas.drawLine(Offset(scCx - 4, scTop - 6 - f1ArrowLen + 8), Offset(scCx, scTop - 6 - f1ArrowLen), Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);
    canvas.drawLine(Offset(scCx + 4, scTop - 6 - f1ArrowLen + 8), Offset(scCx, scTop - 6 - f1ArrowLen), Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);
    _drawLabel(canvas, 'F₁=${force1.toStringAsFixed(0)}N', Offset(scCx, scTop - f1ArrowLen - 16), const Color(0xFFFF6B35), 9);

    // Large: upward force F2
    final f2ArrowLen = (force2 / 5000 * 28 + 12).clamp(12.0, 36.0);
    canvas.drawLine(Offset(lcCx, lcTop - 6), Offset(lcCx, lcTop - 6 - f2ArrowLen),
      Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 3);
    canvas.drawLine(Offset(lcCx - 5, lcTop - 6 - 8), Offset(lcCx, lcTop - 6), Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 3);
    canvas.drawLine(Offset(lcCx + 5, lcTop - 6 - 8), Offset(lcCx, lcTop - 6), Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 3);
    _drawLabel(canvas, 'F₂=${force2.toStringAsFixed(0)}N', Offset(lcCx, lcTop - f2ArrowLen - 16), const Color(0xFF64FF8C), 9);

    // Cylinder labels
    _drawLabel(canvas, 'A₁', Offset(scCx, scBot + 14), const Color(0xFF5A8A9A), 9);
    _drawLabel(canvas, 'A₂', Offset(lcCx, lcBot + 14), const Color(0xFF5A8A9A), 9);

    // --- Formula & values ---
    _drawLabel(canvas, 'F₂ = F₁ × (A₂/A₁)', Offset(w / 2, h * 0.88), const Color(0xFFE0F4FF), 10);
    _drawLabel(canvas, '= ${force2.toStringAsFixed(0)} N  (${areaRatio.toStringAsFixed(0)}x 증폭)', Offset(w / 2, h * 0.95), const Color(0xFF00D4FF), 10);

    // Title
    _drawLabel(canvas, '파스칼 유압기', Offset(w / 2, 14), const Color(0xFF00D4FF), 12, bold: true);
  }

  void _drawLabel(Canvas canvas, String text, Offset center, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PascalHydraulicScreenPainter oldDelegate) => true;
}
